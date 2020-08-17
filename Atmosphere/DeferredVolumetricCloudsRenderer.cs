using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using UnityEngine.Rendering;
using ShaderLoader;
using Utils;

namespace Atmosphere
{
    class DeferredVolumetricCloudsRenderer : MonoBehaviour
    {
        private static Dictionary<Camera, DeferredVolumetricCloudsRenderer> CameraToDeferredVolumetricCloudsRenderer = new Dictionary<Camera, DeferredVolumetricCloudsRenderer>();

        public static void EnableForThisFrame(Camera cam, MeshRenderer mr, Material mat)
        {
            if (CameraToDeferredVolumetricCloudsRenderer.ContainsKey(cam))
            {
                CameraToDeferredVolumetricCloudsRenderer[cam].EnableForThisFrame(mr, mat);
            }
            else
            {
                CameraToDeferredVolumetricCloudsRenderer[cam] = (DeferredVolumetricCloudsRenderer)cam.gameObject.AddComponent(typeof(DeferredVolumetricCloudsRenderer));
            }
        }

        private static DeferredRendererToScreen deferredRendererToScreen;

        public static DeferredRendererToScreen DeferredRendererToScreen
        {
            get
            {
                if(deferredRendererToScreen == null)
                {
                    GameObject deferredRendererToScreenGO = new GameObject("EVE deferredRendererToScreen");
                    deferredRendererToScreen = deferredRendererToScreenGO.AddComponent<DeferredRendererToScreen>();
                    deferredRendererToScreen.Init();
                }
                return deferredRendererToScreen;
            }
        }

        bool renderingEnabled = false;
        bool isInitialized = false;

        private Camera targetCamera;
        private List<CommandBuffer> commandBuffersAdded = new List<CommandBuffer>();
        private RenderTexture targetRT;             //target RT, 1/4 screen res to save performance
        private RenderTexture downscaledDepthRT;
        Material downscaleDepthMaterial;

        public DeferredVolumetricCloudsRenderer()
        {
        }

        public void Initialize()
        {
            targetCamera = GetComponent<Camera>();

            if (!ReferenceEquals(targetCamera.activeTexture, null))
            {
                targetRT = new RenderTexture(targetCamera.activeTexture.width / 2, targetCamera.activeTexture.height / 2, 0, RenderTextureFormat.ARGB32);
                targetRT.anisoLevel = 1;
                targetRT.antiAliasing = 1;
                targetRT.volumeDepth = 0;
                targetRT.useMipMap = false;
                targetRT.autoGenerateMips = false;
                targetRT.Create();
                targetRT.filterMode = FilterMode.Point; //might need a way to access both point and bilinear

                downscaledDepthRT = new RenderTexture(targetCamera.activeTexture.width / 2, targetCamera.activeTexture.height / 2, 0, RenderTextureFormat.RFloat);
                downscaledDepthRT.anisoLevel = 1;
                downscaledDepthRT.antiAliasing = 1;
                downscaledDepthRT.volumeDepth = 0;
                downscaledDepthRT.useMipMap = false;
                downscaledDepthRT.autoGenerateMips = false;
                downscaledDepthRT.Create();

                downscaledDepthRT.filterMode = FilterMode.Point;

                downscaleDepthMaterial = new Material(ShaderLoaderClass.FindShader("EVE/DownscaleDepth"));

                isInitialized = true;
            }
        }

        public void EnableForThisFrame(MeshRenderer mr, Material mat)
        {
            if (isInitialized)
            {
                CommandBuffer cb = new CommandBuffer();
                
                if (!renderingEnabled)
                {
                    DeferredRendererToScreen.SetActive(true);
                    DeferredRendererToScreen.SetRenderTexture(targetRT);

                    //downscale depth
                    cb.Blit(null, downscaledDepthRT, downscaleDepthMaterial);
                    cb.SetGlobalTexture("EVEDownscaledDepth", downscaledDepthRT);
                    DeferredRendererToScreen.SetDepthTexture(downscaledDepthRT);

                    //clear target rendertexture
                    cb.SetRenderTarget(targetRT);
                    cb.ClearRenderTarget(false, true, Color.black);
                }

                cb.DrawRenderer(mr, mat);
                targetCamera.AddCommandBuffer(CameraEvent.AfterForwardOpaque, cb);
                commandBuffersAdded.Add(cb);
                renderingEnabled = true;
            }
        }

        void OnPostRender()
        {
            if (!isInitialized)
            {
                Initialize();
            }
            else
            {
                if (renderingEnabled)
                {
                    foreach (var cb in commandBuffersAdded)
                    {
                        targetCamera.RemoveCommandBuffer(CameraEvent.AfterForwardOpaque, cb);
                    }
                    commandBuffersAdded.Clear();
                    renderingEnabled = false;
                }
                //else
                //{
                //    //if rendering was disabled for this frame set deferred copier to disabled
                //    //DeferredRendererToScreen.SetActive(false); //doesn't work, causes flickering, why? doesn't work because OnPostRender is not called if there is no rendering
                //}
            }

        }

        public void OnDestroy()
        {
            if (!ReferenceEquals(targetCamera, null))
            {
                targetRT.Release();

                foreach (var cb in commandBuffersAdded)
                {
                    targetCamera.RemoveCommandBuffer(CameraEvent.AfterForwardOpaque, cb);
                }
                commandBuffersAdded.Clear();

                renderingEnabled = false;
            }
        }
    }

    public class DeferredRendererNotifier : MonoBehaviour
    {
        MeshRenderer mr;
        public Material mat;

        public DeferredRendererNotifier()
        {
            mr = gameObject.GetComponent<MeshRenderer>();
        }

        void OnWillRenderObject()
        {
            if (mat != null)
                DeferredVolumetricCloudsRenderer.EnableForThisFrame(Camera.current, mr, mat );
        }
    }

    public class DeferredRendererToScreen : MonoBehaviour
    {
        Material material;

        MeshRenderer shadowMR;

        public void Init()
        {
            material = new Material(ShaderLoaderClass.FindShader("EVE/CompositeDeferredClouds"));

            Quad.Create(gameObject, 2, Color.white, Vector3.up, Mathf.Infinity);

            shadowMR = gameObject.AddComponent<MeshRenderer>();
            material.SetOverrideTag("IgnoreProjector", "True");
            shadowMR.sharedMaterial = material;

            shadowMR.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            shadowMR.receiveShadows = false;
            shadowMR.enabled = true;

            gameObject.layer = (int)Tools.Layer.Local;
        }

        public void SetRenderTexture(RenderTexture RT)
        {
            material.SetTexture("cloudTexture", RT);
        }

        public void SetDepthTexture(RenderTexture RT)
        {
            material.SetTexture("EVEDownscaledDepth", RT);
        }

        public void SetActive(bool active)
        {
            shadowMR.enabled = active;
        }

        public void OnWillRenderObject()
        {
            
        }
    }
}
