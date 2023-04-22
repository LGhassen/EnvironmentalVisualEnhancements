using Utils;

namespace Atmosphere
{
    public class FlowMap
    {
        [ConfigItem, Index(999)]
        TextureWrapper texture;
        [ConfigItem]
        float speed = 1f;
        [ConfigItem]
        float displacement = 1f;

        public TextureWrapper Texture { get => texture;  }
        public float Speed { get => speed; }
        public float Displacement { get => displacement; }
    }
}