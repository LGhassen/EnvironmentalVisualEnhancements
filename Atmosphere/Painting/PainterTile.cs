using UnityEngine;
using Utils;

namespace Atmosphere
{
    public class PainterTile
    {
        [ConfigItem]
        string tileName = "New tile";

        [ConfigItem]
        TextureWrapper coverageMap;

        [ConfigItem, Optional]
        TextureWrapper cloudTypeMap;

        [ConfigItem]
        float size = 100000f;

        [ConfigItem]
        Vector2 remapCoverage = new Vector2(0f, 1f);

        [ConfigItem]
        Vector2 remapType = new Vector2(0f, 1f);

        public string TileName { get => tileName; }
        public TextureWrapper CoverageMap { get => coverageMap; }
        public TextureWrapper CloudTypeMap { get => cloudTypeMap; }
        public float Size { get => size; }
        public Vector2 RemapCoverage { get => remapCoverage; }
        public Vector2 RemapType { get => remapType; }
    }

    public class PainterTileMask
    {
        [ConfigItem]
        string tileMaskName = "New tile mask";

        [ConfigItem]
        TextureWrapper texture;

        public string TileMaskName { get => tileMaskName; }
        public TextureWrapper Texture { get => texture; }
    }
}