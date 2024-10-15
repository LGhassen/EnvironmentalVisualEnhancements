using ShaderLoader;
using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;
using Utils;
using System.Linq;

namespace Atmosphere
{
    public class ScreenSpaceShadowsManager : MonoBehaviour
    {
        private static ScreenSpaceShadowsManager instance;
        public static ScreenSpaceShadowsManager Instance
        {
            get
            {
                if (instance == null)
                {
                    var go = GameObject.CreatePrimitive(PrimitiveType.Quad);
                    instance = go.AddComponent<ScreenSpaceShadowsManager>();
                    instance.Init();
                }

                return instance;
            }
        }

        private Dictionary<Camera, ScreenSpaceShadowsRenderer> cameraToShadowsRenderer = new Dictionary<Camera, ScreenSpaceShadowsRenderer>();

        private List<Material> cloud2DShadowMaterials = new List<Material>();
        private List<Material> eclipseMaterials = new List<Material>();

        private Material lightVolumeShadowMaterial = null;

        private Light sunLight, ivaLight;
        private Material downscaleDepthMaterial;

        private void Init()
        {
            SetupGameObject();

            TweakReflectionProbe();

            sunLight = Sun.Instance.GetComponent<Light>();

            GameEvents.OnCameraChange.Add(RegisterInternalCamera);

            downscaleDepthMaterial = new Material(ShaderLoaderClass.FindShader("EVE/DownscaleDepth"));
        }

        private void SetupGameObject()
        {
            gameObject.name = "EVE ScreenSpaceShadowsManager";
            gameObject.layer = (int)Tools.Layer.Local;
            
            if (FlightCamera.fetch != null)
            {
                gameObject.transform.localScale = new Vector3(0.0001f, 0.0001f, 0.0001f);
                gameObject.transform.parent = FlightCamera.fetch.transform;
            }

            var collider = gameObject.GetComponent<Collider>();
            if (collider != null)
            {
                Destroy(collider);
            }

            var mr = gameObject.GetComponent<MeshRenderer>();
            mr.material = new Material(ShaderLoaderClass.FindShader("EVE/InvisibleShadowCaster")); // Allows shadow commandBuffers to fire on reflection probe
            mr.shadowCastingMode = ShadowCastingMode.TwoSided;  // Won't actually cast shadows because zwrite is off, will just trigger the commandBuffer

            var mf = gameObject.GetComponent<MeshFilter>();
            mf.mesh.bounds = new Bounds(Vector3.zero, new Vector3(1e8f, 1e8f, 1e8f));
        }

        void TweakReflectionProbe()
        {
            var flightCamera = FlightCamera.fetch;
            if (flightCamera != null)
            {
                var reflectionProbe = flightCamera.reflectionProbe;
                if (reflectionProbe != null)
                {
                    var probeComponent = reflectionProbe.probeComponent;
                    if (probeComponent != null)
                    {
                        probeComponent.shadowDistance = Mathf.Max(0.01f, probeComponent.shadowDistance);  // Allows shadow commandBuffers to fire on reflection probe
                                                                                                          // Without rendering any of the expensive shadows/objects
                    }
                }
            }
        }

        private void RegisterCamera(Camera camera, bool isIvaCamera)
        {
            if (camera != null && !cameraToShadowsRenderer.ContainsKey(camera))
            {
                // Remove null entries from dictionary first, old internal camera references can become null
                cameraToShadowsRenderer = cameraToShadowsRenderer.Where(kv => kv.Key != null && kv.Value != null).
                                                                            ToDictionary(kv => kv.Key, kv => kv.Value);

                bool isReflectionProbeCamera = camera.name == "Reflection Probes Camera";

                cameraToShadowsRenderer[camera] = camera.gameObject.AddComponent<ScreenSpaceShadowsRenderer>();
                cameraToShadowsRenderer[camera].Init(isIvaCamera ? ivaLight : sunLight, isIvaCamera, isReflectionProbeCamera);

                UpdateRenderers();
            }
        }

        public void RegisterCloudShadowMaterial(Material mat)
        {
            if (mat != null && !cloud2DShadowMaterials.Contains(mat))
            {
                cloud2DShadowMaterials.Add(mat);
                UpdateRenderers();
            }
        }

        public void RegisterEclipseMaterial(Material mat)
        {
            if (mat != null && !eclipseMaterials.Contains(mat))
            {
                eclipseMaterials.Add(mat);
                UpdateRenderers();
            }
        }

        private bool lightVolumeShadowUsedThisFrame = false;
        private bool lightVolumeShadowEnabled = false;

        public void UpdateLightVolumeShadowMaterial(Material mat)
        {
            lightVolumeShadowUsedThisFrame = true;

            if (lightVolumeShadowMaterial == null && mat != null)
            {
                lightVolumeShadowMaterial = mat;
                
                lightVolumeShadowEnabled = true;
                UpdateRenderers();
            }
        }

        public void UnregisterCloudShadowMaterial(Material mat)
        {
            if (mat != null && cloud2DShadowMaterials.Contains(mat))
            {
                cloud2DShadowMaterials.Remove(mat);
                UpdateRenderers();
            }
        }

        public void UnregisterEclipseMaterial(Material mat)
        {
            if (mat != null && eclipseMaterials.Contains(mat))
            {
                eclipseMaterials.Remove(mat);
                UpdateRenderers();
            }
        }

        private void UpdateRenderers()
        {
            foreach (var renderer in cameraToShadowsRenderer.Values)
            {
                renderer.UpdateCommandBuffer(cloud2DShadowMaterials, eclipseMaterials, lightVolumeShadowEnabled ? lightVolumeShadowMaterial : null);
            }
        }

        public void OnWillRenderObject()
        {
            Camera cam = Camera.current;

            if (!cam)
                return;

            RegisterCamera(cam, false);
        }

        void Update()
        {
            if (lightVolumeShadowUsedThisFrame != lightVolumeShadowEnabled)
            {
                lightVolumeShadowEnabled = lightVolumeShadowUsedThisFrame;
                UpdateRenderers();
            }

            lightVolumeShadowUsedThisFrame = false;
        }

        public void RegisterInternalCamera(CameraManager.CameraMode cameraMode)
        {
            if (cameraMode == CameraManager.CameraMode.IVA && InternalCamera.Instance != null)
            {
                var ivaSun = InternalSpace.Instance.transform.Find("IVASun");

                if (ivaSun != null)
                {
                    ivaLight = ivaSun.GetComponent<Light>();
                }

                Camera internalCamera = InternalCamera.Instance.GetComponentInChildren<Camera>();
                RegisterCamera(internalCamera, true);
            }
        }

        // To be called by Scatterer to generate ocean shadows before rendering the ocean
        // Renders light volume and 2d cloud shadows, scatterer handles its own eclipses
        public bool AddOceanShadowCommands(CommandBuffer commandBuffer, int width, int height, int oceanShadowsTextureIdentifier)
        {
            if (lightVolumeShadowMaterial == null && cloud2DShadowMaterials.Count == 0)
            {
                return false;
            }

            // Get temporary RTs
            int downscaledOceanDepthIdentifier = Shader.PropertyToID("ScattererDownscaledOceanDepthTexture");
            int shadowsTextureId = Shader.PropertyToID("ScattererOceanShadowsTexture");

            commandBuffer.GetTemporaryRT(downscaledOceanDepthIdentifier, width / 2, height / 2, 0, FilterMode.Point, RenderTextureFormat.RFloat);
            commandBuffer.GetTemporaryRT(shadowsTextureId, width / 2, height / 2, 0, FilterMode.Bilinear, RenderTextureFormat.R8);

            // Downscale depth
            commandBuffer.SetGlobalTexture("_EVETextureToDownscale", oceanShadowsTextureIdentifier);
            commandBuffer.Blit(null, downscaledOceanDepthIdentifier, downscaleDepthMaterial, 1);
            commandBuffer.SetGlobalTexture("EVEShadowsDownscaledDepth", downscaledOceanDepthIdentifier);                // for shadows shader
            commandBuffer.SetGlobalTexture("ScattererDownscaledOceanDepthTexture", downscaledOceanDepthIdentifier);     // for ocean shader to upscale with

            // Clear shadows RT
            commandBuffer.SetRenderTarget(shadowsTextureId);
            commandBuffer.ClearRenderTarget(false, true, Color.white);

            // First render regular cloud shadows, then if lightVolumeShadowMaterial is present blend it in
            bool blendBetween2DShadowsAndLightVolume = lightVolumeShadowMaterial != null && cloud2DShadowMaterials.Count > 0;

            foreach (Material shadowMaterial in cloud2DShadowMaterials)
            {
                shadowMaterial.SetInt("BlendBetween2DShadowsAndLightVolume", blendBetween2DShadowsAndLightVolume ? 1 : 0);
                commandBuffer.Blit(null, shadowsTextureId, shadowMaterial);
            }

            if (lightVolumeShadowMaterial != null)
            {
                lightVolumeShadowMaterial.SetInt("BlendBetween2DShadowsAndLightVolume", blendBetween2DShadowsAndLightVolume ? 1 : 0);
                commandBuffer.Blit(null, shadowsTextureId, lightVolumeShadowMaterial);
            }

            commandBuffer.SetGlobalTexture("ScattererOceanShadowsTexture", shadowsTextureId);

            return true;
        }
    }

    class ScreenSpaceShadowsRenderer : MonoBehaviour
    {
        private Light light;
        private bool isIvaLight;
        private bool isReflectionProbeCamera;
        private Camera camera;

        private CommandBuffer renderingCommandBuffer;
        private CommandBuffer displayCommandBuffer;

        private int screenWidth, screenHeight;

        private Material blendScreenSpaceShadowsMaterial, downscaleDepthMaterial;

        public void Init(Light light, bool isIvaLight, bool isReflectionProbeCamera)
        {
            this.isIvaLight = isIvaLight;
            this.light = light;
            this.isReflectionProbeCamera = isReflectionProbeCamera;
            camera = gameObject.GetComponent<Camera>();

            SetRenderingResolution();

            renderingCommandBuffer = new CommandBuffer();
            displayCommandBuffer = new CommandBuffer();

            renderingCommandBuffer.name = $"EVE ScreenSpaceShadowsRenderer {camera.name} {light.name} rendering commandBuffer";
            displayCommandBuffer.name = $"EVE ScreenSpaceShadowsRenderer {camera.name} {light.name} display commandBuffer";

            blendScreenSpaceShadowsMaterial = new Material(ShaderLoaderClass.FindShader("EVE/BlendScreenSpaceShadows"));
            downscaleDepthMaterial = new Material(ShaderLoaderClass.FindShader("EVE/DownscaleDepth"));
        }

        private void SetRenderingResolution()
        {
            bool supportVR = VRUtils.VREnabled() && !isReflectionProbeCamera;

            if (supportVR)
            {
                VRUtils.GetEyeTextureResolution(out screenWidth, out screenHeight);
            }
            else
            {
                screenWidth = camera.pixelWidth;
                screenHeight = camera.pixelHeight;
            }
        }

        public void OnPreCull()
        {
            // TODO: the right events and shit for the non-deferred case

            if (renderingCommandBuffer != null)
            { 
                light.AddCommandBuffer(LightEvent.AfterScreenspaceMask, renderingCommandBuffer);
            }

            if (displayCommandBuffer != null)
            { 
                light.AddCommandBuffer(LightEvent.AfterScreenspaceMask, displayCommandBuffer);
            }
        }

        public void OnPostRender()
        {
            if (renderingCommandBuffer != null)
            {
                light.RemoveCommandBuffer(LightEvent.AfterScreenspaceMask, renderingCommandBuffer);
            }

            if (displayCommandBuffer != null)
            {
                light.RemoveCommandBuffer(LightEvent.AfterScreenspaceMask, displayCommandBuffer);
            }
        }

        public void UpdateCommandBuffer(List<Material> cloud2DShadowMaterials, List<Material> eclipseMaterials, Material lightVolumeShadowMaterial)
        {
            if (renderingCommandBuffer != null && displayCommandBuffer != null)
            { 
                renderingCommandBuffer.Clear();
                displayCommandBuffer.Clear();

                if (lightVolumeShadowMaterial != null || cloud2DShadowMaterials.Count > 0 || eclipseMaterials.Count > 0)
                {
                    int tempDownscaledDepthIdentifier = Shader.PropertyToID("Temp downscaled depth RT");
                    int tempShadowsRTIdentifier = Shader.PropertyToID("Temp screenspace shadows RT");

                    // Get temporary RTs
                    renderingCommandBuffer.GetTemporaryRT(tempDownscaledDepthIdentifier, screenWidth / 2, screenHeight / 2, 0, FilterMode.Point, RenderTextureFormat.RFloat);
                    renderingCommandBuffer.GetTemporaryRT(tempShadowsRTIdentifier, screenWidth / 2, screenHeight / 2, 0, FilterMode.Bilinear, RenderTextureFormat.R8);

                    // Downscale depth
                    renderingCommandBuffer.Blit(null, tempDownscaledDepthIdentifier, downscaleDepthMaterial, 0);
                    renderingCommandBuffer.SetGlobalTexture("EVEShadowsDownscaledDepth", tempDownscaledDepthIdentifier); // for shadows shader
                    renderingCommandBuffer.SetGlobalTexture("EVEDownscaledDepth", tempDownscaledDepthIdentifier);        // for upscaling/blending shader

                    // Clear shadows RT
                    renderingCommandBuffer.SetRenderTarget(tempShadowsRTIdentifier);
                    renderingCommandBuffer.ClearRenderTarget(false, true, Color.white);

                    // First render regular cloud shadows, then if lightVolumeShadowMaterial is present blend it in
                    bool blendBetween2DShadowsAndLightVolume = lightVolumeShadowMaterial != null && cloud2DShadowMaterials.Count > 0;

                    foreach (Material shadowMaterial in cloud2DShadowMaterials)
                    {
                        shadowMaterial.SetInt("BlendBetween2DShadowsAndLightVolume", blendBetween2DShadowsAndLightVolume ? 1 : 0);
                        renderingCommandBuffer.Blit(null, tempShadowsRTIdentifier, shadowMaterial);
                    }
            
                    if (lightVolumeShadowMaterial != null)
                    {
                        lightVolumeShadowMaterial.SetInt("BlendBetween2DShadowsAndLightVolume", blendBetween2DShadowsAndLightVolume ? 1 : 0);
                        renderingCommandBuffer.Blit(null, tempShadowsRTIdentifier, lightVolumeShadowMaterial);
                    }

                    // Last render eclipses with multiplicative blending
                    foreach (Material eclipseMaterial in eclipseMaterials)
                    {
                        renderingCommandBuffer.Blit(null, tempShadowsRTIdentifier, eclipseMaterial);
                    }

                    renderingCommandBuffer.SetGlobalTexture("EVEScreenSpaceShadows", tempShadowsRTIdentifier);

                    displayCommandBuffer.Blit(null, BuiltinRenderTextureType.CurrentActive, blendScreenSpaceShadowsMaterial);
                }
            }
        }
    }
}