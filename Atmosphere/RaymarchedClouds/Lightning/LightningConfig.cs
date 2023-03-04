using EVEManager;
using UnityEngine;
using Utils;

namespace Atmosphere
{
    [ConfigName("name")]
    public class LightningConfig : IEVEObject 
    {
		[ConfigItem]
		string name = "new lightning type";

		[ConfigItem]
		float spawnChancePerSecond = 0.7f;

		[ConfigItem]
		float spawnRange = 15000f;

		[ConfigItem]
		float lifeTime = 0.5f;                              //TOOD: turn into a max/min lifetime, affects performance though

		[ConfigItem]
		float lightIntensity = 3f;

		[ConfigItem]
		float lightRange = 10000f;

		[ConfigItem]
		float spawnAltitude = 2000;

		[ConfigItem]
		TextureWrapper boltTexture = null;

		[ConfigItem]
		Vector2 lightningSheetCount = new Vector2(1f, 1f);

        public string Name { get => name; }
        public float SpawnChancePerSecond { get => spawnChancePerSecond; }
        public float SpawnRange { get => spawnRange; }
        public float LifeTime { get => lifeTime; }
        public float LightIntensity { get => lightIntensity; }
        public float LightRange { get => lightRange; }
        public float SpawnAltitude { get => spawnAltitude; }
        public TextureWrapper BoltTexture { get => boltTexture; }
        public Vector2 LightningSheetCount { get => lightningSheetCount; }

        public void LoadConfigNode(ConfigNode node)
        {
            ConfigHelper.LoadObjectFromConfig(this, node);
        }

        public override string ToString() { return name; }

        public void Apply() 
        { 

        }
        public void Remove() { }

        protected void Start()
        {
            
        }
    }
}
