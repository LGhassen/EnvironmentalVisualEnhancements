using Utils;

namespace Atmosphere
{
    public class RaymarchingSettings
    {
        [ConfigItem]
        float lightMarchSteps = 4;

        [ConfigItem]
        float lightMarchDistance = 700f;

        [ConfigItem]
        float baseStepSize = 32f;
        [ConfigItem]
        float adaptiveStepSizeFactor = 0.012f;
        [ConfigItem]
        float maxStepSize = 180f;

        public float LightMarchSteps { get => lightMarchSteps; }
        public float LightMarchDistance { get => lightMarchDistance; }
        public float BaseStepSize { get => baseStepSize; }
        public float AdaptiveStepSizeFactor { get => adaptiveStepSizeFactor; }
        public float MaxStepSize { get => maxStepSize; }
    }
}