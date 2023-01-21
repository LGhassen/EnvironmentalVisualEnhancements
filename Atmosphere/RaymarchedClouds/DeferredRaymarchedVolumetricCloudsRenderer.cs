﻿using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;
using ShaderLoader;
using Utils;
using UnityEngine.XR;

namespace Atmosphere
{
    struct FlipFlop<T>
    {
        public FlipFlop(T flip, T flop)
        {
            this.flip = flip;
            this.flop = flop;
        }

        public T this[bool useFlip]
        {
            get => useFlip ? flip : flop;
            set
            {
                if (useFlip) flip = value;
                else flop = value;
            }
        }

        T flip;
        T flop;
    }

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

        public static void ReinitAll()
        {
            foreach (var renderer in CameraToDeferredRaymarchedVolumetricCloudsRenderer.Values)
            {
                if (renderer != null)
                {
                    renderer.Cleanup();
                }
            }
        }

        bool renderingEnabled = false;
        bool isInitialized = false;

        private Camera targetCamera;
        private FlipFlop<CommandBuffer> commandBuffer; // indexed by isRightEye

        // raw list of volumes added
        List<CloudsRaymarchedVolume> volumesAdded = new List<CloudsRaymarchedVolume>();

        // list of intersections sorted by distance, for rendering closest to farthest, such that already occluded layers in the distance don't add any raymarching cost
        List<raymarchedLayerIntersection> intersections = new List<raymarchedLayerIntersection>();

        // these are indexed by [isRightEye][flip]
        private FlipFlop<FlipFlop<RenderTexture>> historyRT, secondaryHistoryRT, historyMotionVectorsRT;
        // these are indexed by [flip]
        private FlipFlop<RenderTexture> newRaysRT, newRaysSecondaryRT, newMotionVectorsRT;

        bool useFlipScreenBuffer = true;
        Material reconstructCloudsMaterial;

        // indexed by [isRightEye]
        private FlipFlop<Matrix4x4> previousV;
        private FlipFlop<Matrix4x4> previousP;
        Vector3d previousFloatingOriginOffset = Vector3d.zero;

        int reprojectionXfactor = 4;
        int reprojectionYfactor = 2;
        ReprojectionQuality reprojectionQuality = ReprojectionQuality.accurate;

        //manually made sampling sequences that distribute samples in a cross pattern for reprojection
        int[] samplingSequence4 = new int[] { 0, 2, 3, 1 };
        int[] samplingSequence8 = new int[] { 0, 4, 2, 6, 3, 7, 1, 5 };
        int[] samplingSequence16 = new int[] { 0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5 };

        int width, height;

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

        FlipFlop<RenderTexture> CreateFlipFlopRT(int width, int height, RenderTextureFormat format, FilterMode filterMode)
        {
            return new FlipFlop<RenderTexture>(
                CreateRenderTexture(width, height, format, false, filterMode),
                CreateRenderTexture(width, height, format, false, filterMode));
        }

        FlipFlop<FlipFlop<RenderTexture>> CreateVRFlipFlopRT(bool supportVR, int width, int height, RenderTextureFormat format, FilterMode filterMode)
        {
            return new FlipFlop<FlipFlop<RenderTexture>>(
                supportVR ? CreateFlipFlopRT(width, height, format, filterMode) : new FlipFlop<RenderTexture>(null, null),
                CreateFlipFlopRT(width, height, format, filterMode));
        }

        void ReleaseFlipFlopRT(ref FlipFlop<RenderTexture> flipFlop)
        {
            RenderTexture rt;

            rt = flipFlop[false];
            if (rt != null) rt.Release();
            rt = flipFlop[true];
            if (rt != null) rt.Release();

            flipFlop = new FlipFlop<RenderTexture>(null, null);
        }

        void ReleaseVRFlipFlopRT(ref FlipFlop<FlipFlop<RenderTexture>> flipFlop)
        {
            var ff = flipFlop[false];
            ReleaseFlipFlopRT(ref ff);
            ff = flipFlop[true];
            ReleaseFlipFlopRT(ref ff);

            flipFlop = new FlipFlop<FlipFlop<RenderTexture>>(ff, ff);
        }

        public void Initialize()
        {
            targetCamera = GetComponent<Camera>();

            if (targetCamera == null || targetCamera.activeTexture == null)
                return;

            var reprojectionFactors = RaymarchedCloudsQualityManager.GetReprojectionFactors();
            reprojectionXfactor = reprojectionFactors.Item1;
            reprojectionYfactor = reprojectionFactors.Item2;

            reprojectionQuality = RaymarchedCloudsQualityManager.ReprojectionQuality;

            if ((targetCamera.activeTexture.width % reprojectionXfactor != 0) || (targetCamera.activeTexture.height % reprojectionYfactor != 0))
            {
                Debug.LogError("Error: Screen dimensions not evenly divisible by " + reprojectionXfactor.ToString() + " and " + reprojectionYfactor.ToString() + ": " + targetCamera.activeTexture.width.ToString() + " " + targetCamera.activeTexture.height.ToString());
                CameraToDeferredRaymarchedVolumetricCloudsRenderer.Remove(targetCamera);
                Component.Destroy(this);
                return;
            }

            reconstructCloudsMaterial = new Material(ReconstructionShader);
            if (reprojectionQuality == ReprojectionQuality.accurate)
            {
                reconstructCloudsMaterial.EnableKeyword("REPROJECTION_HQ");
                reconstructCloudsMaterial.DisableKeyword("REPROJECTION_FAST");
            }
            else
            {
                reconstructCloudsMaterial.DisableKeyword("REPROJECTION_HQ");
                reconstructCloudsMaterial.EnableKeyword("REPROJECTION_FAST");
            }

            bool supportVR = XRSettings.loadedDeviceName != string.Empty;

            if (supportVR)
            {
                width = XRSettings.eyeTextureWidth;
                height = XRSettings.eyeTextureHeight;
            }
            else
            {
                width = targetCamera.activeTexture.width;
                height = targetCamera.activeTexture.height;
            }

            historyRT = CreateVRFlipFlopRT(supportVR, width, height, RenderTextureFormat.ARGB32, FilterMode.Bilinear);
            secondaryHistoryRT = CreateVRFlipFlopRT(supportVR, width, height, RenderTextureFormat.ARGB32, FilterMode.Bilinear);
            historyMotionVectorsRT = CreateVRFlipFlopRT(supportVR, width, height, RenderTextureFormat.RGHalf, FilterMode.Bilinear);

            newRaysRT = CreateFlipFlopRT(width / reprojectionXfactor, height / reprojectionYfactor, RenderTextureFormat.ARGB32, FilterMode.Point);
            newRaysSecondaryRT = CreateFlipFlopRT(width / reprojectionXfactor, height / reprojectionYfactor, RenderTextureFormat.ARGB32, FilterMode.Point);
            newMotionVectorsRT = CreateFlipFlopRT(width / reprojectionXfactor, height / reprojectionYfactor, RenderTextureFormat.RGHalf, FilterMode.Point);
            
            reconstructCloudsMaterial.SetVector("reconstructedTextureResolution", new Vector2(width, height));
            reconstructCloudsMaterial.SetVector("invReconstructedTextureResolution", new Vector2(1.0f / (float)width, 1.0f / (float)height));

            DeferredRaymarchedRendererToScreen.material.SetVector("reconstructedTextureResolution", new Vector2(width, height));
            DeferredRaymarchedRendererToScreen.material.SetVector("invReconstructedTextureResolution", new Vector2(1.0f / (float)width, 1.0f / (float)height));

            reconstructCloudsMaterial.SetInt("reprojectionXfactor", reprojectionXfactor);
            reconstructCloudsMaterial.SetInt("reprojectionYfactor", reprojectionYfactor);

            commandBuffer = new FlipFlop<CommandBuffer>(
                supportVR ? new CommandBuffer() : null,
                new CommandBuffer());

            isInitialized = true;
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

        static Matrix4x4 GetNonJitteredProjectionMatrixForCamera(Camera cam)
        {
            if (cam.stereoActiveEye == Camera.MonoOrStereoscopicEye.Mono)
            {
                return cam.nonJitteredProjectionMatrix;
            }
            else
            {
                return cam.GetStereoNonJitteredProjectionMatrix(cam.stereoActiveEye == Camera.MonoOrStereoscopicEye.Left ? Camera.StereoscopicEye.Left : Camera.StereoscopicEye.Right);
            }
        }

        static Matrix4x4 GetViewMatrixForCamera(Camera cam)
        {
            if (cam.stereoActiveEye == Camera.MonoOrStereoscopicEye.Mono)
            {
                return cam.worldToCameraMatrix;
            }
            else
            {
                return cam.GetStereoViewMatrix(cam.stereoActiveEye == Camera.MonoOrStereoscopicEye.Left ? Camera.StereoscopicEye.Left : Camera.StereoscopicEye.Right);
            }
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

                bool isRightEye = targetCamera.stereoActiveEye == Camera.MonoOrStereoscopicEye.Right;

                // now we have our intersections, flip flop render where each layer reads what the previous one left as input)
                RenderTargetIdentifier[] flipRaysRenderTextures = { new RenderTargetIdentifier(newRaysRT[true]), new RenderTargetIdentifier(newMotionVectorsRT[true]), new RenderTargetIdentifier(newRaysSecondaryRT[true]) };
                RenderTargetIdentifier[] flopRaysRenderTextures = { new RenderTargetIdentifier(newRaysRT[false]), new RenderTargetIdentifier(newMotionVectorsRT[false]), new RenderTargetIdentifier(newRaysSecondaryRT[false]) };
                var commandBuffer = this.commandBuffer[isRightEye];
                commandBuffer.Clear();

                SetTemporalReprojectionParams(out Vector2 uvOffset);
                int frame = Time.frameCount % (256);

                bool useFlipRaysBuffer = true;
                bool isFirstLayerRendered  = true;

                // have to use these to build the motion vector because the unity provided one in shader will be flipped
                var currentP = GL.GetGPUProjectionMatrix(GetNonJitteredProjectionMatrixForCamera(targetCamera), false);
                var currentV = GetViewMatrixForCamera(targetCamera);

                //handle floatingOrigin changes
                Vector3d currentOffset = Vector3d.zero;

                if (FloatingOrigin.OffsetNonKrakensbane != previousFloatingOriginOffset)
                    currentOffset = FloatingOrigin.OffsetNonKrakensbane;    // this is the frame-to-frame difference in offset, but it's not updated if there is no change
                                                                            // this isn't the best way to check for it, as if we're moving at constant speed and it changes every frame then there's no way to detect it
                                                                            // but it seems to work ok

                previousFloatingOriginOffset = FloatingOrigin.OffsetNonKrakensbane;

                //transform to camera space
                Vector3 floatOffset = currentV.MultiplyVector(currentOffset);

                //inject in the previous view matrix
                var prevV = previousV[isRightEye];
                prevV.m03 += floatOffset.x;
                prevV.m13 += floatOffset.y;
                prevV.m23 += floatOffset.z;

                var prevP = previousP[isRightEye];

                foreach (var intersection in intersections)
                {
                    var cloudMaterial = intersection.layer.RaymarchedCloudMaterial;

                    var mr = intersection.layer.volumeHolder.GetComponent<MeshRenderer>(); //TODO: change this to not use a GetComponent

                    //set material properties
                    cloudMaterial.SetVector("reconstructedTextureResolution", new Vector2(width, height));
                    cloudMaterial.SetVector("invReconstructedTextureResolution", new Vector2(1.0f / width, 1.0f / height));

                    cloudMaterial.SetInt("reprojectionXfactor", reprojectionXfactor);
                    cloudMaterial.SetInt("reprojectionYfactor", reprojectionYfactor);

                    cloudMaterial.SetMatrix("CameraToWorld", targetCamera.cameraToWorldMatrix);
                    cloudMaterial.SetVector("reprojectionUVOffset", uvOffset);
                    cloudMaterial.SetFloat("frameNumber", (float)(frame));

                    Vector3 noiseReprojectionOffset = currentV.MultiplyVector(-intersection.layer.NoiseReprojectionOffset);
                    Matrix4x4 cloudPreviousV = prevV;

                    // inject upwards noise offset
                    cloudPreviousV.m03 += noiseReprojectionOffset.x;
                    cloudPreviousV.m13 += noiseReprojectionOffset.y;
                    cloudPreviousV.m23 += noiseReprojectionOffset.z;

                    cloudMaterial.SetMatrix("currentVP", currentP * currentV);
                    cloudMaterial.SetMatrix("previousVP", prevP * cloudPreviousV * intersection.layer.OppositeFrameDeltaRotationMatrix);    // inject the rotation of the cloud layer itself

                    // handle the actual rendering
                    commandBuffer.SetRenderTarget(useFlipRaysBuffer ? flipRaysRenderTextures : flopRaysRenderTextures, newRaysRT[true].depthBuffer); // REVIEW: this always uses flip - why?
                    commandBuffer.SetGlobalFloat("isFirstLayerRendered", isFirstLayerRendered ? 1f : 0f);
                    commandBuffer.SetGlobalFloat("renderSecondLayerIntersect", intersection.isSecondIntersect ? 1f : 0f);
                    commandBuffer.SetGlobalTexture("PreviousLayerRays", newRaysRT[!useFlipRaysBuffer]);
                    commandBuffer.SetGlobalTexture("PreviousLayerMotionVectors", newMotionVectorsRT[!useFlipRaysBuffer]);
                    commandBuffer.SetGlobalTexture("PreviousLayerRaysSecondary", newRaysSecondaryRT[!useFlipRaysBuffer]);

                    commandBuffer.DrawRenderer(mr, cloudMaterial, 0, -1); //maybe just replace with a drawMesh?

                    isFirstLayerRendered = false;
                    useFlipRaysBuffer = !useFlipRaysBuffer;
                }

                //reconstruct full frame from history and new rays texture
                RenderTargetIdentifier[] flipIdentifiers = { new RenderTargetIdentifier(historyRT[isRightEye][true]), new RenderTargetIdentifier(secondaryHistoryRT[isRightEye][true]), new RenderTargetIdentifier(historyMotionVectorsRT[isRightEye][true]) };
                RenderTargetIdentifier[] flopIdentifiers = { new RenderTargetIdentifier(historyRT[isRightEye][false]), new RenderTargetIdentifier(secondaryHistoryRT[isRightEye][false]), new RenderTargetIdentifier(historyMotionVectorsRT[isRightEye][false]) };
                RenderTargetIdentifier[] targetIdentifiers = useFlipScreenBuffer ? flipIdentifiers : flopIdentifiers;

                commandBuffer.SetRenderTarget(targetIdentifiers, historyRT[isRightEye][true].depthBuffer); // REVIEW: this always uses flip - why?

                reconstructCloudsMaterial.SetMatrix("previousVP", prevP * prevV);

                bool readFromFlip = !useFlipScreenBuffer; // "useFlipScreenBuffer" means the *target* is flip, and we should be reading from flop
                reconstructCloudsMaterial.SetTexture("historyBuffer", historyRT[isRightEye][readFromFlip]);
                reconstructCloudsMaterial.SetTexture("historySecondaryBuffer", secondaryHistoryRT[isRightEye][readFromFlip]);
                reconstructCloudsMaterial.SetTexture("historyMotionVectors", historyMotionVectorsRT[isRightEye][readFromFlip]);
                reconstructCloudsMaterial.SetTexture("newRaysBuffer", newRaysRT[!useFlipRaysBuffer]);
                reconstructCloudsMaterial.SetTexture("newRaysBufferBilinear", newRaysRT[!useFlipRaysBuffer]);
                reconstructCloudsMaterial.SetTexture("newRaysMotionVectors", newMotionVectorsRT[!useFlipRaysBuffer]);
                reconstructCloudsMaterial.SetTexture("newRaysSecondaryBuffer", newRaysSecondaryRT[!useFlipRaysBuffer]);
                reconstructCloudsMaterial.SetTexture("newRaysSecondaryBufferBilinear", newRaysSecondaryRT[!useFlipRaysBuffer]);

                reconstructCloudsMaterial.SetFloat("innerSphereRadius", innerReprojectionRadius);
                reconstructCloudsMaterial.SetFloat("outerSphereRadius", outerRepojectionRadius);
                reconstructCloudsMaterial.SetFloat("planetRadius", volumesAdded.ElementAt(0).PlanetRadius);
                reconstructCloudsMaterial.SetVector("sphereCenter", volumesAdded.ElementAt(0).RaymarchedCloudMaterial.GetVector("sphereCenter")); //TODO: cleaner way to handle it

                reconstructCloudsMaterial.SetMatrix("CameraToWorld", targetCamera.cameraToWorldMatrix);

                reconstructCloudsMaterial.SetFloat("frameNumber", (float)(frame));

                var mr1 = volumesAdded.ElementAt(0).volumeHolder.GetComponent<MeshRenderer>(); // TODO: replace with its own quad?
                commandBuffer.DrawRenderer(mr1, reconstructCloudsMaterial, 0, 0);

                commandBuffer.SetGlobalTexture("colorBuffer", historyRT[isRightEye][useFlipScreenBuffer]);
                commandBuffer.SetGlobalTexture("secondaryColorBuffer", secondaryHistoryRT[isRightEye][useFlipScreenBuffer]);
                commandBuffer.SetGlobalVector("reconstructedTextureResolution", new Vector2(width, height));
                DeferredRaymarchedRendererToScreen.material.renderQueue = 2999;


                // Set texture for scatterer sunflare: temporary
                commandBuffer.SetGlobalTexture("scattererReconstructedCloud",  historyRT[isRightEye][useFlipScreenBuffer]);

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
            uvOffset = pixelOffset / new Vector2(width, height);

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
                bool doneRendering = targetCamera.stereoActiveEye != Camera.MonoOrStereoscopicEye.Left;

                if (renderingEnabled)
                {
                    bool isRightEye = targetCamera.stereoActiveEye == Camera.MonoOrStereoscopicEye.Right;
                    var commandBuffer = this.commandBuffer[isRightEye];

                    targetCamera.RemoveCommandBuffer(CameraEvent.AfterForwardOpaque, commandBuffer);

                    previousP[isRightEye] = GL.GetGPUProjectionMatrix(GetNonJitteredProjectionMatrixForCamera(targetCamera), false);
                    previousV[isRightEye] = GetViewMatrixForCamera(targetCamera);

                    if (doneRendering)
                    {
                        renderingEnabled = false;
                        volumesAdded.Clear();
                        useFlipScreenBuffer = !useFlipScreenBuffer;
                    }
                }

                if (doneRendering)
                {
                    DeferredRaymarchedRendererToScreen.SetActive(false);
                }
            }

        }

        void Cleanup()
        {
            ReleaseVRFlipFlopRT(ref historyRT);
            ReleaseVRFlipFlopRT(ref secondaryHistoryRT);
            ReleaseVRFlipFlopRT(ref historyMotionVectorsRT);
            ReleaseFlipFlopRT(ref newRaysRT);
            ReleaseFlipFlopRT(ref newRaysSecondaryRT);
            ReleaseFlipFlopRT(ref newMotionVectorsRT);
            
            if (targetCamera != null)
            {
                if (commandBuffer[true] != null)
                {
                    targetCamera.RemoveCommandBuffer(CameraEvent.AfterForwardOpaque, commandBuffer[true]);
                }
                targetCamera.RemoveCommandBuffer(CameraEvent.AfterForwardOpaque, commandBuffer[false]);
                volumesAdded.Clear();
            }

            renderingEnabled = false;
            isInitialized = false;
        }

        public void OnDestroy()
        {
            Cleanup();
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
        bool activationRequested = false;

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

        public void SetActive(bool active)
        {
            material.SetFloat(ShaderProperties.rendererEnabled_PROPERTY, active ? 1f : 0f);

            if (active)
            {
                if (activationRequested && active)
                {
                    compositeMR.enabled = active;    // we're late in the rendering process so re-enabling has a frame delay, if disabled every frame it won't re-enable so only disable (and enable) this after 2 frames
                    isActive = true;
                    activationRequested = false;
                }

                activationRequested = true;
            }
            else
                isActive = false;
        }

        public void SetFade(float fade)
        {
            material.SetFloat("cloudFade", fade); //TODO: property
        }
    }
}
