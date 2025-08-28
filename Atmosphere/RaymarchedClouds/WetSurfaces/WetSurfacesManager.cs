using EVEManager;
using ShaderLoader;
using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;
using Utils;

namespace Atmosphere
{
    public class WetSurfacesManager : GenericEVEManager<WetSurfacesConfig>
    {
        public override ObjectType objectType { get { return ObjectType.BODY; } }
        public override String configName { get { return "EVE_WET_SURFACES_CONFIG"; } }
        public override int LoadOrder { get { return 20; } }

        private static WetSurfacesRenderingManager wetSurfacesRenderingManager;

        public static WetSurfacesRenderingManager RenderingManager { get => wetSurfacesRenderingManager; }

        public static WetSurfacesConfig GetConfig(string configName)
        {
            return GetObjectList().Find(x => x.Name == configName);
        }

        protected override void ApplyConfigNode(ConfigNode node)
        {
            if (!preconditionsPassed)
                return;

            if (!CheckDeferredInstalled())
            {
                Log("[Error] Deferred not installed, wet surface effects won't be available");
                preconditionsPassed = false;
                return;
            }

            WetSurfacesConfig wetSurfacesConfig = new WetSurfacesConfig();
            wetSurfacesConfig.LoadConfigNode(node);

            var celestial = Tools.GetCelestialBody(wetSurfacesConfig.Body);

            if (celestial == null)
            {
                Log($"[Error] Body {celestial.name} not found for wet surfaces config: {wetSurfacesConfig.Name}");
            }

            var existingConfigForPlanet = ObjectList.FirstOrDefault(x => x.Body == wetSurfacesConfig.Body);

            if (existingConfigForPlanet == null)
            {
                wetSurfacesConfig.Apply();
                ObjectList.Add(wetSurfacesConfig);
            }
            else
            {
                Log($"[Error] Wet surfaces config already exists for {wetSurfacesConfig.Body}: {existingConfigForPlanet.Name}");
            }
        }

        private bool CheckDeferredInstalled()
        {
            string deferredTypeName = "Deferred.Deferred";

            Type type = null;
            AssemblyLoader.loadedAssemblies.TypeOperation(t => { if (t.FullName == deferredTypeName) type = t; });

            if (type != null)
            {
                return true;
            }

            return false;
        }

        bool preconditionsPassed = true;

        protected override void PostApplyConfigNodes()
        {
            if (ObjectList.Count > 0)
            {
                CloudsManager.Instance.Apply();

                if (wetSurfacesRenderingManager == null)
                {
                    wetSurfacesRenderingManager = new WetSurfacesRenderingManager();
                    wetSurfacesRenderingManager.Initialize();
                }
            }
        }

        public override void Update()
        {
            base.Update();

            if (wetSurfacesRenderingManager != null)
            {
                wetSurfacesRenderingManager.Update();
            }
        }
    }


    public class WetSurfacesRenderingManager
    {
        static Shader wetEffectShader = null;
        static Shader WetEffectShader
        {
            get
            {
                if (wetEffectShader == null) wetEffectShader = ShaderLoaderClass.FindShader("EVE/GBufferWetEffect");
                return wetEffectShader;
            }
        }

        static Shader ripplesLutShader = null;
        static Shader RipplesLutShader
        {
            get
            {
                if (ripplesLutShader == null) ripplesLutShader = ShaderLoaderClass.FindShader("EVE/RipplesLut");
                return ripplesLutShader;
            }
        }

        static Shader accumulationShader = null;
        static Shader AccumulationShader
        {
            get
            {
                if (accumulationShader == null) accumulationShader = ShaderLoaderClass.FindShader("EVE/WetSurfacesAccumulationTracking");
                return accumulationShader;
            }
        }

        class RegisteredWetSurfaceProperties
        {
            public CelestialBody body;
            public List<WetSurfaces> surfaces;
        }

        // This class will update the wet surfaces directly (even if volumetrics are switched
        // off for 2D clouds). In the future these will also be used to catchup on history
        // on game load or cloud layer load
        private Dictionary<WetSurfacesConfig, RegisteredWetSurfaceProperties> registeredSurfaces = new Dictionary<WetSurfacesConfig, RegisteredWetSurfaceProperties>();


        public void RegisterWetSurfacesInstanceLoaded(WetSurfaces cloudWetSurfaces)
        {
            var config = cloudWetSurfaces.WetSurfacesConfigObject;

            if (registeredSurfaces.TryGetValue(config, out var properties))
            {
                properties.surfaces.Add(cloudWetSurfaces);
            }
            else
            {
                registeredSurfaces[config] = new RegisteredWetSurfaceProperties()
                {
                    surfaces = new List<WetSurfaces>() { cloudWetSurfaces },
                    body = cloudWetSurfaces.CloudsRaymarchedVolume.parentCelestialBody
                };
            }
        }

        public void UnregisterWetSurfacesInstanceLoaded(WetSurfaces cloudWetSurfaces)
        {
            var config = cloudWetSurfaces.WetSurfacesConfigObject;

            if (registeredSurfaces.TryGetValue(config, out var properties))
            {
                properties.surfaces.Remove(cloudWetSurfaces);
                if (properties.surfaces.Count == 0)
                {
                    registeredSurfaces.Remove(config);
                }
            }
        }

        WetSurfacesConfig activeConfig = null;
        Transform activeParentTransform = null; // TODO: might need to track celestial body also

        public Material wetEffectMaterial, ripplesLutMaterial, accumulationMaterial;

        public RenderTexture rippleGradientFlip, rippleGradientFlop, rippleNormals;
        private HistoryManager<RenderTexture> trackingRT;

        WetSurfacesPerCameraRenderer nearCameraWetSurfacesRenderer, farCameraWetSurfacesRenderer;
        bool renderersAdded = false;
        bool renderToFlip = true;
        float currentCoverage = 0f;
        float currentCraftWetLevel = 0f;
        float ripplesTime = 0f;
        float maxAltitude, minAltitude;

        public void Initialize()
        {
            rippleGradientFlip = RenderTextureUtils.CreateRenderTexture(1024, 1024, RenderTextureFormat.R8, false, FilterMode.Bilinear);
            rippleGradientFlop = RenderTextureUtils.CreateRenderTexture(1024, 1024, RenderTextureFormat.R8, false, FilterMode.Bilinear);
            rippleNormals = RenderTextureUtils.CreateRenderTexture(1024, 1024, RenderTextureFormat.RG16, false, FilterMode.Bilinear);

            // x y scenery puddles and wetness, z w terrain puddles and wetness
            trackingRT = RenderTextureUtils.CreateRTHistoryManager(true, false, false, 2048, 1024, RenderTextureFormat.ARGBHalf, FilterMode.Bilinear);

            wetEffectMaterial = new Material(WetEffectShader);
            ripplesLutMaterial = new Material(RipplesLutShader);
            accumulationMaterial = new Material(AccumulationShader);
            wetEffectMaterial.SetTexture(ShaderProperties._ripplesLut_PROPERTY, rippleNormals);
        }

        private void RemoveRenderer()
        {
            if (nearCameraWetSurfacesRenderer != null)
            {
                nearCameraWetSurfacesRenderer.Cleanup();
                Component.Destroy(nearCameraWetSurfacesRenderer);
            }

            if (farCameraWetSurfacesRenderer != null)
            {
                farCameraWetSurfacesRenderer.Cleanup();
                Component.Destroy(farCameraWetSurfacesRenderer);
            }

            renderersAdded = false;
        }

        static readonly int MAX_ACTIVE_ACCUMULATION_LAYERS = 6;

        private static readonly int[] mapShaderProperties = new int[6]
        {
            Shader.PropertyToID("map0"),
            Shader.PropertyToID("map1"),
            Shader.PropertyToID("map2"),
            Shader.PropertyToID("map3"),
            Shader.PropertyToID("map4"),
            Shader.PropertyToID("map5"),
        };

        private RenderTexture[] activeAccumulationTextures = new RenderTexture[MAX_ACTIVE_ACCUMULATION_LAYERS];
        private Matrix4x4[] activeAccumulationTransforms = new Matrix4x4[MAX_ACTIVE_ACCUMULATION_LAYERS];
        private float[] activeAccumulationFades = new float[MAX_ACTIVE_ACCUMULATION_LAYERS];

        private int activeAccumulationLayerCount = 0;

        public void Update()
        {
            if (registeredSurfaces.Count == 0)
                return;

            WetSurfacesConfig closestConfig = GetClosestConfig();

            if (closestConfig != activeConfig)
            {
                var volume = registeredSurfaces[closestConfig].surfaces.First().CloudsRaymarchedVolume;
                OnActiveConfigChanged(closestConfig, volume.PlanetRadius, volume.ParentTransform);
            }

            UpdateActiveWetSurfaceInstances();

            UpdateRendering();
        }

        private WetSurfacesConfig GetClosestConfig()
        {
            WetSurfacesConfig closestConfig = null;

            if (registeredSurfaces.Count == 1)
            {
                closestConfig = registeredSurfaces.First().Key;
            }
            else
            {
                // Sort to find nearest
                float minDistanceSquared = float.PositiveInfinity;

                foreach (var surface in registeredSurfaces)
                {
                    float squaredDistance = Vector3.Dot(surface.Value.body.transform.position,
                                                        surface.Value.body.transform.position);

                    if (squaredDistance < minDistanceSquared)
                    {
                        minDistanceSquared = squaredDistance;
                        closestConfig = surface.Key;
                    }
                }
            }

            return closestConfig;
        }

        private void OnActiveConfigChanged(WetSurfacesConfig wetSurfacesConfig, float planetRadius, Transform parentTransform)
        {
            wetEffectMaterial.SetFloat("puddlesTiling", 1f / wetSurfacesConfig.PuddleTextureScale);
            wetEffectMaterial.SetFloat("rippleTiling", 1f / wetSurfacesConfig.RippleScale);

            if (wetSurfacesConfig.PuddlesTexture != null)
            {
                wetSurfacesConfig.PuddlesTexture.ApplyTexture(wetEffectMaterial, "_puddlesTexture");
            }

            maxAltitude = -1e9f;
            minAltitude = 1e9f;

            foreach (var wetSurface in registeredSurfaces[wetSurfacesConfig].surfaces)
            {
                foreach (var cloudType in wetSurface.CloudsRaymarchedVolume.CloudTypes)
                {
                    if (cloudType.WetSurfacesIntensity > 0.0)
                    {
                        maxAltitude = Mathf.Max(maxAltitude, cloudType.MaxAltitude);
                        minAltitude = Mathf.Min(minAltitude, cloudType.MinAltitude);
                    }
                }
            }

            wetEffectMaterial.SetFloat("maxAltitude", maxAltitude);
            wetEffectMaterial.SetFloat("minAltitude", minAltitude);
            wetEffectMaterial.SetFloat("planetRadius", planetRadius);

            accumulationMaterial.SetFloat("planetRadius", planetRadius);

            accumulationMaterial.SetVector("sceneryProperties", new Vector4(
                wetSurfacesConfig.Scenery.PuddleAccumulationSpeed,
                wetSurfacesConfig.Scenery.PuddleDryingSpeed,
                wetSurfacesConfig.Scenery.WetnessAccumulationSpeed,
                wetSurfacesConfig.Scenery.WetnessDryingSpeed));

            accumulationMaterial.SetFloat("maxSceneryPuddleAccumulation", wetSurfacesConfig.Scenery.MaxPuddleAccumulation);

            accumulationMaterial.SetVector("terrainProperties", new Vector4(
                wetSurfacesConfig.Terrain.PuddleAccumulationSpeed,
                wetSurfacesConfig.Terrain.PuddleDryingSpeed,
                wetSurfacesConfig.Terrain.WetnessAccumulationSpeed,
                wetSurfacesConfig.Terrain.WetnessDryingSpeed));

            accumulationMaterial.SetFloat("maxTerrainPuddleAccumulation", wetSurfacesConfig.Terrain.MaxPuddleAccumulation);

            activeConfig = wetSurfacesConfig;
            activeParentTransform = parentTransform;
        }

        private void UpdateActiveWetSurfaceInstances()
        {
            foreach (var wetSurface in registeredSurfaces[activeConfig].surfaces)
            {
                if (activeAccumulationLayerCount >= MAX_ACTIVE_ACCUMULATION_LAYERS)
                    continue;

                var volume = wetSurface.CloudsRaymarchedVolume;
                var config = wetSurface.WetSurfacesConfigObject;

                float timeFade = volume.CurrentTimeFadeCoverage * volume.CurrentTimeFadeDensity;

                if (timeFade <= 0.0f)
                    continue;

                Vector3 positionToSample = Vector3.zero;

                if (FlightGlobals.ActiveVessel != null)
                    positionToSample = FlightGlobals.ActiveVessel.transform.position;

                var coverageAtCraft = volume.SampleCoverage(positionToSample, out float cloudType);

                coverageAtCraft = Mathf.Clamp01((coverageAtCraft - config.MinCoverageThreshold) / (config.MaxCoverageThreshold - config.MinCoverageThreshold));

                if (coverageAtCraft > 0f)
                {
                    coverageAtCraft *= volume.GetInterpolatedCloudTypeWetSurfacesDensity(cloudType);
                }

                currentCoverage += coverageAtCraft;

                activeAccumulationTextures[activeAccumulationLayerCount] = wetSurface.AccumulationTexture;
                activeAccumulationTransforms[activeAccumulationLayerCount] = volume.CloudRotationMatrix;
                activeAccumulationFades[activeAccumulationLayerCount] = timeFade;

                activeAccumulationLayerCount++;
            }
        }

        private void UpdateRendering()
        {
            currentCoverage = Mathf.Min(1f, currentCoverage);

            //if (currentCoverage > 0f || currentWetLevel > 0f || currentPuddleLevel > 0f)
            {
                var deltaTime = Tools.GetDeltaTime();

                if (currentCoverage > 0f)
                {
                    UpdateRipples(deltaTime);
                }

                UpdateCraftWetLevel(deltaTime);

                UpdateTerrainAndSceneryLevels(deltaTime, activeParentTransform.localToWorldMatrix, activeParentTransform.worldToLocalMatrix);

                UpdateRenderers();
            }

            currentCoverage = 0f;
            activeAccumulationLayerCount = 0;
        }

        private void UpdateRenderers()
        {
            if (!renderersAdded || nearCameraWetSurfacesRenderer == null)
            {
                var nearCamera = Camera.allCameras.Where(x => x.name == "Camera 00").FirstOrDefault();
                if (nearCamera != null)
                {
                    nearCameraWetSurfacesRenderer = nearCamera.gameObject.AddComponent<WetSurfacesPerCameraRenderer>();
                    nearCameraWetSurfacesRenderer.SetMaterial(wetEffectMaterial);
                }

                if (!Tools.IsUnifiedCameraMode() && farCameraWetSurfacesRenderer == null)
                {
                    var farCamera = Camera.allCameras.Where(x => x.name == "Camera 01").FirstOrDefault();

                    if (farCamera != null)
                    {
                        farCameraWetSurfacesRenderer = farCamera.gameObject.AddComponent<WetSurfacesPerCameraRenderer>();
                        farCameraWetSurfacesRenderer.SetMaterial(wetEffectMaterial);
                    }
                }

                renderersAdded = true;
            }
        }

        private void UpdateTerrainAndSceneryLevels(float deltaTime, Matrix4x4 planetToWorldMatrix, Matrix4x4 worldToPlanetMatrix)
        {
            if (activeParentTransform == null || activeConfig == null)
                return;

            accumulationMaterial.SetMatrix(ShaderProperties.planetToWorldMatrix_PROPERTY, planetToWorldMatrix);
            wetEffectMaterial.SetMatrix(ShaderProperties.worldToPlanetMatrix_PROPERTY, worldToPlanetMatrix);

            for (int i = 0; i < activeAccumulationLayerCount; i++)
            {
                accumulationMaterial.SetTexture(mapShaderProperties[i], activeAccumulationTextures[i]);
                accumulationMaterial.SetFloatArray(ShaderProperties.fades_PROPERTY, activeAccumulationFades);
                accumulationMaterial.SetMatrixArray(ShaderProperties.transforms_PROPERTY, activeAccumulationTransforms);
            }

            accumulationMaterial.SetInt(ShaderProperties.activeCount_PROPERTY, activeAccumulationLayerCount);
            accumulationMaterial.SetFloat(ShaderProperties.accumulationDeltaTime_PROPERTY, deltaTime);
            accumulationMaterial.SetTexture(ShaderProperties.previousTexture_PROPERTY, trackingRT[!renderToFlip, false, 0]);

            Graphics.Blit(null, trackingRT[renderToFlip, false, 0], accumulationMaterial);

            wetEffectMaterial.SetTexture(ShaderProperties.trackingRT_PROPERTY, trackingRT[renderToFlip, false, 0]);

            renderToFlip = !renderToFlip;
        }

        private void PerformCatchup()
        {
            // Find the timestamp to start at, using the max drying time


            int catchupSteps = 64;
            
            for (int i=0; i < catchupSteps; i++)
            {
                // Do that non-linear mapping to find the time

                // For every time step, recompute the planet rotation using its KSP api info

                // Apply planet scale matrix to it

                // Invert to worldToPlanet

                // Now step through the registered cloud types

                // Use their time settings to fill in the time values

                // Compute their worldToCloud matrices using the rotations

                // Integrate the tracking map levels

                // Integrate the craft/camera levels
            }
        }

        private void UpdateCraftWetLevel(float deltaTime)
        {
            if (activeConfig == null)
                return;

            currentCraftWetLevel += activeConfig.Craft.WetnessAccumulationSpeed * currentCoverage * deltaTime;
            currentCraftWetLevel -= activeConfig.Craft.WetnessDryingSpeed * deltaTime;

            currentCraftWetLevel = Mathf.Clamp01(currentCraftWetLevel);
            currentCraftWetLevel = Mathf.Min(currentCraftWetLevel, 0.5f); // because this looked good
                                                                            // TODO: recheck these?

            wetEffectMaterial.SetFloat(ShaderProperties.craftWetness_PROPERTY, currentCraftWetLevel);

            wetEffectMaterial.SetVector(ShaderProperties.upVector_PROPERTY, -activeParentTransform.position.normalized);
        }

        private void UpdateRipples(float deltaTime)
        {
            ripplesTime += deltaTime;
            ripplesTime = ripplesTime % 20000f;
            ripplesLutMaterial.SetFloat(ShaderProperties.ripplesTime_PROPERTY, ripplesTime);

            Graphics.Blit(null, rippleGradientFlip, ripplesLutMaterial, 0);

            ripplesLutMaterial.SetTexture(ShaderProperties.ripplesInputTexture_PROPERTY, rippleGradientFlip);
            Graphics.Blit(null, rippleGradientFlop, ripplesLutMaterial, 1);

            ripplesLutMaterial.SetTexture(ShaderProperties.ripplesInputTexture_PROPERTY, rippleGradientFlop);
            Graphics.Blit(null, rippleGradientFlip, ripplesLutMaterial, 2);

            // Could combine this step with the previous by doing pixel shader derivatives? We'll see if it helps
            ripplesLutMaterial.SetTexture(ShaderProperties.ripplesInputTexture_PROPERTY, rippleGradientFlip);
            Graphics.Blit(null, rippleNormals, ripplesLutMaterial, 3);

            /*
            rippleNormals.GenerateMips(); // TODO: Should I do this or just fade out the normals with distance?
                                          // Second would be cheaper
            */

            ripplesLutMaterial.SetFloat(ShaderProperties.rainRipplesAmount_PROPERTY, currentCoverage);
        }

        // TODO
        public void SetEnabled(bool value)
        {
            // If disabled, remove renderer from camera, otherwise it will get added in Update
            if (value == false)
            {
                RemoveRenderer();
            }
        }
    }

    public class WetSurfacesPerCameraRenderer : MonoBehaviour
    {
        Camera cam;
        CommandBuffer wetEffectCommandBuffer;
        Material mat;

        Mesh quadMesh;

        bool isInitialized = false;

        public void SetMaterial(Material mat)
        {
            this.mat = mat;
        }

        private void GetRenderResolutions(Camera targetCamera, out int screenWidth, out int screenHeight)
        {
            bool supportVR = VRUtils.VREnabled();

            if (supportVR)
            {
                VRUtils.GetEyeTextureResolution(out screenWidth, out screenHeight);
            }
            else
            {
                screenWidth = targetCamera.activeTexture.width;
                screenHeight = targetCamera.activeTexture.height;
            }
        }

        int tempRT1 = Shader.PropertyToID("_TempRTGbuffer1");
        int tempRT2 = Shader.PropertyToID("_TempRTGbuffer2");

        // TODO: make this add the commandBuffer only when rendering something
        void Initialize()
        {
            cam = GetComponent<Camera>();

            if (cam == null || cam.activeTexture == null || mat == null)
                return;

            int screenWidth, screenHeight;
            GetRenderResolutions(cam, out screenWidth, out screenHeight);

            var go = GameObject.CreatePrimitive(PrimitiveType.Quad);
            quadMesh = Mesh.Instantiate(go.GetComponent<MeshFilter>().mesh);
            GameObject.Destroy(go);

            wetEffectCommandBuffer = new CommandBuffer();
            wetEffectCommandBuffer.name = "EVE Wet Effects CommandBuffer";

            // TODO: consolidate the two rendertextures by copying only what we need from Gbuffer

            // Define a temporary render texture
            wetEffectCommandBuffer.GetTemporaryRT(tempRT1, screenWidth, screenHeight, 0, FilterMode.Point, RenderTextureFormat.ARGB32);
            wetEffectCommandBuffer.GetTemporaryRT(tempRT2, screenWidth, screenHeight, 0, FilterMode.Point, RenderTextureFormat.ARGB2101010);

            // Copy GBuffers
            wetEffectCommandBuffer.Blit(BuiltinRenderTextureType.GBuffer1, tempRT1);
            wetEffectCommandBuffer.Blit(BuiltinRenderTextureType.GBuffer2, tempRT2);

            wetEffectCommandBuffer.SetGlobalTexture("_originalGbuffer1Texture", tempRT1);
            wetEffectCommandBuffer.SetGlobalTexture("_originalGbuffer2Texture", tempRT2);

            RenderTargetIdentifier[] gbufferIdentifiers = { BuiltinRenderTextureType.GBuffer0, BuiltinRenderTextureType.GBuffer1, BuiltinRenderTextureType.GBuffer2 };
            wetEffectCommandBuffer.SetRenderTarget(gbufferIdentifiers, BuiltinRenderTextureType.CameraTarget);

            // TODO: only do this when currentCraftWetLevel > 0 ?
            wetEffectCommandBuffer.DrawMesh(quadMesh, Matrix4x4.identity, mat, 0, 0); // Pass 0: Parts and Kerbals, wet effect only, no puddles

            wetEffectCommandBuffer.DrawMesh(quadMesh, Matrix4x4.identity, mat, 0, 1); // Pass 1: Scenery, wet + puddles

            // TODO: What to do about parallax grass? Turns out its using an invalid mask
            // Can we change parallax grass and scatters to match terrain?
            wetEffectCommandBuffer.DrawMesh(quadMesh, Matrix4x4.identity, mat, 0, 2); // Pass 2: Terrain, wet + puddles

            wetEffectCommandBuffer.ReleaseTemporaryRT(tempRT1);
            wetEffectCommandBuffer.ReleaseTemporaryRT(tempRT2);

            cam.AddCommandBuffer(CameraEvent.BeforeReflections, wetEffectCommandBuffer);

            isInitialized = true;
        }

        public void Cleanup()
        {
            if (cam != null && wetEffectCommandBuffer != null)
                cam.RemoveCommandBuffer(CameraEvent.BeforeReflections, wetEffectCommandBuffer);
        }

        void OnDestroy()
        {
            Cleanup();
        }

        private void OnPreRender()
        {

            if (mat != null)
            {
                if (cam != null)
                    mat.SetMatrix(ShaderProperties.CameraToWorld_PROPERTY, cam.cameraToWorldMatrix);

                // TODO: remove this and do a tracked frame
                mat.SetVector(ShaderProperties.floatingOriginOffset_PROPERTY, new Vector3((float)FloatingOrigin.TerrainShaderOffset.x,
                    (float)FloatingOrigin.TerrainShaderOffset.y, (float)FloatingOrigin.TerrainShaderOffset.z));
            }
        }

        void OnPostRender()
        {
            if (!isInitialized)
            {
                Initialize();
            }
        }

    }
}
