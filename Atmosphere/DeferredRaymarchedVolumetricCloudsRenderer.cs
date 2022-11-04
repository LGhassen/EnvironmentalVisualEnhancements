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

        // raw list of volumes added
        List<CloudsRaymarchedVolume> volumesAdded = new List<CloudsRaymarchedVolume>();

        // list of intersections sorted by distance, for rendering closest to farthest, such that already occluded layers in the distance don't add any raymarching cost
        List<raymarchedLayerIntersection> intersections = new List<raymarchedLayerIntersection>();

        private RenderTexture historyFlipRT, historyFlopRT, secondaryHistoryFlipRT, secondaryHistoryFlopRT, historyMotionVectorsFlipRT, historyMotionVectorsFlopRT, newRaysFlipRT, newRaysFlopRT, newRaysSecondaryFlipRT, newRaysSecondaryFlopRT, newMotionVectorsFlipRT, newMotionVectorsFlopRT;
        bool useFlipScreenBuffer = true;
        Material reconstructCloudsMaterial;

        Matrix4x4 previousV = Matrix4x4.identity;
        Matrix4x4 previousP = Matrix4x4.identity;
        Vector3d previousFloatingOriginOffset = Vector3d.zero;

        int reprojectionXfactor = 4;
        int reprojectionYfactor = 2;

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

                reconstructCloudsMaterial = new Material(ReconstructionShader);

                int width = targetCamera.activeTexture.width;
                int height = targetCamera.activeTexture.height;
                
                historyFlipRT = CreateRenderTexture(width, height, RenderTextureFormat.ARGB32, false, FilterMode.Bilinear);
                historyFlopRT = CreateRenderTexture(width, height, RenderTextureFormat.ARGB32, false, FilterMode.Bilinear);

                secondaryHistoryFlipRT = CreateRenderTexture(width, height, RenderTextureFormat.ARGB32, false, FilterMode.Bilinear);
                secondaryHistoryFlopRT = CreateRenderTexture(width, height, RenderTextureFormat.ARGB32, false, FilterMode.Bilinear);

                historyMotionVectorsFlipRT = CreateRenderTexture(width, height, RenderTextureFormat.RGHalf, false, FilterMode.Bilinear);
                historyMotionVectorsFlopRT = CreateRenderTexture(width, height, RenderTextureFormat.RGHalf, false, FilterMode.Bilinear);

                newRaysFlipRT = CreateRenderTexture(width / reprojectionXfactor, height / reprojectionYfactor, RenderTextureFormat.ARGB32, false, FilterMode.Point);
                newRaysFlopRT = CreateRenderTexture(width / reprojectionXfactor, height / reprojectionYfactor, RenderTextureFormat.ARGB32, false, FilterMode.Point);

                newRaysSecondaryFlipRT = CreateRenderTexture(width / reprojectionXfactor, height / reprojectionYfactor, RenderTextureFormat.ARGB32, false, FilterMode.Point);
                newRaysSecondaryFlopRT = CreateRenderTexture(width / reprojectionXfactor, height / reprojectionYfactor, RenderTextureFormat.ARGB32, false, FilterMode.Point);

                newMotionVectorsFlipRT = CreateRenderTexture(width / reprojectionXfactor, height / reprojectionYfactor, RenderTextureFormat.RGHalf, false, FilterMode.Point);
                newMotionVectorsFlopRT = CreateRenderTexture(width / reprojectionXfactor, height / reprojectionYfactor, RenderTextureFormat.RGHalf, false, FilterMode.Point);

                reconstructCloudsMaterial.SetVector("reconstructedTextureResolution", new Vector2(width, height));
                reconstructCloudsMaterial.SetVector("invReconstructedTextureResolution", new Vector2(1.0f / (float)width, 1.0f / (float)height));

                DeferredRaymarchedRendererToScreen.material.SetVector("reconstructedTextureResolution", new Vector2(width, height));
                DeferredRaymarchedRendererToScreen.material.SetVector("invReconstructedTextureResolution", new Vector2(1.0f / (float)width, 1.0f / (float)height));

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
                DeferredRaymarchedRendererToScreen.SetActive(true);
            }
        }

        struct raymarchedLayerIntersection
        {
            public float distance;
            public CloudsRaymarchedVolume layer;
            public bool isSecondIntersect;
        }

        void OnPreRender()
        {
            if (renderingEnabled)
            {
                // calculate intersections and intersection distances for each layer if we're inside layer -> 1 intersect with distance 0 and 1 intersect with distance camAltitude + 2*planetRadius+innerLayerAlt (layers must not overlap, possibly enforce this in the Clouds class?)
                // if we're lower than the layer -> 1 intersect with distance camAltitude + 2*radius+innerLayerAlt
                // if we're higher than the layer -> 1 intersect with distance camAltitude - outerLayerAltitude
                intersections.Clear();
                float innerReprojectionRadius = float.MaxValue, outerRepojectionRadius = float.MinValue;

                float cloudFade = 1f;

                foreach (var elt in volumesAdded)
                {
                    //calculate camera altitude, doing it per volume is overkill, but let's leave it so if we render volumetrics on multiple planets at the same time it will still work
                    float camDistanceToPlanetOrigin = (gameObject.transform.position - elt.ParentTransform.position).magnitude;

                    if (camDistanceToPlanetOrigin >= elt.InnerSphereRadius && camDistanceToPlanetOrigin <= elt.OuterSphereRadius)
                    {
                        intersections.Add(new raymarchedLayerIntersection() { distance = 0f, layer = elt, isSecondIntersect = false });
                        intersections.Add(new raymarchedLayerIntersection() { distance = camDistanceToPlanetOrigin+elt.InnerSphereRadius, layer = elt, isSecondIntersect = true });
                    }
                    else if (camDistanceToPlanetOrigin < elt.InnerSphereRadius)
                    {
                        intersections.Add(new raymarchedLayerIntersection() { distance = camDistanceToPlanetOrigin + elt.InnerSphereRadius, layer = elt, isSecondIntersect = false });
                    }
                    else if (camDistanceToPlanetOrigin > elt.OuterSphereRadius)
                    {
                        intersections.Add(new raymarchedLayerIntersection() { distance = camDistanceToPlanetOrigin - elt.OuterSphereRadius, layer = elt, isSecondIntersect = false });
                        intersections.Add(new raymarchedLayerIntersection() { distance = camDistanceToPlanetOrigin + elt.InnerSphereRadius, layer = elt, isSecondIntersect = true });
                    }

                    innerReprojectionRadius = Mathf.Min(innerReprojectionRadius, elt.InnerSphereRadius);
                    outerRepojectionRadius = Mathf.Max(outerRepojectionRadius, elt.OuterSphereRadius);

                    cloudFade = Mathf.Min(cloudFade, elt.VolumetricLayerScaledFade);
                }

                DeferredRaymarchedRendererToScreen.SetFade(cloudFade);

                // now sort our intersections front to back
                intersections = intersections.OrderBy(x => x.distance).ToList();

                // now we have our intersections, flip flop render where each layer reads what the previous one left as input)
                RenderTargetIdentifier[] flipRaysRenderTextures = { new RenderTargetIdentifier(newRaysFlipRT), new RenderTargetIdentifier(newMotionVectorsFlipRT), new RenderTargetIdentifier(newRaysSecondaryFlipRT) };
                RenderTargetIdentifier[] flopRaysRenderTextures = { new RenderTargetIdentifier(newRaysFlopRT), new RenderTargetIdentifier(newMotionVectorsFlopRT), new RenderTargetIdentifier(newRaysSecondaryFlopRT) };
                commandBuffer.Clear();

                SetTemporalReprojectionParams(out Vector2 uvOffset);
                int frame = Time.frameCount % (256);

                bool useFlipRaysBuffer = true;
                bool isFirstLayerRendered  = true;

                // have to use these to build the motion vector because the unity provided one in shader will be flipped
                var currentP = GL.GetGPUProjectionMatrix(targetCamera.nonJitteredProjectionMatrix, false);
                var currentV = targetCamera.worldToCameraMatrix;

                //handle floatingOrigin changes
                Vector3d currentOffset = FloatingOrigin.TerrainShaderOffset - previousFloatingOriginOffset;

                //transform to camera space
                Vector3 floatOffset = targetCamera.worldToCameraMatrix.MultiplyVector(currentOffset);

                //inject in the previous view matrix
                previousV.m03 += floatOffset.x;
                previousV.m13 += floatOffset.y;
                previousV.m23 += floatOffset.z;

                foreach (var intersection in intersections)
                {
                    var cloudMaterial = intersection.layer.RaymarchedCloudMaterial;

                    var mr = intersection.layer.volumeHolder.GetComponent<MeshRenderer>(); //TODO: change this to not use a GetComponent

                    //set material properties
                    cloudMaterial.SetVector("reconstructedTextureResolution", new Vector2(historyFlipRT.width, historyFlipRT.height));
                    cloudMaterial.SetVector("invReconstructedTextureResolution", new Vector2(1.0f / historyFlipRT.width, 1.0f / historyFlipRT.height));

                    cloudMaterial.SetInt("reprojectionXfactor", reprojectionXfactor);
                    cloudMaterial.SetInt("reprojectionYfactor", reprojectionYfactor);

                    cloudMaterial.SetMatrix("CameraToWorld", targetCamera.cameraToWorldMatrix);
                    cloudMaterial.SetVector("reprojectionUVOffset", uvOffset);
                    cloudMaterial.SetFloat("frameNumber", (float)(frame));

                    Vector3 noiseReprojectionOffset = targetCamera.worldToCameraMatrix.MultiplyVector(-intersection.layer.NoiseReprojectionOffset);
                    Matrix4x4 cloudPreviousV = previousV;

                    // inject upwards noise offset
                    cloudPreviousV.m03 += noiseReprojectionOffset.x;
                    cloudPreviousV.m13 += noiseReprojectionOffset.y;
                    cloudPreviousV.m23 += noiseReprojectionOffset.z;

                    cloudMaterial.SetMatrix("currentVP", currentP * currentV);
                    cloudMaterial.SetMatrix("previousVP", previousP * cloudPreviousV * intersection.layer.OppositeFrameDeltaRotationMatrix);    // inject the rotation of the cloud layer itself

                    // handle the actual rendering
                    commandBuffer.SetRenderTarget(useFlipRaysBuffer ? flipRaysRenderTextures : flopRaysRenderTextures, newRaysFlipRT.depthBuffer);
                    commandBuffer.SetGlobalFloat("isFirstLayerRendered", isFirstLayerRendered ? 1f : 0f);
                    commandBuffer.SetGlobalFloat("renderSecondLayerIntersect", intersection.isSecondIntersect ? 1f : 0f);
                    commandBuffer.SetGlobalTexture("PreviousLayerRays", useFlipRaysBuffer ? newRaysFlopRT : newRaysFlipRT);
                    commandBuffer.SetGlobalTexture("PreviousLayerMotionVectors", useFlipRaysBuffer ? newMotionVectorsFlopRT : newMotionVectorsFlipRT);
                    commandBuffer.SetGlobalTexture("PreviousLayerRaysSecondary", useFlipRaysBuffer ? newRaysSecondaryFlopRT : newRaysSecondaryFlipRT);

                    commandBuffer.DrawRenderer(mr, cloudMaterial, 0, -1); //maybe just replace with a drawMesh?

                    isFirstLayerRendered = false;
                    useFlipRaysBuffer = !useFlipRaysBuffer;
                }

                //reconstruct full frame from history and new rays texture
                RenderTargetIdentifier[] flipIdentifiers = { new RenderTargetIdentifier(historyFlipRT), new RenderTargetIdentifier(secondaryHistoryFlipRT), new RenderTargetIdentifier(historyMotionVectorsFlipRT) };
                RenderTargetIdentifier[] flopIdentifiers = { new RenderTargetIdentifier(historyFlopRT), new RenderTargetIdentifier(secondaryHistoryFlopRT), new RenderTargetIdentifier(historyMotionVectorsFlopRT) };
                RenderTargetIdentifier[] targetIdentifiers = useFlipScreenBuffer ? flipIdentifiers : flopIdentifiers;

                commandBuffer.SetRenderTarget(targetIdentifiers, historyFlipRT.depthBuffer);

                reconstructCloudsMaterial.SetMatrix("previousVP", previousP * previousV);

                reconstructCloudsMaterial.SetTexture("historyBuffer", useFlipScreenBuffer ? historyFlopRT : historyFlipRT);
                reconstructCloudsMaterial.SetTexture("historySecondaryBuffer", useFlipScreenBuffer ? secondaryHistoryFlopRT : secondaryHistoryFlipRT);
                reconstructCloudsMaterial.SetTexture("historyMotionVectors", useFlipScreenBuffer ? historyMotionVectorsFlopRT : historyMotionVectorsFlipRT);
                reconstructCloudsMaterial.SetTexture("newRaysBuffer", useFlipRaysBuffer ? newRaysFlopRT : newRaysFlipRT);
                reconstructCloudsMaterial.SetTexture("newRaysBufferBilinear", useFlipRaysBuffer ? newRaysFlopRT : newRaysFlipRT);
                reconstructCloudsMaterial.SetTexture("newRaysMotionVectors", useFlipRaysBuffer ? newMotionVectorsFlopRT : newMotionVectorsFlipRT);
                reconstructCloudsMaterial.SetTexture("newRaysSecondaryBuffer", useFlipRaysBuffer ? newRaysSecondaryFlopRT : newRaysSecondaryFlipRT);
                reconstructCloudsMaterial.SetTexture("newRaysSecondaryBufferBilinear", useFlipRaysBuffer ? newRaysSecondaryFlopRT : newRaysSecondaryFlipRT);

                reconstructCloudsMaterial.SetFloat("innerSphereRadius", innerReprojectionRadius);
                reconstructCloudsMaterial.SetFloat("outerSphereRadius", outerRepojectionRadius);
                reconstructCloudsMaterial.SetFloat("planetRadius", volumesAdded.ElementAt(0).PlanetRadius);
                reconstructCloudsMaterial.SetVector("sphereCenter", volumesAdded.ElementAt(0).RaymarchedCloudMaterial.GetVector("sphereCenter")); //TODO: cleaner way to handle it

                reconstructCloudsMaterial.SetMatrix("CameraToWorld", targetCamera.cameraToWorldMatrix);

                reconstructCloudsMaterial.SetFloat("frameNumber", (float)(frame));

                var mr1 = volumesAdded.ElementAt(0).volumeHolder.GetComponent<MeshRenderer>(); // TODO: replace with its own quad?
                commandBuffer.DrawRenderer(mr1, reconstructCloudsMaterial, 0, 0);

                DeferredRaymarchedRendererToScreen.SetRenderTextures(useFlipScreenBuffer ? historyFlipRT : historyFlopRT, useFlipScreenBuffer ? secondaryHistoryFlipRT : secondaryHistoryFlopRT);
                DeferredRaymarchedRendererToScreen.material.renderQueue = 2999;


                // Set texture for scatterer sunflare: temporary
                commandBuffer.SetGlobalTexture("scattererReconstructedCloud", useFlipScreenBuffer ? historyFlipRT : historyFlopRT);

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
            reconstructCloudsMaterial.SetVector("reprojectionUVOffset", uvOffset);
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
                    useFlipScreenBuffer = !useFlipScreenBuffer;
                    targetCamera.RemoveCommandBuffer(CameraEvent.AfterForwardOpaque, commandBuffer);
                    volumesAdded.Clear();

                    previousP = GL.GetGPUProjectionMatrix(targetCamera.nonJitteredProjectionMatrix, false);
                    previousV = targetCamera.worldToCameraMatrix;

                    previousFloatingOriginOffset = FloatingOrigin.TerrainShaderOffset;
                    renderingEnabled = false;
                }

                DeferredRaymarchedRendererToScreen.SetActive(false);
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
            if (Camera.current != null)
            {
                DeferredRaymarchedVolumetricCloudsRenderer.EnableForThisFrame(Camera.current, volume);
            }
        }
    }

    public class DeferredRaymarchedRendererToScreen : MonoBehaviour
    {
        public Material material;

        MeshRenderer compositeMR;
        bool isActive = false;

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

        public void SetRenderTextures(RenderTexture colorBuffer, RenderTexture scatteringBuffer)
        {
            material.SetTexture("colorBuffer", colorBuffer);                                                                //TODO: shader properties
            material.SetTexture("secondaryColorBuffer", scatteringBuffer);                                                  //TODO: shader properties
            material.SetVector("reconstructedTextureResolution", new Vector2(colorBuffer.width, colorBuffer.height));       //TODO: shader properties

        }

        public void SetActive(bool active)
        {
            material.SetFloat(ShaderProperties.rendererEnabled_PROPERTY, active ? 1f : 0f);

            if (isActive == active)
                compositeMR.enabled = active;    // we're late in the rendering process so re-enabling has a frame delay, if disabled every frame it won't re-enable so only disable (and enable) this after 2 frames

            isActive = active;
        }

        public void SetFade(float fade)
        {
            material.SetFloat("cloudFade", fade); //TODO: property
        }
    }
}
