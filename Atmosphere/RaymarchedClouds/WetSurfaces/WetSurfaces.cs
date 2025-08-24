using ShaderLoader;
using UnityEngine;
using Utils;
using static Targeting;

namespace Atmosphere
{
    public class WetSurfaces
    {
        [ConfigItem]
        string wetSurfacesConfig = "";

        WetSurfacesConfig wetSurfacesConfigObject = null;

        CloudsRaymarchedVolume cloudsRaymarchedVolume = null;

        Transform parentTransform;

        RenderTexture accumulationTexture;

        public CloudsRaymarchedVolume CloudsRaymarchedVolume { get => cloudsRaymarchedVolume; }

        public bool Apply(Transform parent, CloudsRaymarchedVolume volume)
        {
            wetSurfacesConfigObject = WetSurfacesManager.GetConfig(wetSurfacesConfig);

            if (wetSurfacesConfigObject == null)
                return false;

            cloudsRaymarchedVolume = volume;
            parentTransform = parent;

            // This is for the catch-up mechanism
            WetSurfacesManager.RenderingManager.RegisterWetSurfacesInstanceLoaded(this);

            InitAccumulationTexture(volume, wetSurfacesConfigObject);

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

        public void Update()
        {
            Vector3 positionToSample = Vector3.zero;
            
            if (FlightGlobals.ActiveVessel != null)
                positionToSample = FlightGlobals.ActiveVessel.transform.position;
            
            var coverageAtCraft = cloudsRaymarchedVolume.SampleCoverage(positionToSample, out float cloudType);

            coverageAtCraft = Mathf.Clamp01((coverageAtCraft - wetSurfacesConfigObject.MinCoverageThreshold) / (wetSurfacesConfigObject.MaxCoverageThreshold - wetSurfacesConfigObject.MinCoverageThreshold));

            if (coverageAtCraft > 0f)
                coverageAtCraft *= cloudsRaymarchedVolume.GetInterpolatedCloudTypeWetSurfacesDensity(cloudType);

            WetSurfacesManager.RenderingManager.AddFrameCoverage(coverageAtCraft, wetSurfacesConfigObject, parentTransform,
                accumulationTexture, cloudsRaymarchedVolume.CloudRotationMatrix, cloudsRaymarchedVolume.PlanetRadius,
                cloudsRaymarchedVolume.CurrentTimeFadeCoverage * cloudsRaymarchedVolume.CurrentTimeFadeDensity);
        }


        // I think when disabled we need to stop doing updates but not register/unregister
        // May not need actually need this
        public void SetEnabled(bool enabled)
        {

        }

        public void Remove()
        {
            WetSurfacesManager.RenderingManager.UnregisterWetSurfacesInstanceLoaded(this);
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