using EVEManager;
using System;
using UnityEngine;

namespace Atmosphere
{
    public class RaymarchedCloudsQualityManager : GenericEVEManager<RaymarchedCloudsQuality>
    {
        static TemporalUpscaling temporalUpscaling = TemporalUpscaling.x8;

        public override int LoadOrder { get { return 120; } }

        public override int DisplayOrder { get { return 10; } }

        static bool nonTiling3DNoise = true;

        static bool renderCloudsInReflectionProbes = true;

        static bool mapViewCloudFade = true;

        static float screenShotModeDenoisingIterations = 8f;

        static LightVolumeSettings lightVolumeSettings = new LightVolumeSettings();

        static float ambientVolume = 1f;
        static float lightningVolume = 1f;

        // KSP's built-in volume sliders default to 0.5. Double each and clamp individually so that
        // at default KSP settings the effective multiplier is 1.0 and these sounds aren't quieter
        // than before, while each KSP slider still reaches full mute at 0.
        static float KSPVolume => Mathf.Clamp01(GameSettings.MASTER_VOLUME * 2f) * Mathf.Clamp01(GameSettings.AMBIENCE_VOLUME * 2f);

        internal static float EffectiveAmbientVolume => KSPVolume * ambientVolume;
        internal static float EffectiveLightningVolume => KSPVolume * lightningVolume;

        public override ObjectType objectType { get { return ObjectType.STATIC; } }
        public override String configName { get { return "EVE_RAYMARCHED_CLOUDS_QUALITY"; } }

        internal static TemporalUpscaling TemporalUpscaling { get => temporalUpscaling; }

        internal static bool NonTiling3DNoise { get => nonTiling3DNoise; }

        internal static bool RenderCloudsInReflectionProbes { get => renderCloudsInReflectionProbes; }

        internal static bool MapViewCloudFade { get => mapViewCloudFade; }

        internal static float ScreenShotModeDenoisingIterations { get => screenShotModeDenoisingIterations; }

        internal static LightVolumeSettings LightVolumeSettings { get => lightVolumeSettings; }

        internal static Tuple<int, int> GetReprojectionFactors()
        {
            switch (temporalUpscaling)
            {
                case TemporalUpscaling.x1:
                    return new Tuple<int, int>(1, 1);
                case TemporalUpscaling.x2:
                    return new Tuple<int, int>(2, 1);
                case TemporalUpscaling.x3:
                    return new Tuple<int, int>(3, 1);
                case TemporalUpscaling.x4:
                    return new Tuple<int, int>(2, 2);
                //case TemporalUpscaling.x5:
                    //return new Tuple<int, int>(5, 1);
                case TemporalUpscaling.x6:
                    return new Tuple<int, int>(3, 2);
                case TemporalUpscaling.x8:
                    return new Tuple<int, int>(4, 2);
                case TemporalUpscaling.x9:
                    return new Tuple<int, int>(3, 3);
                //case TemporalUpscaling.x10:
                    //return new Tuple<int, int>(5, 2);
                case TemporalUpscaling.x12:
                    return new Tuple<int, int>(4, 3);
                case TemporalUpscaling.x16:
                    return new Tuple<int, int>(4, 4);
                case TemporalUpscaling.x32:
                    return new Tuple<int, int>(8, 4);
                default:
                    return new Tuple<int, int>(4, 2);
            }
        }

        protected override void PostApplyConfigNodes()
        {
            if (ObjectList.Count > 0)
            {
                temporalUpscaling = ObjectList[0].TemporalUpscaling;

                nonTiling3DNoise = ObjectList[0].NonTiling3DNoise;
                renderCloudsInReflectionProbes = ObjectList[0].RenderCloudsInReflectionProbes;
                mapViewCloudFade = ObjectList[0].MapViewCloudFade;

                screenShotModeDenoisingIterations = ObjectList[0].ScreenShotModeDenoisingIterations;

                lightVolumeSettings = ObjectList[0].LightVolumeSettings;

                ambientVolume = ObjectList[0].AmbientVolume;
                lightningVolume = ObjectList[0].LightningVolume;

                DeferredRaymarchedVolumetricCloudsRenderer.ReinitAll();

                CloudsManager.Instance.Apply();
            }
        }
    }
}
