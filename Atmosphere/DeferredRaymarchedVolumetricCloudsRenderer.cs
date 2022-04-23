using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using UnityEngine.Rendering;
using ShaderLoader;
using Utils;
using System.Collections;


namespace Atmosphere
{
    class DeferredRaymarchedVolumetricCloudsRenderer : MonoBehaviour
    {
        private static Dictionary<Camera, DeferredRaymarchedVolumetricCloudsRenderer> CameraToDeferredRaymarchedVolumetricCloudsRenderer = new Dictionary<Camera, DeferredRaymarchedVolumetricCloudsRenderer>();

        public static void EnableForThisFrame(Camera cam, MeshRenderer mr, Material mat)
        {
            if (CameraToDeferredRaymarchedVolumetricCloudsRenderer.ContainsKey(cam))
            {
                CameraToDeferredRaymarchedVolumetricCloudsRenderer[cam].EnableForThisFrame(mr, mat);
            }
            else
            {
                CameraToDeferredRaymarchedVolumetricCloudsRenderer[cam] = (DeferredRaymarchedVolumetricCloudsRenderer)cam.gameObject.AddComponent(typeof(DeferredRaymarchedVolumetricCloudsRenderer));
            }
        }

        private static DeferredRendererToScreen deferredRendererToScreen;

        public static DeferredRendererToScreen DeferredRendererToScreen
        {
            get
            {
                if(deferredRendererToScreen == null)
                {
                    GameObject deferredRendererToScreenGO = new GameObject("EVE deferredRaymarchedRendererToScreen");
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
        private RenderTexture targetRT;             //TODO: replace this with the reprojection RT and the flip flop RTs

        Material downscaleDepthMaterial;

        // pairs of volumetric clouds renderers and their materials, sorted by distance, for rendering farthest to closest        
        SortedList<float, Tuple<Renderer, Material>> renderersAdded = new SortedList<float, Tuple<Renderer, Material>>();

        public DeferredRaymarchedVolumetricCloudsRenderer()
        {
        }

        public void Initialize()
        {
            targetCamera = GetComponent<Camera>();

            if (!ReferenceEquals(targetCamera.activeTexture, null))
            {
                /*
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
                */
            }
        }

        public void EnableForThisFrame(MeshRenderer mr, Material mat)
        {
            if (isInitialized)
            {
                if (!renderingEnabled)
                {
                    /*
                    CommandBuffer cb = new CommandBuffer();

                    DeferredRendererToScreen.SetActive(true);
                    DeferredRendererToScreen.SetRenderTexture(targetRT);

                    //downscale depth
                    cb.Blit(null, downscaledDepthRT, downscaleDepthMaterial);
                    cb.SetGlobalTexture("EVEDownscaledDepth", downscaledDepthRT);
                    DeferredRendererToScreen.SetDepthTexture(downscaledDepthRT);

                    //clear target rendertexture
                    cb.SetRenderTarget(targetRT);
                    cb.ClearRenderTarget(false, true, Color.gray);

                    targetCamera.AddCommandBuffer(CameraEvent.AfterForwardOpaque, cb);

                    commandBuffersAdded.Add(cb);
                    */
                }

                renderersAdded.Add(mr.gameObject.transform.position.magnitude, new Tuple<Renderer, Material>(mr, mat));

                renderingEnabled = true;
            }
        }

        void OnPreRender()
        {
            if (renderingEnabled)
            {
                /*
                foreach (var elt in renderersAdded.Reverse())           //sort cloud layers by decreasing distance to camera and render them farthest to closest, // should do these but to composite to the screen, at least for now, or just do it later, for now get a single layer working ffs
                {
                    CommandBuffer cb = new CommandBuffer();

                    cb.SetRenderTarget(targetRT);
                    cb.DrawRenderer(elt.Value.Item1, elt.Value.Item2);

                    targetCamera.AddCommandBuffer(CameraEvent.AfterForwardOpaque, cb);

                    commandBuffersAdded.Add(cb);
                }
                */
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
                    renderersAdded.Clear();

                    DeferredRendererToScreen.SetActive(false);
                    renderingEnabled = false;
                }
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
}
