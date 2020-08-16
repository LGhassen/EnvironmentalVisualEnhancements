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
    class DeferredVolumetricCloudsRenderer : MonoBehaviour //maybe rename this class
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
                    Debug.Log("Ghassen  Creating deferredRendererToScreen");
                    //here create it and init it
                    GameObject deferredRendererToScreenGO = new GameObject("EVE deferredRendererToScreen");
                    //deferredRendererToScreenGO.transform.parent = Camera.current.gameObject.transform;
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
        private RenderTexture targetRT; //target RT, 1/4 screen res to save performance

        

        //private CommandBuffer copyToScreenCommandBuffer; //commandBuffer to composite the results to screen, won't work because we don't control the renderqueue there

        //just add a static quad in this class, and enable it's meshrenderer when rendering is requested? (even if that reacts after 1 frame it's fine)

        //disable it onPostRender

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
                targetRT.useMipMap = true;
                targetRT.autoGenerateMips = false;
                targetRT.Create();

                isInitialized = true;
                Debug.Log("DeferredVolumetricCloudsRenderer initialized successfully!!!");
            }
        }

        public void EnableForThisFrame(MeshRenderer mr, Material mat)
        {
            if (isInitialized)
            {
                CommandBuffer cb = new CommandBuffer();
                cb.SetRenderTarget(targetRT);
                if (!renderingEnabled)
                {
                    //clear texture
                    cb.ClearRenderTarget(false, true, Color.black);

                    DeferredRendererToScreen.SetActive(true);
                    DeferredRendererToScreen.SetRenderTexture(targetRT);
                }
                cb.DrawRenderer(mr, mat); //does this still draw it with the active camera's stuff? yes, shader already takes into account depth buffer and all without any more work needed on my side
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
                //    //DeferredRendererToScreen.SetActive(false); //doesn't work, causes flickering, why?
                //}
            }

        }

        public void OnDestroy()
        {
            Debug.Log("OnDestroy called on ScreenCopyCommandBuffer");
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

        public void SetActive(bool active)
        {
            //Debug.Log("Ghassen DeferredRendererToScreen SetActive "+active.ToString());
            shadowMR.enabled = active;
        }

        public void OnWillRenderObject()
        {
            //Debug.Log("Ghassen DeferredRendererToScreen on will renderObject");
        }
    }
}
