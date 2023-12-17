using Utils;
using UnityEngine;

namespace Atmosphere
{
    public class CloudPhaseFunctions
    {

        [ConfigItem]
        Vector2 singleScattering1 = new Vector2(0.95f, 0.05f);

        [ConfigItem]
        Vector2 singleScattering2 = new Vector2(0.8f, 0.15f);

        [ConfigItem]
        Vector2 multipleScattering1 = new Vector2(0.2f, 2.0f);

        [ConfigItem]
        Vector2 multipleScattering2 = new Vector2(-0.4f, 0.2f);

        public Vector2 SingleScattering1 { get => singleScattering1; }
        public Vector2 SingleScattering2 { get => singleScattering2; }
        public Vector2 MultipleScattering1 { get => multipleScattering1; }
        public Vector2 MultipleScattering2 { get => multipleScattering2; }
    }
}