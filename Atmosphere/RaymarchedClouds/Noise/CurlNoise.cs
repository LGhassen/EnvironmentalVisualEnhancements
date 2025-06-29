using Utils;
using UnityEngine;
using UnityEngine.Rendering;
using ShaderLoader;

namespace Atmosphere
{

    [System.Serializable]
    public class CurlNoise
    {
        [ConfigItem]
        float octaves = 8f;

        [ConfigItem]
        float periods = 1f;

        [ConfigItem]
        float contrast = 1f;

        [ConfigItem]
        bool smooth = false;

        [ConfigItem]
        float tiling = 1f;

        [ConfigItem]
        float strength = 1f;

        public float Octaves { get => octaves; }
        public float Periods { get => periods; }

        public float Contrast { get => contrast; }

        public bool Smooth { get => smooth; }
        public float Tiling { get => tiling; }
        public float Strength { get => strength; }

    }
}
