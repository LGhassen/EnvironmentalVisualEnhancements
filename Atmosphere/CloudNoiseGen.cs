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

        public Vector4 GetParams()
        {
            return new Vector4(octaves, periods, brightness, contrast);
        }
    }

    [System.Serializable]
    public class CurlNoiseSettings
    {
        [ConfigItem]
        float octaves = 0f;
        [ConfigItem]
        float periods = 0f;
        [ConfigItem]
        bool smooth = false;

        public float Octaves { get => octaves; }
        public float Periods { get => periods; }

        public bool Smooth { get => smooth; }

        public Vector4 GetParams()
        {
            return new Vector4(octaves, periods, 1f, 1f);
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

        public static void RenderCurlNoiseToTexture(RenderTexture RT, CurlNoiseSettings settings)
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

        /*public static Texture2D CompressSingleChannelTextureToBC4(Texture2D input, bool mipMaps)
        {
            //create texture2D of the same size but with ARGB type so we can use the built-in DXT5 compression
            Texture2D tex = new Texture2D(input.width, input.height, TextureFormat.ARGB32, mipMaps);

            for (int x = 0; x < input.width; x++)
            {
                for (int y = 0; y < input.height; y++)
                {
                    Color col = input.GetPixel(x, y);
                    col.a = col.r;  //we want the alpha channel, write to the alpha channel from red only channel
                    tex.SetPixel(x, y, col);
                }
            }

            tex.Apply(mipMaps);

            //now compress tex to DXT5
            tex.Compress(true);

            //now copy all the alpha bytes into separate BC4 texture
            Texture2D texCompressed = new Texture2D(input.width, input.height, TextureFormat.BC4, true);
            texCompressed.filterMode = FilterMode.Bilinear;
            texCompressed.wrapMode = TextureWrapMode.Repeat;

            byte[] alphaChannelArray = texCompressed.GetRawTextureData();
            byte[] allChannelArray = tex.GetRawTextureData();

            for (int i = 0; i < alphaChannelArray.Length / 8; i++) //number of blocks
            {
                for (int j = 0; j < 8; j++) //bytes within a block
                {
                    alphaChannelArray[i * 8 + j] = allChannelArray[i * 16 + j]; //take only the first 8 bytes of every 16 bytes for the alpha/BC4 channel
                                                                                //this doesn't seem to work with a 128*8192 texture?
                }
            }

            texCompressed.LoadRawTextureData(alphaChannelArray);
            texCompressed.Apply();

            Destroy(tex);

            return texCompressed;
        }

        public static Texture2D CompressSingleChannelRenderTextureToBC4(RenderTexture inputRT, bool mipMaps)
        {
            Texture2D tex = new Texture2D(inputRT.width, inputRT.height, TextureFormat.R8, false);

            RenderTexture.active = inputRT;
            tex.ReadPixels(new Rect(0, 0, inputRT.width, inputRT.height), 0, 0);
            tex.Apply(false);

            return CompressSingleChannelTextureToBC4(tex, mipMaps);
        }
        */
    }
}
