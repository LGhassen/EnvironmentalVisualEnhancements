using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace Utils
{
    public class HistoryManager<T>
    {
        private T[,,] array = null;

        private bool flipFlop = false;
        private bool vr = false;
        private bool cubemap = false;

        public bool FlipFlop { get => flipFlop; }
        public bool VR { get => vr; }
        public bool Cubemap { get => cubemap; }

        public HistoryManager(bool flipFlop, bool VR, bool cubemap)
        {
            this.flipFlop = flipFlop;
            this.vr = VR;
            this.cubemap = cubemap;

            array = new T[flipFlop ? 2 : 1, VR ? 2 : 1, cubemap ? 6 : 1];
        }

        public void GetDimensions(out int x, out int y, out int z)
        {
            x = array.GetLength(0);
            y = array.GetLength(1);
            z = array.GetLength(2);
        }

        private void CalculateIndices(bool flip, bool VRRightEye, int cubemapFace, out int x, out int y, out int z)
        {
            x = flipFlop && !flip ? 1 : 0;
            y = vr && !VRRightEye ? 1 : 0;
            z = Cubemap ? cubemapFace : 0;
        }

        public T this[bool flip, bool VRRightEye, int cubemapFace]
        {
            get
            {
                CalculateIndices(flip, VRRightEye, cubemapFace, out int x, out int y, out int z);
                return array[x, y, z];
            }
            set
            {
                CalculateIndices(flip, VRRightEye, cubemapFace, out int x, out int y, out int z);
                array[x, y, z] = value;
            }
        }

        public T this[int x, int y, int z]
        {
            get
            {
                x = Math.Min(x, array.GetLength(0)); y = Math.Min(y, array.GetLength(1)); z = Math.Min(z, array.GetLength(2));
                return array[x, y, z];
            }
            set
            {
                x = Math.Min(x, array.GetLength(0)); y = Math.Min(y, array.GetLength(1)); z = Math.Min(z, array.GetLength(2));
                array[x, y, z] = value;
            }
        }
    }

    public static class RenderTextureUtils
	{
        public static HistoryManager<RenderTexture> CreateRTHistoryManager(bool flipFlop, bool VR, bool cubemap, int width,
                                                                        int height, RenderTextureFormat format, FilterMode filterMode, TextureDimension dimension = TextureDimension.Tex2D,
                                                                        int depth = 0, bool randomReadWrite = false, TextureWrapMode wrapMode = TextureWrapMode.Clamp)
        {
            var historyManager = new HistoryManager<RenderTexture>(flipFlop, VR, cubemap);

            historyManager.GetDimensions(out int x, out int y, out int z);

            for (int i = 0; i < x; i++)
            {
                for (int j = 0; j < y; j++)
                {
                    for (int k = 0; k < z; k++)
                    {
                        historyManager[i, j, k] = CreateRenderTexture(width, height, format, false, filterMode, dimension, depth, randomReadWrite, wrapMode);
                    }
                }
            }

            return historyManager;
        }

        public static void ReleaseRTHistoryManager(HistoryManager<RenderTexture> historyManager)
        {
            if (historyManager != null)
            { 
                historyManager.GetDimensions(out int x, out int y, out int z);

                for (int i = 0; i < x; i++)
                {
                    for (int j = 0; j < y; j++)
                    {
                        for (int k = 0; k < z; k++)
                        {
                            var rt = historyManager[i, j, k];
                            if (rt != null)
                            {
                                rt.Release();
                            }

                            historyManager[i, j, k] = null;
                        }
                    }
                }
            }
        }

        public static void ResizeRTHistoryManager(HistoryManager<RenderTexture> historyManager, int newWidth, int newHeight, int newDepth = 0)
        {
            historyManager.GetDimensions(out int x, out int y, out int z);

            for (int i = 0; i < x; i++)
            {
                for (int j = 0; j < y; j++)
                {
                    for (int k = 0; k < z; k++)
                    {
                        ResizeRT(historyManager[i, j, k], newWidth, newHeight, newDepth);
                    }
                }
            }
        }

        public static void ResizeRT(RenderTexture rt, int newWidth, int newHeight, int newDepth = 0)
        {
            if (rt != null)
            {
                rt.Release();
                rt.width = newWidth;
                rt.height = newHeight;
                rt.volumeDepth = newDepth;
                rt.Create();
            }
        }

        public static RenderTexture CreateRenderTexture(int width, int height, RenderTextureFormat format, bool useMips, FilterMode filterMode, TextureDimension dimension = TextureDimension.Tex2D, int depth = 0, bool randomReadWrite = false, TextureWrapMode wrapMode = TextureWrapMode.Repeat, bool autoGenerateMips = false)
        {
            var rt = new RenderTexture(width, height, 0, format);
            rt.anisoLevel = 1;
            rt.antiAliasing = 1;
            rt.dimension = dimension;
            rt.volumeDepth = depth;
            rt.useMipMap = useMips;
            rt.autoGenerateMips = autoGenerateMips;
            rt.filterMode = filterMode;
            rt.enableRandomWrite = randomReadWrite;
            rt.wrapMode = wrapMode;
            rt.Create();

            return rt;
        }

        public static void Blit3D(RenderTexture tex, int slice, int size, Material blitMat, int pass)
        {
            GL.PushMatrix();
            GL.LoadOrtho();

            Graphics.SetRenderTarget(tex, 0, CubemapFace.Unknown, slice);

            float z = Mathf.Clamp01(slice / (float)(size - 1));

            blitMat.SetPass(pass);

            GL.Begin(GL.QUADS);

            GL.TexCoord3(0, 0, z);
            GL.Vertex3(0, 0, 0);
            GL.TexCoord3(1, 0, z);
            GL.Vertex3(1, 0, 0);
            GL.TexCoord3(1, 1, z);
            GL.Vertex3(1, 1, 0);
            GL.TexCoord3(0, 1, z);
            GL.Vertex3(0, 1, 0);

            GL.End();

            GL.PopMatrix();
        }

        public static void BlitToCubemapFace(RenderTexture tex, Material blitMat, int face, int pass = 0)
        {
            GL.PushMatrix();
            GL.LoadOrtho();

            Graphics.SetRenderTarget(tex, 0, (CubemapFace)face);

            blitMat.SetPass(pass);

            GL.Begin(GL.QUADS);

            GL.TexCoord3(0, 0, 0);
            GL.Vertex3(0, 0, 0);
            GL.TexCoord3(1, 0, 0);
            GL.Vertex3(1, 0, 0);
            GL.TexCoord3(1, 1, 0);
            GL.Vertex3(1, 1, 0);
            GL.TexCoord3(0, 1, 0);
            GL.Vertex3(0, 1, 0);

            GL.End();

            GL.PopMatrix();
        }
    }
}
