﻿using EVEManager;
using Utils;

namespace Atmosphere
{
    enum TemporalUpscaling
    {
        // off,
        x1,
        x2,
        x4,
        x8,
        x16,
        x32,
    }

    enum ReprojectionQuality
    {
        fast,
        accurate
    }

    [ConfigName("name")]
    public class RaymarchedCloudsQuality : IEVEObject 
    {
        [ConfigItem]
        TemporalUpscaling temporalUpscaling = TemporalUpscaling.x8;

        //[ConfigItem]
        ReprojectionQuality reprojectionQuality = ReprojectionQuality.accurate;

        [ConfigItem]
        bool nonTiling3DNoise = true;

        internal TemporalUpscaling TemporalUpscaling { get => temporalUpscaling; }
        internal ReprojectionQuality ReprojectionQuality { get => reprojectionQuality; }
        internal bool NonTiling3DNoise { get => nonTiling3DNoise; }

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