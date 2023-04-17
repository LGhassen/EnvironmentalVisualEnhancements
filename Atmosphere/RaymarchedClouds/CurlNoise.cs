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
        float octaves = 0f;

        [ConfigItem]
        float periods = 0f;

        [ConfigItem]
        bool smooth = false;

        [ConfigItem]
        float tiling = 1f;

        [ConfigItem]
        float strength = 1f;

        public float Octaves { get => octaves; }
        public float Periods { get => periods; }

        public bool Smooth { get => smooth; }
        public float Tiling { get => tiling; }
        public float Strength { get => strength; }

        public NoiseSettings ToNoiseSettings()
        {
            return new NoiseSettings(octaves, periods, 1f, 1f, 0f);
        }
    }
}
