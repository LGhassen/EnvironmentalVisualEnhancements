using ShaderLoader;
using UnityEngine;
using Utils;

namespace Atmosphere
{
    public class WetSurfaces
    {
        [ConfigItem]
        string wetSurfacesConfig = "";

        WetSurfacesConfig wetSurfacesConfigObject = null;

        CloudsRaymarchedVolume cloudsRaymarchedVolume = null;

        RenderTexture accumulationTexture;

        public CloudsRaymarchedVolume CloudsRaymarchedVolume { get => cloudsRaymarchedVolume; }
        public WetSurfacesConfig WetSurfacesConfigObject { get => wetSurfacesConfigObject; }
        public RenderTexture AccumulationTexture { get => accumulationTexture; }

        public bool Apply(Transform parent, CloudsRaymarchedVolume volume)
        {
            wetSurfacesConfigObject = WetSurfacesManager.GetConfig(wetSurfacesConfig);

            if (wetSurfacesConfigObject == null)
                return false;

            cloudsRaymarchedVolume = volume;
            InitAccumulationTexture(volume, wetSurfacesConfigObject);

            WetSurfacesManager.RenderingManager?.RegisterWetSurfacesInstanceLoaded(this);

            return true;
        }

        private void InitAccumulationTexture(CloudsRaymarchedVolume volume, WetSurfacesConfig config)
        {
            Material accumulationMaterial = new Material(ShaderLoaderClass.FindShader("EVE/WetSurfacesAccumulationMask"));

            volume.SetShaderParams(accumulationMaterial);

            var cloudTypes = volume.CloudTypes;
            float[] cloudTypeWetSurfaceStrength = new float[cloudTypes.Count];

            for (int i = 0; i < cloudTypes.Count; i++)
            {
                cloudTypeWetSurfaceStrength[i] = cloudTypes[i].WetSurfacesIntensity;
            }

            accumulationMaterial.SetFloatArray("cloudTypeWetSurfaceStrength", cloudTypeWetSurfaceStrength);

            accumulationMaterial.SetFloat("thresholdMin", config.MinCoverageThreshold);
            accumulationMaterial.SetFloat("thresholdMax", config.MaxCoverageThreshold);

            accumulationTexture = RenderTextureUtils.CreateRenderTexture(2048, 1024, RenderTextureFormat.R8, false, FilterMode.Bilinear);

            Graphics.Blit(null, accumulationTexture, accumulationMaterial, 0);
        }

        public void Remove()
        {
            WetSurfacesManager.RenderingManager?.UnregisterWetSurfacesInstanceLoaded(this);
            Cleanup();
        }

        public void Cleanup()
        {
            if (accumulationTexture != null && accumulationTexture.IsCreated())
            {
                accumulationTexture.Release();
            }
        }
    }
}