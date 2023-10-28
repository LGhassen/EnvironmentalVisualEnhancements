using EVEManager;
using System;
using UnityEngine;

namespace Atmosphere
{
    public class RaymarchedCloudsQualityManager : GenericEVEManager<RaymarchedCloudsQuality>
    {
        static TemporalUpscaling temporalUpscaling = TemporalUpscaling.x8;

        public override int LoadOrder { get { return 120; } }

        public override int DisplayOrder { get { return 92; } }

        static bool nonTiling3DNoise = true;

        static bool useOrbitMode = true;

        public override ObjectType objectType { get { return ObjectType.STATIC; } }
        public override String configName { get { return "EVE_RAYMARCHED_CLOUDS_QUALITY"; } }

        internal static TemporalUpscaling TemporalUpscaling { get => temporalUpscaling; }

        internal static bool NonTiling3DNoise { get => nonTiling3DNoise; }

        internal static bool UseOrbitMode { get => useOrbitMode; }

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
                case TemporalUpscaling.x5:
                    return new Tuple<int, int>(5, 1);
                case TemporalUpscaling.x6:
                    return new Tuple<int, int>(3, 2);
                case TemporalUpscaling.x8:
                    return new Tuple<int, int>(4, 2);
                case TemporalUpscaling.x9:
                    return new Tuple<int, int>(3, 3);
                case TemporalUpscaling.x10:
                    return new Tuple<int, int>(5, 2);
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

                useOrbitMode = ObjectList[0].UseOrbitMode;

                DeferredRaymarchedVolumetricCloudsRenderer.ReinitAll();

                CloudsManager.Instance.Apply();
            }
        }
    }
}