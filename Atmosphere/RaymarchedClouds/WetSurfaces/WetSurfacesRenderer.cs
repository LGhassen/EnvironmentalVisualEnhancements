using ShaderLoader;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;
using Utils;

namespace Atmosphere
{
    public class WetSurfacesRenderer
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
        Transform activeParentTransform = null;
        CelestialBody activeCelestialBody = null;

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

        int rippleTextureSize = 1024;

        public void Initialize()
        {
            rippleGradientFlip = RenderTextureUtils.CreateRenderTexture(rippleTextureSize, rippleTextureSize, RenderTextureFormat.R8, false, FilterMode.Bilinear);
            rippleGradientFlop = RenderTextureUtils.CreateRenderTexture(rippleTextureSize, rippleTextureSize, RenderTextureFormat.R8, false, FilterMode.Bilinear);
            rippleNormals = RenderTextureUtils.CreateRenderTexture(rippleTextureSize, rippleTextureSize, RenderTextureFormat.RG16, true, FilterMode.Bilinear);

            // x y scenery puddles and wetness, z w terrain puddles and wetness
            // It's important to use 32-bit floats and not 16-bit because the additions/substractions work with very small numbers
            // Could normalize and multiply by 65k though
            trackingRT = RenderTextureUtils.CreateRTHistoryManager(true, false, false, 2048, 1024, RenderTextureFormat.ARGBFloat, FilterMode.Bilinear);

            wetEffectMaterial = new Material(WetEffectShader);
            ripplesLutMaterial = new Material(RipplesLutShader);
            accumulationMaterial = new Material(AccumulationShader);
            wetEffectMaterial.SetTexture(ShaderProperties._ripplesLut_PROPERTY, rippleNormals);
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

        private double lastUpdateUT = 0d;

        public void Update()
        {
            if (registeredSurfaces.Count != 0 && HighLogic.LoadedScene != GameScenes.MAINMENU)
            {
                WetSurfacesConfig closestActive = GetClosestActive();

                bool activeConfigChanged = closestActive != activeConfig;

                if (activeConfigChanged)
                {
                    var volume = registeredSurfaces[closestActive].surfaces.First().CloudsRaymarchedVolume;
                    OnActiveConfigChanged(closestActive, volume.PlanetRadius, volume.ParentTransform, volume.parentCelestialBody);
                }

                var ut = Planetarium.GetUniversalTime();
                var deltaTime = Tools.GetDeltaTime();

                // Catchup conditions
                bool fastForward = ut > (lastUpdateUT + 1000.0 * deltaTime) && deltaTime > 0.0;
                bool timeTravel = ut + 200.0d < lastUpdateUT; // Warp to next day overshoots sometimes causing this to trigger
                                                              // Add 200s tolerance to fix

                if (fastForward || timeTravel || activeConfigChanged)
                {
                    WetSurfacesManager.Log($"Wet surfaces catchup conditions triggered: Active config change {activeConfigChanged}, large time delta {fastForward}, time travel: {timeTravel}");
                    PerformCatchup();
                }
                else
                {
                    UpdateActiveWetSurfaceInstances();
                    UpdateRendering(deltaTime, closestActive);
                }

                lastUpdateUT = ut;
            }

            AddOrRemoveCameraScripts();
        }

        private WetSurfacesConfig GetClosestActive()
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

        private void OnActiveConfigChanged(WetSurfacesConfig wetSurfacesConfig, float planetRadius, Transform parentTransform, CelestialBody celestialBody)
        {
            wetEffectMaterial.SetFloat("puddlesTiling", 1f / wetSurfacesConfig.PuddleTextureScale);
            wetEffectMaterial.SetFloat("rippleTiling", 1f / wetSurfacesConfig.RippleScale);

            wetEffectMaterial.SetFloat("craftDiffuse", wetSurfacesConfig.Craft.WetDiffuse);
            wetEffectMaterial.SetFloat("craftSmoothness", wetSurfacesConfig.Craft.WetSmoothness);

            wetEffectMaterial.SetFloat("sceneryDiffuse", wetSurfacesConfig.Scenery.WetDiffuse);
            wetEffectMaterial.SetFloat("scenerySmoothness", wetSurfacesConfig.Scenery.WetSmoothness);

            wetEffectMaterial.SetFloat("terrainDiffuse", wetSurfacesConfig.Terrain.WetDiffuse);
            wetEffectMaterial.SetFloat("terrainSmoothness", wetSurfacesConfig.Terrain.WetSmoothness);

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
            activeCelestialBody = celestialBody;
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

        static bool tangentFrameInitialized = false;
        static Vector3d tangentFrameTangent = new Vector3d(0, 0, 0);
        static Vector3d tangentFrameBitangent = new Vector3d(0, 0, 0);
        static Vector3d tangentFrameNormal = new Vector3d(0, 0, 0);
        static Vector3d tangentFrameOrigin = new Vector3d(0, 0, 0);
        static Vector3d cumulatedTangentFrameOffset = new Vector3d(0, 0, 0);

        private void UpdateRendering(float deltaTime, WetSurfacesConfig wetSurfacesConfig)
        {
            currentCoverage = Mathf.Min(1f, currentCoverage);

            //if (currentCoverage > 0f || currentWetLevel > 0f || currentPuddleLevel > 0f)
            {
                if (currentCoverage > 0f)
                {
                    UpdateRipples(deltaTime);
                }

                UpdateCraftWetLevel(deltaTime);

                UpdateTerrainAndSceneryLevels(deltaTime, activeParentTransform.localToWorldMatrix);
                wetEffectMaterial.SetMatrix(ShaderProperties.worldToPlanetMatrix_PROPERTY, activeParentTransform.worldToLocalMatrix);
                wetEffectMaterial.SetInt(ShaderProperties.useRipples_PROPERTY, currentCoverage > 0f ? 1 : 0);

                UpdatePuddlesTangentFrame(activeParentTransform.worldToLocalMatrix, wetSurfacesConfig);
            }

            currentCoverage = 0f;
            activeAccumulationLayerCount = 0;
        }

        private void UpdatePuddlesTangentFrame(Matrix4x4 worldToPlanet, WetSurfacesConfig wetSurfacesConfig)
        {
            var referenceTransform = FlightGlobals.ActiveVessel ? FlightGlobals.ActiveVessel.transform : FlightCamera.fetch.mainCamera.transform;
            var referencePosition = referenceTransform != null ? referenceTransform.position : Vector3.zero;

            var positionInPlanetSpace = worldToPlanet * new Vector4(referencePosition.x, referencePosition.y, referencePosition.z, 1f);

            tangentFrameNormal = new Vector3(positionInPlanetSpace.x, positionInPlanetSpace.y, positionInPlanetSpace.z).normalized;

            if (tangentFrameInitialized)
            {
                tangentFrameTangent = Vector3d.Cross(tangentFrameBitangent, tangentFrameNormal).normalized;
            }
            else
            {
                var reference = Math.Abs(tangentFrameNormal.y) < 0.99d ? new Vector3d(0d, 1d, 0d) : new Vector3d(1d, 0d, 0d);
                tangentFrameTangent = Vector3d.Cross(reference, tangentFrameNormal).normalized;
                tangentFrameInitialized = true;
            }

            tangentFrameBitangent = Vector3d.Cross(tangentFrameNormal, tangentFrameTangent).normalized;

            var currentFrameOrigin = tangentFrameNormal * activeCelestialBody.Radius;

            var frameDelta = currentFrameOrigin - tangentFrameOrigin;
            Vector3d projectedFrameDelta = frameDelta - Vector3d.Dot(frameDelta, tangentFrameNormal) * tangentFrameNormal;  // Remove normal component
            Vector2d frameOffset = new Vector2d(Vector3d.Dot(tangentFrameTangent, projectedFrameDelta), Vector3d.Dot(tangentFrameBitangent, projectedFrameDelta));

            var sinTheta = Vector3d.Cross(tangentFrameOrigin.normalized, currentFrameOrigin.normalized).magnitude;
            var arcAngle = Math.Asin(Math.Max(Math.Min(sinTheta, 1.0), 0.0));
            var arcLength = activeCelestialBody.Radius * arcAngle;

            frameOffset = frameOffset.normalized * arcLength;

            if (double.IsNaN(frameOffset.x) || double.IsNaN(frameOffset.y))
            {
                frameOffset = Vector2d.zero;
            }

            cumulatedTangentFrameOffset += frameOffset;

            tangentFrameOrigin = currentFrameOrigin;

            wetEffectMaterial.SetVector(ShaderProperties.tangentFrameTangent_PROPERTY, (Vector3)tangentFrameTangent);
            wetEffectMaterial.SetVector(ShaderProperties.tangentFrameBitangent_PROPERTY, (Vector3)tangentFrameBitangent);
            wetEffectMaterial.SetVector(ShaderProperties.tangentFrameOrigin_PROPERTY, (Vector3)tangentFrameOrigin);

            var puddleTextureUVOffsets = cumulatedTangentFrameOffset / wetSurfacesConfig.PuddleTextureScale;

            wetEffectMaterial.SetVector(ShaderProperties.tangentFrameUVOffset_PROPERTY, new Vector3(
                                                        (float)(puddleTextureUVOffsets.x - Math.Truncate(puddleTextureUVOffsets.x)),
                                                        (float)(puddleTextureUVOffsets.y - Math.Truncate(puddleTextureUVOffsets.y)),
                                                        (float)(puddleTextureUVOffsets.z - Math.Truncate(puddleTextureUVOffsets.z))));
        }


        private void AddOrRemoveCameraScripts()
        {
            // If in pqs and active
            if (activeConfig != null && registeredSurfaces.ContainsKey(activeConfig) && activeCelestialBody.pqsController.isActive)
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
            else if(renderersAdded)
            {
                RemoveRenderers();
            }
        }

        private void RemoveRenderers()
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

        private void UpdateTerrainAndSceneryLevels(float deltaTime, Matrix4x4 planetToWorldMatrix)
        {
            if (activeParentTransform == null || activeConfig == null)
                return;

            accumulationMaterial.SetMatrix(ShaderProperties.planetToWorldMatrix_PROPERTY, planetToWorldMatrix);

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

        double NonLinearStepSize(double stepIndex, double invStepsSquared, double totalDistance)
        {
            // Remap every "sample" i from i/n to (i/n)^2
            // By developing formula for two steps ((i+1)/n)^2 - (i/n)^2, find the "step size" (2*i+1)/n^2
            return (2 * stepIndex + 1) * invStepsSquared * totalDistance;
        }

        double GetCelestialBodyRotationAngleAtUT(double ut, CelestialBody celestialBody)
        {
            return (celestialBody.initialRotation + (360.0 * celestialBody.rotPeriodRecip) * ut) % 360.0;
        }

        private void PerformCatchup()
        {
            var ut = Planetarium.GetUniversalTime();
            
            // Find max drying time
            var lowestDryingSpeed = Mathf.Min(Mathf.Min(activeConfig.Scenery.PuddleDryingSpeed, activeConfig.Scenery.WetnessDryingSpeed),
                                              Mathf.Min(activeConfig.Terrain.PuddleDryingSpeed, activeConfig.Terrain.WetnessDryingSpeed));

            // If it never dries or takes too long cap to ~1 month
            var capDryingTime = 2.5e6d;
            var dryingTime = lowestDryingSpeed > 0.0 ? Math.Min(1.0d / lowestDryingSpeed, capDryingTime) : capDryingTime;

            // Find the timestamp to start at, using the max drying time
            var startUt = System.Math.Max(ut - dryingTime, 0d);

            WetSurfacesManager.Log($"Wet surfaces history catchup initiated. From universal time {startUt} to {ut}, drying time {dryingTime}");
            
            int catchupSteps = 64;
            int stepsSquared = catchupSteps * catchupSteps;
            double invStepsSquared = 1.0d / stepsSquared;

            var catchupUt = startUt;

            // First clear the existing RT
            RenderTexture rt = RenderTexture.active;
            RenderTexture.active = trackingRT[true, false, 0];
            GL.Clear(false, true, Color.black);
            RenderTexture.active = trackingRT[false, false, 0];
            GL.Clear(false, true, Color.black);
            RenderTexture.active = rt;

            Stopwatch stopwatch = Stopwatch.StartNew();

            for (int i=0; i < catchupSteps; i++)
            {
                // Do non-linear mapping to find the time for the current step, we want to concentrate steps near the current time
                // And take larger steps at the start
                double stepSize = NonLinearStepSize(catchupSteps - 1 - i, invStepsSquared, dryingTime);
                catchupUt += stepSize;

                // For every time step, recompute the planet's rotation and the cloud transform relative to it
                // Technically we are only doing this because of the kill rotation optionand because clouds can rotate on multiple axes
                var celestialBodyRotationAngle = GetCelestialBodyRotationAngleAtUT(catchupUt, activeCelestialBody);

                activeAccumulationLayerCount = 0;

                // Now step through the registered cloud volumes and do the same logic as in regular accumulation
                foreach (var wetSurface in registeredSurfaces[activeConfig].surfaces)
                {
                    if (activeAccumulationLayerCount >= MAX_ACTIVE_ACCUMULATION_LAYERS)
                        continue;

                    var volume = wetSurface.CloudsRaymarchedVolume;
                    var timeFade = 1f;

                    if (volume.CloudsPQS.TimeSettings != null)
                    {
                        timeFade = volume.CloudsPQS.TimeSettings.GetFadeForUT(catchupUt);
                    }

                    if (timeFade <= 0.0f)
                        continue;

                    volume.CloudsPQS.GetMainRotationAtUT(catchupUt, celestialBodyRotationAngle, out var cloudQuat, out var cloudRotationMatrix);

                    activeAccumulationTextures[activeAccumulationLayerCount] = wetSurface.AccumulationTexture;
                    activeAccumulationTransforms[activeAccumulationLayerCount] = cloudRotationMatrix;
                    activeAccumulationFades[activeAccumulationLayerCount] = timeFade;

                    activeAccumulationLayerCount++;
                }

                // Integrate the tracking map levels
                // We don't need the planetToWorld matrix, we have the rotation of the cloud relative to it and that's all that matters
                // Accounting for KillBodyRot and any axes of rotation
                UpdateTerrainAndSceneryLevels((float)stepSize, Matrix4x4.identity); 
            }

            // For the craft/camera, I haven't rewritten the coverage sampling methods to work for any UT
            // So just accumulate the current drying/accumulation for the current position
            currentCraftWetLevel = 0f;
            UpdateActiveWetSurfaceInstances();
            UpdateCraftWetLevel((float)dryingTime);

            // Reset matrix for wet effect material
            wetEffectMaterial.SetMatrix(ShaderProperties.worldToPlanetMatrix_PROPERTY, activeParentTransform.worldToLocalMatrix);
            
            stopwatch.Stop();
            double elapsedSeconds = stopwatch.Elapsed.TotalSeconds;
            WetSurfacesManager.Log($"Catch up executed in {elapsedSeconds} seconds");
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

            rippleNormals.GenerateMips();

            ripplesLutMaterial.SetFloat(ShaderProperties.rainRipplesAmount_PROPERTY, currentCoverage);
        }

        // TODO
        public void SetEnabled(bool value)
        {
            // If disabled, remove renderer from camera, otherwise it will get added in Update
            if (value == false)
            {
                RemoveRenderers();
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

            quadMesh = Resources.GetBuiltinResource<Mesh>("Quad.fbx");

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
            if (mat != null && cam != null)
                mat.SetMatrix(ShaderProperties.CameraToWorld_PROPERTY, cam.cameraToWorldMatrix);
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
