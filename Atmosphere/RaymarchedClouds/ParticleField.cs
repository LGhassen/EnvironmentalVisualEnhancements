﻿using UnityEngine;
using UnityEngine.Rendering;
using Utils;
using ShaderLoader;
using System;
using System.Collections.Generic;
using Random = UnityEngine.Random;

namespace Atmosphere
{
	public class Splashes
    {
		[ConfigItem]
		float splashesSpeed = 1f;

		[ConfigItem]
		Vector2 splashesSize = new Vector2(1f, 1f);

		[ConfigItem]
		Vector2 splashesSheetCount = new Vector2(1f, 1f);

		[ConfigItem]
		Color color = Color.white * 255f;

		[ConfigItem, Optional]
		TextureWrapper splashTexture = null;

		//[ConfigItem, Optional]
		TextureWrapper splashDistorsionTexture = null;
		
		//[ConfigItem]
		float distorsionStrength = 1f;

		public float SplashesSpeed { get => splashesSpeed; }
		public Vector2 SplashesSize { get => splashesSize; }
		public Vector2 SplashesSheetCount { get => splashesSheetCount; }

		public Color Color { get => color; }
		public TextureWrapper SplashTexture { get => splashTexture; }

		public TextureWrapper SplashDistorsionTexture { get => splashDistorsionTexture; }

		public float DistorsionStrength { get => distorsionStrength; }
	}

	public class ParticleField
	{
		[ConfigItem]
		float fieldSize = 30f;

		[ConfigItem]
		float fieldParticleCount = 10000f;

		[ConfigItem]
		float fallSpeed = 1f;

		[ConfigItem]
		float tangentialSpeed = 1f;

		[ConfigItem]
		float randomDirectionStrength = 0.1f;

		[ConfigItem]
		Color color = Color.white * 255f;

		[ConfigItem]
		float particleSize = 0.02f;

		[ConfigItem]
		Vector2 particleSheetCount = new Vector2(1f, 1f);

		[ConfigItem]
		float particleStretch = 0.0f;

		[ConfigItem]
		float minCoverageThreshold = 0.3f;

		[ConfigItem]
		float maxCoverageThreshold = 0.75f;

		[ConfigItem, Optional]
		TextureWrapper particleTexture = null;

		//[ConfigItem, Optional]
		TextureWrapper particleDistorsionTexture = null;

		[ConfigItem]
		float distorsionStrength = 1f;

		[ConfigItem, Optional]
		Splashes splashes = null;

		static Shader particleFieldShader = null;
		static Shader ParticleFieldShader
		{
			get
			{
				if (particleFieldShader == null) particleFieldShader = ShaderLoaderClass.FindShader("EVE/ParticleField");
				return particleFieldShader;
			}
		}

		static Shader particleFieldSplashesShader = null;
		static Shader ParticleFieldSplashesShader
		{
			get
			{
				if (particleFieldSplashesShader == null) particleFieldSplashesShader = ShaderLoaderClass.FindShader("EVE/ParticleFieldSplashes");
				return particleFieldSplashesShader;
			}
		}

		public Material particleFieldMaterial, particleFieldSplashesMaterial;
		Vector3 fieldSizeVector = Vector3.one;

		GameObject fieldHolder;
		Mesh mesh;
		MeshRenderer fieldMeshRenderer;
		Transform parentTransform;
		CelestialBody parentCelestialBody;
		Vector3d accumulatedTimeOffset = Vector3d.zero;
		Vector3d accumulatedSplashesTimeOffset = Vector3d.zero;
		CloudsRaymarchedVolume cloudsRaymarchedVolume = null;

		Vector3 tangentialMovementDirection = Vector3.zero;

		public void Apply(Transform parent, CelestialBody celestialBody, CloudsRaymarchedVolume volume)
        {
			cloudsRaymarchedVolume = volume;
			parentCelestialBody = celestialBody;
			parentTransform = parent;
            fieldSizeVector = new Vector3(fieldSize, fieldSize, fieldSize);

            InitMaterials();
            InitGameObject(parent);
        }

        public void Remove()
		{
			if (fieldHolder != null)
			{
				fieldHolder.transform.parent = null;
				GameObject.Destroy(fieldHolder);
				fieldHolder = null;
			}
		}

		public void UpdateForCamera(Camera cam)
        {
			float coverageAtPosition = cloudsRaymarchedVolume.SampleCoverage(cam.transform.position);
			coverageAtPosition = Mathf.Clamp01((coverageAtPosition - minCoverageThreshold) / (maxCoverageThreshold - minCoverageThreshold));

			Vector3 gravityVector = (parentTransform.position - cam.transform.position).normalized;
			var rainVelocityVector = FlightGlobals.ActiveVessel ? (fallSpeed * gravityVector + tangentialMovementDirection * tangentialSpeed - (Vector3)FlightGlobals.ActiveVessel.srf_velocity).normalized : gravityVector;

			//take only rotation from the world to the camera and render everything in camera space to avoid floating point issues
			var worldToCameraMatrix = cam.worldToCameraMatrix;

			worldToCameraMatrix.m03 = 0f;
			worldToCameraMatrix.m13 = 0f;
			worldToCameraMatrix.m23 = 0f;

			var offset = parentCelestialBody.position - new Vector3d(cam.transform.position.x, cam.transform.position.y, cam.transform.position.z) + accumulatedTimeOffset;
			offset.x = repeatDouble(offset.x, fieldSize);
			offset.y = repeatDouble(offset.y, fieldSize);
			offset.z = repeatDouble(offset.z, fieldSize);
			
			// precision issues when away from floating origin so fade out
			float fade = 1f - Mathf.Clamp01((cam.transform.position.magnitude - 3000f) / 1000f);

			particleFieldMaterial.SetVector("gravityVector", rainVelocityVector);
			particleFieldMaterial.SetMatrix("rotationMatrix", worldToCameraMatrix);
			particleFieldMaterial.SetVector("offset", new Vector3((float)offset.x, (float)offset.y, (float)offset.z));
			particleFieldMaterial.SetFloat("fade", fade);
			particleFieldMaterial.SetFloat("coverage", coverageAtPosition);
			particleFieldMaterial.SetMatrix("cameraToWorldMatrix", cam.cameraToWorldMatrix);

			if (particleFieldSplashesMaterial != null)
            {
				particleFieldSplashesMaterial.SetVector("gravityVector", gravityVector);
				particleFieldSplashesMaterial.SetMatrix("rotationMatrix", worldToCameraMatrix);

				offset = parentCelestialBody.position - new Vector3d(cam.transform.position.x, cam.transform.position.y, cam.transform.position.z) + accumulatedSplashesTimeOffset;
				offset.x = repeatDouble(offset.x, fieldSize);
				offset.y = repeatDouble(offset.y, fieldSize);
				offset.z = repeatDouble(offset.z, fieldSize);

				particleFieldSplashesMaterial.SetVector("offset", new Vector3((float)offset.x, (float)offset.y, (float)offset.z));
				particleFieldSplashesMaterial.SetFloat("fade", fade);
				particleFieldSplashesMaterial.SetFloat("coverage", coverageAtPosition);
				particleFieldSplashesMaterial.SetMatrix("cameraToWorldMatrix", cam.cameraToWorldMatrix);
			}

			if (coverageAtPosition > 0f)
            {
				ParticleFieldRenderer.EnableForThisFrame(cam, fieldMeshRenderer, particleFieldMaterial);
				if (particleFieldSplashesMaterial != null)
					ParticleFieldRenderer.EnableForThisFrame(cam, fieldMeshRenderer, particleFieldSplashesMaterial);
			}
		}

		double repeatDouble(double t, double length)
        {
			return t - Math.Truncate(t / length) * length;
		}

		public void Update(Matrix4x4 oppositeFrameDeltaRotationMatrix)
		{
			Vector3 gravityVector = parentTransform.position.normalized;

			if (FlightCamera.fetch != null)
            {
				gravityVector = (parentTransform.position - FlightCamera.fetch.transform.position).normalized;
			}

			Vector3 timeOffsetDelta = Time.deltaTime * TimeWarp.CurrentRate * (gravityVector * fallSpeed + tangentialMovementDirection * tangentialSpeed);

			accumulatedTimeOffset += timeOffsetDelta;

			if (splashes!=null)
            {
				accumulatedSplashesTimeOffset += timeOffsetDelta *  splashes.SplashesSpeed / fallSpeed;
			}

			var sphereCenter = cloudsRaymarchedVolume.ParentTransform.position;

			particleFieldMaterial.SetVector("sphereCenter", sphereCenter);
			if (particleFieldSplashesMaterial != null)
				particleFieldSplashesMaterial.SetVector("sphereCenter", sphereCenter);

			// calculate the instantaneous movement direction of the cloud at the floating origin
			Vector3 lastPosition = oppositeFrameDeltaRotationMatrix.MultiplyPoint(Vector3.zero);

			tangentialMovementDirection = (-lastPosition).normalized;
		}

		void InitMaterials()
        {
			particleFieldMaterial = new Material(ParticleFieldShader);
			particleFieldMaterial.SetShaderPassEnabled("ForwardBase", false); // Disable main pass, render it only with commandBuffer so it can render after TAA, scondary lights pass is incompatible so leave it here
			particleFieldMaterial.SetShaderPassEnabled("ForwardAdd", true);
			particleFieldMaterial.renderQueue = 3200;

			particleFieldMaterial.SetVector("fieldSize", fieldSizeVector);
            particleFieldMaterial.SetVector("invFieldSize", new Vector3(1f / fieldSize, 1f / fieldSize, 1f / fieldSize));

			particleFieldMaterial.SetVector("particleSheetCount", particleSheetCount);
			particleFieldMaterial.SetFloat("particleSize", particleSize);
			particleFieldMaterial.SetFloat("particleStretch", particleStretch);
			particleFieldMaterial.SetFloat("fallSpeed", fallSpeed);

			particleFieldMaterial.SetFloat("randomDirectionStrength", randomDirectionStrength);

			particleFieldMaterial.SetColor("particleColor", color / 255f);

			if (particleStretch > 0f)
            {
				particleFieldMaterial.EnableKeyword("STRETCH_ON");
				particleFieldMaterial.DisableKeyword("STRETCH_OFF");
			}
			else
            {
				particleFieldMaterial.DisableKeyword("STRETCH_ON");
				particleFieldMaterial.EnableKeyword("STRETCH_OFF");
			}

			if (particleTexture != null)
			{
				particleTexture.ApplyTexture(particleFieldMaterial, "_MainTex");
			}

			
			if (particleDistorsionTexture != null)
			{
				particleDistorsionTexture.ApplyTexture(particleFieldMaterial, "distorsionTexture");
				particleFieldMaterial.SetFloat("distorsionStrength", distorsionStrength);
			}

			if (splashes != null)
            {
				particleFieldSplashesMaterial = new Material(ParticleFieldSplashesShader);
				particleFieldSplashesMaterial.SetShaderPassEnabled("ForwardBase", false);
				particleFieldSplashesMaterial.SetShaderPassEnabled("ForwardAdd", true);
				particleFieldSplashesMaterial.renderQueue = 3200;

				particleFieldSplashesMaterial.SetVector("fieldSize", fieldSizeVector);
				particleFieldSplashesMaterial.SetVector("invFieldSize", new Vector3(1f / fieldSize, 1f / fieldSize, 1f / fieldSize));

				particleFieldSplashesMaterial.SetVector("splashesSheetCount", splashes.SplashesSheetCount);
				particleFieldSplashesMaterial.SetVector("splashesSize", splashes.SplashesSize);
				particleFieldSplashesMaterial.SetFloat("fallSpeed", fallSpeed);

				particleFieldSplashesMaterial.SetFloat("randomDirectionStrength", randomDirectionStrength);

				particleFieldSplashesMaterial.SetColor("particleColor", splashes.Color / 255f);

				if (splashes.SplashTexture != null)
					splashes.SplashTexture.ApplyTexture(particleFieldSplashesMaterial, "_MainTex");

				if (splashes.SplashDistorsionTexture != null)
				{
					splashes.SplashDistorsionTexture.ApplyTexture(particleFieldSplashesMaterial, "distorsionTexture");
					particleFieldSplashesMaterial.SetFloat("distorsionStrength", splashes.DistorsionStrength);
				}
			}
		}

		void InitGameObject(Transform parent)
		{
			fieldHolder = GameObject.CreatePrimitive(PrimitiveType.Cube);
			fieldHolder.name = "ParticleField";
			var cl = fieldHolder.GetComponent<Collider>();

			if (cl != null)
				GameObject.Destroy(cl);

			fieldMeshRenderer = fieldHolder.GetComponent<MeshRenderer>();
			var materials = new List<Material>() { particleFieldMaterial };

			if (particleFieldSplashesMaterial != null)
            {
				materials.Add(particleFieldSplashesMaterial);
			}

			fieldMeshRenderer.materials = materials.ToArray();

			fieldMeshRenderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
			fieldMeshRenderer.receiveShadows = false;                                               // In the future needs to be enabled probably
			fieldMeshRenderer.enabled = false;

			MeshFilter filter = fieldMeshRenderer.GetComponent<MeshFilter>();			
			filter.mesh = createMesh((int)fieldParticleCount);
			filter.mesh.bounds = new Bounds(Vector3.zero, new Vector3(1e8f, 1e8f, 1e8f));

			fieldHolder.transform.parent = parent;
			fieldHolder.transform.localPosition = Vector3.zero;
			fieldHolder.layer = (int)Tools.Layer.Local;

			var fieldUpdater = fieldHolder.AddComponent<FieldUpdater>();
			fieldUpdater.field = this;

			fieldHolder.SetActive(false);
		}

		public void SetEnabled(bool value)
        {
			if (fieldHolder!= null && fieldMeshRenderer!=null)
			{
				fieldHolder.SetActive(value);
				fieldMeshRenderer.enabled = value;
			}
		}

		private Mesh createMesh(int particleCount)
		{
			Mesh mesh = new Mesh();
			mesh.indexFormat = particleCount > (65536 / 4) ? IndexFormat.UInt32 : IndexFormat.UInt16;

			Vector3[] vertices = new Vector3[particleCount * 4];
			Vector2[] UVs = new Vector2[particleCount * 4];
			Vector2[] UVs2 = new Vector2[particleCount * 4];
			Vector3[] normals = new Vector3[particleCount * 4];
			int[] triangles = new int[particleCount * 6];

			for (int i = 0; i < particleCount; i++)
			{
				// for every particle create 4 vertices, center them at the same center position
				Vector3 particlePosition = 0.5f * new Vector3(Random.Range(-1f, 1f), Random.Range(-1f, 1f), Random.Range(-1f, 1f)); // not sure why I need a 0.5f here
				Vector3 randomDirection = new Vector3(Random.Range(-1f, 1f), Random.Range(-1f, 1f), Random.Range(-1f, 1f));
				Vector2 randomIndexes = new Vector2(Random.Range(0f, 1f), Random.Range(0f, 1f));

				for (int j = 0; j < 4; j++)
				{
					vertices[i * 4 + j] = particlePosition;
					normals[i * 4 + j] = randomDirection;
				}

				// create the UVs, UVs are used to encode the actual vertex position relative to the particle position, can also be used to set the actual texture UVs in shader
				UVs[i * 4] = new Vector2(-1f, -1f);
				UVs[i * 4 + 1] = new Vector2(1f, -1f);
				UVs[i * 4 + 2] = new Vector2(1f, 1f);
				UVs[i * 4 + 3] = new Vector2(-1f, 1f);

				// the second UVs are used to store "random" indexes between 0 and 1 used to control particle density on the fly and which texture on the sheet to sample
				UVs2[i * 4] = randomIndexes;
				UVs2[i * 4 + 1] = randomIndexes;
				UVs2[i * 4 + 2] = randomIndexes;
				UVs2[i * 4 + 3] = randomIndexes;

				// create the triangles
				// triangle 1 uses vertices 0, 1 and 2
				triangles[i * 6] = i * 4;
				triangles[i * 6 + 1] = i * 4 + 1;
				triangles[i * 6 + 2] = i * 4 + 2;

				// triangle 2 uses vertices 3, 0 and 2
				triangles[i * 6 + 3] = i * 4 + 3;
				triangles[i * 6 + 4] = i * 4;
				triangles[i * 6 + 5] = i * 4 + 2;
			}


			mesh.Clear();
			mesh.vertices = vertices;
			mesh.normals = normals;
			mesh.uv = UVs;
			mesh.uv2 = UVs2;
			mesh.triangles = triangles;

			return mesh;
		}

		public class FieldUpdater : MonoBehaviour
		{
			public Material mat;
			public Transform parent;
			public ParticleField field;

			public void OnWillRenderObject()
			{
				Camera cam = Camera.current;
				if (!cam)
					return;

				field.UpdateForCamera(cam);
			}
		}

		public class ParticleFieldRenderer : MonoBehaviour
		{
			private static Dictionary<Camera, ParticleFieldRenderer> CameraToParticleFieldRendererRenderer = new Dictionary<Camera, ParticleFieldRenderer>();

			public static void EnableForThisFrame(Camera cam, MeshRenderer mr, Material mat)
			{
				if (CameraToParticleFieldRendererRenderer.ContainsKey(cam))
				{
					CameraToParticleFieldRendererRenderer[cam].AddRenderer(mr, mat);
				}
				else
				{
					CameraToParticleFieldRendererRenderer[cam] = (ParticleFieldRenderer)cam.gameObject.AddComponent(typeof(ParticleFieldRenderer));
				}
			}

			bool renderingEnabled = false;

			private Camera targetCamera;
			private List<CommandBuffer> commandBuffersAdded = new List<CommandBuffer>();

			public ParticleFieldRenderer()
			{
			}

			public void Start()
			{
				targetCamera = GetComponent<Camera>();
			}

			public void AddRenderer(MeshRenderer mr, Material mat)
			{
				if (targetCamera != null)
				{
					CommandBuffer cb = new CommandBuffer();

					/*
					int screenCopyID = Shader.PropertyToID("_ScreenCopyTexture");
					cb.GetTemporaryRT(screenCopyID, -1, -1, 0, FilterMode.Bilinear);
					cb.Blit(BuiltinRenderTextureType.CurrentActive, screenCopyID);
					*/

					cb.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
					//cb.SetGlobalTexture("backgroundTexture", screenCopyID);
					cb.DrawRenderer(mr, mat, 0, 0);

					commandBuffersAdded.Add(cb);

					renderingEnabled = true;
				}
			}

			public void OnPreRender()
            {
				if (renderingEnabled)
                {
					foreach (var cb in commandBuffersAdded)
					{
						targetCamera.AddCommandBuffer(CameraEvent.AfterForwardAlpha, cb);
					}
				}
            }

			public void OnPostRender()
			{
				if (renderingEnabled && targetCamera.stereoActiveEye != Camera.MonoOrStereoscopicEye.Left)
				{
					foreach (var cb in commandBuffersAdded)
					{
						targetCamera.RemoveCommandBuffer(CameraEvent.AfterForwardAlpha, cb);
					}
					commandBuffersAdded.Clear();
				}
			}

			public void OnDestroy()
			{
				if (targetCamera != null)
				{
					foreach (var cb in commandBuffersAdded)
					{
						targetCamera.RemoveCommandBuffer(CameraEvent.AfterForwardAlpha, cb);
					}
					commandBuffersAdded.Clear();

					renderingEnabled = false;
				}
			}
		}
	}
}
