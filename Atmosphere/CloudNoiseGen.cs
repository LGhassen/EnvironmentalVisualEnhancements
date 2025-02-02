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
        float persistence = 0f;
        [ConfigItem]
        float lacunarity = 0f;

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
            }

            if (settings.GetNoiseMode() == NoiseMode.Mix || settings.GetNoiseMode() == NoiseMode.WorleyOnly)
            { 
                NoiseMaterial.SetVector("_WorleyParams", settings.WorleyNoiseSettings.GetParams());
            }

            NoiseMaterial.SetInt("_Mode", (int)settings.GetNoiseMode());

            var active = RenderTexture.active;

            // Create two float textures to render the noise to then normalize the values by finding the min and max

            var halfRTFlip = RenderTextureUtils.CreateRenderTexture(RT.width, RT.height, RenderTextureFormat.RGFloat, true,
                            FilterMode.Bilinear, RT.dimension, (RT.dimension == TextureDimension.Tex3D) ? RT.volumeDepth : 1);
            halfRTFlip.name = "halfRTFlip";

            var halfRTFlop = RenderTextureUtils.CreateRenderTexture(RT.width, RT.height, RenderTextureFormat.RGFloat, true,
                            FilterMode.Bilinear, RT.dimension, (RT.dimension == TextureDimension.Tex3D) ? RT.volumeDepth : 1);
            halfRTFlop.name = "halfRTFlop";

            // Start by rendering normally to the first texture
            if (RT.dimension == TextureDimension.Tex3D)
            {
                for (int i = 0; i < RT.volumeDepth; i++)
                {
                    float zUV = (i + 0.5f) / RT.volumeDepth;
                    noiseMaterial.SetFloat("_Slice", zUV);

                    Graphics.Blit(null, halfRTFlip, noiseMaterial, 0, i);
                }
            }
            else
            {
                Graphics.Blit(null, halfRTFlip, noiseMaterial, 0);
            }

            // Compute min and max values by doing 4 elements at once and writing to mip levels
            // Has to be a CB to write to mips
            CommandBuffer cb = new CommandBuffer();
            cb.name = "Normalize noise texture CB";
            var go = GameObject.CreatePrimitive(PrimitiveType.Quad);
            var quadMesh = Mesh.Instantiate(go.GetComponent<MeshFilter>().sharedMesh);
            GameObject.Destroy(go);

            bool renderToFlip = false;

            Vector3 currentMipLevelDimensions = new Vector3(RT.width, RT.height, (RT.dimension == TextureDimension.Tex3D) ? RT.volumeDepth : 1);
            Vector3 previousMipLevelDimensions = currentMipLevelDimensions;

            // First this will find the min and max values and write min to R and max to G of the highest mip level
            for (int currentMipLevelToRead = 0; currentMipLevelToRead < halfRTFlip.mipmapCount - 1; currentMipLevelToRead++)
            {
                previousMipLevelDimensions = currentMipLevelDimensions;
                currentMipLevelDimensions = new Vector3((int)(currentMipLevelDimensions.x / 2f),
                                                        (int)(currentMipLevelDimensions.y / 2f),
                                                        (int)(currentMipLevelDimensions.z / 2f));

                cb.SetGlobalVector("previousNoiseMipLevelDimensions", previousMipLevelDimensions);
                cb.SetGlobalVector("currentNoiseMipLevelDimensions", currentMipLevelDimensions);

                cb.SetGlobalTexture("previousNoiseTexture", renderToFlip ? halfRTFlop : halfRTFlip);
                cb.SetGlobalInt("currentMipLevelToRead", currentMipLevelToRead);

                // Iterate over all the slices if 3D tex
                if (RT.dimension == TextureDimension.Tex3D)
                {
                    for (int i = 0; i < currentMipLevelDimensions.z; i++)
                    {
                        float zUV = (i + 0.5f) / currentMipLevelDimensions.z;
                        cb.SetGlobalFloat("_Slice", zUV);

                        cb.SetRenderTarget(renderToFlip ? halfRTFlip : halfRTFlop, currentMipLevelToRead + 1, CubemapFace.Unknown, i);
                        cb.DrawMesh(quadMesh, Matrix4x4.identity, noiseMaterial, 0, 2);
                    }
                }
                else
                {
                    cb.SetRenderTarget(renderToFlip ? halfRTFlip : halfRTFlop, currentMipLevelToRead + 1);
                    cb.DrawMesh(quadMesh, Matrix4x4.identity, noiseMaterial, 0, 2);
                }

                renderToFlip = !renderToFlip;
            }

            Graphics.ExecuteCommandBuffer(cb);
            cb.Release();

            // Once we have the min and max, perform the normalization and write to the 8-bit RT
            noiseMaterial.SetTexture("NonNormalizedNoiseTexture", halfRTFlip);
            noiseMaterial.SetTexture("MinMaxNoiseTexture", renderToFlip ? halfRTFlop : halfRTFlip);
            noiseMaterial.SetInt("MinMaxMipLevel", halfRTFlip.mipmapCount - 1);

            if (RT.dimension == TextureDimension.Tex3D)
            {
                for (int i = 0; i < RT.volumeDepth; i++)
                {
                    float zUV = (i + 0.5f) / RT.volumeDepth;
                    noiseMaterial.SetFloat("_Slice", zUV);

                    Graphics.Blit(null, RT, noiseMaterial, 3, i);
                }
            }
            else
            {
                Graphics.Blit(null, RT, noiseMaterial, 3);
            }

            // Then destroy the old textures
            halfRTFlip.Release();
            halfRTFlop.Release();
            GameObject.Destroy(halfRTFlip);
            GameObject.Destroy(halfRTFlop);
            GameObject.Destroy(quadMesh);

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
                    float zUV = (i + 0.5f) / RT.volumeDepth;
                    NoiseMaterial.SetFloat("_Slice", zUV);
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
