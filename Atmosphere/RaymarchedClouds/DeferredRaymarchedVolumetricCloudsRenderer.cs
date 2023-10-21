﻿using System.Collections.Generic;
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
        bool hdrEnabled = false;

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
        private static readonly int[] samplingSequence4 = new int[] { 0, 2, 3, 1 };
        private static readonly int[] samplingSequence8 = new int[] { 0, 4, 2, 6, 3, 7, 1, 5 };
        private static readonly int[] samplingSequence16 = new int[] { 0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5 };
        private static readonly int[] samplingSequence32 = new int[] { 0, 16, 8, 24, 4, 20, 12, 28, 2, 18, 10, 26, 6, 22, 14, 30, 1, 17, 9, 25, 5, 21, 13, 29, 3, 19, 11, 27, 7, 23, 15, 31 };
        private static readonly int[] samplingSequence64 = new int[] { 0, 32, 16, 48, 8, 40, 24, 56, 4, 36, 20, 52, 12, 44, 28, 60, 2, 34, 18, 50, 10, 42, 26, 58, 6, 38, 22, 54, 14, 46, 30, 62, 1, 33, 17, 49, 9, 41, 25, 57, 5, 37, 21, 53, 13, 45, 29, 61, 3, 35, 19, 51, 11, 43, 27, 59, 7, 39, 23, 55, 15, 47, 31, 63 };

        int width, height;

        private static readonly int lightningOcclusionResolution = 32;

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

        public DeferredRaymarchedVolumetricCloudsRenderer()
        {
        }

        public void Initialize()
        {
            targetCamera = GetComponent<Camera>();

            if (targetCamera == null || targetCamera.activeTexture == null)
                return;

            SetReprojectionFactors();

            reconstructCloudsMaterial = new Material(ReconstructionShader);
            SetCombinedOpenGLDepthBufferKeywords(reconstructCloudsMaterial);

            bool supportVR = VRUtils.VREnabled();

            if (supportVR)
            {
                VRUtils.GetEyeTextureResolution(out width, out height);
            }
            else
            {
                width = targetCamera.activeTexture.width;
                height = targetCamera.activeTexture.height;
            }

            InitRenderTextures();

            reconstructCloudsMaterial.SetVector("reconstructedTextureResolution", new Vector2(width, height));
            reconstructCloudsMaterial.SetVector("invReconstructedTextureResolution", new Vector2(1.0f / (float)width, 1.0f / (float)height));

            DeferredRaymarchedRendererToScreen.compositeColorMaterial.SetVector("reconstructedTextureResolution", new Vector2(width, height));
            DeferredRaymarchedRendererToScreen.compositeColorMaterial.SetVector("invReconstructedTextureResolution", new Vector2(1.0f / (float)width, 1.0f / (float)height));

            reconstructCloudsMaterial.SetInt("reprojectionXfactor", reprojectionXfactor);
            reconstructCloudsMaterial.SetInt("reprojectionYfactor", reprojectionYfactor);

            commandBuffer = new FlipFlop<CommandBuffer>(VRUtils.VREnabled() ? new CommandBuffer() : null, new CommandBuffer());

            isInitialized = true;
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
            var colorFormat = RenderTextureFormat.ARGBHalf;
            bool supportVR = VRUtils.VREnabled();

            ReleaseRenderTextures();

            historyRT = VRUtils.CreateVRFlipFlopRT(supportVR, width, height, colorFormat, FilterMode.Bilinear);
            historyMotionVectorsRT = VRUtils.CreateVRFlipFlopRT(supportVR, width, height, RenderTextureFormat.RGHalf, FilterMode.Bilinear);

            newRaysRT = RenderTextureUtils.CreateFlipFlopRT(width / reprojectionXfactor, height / reprojectionYfactor, colorFormat, FilterMode.Point);
            newMotionVectorsRT = RenderTextureUtils.CreateFlipFlopRT(width / reprojectionXfactor, height / reprojectionYfactor, RenderTextureFormat.RGHalf, FilterMode.Point);
            lightningOcclusionRT = RenderTextureUtils.CreateFlipFlopRT(lightningOcclusionResolution * Lightning.MaxConcurrent, lightningOcclusionResolution, RenderTextureFormat.R8, FilterMode.Bilinear);
            maxDepthRT = RenderTextureUtils.CreateFlipFlopRT(width / reprojectionXfactor, height / reprojectionYfactor, RenderTextureFormat.RHalf, FilterMode.Bilinear);
        }

        private void SetReprojectionFactors()
        {
            var reprojectionFactors = RaymarchedCloudsQualityManager.GetReprojectionFactors();
            reprojectionXfactor = reprojectionFactors.Item1;
            reprojectionYfactor = reprojectionFactors.Item2;

            var adaptedReprojectionXFactor = FindAdaptedReprojectionFactor(targetCamera.activeTexture.width,  reprojectionXfactor);
            var adaptedReprojectionYFactor = FindAdaptedReprojectionFactor(targetCamera.activeTexture.height, reprojectionYfactor);

            if ((adaptedReprojectionXFactor != reprojectionXfactor) || (adaptedReprojectionYFactor != reprojectionYfactor))
            {
                Debug.LogWarning("[EVE] Temporal reprojection switched to: " + (adaptedReprojectionXFactor * adaptedReprojectionYFactor).ToString() + " on camera " + targetCamera.name +
                    " because screen dimensions " + targetCamera.activeTexture.width.ToString() + " and " + targetCamera.activeTexture.height.ToString() +
                    " are not evenly divisible by " + reprojectionXfactor.ToString() + " and " + reprojectionYfactor.ToString());
            }

            reprojectionXfactor = adaptedReprojectionXFactor;
            reprojectionYfactor = adaptedReprojectionYFactor;
        }

        private int FindAdaptedReprojectionFactor(int cameraDimension, int reprojectionFactor)
        {
            while (cameraDimension % reprojectionFactor != 0)
            {
                reprojectionFactor /= 2;
            }

            return reprojectionFactor;
        }

        public void EnableForThisFrame(CloudsRaymarchedVolume volume)
        {
            if (isInitialized)
            {
                if (hdrEnabled != targetCamera.allowHDR)
                {
                    InitRenderTextures();
                }

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
                // calculate intersections and intersection distances for each layer if we're inside layer -> 1 intersect with distance 0 and 1 intersect with distance camAltitude + 2*planetRadius+innerLayerAlt (layers must not overlap, possibly enforce this in the Clouds class?)
                // if we're lower than the layer -> 1 intersect with distance camAltitude + 2*radius+innerLayerAlt
                // if we're higher than the layer -> 1 intersect with distance camAltitude - outerLayerAltitude
                intersections.Clear();
                float innerReprojectionRadius = float.MaxValue, outerRepojectionRadius = float.MinValue;

                float cloudFade = 1f;

                float camDistanceToPlanetOrigin = float.MaxValue;

                foreach (var elt in volumesAdded)
                {
                    //calculate camera altitude, doing it per volume is overkill, but let's leave it so if we render volumetrics on multiple planets at the same time it will still work
                    camDistanceToPlanetOrigin = (gameObject.transform.position - elt.ParentTransform.position).magnitude;

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

                // if the camera is higher than the highest layer by 2x as high as it is from the ground, enable orbitMode
                bool orbitMode = (TimeWarp.CurrentRate * Time.timeScale < 100f) && RaymarchedCloudsQualityManager.UseOrbitMode && camDistanceToPlanetOrigin - outerRepojectionRadius > 2f * (outerRepojectionRadius - volumesAdded.ElementAt(0).PlanetRadius);

                DeferredRaymarchedRendererToScreen.SetFade(cloudFade);
                var DeferredRaymarchedRendererToScreenMaterial = DeferredRaymarchedRendererToScreen.compositeColorMaterial;
                DeferredRaymarchedRendererToScreenMaterial.SetFloat(ShaderProperties.useOrbitMode_PROPERTY, orbitMode ? 1f : 0f);
                DeferredRaymarchedRendererToScreenMaterial.SetMatrix(ShaderProperties.CameraToWorld_PROPERTY, targetCamera.cameraToWorldMatrix);
                DeferredRaymarchedRendererToScreenMaterial.SetFloat(ShaderProperties.innerSphereRadius_PROPERTY, innerReprojectionRadius);
                DeferredRaymarchedRendererToScreenMaterial.SetFloat(ShaderProperties.outerSphereRadius_PROPERTY, outerRepojectionRadius);
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

                SetTemporalReprojectionParams(out Vector2 uvOffset);
                int frame = Time.frameCount % ShaderLoader.ShaderLoaderClass.stbnDimensions.z;

                bool useFlipRaysBuffer = true;
                bool isFirstLayerRendered  = true;

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

                foreach (var intersection in intersections)
                {
                    var cloudMaterial = intersection.layer.RaymarchedCloudMaterial;

                    Lightning.SetShaderParams(cloudMaterial);

                    //set material properties
                    cloudMaterial.SetVector(ShaderProperties.reconstructedTextureResolution_PROPERTY, new Vector2(width, height));
                    cloudMaterial.SetVector(ShaderProperties.invReconstructedTextureResolution_PROPERTY, new Vector2(1.0f / width, 1.0f / height));

                    cloudMaterial.SetInt(ShaderProperties.reprojectionXfactor_PROPERTY, reprojectionXfactor);
                    cloudMaterial.SetInt(ShaderProperties.reprojectionYfactor_PROPERTY, reprojectionYfactor);

                    cloudMaterial.SetMatrix(ShaderProperties.CameraToWorld_PROPERTY, targetCamera.cameraToWorldMatrix);
                    cloudMaterial.SetVector(ShaderProperties.reprojectionUVOffset_PROPERTY, uvOffset);
                    cloudMaterial.SetFloat(ShaderProperties.frameNumber_PROPERTY, (float)(frame));

                    cloudMaterial.SetFloat(ShaderProperties.useOrbitMode_PROPERTY, orbitMode ? 1f : 0f);
                    cloudMaterial.SetFloat(ShaderProperties.outerLayerRadius_PROPERTY, outerRepojectionRadius);

                    cloudMaterial.SetFloat(ShaderProperties.useCombinedOpenGLDistanceBuffer_PROPERTY, useCombinedOpenGLDistanceBuffer ? 1f : 0f);

                    Vector3 noiseReprojectionOffset = currentV.MultiplyVector(-intersection.layer.NoiseReprojectionOffset);
                    Matrix4x4 cloudPreviousV = prevV;

                    // inject upwards noise offset
                    cloudPreviousV.m03 += noiseReprojectionOffset.x;
                    cloudPreviousV.m13 += noiseReprojectionOffset.y;
                    cloudPreviousV.m23 += noiseReprojectionOffset.z;

                    cloudMaterial.SetMatrix(ShaderProperties.currentVP_PROPERTY, currentP * currentV);
                    cloudMaterial.SetMatrix(ShaderProperties.previousVP_PROPERTY, prevP * cloudPreviousV * intersection.layer.OppositeFrameDeltaRotationMatrix);    // inject the rotation of the cloud layer itself

                    // handle the actual rendering
                    commandBuffer.SetRenderTarget(useFlipRaysBuffer ? flipRaysRenderTextures : flopRaysRenderTextures, newRaysRT[true].depthBuffer);
                    commandBuffer.SetGlobalFloat(ShaderProperties.isFirstLayerRendered_PROPERTY, isFirstLayerRendered ? 1f : 0f);
                    commandBuffer.SetGlobalFloat(ShaderProperties.renderSecondLayerIntersect_PROPERTY, intersection.isSecondIntersect ? 1f : 0f);
                    commandBuffer.SetGlobalTexture(ShaderProperties.PreviousLayerRays_PROPERTY, newRaysRT[!useFlipRaysBuffer]);
                    commandBuffer.SetGlobalTexture(ShaderProperties.PreviousLayerMotionVectors_PROPERTY, newMotionVectorsRT[!useFlipRaysBuffer]);
                    commandBuffer.SetGlobalTexture("PreviousLayerMaxDepth", maxDepthRT[!useFlipRaysBuffer]); // TODO: property

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

                // Set texture for scatterer sunflare: temporary
                commandBuffer.SetGlobalTexture("scattererReconstructedCloud", historyRT[isRightEye][useFlipScreenBuffer]); // TODO: property

                //reconstruct full frame from history and new rays texture
                RenderTargetIdentifier[] flipIdentifiers = { new RenderTargetIdentifier(historyRT[isRightEye][true]), new RenderTargetIdentifier(historyMotionVectorsRT[isRightEye][true]) };
                RenderTargetIdentifier[] flopIdentifiers = { new RenderTargetIdentifier(historyRT[isRightEye][false]), new RenderTargetIdentifier(historyMotionVectorsRT[isRightEye][false]) };
                RenderTargetIdentifier[] targetIdentifiers = useFlipScreenBuffer ? flipIdentifiers : flopIdentifiers;

                commandBuffer.SetRenderTarget(targetIdentifiers, historyRT[isRightEye][true].depthBuffer);

                reconstructCloudsMaterial.SetMatrix(ShaderProperties.previousVP_PROPERTY, prevP * prevV);

                bool readFromFlip = !useFlipScreenBuffer; // "useFlipScreenBuffer" means the *target* is flip, and we should be reading from flop
                reconstructCloudsMaterial.SetTexture(ShaderProperties.historyBuffer_PROPERTY, historyRT[isRightEye][readFromFlip]);
                reconstructCloudsMaterial.SetTexture(ShaderProperties.historyMotionVectors_PROPERTY, historyMotionVectorsRT[isRightEye][readFromFlip]);

                reconstructCloudsMaterial.SetTexture(ShaderProperties.newRaysBuffer_PROPERTY, newRaysRT[!useFlipRaysBuffer]);
                reconstructCloudsMaterial.SetTexture(ShaderProperties.newRaysBufferBilinear_PROPERTY, newRaysRT[!useFlipRaysBuffer]);
                reconstructCloudsMaterial.SetTexture(ShaderProperties.newRaysMotionVectors_PROPERTY, newMotionVectorsRT[!useFlipRaysBuffer]);

                reconstructCloudsMaterial.SetFloat(ShaderProperties.innerSphereRadius_PROPERTY, innerReprojectionRadius);
                reconstructCloudsMaterial.SetFloat(ShaderProperties.outerSphereRadius_PROPERTY, outerRepojectionRadius);
                reconstructCloudsMaterial.SetFloat(ShaderProperties.planetRadius_PROPERTY, volumesAdded.ElementAt(0).PlanetRadius);
                reconstructCloudsMaterial.SetVector(ShaderProperties.sphereCenter_PROPERTY, volumesAdded.ElementAt(0).RaymarchedCloudMaterial.GetVector(ShaderProperties.sphereCenter_PROPERTY)); //TODO: cleaner way to handle it

                reconstructCloudsMaterial.SetMatrix(ShaderProperties.CameraToWorld_PROPERTY, targetCamera.cameraToWorldMatrix);

                reconstructCloudsMaterial.SetFloat(ShaderProperties.frameNumber_PROPERTY, (float)(frame));
                reconstructCloudsMaterial.SetFloat(ShaderProperties.useOrbitMode_PROPERTY, orbitMode ? 1f : 0f);

                if (useCombinedOpenGLDistanceBuffer && DepthToDistanceCommandBuffer.RenderTexture)
                    reconstructCloudsMaterial.SetTexture(ShaderProperties.combinedOpenGLDistanceBuffer_PROPERTY, DepthToDistanceCommandBuffer.RenderTexture);

                var mr1 = volumesAdded.ElementAt(0).volumeHolder.GetComponent<MeshRenderer>(); // TODO: replace with its own quad?
                commandBuffer.DrawRenderer(mr1, reconstructCloudsMaterial, 0, 0);

                commandBuffer.SetGlobalTexture(ShaderProperties.colorBuffer_PROPERTY, historyRT[isRightEye][useFlipScreenBuffer]);

                commandBuffer.SetGlobalTexture(ShaderProperties.lightningOcclusion_PROPERTY, lightningOcclusionRT[!useFlipRaysBuffer]);
                commandBuffer.SetGlobalTexture("maxDepthRT", maxDepthRT[!useFlipRaysBuffer]);

                commandBuffer.SetGlobalVector(ShaderProperties.reconstructedTextureResolution_PROPERTY, new Vector2(width, height));
                DeferredRaymarchedRendererToScreen.compositeColorMaterial.renderQueue = 2998;

                targetCamera.AddCommandBuffer(CameraEvent.BeforeForwardOpaque, commandBuffer);
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
            else if (reprojectionXfactor == 8 && reprojectionYfactor == 4)
            {
                frame = samplingSequence32[frame];
            }
            else if (reprojectionXfactor == 8 && reprojectionYfactor == 8)
            {
                frame = samplingSequence64[frame];
            }

            //figure out the current targeted pixel
            Vector2 currentPixel = new Vector2(frame % reprojectionXfactor, frame / reprojectionXfactor);

            //figure out the offset from center pixel when we are rendering, to be used in the raymarching shader
            Vector2 centerPixel = new Vector2((float)(reprojectionXfactor - 1) * 0.5f, (float)(reprojectionYfactor - 1) * 0.5f);
            Vector2 pixelOffset = currentPixel - centerPixel;
            uvOffset = pixelOffset / new Vector2(width, height);

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

            //compositeMR.sharedMaterial = compositeColorMaterial;
            compositeMR.materials = new List<Material>() { compositeColorMaterial, depthOcclusionMaterial }.ToArray();
            //compositeMR.materials = new List<Material>() { compositeColorMaterial }.ToArray();

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
