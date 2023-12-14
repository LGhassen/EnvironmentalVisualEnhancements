using UnityEngine;
using System.Linq;
using ShaderLoader;
using Utils;
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Collections;

namespace Atmosphere
{
    [KSPAddon(KSPAddon.Startup.Instantly, true)]
    public class SDFTool : MonoBehaviour
    {
        private static SDFTool instance;

        public SDFTool()
        {
            if (instance == null)
            {
                Debug.Log("SDFUtils instance created");
                instance = this;
            }
            else
            {
                throw new UnityException("Attempted double instance!");
            }
        }

        public void Start()
        {
            DontDestroyOnLoad(this);
        }

        private static Shader sdfShader;

        private static Shader SdfShader
        {
            get
            {
                if (sdfShader == null) sdfShader = ShaderLoaderClass.FindShader("EVE/SDFGenerate");
                return sdfShader;
            }
        }

        private static bool sdfGenerationRunning = false;

        IEnumerator GenerateAndSaveSDFCoroutine(RenderTexture coverageMap, string path)
        {
            sdfGenerationRunning = true;

            ScreenMessages.PostScreenMessage("Generating SDF");

            int width = coverageMap.width;
            int height = coverageMap.height;

            var flipRT = RenderTextureUtils.CreateRenderTexture(width, height, RenderTextureFormat.RGHalf, false, FilterMode.Point, coverageMap.dimension);
            var flopRT = RenderTextureUtils.CreateRenderTexture(width, height, RenderTextureFormat.RGHalf, false, FilterMode.Point, coverageMap.dimension);

            Material material = new Material(SdfShader);

            bool cubemapMode = coverageMap.dimension == UnityEngine.Rendering.TextureDimension.Cube;

            if (cubemapMode)
            {
                material.EnableKeyword("CUBEMAP_ON");
                material.DisableKeyword("CUBEMAP_OFF");
            }
            else
            {
                material.DisableKeyword("CUBEMAP_ON");
                material.EnableKeyword("CUBEMAP_OFF");
            }

            // Initialization pass
            material.SetTexture("inputImage", coverageMap);

            BlitToTarget(material, cubemapMode, flipRT, 0);

            yield return new WaitForFixedUpdate();

            // Iterative passes
            bool renderToFlip = false;

            int iterations = (int)Mathf.Ceil(Mathf.Log(Mathf.Max(width, height), 2f));
            if (cubemapMode) iterations += 20; // kind of a hack but iterations are cheap and it works

            int percentDone = 0;

            for (int i = 0; i < iterations; i++)
            {
                RenderTexture.active = null;

                material.SetFloat("iteration", (float)i);
                material.SetTexture("previousResult", renderToFlip ? flopRT : flipRT);

                BlitToTarget(material, cubemapMode, renderToFlip ? flipRT : flopRT, 1);

                renderToFlip = !renderToFlip;

                int currentPercentDone = i * 100 / iterations;

                if (currentPercentDone - percentDone >= 20)
                {
                    percentDone = currentPercentDone;
                    ScreenMessages.PostScreenMessage("Generating SDF "+percentDone.ToString()+"%");
                }

                yield return new WaitForFixedUpdate();
            }

            // Finalization pass
            var resultRT = renderToFlip ? flipRT : flopRT;

            material.SetTexture("inputImage", coverageMap);
            material.SetTexture("previousResult", renderToFlip ? flopRT : flipRT);

            BlitToTarget(material, cubemapMode, resultRT, 2);

            yield return new WaitForFixedUpdate();

            var downscaledResult = RenderTextureUtils.CreateRenderTexture(width / 4, height / 4, RenderTextureFormat.R16, false, FilterMode.Point, coverageMap.dimension);

            // Downscaling pass
            material.SetVector("screenParams", new Vector2(width / 4, height / 4));

            if (!cubemapMode)
            {
                material.SetTexture("scalarImage", resultRT);
                Graphics.Blit(null, downscaledResult, material, 3);
                yield return new WaitForFixedUpdate();
            }
            else
            {
                // For cubemaps this needs to be done face by face
                var faceRT = RenderTextureUtils.CreateRenderTexture(width, height, RenderTextureFormat.RGHalf, false, FilterMode.Point, UnityEngine.Rendering.TextureDimension.Tex2D);

                for (int cubemapFace = 0; cubemapFace < 6; cubemapFace++)
                {
                    // here we need to copy a specific face and set it up as input
                    Graphics.CopyTexture(resultRT, cubemapFace, faceRT, 0);

                    material.SetTexture("scalarImage", faceRT);
                    RenderTextureUtils.BlitToCubemapFace(downscaledResult, material, cubemapFace, 3);
                    yield return new WaitForFixedUpdate();
                }

                faceRT.Release();
            }

            flipRT.Release();
            flopRT.Release();

            SaveSDFToFile(downscaledResult, path);

            downscaledResult.Release();

            Debug.Log("Saved to " + path);
            ScreenMessages.PostScreenMessage("Saved to " + path);

            sdfGenerationRunning = false;
        }

        public static void GenerateAndSaveSDFInBackground(RenderTexture coverageMap, string path)
        {
            if (!sdfGenerationRunning)
            {
                instance.StartCoroutine(instance.GenerateAndSaveSDFCoroutine(coverageMap, path));
            }
        }

        private static void BlitToTarget(Material material, bool cubemapMode, RenderTexture targetRT, int pass)
        {
            if (!cubemapMode)
            {
                Graphics.Blit(null, targetRT, material, pass);
            }
            else
            {
                for (int cubemapFace = 0; cubemapFace < 6; cubemapFace++)
                {
                    material.SetInt("cubemapFace", cubemapFace); // TODO: handle these in the shader, similarly to paint mode
                    RenderTextureUtils.BlitToCubemapFace(targetRT, material, cubemapFace, pass);
                }
            }
        }

        public static void SaveSDFToFile(RenderTexture sdf, string path)
        {
            byte[] byteArray;

            byteArray = GetByteArray(sdf);

            byteArray = AddHeader(byteArray, new SDFHeader(sdf.width, sdf.height, 0, sdf.dimension == UnityEngine.Rendering.TextureDimension.Cube, TextureFormat.R16, 1));

            System.IO.File.WriteAllBytes(path, byteArray);
        }

        private static byte[] GetByteArray(RenderTexture sdf)
        {
            byte[] byteArray = null;

            if (sdf.dimension != UnityEngine.Rendering.TextureDimension.Cube)
            {
                Texture2D temp = new Texture2D(sdf.width, sdf.height, TextureFormat.R16, false, false);

                RenderTexture.active = sdf;
                temp.ReadPixels(new Rect(0, 0, sdf.width, sdf.height), 0, 0);
                temp.Apply();
                RenderTexture.active = null;

                byteArray = temp.GetRawTextureData();
            }
            else
            {
                // For cubemap need to copy every single RT face to a separate RT, then read to a 2D texture separately then add the total bytes
                RenderTexture cubemapFaceRT = new RenderTexture(sdf.width, sdf.height, 0, sdf.format, 0);
                cubemapFaceRT.filterMode = FilterMode.Bilinear;
                cubemapFaceRT.wrapMode = TextureWrapMode.Clamp;
                cubemapFaceRT.useMipMap = false;
                cubemapFaceRT.Create();

                Texture2D temp = new Texture2D(sdf.width, sdf.height, TextureFormat.R16, false, false);

                for (int cubemapFace = 0; cubemapFace < 6; cubemapFace++)
                {
                    Graphics.CopyTexture(sdf, cubemapFace, cubemapFaceRT, 0);

                    RenderTexture.active = cubemapFaceRT;
                    temp.ReadPixels(new Rect(0, 0, cubemapFaceRT.width, cubemapFaceRT.height), 0, 0);
                    temp.Apply();
                    RenderTexture.active = null;

                    var faceArray = temp.GetRawTextureData();

                    if (byteArray == null)
                    {
                        byteArray = new byte[6 * faceArray.Length];
                    }

                    Buffer.BlockCopy(faceArray, 0, byteArray, cubemapFace * faceArray.Length, faceArray.Length);
                }

                cubemapFaceRT.Release();
            }

            return byteArray;
        }

        public static Texture LoadSDFFromGameDataFile(string path)
        {
            var gameDataPath = System.IO.Path.Combine(KSPUtil.ApplicationRootPath, "GameData");
            path = System.IO.Path.Combine(gameDataPath, path);

            byte[] byteArray =  System.IO.File.ReadAllBytes(path);

            byte[] imageByteArray = GetArrayWithoutHeader(byteArray, out SDFHeader sdfHeader);
            byteArray = null;

            if (!sdfHeader.CubeMap)
            {
                Texture2D sdf2d = new Texture2D(sdfHeader.Width, sdfHeader.Height, sdfHeader.Format, false, false);
                sdf2d.wrapMode = TextureWrapMode.Clamp;
                sdf2d.filterMode = FilterMode.Bilinear;
                sdf2d.LoadRawTextureData(imageByteArray);
                sdf2d.Apply();

                return sdf2d;
            }
            else
            {
                Cubemap sdfCubemap = new Cubemap(sdfHeader.Width, sdfHeader.Format, false);
                sdfCubemap.filterMode = FilterMode.Bilinear;

                byte[] faceByteArray = new byte[imageByteArray.Length / 6];

                for (int cubemapFace = 0; cubemapFace < 6; cubemapFace++)
                {
                    Buffer.BlockCopy(imageByteArray, cubemapFace * faceByteArray.Length, faceByteArray, 0, faceByteArray.Length);
                    sdfCubemap.SetPixelData(faceByteArray, 0, (CubemapFace)cubemapFace, 0);
                }

                sdfCubemap.Apply();

                return sdfCubemap;
            }
        }

        public struct SDFHeader
        {
            public int Width;
            public int Height;
            public int VolumeDepth;
            public bool CubeMap;
            public TextureFormat Format;
            public int Version;

            public int Reserved0;
            public int Reserved1;
            public int Reserved2;
            public int Reserved3;

            public SDFHeader(int width, int height, int volumeDepth, bool cubeMap, TextureFormat format, int version)
            {
                Width = width;
                Height = height;
                VolumeDepth = volumeDepth;
                CubeMap = cubeMap;
                Format = format;
                Version = version;

                Reserved0 = 0;
                Reserved1 = 0;
                Reserved2 = 0;
                Reserved3 = 0;
            }
        }


        private static byte[] StructToBytes<T>(T str) where T : struct
        {
            int size = Marshal.SizeOf(str);
            byte[] bytes = new byte[size];

            IntPtr ptr = IntPtr.Zero;
            try
            {
                ptr = Marshal.AllocHGlobal(size);
                Marshal.StructureToPtr(str, ptr, false);
                Marshal.Copy(ptr, bytes, 0, size);
            }
            finally
            {
                Marshal.FreeHGlobal(ptr);
            }

            return bytes;
        }

        // Helper method to convert a byte array to a structure
        private static T BytesToStruct<T>(byte[] bytes) where T : struct
        {
            T structure;

            IntPtr ptr = IntPtr.Zero;
            try
            {
                ptr = Marshal.AllocHGlobal(bytes.Length);
                Marshal.Copy(bytes, 0, ptr, bytes.Length);
                structure = (T)Marshal.PtrToStructure(ptr, typeof(T));
            }
            finally
            {
                Marshal.FreeHGlobal(ptr);
            }

            return structure;
        }

        public static byte[] AddHeader(byte[] byteArray, SDFHeader header)
        {
            // Convert header to byte array
            byte[] headerBytes = StructToBytes(header);

            // Combine header and original array
            byte[] newArray = new byte[headerBytes.Length + byteArray.Length];
            Buffer.BlockCopy(headerBytes, 0, newArray, 0, headerBytes.Length);
            Buffer.BlockCopy(byteArray, 0, newArray, headerBytes.Length, byteArray.Length);

            return newArray;
        }

        public static byte[] GetArrayWithoutHeader(byte[] withHeader, out SDFHeader header)
        {
            // Read header bytes
            byte[] headerBytes = new byte[Marshal.SizeOf(typeof(SDFHeader))];
            Buffer.BlockCopy(withHeader, 0, headerBytes, 0, headerBytes.Length);

            // Convert header bytes to CustomHeader structure
            header = BytesToStruct<SDFHeader>(headerBytes);

            // Extract original array
            byte[] originalArray = new byte[withHeader.Length - headerBytes.Length];
            Buffer.BlockCopy(withHeader, headerBytes.Length, originalArray, 0, originalArray.Length);

            return originalArray;
        }
    }
}