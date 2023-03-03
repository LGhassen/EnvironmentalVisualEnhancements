using ShaderLoader;
using System.Collections.Generic;
using UnityEngine;
using Utils;

namespace Atmosphere
{
	public class Lightning
	{
		static LinkedList<LightningObject> activeLightningList = new LinkedList<LightningObject>();
		static Vector4[] activeLightningShaderLights = new Vector4[15];

		static int maxConcurrent = 15;
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
						activeLightningShaderLights[currentIndex] = new Vector4(lightningNode.Value.gameObject.transform.position.x,
							lightningNode.Value.gameObject.transform.position.y,
							lightningNode.Value.gameObject.transform.position.z,
							lightningNode.Value.lifeTime);

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

		public class LightningObject
		{
			public float startIntensity = 1f;
			public float startLifeTime = 1f;

			public float lifeTime = 0f;
			public GameObject gameObject = null;
			public Light light = null;

			// return true if it should be destroyed
			public bool Update(float deltaTime)
            {
				lifeTime -= deltaTime;
				light.intensity = startIntensity * lifeTime / startLifeTime; //placeholder

				if (lifeTime <= 0)
				{
					GameObject.Destroy(gameObject);
					return true;
				}

				return false;
			}
		}

		[ConfigItem]
		float spawnChancePerSecond = 0.7f;

		[ConfigItem]
		float spawnRange = 5000f;

		[ConfigItem]
		float lifeTime = 0.5f;								//TOOD: turn into a max/min lifetime, affects performance though

		[ConfigItem]
		float lightIntensity = 3f;

		[ConfigItem]
		float lightRange = 10000f;

		List<float> spawnTimesList = new List<float>();     // TODO: change this to add probability
		int lastSpawnedIndex = -1;

		Transform parentTransform;

		[ConfigItem]
		float spawnAltitude = 2000;

		float spawnDistanceFromParent = 0f;

		CloudsRaymarchedVolume cloudsRaymarchedVolume;

		public bool Apply(Transform parent, CelestialBody celestialBody, CloudsRaymarchedVolume volume)
		{
			// precompute the spawn times for 100s and just repeat those
			// this could be somewhat wasteful memory-wise, so maybe do it on enable in-game and not on init
			int totalSpawns = (int)(spawnChancePerSecond * 100f);

			for (int i = 0; i < totalSpawns; i++)
			{
				spawnTimesList.Add(UnityEngine.Random.Range(0f, 100f));
			}

			spawnTimesList.Sort();

			if (spawnTimesList.Count == 0)
				return false;

			parentTransform = parent;
			spawnDistanceFromParent = spawnAltitude +(float) celestialBody.Radius;

			cloudsRaymarchedVolume = volume;

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
					Spawn();

					// move to next
					lastSpawnedIndex = nextIndex;
					nextIndex++;
				}
			}
		}

		void Spawn()
		{
			if (currentCount < maxConcurrent)
			{
				// TODO: randomize spawn altitude?
				Vector3 spawnPosition = FlightCamera.fetch.transform.position + new Vector3(UnityEngine.Random.Range(-spawnRange, spawnRange), UnityEngine.Random.Range(-spawnRange, spawnRange), UnityEngine.Random.Range(-spawnRange, spawnRange));

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

					light.intensity = lightIntensity;
					light.range = lightRange;               //probably should compute this based on the intensity and not have it as a parameter?

					// light.renderMode = LightRenderMode.ForceVertex; // incompatible with Parallax for now

					light.cullingMask = (1 << (int)Tools.Layer.Local) | (1 << (int)Tools.Layer.Parts) | (1 << (int)Tools.Layer.Kerbals) | (1 << (int)Tools.Layer.Default);

					activeLightningList.AddLast(new LightningObject() { lifeTime = lifeTime, gameObject = lightGameObject, light = light, startIntensity = lightIntensity, startLifeTime = lifeTime });

					currentCount++;
				}

			}
		}
	}


}
