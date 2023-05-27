using UnityEngine;
using UnityEngine.Rendering;
using Utils;
using ShaderLoader;
using System;
using System.Collections.Generic;
using Random = UnityEngine.Random;

namespace Atmosphere
{
	public class ParticleField
	{
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

		[ConfigItem]
		string particleFieldConfig = "";

		ParticleFieldConfig particleFieldConfigObject = null;

		public Material particleFieldMaterial, particleFieldSplashesMaterial;

		GameObject fieldHolder;
		Mesh mesh;
		MeshRenderer fieldMeshRenderer;
		Transform parentTransform;
		CelestialBody parentCelestialBody;
		Vector3d accumulatedTimeOffset = Vector3d.zero;
		Vector3d accumulatedSplashesTimeOffset = Vector3d.zero;
		CloudsRaymarchedVolume cloudsRaymarchedVolume = null;

		public bool Apply(Transform parent, CelestialBody celestialBody, CloudsRaymarchedVolume volume)
        {
			particleFieldConfigObject = ParticleFieldManager.GetConfig(particleFieldConfig);

			if (particleFieldConfigObject == null)
				return false;

			cloudsRaymarchedVolume = volume;
			parentCelestialBody = celestialBody;
			parentTransform = parent;

            InitMaterials();
            InitGameObject(parent);

			return true;
        }

        public void Remove()
		{
			if (mesh != null)
            {
				mesh.Clear();
				GameObject.Destroy(mesh);
				Component.Destroy(fieldMeshRenderer);
			}

			if (fieldHolder != null)
			{
				fieldHolder.transform.parent = null;
				GameObject.Destroy(fieldHolder);
				fieldHolder = null;
			}
		}

		public void UpdateForCamera(Camera cam)
        {
			float coverageAtPosition = cloudsRaymarchedVolume.SampleCoverage(cam.transform.position, out float cloudType);
			coverageAtPosition = Mathf.Clamp01((coverageAtPosition - particleFieldConfigObject.MinCoverageThreshold) / (particleFieldConfigObject.MaxCoverageThreshold - particleFieldConfigObject.MinCoverageThreshold));
			coverageAtPosition *= cloudsRaymarchedVolume.GetInterpolatedCloudTypeParticleFieldDensity(cloudType);

			Vector3 gravityVector = (parentTransform.position - cam.transform.position).normalized;
			var rainVelocityVector = FlightGlobals.ActiveVessel ? (particleFieldConfigObject.FallSpeed * gravityVector + cloudsRaymarchedVolume.TangentialMovementDirection * particleFieldConfigObject.TangentialSpeed - (Vector3)FlightGlobals.ActiveVessel.srf_velocity).normalized : gravityVector;

			//take only rotation from the world to the camera and render everything in camera space to avoid floating point issues
			var worldToCameraMatrix = cam.worldToCameraMatrix;

			worldToCameraMatrix.m03 = 0f;
			worldToCameraMatrix.m13 = 0f;
			worldToCameraMatrix.m23 = 0f;

			var offset = parentCelestialBody.position - new Vector3d(cam.transform.position.x, cam.transform.position.y, cam.transform.position.z) + accumulatedTimeOffset;
			offset.x = repeatDouble(offset.x, particleFieldConfigObject.FieldSize);
			offset.y = repeatDouble(offset.y, particleFieldConfigObject.FieldSize);
			offset.z = repeatDouble(offset.z, particleFieldConfigObject.FieldSize);
			
			// precision issues when away from floating origin so fade out
			float fade = 1f - Mathf.Clamp01((cam.transform.position.magnitude - 3000f) / 1000f);

			particleFieldMaterial.SetVector("gravityVector", rainVelocityVector);
			particleFieldMaterial.SetMatrix("rotationMatrix", worldToCameraMatrix);
			particleFieldMaterial.SetVector("offset", new Vector3((float)offset.x, (float)offset.y, (float)offset.z));
			particleFieldMaterial.SetFloat("fade", fade);
			particleFieldMaterial.SetFloat("coverage", coverageAtPosition);
			particleFieldMaterial.SetMatrix("cameraToWorldMatrix", cam.cameraToWorldMatrix);
			particleFieldMaterial.SetVector("worldSpaceCameraForwardDirection", cam.transform.forward);

			if (particleFieldSplashesMaterial != null)
            {
				particleFieldSplashesMaterial.SetVector("gravityVector", gravityVector);
				particleFieldSplashesMaterial.SetMatrix("rotationMatrix", worldToCameraMatrix);

				offset = parentCelestialBody.position - new Vector3d(cam.transform.position.x, cam.transform.position.y, cam.transform.position.z) + accumulatedSplashesTimeOffset;
				offset.x = repeatDouble(offset.x, particleFieldConfigObject.FieldSize);
				offset.y = repeatDouble(offset.y, particleFieldConfigObject.FieldSize);
				offset.z = repeatDouble(offset.z, particleFieldConfigObject.FieldSize);

				particleFieldSplashesMaterial.SetVector("offset", new Vector3((float)offset.x, (float)offset.y, (float)offset.z));
				particleFieldSplashesMaterial.SetFloat("fade", fade);
				particleFieldSplashesMaterial.SetFloat("coverage", coverageAtPosition);
				particleFieldSplashesMaterial.SetMatrix("cameraToWorldMatrix", cam.cameraToWorldMatrix);
				particleFieldSplashesMaterial.SetVector("worldSpaceCameraForwardDirection", cam.transform.forward);
			}

			if (coverageAtPosition > 0f)
			{
				ParticleFieldRenderer.EnableForThisFrame(cam, fieldMeshRenderer, particleFieldMaterial);
				if (particleFieldSplashesMaterial != null)
					ParticleFieldRenderer.EnableForThisFrame(cam, fieldMeshRenderer, particleFieldSplashesMaterial);

				SetEnabled(true);
			}
			else
				SetEnabled(false);
		}

		double repeatDouble(double t, double length)
        {
			return t - Math.Truncate(t / length) * length;
		}

		public void Update()
		{
			Vector3 gravityVector = parentTransform.position.normalized;

			if (FlightCamera.fetch != null)
            {
				gravityVector = (parentTransform.position - FlightCamera.fetch.transform.position).normalized;
			}

			Vector3 timeOffsetDelta = Time.deltaTime * TimeWarp.CurrentRate * (gravityVector * particleFieldConfigObject.FallSpeed + cloudsRaymarchedVolume.TangentialMovementDirection * particleFieldConfigObject.TangentialSpeed);

			accumulatedTimeOffset += timeOffsetDelta;

			if (particleFieldConfigObject.Splashes !=null)
            {
				accumulatedSplashesTimeOffset += timeOffsetDelta * particleFieldConfigObject.Splashes.SplashesSpeed / particleFieldConfigObject.FallSpeed;
			}

			var sphereCenter = cloudsRaymarchedVolume.ParentTransform.position;

			particleFieldMaterial.SetVector("sphereCenter", sphereCenter);
			if (particleFieldSplashesMaterial != null)
				particleFieldSplashesMaterial.SetVector("sphereCenter", sphereCenter);
		}

		void InitMaterials()
        {
			particleFieldMaterial = new Material(ParticleFieldShader);
			particleFieldMaterial.SetShaderPassEnabled("ForwardBase", false); // Disable main pass, render it only with commandBuffer so it can render after TAA, scondary lights pass is incompatible so leave it here
			particleFieldMaterial.SetShaderPassEnabled("ForwardAdd", true);
			particleFieldMaterial.renderQueue = 3200;

			particleFieldMaterial.SetFloat("fieldSize", particleFieldConfigObject.FieldSize);
            particleFieldMaterial.SetFloat("invFieldSize", 1f / particleFieldConfigObject.FieldSize);

			particleFieldMaterial.SetVector("particleSheetCount", particleFieldConfigObject.ParticleSheetCount);
			particleFieldMaterial.SetFloat("particleSize", particleFieldConfigObject.ParticleSize);
			particleFieldMaterial.SetFloat("particleStretch", particleFieldConfigObject.ParticleStretch);
			particleFieldMaterial.SetFloat("fallSpeed", particleFieldConfigObject.FallSpeed);

			particleFieldMaterial.SetFloat("randomDirectionStrength", particleFieldConfigObject.RandomDirectionStrength);

			particleFieldMaterial.SetColor("particleColor", particleFieldConfigObject.Color / 255f);

			if (particleFieldConfigObject.ParticleStretch > 0f)
            {
				particleFieldMaterial.EnableKeyword("STRETCH_ON");
				particleFieldMaterial.DisableKeyword("STRETCH_OFF");
			}
			else
            {
				particleFieldMaterial.DisableKeyword("STRETCH_ON");
				particleFieldMaterial.EnableKeyword("STRETCH_OFF");
			}

			if (particleFieldConfigObject.ParticleTexture != null)
			{
				particleFieldConfigObject.ParticleTexture.ApplyTexture(particleFieldMaterial, "_MainTex");
			}

			
			if (particleFieldConfigObject.ParticleDistorsionTexture != null)
			{
				particleFieldConfigObject.ParticleDistorsionTexture.ApplyTexture(particleFieldMaterial, "distorsionTexture");
				particleFieldMaterial.SetFloat("distorsionStrength", particleFieldConfigObject.DistorsionStrength);
			}

			if (particleFieldConfigObject.Splashes != null)
            {
				particleFieldSplashesMaterial = new Material(ParticleFieldSplashesShader);
				particleFieldSplashesMaterial.SetShaderPassEnabled("ForwardBase", false);
				particleFieldSplashesMaterial.SetShaderPassEnabled("ForwardAdd", true);
				particleFieldSplashesMaterial.renderQueue = 3200;

				particleFieldSplashesMaterial.SetFloat("fieldSize", particleFieldConfigObject.FieldSize);
				particleFieldSplashesMaterial.SetFloat("invFieldSize", 1f / particleFieldConfigObject.FieldSize);

				particleFieldSplashesMaterial.SetVector("splashesSheetCount", particleFieldConfigObject.Splashes.SplashesSheetCount);
				particleFieldSplashesMaterial.SetVector("splashesSize", particleFieldConfigObject.Splashes.SplashesSize);
				particleFieldSplashesMaterial.SetFloat("fallSpeed", particleFieldConfigObject.FallSpeed);

				particleFieldSplashesMaterial.SetFloat("randomDirectionStrength", particleFieldConfigObject.RandomDirectionStrength);

				particleFieldSplashesMaterial.SetColor("particleColor", particleFieldConfigObject.Splashes.Color / 255f);

				if (particleFieldConfigObject.Splashes.SplashTexture != null)
					particleFieldConfigObject.Splashes.SplashTexture.ApplyTexture(particleFieldSplashesMaterial, "_MainTex");

				if (particleFieldConfigObject.Splashes.SplashDistorsionTexture != null)
				{
					particleFieldConfigObject.Splashes.SplashDistorsionTexture.ApplyTexture(particleFieldSplashesMaterial, "distorsionTexture");
					particleFieldSplashesMaterial.SetFloat("distorsionStrength", particleFieldConfigObject.Splashes.DistorsionStrength);
				}
			}
		}

		void InitGameObject(Transform parent)
		{
			Remove();

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
			mesh = createMesh((int)particleFieldConfigObject.FieldParticleCount);
			filter.sharedMesh = mesh;
			filter.sharedMesh.bounds = new Bounds(Vector3.zero, new Vector3(1e8f, 1e8f, 1e8f));

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

			Dictionary<Camera, bool> allowedCameras = new Dictionary<Camera, bool>();

			public void OnWillRenderObject()
			{
				Camera cam = Camera.current;

				if (!cam)
					return;

				if (!allowedCameras.TryGetValue(cam, out bool isAllowed))
				{
					if (cam.name == "Reflection Probes Camera" || cam.name == "NearCamera") // NearCamera seems to be the Kerbal portrait camera and for some reason it breaks and causes flashing issues when some of its properties are accessed here
						allowedCameras.Add(cam, false);
					else
						allowedCameras.Add(cam, true);
				}
				else if (!isAllowed)
				{ 
					return;
				}

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
					var renderer = CameraToParticleFieldRendererRenderer[cam];
					if (renderer != null)
						renderer.AddRenderer(mr, mat);
				}
				else
				{
					// add null to the cameras we don't want to render on so we don't do a string compare every time
					if ((cam.name == "TRReflectionCamera") || (cam.name == "Reflection Probes Camera"))
					{
						CameraToParticleFieldRendererRenderer[cam] = null;
					}
					else
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
