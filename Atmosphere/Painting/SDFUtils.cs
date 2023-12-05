using UnityEngine;
using System.Linq;
using ShaderLoader;
using Utils;
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Collections.Generic;

namespace Atmosphere
{
    public static class SDFUtils
    {

        private static Shader sdfShader;

        private static Shader SdfShader
        {
            get
            {
                if (sdfShader == null) sdfShader = ShaderLoaderClass.FindShader("EVE/SDFGenerate");
                return sdfShader;
            }
        }

        // TODO: think about cubemap support
        public static RenderTexture GenerateSDF(RenderTexture coverageMap)
        {
            int width = coverageMap.width;
            int height = coverageMap.height;

            Material material = new Material(SdfShader);

            var flipRT = new RenderTexture(width, height, 0, RenderTextureFormat.RGFloat);
            var flopRT = new RenderTexture(width, height, 0, RenderTextureFormat.RGFloat);

            flipRT.useMipMap = false;
            flopRT.useMipMap = false;

            flipRT.filterMode = FilterMode.Point;
            flopRT.filterMode = FilterMode.Point;

            flipRT.Create();
            flopRT.Create();

            // Initialization pass
            material.SetTexture("inputImage", coverageMap);
            Graphics.Blit(null, flipRT, material, 0);

            // Iterative passes
            bool renderToFlip = false;
            int iterations = (int)Mathf.Ceil(Mathf.Log(Mathf.Max(width, height), 2f));

            for (int i=0; i < iterations; i++)
            {
                RenderTexture.active = null;

                material.SetFloat("iteration", (float)i);

                material.SetTexture("previousResult", renderToFlip ? flopRT : flipRT);
                Graphics.Blit(null, renderToFlip ? flipRT : flopRT, material, 1);

                renderToFlip = !renderToFlip;
            }

            // Finalization pass
            var resultRT = renderToFlip ? flipRT : flopRT;

            material.SetTexture("inputImage", coverageMap);
            material.SetTexture("previousResult", renderToFlip ? flopRT : flipRT);
            Graphics.Blit(null, resultRT, material, 2);

            var downscaledResult = new RenderTexture(width / 4, height / 4, 0, RenderTextureFormat.R16);
            downscaledResult.wrapMode = TextureWrapMode.Repeat;
            downscaledResult.useMipMap = true;
            downscaledResult.autoGenerateMips = false;
            downscaledResult.Create();

            // Downscaling pass
            material.SetTexture("scalarImage", resultRT);
            material.SetVector("screenParams", new Vector2(width / 4, height / 4));
            Graphics.Blit(null, downscaledResult, material, 3);

            flipRT.Release();
            flopRT.Release();

            return downscaledResult;
        }

        public static void SaveSDFToFile(RenderTexture sdf, string path)
        {
            Texture2D temp = new Texture2D(sdf.width, sdf.height, TextureFormat.R16, false, false);

            RenderTexture.active = sdf;
            temp.ReadPixels(new Rect(0, 0, sdf.width, sdf.height), 0, 0);
            temp.Apply();
            RenderTexture.active = null;

            byte[] byteArray = temp.GetRawTextureData();

            byteArray = AddHeader(byteArray, new SDFHeader(sdf.width, sdf.height, 0, sdf.dimension == UnityEngine.Rendering.TextureDimension.Cube));

            System.IO.File.WriteAllBytes(path, byteArray);
        }

        public static Texture2D LoadSDFFromGameDataFile(string path)
        {
            var gameDataPath = System.IO.Path.Combine(KSPUtil.ApplicationRootPath, "GameData");
            path = System.IO.Path.Combine(gameDataPath, path);

            byte[] byteArray =  System.IO.File.ReadAllBytes(path);

            byte[] imageByteArray = GetArrayWithoutHeader(byteArray, out SDFHeader sdfHeader);
            byteArray = null;

            Texture2D sdf = new Texture2D(sdfHeader.Width, sdfHeader.Height, TextureFormat.R16, false, false);
            sdf.wrapMode = TextureWrapMode.Clamp;
            sdf.filterMode = FilterMode.Bilinear;
            sdf.LoadRawTextureData(imageByteArray);
            sdf.Apply();

            return sdf;
        }

        public struct SDFHeader
        {
            public int Width;
            public int Height;
            public int VolumeDepth;
            public bool CubeMap;
            public byte Reserved0;
            public byte Reserved1;
            public byte Reserved2;

            public SDFHeader(int width, int height, int volumeDepth, bool cubeMap)
            {
                Width = width;
                Height = height;
                VolumeDepth = volumeDepth;
                CubeMap = cubeMap;
                Reserved0 = new byte();
                Reserved1 = new byte();
                Reserved2 = new byte();
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