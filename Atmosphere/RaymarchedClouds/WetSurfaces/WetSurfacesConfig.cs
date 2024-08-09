using EVEManager;
using Utils;

namespace Atmosphere
{
    [ConfigName("name")]
    public class WetSurfacesConfig : IEVEObject
    {
        [ConfigItem]
        string name = "new wet surfaces config";

        [ConfigItem]
        float accumulationCoverageThreshold = 1f;

        [ConfigItem]
        float wetnessAccumulationSpeed = 1f;

        [ConfigItem]
        float wetnessDryingSpeed = 1f;

        [ConfigItem]
        TextureWrapper puddlesTexture = null;

        [ConfigItem]
        float puddleTextureScale = 1f;

        [ConfigItem]
        float puddleAccumulationSpeed = 1f;

        [ConfigItem]
        float puddleDryingSpeed = 1f;

        [ConfigItem]
        float rippleSpeed = 1f;

        [ConfigItem]
        float rippleScale = 1f;

        [ConfigItem]
        float minCoverageThreshold = 0.0f;

        [ConfigItem]
        float maxCoverageThreshold = 1.0f;

        public string Name { get => name; }
        public float AccumulationCoverageThreshold { get => accumulationCoverageThreshold; }
        public float WetnessAccumulationSpeed { get => wetnessAccumulationSpeed; }
        public float WetnessDryingSpeed { get => wetnessDryingSpeed; }
        public TextureWrapper PuddlesTexture { get => puddlesTexture; }
        public float PuddleTextureScale  { get => puddleTextureScale; }
        public float PuddleAccumulationSpeed { get => puddleAccumulationSpeed; }
        public float PuddleDryingSpeed { get => puddleDryingSpeed; }
        public float RippleScale { get => rippleScale; }
        public float RippleSpeed { get => rippleSpeed; }
        public float MinCoverageThreshold { get => minCoverageThreshold; }
        public float MaxCoverageThreshold { get => maxCoverageThreshold; }

        public void LoadConfigNode(ConfigNode node)
        {
            ConfigHelper.LoadObjectFromConfig(this, node);
        }

        public override string ToString() { return name; }

        public void Apply()
        {

        }
        public void Remove()
        {
            if (puddlesTexture != null) puddlesTexture.Remove();
        }

        protected void Start()
        {

        }
    }
}