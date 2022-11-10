using EVEManager;
using System;
using UnityEngine;

namespace Atmosphere
{
    public class RaymarchedCloudsQualityManager : GenericEVEManager<RaymarchedCloudsQuality>
    {
        static TemporalUpscaling temporalUpscaling = TemporalUpscaling.x8;
        static ReprojectionQuality reprojectionQuality = ReprojectionQuality.accurate;

        public override ObjectType objectType { get { return ObjectType.STATIC; } }
        public override String configName { get { return "EVE_RAYMARCHED_CLOUDS_QUALITY"; } }

        internal static TemporalUpscaling TemporalUpscaling { get => temporalUpscaling; }
        internal static ReprojectionQuality ReprojectionQuality { get => reprojectionQuality; }

        internal static Tuple<int, int> GetReprojectionFactors()
        {
            switch (temporalUpscaling)
            {
                // case TemporalUpscaling.off:
                //    return new Tuple<int, int>(1, 1);
                case TemporalUpscaling.x1:
                    return new Tuple<int, int>(1, 1);
                case TemporalUpscaling.x2:
                    return new Tuple<int, int>(2, 1);
                case TemporalUpscaling.x4:
                    return new Tuple<int, int>(2, 2);
                case TemporalUpscaling.x8:
                    return new Tuple<int, int>(4, 2);
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
                reprojectionQuality = ObjectList[0].ReprojectionQuality;

                DeferredRaymarchedVolumetricCloudsRenderer.ReinitAll();
            }
        }
    }
}