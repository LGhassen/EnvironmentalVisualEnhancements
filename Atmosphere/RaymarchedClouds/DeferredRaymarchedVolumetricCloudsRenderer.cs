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
                if ((cam.name == "TRReflectionCamera") || (cam.name == "Reflection Probes Camera"))
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
                    CameraToDeferredRaymarchedVolumetricCloudsRenderer[cam] = (DeferredRaymarchedVolumetricCloudsRenderer)cam.gameObject.AddComponent(typeof(DeferredRaymarchedVolumetricCloudsRenderer));

                    if (!Tools.IsUnifiedCameraMode() && cam.name == "Camera 00")
                    {
                        CameraToDeferredRaymarchedVolumetricCloudsRenderer[cam].useCombinedOpenGLDistanceBuffer = true;
                        cam.gameObject.AddComponent<DepthToDistanceCommandBuffer>();
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

        // list of intersections sorted by distance, for rendering closest to farthest, such that already occluded layers in the distance don't add any raymarching cost
        List<raymarchedLayerIntersection> intersections = new List<raymarchedLayerIntersection>();

        // these are indexed by [isRightEye][flip]
        private FlipFlop<FlipFlop<RenderTexture>> historyRT, historyMotionVectorsRT;
        // these are indexed by [flip]
        private FlipFlop<RenderTexture> newRaysRT, newMotionVectorsRT, lightningOcclusionRT, maxDepthRT;

        bool useFlipScreenBuffer = true;
        Material reconstructCloudsMaterial;

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

        private bool useCombinedOpenGLDistanceBuffer = false;

        private bool cloudsScreenshotModeEnabled = false;

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
            SetCombinedOpenGLDepthBufferKeywords(reconstructCloudsMaterial);

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

                RenderTextureUtils.ResizeFlipFlopRT(ref newRaysRT, newRaysRenderWidth, newRaysRenderHeight);
                RenderTextureUtils.ResizeFlipFlopRT(ref newMotionVectorsRT, newRaysRenderWidth, newRaysRenderHeight);
                RenderTextureUtils.ResizeFlipFlopRT(ref maxDepthRT, newRaysRenderWidth, newRaysRenderHeight);

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

        private void SetCombinedOpenGLDepthBufferKeywords(Material material)
        {
            if (useCombinedOpenGLDistanceBuffer)
            {
                material.EnableKeyword("OPENGL_COMBINEDBUFFER_ON");
                material.DisableKeyword("OPENGL_COMBINEDBUFFER_OFF");
            }
            else
            {
                material.DisableKeyword("OPENGL_COMBINEDBUFFER_ON");
                material.EnableKeyword("OPENGL_COMBINEDBUFFER_OFF");
            }
        }

        private void InitRenderTextures()
        {
            var colorFormat = RenderTextureFormat.DefaultHDR;
            bool supportVR = VRUtils.VREnabled();

            ReleaseRenderTextures();

            historyRT = VRUtils.CreateVRFlipFlopRT(supportVR, screenWidth, screenHeight, colorFormat, FilterMode.Bilinear);
            historyMotionVectorsRT = VRUtils.CreateVRFlipFlopRT(supportVR, screenWidth, screenHeight, RenderTextureFormat.RGHalf, FilterMode.Bilinear);

            newRaysRT = RenderTextureUtils.CreateFlipFlopRT(newRaysRenderWidth, newRaysRenderHeight, colorFormat, FilterMode.Point);
            newMotionVectorsRT = RenderTextureUtils.CreateFlipFlopRT(newRaysRenderWidth, newRaysRenderHeight, RenderTextureFormat.RGHalf, FilterMode.Point);
            maxDepthRT = RenderTextureUtils.CreateFlipFlopRT(newRaysRenderWidth, newRaysRenderHeight, RenderTextureFormat.RHalf, FilterMode.Bilinear);

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

                renderingEnabled = true;                    
                DeferredRaymarchedRendererToScreen.SetActive(true);
                
                Lightning.UpdateExisting();
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
                HandleScreenshotMode();

                // calculate intersections and intersection distances for each layer if we're inside layer -> 1 intersect with distance 0 and 1 intersect with distance camAltitude + 2*planetRadius+innerLayerAlt (layers must not overlap, possibly enforce this in the Clouds class?)
                // if we're lower than the layer -> 1 intersect with distance camAltitude + 2*radius+innerLayerAlt
                // if we're higher than the layer -> 1 intersect with distance camAltitude - outerLayerAltitude
                intersections.Clear();
                float innerCloudsRadius = float.MaxValue, outerCloudsRadius = float.MinValue;

                float cloudFade = 1f;

                float camDistanceToPlanetOrigin = float.MaxValue;

                Vector3 cameraPosition = gameObject.transform.position;

                useLightVolume = false;
                float lightVolumeMaxRadius = Mathf.Infinity;

                float innerLightVolumeRadius = float.MaxValue, outerLightVolumeRadius = float.MinValue;

                float lightVolumeSlowestRotatingLayerSpeed = float.MaxValue;
                CloudsRaymarchedVolume lightVolumeSlowestRotatingLayer = null;

                foreach (CloudsRaymarchedVolume volumetricLayer in volumesAdded)
                {
                    // calculate camera altitude, doing it per volume is overkill, but let's leave it so if we render volumetrics on multiple planets at the same time it will still work
                    camDistanceToPlanetOrigin = (cameraPosition - volumetricLayer.ParentTransform.position).magnitude;

                    if (camDistanceToPlanetOrigin >= volumetricLayer.InnerSphereRadius && camDistanceToPlanetOrigin <= volumetricLayer.OuterSphereRadius)
                    {
                        intersections.Add(new raymarchedLayerIntersection() { distance = 0f, layer = volumetricLayer, isSecondIntersect = false });
                        intersections.Add(new raymarchedLayerIntersection() { distance = camDistanceToPlanetOrigin + volumetricLayer.InnerSphereRadius, layer = volumetricLayer, isSecondIntersect = true });
                    }
                    else if (camDistanceToPlanetOrigin < volumetricLayer.InnerSphereRadius)
                    {
                        intersections.Add(new raymarchedLayerIntersection() { distance = camDistanceToPlanetOrigin + volumetricLayer.InnerSphereRadius, layer = volumetricLayer, isSecondIntersect = false });
                    }
                    else if (camDistanceToPlanetOrigin > volumetricLayer.OuterSphereRadius)
                    {
                        intersections.Add(new raymarchedLayerIntersection() { distance = camDistanceToPlanetOrigin - volumetricLayer.OuterSphereRadius, layer = volumetricLayer, isSecondIntersect = false });
                        intersections.Add(new raymarchedLayerIntersection() { distance = camDistanceToPlanetOrigin + volumetricLayer.InnerSphereRadius, layer = volumetricLayer, isSecondIntersect = true });
                    }

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

                if (useLightVolume)
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
                RenderTargetIdentifier[] flipRaysRenderTextures = { new RenderTargetIdentifier(newRaysRT[true]), new RenderTargetIdentifier(newMotionVectorsRT[true]), new RenderTargetIdentifier(maxDepthRT[true]) };
                RenderTargetIdentifier[] flopRaysRenderTextures = { new RenderTargetIdentifier(newRaysRT[false]), new RenderTargetIdentifier(newMotionVectorsRT[false]), new RenderTargetIdentifier(maxDepthRT[false]) };
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

                if (useCombinedOpenGLDistanceBuffer && DepthToDistanceCommandBuffer.RenderTexture)
                    commandBuffer.SetGlobalTexture(ShaderProperties.combinedOpenGLDistanceBuffer_PROPERTY, DepthToDistanceCommandBuffer.RenderTexture);

                SetTemporalReprojectionParams(out Vector2 uvOffset);
                int frame = Time.frameCount % ShaderLoader.ShaderLoaderClass.stbnDimensions.z;

                bool useFlipRaysBuffer = true;

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

                for (int i=0; i< renderingIterations; i++)
                {
                    HandleRenderingCommands(innerCloudsRadius, outerCloudsRadius, orbitMode, isRightEye, flipRaysRenderTextures, flopRaysRenderTextures, commandBuffer, uvOffset, frame, ref useFlipRaysBuffer, currentP, currentV, prevV, prevP);
                    frame++;
                    frame = frame % ShaderLoader.ShaderLoaderClass.stbnDimensions.z;
                }

                commandBuffer.SetGlobalTexture(ShaderProperties.colorBuffer_PROPERTY, historyRT[isRightEye][useFlipScreenBuffer]);

                // Set texture for scatterer sunflare: temporary
                commandBuffer.SetGlobalTexture(ShaderProperties.scattererReconstructedCloud_PROPERTY, historyRT[isRightEye][useFlipScreenBuffer]);

                commandBuffer.SetGlobalTexture(ShaderProperties.lightningOcclusion_PROPERTY, lightningOcclusionRT[!useFlipRaysBuffer]);
                commandBuffer.SetGlobalTexture(ShaderProperties.maxDepthRT_PROPERTY, maxDepthRT[!useFlipRaysBuffer]);

                //commandBuffer.SetGlobalVector(ShaderProperties.reconstructedTextureResolution_PROPERTY, new Vector2(screenWidth, screenHeight));
                DeferredRaymarchedRendererToScreen.compositeColorMaterial.renderQueue = 2998;

                targetCamera.AddCommandBuffer(CameraEvent.BeforeForwardOpaque, commandBuffer);
            }
        }

        private void HandleRenderingCommands(float innerCloudsRadius, float outerCloudsRadius, bool orbitMode, bool isRightEye, RenderTargetIdentifier[] flipRaysRenderTextures, RenderTargetIdentifier[] flopRaysRenderTextures, CommandBuffer commandBuffer, Vector2 uvOffset, int frame, ref bool useFlipRaysBuffer, Matrix4x4 currentP, Matrix4x4 currentV, Matrix4x4 prevV, Matrix4x4 prevP)
        {
            commandBuffer.SetGlobalFloat(ShaderProperties.frameNumber_PROPERTY, (float)(frame));
            bool isFirstLayerRendered = true;

            foreach (var intersection in intersections)
            {
                var cloudMaterial = intersection.layer.RaymarchedCloudMaterial;

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

                cloudMaterial.SetFloat(ShaderProperties.useCombinedOpenGLDistanceBuffer_PROPERTY, useCombinedOpenGLDistanceBuffer ? 1f : 0f);

                Matrix4x4 cloudPreviousV = prevV;

                // inject upwards noise offset, but only at low timewarp values, otherwise the movement is too much and adds artifacts
                if (TimeWarp.CurrentRate <= 2f)
                {
                    Vector3 noiseReprojectionOffset = currentV.MultiplyVector(-intersection.layer.NoiseReprojectionOffset);

                    cloudPreviousV.m03 += noiseReprojectionOffset.x;
                    cloudPreviousV.m13 += noiseReprojectionOffset.y;
                    cloudPreviousV.m23 += noiseReprojectionOffset.z;
                }

                cloudMaterial.SetMatrix(ShaderProperties.currentVP_PROPERTY, currentP * currentV);
                cloudMaterial.SetMatrix(ShaderProperties.previousVP_PROPERTY, prevP * cloudPreviousV * intersection.layer.WorldOppositeFrameDeltaRotationMatrix);    // inject the rotation of the cloud layer itself

                // handle the actual rendering
                commandBuffer.SetRenderTarget(useFlipRaysBuffer ? flipRaysRenderTextures : flopRaysRenderTextures, newRaysRT[true].depthBuffer);
                commandBuffer.SetGlobalFloat(ShaderProperties.isFirstLayerRendered_PROPERTY, isFirstLayerRendered ? 1f : 0f);
                commandBuffer.SetGlobalFloat(ShaderProperties.renderSecondLayerIntersect_PROPERTY, intersection.isSecondIntersect ? 1f : 0f);
                commandBuffer.SetGlobalTexture(ShaderProperties.PreviousLayerRays_PROPERTY, newRaysRT[!useFlipRaysBuffer]);
                commandBuffer.SetGlobalTexture(ShaderProperties.PreviousLayerMotionVectors_PROPERTY, newMotionVectorsRT[!useFlipRaysBuffer]);
                commandBuffer.SetGlobalTexture(ShaderProperties.PreviousLayerMaxDepth_PROPERTY, maxDepthRT[!useFlipRaysBuffer]);

                commandBuffer.DrawRenderer(intersection.layer.volumeMeshrenderer, cloudMaterial, 0, 0); // pass 0 render clouds

                if (Lightning.CurrentCount > 0)
                {
                    commandBuffer.SetGlobalTexture(ShaderProperties.PreviousLayerLightningOcclusion_PROPERTY, lightningOcclusionRT[!useFlipRaysBuffer]);
                    commandBuffer.SetRenderTarget(useFlipRaysBuffer ? lightningOcclusionRT[true] : lightningOcclusionRT[false], lightningOcclusionRT[true].depthBuffer);
                    commandBuffer.DrawRenderer(intersection.layer.volumeMeshrenderer, cloudMaterial, 0, 1); // pass 1 render lightning occlusion
                }

                isFirstLayerRendered = false;
                useFlipRaysBuffer = !useFlipRaysBuffer;
            }

            //reconstruct full frame from history and new rays texture
            RenderTargetIdentifier[] flipIdentifiers = { new RenderTargetIdentifier(historyRT[isRightEye][true]), new RenderTargetIdentifier(historyMotionVectorsRT[isRightEye][true]) };
            RenderTargetIdentifier[] flopIdentifiers = { new RenderTargetIdentifier(historyRT[isRightEye][false]), new RenderTargetIdentifier(historyMotionVectorsRT[isRightEye][false]) };
            RenderTargetIdentifier[] targetIdentifiers = useFlipScreenBuffer ? flipIdentifiers : flopIdentifiers;

            commandBuffer.SetRenderTarget(targetIdentifiers, historyRT[isRightEye][true].depthBuffer);

            reconstructCloudsMaterial.SetMatrix(ShaderProperties.previousVP_PROPERTY, prevP * prevV);

            bool readFromFlip = !useFlipScreenBuffer; // "useFlipScreenBuffer" means the *target* is flip, and we should be reading from flop
            commandBuffer.SetGlobalTexture(ShaderProperties.historyBuffer_PROPERTY, historyRT[isRightEye][readFromFlip]); // these probably need to be global
            commandBuffer.SetGlobalTexture(ShaderProperties.historyMotionVectors_PROPERTY, historyMotionVectorsRT[isRightEye][readFromFlip]);

            commandBuffer.SetGlobalTexture(ShaderProperties.newRaysBuffer_PROPERTY, newRaysRT[!useFlipRaysBuffer]);
            commandBuffer.SetGlobalTexture(ShaderProperties.newRaysBufferBilinear_PROPERTY, newRaysRT[!useFlipRaysBuffer]);
            commandBuffer.SetGlobalTexture(ShaderProperties.newRaysMotionVectors_PROPERTY, newMotionVectorsRT[!useFlipRaysBuffer]);

            reconstructCloudsMaterial.SetFloat(ShaderProperties.innerSphereRadius_PROPERTY, innerCloudsRadius);
            reconstructCloudsMaterial.SetFloat(ShaderProperties.outerSphereRadius_PROPERTY, outerCloudsRadius);
            reconstructCloudsMaterial.SetFloat(ShaderProperties.planetRadius_PROPERTY, volumesAdded.ElementAt(0).PlanetRadius);
            reconstructCloudsMaterial.SetVector(ShaderProperties.sphereCenter_PROPERTY, volumesAdded.ElementAt(0).RaymarchedCloudMaterial.GetVector(ShaderProperties.sphereCenter_PROPERTY)); //TODO: cleaner way to handle it

            reconstructCloudsMaterial.SetMatrix(ShaderProperties.CameraToWorld_PROPERTY, targetCamera.cameraToWorldMatrix);

            //reconstructCloudsMaterial.SetFloat(ShaderProperties.frameNumber_PROPERTY, (float)(frame));
            reconstructCloudsMaterial.SetFloat(ShaderProperties.useOrbitMode_PROPERTY, orbitMode ? 1f : 0f);

            if (useCombinedOpenGLDistanceBuffer && DepthToDistanceCommandBuffer.RenderTexture)
                reconstructCloudsMaterial.SetTexture(ShaderProperties.combinedOpenGLDistanceBuffer_PROPERTY, DepthToDistanceCommandBuffer.RenderTexture);

            var mr1 = volumesAdded.ElementAt(0).volumeHolder.GetComponent<MeshRenderer>(); // TODO: replace with its own quad?
            commandBuffer.DrawRenderer(mr1, reconstructCloudsMaterial, 0, cloudsScreenshotModeEnabled ? 1 : 0);
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

                    targetCamera.RemoveCommandBuffer(CameraEvent.BeforeForwardOpaque, commandBuffer);

                    previousP[isRightEye] = GL.GetGPUProjectionMatrix(VRUtils.GetNonJitteredProjectionMatrixForCamera(targetCamera), false);
                    previousV[isRightEye] = VRUtils.GetViewMatrixForCamera(targetCamera);
                    if (doneRendering)
                    {
                        Shader.SetGlobalTexture(ShaderProperties.scattererReconstructedCloud_PROPERTY, Texture2D.whiteTexture);                        
                        renderingEnabled = false;
                        volumesAdded.Clear();

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
                    targetCamera.RemoveCommandBuffer(CameraEvent.BeforeForwardOpaque, commandBuffer[true]);
                }
                targetCamera.RemoveCommandBuffer(CameraEvent.BeforeForwardOpaque, commandBuffer[false]);
                volumesAdded.Clear();
            }

            renderingEnabled = false;
            isInitialized = false;
        }

        private void ReleaseRenderTextures()
        {
            VRUtils.ReleaseVRFlipFlopRT(ref historyRT);
            VRUtils.ReleaseVRFlipFlopRT(ref historyMotionVectorsRT);
            RenderTextureUtils.ReleaseFlipFlopRT(ref newRaysRT);
            RenderTextureUtils.ReleaseFlipFlopRT(ref newMotionVectorsRT);
            RenderTextureUtils.ReleaseFlipFlopRT(ref lightningOcclusionRT);
            RenderTextureUtils.ReleaseFlipFlopRT(ref maxDepthRT);
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
            depthOcclusionMaterial.renderQueue = 1000; // before everything opaque

            Quad.Create(gameObject, 2, Color.white, Vector3.up, Mathf.Infinity);

            compositeMR = gameObject.AddComponent<MeshRenderer>();
            compositeColorMaterial.SetOverrideTag("IgnoreProjector", "True");
            depthOcclusionMaterial.SetOverrideTag("IgnoreProjector", "True");

            if (Tools.IsUnifiedCameraMode())
            {
                compositeMR.materials = new List<Material>() { compositeColorMaterial, depthOcclusionMaterial }.ToArray();
            }
            else
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
