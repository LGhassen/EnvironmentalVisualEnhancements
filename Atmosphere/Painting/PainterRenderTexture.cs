using UnityEngine;
using Utils;

namespace Atmosphere
{
    public class PainterRenderTexture
    {
        private RenderTexture preview;
        private RenderTexture committed;

        public RenderTexture Preview { get => preview; }
        public RenderTexture Committed { get => committed; }

        public bool IsCreated => preview != null && committed != null;

        public void InitTexture(TextureWrapper targetWrapper, RenderTextureFormat format)
        {
            var targetTexture = targetWrapper.GetTexture();

            if (targetTexture != null)
            {
                Cleanup();

                CreateRT(format, targetTexture, ref preview);
                CreateRT(format, targetTexture, ref committed);

                var active = RenderTexture.active;
                {
                    var copyMapMaterial = new Material(CloudsPainter.CopyMapShader);
                    targetWrapper.SetAlphaMask(copyMapMaterial, 1);
                    CopyToRT(targetTexture, copyMapMaterial, preview);
                    CopyToRT(targetTexture, copyMapMaterial, committed);
                }
                RenderTexture.active = active;
            }
        }

        public void CopyCommittedToPreview()
        {
            if (!IsCreated)
                return;

            if (committed.dimension != UnityEngine.Rendering.TextureDimension.Cube)
            {
                Graphics.CopyTexture(committed, preview);
            }
            else
            {
                for (int i = 0; i < 6; i++)
                {
                    Graphics.CopyTexture(committed, i, preview, i);
                }
            }
        }

        private void CopyToRT(Texture targetTexture, Material copyMapMaterial, RenderTexture rt)
        {
            if (preview.dimension == UnityEngine.Rendering.TextureDimension.Cube)
            {
                CopyCubemapToRT(targetTexture, rt, copyMapMaterial);
            }
            else
            {
                copyMapMaterial.SetTexture("textureToCopy", targetTexture);
                Graphics.Blit(null, rt, copyMapMaterial);
            }
        }

        private void CreateRT(RenderTextureFormat format, Texture targetTexture, ref RenderTexture rt)
        {
            rt = new RenderTexture(targetTexture.width, targetTexture.height, 0, format, 0);
            rt.filterMode = FilterMode.Bilinear;
            rt.wrapMode = TextureWrapMode.Repeat;
            rt.useMipMap = false;

            if (targetTexture.dimension == UnityEngine.Rendering.TextureDimension.Cube)
                rt.dimension = UnityEngine.Rendering.TextureDimension.Cube;

            rt.Create();
        }

        // Unity doesn't provide a way to blit from a cubemap face to another with a custom material, do it manually with a custom blit.
        // Blitting from a cubemap face is also not supported except with Graphics.CopyTexture so implement my own by transforming the uv
        // and cubemap face index to cubemap direction to sample the original cubemap
        private void CopyCubemapToRT(Texture sourceTexture, RenderTexture targetRT, Material copyMapMaterial)
        {
            copyMapMaterial.EnableKeyword("CUBEMAP_MODE_ON");
            copyMapMaterial.SetTexture("textureToCopy", sourceTexture);

            for (int i = 0; i < 6; i++)
            {
                copyMapMaterial.SetInt("cubemapFace", i);
                RenderTextureUtils.BlitToCubemapFace(targetRT, copyMapMaterial, i);
            }
        }

        public void Cleanup()
        {
            if (preview != null)
                preview.Release();

            if (committed != null)
                committed.Release();
        }
    }
}