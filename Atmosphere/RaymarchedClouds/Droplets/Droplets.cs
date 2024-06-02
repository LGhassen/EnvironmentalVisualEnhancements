using UnityEngine;
using UnityEngine.Rendering;
using Utils;
using ShaderLoader;
using System;
using System.Collections.Generic;
using System.Linq;
using Random = UnityEngine.Random;

namespace Atmosphere
{
    public class Droplets
    {
        [ConfigItem]
        string dropletsConfig = "";

        DropletsConfig dropletsConfigObject = null;

        public Material dropletsIvaMaterial;
        GameObject dropletsGO;
        CloudsRaymarchedVolume cloudsRaymarchedVolume = null;

        Transform parentTransform;

        float currentCoverage = 0f;
        float currentWetness = 0f;

        bool cloudLayerEnabled = false;
        bool ivaEnabled = false;

        bool directionFadeLerpInProgress = false;
        Vector3 currentShipRelativeDropletDirectionVector = Vector3.zero;
        Vector3 nextShipRelativeDropletDirectionVector = Vector3.zero;

        float fadeLerpTime = 0f;
        float fadeLerpDuration = 0f;

        float sideDropletsTimeOffset1 = 0f;
        float sideDropletsTimeOffset2 = 0f;

        float topDropletsTimeOffset1 = 0f;
        float topDropletsTimeOffset2 = 0f;

        static Shader dropletsIvaShader = null;
        static Shader DropletsIvaShader
        {
            get
            {
                if (dropletsIvaShader == null) dropletsIvaShader = ShaderLoaderClass.FindShader("EVE/DropletsIVA");
                return dropletsIvaShader;
            }
        }

        public bool Apply(Transform parent, CloudsRaymarchedVolume volume)
        {
            dropletsConfigObject = DropletsManager.GetConfig(dropletsConfig);

            if (dropletsConfigObject == null)
                return false;

            cloudsRaymarchedVolume = volume;
            parentTransform = parent;

            InitMaterials();
            InitGameObjects(parent);

            GameEvents.OnCameraChange.Add(CameraChanged);

            Vector3 initialGravityVector = -parentTransform.position.normalized;

            if (FlightCamera.fetch != null)
                initialGravityVector = (FlightCamera.fetch.transform.position - parentTransform.position).normalized;

            if (FlightGlobals.ActiveVessel != null)
                initialGravityVector = FlightGlobals.ActiveVessel.transform.worldToLocalMatrix.MultiplyVector(initialGravityVector);

            currentShipRelativeDropletDirectionVector = initialGravityVector;
            nextShipRelativeDropletDirectionVector = initialGravityVector;

            return true;
        }

        public void Remove()
        {
            if (dropletsGO != null)
            {
                dropletsGO.transform.parent = null;
                GameObject.Destroy(dropletsGO);
                dropletsGO = null;
            }

            GameEvents.OnCameraChange.Remove(CameraChanged);

            if (internalCamera != null && commandBuffer != null)
            {
                var evt = internalCamera.actualRenderingPath == RenderingPath.DeferredShading ? CameraEvent.BeforeGBuffer : CameraEvent.BeforeForwardOpaque;
                internalCamera.RemoveCommandBuffer(evt, commandBuffer);
            }
        }

        public void Update()
        {
            if (FlightGlobals.ActiveVessel != null)
            {
                float deltaTime = Tools.GetDeltaTime();
                float currentSpeed = (float)FlightGlobals.ActiveVessel.srf_velocity.magnitude;

                HandleCoverageAndWetness(deltaTime, currentSpeed);
                if (currentWetness > 0f)
                {
                    UpdateSpeedRelatedMaterialParams(deltaTime, currentSpeed);
                    HandleDirectionChanges(deltaTime);

                    if (InternalSpace.Instance != null)
                        dropletsIvaMaterial.SetMatrix("internalSpaceMatrix", InternalSpace.Instance.transform.worldToLocalMatrix);
                }
            }
        }

        private void HandleCoverageAndWetness(float deltaTime, float currentSpeed)
        {
            currentCoverage = cloudsRaymarchedVolume.SampleCoverage(FlightGlobals.ActiveVessel.transform.position, out float cloudType); // should do this not on the camera position but on the vessel
            currentCoverage = Mathf.Clamp01((currentCoverage - dropletsConfigObject.MinCoverageThreshold) / (dropletsConfigObject.MaxCoverageThreshold - dropletsConfigObject.MinCoverageThreshold));
            currentCoverage *= cloudsRaymarchedVolume.GetInterpolatedCloudTypeDropletsDensity(cloudType);

            if (currentWetness > currentCoverage)
            {
                ApplyDrying(deltaTime);
            }

            currentWetness = Mathf.Max(currentWetness, currentCoverage);
            currentWetness = Mathf.Lerp(currentWetness, 0f, (currentSpeed - dropletsConfigObject.FadeOutStartSpeed) / (dropletsConfigObject.FadeOutEndSpeed - dropletsConfigObject.FadeOutStartSpeed));

            dropletsIvaMaterial.SetFloat("_Coverage", currentWetness);
        }

        private void ApplyDrying(float deltaTime)
        {
            //currentWetness = Mathf.Clamp01(currentWetness - deltaTime * dropletsConfigObject.DryingSpeed * Mathf.Max(Mathf.Log((float)FlightGlobals.ActiveVessel.srf_velocity.magnitude, 1f)));
            currentWetness = Mathf.Clamp01(currentWetness - deltaTime * dropletsConfigObject.DryingSpeed);
        }

        private void HandleDirectionChanges(float deltaTime)
        {
            if (directionFadeLerpInProgress)
            {
                fadeLerpTime += deltaTime;

                if (fadeLerpTime > fadeLerpDuration)
                {
                    directionFadeLerpInProgress = false;
                    currentShipRelativeDropletDirectionVector = nextShipRelativeDropletDirectionVector;
                    sideDropletsTimeOffset1 = sideDropletsTimeOffset2;
                }

                dropletsIvaMaterial.SetFloat("lerp12", fadeLerpTime / fadeLerpDuration);
            }
            else
            {
                Vector3 gravityVector = -parentTransform.position.normalized;
                if (FlightCamera.fetch != null) gravityVector = (FlightCamera.fetch.transform.position - parentTransform.position).normalized;

                gravityVector = (12 * gravityVector + (Vector3)FlightGlobals.ActiveVessel.srf_velocity).normalized;
                nextShipRelativeDropletDirectionVector = FlightGlobals.ActiveVessel.transform.worldToLocalMatrix.MultiplyVector(gravityVector);

                float dotValue = Vector3.Dot(nextShipRelativeDropletDirectionVector, currentShipRelativeDropletDirectionVector);

                if (dotValue > 0.998)
                {
                    // slow rotation lerp for small changes
                    // note: this will sometimes make the whole thing rotate around the axis which is busted, to be checked
                    float t = deltaTime / 10f;
                    var rotationQuaternion = Quaternion.FromToRotation(currentShipRelativeDropletDirectionVector, nextShipRelativeDropletDirectionVector);
                    rotationQuaternion = Quaternion.Slerp(Quaternion.identity, rotationQuaternion, t);

                    currentShipRelativeDropletDirectionVector = rotationQuaternion * currentShipRelativeDropletDirectionVector;
                }
                else
                {
                    directionFadeLerpInProgress = true;
                    fadeLerpDuration = Mathf.Lerp(0.25f, 1f, dotValue * 0.5f + 0.5f);
                    fadeLerpTime = 0f;
                }

                dropletsIvaMaterial.SetFloat("lerp12", 0f);
                sideDropletsTimeOffset2 = 0f;
            }

            dropletsIvaMaterial.SetMatrix("rotationMatrix1", Matrix4x4.Rotate(Quaternion.FromToRotation(currentShipRelativeDropletDirectionVector, Vector3.up)));
            dropletsIvaMaterial.SetMatrix("rotationMatrix2", Matrix4x4.Rotate(Quaternion.FromToRotation(nextShipRelativeDropletDirectionVector, Vector3.up)));
        }

        private void UpdateSpeedRelatedMaterialParams(float deltaTime, float currentSpeed)
        {
            float sideDropletTimeDelta = deltaTime * Mathf.Max(1f, dropletsConfigObject.SpeedIncreaseFactor * Mathf.Min(currentSpeed, dropletsConfigObject.MaxModulationSpeed));

            sideDropletsTimeOffset1 += sideDropletTimeDelta;
            sideDropletsTimeOffset2 += sideDropletTimeDelta;

            if (sideDropletsTimeOffset1 > 20000f) sideDropletsTimeOffset1 = 0f;
            if (sideDropletsTimeOffset2 > 20000f) sideDropletsTimeOffset2 = 0f;

            dropletsIvaMaterial.SetFloat("sideDropletsTimeOffset1", sideDropletsTimeOffset1);
            dropletsIvaMaterial.SetFloat("sideDropletsTimeOffset2", sideDropletsTimeOffset2);

            // Note: using Log here

            if (currentCoverage > 0f && currentWetness <= currentCoverage)
            {
                float topDropletTimeDelta = deltaTime * Mathf.Max(1f, 0.1f * Mathf.Log(Mathf.Min(currentSpeed, dropletsConfigObject.MaxModulationSpeed))) * Mathf.Clamp01(1f - (currentCoverage - currentWetness));

                topDropletsTimeOffset1 += topDropletTimeDelta;
                topDropletsTimeOffset2 += topDropletTimeDelta;

                if (topDropletsTimeOffset1 > 20000f) topDropletsTimeOffset1 = 0f;
                if (topDropletsTimeOffset2 > 20000f) topDropletsTimeOffset2 = 0f;
            }

            dropletsIvaMaterial.SetFloat("topDropletsTimeOffset1", topDropletsTimeOffset1);
            dropletsIvaMaterial.SetFloat("topDropletsTimeOffset2", topDropletsTimeOffset2);

            float speedModulationLerp = Mathf.Clamp01(currentSpeed / dropletsConfigObject.MaxModulationSpeed);
            dropletsIvaMaterial.SetFloat("_StreaksRatio", Mathf.Lerp(dropletsConfigObject.LowSpeedStreakRatio, dropletsConfigObject.HighSpeedStreakRatio, speedModulationLerp));

            dropletsIvaMaterial.SetFloat("_SideDistorsionStrength", Mathf.Lerp(dropletsConfigObject.SideLowSpeedNoiseStrength, dropletsConfigObject.SideHighSpeedNoiseStrength, speedModulationLerp));

            dropletsIvaMaterial.SetFloat("_SpeedRandomness", Mathf.Lerp(dropletsConfigObject.LowSpeedTimeRandomness, dropletsConfigObject.HighSpeedTimeRandomness, speedModulationLerp));


        }

        void InitMaterials()
        {
            dropletsIvaMaterial = new Material(DropletsIvaShader);
            dropletsIvaMaterial.renderQueue = 0;

            dropletsIvaMaterial.SetFloat("_RefractionStrength", dropletsConfigObject.RefractionStrength);
            dropletsIvaMaterial.SetFloat("_Translucency", dropletsConfigObject.Translucency);
            dropletsIvaMaterial.SetVector("_Color", dropletsConfigObject.Color / 255f);
            dropletsIvaMaterial.SetFloat("_SpecularStrength", dropletsConfigObject.SpecularStrength);

            dropletsIvaMaterial.SetFloat("_SpeedRandomness", 1f);
            dropletsIvaMaterial.SetFloat("dropletUVMultiplier", 1f / (dropletsConfigObject.Scale * 0.16f));
            dropletsIvaMaterial.SetFloat("_DropletsTransitionSharpness", dropletsConfigObject.TriplanarTransitionSharpness);

            dropletsIvaMaterial.SetFloat("_SideDistorsionScale", 1f / dropletsConfigObject.SideNoiseScale);

            dropletsIvaMaterial.SetFloat("_TopDistorsionStrength", dropletsConfigObject.TopNoiseStrength);
            dropletsIvaMaterial.SetFloat("_TopDistorsionScale", 1f / dropletsConfigObject.TopNoiseScale);

            if (dropletsConfigObject.Noise != null) { dropletsConfigObject.Noise.ApplyTexture(dropletsIvaMaterial, "_DropletDistorsion"); }

            if (dropletsConfigObject.SideDropletLayers.Count > 0)
            {
                float[] sideDropletLayerSize = new float[dropletsConfigObject.SideDropletLayers.Count];
                float[] sideDropletLayerSpeed = new float[dropletsConfigObject.SideDropletLayers.Count];
                float[] sideDropletLayerAspectRatio = new float[dropletsConfigObject.SideDropletLayers.Count];
                float[] sideDropletLayerStreakPercentage = new float[dropletsConfigObject.SideDropletLayers.Count];

                for (int i = 0; i < dropletsConfigObject.SideDropletLayers.Count; i++)
                {
                    var sideLayerConfig = dropletsConfigObject.SideDropletLayers.ElementAt(i);
                    sideDropletLayerSize[i] = 1f / sideLayerConfig.Scale;
                    sideDropletLayerSpeed[i] = sideLayerConfig.FallSpeed;
                    sideDropletLayerAspectRatio[i] = sideLayerConfig.DropletToTrailAspectRatio;
                    sideDropletLayerStreakPercentage[i] = sideLayerConfig.StreakRatio;
                }

                dropletsIvaMaterial.SetFloatArray("sideDropletLayerSize", sideDropletLayerSize);
                dropletsIvaMaterial.SetFloatArray("sideDropletLayerSpeed", sideDropletLayerSpeed);
                dropletsIvaMaterial.SetFloatArray("sideDropletLayerAspectRatio", sideDropletLayerAspectRatio);
                dropletsIvaMaterial.SetFloatArray("sideDropletLayerStreakPercentage", sideDropletLayerStreakPercentage);
            }

            dropletsIvaMaterial.SetInt("sideDropletLayerCount", dropletsConfigObject.SideDropletLayers.Count);

            if (dropletsConfigObject.TopDropletLayers.Count > 0)
            {
                float[] topDropletLayerSize = new float[dropletsConfigObject.TopDropletLayers.Count];
                float[] topDropletLayerSpeed = new float[dropletsConfigObject.TopDropletLayers.Count];

                for (int i = 0; i < dropletsConfigObject.TopDropletLayers.Count; i++)
                {
                    var topLayerConfig = dropletsConfigObject.TopDropletLayers.ElementAt(i);
                    topDropletLayerSize[i] = 1f / topLayerConfig.Scale;
                    topDropletLayerSpeed[i] = topLayerConfig.Speed;
                }

                dropletsIvaMaterial.SetInt("topDropletLayerCount", dropletsConfigObject.TopDropletLayers.Count);
                dropletsIvaMaterial.SetFloatArray("topDropletLayerSize", topDropletLayerSize);
                dropletsIvaMaterial.SetFloatArray("topDropletLayerSpeed", topDropletLayerSpeed);
            }

            dropletsIvaMaterial.SetFloat("lerp12", 0f);
        }


        MeshRenderer mr;

        void InitGameObjects(Transform parent)
        {
            dropletsGO = GameObject.CreatePrimitive(PrimitiveType.Quad);
            dropletsGO.name = "Droplets GO";

            var cl = dropletsGO.GetComponent<Collider>();
            if (cl != null) GameObject.Destroy(cl);

            mr = dropletsGO.GetComponent<MeshRenderer>();
            mr.material = dropletsIvaMaterial;

            var mf = dropletsGO.GetComponent<MeshFilter>();
            mf.mesh.bounds = new Bounds(Vector3.zero, new Vector3(1e8f, 1e8f, 1e8f));

            dropletsGO.transform.parent = parent;
            dropletsGO.transform.localPosition = Vector3.zero;
            dropletsGO.layer = (int)Tools.Layer.Internal;

            dropletsGO.SetActive(false);
        }


        CommandBuffer commandBuffer;
        Camera internalCamera;

        public void SetDropletsEnabled(bool value)
        {
            cloudLayerEnabled = value;

            bool finalEnabled = cloudLayerEnabled && ivaEnabled && currentWetness > 0f;

            if (finalEnabled && HighLogic.LoadedScene == GameScenes.FLIGHT)
            {
                PartsRenderer.EnableForFrame();

                if (commandBuffer == null)
                {
                    commandBuffer = new CommandBuffer();
                    commandBuffer.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
                    commandBuffer.DrawRenderer(mr, dropletsIvaMaterial);
                }
            }

            if (internalCamera != null && commandBuffer != null)
            {
                var evt = internalCamera.actualRenderingPath == RenderingPath.DeferredShading ? CameraEvent.BeforeGBuffer : CameraEvent.BeforeForwardOpaque;

                internalCamera.RemoveCommandBuffer(evt, commandBuffer);

                if (finalEnabled)
                {
                    internalCamera.AddCommandBuffer(evt, commandBuffer);
                }
            }

        }

        private void CameraChanged(CameraManager.CameraMode cameraMode)
        {
            ivaEnabled = cameraMode == CameraManager.CameraMode.IVA || cameraMode == CameraManager.CameraMode.Internal;

            if (ivaEnabled && internalCamera == null)
            {
                internalCamera = InternalCamera.Instance.GetComponentInChildren<Camera>();
            }
        }

        public class PartsRenderer : MonoBehaviour
        {
            private static PartsRenderer instance;

            public static void EnableForFrame()
            {
                if (instance == null && InternalCamera.Instance != null)
                {
                    instance = InternalCamera.Instance.GetComponentInChildren<Camera>().gameObject.AddComponent<PartsRenderer>();
                }

                if (instance != null)
                {
                    instance.isEnabled = true;
                    instance.framesEnabledCounter = 0;
                }
            }

            Camera partsCamera;
            GameObject partsCameraGO;

            Camera targetCamera;

            bool isEnabled = false;
            bool isInitialized = false;
            int framesEnabledCounter = 0;

            int width, height;

            static Shader partDepthShader = null;
            static Shader PartDepthShader
            {
                get
                {
                    if (partDepthShader == null) partDepthShader = ShaderLoaderClass.FindShader("EVE/PartDepth");
                    return partDepthShader;
                }
            }

            private RenderTexture depthRT;

            public void Initialize()
            {
                targetCamera = FlightCamera.fetch.mainCamera;

                if (targetCamera == null)
                    return;

                bool supportVR = VRUtils.VREnabled();

                if (supportVR)
                {
                    VRUtils.GetEyeTextureResolution(out width, out height);
                }
                else if (targetCamera.activeTexture == null)
                {
                    width = Screen.width;
                    height = Screen.height;
                }
                else
                {
                    width = targetCamera.activeTexture.width;
                    height = targetCamera.activeTexture.height;
                }

                CreateDepthRT();

                partsCameraGO = new GameObject("EVE parts camera");

                partsCamera = partsCameraGO.AddComponent<Camera>();
                partsCamera.enabled = false;

                partsCamera.transform.SetParent(FlightCamera.fetch.transform, false);

                partsCamera.targetTexture = depthRT;
                partsCamera.clearFlags = CameraClearFlags.SolidColor;
                partsCamera.backgroundColor = Color.black;

                isInitialized = true;
            }

            private void CreateDepthRT()
            {
                depthRT = new RenderTexture(width / 2, height / 2, 16, RenderTextureFormat.RFloat); // tried 16-bit but it's not nice enough, quarter-res 32-bit looks the same
                depthRT.autoGenerateMips = false;
                depthRT.Create();
            }

            public void OnPreRender()
            {
                if (isEnabled && isInitialized)
                {
                    if (depthRT == null)
                        CreateDepthRT();

                    partsCamera.CopyFrom(targetCamera);
                    partsCamera.renderingPath = RenderingPath.Forward;
                    partsCamera.depthTextureMode = DepthTextureMode.None;
                    partsCamera.clearFlags = CameraClearFlags.SolidColor;
                    partsCamera.enabled = false;
                    partsCamera.cullingMask = (int)Tools.Layer.Parts;
                    partsCamera.nearClipPlane = 0.0001f;
                    partsCamera.farClipPlane = 30f;

                    partsCamera.targetTexture = depthRT;

                    if (Camera.current.stereoActiveEye != Camera.MonoOrStereoscopicEye.Mono)
                    {
                        Camera.StereoscopicEye currentEye = Camera.current.stereoActiveEye == Camera.MonoOrStereoscopicEye.Right ? Camera.StereoscopicEye.Right : Camera.StereoscopicEye.Left;

                        partsCamera.projectionMatrix = InternalCamera.Instance.GetComponent<Camera>().GetStereoProjectionMatrix(currentEye);
                        partsCamera.transform.position = targetCamera.transform.position + (currentEye == Camera.StereoscopicEye.Right ? 0.5f : -0.5f) * targetCamera.stereoSeparation * partsCamera.transform.right;
                    }

                    partsCamera.RenderWithShader(PartDepthShader, ""); // TODO: replacement tag for transparencies as well so we render less fluff?

                    Shader.SetGlobalTexture("PartsDepthTexture", depthRT);
                }
            }

            public void OnPostRender()
            {
                if (!isInitialized && isEnabled)
                    Initialize();

                if (isEnabled)
                {
                    bool doneRendering = targetCamera.stereoActiveEye != Camera.MonoOrStereoscopicEye.Left;
                    if (doneRendering)
                    {
                        framesEnabledCounter++;
                        if (framesEnabledCounter > 5)
                        {
                            isEnabled = false;
                            depthRT.Release();
                            depthRT = null;
                        }
                    }
                }
            }

            public void OnDestroy()
            {
                if (depthRT != null)
                    depthRT.Release();
            }
        }
    }
}