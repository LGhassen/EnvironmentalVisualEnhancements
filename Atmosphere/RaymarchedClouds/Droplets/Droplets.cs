using UnityEngine;
using UnityEngine.Rendering;
using Utils;
using ShaderLoader;
using System;
using System.Collections.Generic;
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
		CelestialBody parentCelestialBody;

		float currentCoverage = 0f;
		bool cloudLayerEnabled = false;
		bool ivaEnabled = false;

		PartsRenderer partsRenderer;

		bool directionFadeLerpInProgress = false;
		Vector3 currentShipRelativeDropletDirectionVector = Vector3.zero;
		Vector3 nextShipRelativeDropletDirectionVector = Vector3.zero;

		float fadeLerpTime = 0f;
		float fadeLerpDuration = 0f;

		float accumulatedTimeOffset1 = 0f;
		float accumulatedTimeOffset2 = 0f;

		static Shader dropletsIvaShader = null;
		static Shader DropletsIvaShader
		{
			get
			{
				if (dropletsIvaShader == null) dropletsIvaShader = ShaderLoaderClass.FindShader("EVE/DropletsIVA");
				return dropletsIvaShader;
			}
		}

		public bool Apply(Transform parent, CelestialBody celestialBody, CloudsRaymarchedVolume volume)
        {
			dropletsConfigObject = DropletsManager.GetConfig(dropletsConfig);

			if (dropletsConfigObject == null)
				return false;

			cloudsRaymarchedVolume = volume;
			parentCelestialBody = celestialBody;
			parentTransform = parent;

			InitMaterials();
			InitGameObjects(parent);

			partsRenderer = FlightCamera.fetch.mainCamera.gameObject.AddComponent<PartsRenderer>();

			GameEvents.OnCameraChange.Add(CameraChanged);

			Vector3 initialGravityVector = -parentTransform.position.normalized;

			if (FlightCamera.fetch != null)
				initialGravityVector = (FlightCamera.fetch.transform.position - parentTransform.position).normalized;

			if (FlightGlobals.ActiveVessel != null )
				initialGravityVector = FlightGlobals.ActiveVessel.transform.worldToLocalMatrix.MultiplyVector(initialGravityVector);

			currentShipRelativeDropletDirectionVector = initialGravityVector;
			nextShipRelativeDropletDirectionVector    = initialGravityVector;

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

			if (partsRenderer != null)
            {
				Component.DestroyImmediate(partsRenderer);
			}

			GameEvents.OnCameraChange.Remove(CameraChanged);
		}

		public void Update()
		{
			currentCoverage = cloudsRaymarchedVolume.SampleCoverage(FlightCamera.fetch.transform.position, out float cloudType);
			currentCoverage = Mathf.Clamp01((currentCoverage - dropletsConfigObject.MinCoverageThreshold) / (dropletsConfigObject.MaxCoverageThreshold - dropletsConfigObject.MinCoverageThreshold));

			currentCoverage *= cloudsRaymarchedVolume.GetInterpolatedCloudTypeParticleFieldDensity(cloudType);

			dropletsIvaMaterial.SetFloat("_Coverage", currentCoverage);

			if (InternalSpace.Instance != null)
				dropletsIvaMaterial.SetMatrix("internalSpaceMatrix", InternalSpace.Instance.transform.worldToLocalMatrix);

			if (FlightGlobals.ActiveVessel != null)
            {
                float deltaTime = Tools.getDeltaTime();

                UpdateSpeedRelatedMaterialParams(deltaTime);
                HandleDirectionChanges(deltaTime);
            }
        }

        private void HandleDirectionChanges(float deltaTime)
        {
            if (directionFadeLerpInProgress)
            {
                // TODO: Set shader keywords
                fadeLerpTime += deltaTime;

                if (fadeLerpTime > fadeLerpDuration)
                {
                    fadeLerpTime = 0f;
                    directionFadeLerpInProgress = false;
                    currentShipRelativeDropletDirectionVector = nextShipRelativeDropletDirectionVector;
                    accumulatedTimeOffset1 = accumulatedTimeOffset2;
                }

                dropletsIvaMaterial.SetMatrix("rotationMatrix1", Matrix4x4.Rotate(Quaternion.FromToRotation(currentShipRelativeDropletDirectionVector, Vector3.up)));
                dropletsIvaMaterial.SetMatrix("rotationMatrix2", Matrix4x4.Rotate(Quaternion.FromToRotation(nextShipRelativeDropletDirectionVector, Vector3.up)));

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
                    dropletsIvaMaterial.SetMatrix("rotationMatrix1", Matrix4x4.Rotate(Quaternion.FromToRotation(currentShipRelativeDropletDirectionVector, Vector3.up)));
                }
                else
                {
                    fadeLerpDuration = Mathf.Lerp(0.25f, 1f, dotValue * 0.5f + 0.5f);
                    directionFadeLerpInProgress = true;
                    accumulatedTimeOffset2 = 0f;
                }
            }
        }

        private void UpdateSpeedRelatedMaterialParams(float deltaTime)
        {
			float currentSpeed = (float)FlightGlobals.ActiveVessel.srf_velocity.magnitude;

			accumulatedTimeOffset1 += deltaTime * Mathf.Max(1f, dropletsConfigObject.SpeedIncreaseFactor * Mathf.Min(currentSpeed, dropletsConfigObject.MaxModulationSpeed));
            accumulatedTimeOffset2 += deltaTime * Mathf.Max(1f, dropletsConfigObject.SpeedIncreaseFactor * Mathf.Min(currentSpeed, dropletsConfigObject.MaxModulationSpeed));

            if (accumulatedTimeOffset1 > 20000f) accumulatedTimeOffset1 = 0f;
            if (accumulatedTimeOffset2 > 20000f) accumulatedTimeOffset2 = 0f;

            dropletsIvaMaterial.SetFloat("accumulatedTimeOffset1", accumulatedTimeOffset1);
            dropletsIvaMaterial.SetFloat("accumulatedTimeOffset2", accumulatedTimeOffset2);

            float speedModulationLerp = Mathf.Clamp01(currentSpeed / dropletsConfigObject.MaxModulationSpeed);
            dropletsIvaMaterial.SetFloat("_StreaksRatio", Mathf.Lerp(dropletsConfigObject.LowSpeedStreakRatio, dropletsConfigObject.HighSpeedStreakRatio, speedModulationLerp));

            dropletsIvaMaterial.SetFloat("_DistorsionStrength", Mathf.Lerp(dropletsConfigObject.LowSpeedNoiseStrength, dropletsConfigObject.HighSpeedNoiseStrength, speedModulationLerp));
            dropletsIvaMaterial.SetFloat("_DistorsionScale", dropletsConfigObject.NoiseScale);

            dropletsIvaMaterial.SetFloat("_SpeedRandomness", Mathf.Lerp(dropletsConfigObject.LowSpeedTimeRandomness, dropletsConfigObject.HighSpeedTimeRandomness, speedModulationLerp));
        }

        void InitMaterials()
        {
			dropletsIvaMaterial = new Material(DropletsIvaShader);
			dropletsIvaMaterial.renderQueue = 0;

			dropletsIvaMaterial.SetFloat("_DropletSpeed", dropletsConfigObject.Speed);
			dropletsIvaMaterial.SetFloat("_RefractionStrength", dropletsConfigObject.RefractionStrength);
			dropletsIvaMaterial.SetFloat("_DistorsionStrength", dropletsConfigObject.LowSpeedNoiseStrength);
			dropletsIvaMaterial.SetFloat("_DistorsionScale", dropletsConfigObject.NoiseScale);
			dropletsIvaMaterial.SetFloat("_SpecularStrength", dropletsConfigObject.SpecularStrength);

			dropletsIvaMaterial.SetFloat("_SpeedRandomness", 1f);
			dropletsIvaMaterial.SetFloat("dropletUVMultiplier", dropletsConfigObject.UVScale);
			dropletsIvaMaterial.SetFloat("_DropletsTransitionSharpness", dropletsConfigObject.TriplanarTransitionSharpness);

			if (dropletsConfigObject.Noise != null) { dropletsConfigObject.Noise.ApplyTexture(dropletsIvaMaterial, "_DropletDistorsion"); }

			dropletsIvaMaterial.SetFloat("lerp12", 0f);
		}

		
		void InitGameObjects(Transform parent)
		{	
			dropletsGO = GameObject.CreatePrimitive(PrimitiveType.Quad);
			dropletsGO.name = "Droplets GO";

			var cl = dropletsGO.GetComponent<Collider>();
			if (cl != null) GameObject.Destroy(cl);

			var mr = dropletsGO.GetComponent<MeshRenderer>();
			mr.material = dropletsIvaMaterial;

			var mf = dropletsGO.GetComponent<MeshFilter>();
			mf.mesh.bounds = new Bounds(Vector3.zero, new Vector3(1e8f, 1e8f, 1e8f));

			dropletsGO.transform.parent = parent;
			dropletsGO.transform.localPosition = Vector3.zero;
			dropletsGO.layer = (int)Tools.Layer.Internal;
			
			dropletsGO.SetActive(false);
		}
		

		public void SetDropletsEnabled(bool value)
        {
			cloudLayerEnabled = value;

			bool finalEnabled = cloudLayerEnabled && ivaEnabled && currentCoverage > 0f;

			if (dropletsGO != null)
				dropletsGO.SetActive(finalEnabled);

			if (partsRenderer != null)
				partsRenderer.SetEnabled(finalEnabled);
		}

		private void CameraChanged(CameraManager.CameraMode cameraMode)
		{
			ivaEnabled = cameraMode == CameraManager.CameraMode.IVA || cameraMode == CameraManager.CameraMode.Internal;
		}

		public class PartsRenderer : MonoBehaviour
        {
			// TODO: make this an instance thing?
			Camera partsCamera;
			GameObject partsCameraGO;

			Camera targetCamera;

			bool isEnabled = false;
			bool isInitialized = false;

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

			public void SetEnabled(bool enabled)
            {
				isEnabled = enabled;
            }

			public void Initialize()
            {
				targetCamera = FlightCamera.fetch.mainCamera;

				if (targetCamera == null || targetCamera.activeTexture == null)
					return;

				bool supportVR = VRUtils.VREnabled();
				int width, height;

				if (supportVR)
				{
					VRUtils.GetEyeTextureResolution(out width, out height);
				}
				else
				{
					width = targetCamera.activeTexture.width;
					height = targetCamera.activeTexture.height;
				}

				depthRT = new RenderTexture(width / 2, height / 2, 16, RenderTextureFormat.RFloat); // tried 16-bit but it's not nice enough, quarter-res 32-bit looks the same
				depthRT.autoGenerateMips = false;
				depthRT.Create();

				partsCameraGO = new GameObject("EVE parts camera");

				partsCamera = partsCameraGO.AddComponent<Camera>();
				partsCamera.enabled = false;

				partsCamera.transform.position = FlightCamera.fetch.transform.position;
				partsCamera.transform.parent = FlightCamera.fetch.transform;

				partsCamera.targetTexture = depthRT;
				partsCamera.clearFlags = CameraClearFlags.SolidColor;
				partsCamera.backgroundColor = Color.black;

				isInitialized = true;
			}

			public void OnPreRender()
            {
				if (isEnabled && isInitialized)
				{
					partsCamera.CopyFrom(targetCamera);
					partsCamera.depthTextureMode = DepthTextureMode.None;
					partsCamera.clearFlags = CameraClearFlags.SolidColor;
					partsCamera.enabled = false;
					partsCamera.cullingMask = (int)Tools.Layer.Parts;
					partsCamera.nearClipPlane = 0.0001f;
					partsCamera.farClipPlane  = 30f;

					partsCamera.targetTexture = depthRT;
					partsCamera.RenderWithShader(PartDepthShader, ""); // TODO: replacement tag for transparencies as well so we render less fluff?

					Shader.SetGlobalTexture("PartsDepthTexture", depthRT);
				}
            }

			public void OnPostRender()
            {
				if (!isInitialized && isEnabled)
					Initialize();
			}
			
			public void OnDestroy()
            {
				if (depthRT != null)
					depthRT.Release();
			}
        }
	}
}