using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;

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
        public static FlipFlop<RenderTexture> CreateFlipFlopRT(int width, int height, RenderTextureFormat format, FilterMode filterMode)
        {
            return new FlipFlop<RenderTexture>(
                CreateRenderTexture(width, height, format, false, filterMode),
                CreateRenderTexture(width, height, format, false, filterMode));
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

        public static RenderTexture CreateRenderTexture(int width, int height, RenderTextureFormat format, bool mips, FilterMode filterMode)
        {
            var rt = new RenderTexture(width, height, 0, format);
            rt.anisoLevel = 1;
            rt.antiAliasing = 1;
            rt.volumeDepth = 0;
            rt.useMipMap = mips;
            rt.autoGenerateMips = mips;
            rt.filterMode = filterMode;
            rt.Create();

            return rt;
        }
    }
}
