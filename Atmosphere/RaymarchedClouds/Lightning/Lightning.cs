using ShaderLoader;
using System.Collections.Generic;
using UnityEngine;
using Utils;
using PQSManager;

namespace Atmosphere
{
	public class Lightning
	{
		static LinkedList<LightningInstance> activeLightningList = new LinkedList<LightningInstance>();
		static Vector4[] activeLightningShaderLights = new Vector4[4];
		static Vector4[] activeLightningShaderLightColors = new Vector4[4];
		static Matrix4x4[] activeLightningShaderTransforms = new Matrix4x4[4];

		static readonly int maxConcurrent = 4; // more than this and it tanks the performance because of the lights, especially using Parallax and rain/splashes
		static int currentCount = 0;
		static int lastUpdateFrame = 0;

		public static int MaxConcurrent => maxConcurrent;
		public static int CurrentCount { get => currentCount; }

		public static void UpdateExisting()
		{
			int currentFrame = Time.frameCount;

			if (currentFrame > lastUpdateFrame)
			{
				int currentIndex = 0;

				for (var lightningNode = activeLightningList.First; lightningNode != null; )
				{
					var nextNode = lightningNode.Next;

					if (lightningNode.Value.Update(Time.deltaTime * TimeWarp.CurrentRate))
                    {
						activeLightningList.Remove(lightningNode);
						currentCount--;
					}
					else
                    {
						activeLightningShaderLights[currentIndex] = new Vector4(lightningNode.Value.lightGameObject.transform.position.x,
							lightningNode.Value.lightGameObject.transform.position.y,
							lightningNode.Value.lightGameObject.transform.position.z,
							0.25f * lightningNode.Value.startIntensity * lightningNode.Value.lifeTime / lightningNode.Value.startLifeTime); // apply 0.25 the point light intensity to the volumetric cloud

						activeLightningShaderLightColors[currentIndex] = new Vector4(lightningNode.Value.color.a * lightningNode.Value.color.r, lightningNode.Value.color.a * lightningNode.Value.color.g, lightningNode.Value.color.a * lightningNode.Value.color.b, 10f / lightningNode.Value.light.range); // create an exponential falloff term from the light range
						activeLightningShaderTransforms[currentIndex] = lightningNode.Value.boltGameObject.transform.localToWorldMatrix;

						lightningNode.Value.lightningBoltMaterial.SetFloat("maxConcurrentLightning", (float)maxConcurrent);
						lightningNode.Value.lightningBoltMaterial.SetFloat("lightningIndex", (float)currentIndex);

						currentIndex++;
					}

					lightningNode = nextNode;
				}

				lastUpdateFrame = currentFrame;
			}
		}

		public static void SetShaderParams(Material mat)
        {
			if (currentCount > 0)
            {
				mat.EnableKeyword("LIGHTNING_ON");
				mat.DisableKeyword("LIGHTNING_OFF");
				mat.SetInt("lightningCount", currentCount);
				mat.SetInt("maxConcurrentLightning", maxConcurrent);
				mat.SetVectorArray("lightningArray", activeLightningShaderLights);
				mat.SetVectorArray("lightningColorsArray", activeLightningShaderLightColors);
				mat.SetMatrixArray("lightningTransformsArray", activeLightningShaderTransforms);
			}
			else
            {
				mat.EnableKeyword("LIGHTNING_OFF");
				mat.DisableKeyword("LIGHTNING_ON");
			}
        }

		private static Shader lightningBoltShader = null;
		private static Shader LightningBoltShader
		{
			get
			{
				if (lightningBoltShader == null) lightningBoltShader = ShaderLoaderClass.FindShader("EVE/LightningBolt");
				return lightningBoltShader;
			}
		}

        [ConfigItem]
		string lightningConfig = "";

		LightningConfig lightningConfigObject = null;

		List<float> spawnTimesList = new List<float>();     // TODO: change this to add probability
		int lastSpawnedIndex = -1;
		float lastSpawnTime = 0f;

		Transform parentTransform;
		float parentRadius = 0f;

		float spawnDistanceFromParent = 0f;

		CloudsRaymarchedVolume cloudsRaymarchedVolume;

		Material lightningBoltMaterial = null;

		bool useBodyRadiusIntersection = false;
		bool initialized = false;

		List<AudioClip> nearAudioClips = new List<AudioClip>();
		List<AudioClip> farAudioClips = new List<AudioClip>();

		public bool Apply(Transform parent, CelestialBody celestialBody, CloudsRaymarchedVolume volume)
		{
			lightningConfigObject = LightningManager.GetConfig(lightningConfig);

			if (lightningConfigObject == null)
				return false;

			// precompute the spawn times for 100s and just repeat those
			// this could be somewhat wasteful memory-wise, so maybe do it on enable in-game and not on init
			int totalSpawns = (int)(lightningConfigObject.SpawnChancePerSecond * 100f);

			for (int i = 0; i < totalSpawns; i++)
			{
				spawnTimesList.Add(Random.Range(0f, 100f));
			}

			spawnTimesList.Sort();

			if (spawnTimesList.Count == 0)
				return false;

			parentTransform = parent;
			parentRadius = (float)celestialBody.Radius;
			spawnDistanceFromParent = lightningConfigObject.SpawnAltitude +(float) celestialBody.Radius;

			cloudsRaymarchedVolume = volume;

			lightningBoltMaterial = new Material(LightningBoltShader);
			lightningConfigObject.BoltTexture.ApplyTexture(lightningBoltMaterial, "_MainTex");
			lightningBoltMaterial.renderQueue = 2999;

			foreach(var sound in lightningConfigObject.NearSoundNames)
            {
				if (GameDatabase.Instance.ExistsAudioClip(sound.SoundName))
					nearAudioClips.Add(GameDatabase.Instance.GetAudioClip(sound.SoundName));
			}

			foreach (var sound in lightningConfigObject.FarSoundNames)
			{
				if (GameDatabase.Instance.ExistsAudioClip(sound.SoundName))
					farAudioClips.Add(GameDatabase.Instance.GetAudioClip(sound.SoundName));
			}

			useBodyRadiusIntersection = PQSManagerClass.HasRealPQS(celestialBody);

			return true;
		}

		public void Update()
		{
			float time = (float)(Planetarium.GetUniversalTime() % 100);

			int nextIndex = lastSpawnedIndex + 1;
			if (nextIndex == spawnTimesList.Count) nextIndex = 0;

			if (nextIndex < lastSpawnedIndex && time > spawnTimesList[lastSpawnedIndex]) return;

			if (TimeWarp.CurrentRate < 5f)
            {
                // TODO: when you generate the lightning make the number of "brightness bumps" parametric from 1-3 and make up a formula for them
                while (ShouldSpawn(time, nextIndex))
                {
                    if (initialized)
                        Spawn();

                    // move to next
                    lastSpawnedIndex = nextIndex;
                    nextIndex++;
				}

				lastSpawnTime = time;
            }

            initialized = true;
		}

        private bool ShouldSpawn(float time, int nextIndex)
        {
			if (time < lastSpawnTime) time += 100f;

			return nextIndex < spawnTimesList.Count && time > spawnTimesList[nextIndex];
        }

        void Spawn()
		{
			float cameraAltitude = (FlightCamera.fetch.transform.position - parentTransform.position).magnitude - parentRadius;

			if (currentCount < maxConcurrent && (!useBodyRadiusIntersection || cameraAltitude >= 0f))
			{
				// TODO: randomize spawn altitude?

				float currentSpawnRange = Mathf.Max(lightningConfigObject.MinSpawnRange, cameraAltitude * 2f);
				Vector3 spawnPosition = FlightCamera.fetch.transform.position + new Vector3(Random.Range(-currentSpawnRange, currentSpawnRange), Random.Range(-currentSpawnRange, currentSpawnRange), Random.Range(-currentSpawnRange, currentSpawnRange));

				spawnPosition = (spawnPosition - parentTransform.position).normalized * spawnDistanceFromParent + parentTransform.position;
				if (cloudsRaymarchedVolume.SampleCoverage(spawnPosition, out float cloudType, false)  > 0.1f)
                {
					float cloudTypeSpawnChance = cloudsRaymarchedVolume.GetInterpolatedCloudTypeLightningFrequency(cloudType);

					if (cloudTypeSpawnChance > 0f && cloudTypeSpawnChance > Random.Range(0f, 1f))
                    {
						GameObject lightGameObject = new GameObject();

						lightGameObject.transform.position = spawnPosition;
						lightGameObject.transform.parent = parentTransform;
						lightGameObject.layer = (int)Tools.Layer.Local;
						lightGameObject.SetActive(true);

						Light light = lightGameObject.AddComponent<Light>();
						light.type = LightType.Point;

						light.intensity = lightningConfigObject.LightIntensity;
						light.range = lightningConfigObject.LightRange;               //probably should compute this based on the intensity and not have it as a parameter?
						light.color = lightningConfigObject.LightColor;

						// light.renderMode = LightRenderMode.ForceVertex; // incompatible with Parallax for now

						light.cullingMask = (1 << (int)Tools.Layer.Local) | (1 << (int)Tools.Layer.Parts) | (1 << (int)Tools.Layer.Kerbals) | (1 << (int)Tools.Layer.Default);

						GameObject boltGameObject = GameObject.CreatePrimitive(PrimitiveType.Quad);

						var collider = boltGameObject.GetComponent<Collider>(); // TODO: remove this, maybe just create a single GO that you instantiate
						if (collider != null) GameObject.Destroy(collider);

						if (!Tools.IsUnifiedCameraMode())
						{
							var mf = boltGameObject.GetComponent<MeshFilter>();
							mf.mesh.bounds = new Bounds(Vector3.zero, new Vector3(700000f, 700000f, 700000f)); // force rendering on the near camera if OpenGL, because we need to render on top of clouds
						}

						var boltMaterial = Material.Instantiate(lightningBoltMaterial);
						boltMaterial.SetFloat("alpha", 1f);
						boltMaterial.SetColor("color", lightningConfigObject.BoltColor);

						boltGameObject.GetComponent<MeshRenderer>().material = boltMaterial;
						boltGameObject.transform.position = spawnPosition + 0.5f * lightningConfigObject.BoltHeight * (parentTransform.position - spawnPosition).normalized;

						Vector3 upAxis = (boltGameObject.transform.position - parentTransform.position).normalized;
						boltGameObject.transform.rotation = Quaternion.LookRotation(Vector3.Cross(upAxis, Vector3.Cross(upAxis, FlightCamera.fetch.transform.forward)), upAxis);

						boltGameObject.transform.localScale = new Vector3(lightningConfigObject.BoltWidth, lightningConfigObject.BoltHeight, 1f);
						boltGameObject.transform.parent = lightGameObject.transform;

						Vector2 randomIndexes = new Vector2(Random.Range(0f, 1f), Random.Range(0f, 1f));
						boltMaterial.SetVector("randomIndexes", randomIndexes);
						boltMaterial.SetVector("lightningSheetCount", lightningConfigObject.LightningSheetCount);

						activeLightningList.AddLast(new LightningInstance() { lifeTime = lightningConfigObject.LifeTime, lightGameObject = lightGameObject, color = light.color, light = light, startIntensity = lightningConfigObject.LightIntensity, startLifeTime = lightningConfigObject.LifeTime, boltGameObject = boltGameObject, lightningBoltMaterial = boltMaterial, parentTransform = parentTransform });


						var soundDistance = (spawnPosition - FlightCamera.fetch.transform.position).magnitude;

						if (nearAudioClips.Count > 0 && soundDistance < lightningConfigObject.SoundMaxDistance)
						{
							GameObject boltSoundGameObject = new GameObject();
							boltSoundGameObject.transform.position = boltGameObject.transform.position;
							boltSoundGameObject.transform.parent = parentTransform;

							var audioSource = boltSoundGameObject.AddComponent<AudioSource>();
							audioSource.clip = soundDistance > lightningConfigObject.SoundFarThreshold ? farAudioClips[Random.Range(0, farAudioClips.Count)] : nearAudioClips[Random.Range(0, nearAudioClips.Count)];
							audioSource.rolloffMode = AudioRolloffMode.Linear;
							audioSource.spatialBlend = 1f;
							audioSource.minDistance = lightningConfigObject.SoundMinDistance;
							audioSource.maxDistance = lightningConfigObject.SoundMaxDistance;

							float dist = (boltGameObject.transform.position - FlightCamera.fetch.transform.position).magnitude;

							if (lightningConfigObject.RealisticAudioDelayMultiplier > 0f)
							{
								float delay = lightningConfigObject.RealisticAudioDelayMultiplier * dist / 343f; // speed of sound on Earth
								audioSource.PlayDelayed(delay);
							}
							else
							{
								audioSource.Play();
							}

							boltSoundGameObject.AddComponent<KillOnAudioClipFinished>();
						}

						currentCount++;
					}
				}

			}
		}
	}

	public class KillOnAudioClipFinished : MonoBehaviour
    {
		AudioSource audioSource = null;

		public void Awake()
        {
			audioSource = gameObject?.GetComponent<AudioSource>();
			if (audioSource == null)
				GameObject.Destroy(gameObject);
		}

		public void Update()
        {
			if (audioSource != null && !audioSource.isPlaying)      // works with PlayDelayed
			{
				audioSource = null;
				GameObject.Destroy(gameObject);
			}
		}
    }

	public class LightningInstance
	{
		public float startIntensity = 1f;
		public float startLifeTime = 1f;
		public Color color = Color.white;

		public float lifeTime = 0f;
		public GameObject lightGameObject = null;
		public Light light = null;

		public GameObject boltGameObject = null;
		public Material lightningBoltMaterial = null;
		public Transform parentTransform = null;

		// return true if it should be destroyed
		public bool Update(float deltaTime)
		{
			lifeTime -= deltaTime;
			light.intensity = startIntensity * lifeTime / startLifeTime; //placeholder

			Vector3 upAxis = (boltGameObject.transform.position - parentTransform.position).normalized;
			boltGameObject.transform.rotation = Quaternion.LookRotation(Vector3.Cross(upAxis, Vector3.Cross(upAxis, FlightCamera.fetch.transform.forward)), upAxis);

			lightningBoltMaterial.SetFloat("alpha", lifeTime);

			if (lifeTime <= 0)
			{
				light.enabled = false;
				light.intensity = 0f;
				light.range = 0f;
				GameObject.Destroy(lightGameObject);
				GameObject.Destroy(boltGameObject);
				return true;
			}

			return false;
		}
	}
}
