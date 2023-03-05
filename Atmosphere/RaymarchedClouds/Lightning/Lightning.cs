using ShaderLoader;
using System.Collections.Generic;
using UnityEngine;
using Utils;

namespace Atmosphere
{
	public class Lightning
	{
		static LinkedList<LightningInstance> activeLightningList = new LinkedList<LightningInstance>();
		static Vector4[] activeLightningShaderLights = new Vector4[15];

		static int maxConcurrent = 4; // more than this and it tanks the performance, especially using Parallax and rain/splashes
		static int currentCount = 0;
		static int lastUpdateFrame = 0;

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
				mat.SetVectorArray("lightningArray", new List<Vector4>(activeLightningShaderLights));
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

		Transform parentTransform;

		float spawnDistanceFromParent = 0f;

		CloudsRaymarchedVolume cloudsRaymarchedVolume;

		Material lightningBoltMaterial = null;

		bool initialized = false;

		List<AudioClip> audioClips = new List<AudioClip>();

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
				spawnTimesList.Add(UnityEngine.Random.Range(0f, 100f));
			}

			spawnTimesList.Sort();

			if (spawnTimesList.Count == 0)
				return false;

			parentTransform = parent;
			spawnDistanceFromParent = lightningConfigObject.SpawnAltitude +(float) celestialBody.Radius;

			cloudsRaymarchedVolume = volume;

			lightningBoltMaterial = new Material(LightningBoltShader);
			lightningConfigObject.BoltTexture.ApplyTexture(lightningBoltMaterial, "_MainTex");
			lightningBoltMaterial.renderQueue = 2999;

			foreach(var sound in lightningConfigObject.SoundNames)
            {
				if (GameDatabase.Instance.ExistsAudioClip(sound.SoundName))
					audioClips.Add(GameDatabase.Instance.GetAudioClip(sound.SoundName));
			}

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
				while (nextIndex < spawnTimesList.Count && time > spawnTimesList[nextIndex])
				{
					if (initialized)
						Spawn();

					// move to next
					lastSpawnedIndex = nextIndex;
					nextIndex++;
				}
			}

			initialized = true;
		}

		void Spawn()
		{
			if (currentCount < maxConcurrent)
			{
				// TODO: randomize spawn altitude?
				Vector3 spawnPosition = FlightCamera.fetch.transform.position + new Vector3(UnityEngine.Random.Range(-lightningConfigObject.SpawnRange, lightningConfigObject.SpawnRange), UnityEngine.Random.Range(-lightningConfigObject.SpawnRange, lightningConfigObject.SpawnRange), UnityEngine.Random.Range(-lightningConfigObject.SpawnRange, lightningConfigObject.SpawnRange));

				spawnPosition = (spawnPosition - parentTransform.position).normalized * spawnDistanceFromParent + parentTransform.position;
				if (cloudsRaymarchedVolume.SampleCoverage(spawnPosition)  > 0.1f) // TODO: parametrize
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

					// light.renderMode = LightRenderMode.ForceVertex; // incompatible with Parallax for now

					light.cullingMask = (1 << (int)Tools.Layer.Local) | (1 << (int)Tools.Layer.Parts) | (1 << (int)Tools.Layer.Kerbals) | (1 << (int)Tools.Layer.Default);

					GameObject boltGameObject = GameObject.CreatePrimitive(PrimitiveType.Quad);
					
					var collider = boltGameObject.GetComponent<Collider>(); // TODO: remove this, maybe just create a single GO that you instantiate
					if (collider != null) GameObject.Destroy(collider);

					var boltMaterial = Material.Instantiate(lightningBoltMaterial);
					boltMaterial.SetFloat("alpha", 1f);

					boltGameObject.GetComponent<MeshRenderer>().material = boltMaterial;
					boltGameObject.transform.position = spawnPosition;

					Vector3 upAxis = (boltGameObject.transform.position - parentTransform.position).normalized;
					boltGameObject.transform.rotation = Quaternion.LookRotation(Vector3.Cross(upAxis, Vector3.Cross(upAxis, FlightCamera.fetch.transform.forward)), upAxis);

					boltGameObject.transform.localScale = new Vector3(lightningConfigObject.BoltHeight * 2f, lightningConfigObject.BoltWidth * 2f, 1f);
					boltGameObject.transform.parent = lightGameObject.transform;

					Vector2 randomIndexes = new Vector2(Random.Range(0f, 1f), Random.Range(0f, 1f));
					boltMaterial.SetVector("randomIndexes", randomIndexes);
					boltMaterial.SetVector("lightningSheetCount", lightningConfigObject.LightningSheetCount);

					activeLightningList.AddLast(new LightningInstance() { lifeTime = lightningConfigObject.LifeTime, lightGameObject = lightGameObject, light = light, startIntensity = lightningConfigObject.LightIntensity, startLifeTime = lightningConfigObject.LifeTime, boltGameObject = boltGameObject, lightningBoltMaterial = boltMaterial, parentTransform = parentTransform });

					if (audioClips.Count > 0)
                    {
						GameObject boltSoundGameObject = new GameObject();
						boltSoundGameObject.transform.position = boltGameObject.transform.position;
						boltSoundGameObject.transform.parent = parentTransform;

						var audioSource = boltSoundGameObject.AddComponent<AudioSource>();
						audioSource.clip = audioClips[Random.Range(0, audioClips.Count)];
						audioSource.rolloffMode = AudioRolloffMode.Linear;
						audioSource.spatialBlend = 1f;
						audioSource.minDistance = lightningConfigObject.SoundMinDistance;
						audioSource.maxDistance = lightningConfigObject.SoundMaxDistance;

						float dist = (boltGameObject.transform.position - FlightCamera.fetch.transform.position).magnitude;

						if(lightningConfigObject.RealisticAudioDelay)
                        {
							float delay = dist / 343f; // speed of sound on Earth
							audioSource.PlayDelayed(delay);
						}
						else
						{ 
							audioSource.Play();
						}

						boltSoundGameObject.AddComponent<KillOnAudioClipFinished>(); // does this work with playDelayed
					}

					// TODO: give it a special script that will kill it when done

					currentCount++;
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
			if (audioSource != null && !audioSource.isPlaying)
				GameObject.Destroy(gameObject);
		}
    }

	public class LightningInstance
	{
		public float startIntensity = 1f;
		public float startLifeTime = 1f;

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
