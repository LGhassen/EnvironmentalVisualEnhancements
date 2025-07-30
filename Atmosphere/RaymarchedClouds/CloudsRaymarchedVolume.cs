using ShaderLoader;
using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Utils;
using PQSManager;
using System.Threading.Tasks;

namespace Atmosphere
{
    public class CloudsRaymarchedVolume
    {
        public GameObject volumeHolder;

        private static Shader raymarchedCloudShader = null, invisibleShader = null;
        private static Shader RaymarchedCloudShader
        {
            get
            {
                if (raymarchedCloudShader == null) raymarchedCloudShader = ShaderLoaderClass.FindShader("EVE/RaymarchCloud");
                return raymarchedCloudShader;
            }
        }

        private static Shader InvisibleShader
        {
            get
            {
                if (invisibleShader == null) invisibleShader = ShaderLoaderClass.FindShader("EVE/Invisible");
                return invisibleShader;
            }
        }

        private int baseNoiseDimension = 128;
        private RenderTexture baseNoiseRT, curlNoiseRT;

        [ConfigItem]
        NoiseWrapper noise;

        [ConfigItem, Optional]
        CurlNoise curlNoise;

        [ConfigItem, Optional, Index(1), ValueFilter("isClamped|format|type|alphaMask")]
        TextureWrapper coverageMap;

        TextureWrapper detailTex;
        float detailScale = 0f;

        public TextureWrapper CoverageMap { get => coverageMap; }


        [ConfigItem, Optional]
        string sdfMap;

        Texture sdf;

        public Texture SDF { get => sdf; }

        public TextureWrapper DetailTex { get => detailTex; }

        [ConfigItem, Optional, Index(2), ValueFilter("isClamped|format|type|alphaMask")]
        TextureWrapper cloudTypeMap;

        public TextureWrapper CloudTypeMap { get => cloudTypeMap; }

        [ConfigItem, Optional, Index(4), ValueFilter("isClamped|format|type")]
        TextureWrapper cloudColorMap;

        [ConfigItem, Optional]
        FlowMap flowMap;

        public FlowMap FlowMap { get => flowMap; }

        public TextureWrapper CloudColorMap { get => cloudColorMap; }

        [ConfigItem]
        RaymarchingSettings raymarchingSettings = new RaymarchingSettings();

        [ConfigItem]
        LightVolumeUsage lightVolumeSettings = new LightVolumeUsage();

        [ConfigItem]
        CloudPhaseFunctions phaseFunctions = new CloudPhaseFunctions();

        [ConfigItem, Optional]
        ParticleField particleField = null;

        [ConfigItem, Optional]
        Droplets droplets = null;

        [ConfigItem, Optional]
        WetSurfaces wetSurfaces = null;

        [ConfigItem, Optional]
        Lightning lightning = null;

        [ConfigItem, Optional]
        AmbientSound ambientSound = null;

        [ConfigItem]
        Color color = Color.white * 255f;
        [ConfigItem]
        float skylightMultiplier = 1.0f;
        [ConfigItem]
        float skylightTintMultiplier = 0.0f;

        [ConfigItem]
        string receiveShadowsFromLayer = "";

        public string ReceiveShadowsFromLayer { get => receiveShadowsFromLayer; }

        [ConfigItem]
        float receivedShadowsDensity = 100f;

        [ConfigItem]
        float upwardsCloudSpeed = 11.0f;

        [ConfigItem]
        float scaledFadeStartAltitude = 30000.0f;

        [ConfigItem]
        float scaledFadeEndAltitude = 55000.0f;

        [ConfigItem]
        bool useDetailTex = false;

        [ConfigItem]
        bool useUntilingIfEnabled = true;

        float volumetricLayerScaledFade = 1.0f;

        [ConfigItem]
        List<CloudType> cloudTypes = new List<CloudType> { };

        public List<CloudType> CloudTypes { get { return cloudTypes; } }

        CloudsRaymarchedVolume shadowCasterLayerRaymarchedVolume = null;

        private float flowLoopTime = 0f; 

        protected Material raymarchedCloudMaterial, reflectionProbeRaymarchedCloudMaterial;
        public Material RaymarchedCloudMaterial { get => raymarchedCloudMaterial; }

        public Material ReflectionProbeRaymarchedCloudMaterial { get => reflectionProbeRaymarchedCloudMaterial; }

        private Texture2D curvesTexture, accumulatedVerticalCoverageTexture;

        private bool shadowCasterTextureSet = false;
        private bool _enabled = false;
        private bool reflectionProbeMode = false;

        private float currentTimeFadeDensity = 1f;
        private float currentTimeFadeCoverage = 1f;

        private float stepSizeLight = 0f;

        Light sunlight;

        private bool screenspaceShadowMaterialKeywordsEnabled = false;

        public bool enabled
        {
            get { return _enabled; }
            set
            {
                if (!shadowCasterTextureSet && (HighLogic.LoadedScene == GameScenes.FLIGHT || HighLogic.LoadedScene == GameScenes.SPACECENTER))
                {
                    SetShadowCasterTextureParams();
                }

                _enabled = value;
                volumeHolder.SetActive(value);
                volumeMeshrenderer.enabled = value;

                if (particleField != null)
                {
                    particleField.SetParticleFieldEnabled(value);
                }

                if (ambientSound != null)
                {
                    ambientSound.SetEnabled(value);
                }

                if (droplets != null)
                {
                    droplets.SetDropletsEnabled(value);
                }

                if (wetSurfaces != null)
                {
                    wetSurfaces.SetEnabled(value);
                }

                if (screenspaceShadowMaterialKeywordsEnabled != _enabled && screenspaceShadowMaterial != null)
                {
                    if (_enabled)
                    {
                        screenspaceShadowMaterial.EnableKeyword("VOLUMETRIC_CLOUD_SHADOW_ON");
                        screenspaceShadowMaterial.DisableKeyword("VOLUMETRIC_CLOUD_SHADOW_OFF");
                    }
                    else
                    {
                        screenspaceShadowMaterial.DisableKeyword("VOLUMETRIC_CLOUD_SHADOW_ON");
                        screenspaceShadowMaterial.EnableKeyword("VOLUMETRIC_CLOUD_SHADOW_OFF");
                    }

                    screenspaceShadowMaterialKeywordsEnabled = _enabled;
                }
            }
        }

        public void SetShadowCasterTextureParams(RenderTexture editorTexture = null, bool editorAlphamask = false)
        {
            // On Mac we are still short 2 texture slots if all features are enabled.
            // Disable 2d shadow caster in this case as it is the least impactful feature and mostly superseded by light volume.
            // If we are still short another texture slot SDF is disabled too.
            // Essentially if all features are enabled but SDF and Detailtex are disabled, keep this shadowcaster
            // If all features are enabled but one of SDF and Detailtex are enabled, disable this shadowcaster
            // If all features are enabled including SDF and Detailtex, disable shadowcaster + SDF
            bool skipShadowCaster = Tools.IsMac() && lightVolumeSettings.UseLightVolume && cloudColorMap != null
                && curlNoise != null && curlNoiseRT != null && (sdf != null || detailTex != null)
                && RaymarchedCloudsQualityManager.NonTiling3DNoise && (flowMap == null || useUntilingIfEnabled);

            if (!skipShadowCaster && shadowCasterLayerRaymarchedVolume?.CoverageMap != null)
            {
                SetShadowCasterMaterialParams(raymarchedCloudMaterial, editorTexture, editorAlphamask);
                SetShadowCasterMaterialParams(reflectionProbeRaymarchedCloudMaterial, editorTexture, editorAlphamask);

                if (particleField != null)
                {
                    SetShadowCasterMaterialParams(particleField.particleFieldMaterial, editorTexture, editorAlphamask);

                    if (particleField.particleFieldSplashesMaterial != null)
                    { 
                        SetShadowCasterMaterialParams(particleField.particleFieldSplashesMaterial, editorTexture, editorAlphamask);
                    }
                }
            }

            shadowCasterTextureSet = true;
        }

        private void SetShadowCasterMaterialParams(Material mat, RenderTexture editorTexture, bool editorAlphamask)
        {
            shadowCasterLayerRaymarchedVolume.CoverageMap.ApplyTexture(mat, "ShadowCasterCloudCoverage", 3);

            if (editorTexture != null)
            {
                mat.SetTexture("ShadowCasterCloudCoverage", editorTexture);

                if (editorAlphamask)
                {
                    mat.EnableKeyword("ALPHAMAP_3");
                    mat.SetVector("alphaMask3", new Vector4(1f, 0f, 0f, 0f));
                    mat.SetFloat("useAlphaMask3", 1f);
                }
            }

            mat.SetFloat("shadowCasterSphereRadius", shadowCasterLayerRaymarchedVolume.InnerSphereRadius);

            mat.DisableKeyword("CLOUD_SHADOW_CASTER_OFF");
        }

        float planetRadius, innerSphereRadius, outerSphereRadius, cloudMinAltitude, cloudMaxAltitude;
        public float InnerSphereRadius { get => innerSphereRadius;}
        public float OuterSphereRadius { get => outerSphereRadius; }
        public float PlanetRadius { get => planetRadius; }
        
        Transform parentTransform;
        public Transform ParentTransform { get => parentTransform; }

        private double timeXoffset = 0.0, timeYoffset = 0.0, timeZoffset = 0.0;

        private Matrix4x4 worldOppositeFrameDeltaRotationMatrix = Matrix4x4.identity;
        public Matrix4x4 WorldOppositeFrameDeltaRotationMatrix { get => worldOppositeFrameDeltaRotationMatrix; }

        private Matrix4x4 planetOppositeFrameDeltaRotationMatrix = Matrix4x4.identity;
        public Matrix4x4 PlanetOppositeFrameDeltaRotationMatrix { get => planetOppositeFrameDeltaRotationMatrix; }

        private Vector3 noiseReprojectionOffset = Vector3.zero;

        public Vector3 NoiseReprojectionOffset { get => noiseReprojectionOffset; }

        private Vector3 tangentialMovementDirection = Vector3.zero;

        public Vector3 TangentialMovementDirection { get => tangentialMovementDirection; }

        Matrix4x4 cloudRotationMatrix = Matrix4x4.identity;
        Matrix4x4 mainDetailRotationMatrix = Matrix4x4.identity;
        public Matrix4x4 CloudRotationMatrix { get => cloudRotationMatrix; }

        public Matrix4x4 MainDetailRotationMatrix { get => mainDetailRotationMatrix; }

        public float VolumetricLayerScaledFade { get => volumetricLayerScaledFade; }
        public float CurrentTimeFadeDensity { get => currentTimeFadeDensity; }
        public float CurrentTimeFadeCoverage { get => currentTimeFadeCoverage; }
        public float DetailScale { get => detailScale; }

        public MeshRenderer volumeMeshrenderer;

        Material screenspaceShadowMaterial = null;

        public CelestialBody parentCelestialBody;

        private CloudsMaterial CloudsPQSMaterial;

        private float linearSpeedMagnitude;

        public float LinearSpeedMagnitude { get => linearSpeedMagnitude; }
        public LightVolumeUsage LightVolumeSettings { get => lightVolumeSettings; }
        public RaymarchingSettings RaymarchingSettings { get => raymarchingSettings; }

        public void Apply(CloudsMaterial material, float cloudLayerRadius, Transform parent, float parentRadius, CelestialBody celestialBody, Clouds2D layer2d, float linearSpeedMagnitude)
        {
            parentCelestialBody = celestialBody;
            CloudsPQSMaterial = material;

            planetRadius = parentRadius;
            parentTransform = parent;

            raymarchedCloudMaterial = new Material(RaymarchedCloudShader);
            reflectionProbeRaymarchedCloudMaterial = new Material(RaymarchedCloudShader);
            screenspaceShadowMaterial = layer2d?.ScreenSpaceShadowMaterial;

            RenderNoiseTextures();
            ProcessCloudTypes();

            ApplyShaderParams();
            
            raymarchedCloudMaterial.SetFloat("scattererEnabled", 0f); // should be done on init only
            reflectionProbeRaymarchedCloudMaterial.SetFloat("scattererEnabled", 0f); // should be done on init only

            volumeHolder = GameObject.CreatePrimitive(PrimitiveType.Quad);
            volumeHolder.name = "CloudsRaymarchedVolume";
            GameObject.Destroy(volumeHolder.GetComponent<Collider>());

            var volumeUpdater = volumeHolder.AddComponent<Updater>();
            volumeUpdater.volume = this;
            volumeUpdater.mat = raymarchedCloudMaterial;
            volumeUpdater.refProbeMat = reflectionProbeRaymarchedCloudMaterial;
            volumeUpdater.parent = parentTransform;

            if (!raymarchingSettings.FxOnlyLayer)
            { 
                var volumeNotifier = volumeHolder.AddComponent<DeferredRaymarchedRendererNotifier>();
                volumeNotifier.volume = this;
            }

            volumeMeshrenderer = volumeHolder.GetComponent<MeshRenderer>();
            volumeMeshrenderer.material = new Material(InvisibleShader);

            raymarchedCloudMaterial.SetMatrix(ShaderProperties._ShadowBodies_PROPERTY, Matrix4x4.zero); // TODO eclipses
            reflectionProbeRaymarchedCloudMaterial.SetMatrix(ShaderProperties._ShadowBodies_PROPERTY, Matrix4x4.zero); // TODO eclipses

            volumeMeshrenderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            volumeMeshrenderer.receiveShadows = false;
            volumeMeshrenderer.enabled = true;

            MeshFilter filter = volumeHolder.GetComponent<MeshFilter>();
            filter.mesh.bounds = new Bounds(Vector3.zero, new Vector3(Mathf.Infinity, Mathf.Infinity, Mathf.Infinity));

            volumeHolder.transform.parent = parent;
            volumeHolder.transform.localPosition = Vector3.zero;
            volumeHolder.transform.localScale = Vector3.one;
            volumeHolder.transform.localRotation = Quaternion.identity;
            volumeHolder.layer = (int)Tools.Layer.Local;

            volumeHolder.SetActive(false);

            if (particleField != null)
            {
                if (!particleField.Apply(parent, celestialBody, this))
                {
                    particleField.Remove();
                    particleField = null;
                }
            }

            if (droplets != null)
            {
                if (!droplets.Apply(parent, this))
                {
                    droplets.Remove();
                    droplets = null;
                }
            }

            if (wetSurfaces != null)
            {
                if (!wetSurfaces.Apply(parent, this))
                {
                    wetSurfaces.Remove();
                    wetSurfaces = null;
                }
            }

            SetShadowCasterTextureParams();

            if (lightning != null)
                lightning.Apply(parent, celestialBody, this);

            if (ambientSound != null)
            {
                if (!ambientSound.Apply())
                {
                    ambientSound.Remove();
                    ambientSound = null;
                }
            }

            sunlight = Sun.Instance.GetComponent<Light>();

            this.linearSpeedMagnitude = linearSpeedMagnitude;

            raymarchedCloudMaterial.EnableKeyword(mainCameraNoiseKeywords);
            reflectionProbeRaymarchedCloudMaterial.EnableKeyword(reflectionProbeNoiseKeywords);
        }

        public void ApplyShaderParams()
        {
            SetShaderParams(raymarchedCloudMaterial);
            SetShaderParams(reflectionProbeRaymarchedCloudMaterial);

            raymarchedCloudMaterial.SetFloat(ShaderProperties.baseStepSize_PROPERTY, raymarchingSettings.BaseStepSize);
            raymarchedCloudMaterial.SetFloat(ShaderProperties.maxStepSize_PROPERTY, raymarchingSettings.MaxStepSize);
            raymarchedCloudMaterial.SetFloat(ShaderProperties.adaptiveStepSizeFactor_PROPERTY, raymarchingSettings.AdaptiveStepSizeFactor);

            raymarchedCloudMaterial.SetInt(ShaderProperties.lightMarchSteps_PROPERTY, (int)raymarchingSettings.LightMarchSteps);
            raymarchedCloudMaterial.SetFloat(ShaderProperties.stepSizeLight_PROPERTY, stepSizeLight);

            reflectionProbeRaymarchedCloudMaterial.SetFloat(ShaderProperties.baseStepSize_PROPERTY, raymarchingSettings.BaseStepSize * 5f);
            reflectionProbeRaymarchedCloudMaterial.SetFloat(ShaderProperties.maxStepSize_PROPERTY, raymarchingSettings.MaxStepSize * 5f);
            reflectionProbeRaymarchedCloudMaterial.SetFloat(ShaderProperties.adaptiveStepSizeFactor_PROPERTY, raymarchingSettings.AdaptiveStepSizeFactor * 5f);

            reflectionProbeRaymarchedCloudMaterial.SetInt(ShaderProperties.lightMarchSteps_PROPERTY, (int)raymarchingSettings.LightMarchSteps);
            reflectionProbeRaymarchedCloudMaterial.SetFloat(ShaderProperties.stepSizeLight_PROPERTY, 0f);

            if (screenspaceShadowMaterial != null)
            {
                SetShaderParams(screenspaceShadowMaterial);
                screenspaceShadowMaterial.EnableKeyword("VOLUMETRIC_CLOUD_SHADOW_ON");
                screenspaceShadowMaterial.DisableKeyword("VOLUMETRIC_CLOUD_SHADOW_OFF");
                screenspaceShadowMaterial.SetTexture("DensityCurve", Texture2D.whiteTexture);
                screenspaceShadowMaterial.SetTexture("AccumulatedVerticalCoverageTexture", accumulatedVerticalCoverageTexture);
            }

            if (lightVolumeSettings.UseLightVolume)
            {
                raymarchedCloudMaterial.EnableKeyword("LIGHT_VOLUME_ON");
                raymarchedCloudMaterial.DisableKeyword("LIGHT_VOLUME_OFF");

                reflectionProbeRaymarchedCloudMaterial.EnableKeyword("LIGHT_VOLUME_ON");
                reflectionProbeRaymarchedCloudMaterial.DisableKeyword("LIGHT_VOLUME_OFF");
            }
            else
            {
                raymarchedCloudMaterial.EnableKeyword("LIGHT_VOLUME_OFF");
                raymarchedCloudMaterial.DisableKeyword("LIGHT_VOLUME_ON");

                reflectionProbeRaymarchedCloudMaterial.EnableKeyword("LIGHT_VOLUME_OFF");
                reflectionProbeRaymarchedCloudMaterial.DisableKeyword("LIGHT_VOLUME_ON");
            }
        }

        public void RenderNoiseTextures()
        {
            if (noise != null && noise.GetNoiseMode() != NoiseMode.None)
            {
                baseNoiseRT = CreateRT(baseNoiseDimension, baseNoiseDimension, baseNoiseDimension, RenderTextureFormat.R8);
                NoiseGenerator.RenderNoiseToTexture(baseNoiseRT, noise);
            }

            if (curlNoise != null)
            {
                curlNoiseRT = CreateRT(baseNoiseDimension, baseNoiseDimension, baseNoiseDimension, RenderTextureFormat.RGB565);
                NoiseGenerator.RenderCurlNoiseToTexture(curlNoiseRT, curlNoise.ToNoiseSettings());
            }
        }

        public void SetShaderTextureParams(Material mat, bool singleNoiseScale)
        {
            SetNoisetextureParams(mat, singleNoiseScale);

            if (coverageMap != null)
            {
                coverageMap.ApplyTexture(mat, "CloudCoverage", 1);
            }
            else
            {
                mat.SetTexture("CloudCoverage", Texture2D.whiteTexture);
                mat.EnableKeyword("MAP_TYPE_1");
            }

            // On Mac we are still short 2 texture slots if all features are enabled.
            // Disable 2d shadow caster in this case as it is the least impactful feature and mostly superseded by light volume.
            // If we are still short another texture slot SDF is disabled too.
            // Essentially if all features are enabled but SDF and Detailtex are disabled, keep this shadowcaster
            // If all features are enabled but one of SDF and Detailtex are enabled, disable this shadowcaster
            // If all features are enabled including SDF and Detailtex, disable shadowcaster + SDF
            bool skipSDF = Tools.IsMac() && lightVolumeSettings.UseLightVolume && cloudColorMap != null
                        && curlNoise != null && curlNoiseRT != null && detailTex != null
                        && RaymarchedCloudsQualityManager.NonTiling3DNoise && (flowMap == null); // TODO recheck this, nonTiling no longer does added sample

            if (!skipSDF && !string.IsNullOrEmpty(sdfMap) && sdf == null)
            {
                sdf = SDFTool.LoadSDFFromGameDataFile(sdfMap+".sdf"); // TODO: error handling here because it fails to load and borks everything
                                                        // also maybe indicate red in the UI?
            }            

            if (sdf != null)
            {
                mat.EnableKeyword("SDF_ON"); mat.DisableKeyword("SDF_OFF");
                
                if (sdf.dimension == TextureDimension.Cube)
                    mat.SetTexture("cubeCloudSDF", sdf);
                else
                    mat.SetTexture("CloudSDF", sdf);

                Debug.Log("SDF loaded successfully");
            }
            else
            {
                mat.DisableKeyword("SDF_ON"); mat.EnableKeyword("SDF_OFF");
            }

            ApplyCloudTexture(cloudTypeMap, "CloudType", mat, 2);

            if (cloudColorMap != null)
            {
                mat.EnableKeyword("COLORMAP_ON"); mat.DisableKeyword("COLORMAP_OFF");
                ApplyCloudTexture(cloudColorMap, "CloudColorMap", mat, 4);
            }
            else
            {
                mat.EnableKeyword("COLORMAP_OFF"); mat.DisableKeyword("COLORMAP_ON");
            }
        }

        string mainCameraNoiseKeywords, reflectionProbeNoiseKeywords;

        private void SetNoisetextureParams(Material mat, bool singleNoiseScale)
        {
            bool noiseKeywordOn = false;
            bool curlNoiseKeywordOn = false;
            bool flowmapKeywordOn = false;
            bool noiseUntilingKeywordOn = false;

            if (noise != null && noise.GetNoiseMode() != NoiseMode.None && baseNoiseRT != null)
            {
                noiseKeywordOn = true;
                mat.SetTexture("BaseNoiseTexture", baseNoiseRT);
                mat.SetFloat("noiseErosionDepth", noise.ErosionDepth);
            }

            if (curlNoise != null && curlNoiseRT != null)
            {
                curlNoiseKeywordOn = true;
                mat.SetTexture("CurlNoiseTexture", curlNoiseRT);
                mat.SetFloat("smoothCurlNoise", curlNoise.Smooth ? 1f : 0f);
            }

            if (RaymarchedCloudsQualityManager.NonTiling3DNoise && useUntilingIfEnabled)
                noiseUntilingKeywordOn = true;

            if (useDetailTex && CloudsPQSMaterial.DetailTex != null)
            {
                detailTex = CloudsPQSMaterial.DetailTex;
                detailScale = CloudsPQSMaterial.DetailScale;
                CloudsPQSMaterial.DetailTex.ApplyTexture(mat, "_DetailTex");
                mat.SetFloat("_DetailScale", CloudsPQSMaterial.DetailScale);
                mat.EnableKeyword("DETAILTEX_ON"); mat.DisableKeyword("DETAILTEX_OFF");
            }
            else
            {
                mat.EnableKeyword("DETAILTEX_OFF"); mat.DisableKeyword("DETAILTEX_ON");
            }

            if (flowMap != null && flowMap.Texture != null)
            {
                flowmapKeywordOn = true;
                flowMap.Texture.ApplyTexture(mat, "_FlowMap", 999);
                mat.SetFloat("_flowStrength", flowMap.Displacement);
                mat.SetFloat("_flowSpeed", flowMap.Speed);
            }

            if (!noiseKeywordOn)
            {
                mat.EnableKeyword("NOISE_OFF");
            }
            else
            {
                mat.DisableKeyword("NOISE_OFF");
            }

            mainCameraNoiseKeywords = GetNoiseKeywords(noiseKeywordOn, curlNoiseKeywordOn, flowmapKeywordOn, noiseUntilingKeywordOn, singleNoiseScale);
            reflectionProbeNoiseKeywords = GetNoiseKeywords(noiseKeywordOn, curlNoiseKeywordOn, false, false, singleNoiseScale);
        }

        // Manually combined keywords to cut down shader permutations
        private static string GetNoiseKeywords(bool noiseKeywordOn, bool curlNoiseKeywordOn, bool flowmapKeywordOn,
            bool noiseUntilingKeywordOn, bool singleNoiseScaleKeywordOn)
        {
            if (!noiseKeywordOn)
            { 
                return "NOISE_OFF";
            }
            else
            {
                return $"NOISE_UNTILING_{(noiseUntilingKeywordOn ? "ON" : "OFF")}" +
                        $"_CURL_NOISE_{(curlNoiseKeywordOn ? "ON" : "OFF")}" +
                        $"_FLOWMAP_{(flowmapKeywordOn ? "ON" : "OFF")}" +
                        $"_SINGLE_NOISE_SCALE_{(singleNoiseScaleKeywordOn ? "ON" : "OFF")}";
            }
        }

        public void SetShadowCasterLayerRaymarchedVolume(CloudsRaymarchedVolume cloudsRaymarchedVolume)
        {
            if (cloudsRaymarchedVolume != null)
                shadowCasterLayerRaymarchedVolume = cloudsRaymarchedVolume;
        }

        private void ApplyCloudTexture(TextureWrapper cloudTexture, string propertyName, Material mat, int index)
        {
            if (cloudTexture != null)
            {
                cloudTexture.ApplyTexture(mat, propertyName, index);
            }
            else
            {
                mat.SetTexture(propertyName, Texture2D.whiteTexture);
            }
        }

        public void SetShaderParams(Material mat)
        {
            SetCloudTypesShaderParams(mat, out bool singleNoiseScale);
            SetShaderTextureParams(mat, singleNoiseScale);

            mat.SetFloat("useBodyRadiusIntersection", PQSManagerClass.HasRealPQS(parentCelestialBody) ? 1f : 0f);

            mat.SetTexture("StbnBlueNoise", ShaderLoader.ShaderLoaderClass.stbnScalar);
            mat.SetTexture("StbnUnitVec3", ShaderLoader.ShaderLoaderClass.stbnUnitVec3);
            mat.SetVector("stbnDimensions", new Vector3(ShaderLoader.ShaderLoaderClass.stbnDimensions.x, ShaderLoader.ShaderLoaderClass.stbnDimensions.y, ShaderLoader.ShaderLoaderClass.stbnDimensions.z));

            mat.SetColor("cloudColor", Tools.IsColorRGB(color) ? color / 255f : color);

            mat.SetFloat("lightMarchAttenuationMultiplier", 1.0f);

            if (curlNoise != null)
            { 
                mat.SetFloat("curlNoiseTiling", 1f / curlNoise.Tiling);
                mat.SetFloat("curlNoiseStrength", curlNoise.Strength);
            }

            mat.SetFloat("baseStepSize", raymarchingSettings.BaseStepSize);
            mat.SetFloat("maxStepSize", raymarchingSettings.MaxStepSize);
            mat.SetFloat("adaptiveStepSizeFactor", raymarchingSettings.AdaptiveStepSizeFactor);

            mat.SetFloat("lightMarchDistance", raymarchingSettings.LightMarchDistance);
            mat.SetInt("lightMarchSteps", (int)raymarchingSettings.LightMarchSteps);

            stepSizeLight = raymarchingSettings.LightMarchDistance / (int)raymarchingSettings.LightMarchSteps;
            mat.SetFloat("stepSizeLight", stepSizeLight);

            mat.SetFloat("skylightMultiplier", skylightMultiplier);
            mat.SetFloat("skylightTintMultiplier", skylightTintMultiplier);
            mat.SetFloat("shadowCasterDensity", receivedShadowsDensity);

            mat.SetVector("directPhaseFunctionProperties", new Vector4(phaseFunctions.SingleScattering1.x, phaseFunctions.SingleScattering1.y, phaseFunctions.SingleScattering2.x, phaseFunctions.SingleScattering2.y));
            mat.SetVector("multiplePhaseFunctionProperties", new Vector4(phaseFunctions.MultipleScattering1.x, phaseFunctions.MultipleScattering1.y, phaseFunctions.MultipleScattering2.x, phaseFunctions.MultipleScattering2.y));

            mat.EnableKeyword("CLOUD_SHADOW_CASTER_OFF");

            mat.SetFloat("timeFadeDensity", 1f);
            mat.SetFloat("timeFadeCoverage", 1f);
        }

        private void ProcessCloudTypes()
        {
            cloudMinAltitude = Mathf.Infinity;
            cloudMaxAltitude = -Mathf.Infinity;

            for (int i = 0; i < cloudTypes.Count; i++)
            {
                cloudMinAltitude = Mathf.Min(cloudMinAltitude, cloudTypes[i].MinAltitude);
                cloudMaxAltitude = Mathf.Max(cloudMaxAltitude, cloudTypes[i].MaxAltitude);
            }

            innerSphereRadius = planetRadius + cloudMinAltitude;
            outerSphereRadius = planetRadius + cloudMaxAltitude;

            if (curvesTexture != null)
                GameObject.Destroy(curvesTexture);

            if (accumulatedVerticalCoverageTexture != null)
                GameObject.Destroy(accumulatedVerticalCoverageTexture);

            curvesTexture = BakeCurvesTexture(out accumulatedVerticalCoverageTexture);
        }

        private void SetCloudTypesShaderParams(Material mat, out bool singleNoiseScale)
        {
            mat.SetFloat("innerSphereRadius", innerSphereRadius);
            mat.SetFloat("outerSphereRadius", outerSphereRadius);

            mat.SetFloat("layerHeight", outerSphereRadius - innerSphereRadius);
            mat.SetFloat("invLayerHeight", 1f / (outerSphereRadius - innerSphereRadius));

            mat.SetTexture("DensityCurve", curvesTexture);

            Vector4[] cloudTypePropertiesArray = new Vector4[cloudTypes.Count];
            float[] multipleScatteringBrightnessArray = new float[cloudTypes.Count];

            Vector2 minMaxNoiseTilings = new Vector2(1e9f, 0f);

            for (int i = 0; i < cloudTypes.Count; i++)
            {
                cloudTypePropertiesArray[i] = new Vector4(cloudTypes[i].Density, 1f / cloudTypes[i].BaseNoiseTiling, Mathf.Clamp01(Mathf.Max(1f - cloudTypes[i].NoiseEdgeHardness, 1e-10f)), cloudTypes[i].CurlNoiseStrength);
                multipleScatteringBrightnessArray[i] = cloudTypes[i].MultipleScatteringBrightness;

                minMaxNoiseTilings = new Vector2(Mathf.Min(minMaxNoiseTilings.x, 1f / cloudTypes[i].BaseNoiseTiling), Mathf.Max(minMaxNoiseTilings.y, 1f / cloudTypes[i].BaseNoiseTiling));
            }

            singleNoiseScale = minMaxNoiseTilings.x == minMaxNoiseTilings.y;

            if (curlNoise != null)
            {
                minMaxNoiseTilings = new Vector2(Mathf.Min(minMaxNoiseTilings.x, 1f / curlNoise.Tiling), Mathf.Max(minMaxNoiseTilings.y, 1f / curlNoise.Tiling));
            }

            mat.SetVectorArray("cloudTypeProperties0", cloudTypePropertiesArray);
            mat.SetFloatArray("multipleScatteringBrightnessArray", multipleScatteringBrightnessArray);
            mat.SetInt("numberOfCloudTypes", cloudTypes.Count);
            mat.SetFloat("planetRadius", planetRadius);

            mat.SetVector("minMaxNoiseTilings", minMaxNoiseTilings);
        }

        private Texture2D BakeCurvesTexture(out Texture2D accumulatedVerticalDensityTexture)
        {
            int resolution = 128;

            if (cloudTypes.Count == 0)
            {
                accumulatedVerticalDensityTexture = Texture2D.Instantiate(Texture2D.blackTexture);
                return Texture2D.Instantiate(Texture2D.whiteTexture);
            }

            Texture2D curvesTexture = new Texture2D(resolution, resolution, TextureFormat.RG16, false);
            curvesTexture.filterMode = FilterMode.Bilinear;
            curvesTexture.wrapMode = TextureWrapMode.Clamp;

            accumulatedVerticalDensityTexture = new Texture2D(resolution, resolution, TextureFormat.RHalf, false);
            accumulatedVerticalDensityTexture.filterMode = FilterMode.Bilinear;
            accumulatedVerticalDensityTexture.wrapMode = TextureWrapMode.Clamp;
            float layerHeight = cloudMaxAltitude - cloudMinAltitude;

            Color[] curvesColors = new Color[resolution * resolution];
            Color[] accumulatedVerticalCoverageColors = new Color[resolution * resolution];

            // Don't use parallel.for here, unity float curve isn't thread safe for reads
            for (int x = 0; x < resolution; x++)
            {
                // Find where we are and the two curves to interpolate
                float cloudTypeIndex = (float)x / (float)(resolution-1);
                cloudTypeIndex *= cloudTypes.Count - 1;
                int currentCloudType = (int)cloudTypeIndex;
                int nextCloudType = Math.Min(currentCloudType + 1, cloudTypes.Count - 1);
                float cloudFrac = cloudTypeIndex - currentCloudType;

                float interpolatedMinAltitude = Mathf.Lerp(cloudTypes[currentCloudType].MinAltitude, cloudTypes[nextCloudType].MinAltitude, cloudFrac);
                float interpolatedMaxAltitude = Mathf.Lerp(cloudTypes[currentCloudType].MaxAltitude, cloudTypes[nextCloudType].MaxAltitude, cloudFrac);

                for (int y = 0; y < resolution; y++)
                {
                    float currentAltitude = Mathf.Lerp(cloudMinAltitude, cloudMaxAltitude, (float)y / (float)(resolution-1));

                    float coverageValue = Mathf.Lerp(EvaluateCoverageValue(currentCloudType, currentAltitude, interpolatedMinAltitude, interpolatedMaxAltitude),
                                                EvaluateCoverageValue(nextCloudType, currentAltitude, interpolatedMinAltitude, interpolatedMaxAltitude),
                                                cloudFrac);
                    
                    float densityValue = Mathf.Lerp(EvaluateDensityValue(currentCloudType, currentAltitude, interpolatedMinAltitude, interpolatedMaxAltitude),
                                                EvaluateDensityValue(nextCloudType, currentAltitude, interpolatedMinAltitude, interpolatedMaxAltitude),
                                                cloudFrac);

                    curvesColors[x + y * resolution].r = coverageValue;
                    curvesColors[x + y * resolution].g = densityValue;
                }
            }

            curvesTexture.SetPixels(curvesColors);
            curvesTexture.Apply(false);

            Parallel.For(0, resolution, x =>
            {
                float cloudTypeIndex = (float)x / (float)(resolution - 1);
                cloudTypeIndex *= cloudTypes.Count - 1;
                int currentCloudType = (int)cloudTypeIndex;
                int nextCloudType = Math.Min(currentCloudType + 1, cloudTypes.Count - 1);
                float cloudFrac = cloudTypeIndex - currentCloudType;

                for (int y = 0; y < resolution; y++)
                {
                    float c = (float)y / (float)(resolution - 1);
                    float a = 0f;

                    for (int z = 0; z < resolution; z++)
                    {
                        float cg = Mathf.Clamp01(c + curvesColors[x + z * resolution].r - 1f);
                        float ih = Mathf.Lerp(Mathf.Clamp01(Mathf.Max(1f - cloudTypes[currentCloudType].NoiseEdgeHardness, 1e-10f)), Mathf.Clamp01(Mathf.Max(1f - cloudTypes[nextCloudType].NoiseEdgeHardness, 1e-10f)), cloudFrac);
                        a += Mathf.Clamp01((cg - 0.5f * noise.ErosionDepth) / (1.0f - ih)) * curvesColors[x + z * resolution].g * Mathf.Lerp(cloudTypes[currentCloudType].Density, cloudTypes[nextCloudType].Density, cloudFrac);
                    }

                    a *= layerHeight / resolution;
                    accumulatedVerticalCoverageColors[x + y * resolution] = new Color(a, a, a, a);
                }
            });

            accumulatedVerticalDensityTexture.SetPixels(accumulatedVerticalCoverageColors);
            accumulatedVerticalDensityTexture.Apply(false);

            return curvesTexture;
        }

        private float EvaluateCoverageValue(int cloudIndex, float currentAltitude, float interpolatedMinAltitude, float interpolatedMaxAltitude)
        {
            float minAltitude = cloudTypes[cloudIndex].InterpolateCloudHeights ? interpolatedMinAltitude : cloudTypes[cloudIndex].MinAltitude;
            float maxAltitude = cloudTypes[cloudIndex].InterpolateCloudHeights ? interpolatedMaxAltitude : cloudTypes[cloudIndex].MaxAltitude;

            if (currentAltitude <= maxAltitude && currentAltitude >= minAltitude)
            {
                float t = (currentAltitude - minAltitude) / (maxAltitude - minAltitude);
                return cloudTypes[cloudIndex].CoverageCurve.Evaluate(t);
            }

            return 0f;
        }
        
        private float EvaluateDensityValue(int cloudIndex, float currentAltitude, float interpolatedMinAltitude, float interpolatedMaxAltitude)
        {
            if (cloudTypes[cloudIndex].DensityCurve == null || cloudTypes[cloudIndex].DensityCurve.Curve.keys.Length == 0)
                return 1f;

            float minAltitude = interpolatedMinAltitude;
            float maxAltitude = interpolatedMaxAltitude;

            if (currentAltitude <= maxAltitude && currentAltitude >= minAltitude)
            {
                float t = (currentAltitude - minAltitude) / (maxAltitude - minAltitude);
                return cloudTypes[cloudIndex].DensityCurve.Evaluate(t);
            }

            return 1f;
        }

        public void UpdateShaderParams()
        {
            UpdateNoiseOffsets();

            if (shadowCasterLayerRaymarchedVolume != null)
            {
                // these may be 1-2 frames behind
                updateShadowCasterMaterialProperties(raymarchedCloudMaterial);
                updateShadowCasterMaterialProperties(reflectionProbeRaymarchedCloudMaterial);
                if (particleField != null)
                {
                    updateShadowCasterMaterialProperties(particleField.particleFieldMaterial);

                    if (particleField.particleFieldSplashesMaterial != null)
                        updateShadowCasterMaterialProperties(particleField.particleFieldSplashesMaterial);
                }
            }


            if (flowMap != null && flowMap.Texture != null)
            {
                float scaledDeltaTime = Tools.GetDeltaTime();
                raymarchedCloudMaterial.SetFloat(ShaderProperties.timeDelta_PROPERTY, scaledDeltaTime);
                reflectionProbeRaymarchedCloudMaterial.SetFloat(ShaderProperties.timeDelta_PROPERTY, scaledDeltaTime);

                flowLoopTime += scaledDeltaTime * FlowMap.Speed;
                flowLoopTime = flowLoopTime % 1;

                raymarchedCloudMaterial.SetFloat(ShaderProperties.flowLoopTime_PROPERTY, flowLoopTime);
                reflectionProbeRaymarchedCloudMaterial.SetFloat(ShaderProperties.flowLoopTime_PROPERTY, flowLoopTime);

                if (screenspaceShadowMaterial != null) screenspaceShadowMaterial.SetFloat(ShaderProperties.flowLoopTime_PROPERTY, flowLoopTime);
            }

            if (sunlight!=null)
            {
                raymarchedCloudMaterial.SetVector(ShaderProperties.SUNDIR_PROPERTY, Vector3.Normalize(-sunlight.transform.forward));
                reflectionProbeRaymarchedCloudMaterial.SetVector(ShaderProperties.SUNDIR_PROPERTY, Vector3.Normalize(-sunlight.transform.forward));
            }

            if (screenspaceShadowMaterial != null && coverageMap != null)
            {
                coverageMap.SetAlphaMask(screenspaceShadowMaterial, 1); // this gets overwritten on scaled/local changes, TODO: change the calls in here to use properties
            }

            // These are set by scatterer and can change at any moment
            var godrayStepCount = raymarchedCloudMaterial.GetFloat(ShaderProperties.godraysStepCount_PROPERTY);
            reflectionProbeRaymarchedCloudMaterial.SetFloat(ShaderProperties.godraysStepCount_PROPERTY, godrayStepCount / 5f);
        }

        private void UpdateNoiseOffsets()
        {
            double xOffset = 0.0, yOffset = 0.0, zOffset = 0.0;

            Vector3 upwardsVector = (parentTransform.position).normalized; //usually this is fine but if you see some issues add the camera
            noiseReprojectionOffset = -Tools.GetDeltaTime() * (upwardsVector * upwardsCloudSpeed);

            upwardsVector = cloudRotationMatrix.MultiplyVector(upwardsVector);

            Vector3 cloudSpaceNoiseOffset = Tools.GetDeltaTime() * (upwardsVector * upwardsCloudSpeed);

            timeXoffset += cloudSpaceNoiseOffset.x; timeYoffset += cloudSpaceNoiseOffset.y; timeZoffset += cloudSpaceNoiseOffset.z;

            xOffset += timeXoffset; yOffset += timeYoffset; zOffset += timeZoffset;

            Vector4[] baseNoiseOffsets = new Vector4[cloudTypes.Count];
            for (int i = 0; i < cloudTypes.Count; i++)
            {
                GetNoiseOffsets(xOffset, yOffset, zOffset, cloudTypes[i].BaseNoiseTiling, out baseNoiseOffsets[i]);
            }
            raymarchedCloudMaterial.SetVectorArray(ShaderProperties.baseNoiseOffsets_PROPERTY, baseNoiseOffsets);
            reflectionProbeRaymarchedCloudMaterial.SetVectorArray(ShaderProperties.baseNoiseOffsets_PROPERTY, baseNoiseOffsets);

            if (screenspaceShadowMaterial != null)
            {
                screenspaceShadowMaterial.SetVectorArray(ShaderProperties.baseNoiseOffsets_PROPERTY, baseNoiseOffsets);
            }

            if (curlNoise != null)
            {
                GetNoiseOffsets(xOffset, yOffset, zOffset, curlNoise.Tiling, out Vector4 curlNoiseOffset);
                raymarchedCloudMaterial.SetVector(ShaderProperties.curlNoiseOffset_PROPERTY, curlNoiseOffset);
                reflectionProbeRaymarchedCloudMaterial.SetVector(ShaderProperties.curlNoiseOffset_PROPERTY, curlNoiseOffset);
                if (screenspaceShadowMaterial != null) screenspaceShadowMaterial.SetVector(ShaderProperties.curlNoiseOffset_PROPERTY, curlNoiseOffset);
            }
        }

        private void GetNoiseOffsets(double xOffset, double yOffset, double zOffset, double noiseTiling, out Vector4 offset)
        {
            double noiseXOffset = xOffset / noiseTiling, noiseYOffset = yOffset / noiseTiling, noiseZOffset = zOffset / noiseTiling;

            offset = new Vector4((float)(noiseXOffset - Math.Truncate(noiseXOffset)), (float)(noiseYOffset - Math.Truncate(noiseYOffset)), (float)(noiseZOffset - Math.Truncate(noiseZOffset)));
        }

        private void updateShadowCasterMaterialProperties(Material mat)
        {
            mat.SetMatrix(ShaderProperties.shadowCasterCloudRotation_PROPERTY, shadowCasterLayerRaymarchedVolume.CloudRotationMatrix);
            mat.SetMatrix(ShaderProperties._ShadowDetailRotation_PROPERTY, shadowCasterLayerRaymarchedVolume.MainDetailRotationMatrix);
            mat.SetFloat(ShaderProperties.shadowCasterTimeFadeDensity_PROPERTY, shadowCasterLayerRaymarchedVolume.CurrentTimeFadeDensity);
            mat.SetFloat(ShaderProperties.shadowCasterTimeFadeCoverage_PROPERTY, shadowCasterLayerRaymarchedVolume.CurrentTimeFadeCoverage);
        }

        public void Remove()
        {
            if (volumeHolder != null)
            {
                volumeHolder.transform.parent = null;
                GameObject.Destroy(volumeHolder);
                volumeHolder = null;
            }

            if (particleField != null)
                particleField.Remove();

            if (droplets != null)
                droplets.Remove();

            if (wetSurfaces != null)
                wetSurfaces.Remove();

            if (ambientSound != null)
                ambientSound.Remove();

            if (coverageMap != null)
                coverageMap.Remove();
            
            if (cloudTypeMap != null)
                cloudTypeMap.Remove();

            if (CloudColorMap != null)
                cloudColorMap.Remove();

            if (flowMap != null)
                flowMap.Remove();

            if (curvesTexture != null)
                GameObject.Destroy(curvesTexture);

            if (accumulatedVerticalCoverageTexture != null)
                GameObject.Destroy(accumulatedVerticalCoverageTexture);
        }

        internal bool checkVisible (Vector3 camPos, out float scaledLayerFade)
        {
            float camAltitude = (camPos - parentTransform.position).magnitude - planetRadius;

            if (camAltitude >= scaledFadeEndAltitude || MapView.MapIsEnabled || HighLogic.LoadedScene == GameScenes.MAINMENU)
            {
                volumetricLayerScaledFade = 0f;
                scaledLayerFade = 1f;
                return false;
            }

            volumetricLayerScaledFade = 1f - (camAltitude - scaledFadeStartAltitude) / (scaledFadeEndAltitude - scaledFadeStartAltitude);
            
            scaledLayerFade = Mathf.Clamp01(4f * (1f - volumetricLayerScaledFade));                 // completely fade in the 2d layer by the first 25% of the transition
            volumetricLayerScaledFade = Mathf.Clamp01(1.33333333f * volumetricLayerScaledFade);     // fade out the volumetric layer starting from 25% to the rest of the way

            return true;
        }

        internal void UpdatePos(Vector3 WorldPos, Matrix4x4 World2Planet, QuaternionD rotation, QuaternionD detailRotation, Matrix4x4 mainRotationMatrix, Matrix4x4 inPlanetOppositeFrameDeltaRotationMatrix, Matrix4x4 inWorldOppositeFrameDeltaRotationMatrix, Matrix4x4 detailRotationMatrix)
        {
            if (HighLogic.LoadedScene == GameScenes.FLIGHT || HighLogic.LoadedScene == GameScenes.SPACECENTER)
            {
                Matrix4x4 rotationMatrix = mainRotationMatrix * World2Planet;
                Matrix4x4 mainDetailRotationMatrix = detailRotationMatrix * World2Planet;

                raymarchedCloudMaterial.SetMatrix(ShaderProperties.cloudRotation_PROPERTY, rotationMatrix);
                reflectionProbeRaymarchedCloudMaterial.SetMatrix(ShaderProperties.cloudRotation_PROPERTY, rotationMatrix);

                // raymarchedCloudMaterial.SetMatrix("invCloudRotation", rotationMatrix.inverse); // for flowmaps reprojection but it's not really working

                raymarchedCloudMaterial.SetMatrix(ShaderProperties.cloudDetailRotation_PROPERTY, mainDetailRotationMatrix);
                reflectionProbeRaymarchedCloudMaterial.SetMatrix(ShaderProperties.cloudDetailRotation_PROPERTY, mainDetailRotationMatrix);

                if (screenspaceShadowMaterial != null)
                {
                    screenspaceShadowMaterial.SetMatrix(ShaderProperties.cloudRotation_PROPERTY, rotationMatrix);
                }

                cloudRotationMatrix = rotationMatrix;
                this.mainDetailRotationMatrix = mainDetailRotationMatrix;
                worldOppositeFrameDeltaRotationMatrix = inWorldOppositeFrameDeltaRotationMatrix;
                planetOppositeFrameDeltaRotationMatrix = inPlanetOppositeFrameDeltaRotationMatrix;

                // calculate the instantaneous movement direction of the cloud at the floating origin
                Vector3 lastPosition = worldOppositeFrameDeltaRotationMatrix.MultiplyPoint(Vector3.zero);
                tangentialMovementDirection = (-lastPosition).normalized;

                if (particleField != null)
                    particleField.Update();

                if (droplets != null)
                    droplets.Update();

                if (wetSurfaces != null)
                    wetSurfaces.Update();

                if (lightning != null)
                    lightning.Update();

                if (ambientSound != null && FlightCamera.fetch != null)
                {
                    float coverageAtPosition = SampleCoverage(FlightCamera.fetch.transform.position, out float cloudType, false);
                    coverageAtPosition *= GetInterpolatedCloudTypeAmbientVolume(cloudType);
                    ambientSound.Update(coverageAtPosition);
                }
            }
        }

        internal void SetTimeFade(float currentTimeFade, TimeFadeMode mode)
        {
            if (mode == TimeFadeMode.Density)
            {
                currentTimeFadeDensity = currentTimeFade;
                raymarchedCloudMaterial.SetFloat(ShaderProperties.timeFadeDensity_PROPERTY, currentTimeFade);
                reflectionProbeRaymarchedCloudMaterial.SetFloat(ShaderProperties.timeFadeDensity_PROPERTY, currentTimeFade);
            }
            else if (mode == TimeFadeMode.Coverage)
            {
                currentTimeFadeCoverage = currentTimeFade;
                raymarchedCloudMaterial.SetFloat(ShaderProperties.timeFadeCoverage_PROPERTY, currentTimeFade);
                reflectionProbeRaymarchedCloudMaterial.SetFloat(ShaderProperties.timeFadeCoverage_PROPERTY, currentTimeFade);
            }

        }

        public float SampleCoverage(Vector3 worldPosition, out float cloudType, bool planetRadiusCheck = true)
        {
            cloudType = 0f;
            
            Vector3 sphereVector = cloudRotationMatrix.MultiplyPoint(worldPosition).normalized;

            float altitude = (worldPosition - parentTransform.position).magnitude;
            if (planetRadiusCheck && altitude < PlanetRadius) return 0f;

            float heightFraction = (altitude - innerSphereRadius) / (outerSphereRadius - innerSphereRadius);

            if (heightFraction > 1 || heightFraction < 0)
                return 0f;

            float result = 1f;
            if (coverageMap != null)
                result = coverageMap.Sample(sphereVector).a;

            if (cloudTypeMap != null)
                cloudType = cloudTypeMap.Sample(sphereVector).r;

            result *= curvesTexture.GetPixelBilinear(cloudType, heightFraction).r;

            return result * currentTimeFadeCoverage * currentTimeFadeDensity;
        }

        public float GetInterpolatedCloudTypeParticleFieldDensity(float cloudType)
        {
            int currentCloudType, nextCloudType;
            float cloudFrac = getCloudFrac(cloudType, out currentCloudType, out nextCloudType);

            return Mathf.Lerp(cloudTypes[currentCloudType].ParticleFieldDensity, cloudTypes[nextCloudType].ParticleFieldDensity, cloudFrac);
        }

        public float GetInterpolatedCloudTypeDropletsDensity(float cloudType)
        {
            int currentCloudType, nextCloudType;
            float cloudFrac = getCloudFrac(cloudType, out currentCloudType, out nextCloudType);

            return Mathf.Lerp(cloudTypes[currentCloudType].DropletsDensity, cloudTypes[nextCloudType].DropletsDensity, cloudFrac);
        }

        public float GetInterpolatedCloudTypeWetSurfacesDensity(float cloudType)
        {
            int currentCloudType, nextCloudType;
            float cloudFrac = getCloudFrac(cloudType, out currentCloudType, out nextCloudType);

            return Mathf.Lerp(cloudTypes[currentCloudType].WetSurfacesIntensity, cloudTypes[nextCloudType].WetSurfacesIntensity, cloudFrac);
        }

        public float GetInterpolatedCloudTypeLightningFrequency(float cloudType)
        {
            int currentCloudType, nextCloudType;
            float cloudFrac = getCloudFrac(cloudType, out currentCloudType, out nextCloudType);

            return Mathf.Lerp(cloudTypes[currentCloudType].LightningFrequency, cloudTypes[nextCloudType].LightningFrequency, cloudFrac);
        }

        public float GetInterpolatedCloudTypeAmbientVolume(float cloudType)
        {
            int currentCloudType, nextCloudType;
            float cloudFrac = getCloudFrac(cloudType, out currentCloudType, out nextCloudType);

            return Mathf.Lerp(cloudTypes[currentCloudType].AmbientVolume, cloudTypes[nextCloudType].AmbientVolume, cloudFrac);
        }

        private float getCloudFrac(float cloudType, out int currentCloudType, out int nextCloudType)
        {
            cloudType *= CloudTypes.Count - 1;
            currentCloudType = (int)cloudType;
            nextCloudType = Math.Min(currentCloudType + 1, CloudTypes.Count - 1);
            return cloudType - currentCloudType;
        }

        // TODO: move to utils
        private RenderTexture CreateRT(int height, int width, int volume, RenderTextureFormat format)
        {
            RenderTexture RT = new RenderTexture(height, width, 0, format);
            RT.filterMode = FilterMode.Bilinear;

            if (volume > 0)
            {
                RT.dimension = TextureDimension.Tex3D;
                RT.volumeDepth = volume;
            }

            RT.useMipMap = true;
            RT.autoGenerateMips = false;
            RT.wrapMode = TextureWrapMode.Repeat;
            RT.Create();

            return RT;
        }

        public class Updater : MonoBehaviour
        {
            public Material mat, refProbeMat;
            public Transform parent;
            public CloudsRaymarchedVolume volume;

            public void OnWillRenderObject()
            {
                Camera cam = Camera.current;
                if (!cam || !mat)
                    return;

                mat.SetVector(ShaderProperties.sphereCenter_PROPERTY, parent.position); //this needs to be moved to deferred renderer because it's needed for reconstruction
                refProbeMat.SetVector(ShaderProperties.sphereCenter_PROPERTY, parent.position); //this needs to be moved to deferred renderer because it's needed for reconstruction
            }

            public void Update()
            {
                volume.UpdateShaderParams();
            }
        }
    }
}