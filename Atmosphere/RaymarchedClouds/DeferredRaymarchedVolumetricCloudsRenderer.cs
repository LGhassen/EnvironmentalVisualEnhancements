using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;
using ShaderLoader;
using Utils;

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
                if ((cam.name == "TRReflectionCamera") || (cam.name == "Reflection Probes Camera") || (cam.name == "DepthCamera") || (cam.name == "NearCamera"))
                {
                    CameraToDeferredRaymarchedVolumetricCloudsRenderer[cam] = null;
                }
                else if (!Tools.IsUnifiedCameraMode() && cam.name == "Camera 01")
                {
                    CameraToDeferredRaymarchedVolumetricCloudsRenderer[cam] = null;
                    cam.gameObject.AddComponent<DepthToDistanceCommandBuffer>();
                }
                else
                {
                    CameraToDeferredRaymarchedVolumetricCloudsRenderer[cam] = (DeferredRaymarchedVolumetricCloudsRenderer)cam.gameObject
                        .AddComponent(typeof(DeferredRaymarchedVolumetricCloudsRenderer));

                    if (cam.name == "Camera 00")
                    {
                        CameraToDeferredRaymarchedVolumetricCloudsRenderer[cam].MainFlightCamera = true;

                        if (!Tools.IsUnifiedCameraMode())
                        {
                            CameraToDeferredRaymarchedVolumetricCloudsRenderer[cam].useCombinedOpenGLDistanceBuffer = true;
                            cam.gameObject.AddComponent<DepthToDistanceCommandBuffer>();
                        }
                    }
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
        bool useLightVolume = false;

        private Camera targetCamera;
        private FlipFlop<CommandBuffer> commandBuffer; // indexed by isRightEye

        // raw list of volumes added
        List<CloudsRaymarchedVolume> volumesAdded = new List<CloudsRaymarchedVolume>();

        // list of volume bounds, to be traversed bottom to top to figure out overlaps
        List<RaymarchedLayerBound> volumesBounds = new List<RaymarchedLayerBound>();

        // an overlap interval is a region of space where a given set of layers overlap
        // this is a list of overlap intervals sorted by distance from camera for rendering closest to
        // farthest such that already occluded layers/overlaps in the distance don't add any raymarching cost
        List<OverlapIntervalIntersection> intersections = new List<OverlapIntervalIntersection>();

        // these are indexed by [isRightEye][flip]
        private FlipFlop<FlipFlop<RenderTexture>> historyRT, historyMotionVectorsRT;

        // these are indexed by [flip]
        private FlipFlop<RenderTexture> packedNewRaysRT, packedOverlapRaysRT; // These are packed 32-bit per channel textures to save texture slots on Mac
                                                                              // RG encodes 16-bit per channel RGBA colors
                                                                              // B encodes 16-bit per channel motion vectors
                                                                              // A encodes 16-bit per channel max depth and weighted depth
                                                                              // We don't need bilinear interpolation for these so the packing works

        
        private RenderTexture unpackedNewRaysRT, unpackedMotionVectorsRT, unpackedMaxDepthRT; // Unpacked Textures used to speed up reconstruction which does lots of lookups
        private RenderTexture weightedDepthRTDebug; // Debug textures to visualize the previous packed textures after each rendering step
        private bool packedTexturesDebugMode = false;

        private FlipFlop<RenderTexture> lightningOcclusionRT;

        bool useFlipScreenBuffer = true;
        Material reconstructCloudsMaterial, unpackRaysMaterial;

        // indexed by [isRightEye]
        private FlipFlop<Matrix4x4> previousV;
        private FlipFlop<Matrix4x4> previousP;
        Vector3d previousParentPosition = Vector3d.zero;

        int reprojectionXfactor = 4;
        int reprojectionYfactor = 2;

        // sampling sequences that distribute samples in a cross pattern for reprojection
        private static readonly int[] samplingSequence3 = new int[] { 0, 2, 1 };
        private static readonly int[] samplingSequence4 = new int[] { 0, 3, 1, 2 };
        private static readonly int[] samplingSequence5 = new int[] { 0, 3, 1, 4, 2 };
        private static readonly int[] samplingSequence6 = new int[] { 0, 4, 2, 3, 1, 5 };
        private static readonly int[] samplingSequence8 = new int[] { 0, 6, 3, 4, 2, 5, 1, 7 };
        private static readonly int[] samplingSequence9 = new int[] { 0, 7, 2, 3, 8, 1, 6, 5, 4 };
        private static readonly int[] samplingSequence10 = new int[] { 0, 8, 1, 9, 6, 3, 5, 2, 4, 7 };
        private static readonly int[] samplingSequence12 = new int[] { 0, 10, 3, 5, 11, 1, 8, 2, 9, 7, 4, 6 };
        private static readonly int[] samplingSequence16 = new int[] { 0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5 };
        private static readonly int[] samplingSequence32 = new int[] { 0, 16, 8, 24, 4, 20, 12, 28, 2, 18, 10, 26, 6, 22, 14, 30, 1, 17, 9, 25, 5, 21, 13, 29, 3, 19, 11, 27, 7, 23, 15, 31 };
        
        private int[] reorderedSamplingSequence = null;

        private int screenWidth, screenHeight;

        // When we have dimensions not evenly divisible by the reprojection factors assume we are working with an evenly disible one then just oversample the side pixels
        private int paddedScreenWidth, paddedScreenHeight;
        private int newRaysRenderWidth, newRaysRenderHeight;

        private bool mainFlightCamera = false;

        private static readonly int lightningOcclusionResolution = 32;
        private float screenshotModeIterations = 8;

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

        private static Shader unpackRaysShader = null;
        private static Shader UnpackRaysShader
        {
            get
            {
                if (unpackRaysShader == null)
                {
                    unpackRaysShader = ShaderLoaderClass.FindShader("EVE/UnpackRays");
                }
                return unpackRaysShader;
            }
        }

        public bool MainFlightCamera { get => mainFlightCamera; set => mainFlightCamera = value; }

        private bool useCombinedOpenGLDistanceBuffer = false;

        private bool cloudsScreenshotModeEnabled = false;

        private const int renderCloudsPass = 0;
        private const int renderLightingOcclusionPass = 1;

        public DeferredRaymarchedVolumetricCloudsRenderer()
        {
        }

        public void Initialize()
        {
            targetCamera = GetComponent<Camera>();

            if (targetCamera == null || targetCamera.activeTexture == null)
                return;

            SetReprojectionFactors();
            SetRenderAndUpscaleResolutions();
            InitRenderTextures();

            screenshotModeIterations = RaymarchedCloudsQualityManager.ScreenShotModeDenoisingIterations;

            reconstructCloudsMaterial = new Material(ReconstructionShader);
            unpackRaysMaterial = new Material(UnpackRaysShader);

            reconstructCloudsMaterial.SetVector("reconstructedTextureResolution", new Vector2(screenWidth, screenHeight));
            reconstructCloudsMaterial.SetVector("invReconstructedTextureResolution", new Vector2(1.0f / (float)screenWidth, 1.0f / (float)screenHeight));

            reconstructCloudsMaterial.SetVector("paddedReconstructedTextureResolution", new Vector2(paddedScreenWidth, paddedScreenHeight));
            reconstructCloudsMaterial.SetVector("invPaddedReconstructedTextureResolution", new Vector2(1.0f / (float)paddedScreenWidth, 1.0f / (float)paddedScreenHeight));

            reconstructCloudsMaterial.SetVector("newRaysRenderResolution", new Vector2(newRaysRenderWidth, newRaysRenderHeight));
            reconstructCloudsMaterial.SetVector("invNewRaysRenderResolution", new Vector2(1.0f / (float)newRaysRenderWidth, 1.0f / (float)newRaysRenderHeight));

            reconstructCloudsMaterial.SetInt(ShaderProperties.reprojectionXfactor_PROPERTY, reprojectionXfactor);
            reconstructCloudsMaterial.SetInt(ShaderProperties.reprojectionYfactor_PROPERTY, reprojectionYfactor);

            reconstructCloudsMaterial.SetFloat("screenshotModeIterations", screenshotModeIterations);

            commandBuffer = new FlipFlop<CommandBuffer>(VRUtils.VREnabled() ? new CommandBuffer() : null, new CommandBuffer());

            isInitialized = true;
        }

        private void HandleScreenshotMode()
        {
            bool screenShotModeEnabled = GameSettings.TAKE_SCREENSHOT.GetKeyDown(false);

            if (screenShotModeEnabled != cloudsScreenshotModeEnabled)
            {
                cloudsScreenshotModeEnabled = screenShotModeEnabled;

                SetReprojectionFactors(screenShotModeEnabled);

                int superSizingFactor = Mathf.Max(GameSettings.SCREENSHOT_SUPERSIZE, 1);

                if (screenShotModeEnabled)
                { 
                    screenWidth *= superSizingFactor;
                    screenHeight *= superSizingFactor;
                }
                else
                {
                    screenWidth /= superSizingFactor;
                    screenHeight /= superSizingFactor;
                }

                SetNewRaysAndPaddedScreenResolution();

                RenderTextureUtils.ResizeFlipFlopRT(ref packedNewRaysRT, newRaysRenderWidth, newRaysRenderHeight);
                RenderTextureUtils.ResizeFlipFlopRT(ref packedOverlapRaysRT, newRaysRenderWidth, newRaysRenderHeight);

                RenderTextureUtils.ResizeRT(unpackedNewRaysRT, newRaysRenderWidth, newRaysRenderHeight);
                RenderTextureUtils.ResizeRT(unpackedMotionVectorsRT, newRaysRenderWidth, newRaysRenderHeight);
                RenderTextureUtils.ResizeRT(unpackedMaxDepthRT, newRaysRenderWidth, newRaysRenderHeight);

                if (packedTexturesDebugMode)
                {
                    RenderTextureUtils.ResizeRT(weightedDepthRTDebug, newRaysRenderWidth, newRaysRenderHeight);
                }

                VRUtils.ResizeVRFlipFlopRT(ref historyRT, screenWidth, screenHeight);
                VRUtils.ResizeVRFlipFlopRT(ref historyMotionVectorsRT, screenWidth, screenHeight);

                reconstructCloudsMaterial.SetVector("reconstructedTextureResolution", new Vector2(screenWidth, screenHeight));
                reconstructCloudsMaterial.SetVector("invReconstructedTextureResolution", new Vector2(1.0f / (float)screenWidth, 1.0f / (float)screenHeight));

                reconstructCloudsMaterial.SetVector("paddedReconstructedTextureResolution", new Vector2(paddedScreenWidth, paddedScreenHeight));
                reconstructCloudsMaterial.SetVector("invPaddedReconstructedTextureResolution", new Vector2(1.0f / (float)paddedScreenWidth, 1.0f / (float)paddedScreenHeight));

                reconstructCloudsMaterial.SetVector("newRaysRenderResolution", new Vector2(newRaysRenderWidth, newRaysRenderHeight));
                reconstructCloudsMaterial.SetVector("invNewRaysRenderResolution", new Vector2(1.0f / (float)newRaysRenderWidth, 1.0f / (float)newRaysRenderHeight));

                reconstructCloudsMaterial.SetInt(ShaderProperties.reprojectionXfactor_PROPERTY, reprojectionXfactor);
                reconstructCloudsMaterial.SetInt(ShaderProperties.reprojectionYfactor_PROPERTY, reprojectionYfactor);
            }
        }

        private void SetRenderAndUpscaleResolutions()
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

            SetNewRaysAndPaddedScreenResolution();
        }

        private void SetNewRaysAndPaddedScreenResolution()
        {
            paddedScreenWidth = screenWidth % reprojectionXfactor == 0 ? screenWidth : ((screenWidth / reprojectionXfactor) + 1) * reprojectionXfactor;
            paddedScreenHeight = screenHeight % reprojectionYfactor == 0 ? screenHeight : ((screenHeight / reprojectionYfactor) + 1) * reprojectionYfactor;

            newRaysRenderWidth = paddedScreenWidth / reprojectionXfactor;
            newRaysRenderHeight = paddedScreenHeight / reprojectionYfactor;
        }

        private void InitRenderTextures()
        {
            var colorFormat = RenderTextureFormat.DefaultHDR;
            bool supportVR = VRUtils.VREnabled();

            ReleaseRenderTextures();

            historyRT = VRUtils.CreateVRFlipFlopRT(supportVR, screenWidth, screenHeight, colorFormat, FilterMode.Bilinear);
            historyMotionVectorsRT = VRUtils.CreateVRFlipFlopRT(supportVR, screenWidth, screenHeight, RenderTextureFormat.RGHalf, FilterMode.Bilinear);

            packedNewRaysRT = RenderTextureUtils.CreateFlipFlopRT(newRaysRenderWidth, newRaysRenderHeight, RenderTextureFormat.ARGBFloat, FilterMode.Point);
            packedNewRaysRT[true].name = "newrays flip";
            packedNewRaysRT[false].name = "newrays flop";

            // TODO: maybe allocate this only if overlaps are currently needed
            packedOverlapRaysRT = RenderTextureUtils.CreateFlipFlopRT(newRaysRenderWidth, newRaysRenderHeight, RenderTextureFormat.ARGBFloat, FilterMode.Point);
            packedOverlapRaysRT[true].name = "overlap flip";
            packedOverlapRaysRT[false].name = "overlap flop";

            unpackedNewRaysRT = RenderTextureUtils.CreateRenderTexture(newRaysRenderWidth, newRaysRenderHeight, RenderTextureFormat.ARGBHalf, false, FilterMode.Point);
            unpackedMotionVectorsRT = RenderTextureUtils.CreateRenderTexture(newRaysRenderWidth, newRaysRenderHeight, RenderTextureFormat.RGHalf, false, FilterMode.Point);
            unpackedMaxDepthRT = RenderTextureUtils.CreateRenderTexture(newRaysRenderWidth, newRaysRenderHeight, RenderTextureFormat.RHalf, false, FilterMode.Point);

            if (packedTexturesDebugMode)
            { 
                weightedDepthRTDebug = RenderTextureUtils.CreateRenderTexture(newRaysRenderWidth, newRaysRenderHeight, RenderTextureFormat.RHalf, false, FilterMode.Point);
            }

            lightningOcclusionRT = RenderTextureUtils.CreateFlipFlopRT(lightningOcclusionResolution * Lightning.MaxConcurrent, lightningOcclusionResolution, RenderTextureFormat.R8, FilterMode.Bilinear);
        }

        private void SetReprojectionFactors(bool screenshotMode = false)
        {
            System.Tuple<int, int> reprojectionFactors = screenshotMode ? new System.Tuple<int, int>(1, 1) : RaymarchedCloudsQualityManager.GetReprojectionFactors();

            reprojectionXfactor = reprojectionFactors.Item1;
            reprojectionYfactor = reprojectionFactors.Item2;

            // TODO: simplify this
            if (reprojectionXfactor == 3 && reprojectionYfactor == 1)
            {
                reorderedSamplingSequence = samplingSequence3;
            }
            else if (reprojectionXfactor == 2 && reprojectionYfactor == 2)
            {
                reorderedSamplingSequence = samplingSequence4;
            }
            else if (reprojectionXfactor == 5 && reprojectionYfactor == 1)
            {
                reorderedSamplingSequence = samplingSequence5;
            }
            if (reprojectionXfactor == 3 && reprojectionYfactor == 2)
            {
                reorderedSamplingSequence = samplingSequence6;
            }
            else if (reprojectionXfactor == 4 && reprojectionYfactor == 2)
            {
                reorderedSamplingSequence = samplingSequence8;
            }
            else if (reprojectionXfactor == 5 && reprojectionYfactor == 2)
            {
                reorderedSamplingSequence = samplingSequence10;
            }
            if (reprojectionXfactor == 3 && reprojectionYfactor == 3)
            {
                reorderedSamplingSequence = samplingSequence9;
            }
            if (reprojectionXfactor == 4 && reprojectionYfactor == 3)
            {
                reorderedSamplingSequence = samplingSequence12;
            }
            else if (reprojectionXfactor == 4 && reprojectionYfactor == 4)
            {
                reorderedSamplingSequence = samplingSequence16;
            }
            else if (reprojectionXfactor == 8 && reprojectionYfactor == 4)
            {
                reorderedSamplingSequence = samplingSequence32;
            }
            else
                reorderedSamplingSequence = null;
        }

        public void EnableForThisFrame(CloudsRaymarchedVolume volume)
        {
            if (isInitialized)
            {
                volumesAdded.Add(volume);

                volumesBounds.Add(new RaymarchedLayerBound() { nature = RaymarchedLayerBoundNature.Bottom, radius = volume.InnerSphereRadius, layer = volume });
                volumesBounds.Add(new RaymarchedLayerBound() { nature = RaymarchedLayerBoundNature.Top, radius = volume.OuterSphereRadius, layer = volume });

                renderingEnabled = true;                    
                DeferredRaymarchedRendererToScreen.SetActive(true);
                
                Lightning.UpdateExisting();
            }
        }

        public enum RaymarchedLayerBoundNature
        {
            Bottom,
            Top
        }

        struct RaymarchedLayerBound
        {
            public float radius;
            public CloudsRaymarchedVolume layer;
            public RaymarchedLayerBoundNature nature;
        }

        struct OverlapInterval
        {
            public float InnerRadius;
            public float OuterRadius;
            public List<CloudsRaymarchedVolume> volumes;
        }
        struct OverlapIntervalIntersection
        {
            public float distance;
            public OverlapInterval overlapInterval;
            public bool isSecondIntersect;
        }

        void OnPreRender()
        {
            if (renderingEnabled)
            {
                HandleScreenshotMode();

                Vector3 cameraPosition = gameObject.transform.position;
                float camDistanceToPlanetOrigin = (cameraPosition - volumesAdded[0].ParentTransform.position).magnitude;

                List<OverlapInterval> overlapIntervals = ResolveLayerOverlapIntervals(volumesBounds);                
                ResolveLayerIntersections(overlapIntervals, camDistanceToPlanetOrigin, intersections);

                float innerCloudsRadius = float.MaxValue, outerCloudsRadius = float.MinValue;

                float cloudFade = 1f;

                useLightVolume = false;
                float lightVolumeMaxRadius = Mathf.Infinity;

                float innerLightVolumeRadius = float.MaxValue, outerLightVolumeRadius = float.MinValue;

                float lightVolumeSlowestRotatingLayerSpeed = float.MaxValue;
                CloudsRaymarchedVolume lightVolumeSlowestRotatingLayer = null;

                foreach (CloudsRaymarchedVolume volumetricLayer in volumesAdded)
                {
                    innerCloudsRadius = Mathf.Min(innerCloudsRadius, volumetricLayer.InnerSphereRadius);
                    outerCloudsRadius = Mathf.Max(outerCloudsRadius, volumetricLayer.OuterSphereRadius);

                    cloudFade = Mathf.Min(cloudFade, volumetricLayer.VolumetricLayerScaledFade);

                    if (volumetricLayer.LightVolumeSettings.UseLightVolume)
                    {
                        useLightVolume = true;

                        innerLightVolumeRadius = Mathf.Min(innerLightVolumeRadius, volumetricLayer.InnerSphereRadius);
                        outerLightVolumeRadius = Mathf.Max(outerLightVolumeRadius, volumetricLayer.OuterSphereRadius);

                        if (volumetricLayer.LinearSpeedMagnitude < lightVolumeSlowestRotatingLayerSpeed)
                        {
                            lightVolumeSlowestRotatingLayerSpeed = volumetricLayer.LinearSpeedMagnitude;
                            lightVolumeSlowestRotatingLayer = volumetricLayer;
                        }

                        lightVolumeMaxRadius = Mathf.Min(lightVolumeMaxRadius, volumetricLayer.LightVolumeSettings.MaxLightVolumeRadius);
                    }
                }

                float planetRadius = volumesAdded.ElementAt(0).PlanetRadius;

                if (useLightVolume && mainFlightCamera)
                    LightVolume.Instance.Update(volumesAdded, cameraPosition, volumesAdded.ElementAt(0).parentCelestialBody.transform, planetRadius, innerLightVolumeRadius, outerLightVolumeRadius, lightVolumeSlowestRotatingLayer.PlanetOppositeFrameDeltaRotationMatrix.inverse, lightVolumeMaxRadius);

                // if the camera is higher than the highest layer by 2x as high as the layer is from the ground, enable orbitMode
                bool orbitMode = (TimeWarp.CurrentRate * Time.timeScale < 100f) && RaymarchedCloudsQualityManager.UseOrbitMode && camDistanceToPlanetOrigin - outerCloudsRadius > 2f * (outerCloudsRadius - planetRadius);

                DeferredRaymarchedRendererToScreen.SetFade(cloudFade);
                var DeferredRaymarchedRendererToScreenMaterial = DeferredRaymarchedRendererToScreen.compositeColorMaterial;
                DeferredRaymarchedRendererToScreenMaterial.SetFloat(ShaderProperties.useOrbitMode_PROPERTY, orbitMode ? 1f : 0f);
                DeferredRaymarchedRendererToScreenMaterial.SetMatrix(ShaderProperties.CameraToWorld_PROPERTY, targetCamera.cameraToWorldMatrix);
                DeferredRaymarchedRendererToScreenMaterial.SetFloat(ShaderProperties.innerSphereRadius_PROPERTY, innerCloudsRadius);
                DeferredRaymarchedRendererToScreenMaterial.SetFloat(ShaderProperties.outerSphereRadius_PROPERTY, outerCloudsRadius);
                DeferredRaymarchedRendererToScreenMaterial.SetVector(ShaderProperties.sphereCenter_PROPERTY, volumesAdded.ElementAt(0).RaymarchedCloudMaterial.GetVector(ShaderProperties.sphereCenter_PROPERTY)); //TODO: cleaner way to handle it
                DeferredRaymarchedRendererToScreenMaterial.SetFloat(ShaderProperties.useCombinedOpenGLDistanceBuffer_PROPERTY, useCombinedOpenGLDistanceBuffer ? 1f : 0f);
                DeferredRaymarchedRendererToScreen.depthOcclusionMaterial.SetMatrix(ShaderProperties.CameraToWorld_PROPERTY, targetCamera.cameraToWorldMatrix);

                // now sort our intersections front to back
                intersections = intersections.OrderBy(x => x.distance).ToList();

                bool isRightEye = targetCamera.stereoActiveEye == Camera.MonoOrStereoscopicEye.Right;

                // now we have our intersections, flip flop render where each layer reads what the previous one left as input)
                RenderTargetIdentifier[] flipRaysRenderTextures = { new RenderTargetIdentifier(packedNewRaysRT[true]) };
                RenderTargetIdentifier[] flopRaysRenderTextures = { new RenderTargetIdentifier(packedNewRaysRT[false]) };
                var commandBuffer = this.commandBuffer[isRightEye];
                commandBuffer.Clear();

                // have to use these to build the motion vector because the unity provided one in shader will be flipped
                var currentP = GL.GetGPUProjectionMatrix(VRUtils.GetNonJitteredProjectionMatrixForCamera(targetCamera), false);
                var currentV = VRUtils.GetViewMatrixForCamera(targetCamera);

                // add the frame to frame offset of the parent body, this contains both the movement of the body and the floating origin
                Vector3d currentOffset = volumesAdded.ElementAt(0).parentCelestialBody.position - previousParentPosition;
                previousParentPosition = volumesAdded.ElementAt(0).parentCelestialBody.position;

                //transform to camera space
                Vector3 floatOffset = currentV.MultiplyVector(-currentOffset);

                //inject in the previous view matrix
                var prevV = previousV[isRightEye];

                prevV.m03 += floatOffset.x;
                prevV.m13 += floatOffset.y;
                prevV.m23 += floatOffset.z;

                var prevP = previousP[isRightEye];

                commandBuffer.SetGlobalFloat(ShaderProperties.useCombinedOpenGLDistanceBuffer_PROPERTY, useCombinedOpenGLDistanceBuffer ? 1f : 0f);

                if (useCombinedOpenGLDistanceBuffer && DepthToDistanceCommandBuffer.RenderTexture)
                {
                    commandBuffer.SetGlobalTexture(ShaderProperties.cameraDepthBufferForClouds_PROPERTY, DepthToDistanceCommandBuffer.RenderTexture);
                }
                else
                {
                    commandBuffer.SetGlobalTexture(ShaderProperties.cameraDepthBufferForClouds_PROPERTY,
                        targetCamera.actualRenderingPath == RenderingPath.DeferredShading ? BuiltinRenderTextureType.ResolvedDepth : BuiltinRenderTextureType.Depth);
                }

                SetTemporalReprojectionParams(out Vector2 uvOffset);
                int frame = Time.frameCount % ShaderLoader.ShaderLoaderClass.stbnDimensions.z;

                bool useFlipRaysBuffer = true;
                bool useLightningFlipRaysBuffer = true;

                float renderingIterations = 1;

                if (cloudsScreenshotModeEnabled)
                {
                    renderingIterations = screenshotModeIterations;

                    // In screenshot mode render multiple iterations additively to a single target without reprojection or neighborhood clipping, so clear targets in advance
                    commandBuffer.SetRenderTarget(new RenderTargetIdentifier(historyRT[isRightEye][true]), historyRT[isRightEye][true].depthBuffer);
                    commandBuffer.ClearRenderTarget(false, true, Color.clear);
                    commandBuffer.SetRenderTarget(new RenderTargetIdentifier(historyRT[isRightEye][false]), historyRT[isRightEye][false].depthBuffer);
                    commandBuffer.ClearRenderTarget(false, true, Color.clear);
                }

                for (int i = 0; i < renderingIterations; i++)
                {
                    HandleRenderingCommands(innerCloudsRadius, outerCloudsRadius, orbitMode, isRightEye, flipRaysRenderTextures, flopRaysRenderTextures, commandBuffer, uvOffset, frame, ref useFlipRaysBuffer, ref useLightningFlipRaysBuffer, currentP, currentV, prevV, prevP);
                    frame++;
                    frame = frame % ShaderLoader.ShaderLoaderClass.stbnDimensions.z;
                }

                commandBuffer.SetGlobalTexture(ShaderProperties.colorBuffer_PROPERTY, historyRT[isRightEye][useFlipScreenBuffer]);

                // Set texture for scatterer sunflare: temporary
                commandBuffer.SetGlobalTexture(ShaderProperties.scattererReconstructedCloud_PROPERTY, historyRT[isRightEye][useFlipScreenBuffer]);

                commandBuffer.SetGlobalTexture(ShaderProperties.lightningOcclusion_PROPERTY, lightningOcclusionRT[!useLightningFlipRaysBuffer]);

                DeferredRaymarchedRendererToScreen.compositeColorMaterial.renderQueue = 2998;

                targetCamera.AddCommandBuffer(CameraEvent.AfterForwardOpaque, commandBuffer);
            }
        }

        private void ResolveLayerIntersections(List<OverlapInterval> overlapIntervals, float camDistanceToPlanetOrigin, List<OverlapIntervalIntersection> intersections)
        {
            // calculate intersections and intersection distances for each layer/interval
            // if we're inside layer -> 1 intersect with distance 0 and 1 intersect with distance camAltitude + 2 * planetRadius+innerLayerAlt
            // if we're lower than the layer -> 1 intersect with distance camAltitude + 2*radius+innerLayerAlt
            // if we're higher than the layer -> 1 intersect with distance camAltitude - outerLayerAltitude
            intersections.Clear();

            foreach (OverlapInterval overlapInterval in overlapIntervals)
            {
                if (camDistanceToPlanetOrigin >= overlapInterval.InnerRadius && camDistanceToPlanetOrigin <= overlapInterval.OuterRadius)
                {
                    intersections.Add(new OverlapIntervalIntersection() { distance = 0f, overlapInterval = overlapInterval, isSecondIntersect = false });
                    intersections.Add(new OverlapIntervalIntersection() { distance = camDistanceToPlanetOrigin + overlapInterval.InnerRadius, overlapInterval = overlapInterval, isSecondIntersect = true });
                }
                else if (camDistanceToPlanetOrigin < overlapInterval.InnerRadius)
                {
                    intersections.Add(new OverlapIntervalIntersection() { distance = camDistanceToPlanetOrigin + overlapInterval.InnerRadius, overlapInterval = overlapInterval, isSecondIntersect = false });
                }
                else if (camDistanceToPlanetOrigin > overlapInterval.OuterRadius)
                {
                    intersections.Add(new OverlapIntervalIntersection() { distance = camDistanceToPlanetOrigin - overlapInterval.OuterRadius, overlapInterval = overlapInterval, isSecondIntersect = false });
                    intersections.Add(new OverlapIntervalIntersection() { distance = camDistanceToPlanetOrigin + overlapInterval.InnerRadius, overlapInterval = overlapInterval, isSecondIntersect = true });
                }
            }
        }

        // This method finds distinct intervals in which layers can overlap, or a single layer can render using the layer start and end altitudes
        // This is essentially a classic "overlapping interval" search problem which can be solved using a sweep line algorithm
        // The key is to sort the intervals by altitudes, and make sure to break ties by putting the end of the intervals before the start
        private List<OverlapInterval> ResolveLayerOverlapIntervals(List<RaymarchedLayerBound> volumeBounds)
        {
            // Order by radius but also by nature, if radius is the same, closing/top comes first to break up ties when sorting
            volumeBounds = volumeBounds.OrderBy(x => x.radius).ThenByDescending(x => x.nature).ToList();

            HashSet<CloudsRaymarchedVolume> layersInCurrentInterval = new HashSet<CloudsRaymarchedVolume>();
            float lastBoundCrossed = Mathf.NegativeInfinity;

            List<OverlapInterval> overlapIntervals = new List<OverlapInterval>();

            foreach (RaymarchedLayerBound bound in volumeBounds)
            {
                if (bound.nature == RaymarchedLayerBoundNature.Bottom)
                {
                    // Only write out a new interval if we are already inside some layers and the altitude is different from last one
                    // So that if we are opening multiple layers at the same altitude we don't write out multiple intervals
                    if (layersInCurrentInterval.Count > 0 && bound.radius != lastBoundCrossed)
                    {
                        overlapIntervals.Add(new OverlapInterval() { InnerRadius = lastBoundCrossed, OuterRadius = bound.radius, volumes = layersInCurrentInterval.ToList() });
                    }

                    // Add the new layer to the current list
                    layersInCurrentInterval.Add(bound.layer);
                }
                else
                {
                    // Closing, remove layer from the current list, write out a new interval if it's a different bound from last one
                    // So that if we are closing multiple layers at the same altitude, the first close takes care of the writing
                    if (bound.radius != lastBoundCrossed)
                    {
                        overlapIntervals.Add(new OverlapInterval() { InnerRadius = lastBoundCrossed, OuterRadius = bound.radius, volumes = layersInCurrentInterval.ToList() });
                    }

                    layersInCurrentInterval.Remove(bound.layer);
                }

                lastBoundCrossed = bound.radius;
            }

            return overlapIntervals;
        }

        private void HandleRenderingCommands(float innerCloudsRadius, float outerCloudsRadius, bool orbitMode, bool isRightEye, RenderTargetIdentifier[] flipRaysRenderTextures, RenderTargetIdentifier[] flopRaysRenderTextures, CommandBuffer commandBuffer, Vector2 uvOffset, int frame, ref bool useFlipRaysBuffer, ref bool useLightningFlipRaysBuffer, Matrix4x4 currentP, Matrix4x4 currentV, Matrix4x4 prevV, Matrix4x4 prevP)
        {
            commandBuffer.SetGlobalFloat(ShaderProperties.frameNumber_PROPERTY, (float)(frame));
            bool isFirstLayerRendered = true;
            bool isFirstLightningLayerRendered = true;

            RenderTargetIdentifier[] overlapFlipRaysRenderTextures = { new RenderTargetIdentifier(packedOverlapRaysRT[true]) };
            RenderTargetIdentifier[] overlapFlopRaysRenderTextures = { new RenderTargetIdentifier(packedOverlapRaysRT[false]) };
            RenderTargetIdentifier[] debugRenderTextures = { new RenderTargetIdentifier(unpackedNewRaysRT), new RenderTargetIdentifier(unpackedMotionVectorsRT), new RenderTargetIdentifier(unpackedMaxDepthRT), new RenderTargetIdentifier(weightedDepthRTDebug) };

            foreach (var intersection in intersections)
            {
                List<CloudsRaymarchedVolume> overlapLayers = intersection.overlapInterval.volumes;

                bool renderOverlap = intersection.overlapInterval.volumes.Count > 1;
                bool firstOverlapLayer = true, useOverlapFlipRaysBuffer = true;
                if (renderOverlap) overlapLayers = overlapLayers.OrderBy(x => x.RaymarchingSettings.OverlapRenderOrder).ToList();

                for (int i = 0; i < overlapLayers.Count; i++)
                {
                    var layer = overlapLayers[i];
                    var cloudMaterial = layer.RaymarchedCloudMaterial;

                    Lightning.SetShaderParams(cloudMaterial);

                    // set material properties
                    cloudMaterial.SetVector(ShaderProperties.reconstructedTextureResolution_PROPERTY, new Vector2(screenWidth, screenHeight));
                    cloudMaterial.SetVector(ShaderProperties.invReconstructedTextureResolution_PROPERTY, new Vector2(1.0f / screenWidth, 1.0f / screenHeight));
                    cloudMaterial.SetVector(ShaderProperties.paddedReconstructedTextureResolution_PROPERTY, new Vector2(paddedScreenWidth, paddedScreenHeight));

                    cloudMaterial.SetInt(ShaderProperties.reprojectionXfactor_PROPERTY, reprojectionXfactor);
                    cloudMaterial.SetInt(ShaderProperties.reprojectionYfactor_PROPERTY, reprojectionYfactor);

                    cloudMaterial.SetMatrix(ShaderProperties.CameraToWorld_PROPERTY, targetCamera.cameraToWorldMatrix);
                    cloudMaterial.SetVector(ShaderProperties.reprojectionUVOffset_PROPERTY, uvOffset);

                    cloudMaterial.SetFloat(ShaderProperties.useOrbitMode_PROPERTY, orbitMode ? 1f : 0f);
                    cloudMaterial.SetFloat(ShaderProperties.outerLayerRadius_PROPERTY, outerCloudsRadius);

                    Matrix4x4 cloudPreviousV = prevV;

                    // inject upwards noise offset, but only at low timewarp values, otherwise the movement is too much and adds artifacts
                    if (TimeWarp.CurrentRate <= 2f)
                    {
                        Vector3 noiseReprojectionOffset = currentV.MultiplyVector(-layer.NoiseReprojectionOffset);

                        cloudPreviousV.m03 += noiseReprojectionOffset.x;
                        cloudPreviousV.m13 += noiseReprojectionOffset.y;
                        cloudPreviousV.m23 += noiseReprojectionOffset.z;
                    }

                    cloudMaterial.SetMatrix(ShaderProperties.currentVP_PROPERTY, currentP * currentV);
                    cloudMaterial.SetMatrix(ShaderProperties.previousVP_PROPERTY, prevP * cloudPreviousV * layer.WorldOppositeFrameDeltaRotationMatrix); // inject the rotation of the cloud layer itself

                    commandBuffer.SetGlobalFloat(ShaderProperties.isFirstLayerRendered_PROPERTY, isFirstLayerRendered ? 1f : 0f);
                    commandBuffer.SetGlobalFloat(ShaderProperties.renderSecondLayerIntersect_PROPERTY, intersection.isSecondIntersect ? 1f : 0f);
                    commandBuffer.SetGlobalTexture(ShaderProperties.PreviousLayerRays_PROPERTY, packedNewRaysRT[!useFlipRaysBuffer]);

                    commandBuffer.SetGlobalFloat(ShaderProperties.currentIntervalInnerRadius_PROPERTY, intersection.overlapInterval.InnerRadius);
                    commandBuffer.SetGlobalFloat(ShaderProperties.currentIntervalOuterRadius_PROPERTY, intersection.overlapInterval.OuterRadius);

                    if (!renderOverlap)
                    {
                        commandBuffer.SetRenderTarget(useFlipRaysBuffer ? flipRaysRenderTextures : flopRaysRenderTextures, packedNewRaysRT[true].depthBuffer);
                        commandBuffer.DisableShaderKeyword("RENDER_OVERLAP_ON");
                        commandBuffer.DrawRenderer(layer.volumeMeshrenderer, cloudMaterial, 0, renderCloudsPass);

                        if (packedTexturesDebugMode)
                        {
                            var textureToDebug = (useFlipRaysBuffer ? flipRaysRenderTextures : flopRaysRenderTextures)[0];
                            UnpackTextures(textureToDebug, commandBuffer, debugRenderTextures, layer.volumeMeshrenderer);
                        }
                    }
                    else
                    {
                        bool lastOverlapLayer = i == overlapLayers.Count - 1;

                        if (!lastOverlapLayer)
                        {
                            commandBuffer.SetRenderTarget(useOverlapFlipRaysBuffer ? overlapFlipRaysRenderTextures : overlapFlopRaysRenderTextures, packedOverlapRaysRT[true].depthBuffer);
                        }
                        else
                        { 
                            commandBuffer.SetRenderTarget(useFlipRaysBuffer ? flipRaysRenderTextures : flopRaysRenderTextures, packedNewRaysRT[true].depthBuffer);
                        }

                        commandBuffer.EnableShaderKeyword("RENDER_OVERLAP_ON");
                        commandBuffer.SetGlobalFloat(ShaderProperties.firstOverlapLayer_PROPERTY, firstOverlapLayer ? 1f : 0f);
                        commandBuffer.SetGlobalFloat(ShaderProperties.lastOverlapLayer_PROPERTY, lastOverlapLayer ? 1f : 0f);

                        commandBuffer.SetGlobalTexture(ShaderProperties.PreviousLayerOverlapRays_PROPERTY, packedOverlapRaysRT[!useOverlapFlipRaysBuffer]);

                        commandBuffer.DrawRenderer(layer.volumeMeshrenderer, cloudMaterial, 0, renderCloudsPass);

                        if (packedTexturesDebugMode)
                        {
                            var textureToDebug = (!lastOverlapLayer ? (useOverlapFlipRaysBuffer ? overlapFlipRaysRenderTextures : overlapFlopRaysRenderTextures) : (useFlipRaysBuffer ? flipRaysRenderTextures : flopRaysRenderTextures))[0];
                            UnpackTextures(textureToDebug, commandBuffer, debugRenderTextures, layer.volumeMeshrenderer);
                        }

                        useOverlapFlipRaysBuffer = !useOverlapFlipRaysBuffer;
                        firstOverlapLayer = false;
                    }

                    if (Lightning.CurrentCount > 0)
                    {
                        commandBuffer.SetGlobalFloat(ShaderProperties.isFirstLightningLayerRendered_PROPERTY, isFirstLightningLayerRendered ? 1f : 0f);
                        commandBuffer.SetGlobalTexture(ShaderProperties.PreviousLayerLightningOcclusion_PROPERTY, lightningOcclusionRT[!useLightningFlipRaysBuffer]);
                        commandBuffer.SetRenderTarget(useLightningFlipRaysBuffer ? lightningOcclusionRT[true] : lightningOcclusionRT[false], lightningOcclusionRT[true].depthBuffer);
                        commandBuffer.DrawRenderer(layer.volumeMeshrenderer, cloudMaterial, 0, renderLightingOcclusionPass);

                        isFirstLightningLayerRendered = false;
                        useLightningFlipRaysBuffer = !useLightningFlipRaysBuffer;
                    }
                }

                isFirstLayerRendered = false;
                useFlipRaysBuffer = !useFlipRaysBuffer;
            }

            // Unpack color and motion vectors textures to speed up reconstruction
            var mr1 = volumesAdded.ElementAt(0).volumeHolder.GetComponent<MeshRenderer>(); // TODO: replace with its own quad?
            RenderTargetIdentifier[] unpackedRenderTextures = { new RenderTargetIdentifier(unpackedNewRaysRT), new RenderTargetIdentifier(unpackedMotionVectorsRT), new RenderTargetIdentifier(unpackedMaxDepthRT) };
            UnpackTextures(packedNewRaysRT[!useFlipRaysBuffer], commandBuffer, unpackedRenderTextures, mr1);

            // reconstruct full frame from history and new rays texture
            RenderTargetIdentifier[] flipIdentifiers = { new RenderTargetIdentifier(historyRT[isRightEye][true]), new RenderTargetIdentifier(historyMotionVectorsRT[isRightEye][true]) };
            RenderTargetIdentifier[] flopIdentifiers = { new RenderTargetIdentifier(historyRT[isRightEye][false]), new RenderTargetIdentifier(historyMotionVectorsRT[isRightEye][false]) };
            RenderTargetIdentifier[] targetIdentifiers = useFlipScreenBuffer ? flipIdentifiers : flopIdentifiers;

            commandBuffer.SetRenderTarget(targetIdentifiers, historyRT[isRightEye][true].depthBuffer);

            reconstructCloudsMaterial.SetMatrix(ShaderProperties.previousVP_PROPERTY, prevP * prevV);

            bool readFromFlip = !useFlipScreenBuffer; // "useFlipScreenBuffer" means the *target* is flip, and we should be reading from flop

            commandBuffer.SetGlobalTexture(ShaderProperties.historyBuffer_PROPERTY, historyRT[isRightEye][readFromFlip]);
            commandBuffer.SetGlobalTexture(ShaderProperties.historyMotionVectors_PROPERTY, historyMotionVectorsRT[isRightEye][readFromFlip]);

            commandBuffer.SetGlobalTexture(ShaderProperties.newRaysBuffer_PROPERTY, unpackedNewRaysRT);
            commandBuffer.SetGlobalTexture(ShaderProperties.newRaysBufferBilinear_PROPERTY, unpackedNewRaysRT);
            commandBuffer.SetGlobalTexture(ShaderProperties.newRaysMotionVectors_PROPERTY, unpackedMotionVectorsRT);
            commandBuffer.SetGlobalTexture(ShaderProperties.newRaysMaxDepthBuffer_PROPERTY, unpackedMaxDepthRT);

            reconstructCloudsMaterial.SetFloat(ShaderProperties.innerSphereRadius_PROPERTY, innerCloudsRadius);
            reconstructCloudsMaterial.SetFloat(ShaderProperties.outerSphereRadius_PROPERTY, outerCloudsRadius);
            reconstructCloudsMaterial.SetFloat(ShaderProperties.planetRadius_PROPERTY, volumesAdded.ElementAt(0).PlanetRadius);
            reconstructCloudsMaterial.SetVector(ShaderProperties.sphereCenter_PROPERTY, volumesAdded.ElementAt(0).RaymarchedCloudMaterial.GetVector(ShaderProperties.sphereCenter_PROPERTY)); //TODO: cleaner way to handle it

            reconstructCloudsMaterial.SetMatrix(ShaderProperties.CameraToWorld_PROPERTY, targetCamera.cameraToWorldMatrix);

            reconstructCloudsMaterial.SetFloat(ShaderProperties.useOrbitMode_PROPERTY, orbitMode ? 1f : 0f);

            if (useCombinedOpenGLDistanceBuffer && DepthToDistanceCommandBuffer.RenderTexture)
                reconstructCloudsMaterial.SetTexture(ShaderProperties.combinedOpenGLDistanceBuffer_PROPERTY, DepthToDistanceCommandBuffer.RenderTexture);

            commandBuffer.DrawRenderer(mr1, reconstructCloudsMaterial, 0, cloudsScreenshotModeEnabled ? 1 : 0);
        }

        private void UnpackTextures(RenderTargetIdentifier inputTexture, CommandBuffer commandBuffer, RenderTargetIdentifier[] unpackedRenderTextures, MeshRenderer meshRenderer)
        {
            commandBuffer.SetRenderTarget(unpackedRenderTextures, packedNewRaysRT[true].depthBuffer);
            commandBuffer.SetGlobalTexture(ShaderProperties.PreviousLayerRays_PROPERTY, inputTexture);
            commandBuffer.DrawRenderer(meshRenderer, unpackRaysMaterial, 0, 0);
        }

        public void SetTemporalReprojectionParams(out Vector2 uvOffset)
        {
            int frame = Time.frameCount % (reprojectionXfactor * reprojectionYfactor);

            if (reorderedSamplingSequence != null)
            {
                frame = reorderedSamplingSequence[frame];
            }

            //figure out the current targeted pixel
            Vector2 currentPixel = new Vector2(frame % reprojectionXfactor, frame / reprojectionXfactor);

            //figure out the offset from center pixel when we are rendering, to be used in the raymarching shader
            Vector2 centerPixel = new Vector2((float)(reprojectionXfactor - 1) * 0.5f, (float)(reprojectionYfactor - 1) * 0.5f);
            Vector2 pixelOffset = currentPixel - centerPixel;
            uvOffset = pixelOffset / new Vector2(screenWidth, screenHeight);

            reconstructCloudsMaterial.SetVector(ShaderProperties.reprojectionCurrentPixel_PROPERTY, currentPixel);
            reconstructCloudsMaterial.SetVector(ShaderProperties.reprojectionUVOffset_PROPERTY, uvOffset);
        }

        void OnPostRender()
        {
            if (!isInitialized)
            {
                Initialize();
            }
            else
            {
                Shader.SetGlobalFloat(ShaderProperties.scattererCloudLightVolumeEnabled_PROPERTY, renderingEnabled && useLightVolume ? 1f : 0f);

                bool doneRendering = targetCamera.stereoActiveEye != Camera.MonoOrStereoscopicEye.Left;

                if (renderingEnabled)
                {
                    bool isRightEye = targetCamera.stereoActiveEye == Camera.MonoOrStereoscopicEye.Right;
                    var commandBuffer = this.commandBuffer[isRightEye];

                    targetCamera.RemoveCommandBuffer(CameraEvent.AfterForwardOpaque, commandBuffer);

                    previousP[isRightEye] = GL.GetGPUProjectionMatrix(VRUtils.GetNonJitteredProjectionMatrixForCamera(targetCamera), false);
                    previousV[isRightEye] = VRUtils.GetViewMatrixForCamera(targetCamera);
                    if (doneRendering)
                    {
                        Shader.SetGlobalTexture(ShaderProperties.scattererReconstructedCloud_PROPERTY, Texture2D.whiteTexture);                        
                        renderingEnabled = false;
                        volumesAdded.Clear();
                        volumesBounds.Clear();

                        useFlipScreenBuffer = !useFlipScreenBuffer;
                    }
                }

                if (doneRendering)
                {
                    DeferredRaymarchedRendererToScreen.SetActive(false);
                    LightVolume.Instance.NotifyRenderingEnded();

                    renderingEnabled = false;
                }
            }
        }

        void Cleanup()
        {
            ReleaseRenderTextures();

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

        private void ReleaseRenderTextures()
        {
            VRUtils.ReleaseVRFlipFlopRT(ref historyRT);
            VRUtils.ReleaseVRFlipFlopRT(ref historyMotionVectorsRT);
            
            RenderTextureUtils.ReleaseFlipFlopRT(ref packedNewRaysRT);
            RenderTextureUtils.ReleaseFlipFlopRT(ref lightningOcclusionRT);

            RenderTextureUtils.ReleaseFlipFlopRT(ref packedOverlapRaysRT);

            if (unpackedNewRaysRT)
                unpackedNewRaysRT.Release();

            if (unpackedMotionVectorsRT)
                unpackedMotionVectorsRT.Release();

            if (packedTexturesDebugMode)
            {   
                if (unpackedMaxDepthRT)
                    unpackedMaxDepthRT.Release();
                
                if (weightedDepthRTDebug)
                    weightedDepthRTDebug.Release();
            }

        }

        public void OnDestroy()
        {
            Cleanup();
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
        public Material compositeColorMaterial;
        public Material depthOcclusionMaterial;

        MeshRenderer compositeMR;
        bool isActive = false;
        bool activationRequested = false;

        public void Init()
        {
            compositeColorMaterial = new Material(ShaderLoaderClass.FindShader("EVE/CompositeRaymarchedClouds"));
            compositeColorMaterial.renderQueue = 4000; //TODO: Fix, for some reason scatterer sky was drawing over it

            depthOcclusionMaterial = new Material(ShaderLoaderClass.FindShader("EVE/CloudDepthOcclusion"));
            depthOcclusionMaterial.renderQueue = 1000; // before anything opaque

            Quad.Create(gameObject, 2, Color.white, Vector3.up, Mathf.Infinity);

            compositeMR = gameObject.AddComponent<MeshRenderer>();
            compositeColorMaterial.SetOverrideTag("IgnoreProjector", "True");
            depthOcclusionMaterial.SetOverrideTag("IgnoreProjector", "True");

            // Depth occlusion doesn't work with deferred rendering because it doesn't have a depth prepass, just disable it entirely for now
            // any speedups were negligible anyway
            /*
            if (Tools.IsUnifiedCameraMode())
            {
                compositeMR.materials = new List<Material>() { compositeColorMaterial, depthOcclusionMaterial }.ToArray();
            }
            else
            */
            {
                compositeMR.materials = new List<Material>() { compositeColorMaterial }.ToArray();
            }

            compositeMR.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            compositeMR.receiveShadows = false;
            compositeMR.enabled = true;
            compositeColorMaterial.SetFloat(ShaderProperties.rendererEnabled_PROPERTY, 0f);
            depthOcclusionMaterial.SetFloat(ShaderProperties.rendererEnabled_PROPERTY, 0f);

            gameObject.layer = (int)Tools.Layer.Local;
        }

        public void SetActive(bool active)
        {
            compositeColorMaterial.SetFloat(ShaderProperties.rendererEnabled_PROPERTY, active ? 1f : 0f);
            depthOcclusionMaterial.SetFloat(ShaderProperties.rendererEnabled_PROPERTY, active ? 1f : 0f);

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
            compositeColorMaterial.SetFloat(ShaderProperties.cloudFade_PROPERTY, fade);
            depthOcclusionMaterial.SetFloat(ShaderProperties.cloudFade_PROPERTY, fade);
        }
    }
}
