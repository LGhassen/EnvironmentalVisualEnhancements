using EVEManager;
using UnityEngine;
using Utils;

namespace Atmosphere
{
    [ConfigName("name")]
    public class ParticleFieldConfig : IEVEObject 
    {
		[ConfigItem]
		string name = "new particle field type";

		[ConfigItem]
		float fieldSize = 30f;

		[ConfigItem]
		float fieldParticleCount = 10000f;

		[ConfigItem]
		float fallSpeed = 1f;

		[ConfigItem]
		float tangentialSpeed = 1f;

		[ConfigItem]
		float randomDirectionStrength = 0.1f;

		[ConfigItem]
		Color color = Color.white * 255f;

		[ConfigItem]
		float particleSize = 0.02f;

		[ConfigItem]
		Vector2 particleSheetCount = new Vector2(1f, 1f);

		[ConfigItem]
		float particleStretch = 0.0f;

		[ConfigItem]
		float minCoverageThreshold = 0.3f;

		[ConfigItem]
		float maxCoverageThreshold = 0.75f;

		[ConfigItem, Optional]
		TextureWrapper particleTexture = null;

		//[ConfigItem, Optional]
		TextureWrapper particleDistorsionTexture = null;

		[ConfigItem]
		float distorsionStrength = 1f;

		[ConfigItem, Optional]
		Splashes splashes = null;

        public string Name { get => name; }
        public float FieldSize { get => fieldSize; }
        public float FieldParticleCount { get => fieldParticleCount; }
        public float FallSpeed { get => fallSpeed; }
        public float TangentialSpeed { get => tangentialSpeed; }
        public float RandomDirectionStrength { get => randomDirectionStrength; }
        public Color Color { get => color; }
        public float ParticleSize { get => particleSize; }
        public Vector2 ParticleSheetCount { get => particleSheetCount; }
        public float ParticleStretch { get => particleStretch; }
        public float MinCoverageThreshold { get => minCoverageThreshold; }
        public float MaxCoverageThreshold { get => maxCoverageThreshold; }
        public TextureWrapper ParticleTexture { get => particleTexture; }
        public TextureWrapper ParticleDistorsionTexture { get => particleDistorsionTexture; }
        public float DistorsionStrength { get => distorsionStrength; }
        public Splashes Splashes { get => splashes; }

        public void LoadConfigNode(ConfigNode node)
        {
            ConfigHelper.LoadObjectFromConfig(this, node);
        }

        public override string ToString() { return name; }

        public void Apply() 
        { 

        }
        public void Remove() { if (particleTexture != null) particleTexture.Remove(); }

        protected void Start()
        {
            
        }
	}

	public class Splashes
	{
		[ConfigItem]
		float splashesSpeed = 1f;

		[ConfigItem]
		Vector2 splashesSize = new Vector2(1f, 1f);

		[ConfigItem]
		Vector2 splashesSheetCount = new Vector2(1f, 1f);

		[ConfigItem]
		Color color = Color.white * 255f;

		[ConfigItem, Optional]
		TextureWrapper splashTexture = null;

		//[ConfigItem, Optional]
		TextureWrapper splashDistorsionTexture = null;

		//[ConfigItem]
		float distorsionStrength = 1f;

		public float SplashesSpeed { get => splashesSpeed; }
		public Vector2 SplashesSize { get => splashesSize; }
		public Vector2 SplashesSheetCount { get => splashesSheetCount; }

		public Color Color { get => color; }
		public TextureWrapper SplashTexture { get => splashTexture; }

		public TextureWrapper SplashDistorsionTexture { get => splashDistorsionTexture; }

		public float DistorsionStrength { get => distorsionStrength; }
	}
}
