using EVEManager;
using UnityEngine;
using Utils;

namespace Atmosphere
{
    [ConfigName("name")]
    public class DropletsConfig : IEVEObject 
    {
		[ConfigItem]
		string name = "new droplets config";

		[ConfigItem]
		float speed = 1f;

        [ConfigItem]
        float speedIncreaseFactor = 0.1f;

        [ConfigItem]
        float refractionStrength = 0.2f;

        [ConfigItem]
        float specularStrength = 1f;

        [ConfigItem]
        float uvScale = 6f;

        [ConfigItem]
        float triplanarTransitionSharpness = 2f;

        [ConfigItem]
        TextureWrapper noise = null;

        [ConfigItem]
        float lowSpeedNoiseStrength = 0.01f;

        [ConfigItem]
        float lowSpeedNoiseScale = 4f;

        [ConfigItem]
        float highSpeedNoiseStrength = 0.01f;

        [ConfigItem]
        float highSpeedNoiseScale = 2f;

        [ConfigItem]
        float lowSpeedStreakRatio = 0.05f;

        [ConfigItem]
        float highSpeedStreakRatio = 0.12f;

        [ConfigItem]
        float maxModulationSpeed = 100f;

        public string Name { get => name; }
        public TextureWrapper Noise { get => noise; }
        public float Speed { get => speed; }
        public float SpeedIncreaseFactor { get => speedIncreaseFactor; }
        public float RefractionStrength { get => refractionStrength; }
        public float SpecularStrength { get => specularStrength; }
        public float UVScale { get => uvScale; }
        public float TriplanarTransitionSharpness { get => triplanarTransitionSharpness; }
        public float LowSpeedNoiseStrength { get => lowSpeedNoiseStrength; }
        public float LowSpeedNoiseScale { get => lowSpeedNoiseScale; }
        public float HighSpeedNoiseStrength { get => highSpeedNoiseStrength; }
        public float HighSpeedNoiseScale { get => highSpeedNoiseScale; }
        public float LowSpeedStreakRatio { get => lowSpeedStreakRatio; }
        public float HighSpeedStreakRatio { get => highSpeedStreakRatio; }
        public float MaxModulationSpeed { get => maxModulationSpeed; }

        public void LoadConfigNode(ConfigNode node)
        {
            ConfigHelper.LoadObjectFromConfig(this, node);
        }

        public override string ToString() { return name; }

        public void Apply() 
        { 

        }
        public void Remove()
        {
            if (noise != null) noise.Remove();
        }

        protected void Start()
        {
            
        }
	}
}
