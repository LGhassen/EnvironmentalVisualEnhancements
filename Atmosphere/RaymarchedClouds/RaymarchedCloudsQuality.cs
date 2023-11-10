using EVEManager;
using Utils;

namespace Atmosphere
{
    enum TemporalUpscaling
    {
        // off,
        x1,
        x2,
        x3,
        x4,
        //x5,
        x6,
        x8,
        x9,
        //x10,
        x12,
        x16,
        x32
    }

    [ConfigName("name")]
    public class RaymarchedCloudsQuality : IEVEObject
    {
        [ConfigItem]
        TemporalUpscaling temporalUpscaling = TemporalUpscaling.x8;

        [ConfigItem]
        bool nonTiling3DNoise = true;

        [ConfigItem]
        bool useOrbitMode = true;

        [ConfigItem]
        LightVolumeSettings lightVolumeSettings = new LightVolumeSettings();

        internal TemporalUpscaling TemporalUpscaling { get => temporalUpscaling; }
        internal bool NonTiling3DNoise { get => nonTiling3DNoise; }

        internal bool UseOrbitMode { get => useOrbitMode; }

        internal LightVolumeSettings LightVolumeSettings { get => lightVolumeSettings; }

        public void LoadConfigNode(ConfigNode node)
        {
            ConfigHelper.LoadObjectFromConfig(this, node);
        }

        public void Apply()
        {

        }

        public void Remove()
        {

        }
    }

    public class LightVolumeSettings
    {
        [ConfigItem]
        bool useLightVolume = true; // TODO: may remove this after doing comparison videos/shots

        [ConfigItem]
        float horizontalResolution = 256f;

        [ConfigItem]
        float verticalResolution = 32f;

        [ConfigItem]
        float directLightTimeSlicing = 8f;

        [ConfigItem]
        float ambientLightTimeSlicing = 32f;

        [ConfigItem]
        float timewarpRateMultiplier = 3f;

        public bool UseLightVolume { get => useLightVolume; }
        public float HorizontalResolution { get => horizontalResolution; }
        public float VerticalResolution { get => verticalResolution; }
        public float DirectLightTimeSlicing { get => directLightTimeSlicing; }
        public float AmbientLightTimeSlicing { get => ambientLightTimeSlicing; }

        public float TimewarpRateMultiplier { get => timewarpRateMultiplier; }
    }
}
