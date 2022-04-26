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

        public static void EnableForThisFrame(Camera cam, CloudsRaymarchedVolume volume)
        {
            if (CameraToDeferredRaymarchedVolumetricCloudsRenderer.ContainsKey(cam))
            {
                var renderer = CameraToDeferredRaymarchedVolumetricCloudsRenderer[cam];
                if (renderer != null)
                    renderer.EnableForThisFrame(volume);
            }
            else
            {
                // add null to the cameras we don't want to render on so we don't do a string compare every time
                if ((cam.name == "TRReflectionCamera") || (cam.name == "Reflection Probes Camera"))
                {
                    CameraToDeferredRaymarchedVolumetricCloudsRenderer[cam] = null;
                }
                else
                {
                    CameraToDeferredRaymarchedVolumetricCloudsRenderer[cam] = (DeferredRaymarchedVolumetricCloudsRenderer)cam.gameObject.AddComponent(typeof(DeferredRaymarchedVolumetricCloudsRenderer));
                }
            }
        }

        private static DeferredRaymarchedRendererToScreen deferredRaymarchedRendererToScreen;

        public static DeferredRaymarchedRendererToScreen DeferredRaymarchedRendererToScreen
        {
            get
            {
                if(deferredRaymarchedRendererToScreen == null)
                {
                    GameObject deferredRendererToScreenGO = new GameObject("EVE deferredRaymarchedRendererToScreen");
                    deferredRaymarchedRendererToScreen = deferredRendererToScreenGO.AddComponent<DeferredRaymarchedRendererToScreen>();
                    deferredRaymarchedRendererToScreen.Init();
                }
                return deferredRaymarchedRendererToScreen;
            }
        }

        bool renderingEnabled = false;
        bool isInitialized = false;

        private Camera targetCamera;
        private CommandBuffer commandBuffer;

        // list of volumes sorted by distance, for rendering closest to farthest, such that already occluded layers in the distance don't add any raymarching cost
        List<CloudsRaymarchedVolume> volumesAdded = new List<CloudsRaymarchedVolume>();

        private RenderTexture historyFlipRT, historyFlopRT, newDistanceFlipRT, newDistanceFlopRT, newRaysFlipRT, newRaysFlopRT;
        bool useFlipBuffer = true;
        Material reconstructCloudsMaterial;

        Matrix4x4 previousV = Matrix4x4.identity;
        Matrix4x4 previousP = Matrix4x4.identity;


        int reprojectionXfactor = 4;
        int reprojectionYfactor = 2;

        //int reprojectionXfactor = 1;
        //int reprojectionYfactor = 1;

        //manually made sampling sequences that distribute samples in a cross pattern for reprojection
        int[] samplingSequence4 = new int[] { 0, 2, 3, 1 };
        int[] samplingSequence8 = new int[] { 0, 4, 2, 6, 3, 7, 1, 5 };
        int[] samplingSequence16 = new int[] { 0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5 };

        private static Shader reconstructCloudShader = null;
        private static Shader ReconstructionShader
        {
            get
            {
                if (reconstructCloudShader == null)
                {
                    reconstructCloudShader = ShaderLoaderClass.FindShader("EVE/ReconstructRaymarchedClouds");
                }
                return reconstructCloudShader;
            }
        }

        /*
        private static Shader compositeRaymarchedCloudShader = null;
        private static Shader CompositeRaymarchedCloudShader
        {
            get
            {
                if (compositeRaymarchedCloudShader == null)
                {
                    compositeRaymarchedCloudShader = ShaderLoaderClass.FindShader("EVE/CompositeRaymarchedClouds");
                }
                return compositeRaymarchedCloudShader;
            }
        }
        */

        public DeferredRaymarchedVolumetricCloudsRenderer()
        {
        }

        public void Initialize()
        {
            targetCamera = GetComponent<Camera>();
            if (!ReferenceEquals(targetCamera.activeTexture, null))
            {
                if ((targetCamera.activeTexture.width % reprojectionXfactor != 0) || (targetCamera.activeTexture.height % reprojectionYfactor != 0))
                {
                    Debug.LogError ("Error: Screen dimensions not evenly divisible by " + reprojectionXfactor.ToString() + " and " + reprojectionYfactor.ToString() + ": " + targetCamera.targetTexture.width.ToString() + " " + targetCamera.targetTexture.height.ToString());
                    return;
                }

                //compositeCloudsMaterial = new Material(CompositeRaymarchedCloudShader);
                reconstructCloudsMaterial = new Material(ReconstructionShader);

                int width = targetCamera.activeTexture.width;
                int height = targetCamera.activeTexture.height;
                
                historyFlipRT = CreateRenderTexture(width, height, RenderTextureFormat.ARGB32, false, FilterMode.Point);
                historyFlopRT = CreateRenderTexture(width, height, RenderTextureFormat.ARGB32, false, FilterMode.Point);
                
                newRaysFlipRT = CreateRenderTexture(width / reprojectionXfactor, height / reprojectionYfactor, RenderTextureFormat.ARGB32, false, FilterMode.Point);
                newRaysFlopRT = CreateRenderTexture(width / reprojectionXfactor, height / reprojectionYfactor, RenderTextureFormat.ARGB32, false, FilterMode.Point);
                
                newDistanceFlipRT = CreateRenderTexture(width / reprojectionXfactor, height / reprojectionYfactor, RenderTextureFormat.RGHalf, false, FilterMode.Point);
                newDistanceFlopRT = CreateRenderTexture(width / reprojectionXfactor, height / reprojectionYfactor, RenderTextureFormat.RGHalf, false, FilterMode.Point);
                
                reconstructCloudsMaterial.SetVector("reconstructedTextureResolution", new Vector2(width, height));
                reconstructCloudsMaterial.SetVector("invReconstructedTextureResolution", new Vector2(1.0f / width, 1.0f / height));

                //compositeCloudsMaterial.SetVector("reconstructedTextureResolution", new Vector2(width, height));
                //compositeCloudsMaterial.SetVector("invReconstructedTextureResolution", new Vector2(1.0f / width, 1.0f / height));

                DeferredRaymarchedRendererToScreen.material.SetVector("reconstructedTextureResolution", new Vector2(width, height));
                DeferredRaymarchedRendererToScreen.material.SetVector("invReconstructedTextureResolution", new Vector2(1.0f / width, 1.0f / height));

                reconstructCloudsMaterial.SetInt("reprojectionXfactor", reprojectionXfactor);
                reconstructCloudsMaterial.SetInt("reprojectionYfactor", reprojectionYfactor);
                
                commandBuffer = new CommandBuffer();

                isInitialized = true;
            }
        }

        public void EnableForThisFrame(CloudsRaymarchedVolume volume)
        {
            if (isInitialized)
            {
                volumesAdded.Add(volume);

                renderingEnabled = true;
            }
        }

        void OnPreRender()
        {
            if (renderingEnabled)
            {
                //calculate camera altitude
                //float camAltitude = 0; //TODO: placeholder FIX IT

                //TODO: sort layers by distance to nearest thing
                //Do a flip flop raymarching scheme to the reprojection buffer
                //Do a single reconstruction pass
                //RT is passed to the compositing MR
                /*foreach (var elt in volumesAdded)
                {
                    CommandBuffer cb = new CommandBuffer();

                    cb.SetRenderTarget(targetRT);
                    cb.DrawRenderer(elt.Value.Item1, elt.Value.Item2);

                    targetCamera.AddCommandBuffer(CameraEvent.AfterForwardOpaque, cb);

                    commandBuffersAdded.Add(cb);
                }
                */

                //for now just do the front one
                commandBuffer.Clear();

                SetTemporalReprojectionParams(out Vector2 uvOffset);

                var cloudMaterial = volumesAdded.ElementAt(0).RaymarchedCloudMaterial;
                var mr = volumesAdded.ElementAt(0).volumeHolder.GetComponent<MeshRenderer>(); //TODO: change this to not use a GetComponent

                //render to new rays and distance textures
                //TODO change this to flip flop when doing multiple layers
                RenderTargetIdentifier[] raysRenderTextures = { new RenderTargetIdentifier(newRaysFlipRT), new RenderTargetIdentifier(newDistanceFlipRT) };
                commandBuffer.SetRenderTarget(raysRenderTextures, newRaysFlipRT.depthBuffer);
                commandBuffer.DrawRenderer(mr, cloudMaterial, 0, -1);                          //maybe just replace with a drawMesh?

                RenderTargetIdentifier[] flipIdentifiers = { new RenderTargetIdentifier(historyFlipRT) };   //technically don't need to output the distance here
                RenderTargetIdentifier[] flopIdentifiers = { new RenderTargetIdentifier(historyFlopRT) };

                //reconstruct full frame from history and new rays texture
                RenderTargetIdentifier[] targetIdentifiers = useFlipBuffer ? flipIdentifiers : flopIdentifiers;

                commandBuffer.SetRenderTarget(targetIdentifiers, historyFlipRT.depthBuffer);
                reconstructCloudsMaterial.SetMatrix("previousVP", previousP * previousV);   //this jitters a lot so the precision is probably absolutely messed up
                                                                                            //it also messes with the reprojection/reconstruction, horrible

                //reconstructCloudsMaterial.SetMatrix("previousVP", targetCamera.previousViewProjectionMatrix); //appears to be broken completely




                reconstructCloudsMaterial.SetTexture("historyBuffer", useFlipBuffer ? historyFlopRT : historyFlipRT);

                reconstructCloudsMaterial.SetTexture("newRaysBuffer", newRaysFlipRT);   //TODO: change this blabla flip flop multi layer blabla
                reconstructCloudsMaterial.SetTexture("newRaysDepthBuffer", newDistanceFlipRT);

                commandBuffer.DrawRenderer(mr, reconstructCloudsMaterial, 0, 0);

                DeferredRaymarchedRendererToScreen.SetActive(true);
                DeferredRaymarchedRendererToScreen.SetRenderTexture(useFlipBuffer ? historyFlipRT : historyFlopRT);


                //this needs to be done on pre-render but it's a bit of a waste
                cloudMaterial.SetVector("reconstructedTextureResolution", new Vector2(historyFlipRT.width, historyFlipRT.height));
                cloudMaterial.SetVector("invReconstructedTextureResolution", new Vector2(1.0f / historyFlipRT.width, 1.0f / historyFlipRT.height));

                cloudMaterial.SetInt("reprojectionXfactor", reprojectionXfactor);
                cloudMaterial.SetInt("reprojectionYfactor", reprojectionYfactor);

                reconstructCloudsMaterial.SetFloat("innerSphereRadius", volumesAdded.ElementAt(0).InnerSphereRadius);
                reconstructCloudsMaterial.SetFloat("outerSphereRadius", volumesAdded.ElementAt(0).OuterSphereRadius);

                cloudMaterial.SetMatrix("CameraToWorld", targetCamera.cameraToWorldMatrix);
                reconstructCloudsMaterial.SetMatrix("CameraToWorld", targetCamera.cameraToWorldMatrix);

                //also do this
                cloudMaterial.SetVector("reprojectionUVOffset", uvOffset);

                //also need to set the blue noise offset
                int frame = Time.frameCount % (256);

                DeferredRaymarchedRendererToScreen.material.renderQueue = 4000; //TODO: Fix, for some reason scatterer sky was drawing over it

                //to double check if these are still needed
                cloudMaterial.SetFloat("frameNumber", (float)(frame));
                reconstructCloudsMaterial.SetFloat("frameNumber", (float)(frame));

                targetCamera.AddCommandBuffer(CameraEvent.AfterForwardOpaque, commandBuffer);
            }
        }

        public void SetTemporalReprojectionParams(out Vector2 uvOffset)
        {
            int frame = Time.frameCount % (reprojectionXfactor * reprojectionYfactor);  //the current frame

            if (reprojectionXfactor == 2 && reprojectionYfactor == 2)
            {
                frame = samplingSequence4[frame];
            }
            else if (reprojectionXfactor == 4 && reprojectionYfactor == 2)
            {
                frame = samplingSequence8[frame];
            }
            else if (reprojectionXfactor == 4 && reprojectionYfactor == 4)
            {
                frame = samplingSequence16[frame];
            }

            //figure out the current targeted pixel
            Vector2 currentPixel = new Vector2(frame % reprojectionXfactor, frame / reprojectionXfactor);

            //figure out the offset from center pixel when we are rendering, to be used in the raymarching shader
            Vector2 centerPixel = new Vector2((float)(reprojectionXfactor - 1) * 0.5f, (float)(reprojectionYfactor - 1) * 0.5f);
            Vector2 pixelOffset = currentPixel - centerPixel;
            uvOffset = pixelOffset / new Vector2(historyFlipRT.width, historyFlipRT.height);

            reconstructCloudsMaterial.SetVector("reprojectionCurrentPixel", currentPixel);
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
                    useFlipBuffer = !useFlipBuffer;
                    targetCamera.RemoveCommandBuffer(CameraEvent.AfterForwardOpaque, commandBuffer);
                    volumesAdded.Clear();

                    previousP = GL.GetGPUProjectionMatrix(targetCamera.projectionMatrix, false);
                    previousV = targetCamera.worldToCameraMatrix;

                    DeferredRaymarchedRendererToScreen.SetActive(false);
                    renderingEnabled = false;
                }
            }

        }

        public void OnDestroy()
        {
            if (!ReferenceEquals(targetCamera, null))
            {
                //TODO: here don't forget to release all the textures

                targetCamera.RemoveCommandBuffer(CameraEvent.AfterForwardOpaque, commandBuffer);
                volumesAdded.Clear();

                renderingEnabled = false;
            }
        }

        // TODO: move to utils
        RenderTexture CreateRenderTexture(int width, int height, RenderTextureFormat format, bool mips, FilterMode filterMode)
        {
            var rt = new RenderTexture(width, height, 0, format);
            rt.anisoLevel = 1;
            rt.antiAliasing = 1;
            rt.volumeDepth = 0;
            rt.useMipMap = mips;
            rt.autoGenerateMips = mips;
            rt.filterMode = filterMode;
            rt.Create();

            return rt;
        }
    }

    class DeferredRaymarchedRendererNotifier : MonoBehaviour
    {
        public CloudsRaymarchedVolume volume;

        void OnWillRenderObject()
        {
            //if (volume != null) //not needed?
            if (Camera.current != null)
                DeferredRaymarchedVolumetricCloudsRenderer.EnableForThisFrame(Camera.current, volume);
        }
    }

    public class DeferredRaymarchedRendererToScreen : MonoBehaviour
    {
        public Material material;

        MeshRenderer compositeMR;

        public void Init()
        {
            material = new Material(ShaderLoaderClass.FindShader("EVE/CompositeRaymarchedClouds"));
            material.renderQueue = 4000; //TODO: Fix, for some reason scatterer sky was drawing over it

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
            material.SetTexture("colorBuffer", RT);                                                     //TODO: shader properties
            material.SetVector("reconstructedTextureResolution", new Vector2(RT.width, RT.height));     //TODO: shader properties
        }

        public void SetActive(bool active)      //needed?
        {
            material.SetFloat(ShaderProperties.rendererEnabled_PROPERTY, active ? 1f : 0f);
        }

    }
}
