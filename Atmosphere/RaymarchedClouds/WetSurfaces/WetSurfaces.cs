using UnityEngine;
using Utils;
using ShaderLoader;
using UnityEngine.Rendering;
using System;
using System.Linq;

namespace Atmosphere
{
    public class WetSurfaces
    {
        [ConfigItem]
        string wetSurfacesConfig = "";

        WetSurfacesConfig wetSurfacesConfigObject = null;

        CloudsRaymarchedVolume cloudsRaymarchedVolume = null;

        Transform parentTransform;

        //float currentCoverage = 0f;
        //float currentWetness = 0f;

        //bool cloudLayerEnabled = false;

        WetSurfacesRenderer nearCameraWetSurfacesRenderer, farCameraWetSurfacesRenderer;
        bool rendererAdded = false;

        float currentCoverage = 0f;

        public Material wetEffectMaterial;

        static Shader wetEffectShader = null;
        static Shader WetEffectShader
        {
            get
            {
                if (wetEffectShader == null) wetEffectShader = ShaderLoaderClass.FindShader("EVE/GBufferWetEffect");
                return wetEffectShader;
            }
        }

        bool CheckDeferredInstalled()
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

        public bool Apply(Transform parent, CloudsRaymarchedVolume volume)
        {
            if (!CheckDeferredInstalled())
            {
                WetSurfacesManager.Log("[Error] Deferred not installed, wet surface effects won't be available");
                return false;
            }

            wetSurfacesConfigObject = WetSurfacesManager.GetConfig(wetSurfacesConfig);

            if (wetSurfacesConfigObject == null)
                return false;

            cloudsRaymarchedVolume = volume;
            parentTransform = parent;

            //InitMaterials();
            //InitGameObjects(parent);

            // Init material
            wetEffectMaterial = new Material(wetEffectShader);

            // assign texture
            if (wetSurfacesConfigObject.PuddlesTexture != null)
                wetSurfacesConfigObject.PuddlesTexture.ApplyTexture(wetEffectMaterial, "_puddlesTexture");

            // assign properties?
            wetEffectMaterial.SetFloat("puddlesAmount", 1f); // to be overridden by coverage and stuff
            wetEffectMaterial.SetFloat("WetLevel", 1f); // to be overridden by coverage and stuff
            wetEffectMaterial.SetFloat("rainRipplesAmount", 1f); // to be overridden by coverage and stuff

            wetEffectMaterial.SetFloat("puddlesTiling", 1f / wetSurfacesConfigObject.PuddleTextureScale);

            return true;
        }

        public void Remove()
        {
            RemoveRenderer();
        }

        public void Update()
        {
            // if enabled and wetness above zero, draw effect to gbuffer, no need to recreate the commandBuffer every frame maybe?

            currentCoverage = cloudsRaymarchedVolume.SampleCoverage(FlightGlobals.ActiveVessel.transform.position, out float cloudType);
            currentCoverage = Mathf.Clamp01((currentCoverage - wetSurfacesConfigObject.MinCoverageThreshold) / (wetSurfacesConfigObject.MaxCoverageThreshold - wetSurfacesConfigObject.MinCoverageThreshold));

            if (currentCoverage > 0f)
                currentCoverage *= cloudsRaymarchedVolume.GetInterpolatedCloudTypeWetSurfacesDensity(cloudType);

            // for now just traight up hook current coverage to wetness, just for testing

            if (currentCoverage > 0f)
            {
                // Update material

                wetEffectMaterial.SetFloat("puddlesAmount", Mathf.Clamp01(2f * (currentCoverage - 0.5f)));  // to be overridden by coverage and stuff
                wetEffectMaterial.SetFloat("WetLevel", Mathf.Clamp01(2f * currentCoverage));                // to be overridden by coverage and stuff

                wetEffectMaterial.SetVector("upVector", -parentTransform.position.normalized);

                if (!rendererAdded)
                {
                    var nearCamera = Camera.allCameras.Where(x => x.name == "Camera 00").FirstOrDefault();
                    if (nearCamera != null)
                    {
                        nearCameraWetSurfacesRenderer = nearCamera.gameObject.AddComponent<WetSurfacesRenderer>();
                        nearCameraWetSurfacesRenderer.SetMaterial(wetEffectMaterial);
                    }

                    if (Tools.IsUnifiedCameraMode())
                    {
                        var farCamera = Camera.allCameras.Where(x => x.name == "Camera 00").FirstOrDefault();

                        if (farCamera != null)
                        {
                            farCameraWetSurfacesRenderer = farCamera.gameObject.AddComponent<WetSurfacesRenderer>();
                            farCameraWetSurfacesRenderer.SetMaterial(wetEffectMaterial);
                        }
                    }

                    rendererAdded = true;
                }
            }
            else if (rendererAdded)
            {
                RemoveRenderer();
            }

        }

        private void RemoveRenderer()
        {
            if (nearCameraWetSurfacesRenderer != null)
            {
                Component.Destroy(nearCameraWetSurfacesRenderer);
            }

            if (farCameraWetSurfacesRenderer != null)
            {
                Component.Destroy(farCameraWetSurfacesRenderer);
            }

            rendererAdded = false;
        }

        public void SetEnabled(bool value)
        {
            // If disabled, remove renderer from camera, otherwise it will get added in Update
            if (value == false)
            {
                RemoveRenderer();
            }
        }
    }

    public class WetSurfacesRenderer : MonoBehaviour
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

            // TODO: consolidate the two rendertextures by copying only what we need from Gbuffer

            // Define a temporary render texture
            int tempRT1 = Shader.PropertyToID("_TempRTGbuffer1");
            wetEffectCommandBuffer.GetTemporaryRT(tempRT1, screenWidth, screenHeight, 0, FilterMode.Point, RenderTextureFormat.ARGB32);

            int tempRT2 = Shader.PropertyToID("_TempRTGbuffer2");
            wetEffectCommandBuffer.GetTemporaryRT(tempRT2, screenWidth, screenHeight, 0, FilterMode.Point, RenderTextureFormat.ARGB32);

            // Copy GBuffers
            wetEffectCommandBuffer.Blit(BuiltinRenderTextureType.GBuffer1, tempRT1);
            wetEffectCommandBuffer.Blit(BuiltinRenderTextureType.GBuffer2, tempRT2);

            wetEffectCommandBuffer.SetGlobalTexture("_originalGbuffer1Texture", tempRT1);
            wetEffectCommandBuffer.SetGlobalTexture("_originalGbuffer2Texture", tempRT2);

            wetEffectCommandBuffer.SetGlobalMatrix("CameraToWorld", cam.cameraToWorldMatrix);

            RenderTargetIdentifier[] gbufferIdentifiers = { BuiltinRenderTextureType.GBuffer0, BuiltinRenderTextureType.GBuffer1, BuiltinRenderTextureType.GBuffer2 };
            wetEffectCommandBuffer.SetRenderTarget(gbufferIdentifiers, BuiltinRenderTextureType.None);

            wetEffectCommandBuffer.DrawMesh(quadMesh, Matrix4x4.identity, mat, 0, 0);

            cam.AddCommandBuffer(CameraEvent.BeforeReflections, wetEffectCommandBuffer);

            isInitialized = true;
        }

        void Remove()
        {
            if (wetEffectCommandBuffer != null)
                cam.RemoveCommandBuffer(CameraEvent.BeforeReflections, wetEffectCommandBuffer);
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