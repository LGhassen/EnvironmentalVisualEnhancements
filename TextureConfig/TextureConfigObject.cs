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
                string[] textureNames = new string[6];
                textureNames[(int)CubemapFace.NegativeX] = texXn;
                textureNames[(int)CubemapFace.NegativeY] = texYn;
                textureNames[(int)CubemapFace.NegativeZ] = texZn;
                textureNames[(int)CubemapFace.PositiveX] = texXp;
                textureNames[(int)CubemapFace.PositiveY] = texYp;
                textureNames[(int)CubemapFace.PositiveZ] = texZp;
                CubemapWrapperConfig.GenerateCubemapWrapperConfig(name, textureNames, TextureTypeEnum.CubeMap);
            }
            else if(type == TexTypeEnum.TEX_CUBE_2)
            {
                string[] textureNames = new string[2];
                textureNames[0] = texP;
                textureNames[1] = texN;
                CubemapWrapperConfig.GenerateCubemapWrapperConfig(name, textureNames, TextureTypeEnum.RGB2_CubeMap);
            }
        }


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
