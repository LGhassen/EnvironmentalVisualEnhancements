using Utils;
using UnityEngine;

namespace Atmosphere
{
    public class LightVolumeUsage
    {
        [ConfigItem]
        bool useLightVolume = true;

        [ConfigItem, Optional]
        float maxLightVolumeRadius = Mathf.Infinity;

        public bool UseLightVolume { get => useLightVolume; }
        public float MaxLightVolumeRadius { get => maxLightVolumeRadius; }
    }
}