using UnityEngine;
using Utils;

namespace Atmosphere
{
    public class PainterTile
    {
        [ConfigItem]
        string tileName = "New tile";

        // Technically these shouldn't be loaded until I apply them in the painter, just make sure that's the case
        [ConfigItem]
        TextureWrapper coverageMap;

        [ConfigItem, Optional]  // TODO: deduce RG mode from this being present or not
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
}