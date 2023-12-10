using System;
using System.IO;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using System.Collections.Generic;

namespace Utils
{ 
    public class EVEDDSValues
    {
        public static uint BC4U = MakePixelFormatFourCC("BC4U");

        // Source: https://gist.github.com/Scobalula/d9474f3fcf3d5a2ca596fceb64e16c98#file-directxtexutil-cs
        private static uint MakePixelFormatFourCC(string format)
        {
            char[] chars = format.ToCharArray(0, 4);
            return Convert.ToByte(chars[0]) | (uint)Convert.ToByte(chars[1]) << 8 | (uint)Convert.ToByte(chars[2]) << 16 | (uint)Convert.ToByte(chars[3]) << 24;
        }
    }

    public class TextureConverter
    {

        private static Color32[] ResizePixels(Color32[] pixels, int width, int height, int newWidth, int newHeight)
        {
            if (width != newWidth || height != newHeight)
            {
                Color32[] newPixels = new Color32[newWidth * newHeight];
                int index = 0;
                for (int h = 0; h < newHeight; h++)
                {
                    for (int w = 0; w < newWidth; w++)
                    {
                        GetPixel(ref newPixels[index++], pixels, width, height, ((float)w) / newWidth, ((float)h) / newHeight, newWidth, newHeight);
                    }
                }
                return newPixels;
            }
            else
            {
                return pixels;
            }
        }


        static Color32 cw1 = new Color32();
        static Color32 cw2 = new Color32();
        static Color32 cw3 = new Color32();
        static Color32 cw4 = new Color32();
        static Color32 ch1 = new Color32();
        static Color32 ch2 = new Color32();
        static Color32 ch3 = new Color32();
        static Color32 ch4 = new Color32();
        private static void GetPixel(ref Color32 newPixel, Color32[] pixels, int width, int height, float w, float h, int newWidth, int newHeight)
        {
            float widthDist = 4.0f - ((4.0f * (float)newWidth) / width);
            float heightDist = 4.0f - ((4.0f * (float)newHeight) / height);
            int[,] posArray = new int[2, 4];
            posArray[0, 0] = (int)Math.Floor((w * width) - widthDist);
            posArray[0, 1] = (int)Math.Floor(w * width);
            posArray[0, 2] = (int)Math.Ceiling((w * width) + widthDist);
            posArray[0, 3] = (int)Math.Ceiling((w * width) + (2.0 * widthDist));
            posArray[1, 0] = (int)Math.Floor((h * height) - heightDist);
            posArray[1, 1] = (int)Math.Floor(h * height);
            posArray[1, 2] = (int)Math.Ceiling((h * height) + heightDist);
            posArray[1, 3] = (int)Math.Ceiling((h * height) + (2.0 * heightDist));


            int w1 = posArray[0, 0];
            int w2 = posArray[0, 1];
            int w3 = posArray[0, 2];
            int w4 = posArray[0, 3];
            int h1 = posArray[1, 0];
            int h2 = posArray[1, 1];
            int h3 = posArray[1, 2];
            int h4 = posArray[1, 3];

            if (h2 >= 0 && h2 < height)
            {
                if (w2 >= 0 && w2 < width)
                {
                    cw2 = pixels[w2 + (h2 * width)];
                }
                if (w1 >= 0 && w1 < width)
                {
                    cw1 = pixels[w1 + (h2 * width)];
                }
                else
                {
                    cw1 = cw2;
                }
                if (w3 >= 0 && w3 < width)
                {
                    cw3 = pixels[w3 + (h2 * width)];
                }
                else
                {
                    cw3 = cw2;
                }
                if (w4 >= 0 && w4 < width)
                {
                    cw4 = pixels[w4 + (h2 * width)];
                }
                else
                {
                    cw4 = cw3;
                }

            }
            if (w2 >= 0 && w2 < width)
            {
                if (h2 >= 0 && h2 < height)
                {
                    ch2 = pixels[w2 + (h2 * width)];
                }
                if (h1 >= 0 && h1 < height)
                {
                    ch1 = pixels[w2 + (h1 * width)];
                }
                else
                {
                    ch1 = ch2;
                }
                if (h3 >= 0 && h3 < height)
                {
                    ch3 = pixels[w2 + (h3 * width)];
                }
                else
                {
                    ch3 = ch2;
                }
                if (h4 >= 0 && h4 < height)
                {
                    ch4 = pixels[w2 + (h4 * width)];
                }
                else
                {
                    ch4 = ch3;
                }
            }
            byte cwr = (byte)(((.25f * cw1.r) + (.75f * cw2.r) + (.75f * cw3.r) + (.25f * cw4.r)) / 2.0f);
            byte cwg = (byte)(((.25f * cw1.g) + (.75f * cw2.g) + (.75f * cw3.g) + (.25f * cw4.g)) / 2.0f);
            byte cwb = (byte)(((.25f * cw1.b) + (.75f * cw2.b) + (.75f * cw3.b) + (.25f * cw4.b)) / 2.0f);
            byte cwa = (byte)(((.25f * cw1.a) + (.75f * cw2.a) + (.75f * cw3.a) + (.25f * cw4.a)) / 2.0f);
            byte chr = (byte)(((.25f * ch1.r) + (.75f * ch2.r) + (.75f * ch3.r) + (.25f * ch4.r)) / 2.0f);
            byte chg = (byte)(((.25f * ch1.g) + (.75f * ch2.g) + (.75f * ch3.g) + (.25f * ch4.g)) / 2.0f);
            byte chb = (byte)(((.25f * ch1.b) + (.75f * ch2.b) + (.75f * ch3.b) + (.25f * ch4.b)) / 2.0f);
            byte cha = (byte)(((.25f * ch1.a) + (.75f * ch2.a) + (.75f * ch3.a) + (.25f * ch4.a)) / 2.0f);
            newPixel.r = (byte)((cwr + chr) / 2.0f);
            newPixel.g = (byte)((cwg + chg) / 2.0f);
            newPixel.b = (byte)((cwb + chb) / 2.0f);
            newPixel.a = (byte)((cwa + cha) / 2.0f);
        }

        public static void DDSToTexture(GameDatabase.TextureInfo texture, bool inPlace, Vector2 size, string cache = null, bool mipmaps = false)
        {
            /**
             * Kopernicus Planetary System Modifier
             * ====================================
             * Created by: BryceSchroeder and Teknoman117 (aka. Nathaniel R. Lewis)
             * Maintained by: Thomas P., NathanKell and KillAshley
             * Additional Content by: Gravitasi, aftokino, KCreator, Padishar, Kragrathea, OvenProofMars, zengei, MrHappyFace
             * ------------------------------------------------------------- 
             * This library is free software; you can redistribute it and/or
             * modify it under the terms of the GNU Lesser General Public
             * License as published by the Free Software Foundation; either
             * version 3 of the License, or (at your option) any later version.
             *
             * This library is distributed in the hope that it will be useful,
             * but WITHOUT ANY WARRANTY; without even the implied warranty of
             * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
             * Lesser General Public License for more details.
             *
             * You should have received a copy of the GNU Lesser General Public
             * License along with this library; if not, write to the Free Software
             * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
             * MA 02110-1301  USA
             * 
             * This library is intended to be used as a plugin for Kerbal Space Program
             * which is copyright 2011-2015 Squad. Your usage of Kerbal Space Program
             * itself is governed by the terms of its EULA, not the license above.
             * 
             * https://kerbalspaceprogram.com
             */
            // Borrowed from stock KSP 1.0 DDS loader (hi Mike!)
            // Also borrowed the extra bits from Sarbian.
            byte[] buffer = System.IO.File.ReadAllBytes(texture.file.fullPath);
            System.IO.BinaryReader binaryReader = new System.IO.BinaryReader(new System.IO.MemoryStream(buffer));
            uint num = binaryReader.ReadUInt32();
            if (num == DDSHeaders.DDSValues.uintMagic)
            {

                DDSHeaders.DDSHeader dDSHeader = new DDSHeaders.DDSHeader(binaryReader);

                if (dDSHeader.ddspf.dwFourCC == DDSHeaders.DDSValues.uintDX10)
                {
                    new DDSHeaders.DDSHeaderDX10(binaryReader);
                }
                bool alpha = (dDSHeader.dwFlags & 0x00000002) != 0;
                bool fourcc = (dDSHeader.dwFlags & 0x00000004) != 0;
                bool rgb = (dDSHeader.dwFlags & 0x00000040) != 0;
                bool alphapixel = (dDSHeader.dwFlags & 0x00000001) != 0;
                bool luminance = (dDSHeader.dwFlags & 0x00020000) != 0;
                bool rgb888 = dDSHeader.ddspf.dwRBitMask == 0x000000ff && dDSHeader.ddspf.dwGBitMask == 0x0000ff00 && dDSHeader.ddspf.dwBBitMask == 0x00ff0000;
                //bool bgr888 = dDSHeader.ddspf.dwRBitMask == 0x00ff0000 && dDSHeader.ddspf.dwGBitMask == 0x0000ff00 && dDSHeader.ddspf.dwBBitMask == 0x000000ff;
                bool rgb565 = dDSHeader.ddspf.dwRBitMask == 0x0000F800 && dDSHeader.ddspf.dwGBitMask == 0x000007E0 && dDSHeader.ddspf.dwBBitMask == 0x0000001F;
                bool argb4444 = dDSHeader.ddspf.dwABitMask == 0x0000f000 && dDSHeader.ddspf.dwRBitMask == 0x00000f00 && dDSHeader.ddspf.dwGBitMask == 0x000000f0 && dDSHeader.ddspf.dwBBitMask == 0x0000000f;
                bool rbga4444 = dDSHeader.ddspf.dwABitMask == 0x0000000f && dDSHeader.ddspf.dwRBitMask == 0x0000f000 && dDSHeader.ddspf.dwGBitMask == 0x000000f0 && dDSHeader.ddspf.dwBBitMask == 0x00000f00;

                bool mipmap = (dDSHeader.dwCaps & DDSHeaders.DDSPixelFormatCaps.MIPMAP) != (DDSHeaders.DDSPixelFormatCaps)0u;
                bool isNormalMap = ((dDSHeader.ddspf.dwFlags & 524288u) != 0u || (dDSHeader.ddspf.dwFlags & 2147483648u) != 0u);

                Vector2 newSize = size == default(Vector2) ? new Vector2(dDSHeader.dwWidth, dDSHeader.dwHeight) : size;
                if (fourcc)
                {
                    if (dDSHeader.ddspf.dwFourCC == DDSHeaders.DDSValues.uintDXT1)
                    {
                        if (inPlace && !texture.isReadable)
                        {
                            //This is a small hack to re-load the texture, even when it isn't readable. Unfortnately,
                            //we can't control compression, mipmaps, or anything else really, as the texture is still
                            //marked as unreadable. This will update the size and pixel data however.
                            Texture2D tmpTex = new Texture2D((int)newSize.x, (int)newSize.y, TextureFormat.ARGB32, mipmap);
                            Texture2D tmpTexSrc = new Texture2D((int)dDSHeader.dwWidth, (int)dDSHeader.dwHeight, TextureFormat.DXT1, mipmap);
                            tmpTexSrc.LoadRawTextureData(binaryReader.ReadBytes((int)(binaryReader.BaseStream.Length - binaryReader.BaseStream.Position)));
                            Color32[] colors = tmpTexSrc.GetPixels32();
                            colors = ResizePixels(colors, tmpTexSrc.width, tmpTexSrc.height, (int)newSize.x, (int)newSize.y);
                            tmpTex.SetPixels32(colors);
                            tmpTex.Apply(false);
                            //size using JPG to force DXT1

                            byte[] file = ImageConversion.EncodeToPNG(tmpTex);//tmpTex.EncodeToJPG();
                            if (cache != null)
                            {
                                Directory.GetParent(cache).Create();
                                System.IO.File.WriteAllBytes(cache, file);
                            }
                            texture.texture.LoadImage(file);

                            GameObject.DestroyImmediate(tmpTex);
                            GameDatabase.DestroyImmediate(tmpTexSrc);
                        }
                        else if (inPlace)
                        {
                            texture.texture.Resize((int)dDSHeader.dwWidth, (int)dDSHeader.dwHeight, TextureFormat.RGB24, mipmap);
                            texture.texture.Compress(false);
                            texture.texture.LoadRawTextureData(binaryReader.ReadBytes((int)(binaryReader.BaseStream.Length - binaryReader.BaseStream.Position)));
                            texture.texture.Apply(false, !texture.isReadable);
                        }
                        else
                        {
                            GameObject.DestroyImmediate(texture.texture);
                            texture.texture = new Texture2D((int)dDSHeader.dwWidth, (int)dDSHeader.dwHeight, TextureFormat.DXT1, mipmap);
                            texture.texture.LoadRawTextureData(binaryReader.ReadBytes((int)(binaryReader.BaseStream.Length - binaryReader.BaseStream.Position)));
                            texture.texture.Apply(false, !texture.isReadable);
                        }
                    }
                    else if (dDSHeader.ddspf.dwFourCC == DDSHeaders.DDSValues.uintDXT3)
                    {
                        if (inPlace && !texture.isReadable)
                        {
                            //This is a small hack to re-load the texture, even when it isn't readable. Unfortnately,
                            //we can't control compression, mipmaps, or anything else really, as the texture is still
                            //marked as unreadable. This will update the size and pixel data however.
                            Texture2D tmpTex = new Texture2D((int)newSize.x, (int)newSize.y, TextureFormat.ARGB32, mipmap);
                            Texture2D tmpTexSrc = new Texture2D((int)dDSHeader.dwWidth, (int)dDSHeader.dwHeight, (TextureFormat)11, mipmap);
                            tmpTexSrc.LoadRawTextureData(binaryReader.ReadBytes((int)(binaryReader.BaseStream.Length - binaryReader.BaseStream.Position)));
                            Color32[] colors = tmpTexSrc.GetPixels32();
                            colors = ResizePixels(colors, tmpTexSrc.width, tmpTexSrc.height, (int)newSize.x, (int)newSize.y);
                            tmpTex.SetPixels32(colors);
                            tmpTex.Apply(false);
                            //size using JPG to force DXT5
                            byte[] file = ImageConversion.EncodeToPNG(tmpTex);
                            if (cache != null)
                            {
                                Directory.GetParent(cache).Create();
                                System.IO.File.WriteAllBytes(cache, file);
                            }
                            texture.texture.LoadImage(file);

                            GameObject.DestroyImmediate(tmpTex);
                            GameDatabase.DestroyImmediate(tmpTexSrc);
                        }
                        else if (inPlace)
                        {
                            texture.texture.Resize((int)dDSHeader.dwWidth, (int)dDSHeader.dwHeight, (TextureFormat)11, mipmap);
                            texture.texture.LoadRawTextureData(binaryReader.ReadBytes((int)(binaryReader.BaseStream.Length - binaryReader.BaseStream.Position)));
                            texture.texture.Apply(false, !texture.isReadable);
                        }
                        else
                        {
                            GameObject.DestroyImmediate(texture.texture);
                            texture.texture = new Texture2D((int)dDSHeader.dwWidth, (int)dDSHeader.dwHeight, (TextureFormat)11, mipmap);
                            texture.texture.LoadRawTextureData(binaryReader.ReadBytes((int)(binaryReader.BaseStream.Length - binaryReader.BaseStream.Position)));
                            texture.texture.Apply(false, !texture.isReadable);
                        }
                    }
                    else if (dDSHeader.ddspf.dwFourCC == DDSHeaders.DDSValues.uintDXT5)
                    {
                        if (inPlace && !texture.isReadable)
                        {
                            //This is a small hack to re-load the texture, even when it isn't readable. Unfortnately,
                            //we can't control compression, mipmaps, or anything else really, as the texture is still
                            //marked as unreadable. This will update the size and pixel data however.
                            Texture2D tmpTex = new Texture2D((int)newSize.x, (int)newSize.y, TextureFormat.ARGB32, mipmap);
                            Texture2D tmpTexSrc = new Texture2D((int)dDSHeader.dwWidth, (int)dDSHeader.dwHeight, TextureFormat.DXT5, mipmap);
                            tmpTexSrc.LoadRawTextureData(binaryReader.ReadBytes((int)(binaryReader.BaseStream.Length - binaryReader.BaseStream.Position)));
                            Color32[] colors = tmpTexSrc.GetPixels32();
                            colors = ResizePixels(colors, tmpTexSrc.width, tmpTexSrc.height, (int)newSize.x, (int)newSize.y);
                            tmpTex.SetPixels32(colors);
                            tmpTex.Apply(false);
                            //size using JPG to force DXT5 
                            byte[] file = ImageConversion.EncodeToPNG(tmpTex);
                            if (cache != null)
                            {
                                Directory.GetParent(cache).Create();
                                System.IO.File.WriteAllBytes(cache, file);
                            }
                            texture.texture.LoadImage(file);
                            GameObject.DestroyImmediate(tmpTex);
                            GameDatabase.DestroyImmediate(tmpTexSrc);
                        }
                        else if (inPlace)
                        {
                            texture.texture.Resize((int)dDSHeader.dwWidth, (int)dDSHeader.dwHeight, TextureFormat.ARGB32, mipmap);
                            texture.texture.Compress(false);

                            texture.texture.LoadRawTextureData(binaryReader.ReadBytes((int)(binaryReader.BaseStream.Length - binaryReader.BaseStream.Position)));
                            texture.texture.Apply(false, !texture.isReadable);
                        }
                        else
                        {
                            GameObject.DestroyImmediate(texture.texture);
                            texture.texture = new Texture2D((int)dDSHeader.dwWidth, (int)dDSHeader.dwHeight, TextureFormat.DXT5, mipmap);
                            texture.texture.LoadRawTextureData(binaryReader.ReadBytes((int)(binaryReader.BaseStream.Length - binaryReader.BaseStream.Position)));
                            texture.texture.Apply(false, !texture.isReadable);
                        }
                    }
                    else if (dDSHeader.ddspf.dwFourCC == EVEDDSValues.BC4U)
                    {
                        GameObject.DestroyImmediate(texture.texture);
                        texture.texture = new Texture2D((int)dDSHeader.dwWidth, (int)dDSHeader.dwHeight, GraphicsFormat.R_BC4_UNorm, mipmap ? TextureCreationFlags.MipChain : TextureCreationFlags.None);
                        texture.texture.LoadRawTextureData(binaryReader.ReadBytes((int)(binaryReader.BaseStream.Length - binaryReader.BaseStream.Position)));
                        texture.texture.Apply(false, !texture.isReadable);
                    }
                    else if (dDSHeader.ddspf.dwFourCC == DDSHeaders.DDSValues.uintDXT2)
                    {
                        Debug.Log("DXT2 not supported");
                    }
                    else if (dDSHeader.ddspf.dwFourCC == DDSHeaders.DDSValues.uintDXT4)
                    {
                        Debug.Log("DXT4 not supported: ");
                    }
                    else if (dDSHeader.ddspf.dwFourCC == DDSHeaders.DDSValues.uintDX10)
                    {
                        Debug.Log("DX10 dds not supported: ");
                    }
                    else
                        fourcc = false;
                }
                if (!fourcc)
                {
                    TextureFormat textureFormat = TextureFormat.ARGB32;
                    bool ok = true;
                    if (rgb && (rgb888 /*|| bgr888*/))
                    {
                        // RGB or RGBA format
                        textureFormat = alphapixel
                        ? TextureFormat.RGBA32
                        : TextureFormat.RGB24;
                    }
                    else if (rgb && rgb565)
                    {
                        // Nvidia texconv B5G6R5_UNORM
                        textureFormat = TextureFormat.RGB565;
                    }
                    else if (rgb && alphapixel && argb4444)
                    {
                        // Nvidia texconv B4G4R4A4_UNORM
                        textureFormat = TextureFormat.ARGB4444;
                    }
                    else if (rgb && alphapixel && rbga4444)
                    {
                        textureFormat = TextureFormat.RGBA4444;
                    }
                    else if (!rgb && alpha != luminance)
                    {
                        // A8 format or Luminance 8
                        textureFormat = TextureFormat.Alpha8;
                    }
                    else
                    {
                        ok = false;
                        Debug.Log("Only DXT1, DXT5, BC4U, A8, RGB24, RGBA32, RGB565, ARGB4444 and RGBA4444 are supported");
                    }
                    if (ok)
                    {
                        if (inPlace && !texture.isReadable)
                        {
                            //This is a small hack to re-load the texture, even when it isn't readable. Unfortnately,
                            //we can't control compression, mipmaps, or anything else really, as the texture is still
                            //marked as unreadable. This will update the size and pixel data however.
                            Texture2D tmpTex = new Texture2D((int)newSize.x, (int)newSize.y, TextureFormat.ARGB32, mipmap);
                            Texture2D tmpTexSrc = new Texture2D((int)dDSHeader.dwWidth, (int)dDSHeader.dwHeight, textureFormat, mipmap);
                            tmpTexSrc.LoadRawTextureData(binaryReader.ReadBytes((int)(binaryReader.BaseStream.Length - binaryReader.BaseStream.Position)));
                            Color32[] colors = tmpTexSrc.GetPixels32();
                            colors = ResizePixels(colors, tmpTexSrc.width, tmpTexSrc.height, (int)newSize.x, (int)newSize.y);
                            tmpTex.SetPixels32(colors);
                            tmpTex.Apply(false);
                            //size using JPG to force alpha-less
                            byte[] file;
                            if (alphapixel)
                            {
                                file = ImageConversion.EncodeToPNG(tmpTex);
                            }
                            else
                            {
                                file = ImageConversion.EncodeToPNG(tmpTex);//file = tmpTex.EncodeToJPG();
                            }
                            if (cache != null)
                            {
                                Directory.GetParent(cache).Create();
                                System.IO.File.WriteAllBytes(cache, file);
                            }
                            texture.texture.LoadImage(file);
                            GameDatabase.DestroyImmediate(tmpTex);
                            GameDatabase.DestroyImmediate(tmpTexSrc);
                        }
                        else if (inPlace)
                        {
                            texture.texture.Resize((int)dDSHeader.dwWidth, (int)dDSHeader.dwHeight, textureFormat, mipmap);
                            texture.texture.LoadRawTextureData(binaryReader.ReadBytes((int)(binaryReader.BaseStream.Length - binaryReader.BaseStream.Position)));
                            texture.texture.Apply(false, !texture.isReadable);
                        }
                        else
                        {
                            GameDatabase.DestroyImmediate(texture.texture);
                            texture.texture = new Texture2D((int)dDSHeader.dwWidth, (int)dDSHeader.dwHeight, textureFormat, mipmap);
                            texture.texture.LoadRawTextureData(binaryReader.ReadBytes((int)(binaryReader.BaseStream.Length - binaryReader.BaseStream.Position)));
                            texture.texture.Apply(false, !texture.isReadable);
                        }
                    }

                }
            }
            else
                Debug.Log("Bad DDS header.");
        }

        // This assumes no mipmaps on input
        public static Texture2D ExtractBC4TextureFromBC3Alpha(Texture2D input)
        {
            Texture2D textureBC4 = new Texture2D(input.width, input.height, TextureFormat.BC4, false);
            textureBC4.filterMode = input.filterMode;
            textureBC4.wrapMode = input.wrapMode;

            byte[] allChannelArray = input.GetRawTextureData();
            byte[] alphaChannelArray = textureBC4.GetRawTextureData();

            for (int i = 0; i < alphaChannelArray.Length / 8; i++) //number of blocks
            {
                for (int j = 0; j < 8; j++) //bytes within a block
                {
                    alphaChannelArray[i * 8 + j] = allChannelArray[i * 16 + j]; //take only the first 8 bytes of every 16 bytes for the alpha/BC4 channel
                }
            }

            textureBC4.LoadRawTextureData(alphaChannelArray);
            textureBC4.Apply();

            return textureBC4;
        }

        // This was generated from unity docs, I didn't double check everything
        private static Dictionary<TextureFormat, int> bitsPerTextureFormatPixel = new Dictionary<TextureFormat, int>()
        {
            {TextureFormat.Alpha8, 8},
            {TextureFormat.ARGB4444, 16},
            {TextureFormat.RGB24, 24},
            {TextureFormat.RGBA32, 32},
            {TextureFormat.ARGB32, 32},
            {TextureFormat.RGB565, 16},
            {TextureFormat.R16, 16},
            {TextureFormat.DXT1, 4},
            {TextureFormat.DXT5, 8},
            {TextureFormat.RGBA4444, 16},
            {TextureFormat.BGRA32, 32},
            {TextureFormat.RHalf, 16},
            {TextureFormat.RGHalf, 32},
            {TextureFormat.RGBAHalf, 64},
            {TextureFormat.RFloat, 32},
            {TextureFormat.RGFloat, 64},
            {TextureFormat.RGBAFloat, 128},
            {TextureFormat.YUY2, 16},
            {TextureFormat.RGB9e5Float, 32},
            {TextureFormat.BC4, 4},
            {TextureFormat.BC5, 8},
            {TextureFormat.BC6H, 8},
            {TextureFormat.BC7, 8},
            {TextureFormat.DXT1Crunched, 4},
            {TextureFormat.DXT5Crunched, 8},
            {TextureFormat.PVRTC_RGB2, 2},
            {TextureFormat.PVRTC_RGBA2, 2},
            {TextureFormat.PVRTC_RGB4, 4},
            {TextureFormat.PVRTC_RGBA4, 4},
            {TextureFormat.ETC_RGB4, 4},
            {TextureFormat.EAC_R, 4},
            {TextureFormat.EAC_R_SIGNED, 4},
            {TextureFormat.EAC_RG, 8},
            {TextureFormat.EAC_RG_SIGNED, 8},
            {TextureFormat.ETC2_RGB, 4},
            {TextureFormat.ETC2_RGBA1, 4},
            {TextureFormat.ETC2_RGBA8, 8},
            {TextureFormat.ASTC_4x4, 8},
            {TextureFormat.ASTC_5x5, 16},
            {TextureFormat.ASTC_6x6, 24},
            {TextureFormat.ASTC_8x8, 32},
            {TextureFormat.ASTC_10x10, 64},
            {TextureFormat.ASTC_12x12, 96},
            {TextureFormat.RG16, 16},
            {TextureFormat.R8, 8},
            {TextureFormat.ETC_RGB4Crunched, 4},
            {TextureFormat.ETC2_RGBA8Crunched, 8},
            {TextureFormat.ASTC_HDR_4x4, 8},
            {TextureFormat.ASTC_HDR_5x5, 16},
            {TextureFormat.ASTC_HDR_6x6, 24},
            {TextureFormat.ASTC_HDR_8x8, 32},
            {TextureFormat.ASTC_HDR_10x10, 64},
            {TextureFormat.ASTC_HDR_12x12, 96}
        };

        public static int GetBitsPerPixel(TextureFormat format)
        {
            if (bitsPerTextureFormatPixel.ContainsKey(format))
            {
                return bitsPerTextureFormatPixel[format];
            }
            else
            {
                throw new ArgumentException("Invalid texture format");
            }
        }

    }
}
