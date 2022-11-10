using ShaderLoader;
using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Utils;

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
        private RenderTexture baseNoiseRT;

        private float deTilifyBaseNoise = 1f;

        [ConfigItem]
        NoiseWrapper noise;

        [ConfigItem, Optional, Index(1), ValueFilter("isClamped|format|type|alphaMask")]
        TextureWrapper coverageMap;

        public TextureWrapper CoverageMap { get => coverageMap; }

        [ConfigItem, Optional, Index(1), ValueFilter("isClamped|format|type|alphaMask")]
        TextureWrapper cloudTypeMap;

        [ConfigItem]
        RaymarchingSettings raymarchingSettings = new RaymarchingSettings();

        [ConfigItem]
        Color color = Color.white;
        [ConfigItem]
        float absorptionMultiplier = 1.0f;
        [ConfigItem]
        float skylightMultiplier = 1.0f;

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

        float volumetricLayerScaledFade = 1.0f;

        //[ConfigItem]
        //float curlNoiseTiling = 1f;
        //[ConfigItem]
        //float curlNoiseStrength = 1f;

        //potentially move these to be per cloud type as well?

        [ConfigItem]
        float detailNoiseTiling = 1f;
        [ConfigItem]
        float detailNoiseStrength = 1f;
        //[ConfigItem]
        //float secondaryNoiseGradient = 1f;

        [ConfigItem]
        List<CloudType> cloudTypes = new List<CloudType> { };

        CloudsRaymarchedVolume shadowCasterLayerRaymarchedVolume = null;

        ///////////

        protected Material raymarchedCloudMaterial;
        public Material RaymarchedCloudMaterial { get => raymarchedCloudMaterial; }

        private Texture coverageCurvesTexture;

        private bool shadowCasterTextureSet = false;
        private bool _enabled = false;

        private float currentTimeFadeDensity = 1f;
        private float currentTimeFadeCoverage = 1f;

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
            }
        }

        private void SetShadowCasterTextureParams()
        {
            if (shadowCasterLayerRaymarchedVolume?.CoverageMap != null)
            {
                // this will break if using different map types, TODO: fix it
                shadowCasterLayerRaymarchedVolume.CoverageMap.ApplyTexture(raymarchedCloudMaterial, "ShadowCasterCloudCoverage");
                raymarchedCloudMaterial.EnableKeyword("CLOUD_SHADOW_CASTER_ON");
                raymarchedCloudMaterial.DisableKeyword("CLOUD_SHADOW_CASTER_OFF");
                raymarchedCloudMaterial.SetFloat("shadowCasterSphereRadius", shadowCasterLayerRaymarchedVolume.InnerSphereRadius);

                shadowCasterTextureSet = true;
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

        Matrix4x4 cloudRotationMatrix = Matrix4x4.identity;
        public Matrix4x4 CloudRotationMatrix { get => cloudRotationMatrix; }
        public float VolumetricLayerScaledFade { get => volumetricLayerScaledFade; }
        public float CurrentTimeFadeDensity { get => currentTimeFadeDensity; }
        public float CurrentTimeFadeCoverage { get => currentTimeFadeCoverage; }

        private MeshRenderer volumeMeshrenderer;

        public void Apply(CloudsMaterial material, float cloudLayerRadius, Transform parent, float parentRadius)
        {
            planetRadius = parentRadius;
            parentTransform = parent;

            raymarchedCloudMaterial = new Material(RaymarchedCloudShader);

            raymarchedCloudMaterial.SetTexture("StbnBlueNoise", ShaderLoader.ShaderLoaderClass.stbn);
            raymarchedCloudMaterial.SetFloat("blueNoiseResolution", ShaderLoader.ShaderLoaderClass.stbnDimensions.x);
            raymarchedCloudMaterial.SetFloat("blueNoiseSlices", ShaderLoader.ShaderLoaderClass.stbnDimensions.z);

            ConfigureTextures();

            ProcessCloudTypes();

            SetShaderParams(raymarchedCloudMaterial);

            Remove();

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

            SetShadowCasterTextureParams();
        }

        public void ConfigureTextures()
        {
            if (noise != null && noise.GetNoiseMode() != NoiseMode.None)
            { 
                baseNoiseRT = CreateRT(baseNoiseDimension, baseNoiseDimension, baseNoiseDimension, RenderTextureFormat.R8);
                CloudNoiseGen.RenderNoiseToTexture(baseNoiseRT, noise);
                raymarchedCloudMaterial.SetTexture("BaseNoiseTexture", baseNoiseRT);
                raymarchedCloudMaterial.EnableKeyword("NOISE_ON"); raymarchedCloudMaterial.DisableKeyword("NOISE_OFF");
            }
            else
            {
                raymarchedCloudMaterial.EnableKeyword("NOISE_OFF"); raymarchedCloudMaterial.DisableKeyword("NOISE_ON");
            }

            if (coverageMap != null)    //have to apply this last because it sets the MAP type keywords
            {
                coverageMap.ApplyTexture(raymarchedCloudMaterial, "CloudCoverage");
            }
            else
            {
                raymarchedCloudMaterial.SetTexture("CloudCoverage", Texture2D.whiteTexture);
                raymarchedCloudMaterial.EnableKeyword("MAP_TYPE_1");
            }

            ApplyCloudTexture(cloudTypeMap, "CloudType", raymarchedCloudMaterial);
        }

        public void SetShadowCasterLayerRaymarchedVolume(CloudsRaymarchedVolume cloudsRaymarchedVolume)
        {
            if (cloudsRaymarchedVolume != null)
                shadowCasterLayerRaymarchedVolume = cloudsRaymarchedVolume;
        }

        private void ApplyCloudTexture(TextureWrapper cloudTexture, string propertyName, Material mat)
        {
            if (cloudTexture != null)
            {
                cloudTexture.ApplyTexture(mat, propertyName);
            }
            else
            {
                mat.SetTexture(propertyName, Texture2D.whiteTexture);
            }
        }

        private void GenerateAndAssignTexture(NoiseWrapper noiseWrapper, string propertyName, Material mat)
        {
            RenderTexture rt = CreateRT(512, 512, 0, RenderTextureFormat.R8);
            CloudNoiseGen.RenderNoiseToTexture(rt, noiseWrapper);
            //var tex = TextureUtils.CompressSingleChannelRenderTextureToBC4(LocalCoverage, true);	//compress to BC4, increases fps a tiny bit, just disabled for now because it's slow
                                                                                                    //delete this because it doesn't work in 3d and I removed every 2d case
            mat.SetTexture(propertyName, rt);
        }

        public void SetShaderParams(Material mat)
        {
            mat.SetColor("cloudColor", color);

            mat.SetFloat("detailTiling", 1f / detailNoiseTiling);
            mat.SetFloat("detailStrength", detailNoiseStrength);
            //mat.SetFloat("detailHeightGradient", secondaryNoiseGradient);
            mat.SetFloat("absorptionMultiplier", absorptionMultiplier);
            mat.SetFloat("lightMarchAttenuationMultiplier", 1.0f);

            mat.SetFloat("baseStepSize", raymarchingSettings.BaseStepSize);
            mat.SetFloat("maxStepSize", raymarchingSettings.MaxStepSize);
            mat.SetFloat("adaptiveStepSizeFactor", raymarchingSettings.AdaptiveStepSizeFactor);

            mat.SetFloat("lightMarchDistance", raymarchingSettings.LightMarchDistance);
            mat.SetInt("lightMarchSteps", (int)raymarchingSettings.LightMarchSteps);

            Texture2D tex = GameDatabase.Instance.GetTexture("EnvironmentalVisualEnhancements/Blue16b", false); //TODO: remove/replace with lower res texture?
            mat.SetTexture("BlueNoise", tex);
            mat.SetFloat("deTilifyBaseNoise", deTilifyBaseNoise * 0.01f);
            mat.SetFloat("skylightMultiplier", skylightMultiplier);
            mat.SetFloat("shadowCasterDensity", receivedShadowsDensity);

            mat.EnableKeyword("CLOUD_SHADOW_CASTER_OFF");
            mat.DisableKeyword("CLOUD_SHADOW_CASTER_ON");

            mat.SetFloat("timeFadeDensity", 1f);
            mat.SetFloat("timeFadeCoverage", 1f);
        }

        private void ProcessCloudTypes()
        {
            cloudMinAltitude = Mathf.Infinity;
            cloudMaxAltitude = 0f;

            for (int i = 0; i < cloudTypes.Count; i++)
            {
                cloudMinAltitude = Mathf.Min(cloudMinAltitude, cloudTypes[i].MinAltitude);
                cloudMaxAltitude = Mathf.Max(cloudMaxAltitude, cloudTypes[i].MaxAltitude);
            }

            innerSphereRadius = planetRadius + cloudMinAltitude;
            outerSphereRadius = planetRadius + cloudMaxAltitude;

            raymarchedCloudMaterial.SetFloat("innerSphereRadius", innerSphereRadius);
            raymarchedCloudMaterial.SetFloat("outerSphereRadius", outerSphereRadius);

            coverageCurvesTexture = BakeCoverageCurvesTexture();
            raymarchedCloudMaterial.SetTexture("DensityCurve", coverageCurvesTexture);

            Vector4[] cloudTypePropertiesArray0 = new Vector4[cloudTypes.Count];
            Vector4[] cloudTypePropertiesArray1 = new Vector4[cloudTypes.Count];

            Vector2 minMaxNoiseTilings = new Vector2(1f / detailNoiseTiling, 1f / detailNoiseTiling);

            for (int i = 0; i < cloudTypes.Count; i++)
            {
                cloudTypePropertiesArray0[i] = new Vector4(cloudTypes[i].Density, 1f / cloudTypes[i].BaseNoiseTiling, 0f, 0f);
                cloudTypePropertiesArray1[i] = new Vector4(0f, 0f, 0f, 0f);

                minMaxNoiseTilings = new Vector2(Mathf.Min(minMaxNoiseTilings.x, 1f / cloudTypes[i].BaseNoiseTiling), Mathf.Max(minMaxNoiseTilings.y, 1f / cloudTypes[i].BaseNoiseTiling));
            }
            raymarchedCloudMaterial.SetVectorArray("cloudTypeProperties0", cloudTypePropertiesArray0);
            raymarchedCloudMaterial.SetVectorArray("cloudTypeProperties1", cloudTypePropertiesArray1);
            raymarchedCloudMaterial.SetInt("numberOfCloudTypes", cloudTypes.Count);
            raymarchedCloudMaterial.SetFloat("planetRadius", planetRadius);

            raymarchedCloudMaterial.SetVector("minMaxNoiseTilings", minMaxNoiseTilings);
        }

        private Texture2D BakeCoverageCurvesTexture()
        {
            int resolution = 128;

            if (cloudTypes.Count == 0)
                return Texture2D.whiteTexture;

            Texture2D tex = new Texture2D(resolution, resolution, TextureFormat.R8, false);

            tex.filterMode = FilterMode.Bilinear;
            tex.wrapMode = TextureWrapMode.Clamp; //will need to pass this to the compressor script after

            Color[] colors = new Color[resolution * resolution];

            for (int x = 0; x < resolution; x++)
            {
                // find where we are and the two curves to interpolate
                float cloudTypeIndex = (float)x / (float)resolution;
                cloudTypeIndex *= cloudTypes.Count - 1;
                int currentCloudType = (int)cloudTypeIndex;
                int nextCloudType = Math.Min(currentCloudType + 1, cloudTypes.Count - 1);
                float cloudFrac = cloudTypeIndex - currentCloudType;

                float interpolatedMinAltitude = Mathf.Lerp(cloudTypes[currentCloudType].MinAltitude, cloudTypes[nextCloudType].MinAltitude, cloudFrac);
                float interpolatedMaxAltitude = Mathf.Lerp(cloudTypes[currentCloudType].MaxAltitude, cloudTypes[nextCloudType].MaxAltitude, cloudFrac);

                for (int y = 0; y < resolution; y++)
                {
                    float currentAltitude = Mathf.Lerp(cloudMinAltitude, cloudMaxAltitude, (float)y / resolution);
                    colors[x + y * resolution].r = Mathf.Lerp(EvaluateCloudValue(currentCloudType, currentAltitude, interpolatedMinAltitude, interpolatedMaxAltitude),
                                        EvaluateCloudValue(nextCloudType, currentAltitude, interpolatedMinAltitude, interpolatedMaxAltitude),
                                        cloudFrac);
                }

            }

            tex.SetPixels(colors);
            tex.Apply(false);

            return tex;
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

        // TODO: refactor/simplify
        // TODO: shader params
        public void UpdateCloudNoiseOffsets()
        {
            double xOffset = 0.0, yOffset = 0.0, zOffset = 0.0;

            Vector3 upwardsVector = (parentTransform.position).normalized; //usually this is fine but if you see some issues add the camera
            noiseReprojectionOffset = -upwardsVector * Time.deltaTime * TimeWarp.CurrentRate * upwardsCloudSpeed;

            upwardsVector = cloudRotationMatrix.MultiplyVector(upwardsVector);

            Vector3 cloudSpaceNoiseReprojectionOffset = upwardsVector * Time.deltaTime * TimeWarp.CurrentRate * upwardsCloudSpeed;

            timeXoffset += cloudSpaceNoiseReprojectionOffset.x; timeYoffset += cloudSpaceNoiseReprojectionOffset.y; timeZoffset += cloudSpaceNoiseReprojectionOffset.z;

            xOffset += timeXoffset; yOffset += timeYoffset; zOffset += timeZoffset;

            Vector4[] baseNoiseOffsets   = new Vector4[cloudTypes.Count];
            Vector4[] noTileNoiseOffsets = new Vector4[cloudTypes.Count];
            for (int i = 0; i < cloudTypes.Count; i++)
            {
                double noiseXOffset = xOffset / (double)cloudTypes[i].BaseNoiseTiling, noiseYOffset = yOffset / (double)cloudTypes[i].BaseNoiseTiling, noiseZOffset = zOffset / (double)cloudTypes[i].BaseNoiseTiling;

                baseNoiseOffsets[i] = new Vector4((float)(noiseXOffset - Math.Truncate(noiseXOffset)), (float) (noiseYOffset - Math.Truncate(noiseYOffset)),
                    (float) (noiseZOffset - Math.Truncate(noiseZOffset)), 0f);

                double noTileXOffset = (xOffset * deTilifyBaseNoise * 0.01) / ((double)cloudTypes[i].BaseNoiseTiling);
                double noTileYOffset = (yOffset * deTilifyBaseNoise * 0.01) / ((double)cloudTypes[i].BaseNoiseTiling);
                double noTileZOffset = (zOffset * deTilifyBaseNoise * 0.01) / ((double)cloudTypes[i].BaseNoiseTiling);

                noTileNoiseOffsets[i] = new Vector4((float)(noTileXOffset - Math.Truncate(noTileXOffset)), (float)(noTileYOffset - Math.Truncate(noTileYOffset)),
                    (float)(noTileZOffset - Math.Truncate(noTileZOffset)), 0f);
            }
            raymarchedCloudMaterial.SetVectorArray("baseNoiseOffsets", baseNoiseOffsets);
            raymarchedCloudMaterial.SetVectorArray("noTileNoiseOffsets", noTileNoiseOffsets);

            double detailXOffset = xOffset / (double) detailNoiseTiling, detailYOffset = yOffset / (double)detailNoiseTiling, detailZOffset = zOffset / (double)detailNoiseTiling;

            raymarchedCloudMaterial.SetVector("detailOffset", new Vector4((float)(detailXOffset - Math.Truncate(detailXOffset)),
                (float)(detailYOffset - Math.Truncate(detailYOffset)), (float)(detailZOffset - Math.Truncate(detailZOffset)), 0f));

            detailXOffset = (xOffset * deTilifyBaseNoise * 0.01) / ((double)detailNoiseTiling);
            detailYOffset = (yOffset * deTilifyBaseNoise * 0.01) / ((double)detailNoiseTiling);
            detailZOffset = (zOffset * deTilifyBaseNoise * 0.01) / ((double)detailNoiseTiling);

            Vector3 noTileNoiseDetailOffset = new Vector3((float)(detailXOffset - Math.Truncate(detailXOffset)),
                (float)(detailYOffset - Math.Truncate(detailYOffset)), (float)(detailZOffset - Math.Truncate(detailZOffset)));

            raymarchedCloudMaterial.SetVector("noTileNoiseDetailOffset", noTileNoiseDetailOffset);

            if (shadowCasterLayerRaymarchedVolume != null)
            {
                // these may be 1-2 frames behind
                raymarchedCloudMaterial.SetMatrix("shadowCasterCloudRotation", shadowCasterLayerRaymarchedVolume.CloudRotationMatrix); 
                raymarchedCloudMaterial.SetFloat("shadowCasterTimeFadeDensity", shadowCasterLayerRaymarchedVolume.CurrentTimeFadeDensity);
                raymarchedCloudMaterial.SetFloat("shadowCasterTimeFadeCoverage", shadowCasterLayerRaymarchedVolume.CurrentTimeFadeCoverage);
            }
        }

        public void Remove()
        {
            if (volumeHolder != null)
            {
                volumeHolder.transform.parent = null;
                GameObject.Destroy(volumeHolder);
                volumeHolder = null;
            }
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
                raymarchedCloudMaterial.SetMatrix(ShaderProperties.MAIN_ROTATION_PROPERTY, rotationMatrix);
                raymarchedCloudMaterial.SetMatrix(ShaderProperties.DETAIL_ROTATION_PROPERTY, detailRotationMatrix);

                volumeHolder.transform.localRotation = rotation;                                            // don't need this I think
                raymarchedCloudMaterial.SetMatrix(ShaderProperties._PosRotation_Property, rotationMatrix);  // or this

                raymarchedCloudMaterial.SetMatrix("cloudRotation", rotationMatrix);                         // TODO: shader params
                cloudRotationMatrix = rotationMatrix;
                oppositeFrameDeltaRotationMatrix = inOppositeFrameDeltaRotationMatrix;
            }
        }

        internal void SetTimeFade(float currentTimeFade, TimeFadeMode mode)
        {
            if (mode == TimeFadeMode.Density)
            {
                currentTimeFadeDensity = currentTimeFade;
                raymarchedCloudMaterial.SetFloat("timeFadeDensity", currentTimeFade); // TODO: shader params
            }
            else if (mode == TimeFadeMode.Coverage)
            {
                currentTimeFadeCoverage = currentTimeFade;
                raymarchedCloudMaterial.SetFloat("timeFadeCoverage", currentTimeFade); // TODO: shader params
            }

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

            RT.enableRandomWrite = true;
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

                mat.SetVector("sphereCenter", parent.position); //this needs to be moved to deferred renderer because it's needed for reconstruction
            }

            public void Update()
            {
                volume.UpdateCloudNoiseOffsets();
            }
        }
    }
}