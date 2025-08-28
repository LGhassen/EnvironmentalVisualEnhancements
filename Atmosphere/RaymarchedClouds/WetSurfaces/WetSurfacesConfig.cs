using EVEManager;
using System;
using UnityEngine;
using Utils;

namespace Atmosphere
{
    [ConfigName("name")]
    public class WetSurfacesConfig : IEVEObject
    {
        [ConfigItem]
        string name = "new wet surfaces config";

        [ConfigItem, GUIHidden]
        String body;


        [ConfigItem]
        float minCoverageThreshold = 0.0f;

        [ConfigItem]
        float maxCoverageThreshold = 1.0f;


        [ConfigItem]
        TextureWrapper puddlesTexture = null;

        [ConfigItem]
        float puddleTextureScale = 1f;

        [ConfigItem]
        float rippleSpeed = 1f;

        [ConfigItem]
        float rippleScale = 1f;


        [ConfigItem]
        Scenery scenery = new Scenery();

        [ConfigItem]
        Terrain terrain = new Terrain();

        [ConfigItem]
        Craft craft = new Craft();

        public string Name { get => name; }
        public string Body { get => body; }


        public float MinCoverageThreshold { get => minCoverageThreshold; }
        public float MaxCoverageThreshold { get => maxCoverageThreshold; }


        public TextureWrapper PuddlesTexture { get => puddlesTexture; }
        public float PuddleTextureScale { get => puddleTextureScale; }
        public float RippleScale { get => rippleScale; }
        public float RippleSpeed { get => rippleSpeed; }


        public Scenery Scenery { get => scenery; }
        public Terrain Terrain { get => terrain; }
        public Craft Craft { get => craft; }


        public void LoadConfigNode(ConfigNode node)
        {
            ConfigHelper.LoadObjectFromConfig(this, node);
        }

        public override string ToString() { return name; }

        public void Apply()
        {

        }


        protected void Start()
        {

        }

        public void Remove()
        {
            if (puddlesTexture != null)
            {
                puddlesTexture.Remove();
            }
        }
    }

    public class Scenery
    {
        [ConfigItem]
        float wetnessAccumulationSpeed = 0.1f;

        [ConfigItem]
        float wetnessDryingSpeed = 0.0001f;

        [ConfigItem]
        float wetDiffuse = 0.5f;

        [ConfigItem]
        float wetSmoothness = 0.6f;

        [ConfigItem]
        float puddleAccumulationSpeed = 0.01f;

        [ConfigItem]
        float puddleDryingSpeed = 0.00001f;

        [ConfigItem]
        float maxPuddleAccumulation = 0.85f;

        public float WetnessAccumulationSpeed { get => wetnessAccumulationSpeed; }
        public float WetnessDryingSpeed { get => wetnessDryingSpeed; }
        public float PuddleAccumulationSpeed { get => puddleAccumulationSpeed; }
        public float PuddleDryingSpeed { get => puddleDryingSpeed; }
        public float MaxPuddleAccumulation { get => maxPuddleAccumulation; }
        public float WetDiffuse { get => wetDiffuse; }
        public float WetSmoothness { get => wetSmoothness; }
    }

    public class Terrain
    {
        [ConfigItem]
        float wetnessAccumulationSpeed = 0.1f;

        [ConfigItem]
        float wetnessDryingSpeed = 0.0001f;

        [ConfigItem]
        float wetDiffuse = 0.4f;

        [ConfigItem]
        float wetSmoothness = 0.5f;

        [ConfigItem]
        float puddleAccumulationSpeed = 0.01f;

        [ConfigItem]
        float puddleDryingSpeed = 0.00001f;

        [ConfigItem]
        float maxPuddleAccumulation = 0.5f; // I think 0.4-0.5 here is good?

        // Smoothness and albedo darkening?

        public float WetnessAccumulationSpeed { get => wetnessAccumulationSpeed; }
        public float WetnessDryingSpeed { get => wetnessDryingSpeed; }
        public float PuddleAccumulationSpeed { get => puddleAccumulationSpeed; }
        public float PuddleDryingSpeed { get => puddleDryingSpeed; }
        public float MaxPuddleAccumulation { get => maxPuddleAccumulation; }
        public float WetDiffuse { get => wetDiffuse; }
        public float WetSmoothness { get => wetSmoothness; }
    }

    public class Craft
    {
        [ConfigItem]
        float wetnessAccumulationSpeed = 0.1f;

        [ConfigItem]
        float wetnessDryingSpeed = 0.01f;

        [ConfigItem]
        float wetDiffuse = 0.65f;

        [ConfigItem]
        float wetSmoothness = 0.7f;

        public float WetnessAccumulationSpeed { get => wetnessAccumulationSpeed; }
        public float WetnessDryingSpeed { get => wetnessDryingSpeed; }
        public float WetDiffuse { get => wetDiffuse; }
        public float WetSmoothness { get => wetSmoothness; }
    }
}