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

		PartsRenderer dropletsRenderer;

		bool fadeLerpInProgress = false;
		Vector3 currentDropletDirectionVector = Vector3.zero;
		Vector3 nextDropletDirectionVector = Vector3.zero;

		float fadeLerpTime = 0f;
		float fadeLerpDuration = 0f;

		float accumulatedTimeOffset = 0f;

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

			dropletsRenderer = FlightCamera.fetch.mainCamera.gameObject.AddComponent<PartsRenderer>();

			InitMaterials();
			InitGameObjects(parent);

			GameEvents.OnCameraChange.Add(CameraChanged);

			Vector3 initialGravityVector = -parentTransform.position.normalized;

			if (FlightCamera.fetch != null)
			{
				initialGravityVector = (FlightCamera.fetch.transform.position - parentTransform.position).normalized;
			}

			currentDropletDirectionVector = initialGravityVector;
			nextDropletDirectionVector    = initialGravityVector;

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

			if (dropletsRenderer != null)
            {
				Component.DestroyImmediate(dropletsRenderer);
			}

			GameEvents.OnCameraChange.Remove(CameraChanged);
		}

		public void Update()
		{
			currentCoverage = cloudsRaymarchedVolume.SampleCoverage(FlightCamera.fetch.transform.position, out float cloudType);
			// currentCoverage = Mathf.Clamp01((currentCoverage - dropletsConfigObject.MinCoverageThreshold) / (dropletsConfigObject.MaxCoverageThreshold - dropletsConfigObject.MinCoverageThreshold));
			currentCoverage *= cloudsRaymarchedVolume.GetInterpolatedCloudTypeParticleFieldDensity(cloudType);

			/*
			if (currentCoverage > 0f)
				SetRendererEnabled(true);
			else
				SetRendererEnabled(false);
			*/

			// dropletsWorldMaterial.SetFloat("_Coverage", currentCoverage);
			dropletsIvaMaterial.SetFloat("_Coverage", 1f);

			Vector3 gravityVector = -parentTransform.position.normalized;
			if (FlightCamera.fetch != null) gravityVector = (FlightCamera.fetch.transform.position - parentTransform.position).normalized;

			if (FlightGlobals.ActiveVessel != null)
			{
				dropletsIvaMaterial.SetMatrix("worldToCraftMatrix", FlightGlobals.ActiveVessel.transform.worldToLocalMatrix);

				float deltaTime = Tools.getDeltaTime();

				float currentSpeed = (float)FlightGlobals.ActiveVessel.srf_velocity.magnitude;

				accumulatedTimeOffset += deltaTime * Mathf.Max(1f, currentSpeed * dropletsConfigObject.SpeedIncreaseFactor);
				dropletsIvaMaterial.SetFloat("accumulatedTimeOffset", accumulatedTimeOffset);

				float speedModulationLerp = Mathf.Clamp01(currentSpeed / dropletsConfigObject.MaxModulationSpeed);
				dropletsIvaMaterial.SetFloat("_StreaksRatio", Mathf.Lerp(dropletsConfigObject.LowSpeedStreakRatio, dropletsConfigObject.HighSpeedStreakRatio, speedModulationLerp));

				dropletsIvaMaterial.SetFloat("_DistorsionStrength", Mathf.Lerp(dropletsConfigObject.LowSpeedNoiseStrength, dropletsConfigObject.HighSpeedNoiseStrength, speedModulationLerp));
				dropletsIvaMaterial.SetFloat("_DistorsionScale", Mathf.Lerp(dropletsConfigObject.LowSpeedNoiseScale, dropletsConfigObject.HighSpeedNoiseScale, speedModulationLerp));

				if (fadeLerpInProgress)
                {
					// TODO: Set shader keywords

					fadeLerpTime += deltaTime;

					if (fadeLerpTime > fadeLerpDuration)
                    {
						fadeLerpTime = 0f;
						fadeLerpInProgress = false;
						currentDropletDirectionVector = nextDropletDirectionVector;
					}

					dropletsIvaMaterial.SetMatrix("rotationMatrix1", Matrix4x4.Rotate(Quaternion.FromToRotation(currentDropletDirectionVector, Vector3.up)));
					dropletsIvaMaterial.SetMatrix("rotationMatrix2", Matrix4x4.Rotate(Quaternion.FromToRotation(nextDropletDirectionVector, Vector3.up)));

					dropletsIvaMaterial.SetFloat("lerp12", fadeLerpTime / fadeLerpDuration);
				}
                else
				{
					gravityVector = (12 * gravityVector + (Vector3)FlightGlobals.ActiveVessel.srf_velocity).normalized;
					nextDropletDirectionVector = FlightGlobals.ActiveVessel.transform.worldToLocalMatrix.MultiplyVector(gravityVector);

					float dotValue = Vector3.Dot(nextDropletDirectionVector, currentDropletDirectionVector);

					
					if (dotValue > 0.998)
					{
						// slow rotation lerp for small changes
						float t = deltaTime / 10f;
						var rotationQuaternion = Quaternion.FromToRotation(currentDropletDirectionVector, nextDropletDirectionVector);
						rotationQuaternion = Quaternion.Slerp(Quaternion.identity, rotationQuaternion, t);

						currentDropletDirectionVector = rotationQuaternion * currentDropletDirectionVector;
						dropletsIvaMaterial.SetMatrix("rotationMatrix1", Matrix4x4.Rotate(Quaternion.FromToRotation(currentDropletDirectionVector, Vector3.up)));
					}
					else
					
                    {
						// fade rotation lerp for big changes
						//fadeLerpDuration = Mathf.Lerp(1f, 3f, 1f - (dotValue * 0.5f + 0.5f)); // this works surprisingly well lol
						//fadeLerpDuration = Mathf.Lerp(0.5f, 2f, dotValue * 0.5f + 0.5f); // let's go with this for now

						fadeLerpDuration = Mathf.Lerp(0.25f, 1f, dotValue * 0.5f + 0.5f);

						fadeLerpInProgress = true;
					}
				}
			}
		}

		void InitMaterials()
        {
			dropletsIvaMaterial = new Material(DropletsIvaShader);
			dropletsIvaMaterial.renderQueue = 6000;

			dropletsIvaMaterial.SetFloat("_DropletSpeed", dropletsConfigObject.Speed);
			dropletsIvaMaterial.SetFloat("_RefractionStrength", dropletsConfigObject.RefractionStrength);
			dropletsIvaMaterial.SetFloat("_DropletSpeed", dropletsConfigObject.Speed);
			dropletsIvaMaterial.SetFloat("_DistorsionStrength", dropletsConfigObject.LowSpeedNoiseStrength);
			dropletsIvaMaterial.SetFloat("_DistorsionScale", dropletsConfigObject.LowSpeedNoiseScale);
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
			dropletsGO.layer = (int)Tools.Layer.Local; // with this make it so it only renders if IVAcamera is active
		}
		

		public void SetDropletsEnabled(bool value)
        {
			cloudLayerEnabled = value;

			bool finalEnabled = cloudLayerEnabled && ivaEnabled;

			if (dropletsGO != null)
				dropletsGO.SetActive(finalEnabled);

			if (dropletsRenderer != null)
				dropletsRenderer.SetEnabled(finalEnabled);
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

				depthRT = new RenderTexture(width, height, 16, RenderTextureFormat.RFloat);
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
					partsCamera.nearClipPlane = 0.01f;
					partsCamera.farClipPlane  = 30f;

					partsCamera.targetTexture = depthRT;
					partsCamera.RenderWithShader(PartDepthShader, ""); // TODO: replacement tag for transparencies as well so we render less fluff?

					Shader.SetGlobalTexture("PartsDepthTexture", depthRT);

					/*
					dropletsIvaMaterial.SetTexture("PartsDepthTexture", depthRT);
					dropletsIvaMaterial.SetMatrix(ShaderProperties.cameraToWorldMatrix_PROPERTY, targetCamera.cameraToWorldMatrix); // this isn't gonna work, replace with unity_MatrixInvV in shader

					dropletsCommandBuffer.Clear();

					int screenCopyID = Shader.PropertyToID("_ScreenCopyTexture");
					dropletsCommandBuffer.GetTemporaryRT(screenCopyID, -1, -1, 0, FilterMode.Bilinear);
					dropletsCommandBuffer.Blit(BuiltinRenderTextureType.CurrentActive, screenCopyID);

					dropletsCommandBuffer.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
					dropletsCommandBuffer.SetGlobalTexture("_DropletBackGround", screenCopyID);
					dropletsCommandBuffer.Blit(null, BuiltinRenderTextureType.CameraTarget, dropletsIvaMaterial); // material here for droplets, make sure to use the backGroundTexture and set depthRT as property

					targetCamera.AddCommandBuffer(CameraEvent.AfterForwardAlpha, dropletsCommandBuffer); // try this or afterAll?
					*/
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