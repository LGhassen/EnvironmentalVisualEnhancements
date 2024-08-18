using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Rendering;

namespace Utils
{
    public struct FlipFlop<T>
    {
        public FlipFlop(T flip, T flop)
        {
            this.flip = flip;
            this.flop = flop;
        }

        public T this[bool useFlip]
        {
            get => useFlip ? flip : flop;
            set
            {
                if (useFlip) flip = value;
                else flop = value;
            }
        }

        T flip;
        T flop;
    }

    public static class RenderTextureUtils
	{
        public static FlipFlop<RenderTexture> CreateFlipFlopRT(int width, int height, RenderTextureFormat format, FilterMode filterMode, TextureDimension dimension = TextureDimension.Tex2D, int depth = 0, bool randomReadWrite = false, TextureWrapMode wrapMode = TextureWrapMode.Clamp)
        {
            return new FlipFlop<RenderTexture>(
                CreateRenderTexture(width, height, format, false, filterMode, dimension, depth, randomReadWrite, wrapMode),
                CreateRenderTexture(width, height, format, false, filterMode, dimension, depth, randomReadWrite, wrapMode));
        }

        public static void ReleaseFlipFlopRT(ref FlipFlop<RenderTexture> flipFlop)
        {
            RenderTexture rt;

            rt = flipFlop[false];
            if (rt != null) rt.Release();
            rt = flipFlop[true];
            if (rt != null) rt.Release();

            flipFlop = new FlipFlop<RenderTexture>(null, null);
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

        public static void ResizeFlipFlopRT(ref FlipFlop<RenderTexture> flipFlop, int newWidth, int newHeight, int newDepth = 0)
        {
            RenderTextureUtils.ResizeRT(flipFlop[false], newWidth, newHeight, newDepth);
            RenderTextureUtils.ResizeRT(flipFlop[true], newWidth, newHeight, newDepth);
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
