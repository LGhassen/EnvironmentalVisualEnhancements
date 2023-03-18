using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Utils
{


    [Flags]
    public enum TextureTypeEnum
    {
        RGBA = 0x1,
        AlphaMap = 0x2,
        CubeMap = 0x4,
        AlphaCubeMap = 0x8,
        [EnumMask] //This will hide it from the GUI until it is supported.
        RGB2_CubeMap = 0x10,

        [EnumMask]
        CubeMapMask = CubeMap | AlphaCubeMap | RGB2_CubeMap,
        [EnumMask]
        AlphaMapMask = AlphaMap | AlphaCubeMap
    }

    [Flags]
    public enum TextureMasksEnum
    {
    }

    public class TextureType : System.Attribute
    {
        public TextureTypeEnum Type;
        public TextureType(TextureTypeEnum type)
        {
            Type = type;
        }
    }

    public class BumpMap : System.Attribute
    { }

    public class Clamped : System.Attribute
    {
    }

    public class Index : System.Attribute
    {
        public int value;
        public Index(int i)
        {
            value = i;
        }
    }

    public class CubemapWrapper
    {

        private static Dictionary<String,CubemapWrapper> CubemapList = new Dictionary<String,CubemapWrapper>();

        private TextureTypeEnum type;
        public string name;

        Texture2D texPositive;
        Texture2D texNegative;
        Texture2D[] texList;

        public CubemapWrapper(string value, Texture2D[] textures, TextureTypeEnum cubeType, bool mipmaps, bool readable)
        {
            this.name = value;
            type = cubeType == TextureTypeEnum.RGB2_CubeMap? TextureTypeEnum.RGB2_CubeMap : TextureTypeEnum.CubeMap;
            KSPLog.print("[EVE] Creating " + name + " Cubemap");

            foreach (Texture2D tex in textures)
            {
                tex.wrapMode = TextureWrapMode.Clamp;
            }

            if (type == TextureTypeEnum.RGB2_CubeMap)
            {
                texPositive = textures[0];
                texNegative = textures[1];
            }
            else
            {
                /*
                cubeTex = new Cubemap(textures[0].width, TextureFormat.RGBA32, mipmaps);
                
                foreach (CubemapFace face in Enum.GetValues(typeof(CubemapFace)))
                {
                    Texture2D tex = textures[(int)face];
                    cubeTex.SetPixels(tex.GetPixels(), face);
                }
                cubeTex.Apply(mipmaps, !readable);
                cubeTex.SmoothEdges();
                */
                texList = textures;
                
            }
        }

        public static void GenerateCubemapWrapper(string value, Texture2D[] textures, TextureTypeEnum cubeType, bool mipmaps, bool readable)
        {
            CubemapList[value] = new CubemapWrapper(value, textures, cubeType, mipmaps, readable);
        }

        internal void ApplyCubeMap(Material mat, string name, int index)
        {
            if (type == TextureTypeEnum.RGB2_CubeMap)
            {
                mat.SetTexture("cube" + name + "POS", texPositive);
                mat.SetTexture("cube" + name + "NEG", texNegative);
                mat.EnableKeyword("MAP_TYPE_CUBE2_" + index.ToString());
                KSPLog.print("[EVE] Applying " + name + " Cubemap");
            }
            else
            {
                /*
                KSPLog.print("[EVE] Setting cube" + name);
                mat.SetTexture("cube" + name, cubeTex);
                mat.EnableKeyword("MAP_TYPE_CUBE_" + index.ToString());
                */
                mat.SetTexture("cube" + name + "xn", texList[(int)CubemapFace.NegativeX]);
                mat.SetTexture("cube" + name + "yn", texList[(int)CubemapFace.NegativeY]);
                mat.SetTexture("cube" + name + "zn", texList[(int)CubemapFace.NegativeZ]);
                mat.SetTexture("cube" + name + "xp", texList[(int)CubemapFace.PositiveX]);
                mat.SetTexture("cube" + name + "yp", texList[(int)CubemapFace.PositiveY]);
                mat.SetTexture("cube" + name + "zp", texList[(int)CubemapFace.PositiveZ]);
                mat.EnableKeyword("MAP_TYPE_CUBE6_" + index.ToString());
                
            }
        }

        internal static bool Exists(string value, TextureTypeEnum type)
        {
            //Only the one type supported for now
            return (CubemapList.ContainsKey(value));// && CubemapList[value].type == type);
        }

        public static CubemapWrapper fetchCubeMap(TextureWrapper textureWrapper)
        {
            bool cubemapExists = CubemapList.ContainsKey(textureWrapper.Name);
            if (cubemapExists)
            {
                return CubemapList[textureWrapper.Name];
            }
            else
            {
                return null;
            }
        }

        public Color Sample(Vector3 normalizedSphereVector)
        {
            if (type != TextureTypeEnum.RGB2_CubeMap)
            {
                var uv = GetCubeMapUVAndFaceTosample(normalizedSphereVector, out CubemapFace faceToSample);
                return texList[(int)faceToSample].GetPixelBilinear(uv.x, uv.y, 0);
            }

            return Color.white;
        }

        private Vector2 GetCubeMapUVAndFaceTosample(Vector3 cubeVectNorm, out CubemapFace faceToSample)
        {
            Vector3 cubeVectNormAbs = new Vector3(Mathf.Abs(cubeVectNorm.x), Mathf.Abs(cubeVectNorm.y), Mathf.Abs(cubeVectNorm.z));
            float zxlerp = step(cubeVectNormAbs.x, cubeVectNormAbs.z);
            float nylerp = step(cubeVectNormAbs.y, Mathf.Max(cubeVectNormAbs.x, cubeVectNormAbs.z));
            float s = Mathf.Lerp(cubeVectNorm.x, cubeVectNorm.z, zxlerp);
            s = Mathf.Sign(Mathf.Lerp(cubeVectNorm.y, s, nylerp));

            Vector3 detailCoords = Vector3.Lerp(new Vector3(cubeVectNorm.x, -s * cubeVectNorm.z, -cubeVectNorm.y), new Vector3(cubeVectNorm.z, s * cubeVectNorm.x, -cubeVectNorm.y), zxlerp);
            detailCoords = Vector3.Lerp(new Vector3(cubeVectNorm.y, cubeVectNorm.x, s * cubeVectNorm.z), detailCoords, nylerp);

            Vector2 uv = (new Vector2(0.5f * detailCoords.y, 0.5f * detailCoords.z) / Mathf.Abs(detailCoords.x)) + new Vector2(0.5f, 0.5f);

            bool positive = s > 0;

            if (nylerp < 0)
            {
                faceToSample = positive ? CubemapFace.PositiveY : CubemapFace.NegativeY;
            }
            else
            {
                if (zxlerp > 0 )
                {
                    faceToSample = positive ? CubemapFace.PositiveZ : CubemapFace.NegativeZ;
                }
                else
                {
                    faceToSample = positive ? CubemapFace.PositiveX : CubemapFace.NegativeX;
                }
            }

            return uv;
        }

        private float step(float a, float x)
        {
            return x >= a ? 1f :0f;
        }
    }

    public enum AlphaMaskEnum
    {
        ALPHAMAP_R,
        ALPHAMAP_G,
        ALPHAMAP_B,
        ALPHAMAP_A
    }


    [ValueNode, ValueFilter("isClamped|format")]
    public class TextureWrapper
    {
        bool isNormal = false;

#pragma warning disable 0649
#pragma warning disable 0414
        [ConfigItem, GUIHidden, NodeValue]
        string value;
        [ConfigItem]
        bool isClamped = false;
        [ConfigItem]
        TextureTypeEnum type = TextureTypeEnum.RGBA;
        [ConfigItem, Conditional("alphaMaskEval")]
        AlphaMaskEnum alphaMask = AlphaMaskEnum.ALPHAMAP_A;

        Texture2D textureValue = null;
        CubemapWrapper cubemapWrapper = null;

        int index = 1;
        public bool IsNormal { get { return isNormal; } set { isNormal = value; } }
        public bool IsClamped { get { return isClamped; } set { isClamped = value; } }
        public int Index { get { return index; } set { index = value; } }
        public string Name { get { return value; } }
        public TextureTypeEnum Type { get { return type; } }
        public AlphaMaskEnum AlphaMask { get { return alphaMask; } }

        public TextureWrapper()
        {

        }

        public void ApplyTexture(Material mat, string name, int? overrideIndex = null)
        {
            int indexToUse = overrideIndex.HasValue ? overrideIndex.Value : index;
            GameDatabase.TextureInfo texture = null;
            if ((type & TextureTypeEnum.CubeMapMask) > 0)
            {
                CubemapWrapper cubeMap = CubemapWrapper.fetchCubeMap(this);
                if (cubeMap != null)
                {
                    cubeMap.ApplyCubeMap(mat, name, indexToUse);
                    cubemapWrapper = cubeMap;
                }
            }
            else
            {
                texture = GameDatabase.Instance.GetTextureInfo(value);
            }
            if (texture != null)
            {
                texture.texture.wrapMode = isClamped ? TextureWrapMode.Clamp : TextureWrapMode.Repeat;
                mat.SetTexture(name, texture.texture);
                textureValue = texture.texture;
            }
            SetAlphaMask(mat, indexToUse);
        }

        public void SetAlphaMask(Material mat, int indexToUse)
        {
            if ((type & TextureTypeEnum.AlphaMapMask) > 0)
            {
                mat.EnableKeyword(alphaMask + "_" + indexToUse);
                mat.EnableKeyword("ALPHAMAP_" + indexToUse);
                Vector4 alphaMaskVector;
                alphaMaskVector.x = alphaMask == AlphaMaskEnum.ALPHAMAP_R ? 1 : 0;
                alphaMaskVector.y = alphaMask == AlphaMaskEnum.ALPHAMAP_G ? 1 : 0;
                alphaMaskVector.z = alphaMask == AlphaMaskEnum.ALPHAMAP_B ? 1 : 0;
                alphaMaskVector.w = alphaMask == AlphaMaskEnum.ALPHAMAP_A ? 1 : 0;
                mat.SetVector("alphaMask" + indexToUse, alphaMaskVector);
                mat.SetFloat("useAlphaMask" + indexToUse, 1f);
            }
            else
            {
                mat.DisableKeyword(alphaMask + "_" + indexToUse);
                mat.DisableKeyword("ALPHAMAP_" + indexToUse);

                mat.EnableKeyword("ALPHAMAP_N_" + indexToUse);
                mat.SetFloat("useAlphaMask" + indexToUse, 0f);
            }
        }

        public Texture2D GetTexture()
        {
            if ((type & TextureTypeEnum.CubeMapMask) > 0)
            {
                return null;
            }
            else
            {
                return GameDatabase.Instance.GetTextureInfo(value)?.texture;
            }
        }

        public CubemapWrapper GetCubemapWrapper()
        {
            if ((type & TextureTypeEnum.CubeMapMask) > 0)
            {
                return CubemapWrapper.fetchCubeMap(this);
            }
            else
            {
                return null;
            }
        }

        public bool isValid()
        {
            if (value == null || value == "")
            {
                return true;
            }
            else if ((type & TextureTypeEnum.CubeMapMask) > 0)
            {
                return CubemapWrapper.Exists(value, type);
            }
            else
            {
                return GameDatabase.Instance.ExistsTexture(value);
            }
        }

        public static bool alphaMaskEval(ConfigNode node)
        {
            TextureWrapper test = new TextureWrapper();
            ConfigHelper.LoadObjectFromConfig(test, node);
            
            if ((test.type & TextureTypeEnum.AlphaMapMask) > 0)
            {
                return true;
            }
            else
            {
                return false;
            }
        }

        public Color Sample(Vector3 normalizedSphereVector)
        {
            Color result = Color.white;

            if (textureValue != null)
            {
                Vector2 uv = GetEquirectangularUV(normalizedSphereVector);
                result = textureValue.GetPixelBilinear(uv.x, uv.y, 0);
            }
            else if ((type & TextureTypeEnum.CubeMapMask) > 0)
            {
                result = cubemapWrapper.Sample(normalizedSphereVector);
            }

            if ((type & TextureTypeEnum.AlphaMapMask) > 0)
            {
                float resultComponent = result.r;

                if (alphaMask == AlphaMaskEnum.ALPHAMAP_G)
                    resultComponent = result.g;
                else if (alphaMask == AlphaMaskEnum.ALPHAMAP_B)
                    resultComponent = result.b;
                else if (alphaMask == AlphaMaskEnum.ALPHAMAP_A)
                    resultComponent = result.a;

                return new Vector4(resultComponent, resultComponent, resultComponent, resultComponent);
            }

            return result;
        }

        private static Vector2 GetEquirectangularUV(Vector3 normalizedSphereVector)
        {
            Vector2 uv;

            uv.y = Mathf.Acos(normalizedSphereVector.y) / Mathf.PI;
            uv.x = 0.5f + (0.5f / Mathf.PI * Mathf.Atan2(normalizedSphereVector.x, normalizedSphereVector.z));

            return uv;
        }
    }
}
