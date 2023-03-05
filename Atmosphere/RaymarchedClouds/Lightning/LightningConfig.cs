using EVEManager;
using UnityEngine;
using Utils;
using System.Collections.Generic;

namespace Atmosphere
{
    [ConfigName("name")]
    public class LightningConfig : IEVEObject
    {
        [ConfigItem]
        string name = "new lightning type";

        [ConfigItem]
        float spawnChancePerSecond = 1f;

        [ConfigItem]
        float spawnRange = 15000f;

        [ConfigItem]
        float lifeTime = 0.5f;                              //TOOD: turn into a max/min lifetime

        [ConfigItem]
        float lightIntensity = 3f;

        //[ConfigItem]
        float lightRange = 10000f;

        [ConfigItem]
        float spawnAltitude = 2000;

        [ConfigItem]
        float boltWidth = 2000f;

        [ConfigItem]
        float boltHeight = 2000f;

        [ConfigItem]
        TextureWrapper boltTexture = null;

        [ConfigItem]
        Vector2 lightningSheetCount = new Vector2(1f, 1f);

        [ConfigItem]
        float soundMinDistance = 2000f;

        [ConfigItem]
        float soundMaxDistance = 15000f;

        [ConfigItem]
        bool realisticAudioDelay = false;

        [ConfigItem, Optional]
        List<LightningSoundConfig> sounds = new List<LightningSoundConfig>();

        public string Name { get => name; }
        public float SpawnChancePerSecond { get => spawnChancePerSecond; }
        public float SpawnRange { get => spawnRange; }
        public float LifeTime { get => lifeTime; }
        public float LightIntensity { get => lightIntensity; }
        public float LightRange { get => lightRange; }
        public float SpawnAltitude { get => spawnAltitude; }

        public float BoltWidth { get => boltWidth; }

        public float BoltHeight { get => boltHeight; }

        public TextureWrapper BoltTexture { get => boltTexture; }
        public Vector2 LightningSheetCount { get => lightningSheetCount; }

        public float SoundMinDistance { get => soundMinDistance; }

        public float SoundMaxDistance { get => soundMaxDistance; }

        public bool RealisticAudioDelay { get => realisticAudioDelay; }

        public List<LightningSoundConfig> SoundNames { get => sounds; }

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

    public class LightningSoundConfig
    {
        [ConfigItem]
        string soundName = "Sound path here";

        public string SoundName { get => soundName; }
    }
}