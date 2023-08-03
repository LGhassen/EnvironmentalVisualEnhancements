using Utils;

namespace Atmosphere
{
    public class CloudType
    {
        [ConfigItem]
        string typeName = "New cloud type";
        
        [ConfigItem]
        float minAltitude = 0f;
        [ConfigItem]
        float maxAltitude = 0f;

        [ConfigItem]
        float density = 0.1f;

        [ConfigItem]
        float baseNoiseTiling = 1000f;

        [ConfigItem]
        float detailNoiseStrength = 0.5f;

        [ConfigItem]
        float particleFieldDensity = 1f;

        [ConfigItem]
        float dropletsDensity = 1f;

        [ConfigItem]
        float lightningFrequency = 1f;

        [ConfigItem]
        float ambientVolume = 1f;

        [ConfigItem]
        bool interpolateCloudHeights = true;

        [ConfigItem]
        FloatCurve coverageCurve;

        public FloatCurve CoverageCurve { get => coverageCurve; }
        public float MinAltitude { get => minAltitude; }
        public float MaxAltitude { get => maxAltitude; }
        public bool InterpolateCloudHeights { get => interpolateCloudHeights; }
        public float BaseNoiseTiling { get => baseNoiseTiling; }
        public float DetailNoiseStrength { get => detailNoiseStrength; }

        public float Density { get => density; }

        public float ParticleFieldDensity { get => particleFieldDensity; }

        public float DropletsDensity { get => dropletsDensity; }

        public float LightningFrequency { get => lightningFrequency; }

        public float AmbientVolume { get => ambientVolume; }

        public string TypeName { get => typeName; }
    }
}