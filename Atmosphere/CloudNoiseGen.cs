using Utils;
using UnityEngine;
using UnityEngine.Rendering;
using ShaderLoader;

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
        float octaves = 0f;
        [ConfigItem]
        float periods = 0f;
        [ConfigItem]
        float brightness = 0f;
        [ConfigItem]
        float contrast = 0f;
        [ConfigItem]
        float lift = 0f;

        public float Octaves { get => octaves; }
        public float Periods { get => periods; }
        public float Brightness { get => brightness; }
        public float Contrast { get => contrast; }
        public float Lift { get => lift; }

        public NoiseSettings()
        {

        }

        public NoiseSettings(float octaves, float periods, float brightness, float contrast, float lift)
        {
            this.octaves = octaves;
            this.periods = periods;
            this.brightness = brightness;
            this.contrast = contrast;
            this.lift = lift;
        }

        public Vector4 GetParams()
        {
            return new Vector4(octaves, periods, brightness, contrast);
        }
    }

    [System.Serializable]
    public class NoiseWrapper
    {
        [ConfigItem, Optional]
        NoiseSettings worley;

        [ConfigItem, Optional]
        NoiseSettings perlin;

        public NoiseSettings PerlinNoiseSettings { get => perlin; }
        public NoiseSettings WorleyNoiseSettings { get => worley; }

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

    class CloudNoiseGen
    {
        private static Material noiseMaterial = null;

        private static Material NoiseMaterial
        {
            get
            {
                if (noiseMaterial == null)
                {
                    noiseMaterial =  new Material(ShaderLoaderClass.FindShader("EVE/CloudNoiseGen"));
                }
                return noiseMaterial;
            }
        }


        public static void RenderNoiseToTexture(RenderTexture RT, NoiseWrapper settings)
        {
            if (settings.GetNoiseMode() == NoiseMode.Mix || settings.GetNoiseMode() == NoiseMode.PerlinOnly)
            { 
                NoiseMaterial.SetVector("_PerlinParams", settings.PerlinNoiseSettings.GetParams());
                NoiseMaterial.SetFloat("_PerlinLift", settings.PerlinNoiseSettings.Lift);
            }

            if (settings.GetNoiseMode() == NoiseMode.Mix || settings.GetNoiseMode() == NoiseMode.WorleyOnly)
            { 
                NoiseMaterial.SetVector("_WorleyParams", settings.WorleyNoiseSettings.GetParams());
                NoiseMaterial.SetFloat("_WorleyLift", settings.WorleyNoiseSettings.Lift);
            }

            NoiseMaterial.SetInt("_Mode", (int)settings.GetNoiseMode());
            NoiseMaterial.SetInt("_TargetChannel", 0);
            NoiseMaterial.SetVector("_Resolution", new Vector3(RT.width, RT.height, (RT.dimension == TextureDimension.Tex3D) ? RT.volumeDepth : 1f));

            var active = RenderTexture.active;

            if (RT.dimension == TextureDimension.Tex3D)
            {
                for (int i = 0; i < RT.volumeDepth; i++)
                {
                    NoiseMaterial.SetFloat("_Slice", (float)(i) / (float)(RT.volumeDepth));
                    Graphics.Blit(null, RT, NoiseMaterial, 0, i);
                }
            }
            else
            {
                Graphics.Blit(null, RT, NoiseMaterial, 0);
            }

            RT.GenerateMips();

            RenderTexture.active = active;
        }

        public static void RenderCurlNoiseToTexture(RenderTexture RT, NoiseSettings settings)
        {
            NoiseMaterial.SetVector("_PerlinParams", settings.GetParams());
            NoiseMaterial.SetFloat("_PerlinLift", 0f);

            NoiseMaterial.SetVector("_Resolution", new Vector3(RT.width, RT.height, (RT.dimension == TextureDimension.Tex3D) ? RT.volumeDepth : 1f));

            var active = RenderTexture.active;

            if (RT.dimension == TextureDimension.Tex3D)
            {
                for (int i = 0; i < RT.volumeDepth; i++)
                {
                    NoiseMaterial.SetFloat("_Slice", (float)(i) / (float)(RT.volumeDepth));
                    Graphics.Blit(null, RT, NoiseMaterial, 1, i);
                }
            }
            else
            {
                Graphics.Blit(null, RT, NoiseMaterial, 1);
            }

            RT.GenerateMips();

            RenderTexture.active = active;
        }
    }
}
