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

        WetSurfacesRenderer nearCameraWetSurfacesRenderer, farCameraWetSurfacesRenderer;
        bool rendererAdded = false;

        float currentCoverage = 0f;

        public Material wetEffectMaterial, ripplesLutMaterial;

        public RenderTexture rippleGradientFlip, rippleGradientFlop, rippleNormals;

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

            if (!WetEffectShader)
            {
                WetSurfacesManager.Log("[Error] Wet surfaces shader not found, wet surface effects won't be available");
                return false;
            }

            wetSurfacesConfigObject = WetSurfacesManager.GetConfig(wetSurfacesConfig);

            if (wetSurfacesConfigObject == null)
                return false;

            cloudsRaymarchedVolume = volume;
            parentTransform = parent;

            wetEffectMaterial = new Material(WetEffectShader);
            ripplesLutMaterial = new Material(RipplesLutShader);

            if (wetSurfacesConfigObject.PuddlesTexture != null)
                wetSurfacesConfigObject.PuddlesTexture.ApplyTexture(wetEffectMaterial, "_puddlesTexture");

            // assign properties?
            wetEffectMaterial.SetFloat("puddlesAmount", 1f); // to be overridden by coverage and stuff
            wetEffectMaterial.SetFloat("WetLevel", 1f); // to be overridden by coverage and stuff

            wetEffectMaterial.SetFloat("puddlesTiling", 1f / wetSurfacesConfigObject.PuddleTextureScale);
            wetEffectMaterial.SetFloat("rippleTiling", 1f / wetSurfacesConfigObject.RippleScale);

            ripplesLutMaterial.SetFloat("rainRipplesAmount", 1f); // to be overridden by coverage and stuff

            if (rippleGradientFlip != null && rippleGradientFlip.IsCreated())
                rippleGradientFlip.Release();

            rippleGradientFlip = RenderTextureUtils.CreateRenderTexture(1024, 1024, RenderTextureFormat.R8, false, FilterMode.Bilinear);

            if (rippleGradientFlop != null && rippleGradientFlop.IsCreated())
                rippleGradientFlop.Release();

            rippleGradientFlop = RenderTextureUtils.CreateRenderTexture(1024, 1024, RenderTextureFormat.R8, false, FilterMode.Bilinear);

            if (rippleNormals != null && rippleNormals.IsCreated())
                rippleNormals.Release();

            rippleNormals = RenderTextureUtils.CreateRenderTexture(1024, 1024, RenderTextureFormat.RG16, true, FilterMode.Bilinear);

            return true;
        }

        public void Remove()
        {
            RemoveRenderer();

            if (rippleGradientFlip != null && rippleGradientFlip.IsCreated())
                rippleGradientFlip.Release();

            if (rippleGradientFlop != null && rippleGradientFlop.IsCreated())
                rippleGradientFlop.Release();

            if (rippleNormals != null && rippleNormals.IsCreated())
                rippleNormals.Release();
        }

        public void Update()
        {
            // if enabled and wetness above zero, draw effect to gbuffer, no need to recreate the commandBuffer every frame maybe?
            Vector3 positionToSample = Vector3.zero;

            if (FlightGlobals.ActiveVessel != null)
                positionToSample = FlightGlobals.ActiveVessel.transform.position;

            currentCoverage = cloudsRaymarchedVolume.SampleCoverage(positionToSample, out float cloudType);
            //currentCoverage = Mathf.Clamp01((currentCoverage - wetSurfacesConfigObject.MinCoverageThreshold) / (wetSurfacesConfigObject.MaxCoverageThreshold - wetSurfacesConfigObject.MinCoverageThreshold));

            if (currentCoverage > 0f)
                currentCoverage *= cloudsRaymarchedVolume.GetInterpolatedCloudTypeWetSurfacesDensity(cloudType);

            // for now just traight up hook current coverage to wetness, just for testing

            //if (currentCoverage > 0f)
            {
                // update ripples lut

                Graphics.Blit(null, rippleGradientFlip, ripplesLutMaterial, 0);

                ripplesLutMaterial.SetTexture("ripplesInputTexture", rippleGradientFlip);
                Graphics.Blit(null, rippleGradientFlop, ripplesLutMaterial, 1);

                ripplesLutMaterial.SetTexture("ripplesInputTexture", rippleGradientFlop);
                Graphics.Blit(null, rippleGradientFlip, ripplesLutMaterial, 2);

                ripplesLutMaterial.SetTexture("ripplesInputTexture", rippleGradientFlip);
                Graphics.Blit(null, rippleNormals, ripplesLutMaterial, 3);

                rippleNormals.GenerateMips();
                wetEffectMaterial.SetTexture("_ripplesLut", rippleNormals);


                // Update material

                //Debug.Log("WetSurface coverage " + currentCoverage.ToString());

                //wetEffectMaterial.SetFloat("puddlesAmount", Mathf.Clamp01(2f * (currentCoverage - 0.5f)));  // to be overridden by coverage and stuff
                //wetEffectMaterial.SetFloat("WetLevel", Mathf.Clamp01(2f * currentCoverage));                // to be overridden by coverage and stuff

                wetEffectMaterial.SetFloat("puddlesAmount", wetSurfacesConfigObject.MaxCoverageThreshold);  // to be overridden by coverage and stuff
                wetEffectMaterial.SetFloat("WetLevel", wetSurfacesConfigObject.MinCoverageThreshold);                // to be overridden by coverage and stuff

                wetEffectMaterial.SetVector("upVector", -parentTransform.position.normalized);

                if (!rendererAdded || nearCameraWetSurfacesRenderer == null)
                {
                    var nearCamera = Camera.allCameras.Where(x => x.name == "Camera 00").FirstOrDefault();
                    if (nearCamera != null)
                    {
                        nearCameraWetSurfacesRenderer = nearCamera.gameObject.AddComponent<WetSurfacesRenderer>();
                        nearCameraWetSurfacesRenderer.SetMaterial(wetEffectMaterial);
                    }

                    if (!Tools.IsUnifiedCameraMode() && farCameraWetSurfacesRenderer == null)
                    {
                        var farCamera = Camera.allCameras.Where(x => x.name == "Camera 01").FirstOrDefault();

                        if (farCamera != null)
                        {
                            farCameraWetSurfacesRenderer = farCamera.gameObject.AddComponent<WetSurfacesRenderer>();
                            farCameraWetSurfacesRenderer.SetMaterial(wetEffectMaterial);
                        }
                    }

                    rendererAdded = true;
                }
            }
            /*
            else if (rendererAdded)
            {
                RemoveRenderer();
            }
            */

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
            wetEffectCommandBuffer.GetTemporaryRT(tempRT2, screenWidth, screenHeight, 0, FilterMode.Point, RenderTextureFormat.ARGB2101010);

            // Copy GBuffers
            wetEffectCommandBuffer.Blit(BuiltinRenderTextureType.GBuffer1, tempRT1);
            wetEffectCommandBuffer.Blit(BuiltinRenderTextureType.GBuffer2, tempRT2);

            wetEffectCommandBuffer.SetGlobalTexture("_originalGbuffer1Texture", tempRT1);
            wetEffectCommandBuffer.SetGlobalTexture("_originalGbuffer2Texture", tempRT2);

            RenderTargetIdentifier[] gbufferIdentifiers = { BuiltinRenderTextureType.GBuffer0, BuiltinRenderTextureType.GBuffer1, BuiltinRenderTextureType.GBuffer2 };
            wetEffectCommandBuffer.SetRenderTarget(gbufferIdentifiers, BuiltinRenderTextureType.CameraTarget);

            wetEffectCommandBuffer.DrawMesh(quadMesh, Matrix4x4.identity, mat, 0, 0); // Pass 0: Parts and Kerbals, wet effect only, no puddles

            wetEffectCommandBuffer.DrawMesh(quadMesh, Matrix4x4.identity, mat, 0, 1); // Pass 1: Terrain and scenery, wet + puddles

            //wetEffectCommandBuffer.DrawMesh(quadMesh, Matrix4x4.identity, mat, 0, 2); // Pass 2: Scenery with unreliable per-pixel normals like KSC runways (all normals point up so that different parts of runway connect seamlessly)
                                                                                      // wet + puddles but puddles based on depth-based normals

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
                    mat.SetMatrix("CameraToWorld", cam.cameraToWorldMatrix);

                mat.SetVector("floatingOriginOffset", new Vector3((float)FloatingOrigin.TerrainShaderOffset.x,
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