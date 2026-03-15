using Utils;
using UnityEngine;
using UnityEngine.Rendering;
using ShaderLoader;

namespace Atmosphere
{

    class NoiseGenerator
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
                NoiseMaterial.SetFloat("_PerlinContrast", 1f);
            }

            if (settings.GetNoiseMode() == NoiseMode.Mix || settings.GetNoiseMode() == NoiseMode.WorleyOnly)
            { 
                NoiseMaterial.SetVector("_WorleyParams", settings.WorleyNoiseSettings.GetParams());
                NoiseMaterial.SetFloat("_WorleySpherical", settings.WorleyNoiseSettings.Spherical);
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
            GameObject.Destroy(go.GetComponent<Collider>());
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

            Generate3DTextureMips(RT);

            RenderTexture.active = active;
        }

        public static void RenderCurlNoiseToTexture(RenderTexture RT, CurlNoise curlNoise)
        {
            NoiseMaterial.SetVector("_PerlinParams", new Vector4(curlNoise.Octaves, curlNoise.Periods, 0.5f, 2f)); // octaves, periods, persistence, lacunarity
            NoiseMaterial.SetFloat("_PerlinLift", 0f);
            NoiseMaterial.SetFloat("_PerlinContrast", curlNoise.Contrast);

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

            Generate3DTextureMips(RT);

            RenderTexture.active = active;
        }

        // The built-in mip generation functions don't work correctly for 3d textures on all platforms
        static void Generate3DTextureMips(RenderTexture RT)
        {
            var scratchRT = RenderTextureUtils.CreateRenderTexture(RT.width, RT.height, RT.format, true, FilterMode.Bilinear, RT.dimension, RT.volumeDepth);
            scratchRT.name = "scratchRT";

            CommandBuffer cb = new CommandBuffer();
            cb.name = "Mips CB";

            var go = GameObject.CreatePrimitive(PrimitiveType.Quad);
            var quadMesh = Mesh.Instantiate(go.GetComponent<MeshFilter>().sharedMesh);
            GameObject.Destroy(go.GetComponent<Collider>());
            GameObject.Destroy(go);

            Vector3 currentMipLevelDimensions = new Vector3(RT.width, RT.height, (RT.dimension == TextureDimension.Tex3D) ? RT.volumeDepth : 1);
            Vector3 previousMipLevelDimensions = currentMipLevelDimensions;

            for (int currentMipLevelToRead = 0; currentMipLevelToRead < scratchRT.mipmapCount - 1; currentMipLevelToRead++)
            {
                previousMipLevelDimensions = currentMipLevelDimensions;
                currentMipLevelDimensions = new Vector3((int)(currentMipLevelDimensions.x / 2f),
                                                        (int)(currentMipLevelDimensions.y / 2f),
                                                        (int)(currentMipLevelDimensions.z / 2f));

                cb.SetGlobalVector("previousNoiseMipLevelDimensions", previousMipLevelDimensions);
                cb.SetGlobalVector("currentNoiseMipLevelDimensions", currentMipLevelDimensions);

                cb.SetGlobalTexture("previousNoiseTexture", RT);
                cb.SetGlobalInt("currentMipLevelToRead", currentMipLevelToRead);

                // Iterate over all the slices of the current mip level
                for (int i = 0; i < currentMipLevelDimensions.z; i++)
                {
                    float zUV = (i + 0.5f) / currentMipLevelDimensions.z;
                    cb.SetGlobalFloat("_Slice", zUV);

                    cb.SetRenderTarget(scratchRT, currentMipLevelToRead + 1, CubemapFace.Unknown, i);
                    cb.DrawMesh(quadMesh, Matrix4x4.identity, noiseMaterial, 0, 4);
                }

                // When done copy back results to the original texture, we'll see if this works

                // This doesn't work on all platforms and is probably the source of the original issue
                //cb.CopyTexture(scratchRT, 0, currentMipLevelToRead + 1, RT, 0, currentMipLevelToRead + 1);

                cb.SetGlobalTexture("mippedNoiseTexture", scratchRT);
                cb.SetGlobalInt("currentMipLevelToCopy", currentMipLevelToRead + 1);

                for (int i = 0; i < currentMipLevelDimensions.z; i++)
                {
                    float zUV = (i + 0.5f) / currentMipLevelDimensions.z;
                    cb.SetGlobalFloat("_Slice", zUV);

                    cb.SetRenderTarget(RT, currentMipLevelToRead + 1, CubemapFace.Unknown, i);
                    cb.DrawMesh(quadMesh, Matrix4x4.identity, noiseMaterial, 0, 5);
                }
            }

            Graphics.ExecuteCommandBuffer(cb);
            cb.Release();

            scratchRT.Release();
            GameObject.Destroy(scratchRT);
            GameObject.Destroy(quadMesh);
        }
    }
}
