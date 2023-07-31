using EVEManager;
using UnityEngine;
using Utils;
using System.Collections.Generic;

namespace Atmosphere
{
    [ConfigName("name")]
    public class DropletsConfig : IEVEObject
    {
        [ConfigItem]
        string name = "new droplets config";

        [ConfigItem]
        float minCoverageThreshold = 0.0f;

        [ConfigItem]
        float maxCoverageThreshold = 0.6f;

        [ConfigItem]
        float refractionStrength = 0.2f;

        [ConfigItem]
        float translucency = 0.9f;

        [ConfigItem]
        Vector3 color = new Vector3(255f, 255f, 255f);

        [ConfigItem]
        float specularStrength = 1f;

        [ConfigItem]
        float scale = 1f;

        [ConfigItem]
        float triplanarTransitionSharpness = 2f;

        [ConfigItem]
        float speedIncreaseFactor = 0.1f;

        [ConfigItem]
        float maxModulationSpeed = 100f;

        [ConfigItem]
        TextureWrapper noise = null;

        [ConfigItem]
        float noiseScale = 4f;

        [ConfigItem]
        float lowSpeedNoiseStrength = 0.01f;

        [ConfigItem]
        float highSpeedNoiseStrength = 0.01f;

        [ConfigItem]
        float lowSpeedStreakRatio = 1f;

        [ConfigItem]
        float highSpeedStreakRatio = 3f;

        [ConfigItem]
        float lowSpeedTimeRandomness = 1f;

        [ConfigItem]
        float highSpeedTimeRandomness = 0.3f;

        [ConfigItem]
        List<SideDropletLayer> sideDropletLayers = new List<SideDropletLayer>();

        [ConfigItem]
        List<TopDropletLayer> topDropletLayers = new List<TopDropletLayer>();

        public string Name { get => name; }
        public TextureWrapper Noise { get => noise; }
        public float MinCoverageThreshold { get => minCoverageThreshold; }
        public float MaxCoverageThreshold { get => maxCoverageThreshold; }
        public float SpeedIncreaseFactor { get => speedIncreaseFactor; }
        public float RefractionStrength { get => refractionStrength; }
        public float Translucency { get => translucency; }
        public Vector3 Color { get => color; }
        public float SpecularStrength { get => specularStrength; }
        public float Scale { get => scale; }
        public float TriplanarTransitionSharpness { get => triplanarTransitionSharpness; }
        public float NoiseScale { get => noiseScale; }
        public float LowSpeedNoiseStrength { get => lowSpeedNoiseStrength; }
        public float HighSpeedNoiseStrength { get => highSpeedNoiseStrength; }
        public float LowSpeedStreakRatio { get => lowSpeedStreakRatio; }
        public float HighSpeedStreakRatio { get => highSpeedStreakRatio; }
        public float LowSpeedTimeRandomness { get => lowSpeedTimeRandomness; }
        public float HighSpeedTimeRandomness { get => highSpeedTimeRandomness; }
        public float MaxModulationSpeed { get => maxModulationSpeed; }
        public List<SideDropletLayer> SideDropletLayers { get => sideDropletLayers; }
        public List<TopDropletLayer> TopDropletLayers { get => topDropletLayers; }


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

    public class SideDropletLayer
    {
        [ConfigItem]
        string name = "new side droplets layer";

        [ConfigItem]
        float fallSpeed = 0.15f;

        [ConfigItem]
        float scale = 1f;

        [ConfigItem]
        float dropletToTrailAspectRatio = 0.06f;

        [ConfigItem]
        float streakRatio = 0.06f;

        public float FallSpeed { get => fallSpeed; }
        public float Scale { get => scale; }
        public float DropletToTrailAspectRatio { get => dropletToTrailAspectRatio; }
        public float StreakRatio { get => streakRatio; }
    }

    public class TopDropletLayer
    {
        [ConfigItem]
        string name = "new top droplets layer";

        [ConfigItem]
        float scale = 1f;

        public float Scale { get => scale; }
    }
}