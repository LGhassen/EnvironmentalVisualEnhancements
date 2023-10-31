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
        float lightVolumeHorizontalResolution = 256f;

        [ConfigItem]
        float lightVolumeVerticalResolution = 32f;

        [ConfigItem]
        float lightVolumeDirectLightTimeSlicingFrames = 8f;

        [ConfigItem]
        float lightVolumeAmbientLightTimeSlicingFrames = 32f;

        internal TemporalUpscaling TemporalUpscaling { get => temporalUpscaling; }
        internal bool NonTiling3DNoise { get => nonTiling3DNoise; }

        internal bool UseOrbitMode { get => useOrbitMode; }

        internal float LightVolumeHorizontalResolution { get => lightVolumeHorizontalResolution; }

        internal float LightVolumeVerticalResolution { get => lightVolumeVerticalResolution; }

        internal float LightVolumeDirectLightTimeSlicingFrames { get => lightVolumeDirectLightTimeSlicingFrames; }

        internal float LightVolumeAmbientLightTimeSlicingFrames { get => lightVolumeAmbientLightTimeSlicingFrames; }

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
}
