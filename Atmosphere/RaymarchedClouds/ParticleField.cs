using UnityEngine;
using UnityEngine.Rendering;
using Utils;
using ShaderLoader;
using System;
using Random = UnityEngine.Random;

namespace Atmosphere
{
	public class Splashes
	{
		[ConfigItem]
		Vector2 splashesSize = new Vector3(1f, 1f);

		[ConfigItem]
		Vector2 splashesSheetCount = new Vector3(1f, 1f);

		[ConfigItem]
		TextureWrapper splashesTextureSheet = null;
		public Vector2 SplashesSize { get => splashesSize; }
		public Vector2 SplashesSheetCount { get => splashesSheetCount; }
		public TextureWrapper SplashesTextureSheet { get => splashesTextureSheet; }
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
		float randomDirectionStrength = 0.1f;

		[ConfigItem]
		Color color = Color.white * 255f;

		[ConfigItem]
		float particleSize = 0.02f;

		[ConfigItem]
		Vector2 particleSheetCount = new Vector3(1f, 1f);

		[ConfigItem]
		float particleStretch = 0.0f;

		[ConfigItem]
		TextureWrapper particleTextureSheet = null;

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

		public void Apply(Transform parent, CelestialBody celestialBody)
        {
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
			Vector3 gravityVector = (parentTransform.position - cam.transform.position).normalized;
			particleFieldMaterial.SetVector("gravityVector", gravityVector);

			//take only rotation from the world to the camera and render everything in camera space to avoid floating point issues
			var worldToCameraMatrix = cam.worldToCameraMatrix;

			worldToCameraMatrix.m03 = 0f;
			worldToCameraMatrix.m13 = 0f;
			worldToCameraMatrix.m23 = 0f;

			particleFieldMaterial.SetMatrix("rotationMatrix", worldToCameraMatrix);

			var offset = parentCelestialBody.position - new Vector3d(cam.transform.position.x, cam.transform.position.y, cam.transform.position.z) + accumulatedTimeOffset;
			offset.x = repeatDouble(offset.x, fieldSize);
			offset.y = repeatDouble(offset.y, fieldSize);
			offset.z = repeatDouble(offset.z, fieldSize);
			particleFieldMaterial.SetVector("offset", new Vector3((float) offset.x, (float)offset.y, (float)offset.z));

			// precision issues when away from floating origin so fade out
			float fade = 1f - Mathf.Clamp01((cam.transform.position.magnitude - 3000f) / 1000f);
			particleFieldMaterial.SetFloat("fade", fade);
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

			accumulatedTimeOffset += gravityVector * Time.deltaTime * TimeWarp.CurrentRate * fallSpeed;
		}

		void InitMaterials()
        {
			particleFieldMaterial = new Material(ParticleFieldShader);
			particleFieldMaterial.renderQueue = 9000;

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

			if (particleTextureSheet != null)
			{
				particleTextureSheet.ApplyTexture(particleFieldMaterial, "_MainTex");
			}

			if (splashes != null)
            {
				particleFieldSplashesMaterial = new Material(ParticleFieldSplashesShader);
				particleFieldSplashesMaterial.renderQueue = 9000;

				particleFieldSplashesMaterial.SetVector("fieldSize", fieldSizeVector);
				particleFieldSplashesMaterial.SetVector("invFieldSize", new Vector3(1f / fieldSize, 1f / fieldSize, 1f / fieldSize));

				particleFieldSplashesMaterial.SetVector("splashesSheetCount", splashes.SplashesSheetCount);
				particleFieldSplashesMaterial.SetVector("splashesSize", splashes.SplashesSize);
				particleFieldSplashesMaterial.SetFloat("fallSpeed", fallSpeed);

				particleFieldSplashesMaterial.SetFloat("randomDirectionStrength", randomDirectionStrength);

				particleFieldSplashesMaterial.SetColor("particleColor", color / 255f);

				if (splashes.SplashesTextureSheet != null)
				{
					splashes.SplashesTextureSheet.ApplyTexture(particleFieldSplashesMaterial, "_MainTex");
				}
			}
		}

		void InitGameObject(Transform parent)
		{
			fieldHolder = GameObject.CreatePrimitive(PrimitiveType.Cube);
			fieldHolder.name = "ParticleField";
			var cl = fieldHolder.GetComponent<Collider>();

			if (cl != null)
				GameObject.Destroy(fieldHolder.GetComponent<Collider>());

			fieldMeshRenderer = fieldHolder.GetComponent<MeshRenderer>();
			fieldMeshRenderer.material = particleFieldMaterial;

			fieldMeshRenderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
			fieldMeshRenderer.receiveShadows = false;                                               // In the future needs to be enabled probably
			fieldMeshRenderer.enabled = true;

			MeshFilter filter = fieldMeshRenderer.GetComponent<MeshFilter>();			
			filter.mesh = createMesh((int)fieldParticleCount);
			filter.mesh.bounds = new Bounds(Vector3.zero, new Vector3(Mathf.Infinity, Mathf.Infinity, Mathf.Infinity));

			fieldHolder.transform.parent = parent;
			fieldHolder.transform.localPosition = Vector3.zero;
			fieldHolder.layer = (int)Tools.Layer.Local;

			var fieldUpdater = fieldHolder.AddComponent<FieldUpdater>();
			fieldUpdater.field = this;

			//fieldHolder.SetActive(false);
			fieldHolder.SetActive(true);
		}

		Mesh createMesh(int particleCount)
		{
			Mesh mesh = new Mesh();
			mesh.indexFormat = particleCount > (65536 / 4) ? IndexFormat.UInt32 : IndexFormat.UInt16;

			Vector3[] vertices = new Vector3[particleCount * 4];
			Vector2[] UVs = new Vector2[particleCount * 4];
			Vector3[] normals = new Vector3[particleCount * 4];
			int[] triangles = new int[particleCount * 6];

			for (int i = 0; i < particleCount; i++)
			{
				// for every particle create 4 vertices, center them at the same center position
				Vector3 particlePosition = 0.5f * new Vector3(Random.Range(-1f, 1f), Random.Range(-1f, 1f), Random.Range(-1f, 1f)); // not sure why I need a 0.5f here
				Vector3 randomDirection = new Vector3(Random.Range(-1f, 1f), Random.Range(-1f, 1f), Random.Range(-1f, 1f));

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
	}
}
