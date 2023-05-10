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
        Color lightColor = Color.white * 255f;

        [ConfigItem]
        float lightIntensity = 3f;

        [ConfigItem]
        float lightRange = 10000f;

        [ConfigItem]
        float spawnAltitude = 2000;

        [ConfigItem]
        Color boltColor = Color.white * 255f;

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
        float soundFarThreshold = 5000f;

        [ConfigItem]
        float realisticAudioDelayMultiplier = 0f;

        [ConfigItem, Optional]
        List<LightningSoundConfig> nearSounds = new List<LightningSoundConfig>();

        [ConfigItem, Optional]
        List<LightningSoundConfig> farSounds = new List<LightningSoundConfig>();

        public string Name { get => name; }
        public float SpawnChancePerSecond { get => spawnChancePerSecond; }
        public float SpawnRange { get => spawnRange; }
        public float LifeTime { get => lifeTime; }

        public Color LightColor { get => lightColor / 255f; }

        public Color BoltColor { get => boltColor / 255f; }

        public float LightIntensity { get => lightIntensity; }
        public float LightRange { get => lightRange; }
        public float SpawnAltitude { get => spawnAltitude; }

        public float BoltWidth { get => boltWidth; }

        public float BoltHeight { get => boltHeight; }

        public TextureWrapper BoltTexture { get => boltTexture; }
        public Vector2 LightningSheetCount { get => lightningSheetCount; }

        public float SoundMinDistance { get => soundMinDistance; }

        public float SoundMaxDistance { get => soundMaxDistance; }

        public float SoundFarThreshold { get => soundFarThreshold; }

        public float RealisticAudioDelayMultiplier { get => realisticAudioDelayMultiplier; }

        public List<LightningSoundConfig> NearSoundNames { get => nearSounds; }

        public List<LightningSoundConfig> FarSoundNames { get => farSounds; }

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