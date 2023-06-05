using EVEManager;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using Utils;

namespace TextureConfig
{
    [ConfigName("name")]
    public class TextureConfigObject : IEVEObject 
    {
        enum TexTypeEnum
        {
            REGULAR,
            TEX_CUBE_6,
            TEX_CUBE_2
        }

#pragma warning disable 0649
        [ConfigItem, GUIHidden]
        String name;
        [ConfigItem]
        bool mipmaps = true;
        [ConfigItem]
        bool isNormalMap = false;
        [ConfigItem]
        bool isReadable = false;
        [ConfigItem]
        bool isCompressed = false;
        [ConfigItem]
        TexTypeEnum type = TexTypeEnum.REGULAR;

        [ConfigItem, Conditional("cubeMapEval")]
        String texXn;
        [ConfigItem, Conditional("cubeMapEval")]
        String texXp;
        [ConfigItem, Conditional("cubeMapEval")]
        String texYn;
        [ConfigItem, Conditional("cubeMapEval")]
        String texYp;
        [ConfigItem, Conditional("cubeMapEval")]
        String texZn;
        [ConfigItem, Conditional("cubeMapEval")]
        String texZp;

        [ConfigItem, Conditional("dualMapEval")]
        String texP;
        [ConfigItem, Conditional("dualMapEval")]
        String texN;

        public override String ToString() { return name; }

        public void LoadConfigNode(ConfigNode node)
        {
            ConfigHelper.LoadObjectFromConfig(this, node);
        }

        public void Apply() 
        {
            if(type == TexTypeEnum.TEX_CUBE_6)
            {
                
                // for now No idea how to handle this logic so I can do on demand
                // probably just add a flag inside a cubemap wrapper that if it doesn't find textures it should try later on, on-demand
                // then it keeps a count by itself 

                ReplaceIfNecessaryInGameDatabase(texXn, isNormalMap, mipmaps, isReadable, isCompressed);
                ReplaceIfNecessaryInGameDatabase(texYn, isNormalMap, mipmaps, isReadable, isCompressed);
                ReplaceIfNecessaryInGameDatabase(texZn, isNormalMap, mipmaps, isReadable, isCompressed);
                ReplaceIfNecessaryInGameDatabase(texXp, isNormalMap, mipmaps, isReadable, isCompressed);
                ReplaceIfNecessaryInGameDatabase(texYp, isNormalMap, mipmaps, isReadable, isCompressed);
                ReplaceIfNecessaryInGameDatabase(texZp, isNormalMap, mipmaps, isReadable, isCompressed);
                
                string[] textureNames = new string[6];
                textureNames[(int)CubemapFace.NegativeX] = texXn;
                textureNames[(int)CubemapFace.NegativeY] = texYn;
                textureNames[(int)CubemapFace.NegativeZ] = texZn;
                textureNames[(int)CubemapFace.PositiveX] = texXp;
                textureNames[(int)CubemapFace.PositiveY] = texYp;
                textureNames[(int)CubemapFace.PositiveZ] = texZp;
                CubemapWrapperConfig.GenerateCubemapWrapperConfig(name, textureNames, TextureTypeEnum.CubeMap, mipmaps, isReadable);
            }
            else if(type == TexTypeEnum.TEX_CUBE_2)
            {
                ReplaceIfNecessaryInGameDatabase(texP, isNormalMap, mipmaps, isReadable, isCompressed);
                ReplaceIfNecessaryInGameDatabase(texN, isNormalMap, mipmaps, isReadable, isCompressed);

                string[] textureNames = new string[2];
                textureNames[0] = texP;
                textureNames[1] = texN;
                CubemapWrapperConfig.GenerateCubemapWrapperConfig(name, textureNames, TextureTypeEnum.RGB2_CubeMap, mipmaps, isReadable);
            }
            else
            {
                ReplaceIfNecessaryInGameDatabase(name, isNormalMap, mipmaps, isReadable, isCompressed);
            }
        }

        private static void ReplaceIfNecessaryInGameDatabase(string name, bool normalMap, bool mipmaps, bool readable, bool compressed)
        {
            if (GameDatabase.Instance.ExistsTexture(name))
            {
                GameDatabase.TextureInfo info = GameDatabase.Instance.GetTextureInfo(name);
                bool isReadable = false;
                try { info.texture.GetPixel(0, 0); isReadable = true; }
                catch { }
                bool hasMipmaps = info.texture.mipmapCount > 0;
                bool isCompressed = (info.texture.format == TextureFormat.DXT1 || info.texture.format == TextureFormat.DXT5);
                bool isNormalMap = info.isNormalMap;

                
                if (!isReadable || ( isCompressed && !compressed) || (isNormalMap != normalMap))
                {
                    //Pretty ineficient to not check beforehand, but makes the logic much simpler by simply reloading the textures.
                    info.isNormalMap = normalMap;
                    info.isReadable = readable;
                    info.isCompressed = compressed;
                    TextureConverter.Reload(info, false, default(Vector2), null, mipmaps);
                    info.texture.name = name;
                }
                else if (isReadable != readable || isCompressed != compressed || hasMipmaps != mipmaps)
                {
                    if(compressed)
                    {
                        info.texture.Compress(true);
                    }
                    info.texture.Apply(mipmaps, !readable);
                }
            }
        }

        //Right now we don't really have a good way to "undo" the changes. For now they will have to stay.
        public void Remove() { }

        public static bool cubeMapEval(ConfigNode node)
        {
            TextureConfigObject test = new TextureConfigObject();
            ConfigHelper.LoadObjectFromConfig(test, node);

            return test.type== TexTypeEnum.TEX_CUBE_6;
        }

        public static bool dualMapEval(ConfigNode node)
        {
            TextureConfigObject test = new TextureConfigObject();
            ConfigHelper.LoadObjectFromConfig(test, node);

            return test.type == TexTypeEnum.TEX_CUBE_2;
        }
    }
}
