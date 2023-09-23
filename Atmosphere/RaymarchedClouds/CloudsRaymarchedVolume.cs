using ShaderLoader;
using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Utils;
using System.Linq;
using PQSManager;

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
        private RenderTexture baseNoiseRT, detailNoiseRT, curlNoiseRT;

        private float deTilifyBaseNoise = 1f;

        [ConfigItem]
        NoiseWrapper noise;

        [ConfigItem]
        NoiseWrapper detailNoise;

        [ConfigItem, Optional]
        CurlNoise curlNoise;

        [ConfigItem, Optional, Index(1), ValueFilter("isClamped|format|type|alphaMask")]
        TextureWrapper coverageMap;

        TextureWrapper detailTex;
        float detailScale = 0f;

        public TextureWrapper CoverageMap { get => coverageMap; }

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

        [ConfigItem, Optional]
        ParticleField particleField = null;

        [ConfigItem, Optional]
        Droplets droplets = null;

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

        float volumetricLayerScaledFade = 1.0f;

        [ConfigItem]
        float detailNoiseTiling = 1f;

        [ConfigItem]
        List<CloudType> cloudTypes = new List<CloudType> { };

        public List<CloudType> CloudTypes { get { return cloudTypes; } }

        CloudsRaymarchedVolume shadowCasterLayerRaymarchedVolume = null;

        private float flowLoopTime = 0f; 

        protected Material raymarchedCloudMaterial;
        public Material RaymarchedCloudMaterial { get => raymarchedCloudMaterial; }

        private Texture2D coverageCurvesTexture;

        private bool shadowCasterTextureSet = false;
        private bool _enabled = false;

        private float currentTimeFadeDensity = 1f;
        private float currentTimeFadeCoverage = 1f;

        Light sunlight;

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

                if (screenspaceShadowMaterial != null)
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
                }
            }
        }

        public void SetShadowCasterTextureParams(RenderTexture editorTexture = null, bool editorAlphamask = false)
        {
            if (shadowCasterLayerRaymarchedVolume?.CoverageMap != null)
            {
                setShadowCasterMaterialParams(raymarchedCloudMaterial, editorTexture, editorAlphamask);

                if (particleField != null)
                {
                    setShadowCasterMaterialParams(particleField.particleFieldMaterial, editorTexture, editorAlphamask);

                    if (particleField.particleFieldSplashesMaterial != null)
                    { 
                        setShadowCasterMaterialParams(particleField.particleFieldSplashesMaterial, editorTexture, editorAlphamask);
                    }
                }

                shadowCasterTextureSet = true;
            }
        }

        private void setShadowCasterMaterialParams(Material mat, RenderTexture editorTexture, bool editorAlphamask)
        {
            // this will break if using different map types, TODO: fix it
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

            if (shadowCasterLayerRaymarchedVolume.useDetailTex && shadowCasterLayerRaymarchedVolume.detailTex != null)
            {
                shadowCasterLayerRaymarchedVolume.detailTex.ApplyTexture(mat, "_ShadowDetailTex");
                mat.SetFloat("_ShadowDetailScale", shadowCasterLayerRaymarchedVolume.DetailScale);
                mat.EnableKeyword("CLOUD_SHADOW_CASTER_ON_DETAILTEX_ON");
                mat.DisableKeyword("CLOUD_SHADOW_CASTER_OFF");
                mat.DisableKeyword("CLOUD_SHADOW_CASTER_ON");
            }
            else
            {
                mat.DisableKeyword("CLOUD_SHADOW_CASTER_ON_DETAILTEX_ON");
                mat.DisableKeyword("CLOUD_SHADOW_CASTER_OFF");
                mat.EnableKeyword("CLOUD_SHADOW_CASTER_ON");
            }
        }

        float planetRadius, innerSphereRadius, outerSphereRadius, cloudMinAltitude, cloudMaxAltitude;
        public float InnerSphereRadius { get => innerSphereRadius;}
        public float OuterSphereRadius { get => outerSphereRadius; }
        public float PlanetRadius { get => planetRadius; }
        
        Transform parentTransform;
        public Transform ParentTransform { get => parentTransform; }

        private double timeXoffset = 0.0, timeYoffset = 0.0, timeZoffset = 0.0;

        private Matrix4x4 oppositeFrameDeltaRotationMatrix = Matrix4x4.identity;
        public Matrix4x4 OppositeFrameDeltaRotationMatrix { get => oppositeFrameDeltaRotationMatrix; }

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

        public void Apply(CloudsMaterial material, float cloudLayerRadius, Transform parent, float parentRadius, CelestialBody celestialBody, Clouds2D layer2d)
        {
            parentCelestialBody = celestialBody;

            planetRadius = parentRadius;
            parentTransform = parent;

            raymarchedCloudMaterial = new Material(RaymarchedCloudShader);
            screenspaceShadowMaterial = layer2d?.ScreenSpaceShadow?.material;

            RenderNoiseTextures();
            ProcessCloudTypes();

            SetShaderParams(raymarchedCloudMaterial, material, celestialBody);
            if (screenspaceShadowMaterial != null)
            {
                SetShaderParams(screenspaceShadowMaterial, material, celestialBody);
                screenspaceShadowMaterial.EnableKeyword("VOLUMETRIC_CLOUD_SHADOW_ON");
                screenspaceShadowMaterial.DisableKeyword("VOLUMETRIC_CLOUD_SHADOW_OFF");
                screenspaceShadowMaterial.SetTexture("DensityCurve", Texture2D.whiteTexture);
            }

            volumeHolder = GameObject.CreatePrimitive(PrimitiveType.Quad);
            volumeHolder.name = "CloudsRaymarchedVolume";
            GameObject.Destroy(volumeHolder.GetComponent<Collider>());

            var volumeUpdater = volumeHolder.AddComponent<Updater>();
            volumeUpdater.volume = this;
            volumeUpdater.mat = raymarchedCloudMaterial;
            volumeUpdater.parent = parentTransform;

            var volumeNotifier = volumeHolder.AddComponent<DeferredRaymarchedRendererNotifier>();
            volumeNotifier.volume = this;

            volumeMeshrenderer = volumeHolder.GetComponent<MeshRenderer>();
            volumeMeshrenderer.material = new Material(InvisibleShader);
            
            raymarchedCloudMaterial.SetMatrix(ShaderProperties._ShadowBodies_PROPERTY, Matrix4x4.zero); // TODO eclipses

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
                if(!particleField.Apply(parent, celestialBody, this))
                {
                    particleField.Remove();
                    particleField = null;
                }
            }

            if (droplets != null)
            {
                if (!droplets.Apply(parent, celestialBody, this))
                {
                    droplets.Remove();
                    droplets = null;
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
        }

        public void RenderNoiseTextures()
        {
            if (noise != null && noise.GetNoiseMode() != NoiseMode.None)
            {
                baseNoiseRT = CreateRT(baseNoiseDimension, baseNoiseDimension, baseNoiseDimension, RenderTextureFormat.R8);
                CloudNoiseGen.RenderNoiseToTexture(baseNoiseRT, noise);

                if (detailNoise != null && detailNoise.GetNoiseMode() != NoiseMode.None)
                {
                    detailNoiseRT = CreateRT(baseNoiseDimension, baseNoiseDimension, baseNoiseDimension, RenderTextureFormat.R8);
                    CloudNoiseGen.RenderNoiseToTexture(detailNoiseRT, detailNoise);
                }
            }

            if (curlNoise != null)
            {
                curlNoiseRT = CreateRT(baseNoiseDimension, baseNoiseDimension, baseNoiseDimension, RenderTextureFormat.RGB565);
                CloudNoiseGen.RenderCurlNoiseToTexture(curlNoiseRT, curlNoise.ToNoiseSettings());
            }
        }

        public void SetShaderTextureParams(Material mat, CloudsMaterial material)
        {
            if (noise != null && noise.GetNoiseMode() != NoiseMode.None && baseNoiseRT != null)
            { 
                mat.SetTexture("BaseNoiseTexture", baseNoiseRT);
                mat.EnableKeyword("NOISE_ON"); mat.DisableKeyword("NOISE_OFF");

                if (detailNoise != null && detailNoise.GetNoiseMode() != NoiseMode.None && detailNoiseRT != null)
                {
                    mat.SetTexture("DetailNoiseTexture", detailNoiseRT);
                }
                else
                {
                    mat.SetTexture("DetailNoiseTexture", baseNoiseRT);
                }
            }
            else
            {
                mat.EnableKeyword("NOISE_OFF"); mat.DisableKeyword("NOISE_ON");
            }

            if (curlNoise != null && curlNoiseRT!= null)
            {
                mat.SetTexture("CurlNoiseTexture", curlNoiseRT);
                mat.EnableKeyword("CURL_NOISE_ON"); mat.DisableKeyword("CURL_NOISE_OFF");
                mat.SetFloat("smoothCurlNoise", curlNoise.Smooth ? 1f : 0f);
            }
            else
            {
                mat.EnableKeyword("CURL_NOISE_OFF"); mat.DisableKeyword("CURL_NOISE_ON");
            }

            if (coverageMap != null)
            {
                coverageMap.ApplyTexture(mat, "CloudCoverage", 1);
            }
            else
            {
                mat.SetTexture("CloudCoverage", Texture2D.whiteTexture);
                mat.EnableKeyword("MAP_TYPE_1");
            }

            ApplyCloudTexture(cloudTypeMap, "CloudType", mat, 2);

            if (cloudColorMap!= null)
            {
                mat.EnableKeyword("COLORMAP_ON"); mat.DisableKeyword("COLORMAP_OFF");
                ApplyCloudTexture(cloudColorMap, "CloudColorMap", mat, 4);
            }
            else
            { 
                mat.EnableKeyword("COLORMAP_OFF"); mat.DisableKeyword("COLORMAP_ON");
            }

            if (useDetailTex && material.DetailTex != null)
            {
                detailTex = material.DetailTex;
                detailScale = material.DetailScale;
                material.DetailTex.ApplyTexture(mat, "_DetailTex");
                mat.SetFloat("_DetailScale", material.DetailScale);
                mat.EnableKeyword("DETAILTEX_ON"); mat.DisableKeyword("DETAILTEX_OFF");
            }
            else
            {
                mat.EnableKeyword("DETAILTEX_OFF"); mat.DisableKeyword("DETAILTEX_ON");
            }

            if (flowMap != null && flowMap.Texture != null)
            {
                mat.EnableKeyword("FLOWMAP_ON");
                mat.DisableKeyword("FLOWMAP_OFF");
                flowMap.Texture.ApplyTexture(mat, "_FlowMap", 999);
                mat.SetFloat("_flowStrength", flowMap.Displacement);
                mat.SetFloat("_flowSpeed", flowMap.Speed);
            }
            else
            {
                mat.EnableKeyword("FLOWMAP_OFF");
                mat.DisableKeyword("FLOWMAP_ON");
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

        public void SetShaderParams(Material mat, CloudsMaterial material, CelestialBody celestialBody)
        {
            SetShaderTextureParams(mat, material);
            SetCloudTypesShaderParams(mat);

            mat.SetFloat("useBodyRadiusIntersection", PQSManagerClass.HasRealPQS(celestialBody) ? 1f : 0f);

            mat.SetTexture("StbnBlueNoise", ShaderLoader.ShaderLoaderClass.stbn);
            mat.SetVector("stbnDimensions", new Vector3(ShaderLoader.ShaderLoaderClass.stbnDimensions.x, ShaderLoader.ShaderLoaderClass.stbnDimensions.y, ShaderLoader.ShaderLoaderClass.stbnDimensions.z));

            mat.SetColor("cloudColor", Tools.IsColorRGB(color) ? color / 255f : color);

            mat.SetFloat("detailTiling", 1f / detailNoiseTiling);
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
            mat.SetFloat("stepSizeLight", raymarchingSettings.LightMarchDistance / (int)raymarchingSettings.LightMarchSteps);

            Texture2D tex = GameDatabase.Instance.GetTexture("EnvironmentalVisualEnhancements/Blue16b", false); //TODO: remove/replace with lower res texture?
            mat.SetTexture("BlueNoise", tex);
            mat.SetFloat("deTilifyBaseNoise", deTilifyBaseNoise * 0.01f);
            mat.SetFloat("skylightMultiplier", skylightMultiplier);
            mat.SetFloat("skylightTintMultiplier", skylightTintMultiplier);
            mat.SetFloat("shadowCasterDensity", receivedShadowsDensity);

            mat.EnableKeyword("CLOUD_SHADOW_CASTER_OFF");
            mat.DisableKeyword("CLOUD_SHADOW_CASTER_ON");

            mat.SetFloat("timeFadeDensity", 1f);
            mat.SetFloat("timeFadeCoverage", 1f);

            if (RaymarchedCloudsQualityManager.NonTiling3DNoise && (flowMap == null || flowMap.KeepUntilingOnNoFlowAreas))
            {
                mat.EnableKeyword("NOISE_UNTILING_ON");mat.DisableKeyword("NOISE_UNTILING_OFF");
            }
            else
            {
                mat.EnableKeyword("NOISE_UNTILING_OFF"); mat.DisableKeyword("NOISE_UNTILING_ON");
            }

            mat.DisableKeyword("CLOUD_SHADOW_CASTER_ON_DETAILTEX_ON");
            mat.DisableKeyword("CLOUD_SHADOW_CASTER_ON");
            mat.EnableKeyword("CLOUD_SHADOW_CASTER_OFF");
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

            coverageCurvesTexture = BakeCoverageCurvesTexture();
        }

        private void SetCloudTypesShaderParams(Material mat)
        {
            mat.SetFloat("innerSphereRadius", innerSphereRadius);
            mat.SetFloat("outerSphereRadius", outerSphereRadius);

            mat.SetFloat("layerHeight", outerSphereRadius - innerSphereRadius);
            mat.SetFloat("invLayerHeight", 1f / (outerSphereRadius - innerSphereRadius));

            mat.SetTexture("DensityCurve", coverageCurvesTexture);

            Vector4[] cloudTypePropertiesArray0 = new Vector4[cloudTypes.Count];

            Vector2 minMaxNoiseTilings = new Vector2(1f / detailNoiseTiling, 1f / detailNoiseTiling);

            for (int i = 0; i < cloudTypes.Count; i++)
            {
                cloudTypePropertiesArray0[i] = new Vector4(cloudTypes[i].Density, 1f / cloudTypes[i].BaseNoiseTiling, cloudTypes[i].DetailNoiseStrength, 0f);

                minMaxNoiseTilings = new Vector2(Mathf.Min(minMaxNoiseTilings.x, 1f / cloudTypes[i].BaseNoiseTiling), Mathf.Max(minMaxNoiseTilings.y, 1f / cloudTypes[i].BaseNoiseTiling));
            }

            if (curlNoise != null)
            {
                minMaxNoiseTilings = new Vector2(Mathf.Min(minMaxNoiseTilings.x, 1f / curlNoise.Tiling), Mathf.Max(minMaxNoiseTilings.y, 1f / curlNoise.Tiling));
            }

            mat.SetVectorArray("cloudTypeProperties0", cloudTypePropertiesArray0);
            mat.SetInt("numberOfCloudTypes", cloudTypes.Count);
            mat.SetFloat("planetRadius", planetRadius);

            mat.SetVector("minMaxNoiseTilings", minMaxNoiseTilings);
        }

        private Texture2D BakeCoverageCurvesTexture()
        {
            int resolution = 128;

            if (cloudTypes.Count == 0)
                return Texture2D.whiteTexture;

            Texture2D tex = new Texture2D(resolution, resolution, TextureFormat.ARGB32, false);

            tex.filterMode = FilterMode.Bilinear;
            tex.wrapMode = TextureWrapMode.Clamp;

            Color[] colors = new Color[resolution * resolution];

            for (int x = 0; x < resolution; x++)
            {
                // find where we are and the two curves to interpolate
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
                    float result = Mathf.Lerp(EvaluateCloudValue(currentCloudType, currentAltitude, interpolatedMinAltitude, interpolatedMaxAltitude),
                                                EvaluateCloudValue(nextCloudType, currentAltitude, interpolatedMinAltitude, interpolatedMaxAltitude),
                                                cloudFrac);
                    
                    // We want to compress to BC4 which doesn't work unless we compress to BC3 and extract the alpha channel, and that also doesn't work unless you set both alpha and another channel
                    colors[x + y * resolution].r = result;
                    colors[x + y * resolution].a = result;
                }

            }

            tex.SetPixels(colors);
            tex.Apply(false);

            tex.Compress(true); // this compresses a color image to BC3, compressing R8 directly to BC4 doesn't work

            var texBC4 = TextureConverter.ExtractBC4TextureFromBC3Alpha(tex);

            GameObject.Destroy(tex);

            return texBC4;
        }

        private float EvaluateCloudValue(int cloudIndex, float currentAltitude, float interpolatedMinAltitude, float interpolatedMaxAltitude)
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

        public void UpdateShaderParams()
        {
            UpdateNoiseOffsets();

            if (shadowCasterLayerRaymarchedVolume != null)
            {
                // these may be 1-2 frames behind
                updateShadowCasterMaterialProperties(raymarchedCloudMaterial);
                if (particleField != null)
                {
                    updateShadowCasterMaterialProperties(particleField.particleFieldMaterial);

                    if (particleField.particleFieldSplashesMaterial != null)
                        updateShadowCasterMaterialProperties(particleField.particleFieldSplashesMaterial);
                }
            }


            if (flowMap != null && flowMap.Texture != null)
            {
                float scaledDeltaTime = Tools.getDeltaTime();
                raymarchedCloudMaterial.SetFloat(ShaderProperties.timeDelta_PROPERTY, scaledDeltaTime);

                flowLoopTime += scaledDeltaTime * FlowMap.Speed;
                flowLoopTime = flowLoopTime % 1;

                raymarchedCloudMaterial.SetFloat(ShaderProperties.flowLoopTime_PROPERTY, flowLoopTime);

                if (screenspaceShadowMaterial != null) screenspaceShadowMaterial.SetFloat(ShaderProperties.flowLoopTime_PROPERTY, flowLoopTime);
            }

            if (sunlight!=null)
            {
                raymarchedCloudMaterial.SetVector(ShaderProperties.SUNDIR_PROPERTY, Vector3.Normalize(-sunlight.transform.forward));
            }

            if (screenspaceShadowMaterial != null && coverageMap != null)
            {
                coverageMap.SetAlphaMask(screenspaceShadowMaterial, 1); // this gets overwritten on scaled/local changes, TODO: change the calls in here to use properties
            }
        }

        private void UpdateNoiseOffsets()
        {
            double xOffset = 0.0, yOffset = 0.0, zOffset = 0.0;

            Vector3 upwardsVector = (parentTransform.position).normalized; //usually this is fine but if you see some issues add the camera
            noiseReprojectionOffset = -Tools.getDeltaTime() * (upwardsVector * upwardsCloudSpeed);

            upwardsVector = cloudRotationMatrix.MultiplyVector(upwardsVector);

            Vector3 cloudSpaceNoiseOffset = Tools.getDeltaTime() * (upwardsVector * upwardsCloudSpeed);

            timeXoffset += cloudSpaceNoiseOffset.x; timeYoffset += cloudSpaceNoiseOffset.y; timeZoffset += cloudSpaceNoiseOffset.z;

            xOffset += timeXoffset; yOffset += timeYoffset; zOffset += timeZoffset;

            Vector4[] baseNoiseOffsets = new Vector4[cloudTypes.Count];
            Vector4[] noTileNoiseOffsets = new Vector4[cloudTypes.Count];
            for (int i = 0; i < cloudTypes.Count; i++)
            {
                GetNoiseOffsets(xOffset, yOffset, zOffset, cloudTypes[i].BaseNoiseTiling, out baseNoiseOffsets[i], out noTileNoiseOffsets[i]);
            }
            raymarchedCloudMaterial.SetVectorArray(ShaderProperties.baseNoiseOffsets_PROPERTY, baseNoiseOffsets);
            raymarchedCloudMaterial.SetVectorArray(ShaderProperties.noTileNoiseOffsets_PROPERTY, noTileNoiseOffsets);

            GetNoiseOffsets(xOffset, yOffset, zOffset, detailNoiseTiling, out Vector4 detailOffset, out Vector4 noTileNoiseDetailOffset);
            raymarchedCloudMaterial.SetVector(ShaderProperties.detailOffset_PROPERTY, detailOffset);
            raymarchedCloudMaterial.SetVector(ShaderProperties.noTileNoiseDetailOffset_PROPERTY, noTileNoiseDetailOffset);

            if (screenspaceShadowMaterial != null)
            {
                screenspaceShadowMaterial.SetVectorArray(ShaderProperties.baseNoiseOffsets_PROPERTY, baseNoiseOffsets);
                screenspaceShadowMaterial.SetVectorArray(ShaderProperties.noTileNoiseOffsets_PROPERTY, noTileNoiseOffsets);
                screenspaceShadowMaterial.SetVector(ShaderProperties.detailOffset_PROPERTY, detailOffset);
                screenspaceShadowMaterial.SetVector(ShaderProperties.noTileNoiseDetailOffset_PROPERTY, noTileNoiseDetailOffset);
            }

            if (curlNoise != null)
            {
                GetNoiseOffsets(xOffset, yOffset, zOffset, curlNoise.Tiling, out Vector4 curlNoiseOffset, out Vector4 noTileCurlNoiseOffset);
                raymarchedCloudMaterial.SetVector(ShaderProperties.curlNoiseOffset_PROPERTY, curlNoiseOffset);
                if (screenspaceShadowMaterial != null) screenspaceShadowMaterial.SetVector(ShaderProperties.curlNoiseOffset_PROPERTY, curlNoiseOffset);
            }
        }

        private void GetNoiseOffsets(double xOffset, double yOffset, double zOffset, double noiseTiling, out Vector4 offset, out Vector4 noTileOffset)
        {
            double noiseXOffset = xOffset / noiseTiling, noiseYOffset = yOffset / noiseTiling, noiseZOffset = zOffset / noiseTiling;

            offset = new Vector4((float)(noiseXOffset - Math.Truncate(noiseXOffset)), (float)(noiseYOffset - Math.Truncate(noiseYOffset)), (float)(noiseZOffset - Math.Truncate(noiseZOffset)));

            noiseXOffset = (xOffset * deTilifyBaseNoise * 0.01) / ((double)noiseTiling);
            noiseYOffset = (yOffset * deTilifyBaseNoise * 0.01) / ((double)noiseTiling);
            noiseZOffset = (zOffset * deTilifyBaseNoise * 0.01) / ((double)noiseTiling);

            noTileOffset = new Vector4((float)(noiseXOffset - Math.Truncate(noiseXOffset)), (float)(noiseYOffset - Math.Truncate(noiseYOffset)), (float)(noiseZOffset - Math.Truncate(noiseZOffset)));
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

        internal void UpdatePos(Vector3 WorldPos, Matrix4x4 World2Planet, QuaternionD rotation, QuaternionD detailRotation, Matrix4x4 mainRotationMatrix, Matrix4x4 inOppositeFrameDeltaRotationMatrix, Matrix4x4 detailRotationMatrix)
        {
            if (HighLogic.LoadedScene == GameScenes.FLIGHT || HighLogic.LoadedScene == GameScenes.SPACECENTER)
            {
                Matrix4x4 rotationMatrix = mainRotationMatrix * World2Planet;
                Matrix4x4 mainDetailRotationMatrix = detailRotationMatrix * World2Planet;

                raymarchedCloudMaterial.SetMatrix(ShaderProperties.cloudRotation_PROPERTY, rotationMatrix);

                // raymarchedCloudMaterial.SetMatrix("invCloudRotation", rotationMatrix.inverse); // for flowmaps reprojection but it's not really working

                raymarchedCloudMaterial.SetMatrix(ShaderProperties.cloudDetailRotation_PROPERTY, mainDetailRotationMatrix);

                if (screenspaceShadowMaterial != null)
                {
                    screenspaceShadowMaterial.SetMatrix(ShaderProperties.cloudRotation_PROPERTY, rotationMatrix);
                }

                cloudRotationMatrix = rotationMatrix;
                this.mainDetailRotationMatrix = mainDetailRotationMatrix;
                oppositeFrameDeltaRotationMatrix = inOppositeFrameDeltaRotationMatrix;

                // calculate the instantaneous movement direction of the cloud at the floating origin
                Vector3 lastPosition = oppositeFrameDeltaRotationMatrix.MultiplyPoint(Vector3.zero);
                tangentialMovementDirection = (-lastPosition).normalized;

                if (particleField != null) particleField.Update();

                if (droplets != null) droplets.Update();

                if (lightning != null) lightning.Update();

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
            }
            else if (mode == TimeFadeMode.Coverage)
            {
                currentTimeFadeCoverage = currentTimeFade;
                raymarchedCloudMaterial.SetFloat(ShaderProperties.timeFadeCoverage_PROPERTY, currentTimeFade);
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

            result *= coverageCurvesTexture.GetPixelBilinear(cloudType, heightFraction).r;

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
            public Material mat;
            public Transform parent;
            public CloudsRaymarchedVolume volume;

            public void OnWillRenderObject()
            {
                Camera cam = Camera.current;
                if (!cam || !mat)
                    return;

                mat.SetVector(ShaderProperties.sphereCenter_PROPERTY, parent.position); //this needs to be moved to deferred renderer because it's needed for reconstruction
            }

            public void Update()
            {
                volume.UpdateShaderParams();
            }
        }
    }
}