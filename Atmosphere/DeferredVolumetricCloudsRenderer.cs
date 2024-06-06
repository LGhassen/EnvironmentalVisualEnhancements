﻿using System;
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

        // pairs of volumetric clouds renderers and their materials, sorted by distance, for rendering farthest to closest        
        SortedList<float, Tuple<Renderer, Material>> renderersAdded = new SortedList<float, Tuple<Renderer, Material>>();

        private static CameraEvent CloudRenderingCameraEvent = CameraEvent.AfterForwardOpaque;

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
                renderersAdded.Add(mr.gameObject.transform.position.magnitude, new Tuple<Renderer, Material>(mr, mat));

                renderingEnabled = true;
            }
        }

        void OnPreRender()
        {
            if (renderingEnabled)
            {
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

                foreach (var elt in renderersAdded.Reverse())           //sort cloud layers by decreasing distance to camera and render them farthest to closest
                {
                    cb.DrawRenderer(elt.Value.Item1, elt.Value.Item2);
                }

                targetCamera.AddCommandBuffer(CloudRenderingCameraEvent, cb);
                commandBuffersAdded.Add(cb);
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
                        targetCamera.RemoveCommandBuffer(CloudRenderingCameraEvent, cb);
                    }
                    commandBuffersAdded.Clear();

                    if (targetCamera.stereoActiveEye != Camera.MonoOrStereoscopicEye.Left)
                    {
                        renderersAdded.Clear();

                        DeferredRendererToScreen.SetActive(false);
                        renderingEnabled = false;
                    }
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
                    targetCamera.RemoveCommandBuffer(CloudRenderingCameraEvent, cb);
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
            
        }

        public void Init()
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

        MeshRenderer compositeMR;

        public void Init()
        {
            material = new Material(ShaderLoaderClass.FindShader("EVE/CompositeDeferredClouds"));

            Quad.Create(gameObject, 2, Color.white, Vector3.up, Mathf.Infinity);

            compositeMR = gameObject.AddComponent<MeshRenderer>();
            material.SetOverrideTag("IgnoreProjector", "True");
            compositeMR.sharedMaterial = material;

            compositeMR.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            compositeMR.receiveShadows = false;
            compositeMR.enabled = true;
            material.SetFloat(ShaderProperties.rendererEnabled_PROPERTY, 0f);

            gameObject.layer = (int)Tools.Layer.Local;
        }

        public void SetRenderTexture(RenderTexture RT)
        {
            material.SetTexture("cloudTexture", RT);    //TODO: shader properties
        }

        public void SetDepthTexture(RenderTexture RT)
        {
            material.SetTexture("EVEDownscaledDepth", RT);
        }

        public void SetActive(bool active)
        {
            material.SetFloat(ShaderProperties.rendererEnabled_PROPERTY, active ? 1f : 0f);
        }
    }
}
