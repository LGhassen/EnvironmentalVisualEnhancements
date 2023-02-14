using UnityEngine;
using UnityEngine.Rendering;
using Utils;
using ShaderLoader;

namespace Atmosphere
{
	public class ParticleField
	{
		[ConfigItem]
		float fieldSize = 30f;

		[ConfigItem]
		float fieldParticleCount = 10000f;

		[ConfigItem]
		Vector3 particleSize = new Vector3(1f, 1f, 1f);

		[ConfigItem]
		float fallSpeed = 1f;

		[ConfigItem]
		float randomDirectionStrength = 0.1f;

		[ConfigItem]
		TextureWrapper particleTexture = null;

		private static Shader particleFieldShader = null;
		private static Shader ParticleFieldShader
		{
			get
			{
				if (particleFieldShader == null) particleFieldShader = ShaderLoaderClass.FindShader("EVE/ParticleField");
				return particleFieldShader;
			}
		}

		public Material material;
		Vector3 fieldSizeVector = Vector3.one;

		private GameObject fieldHolder;
		private Mesh mesh;
		private MeshRenderer fieldMeshRenderer;

		public void Apply()
        {
			// We could parent this to the local camera probably?

			material = new Material(ParticleFieldShader);
			material.renderQueue = 3000;

			fieldHolder = GameObject.CreatePrimitive(PrimitiveType.Cube);

			fieldHolder.name = "ParticleField";
			
			var cl = fieldHolder.GetComponent<Collider>();

			if(cl!=null)
			GameObject.Destroy(fieldHolder.GetComponent<Collider>());

			fieldMeshRenderer = fieldHolder.GetComponent<MeshRenderer>();
			fieldMeshRenderer.material = material;

			fieldMeshRenderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
			fieldMeshRenderer.receiveShadows = false;												// In the future needs to be enabled probably
			fieldMeshRenderer.enabled = true;

			MeshFilter filter = fieldMeshRenderer.GetComponent<MeshFilter>();
			//filter.mesh.bounds = new Bounds(Vector3.zero, new Vector3(Mathf.Infinity, Mathf.Infinity, Mathf.Infinity));
			filter.mesh = createMesh((int)fieldParticleCount);

			fieldSizeVector = new Vector3(fieldSize, fieldSize, fieldSize);
			InitMaterialProperties();

			//fieldHolder.transform.parent =;
			fieldHolder.transform.position = Vector3.zero;                                          // will just spawn at the floating origin for now
			fieldHolder.transform.localPosition = Vector3.zero;
			//fieldHolder.transform.localScale = Vector3.one;
			fieldHolder.transform.localScale = fieldSizeVector;
			fieldHolder.transform.localRotation = Quaternion.identity;
			fieldHolder.layer = (int)Tools.Layer.Local;

			//fieldHolder.SetActive(false);
			fieldHolder.SetActive(true);
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

		// Move all this to OnWillRenderObject?
		// That way you can add this to the volumeHolder
		// Use the camera's CameraToWorldMatrix as Model matrix
		// Build the field extents around the camera
		// For now just create your own GO here and parent it to the near camera
		public void Update()
		{
			material.SetVector("fieldOrigin", fieldHolder.transform.position);

			Vector3 fieldMinExtents = fieldHolder.transform.position - 0.5f * fieldSizeVector;
			material.SetVector("fieldMinExtents", fieldMinExtents);

			// Needs to be updated by checking the center to the planet
			material.SetVector("gravityVector", new Vector3(-1f, 0f, 0f));
		}

		private void InitMaterialProperties()
        {
            
            material.SetVector("fieldSize", fieldSizeVector);
            material.SetVector("invFieldSize", new Vector3(1f / fieldSize, 1f / fieldSize, 1f / fieldSize));

            material.SetVector("particleSize", particleSize);
            material.SetFloat("fallSpeed", fallSpeed);

            material.SetFloat("randomDirectionStrength", randomDirectionStrength);

			if (particleTexture != null)
			{
				particleTexture.ApplyTexture(material, "_MainTex");
			}
		}

		private Mesh createMesh(int particleCount)
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
	}
}
