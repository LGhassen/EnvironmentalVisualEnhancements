using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using Utils;

namespace Atmosphere
{
    [System.Serializable]
    public enum NoiseMode
    {
        Mix = 0,
        PerlinOnly = 1,
        WorleyOnly = 2,
        None = 4,
    }

    [System.Serializable]
    public class NoiseSettings
    {
        [ConfigItem]
        float octaves = 8f;
        [ConfigItem]
        float periods = 1f;

        [ConfigItem]
        float persistence = 0.57f;
        [ConfigItem]
        float lacunarity = 2f;

        public float Octaves { get => octaves; }
        public float Periods { get => periods; }

        public float Persistence { get => persistence; }
        public float Lacunarity { get => lacunarity; }

        public NoiseSettings()
        {

        }

        public NoiseSettings(float octaves, float periods, float persistence, float lacunarity)
        {
            this.octaves = octaves;
            this.periods = periods;
            this.persistence = persistence;
            this.lacunarity = lacunarity;
        }

        public Vector4 GetParams()
        {
            return new Vector4(octaves, periods, persistence, lacunarity);
        }
    }

    [System.Serializable]
    public class WorleyNoiseSettings
    {
        [ConfigItem]
        float octaves = 8f;
        [ConfigItem]
        float periods = 1f;

        [ConfigItem]
        float persistence = 0.57f;
        [ConfigItem]
        float lacunarity = 2f;

        public float Octaves { get => octaves; }
        public float Periods { get => periods; }

        public float Persistence { get => persistence; }
        public float Lacunarity { get => lacunarity; }

        public WorleyNoiseSettings()
        {

        }

        public WorleyNoiseSettings(float octaves, float periods, float persistence, float lacunarity)
        {
            this.octaves = octaves;
            this.periods = periods;
            this.persistence = persistence;
            this.lacunarity = lacunarity;
        }

        public Vector4 GetParams()
        {
            return new Vector4(octaves, periods, persistence, lacunarity);
        }

        [ConfigItem]
        float spherical = 0f;

        public float Spherical { get => spherical; }
    }

    [System.Serializable]
    public class NoiseWrapper
    {
        [ConfigItem]
        float erosionDepth = 0.7f;

        [ConfigItem, Optional]
        WorleyNoiseSettings worley;

        [ConfigItem, Optional]
        NoiseSettings perlin;

        public NoiseSettings PerlinNoiseSettings { get => perlin; }
        public WorleyNoiseSettings WorleyNoiseSettings { get => worley; }

        public float ErosionDepth { get => erosionDepth; }

        public NoiseMode GetNoiseMode()
        {
            if (worley != null && perlin != null)
                return NoiseMode.Mix;
            else if (worley != null)
                return NoiseMode.WorleyOnly;
            else if (perlin != null)
                return NoiseMode.PerlinOnly;
            else
                return NoiseMode.None;
        }
    }
}
