using ShaderLoader;
using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Utils;

namespace Atmosphere
{
    public class CloudTexture
    {
        [ConfigItem, Optional, Index(1), ValueFilter("isClamped|format|type|alphaMask")]
        TextureWrapper globalTexture;

        [ConfigItem, Optional]
        TextureWrapper tiledTexture;

        [ConfigItem, Optional]
        NoiseWrapper generatedTiledTexture;

        public TextureWrapper GlobalTexture { get => globalTexture; }
        public TextureWrapper TiledTexture { get => tiledTexture; }
        public NoiseWrapper GeneratedTiledTexture { get => generatedTiledTexture; }
    }

    public class TiledCloudTexture
    {
        [ConfigItem, Optional]
        TextureWrapper tiledTexture;

        [ConfigItem, Optional]
        NoiseWrapper generatedTiledTexture;

        public TextureWrapper TiledTexture { get => tiledTexture; }
        public NoiseWrapper GeneratedTiledTexture { get => generatedTiledTexture; }
    }

    public class CloudType
    {
        [ConfigItem]
        string typeName = "New cloud type";
        
        [ConfigItem]
        float minAltitude = 0f;
        [ConfigItem]
        float maxAltitude = 0f;

        [ConfigItem]
        bool lockHeights = false;

        [ConfigItem]
        float coverageDetailTiling = 1f;
        [ConfigItem]
        float baseTiling = 1000f;
        [ConfigItem]
        float detailTiling = 100f;

        [ConfigItem]
        float density = 0.15f;
        [ConfigItem]
        FloatCurve densityCurve;


        //these aren't used yet, using global for now
        [ConfigItem]
        float detailHeightGradient;
        [ConfigItem]
        float detailStrength;

        /*
        [ConfigItem]
        float curlNoiseTiling;
        [ConfigItem]
        float curlNoiseStrength;
        */

        public FloatCurve DensityCurve { get => densityCurve; }
        public float MinAltitude { get => minAltitude; }
        public float MaxAltitude { get => maxAltitude; }
        public bool LockHeights { get => lockHeights; }
        public float CoverageDetailTiling { get => coverageDetailTiling; }
        public float BaseTiling { get => baseTiling; }
        public float DetailTiling { get => detailTiling; }
        public float Density { get => density; }
    }

    class CloudsRaymarchedVolume
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

        [ConfigItem]
        float deTilifyBaseNoise = 1f;

        //TODO: move these to global quality settings or something like that
        [ConfigItem]
        float lightMarchSteps = 4;

        [ConfigItem]
        float lightMarchDistance = 800f;

        [ConfigItem]
        float baseStepSize = 32f;
        [ConfigItem]
        float adaptiveStepSizeFactor = 0.0075f;
        [ConfigItem]
        float maxStepSize = 250f;

        public float baseMipLevel = 0f, lightRayMipLevel = 0f;
        //////////////////////////////

        ///noise and texture params
        [ConfigItem]
        NoiseWrapper noise;

        [ConfigItem, Optional, Index(1), ValueFilter("isClamped|format|type|alphaMask")]
        TextureWrapper coverageMap;

        [ConfigItem, Optional]
        TiledCloudTexture localCoverageMap;

        [ConfigItem, Optional]
        CloudTexture cloudTypeMap;

        [ConfigItem, Optional]
        CloudTexture cloudMaxHeightMap;

        ///cloud params
        [ConfigItem]
        Color cloudColor = Color.white;
        [ConfigItem]
        float absorptionMultiplier = 1.0f;  //I think this isn't needed
        [ConfigItem]
        float skylightMultiplier = 0.5f;

        [ConfigItem]
        float cloudTypeTiling = 5f;
        [ConfigItem]
        float cloudMaxHeightTiling = 5f;
        [ConfigItem]
        float cloudSpeed = 11.0f;   // TODO: fix the direction for this
        
        [ConfigItem]
        float upwardsCloudSpeed = 11.0f;


        //[ConfigItem]
        //float curlNoiseTiling = 1f;
        //[ConfigItem]
        //float curlNoiseStrength = 1f;

        //potentially move these to be per cloud type as well?

        [ConfigItem]
        float secondaryNoiseTiling = 1f;
        [ConfigItem]
        float secondaryNoiseStrength = 1f;
        [ConfigItem]
        float secondaryNoiseGradient = 1f;
        
        [ConfigItem]
        List<CloudType> cloudTypes = new List<CloudType> { };

        ///////////

        protected Material raymarchedCloudMaterial;
        public Material RaymarchedCloudMaterial { get => raymarchedCloudMaterial; }

        private Texture densityCurvesTexture;

        private bool _enabled = true;
        public bool enabled
        {
            get { return _enabled; }
            set
            {
                _enabled = value;
                //TODO: here any stuff that enables disables stuff
            }
        }


        float planetRadius, innerSphereRadius, outerSphereRadius, cloudMinAltitude, cloudMaxAltitude;
        public float InnerSphereRadius { get => innerSphereRadius;}
        public float OuterSphereRadius { get => outerSphereRadius; }
        public float PlanetRadius { get => planetRadius; }
        
        Transform parentTransform;

        private double timeXoffset = 0.0, timeYoffset = 0.0, timeZoffset = 0.0;

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

            //check if need this
            Remove();

            volumeHolder = GameObject.CreatePrimitive(PrimitiveType.Quad);
            volumeHolder.name = "CloudsRaymarchedVolume";
            GameObject.Destroy(volumeHolder.GetComponent<Collider>());

            var updater = volumeHolder.AddComponent<Updater>();
            updater.volume = this;
            updater.mat = raymarchedCloudMaterial;
            updater.parent = parentTransform;
            var notifier = volumeHolder.AddComponent<DeferredRaymarchedRendererNotifier>();
            notifier.volume = this;

            MeshRenderer mr = volumeHolder.GetComponent<MeshRenderer>();
            //mr.material = raymarchedCloudMaterial;
            mr.material = new Material(InvisibleShader);
            raymarchedCloudMaterial.SetMatrix(ShaderProperties._ShadowBodies_PROPERTY, Matrix4x4.zero);
            //raymarchedCloudMaterial.renderQueue = (int)Tools.Queue.Transparent + 2; //check this

            mr.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            mr.receiveShadows = false;
            mr.enabled = true;

            MeshFilter filter = volumeHolder.GetComponent<MeshFilter>();
            filter.mesh.bounds = new Bounds(Vector3.zero, new Vector3(Mathf.Infinity, Mathf.Infinity, Mathf.Infinity));

            volumeHolder.transform.parent = parent; //probably parent this to the camera instead, if you want it to render before scatterer sky at least
            volumeHolder.transform.localPosition = Vector3.zero;
            volumeHolder.transform.localScale = Vector3.one;
            volumeHolder.transform.localRotation = Quaternion.identity;
            volumeHolder.layer = (int)Tools.Layer.Local;
        }

        public void ConfigureTextures()
        {
            baseNoiseRT = CreateRT(baseNoiseDimension, baseNoiseDimension, baseNoiseDimension, RenderTextureFormat.R8);
            CloudNoiseGen.RenderNoiseToTexture(baseNoiseRT, noise);
            raymarchedCloudMaterial.SetTexture("BaseNoiseTexture", baseNoiseRT);

            if (coverageMap != null)    //have to apply this last because it sets the MAP type keywords
            {
                coverageMap.ApplyTexture(raymarchedCloudMaterial, "CloudCoverage");
            }
            else
            {
                raymarchedCloudMaterial.SetTexture("CloudCoverage", Texture2D.whiteTexture);
                raymarchedCloudMaterial.EnableKeyword("MAP_TYPE_1");
            }

            if (localCoverageMap.GeneratedTiledTexture != null)
            {
                GenerateAndAssignTexture(localCoverageMap.GeneratedTiledTexture, "CloudCoverageDetail", raymarchedCloudMaterial);
            }
            else if (localCoverageMap.TiledTexture != null)
            {
                localCoverageMap.TiledTexture.ApplyTexture(raymarchedCloudMaterial, "CloudCoverageDetail");
            }
            else
            {
                raymarchedCloudMaterial.SetTexture("CloudCoverageDetail", Texture2D.whiteTexture);
            }

            ApplyCloudTexture(cloudTypeMap, "CloudType", raymarchedCloudMaterial);
            ApplyCloudTexture(cloudMaxHeightMap, "CloudMaxHeight", raymarchedCloudMaterial);
        }

        private void ApplyCloudTexture(CloudTexture cloudTexture, string propertyName, Material mat)
        {
            if (cloudTexture.GlobalTexture != null)
            {
                cloudTexture.GlobalTexture.ApplyTexture(mat, propertyName);
            }
            else if (cloudTexture.GeneratedTiledTexture != null)
            {
                GenerateAndAssignTexture(cloudTexture.GeneratedTiledTexture, propertyName, mat);
            }
            else if (cloudTexture.TiledTexture != null)
            {
                cloudTexture.TiledTexture.ApplyTexture(mat, propertyName);
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
            mat.SetTexture(propertyName, rt);
        }

        public void SetShaderParams(Material mat)
        {
            mat.SetColor("cloudColor", cloudColor);
            mat.SetFloat("cloudTypeTiling", cloudTypeTiling);
            mat.SetFloat("cloudMaxHeightTiling", cloudMaxHeightTiling);

            mat.SetFloat("detailTiling", 1f / secondaryNoiseTiling);
            mat.SetFloat("detailStrength", secondaryNoiseStrength);
            mat.SetFloat("detailHeightGradient", secondaryNoiseGradient);
            mat.SetFloat("absorptionMultiplier", absorptionMultiplier);
            mat.SetFloat("lightMarchAttenuationMultiplier", 1.0f);
            mat.SetFloat("baseMipLevel", baseMipLevel);
            mat.SetFloat("lightRayMipLevel", lightRayMipLevel);
            mat.SetFloat("cloudSpeed", cloudSpeed);

            mat.SetFloat("baseStepSize", baseStepSize);
            mat.SetFloat("maxStepSize", maxStepSize);
            mat.SetFloat("adaptiveStepSizeFactor", adaptiveStepSizeFactor);

            mat.SetFloat("lightMarchDistance", lightMarchDistance);
            mat.SetInt("lightMarchSteps", (int)lightMarchSteps);

            Texture2D tex = GameDatabase.Instance.GetTexture("EnvironmentalVisualEnhancements/Blue16b", false);
            mat.SetTexture("BlueNoise", tex);
            mat.SetFloat("deTilifyBaseNoise", deTilifyBaseNoise * 0.01f);
            mat.SetFloat("skylightMultiplier", skylightMultiplier);
        }

        private void ProcessCloudTypes()
        {
            //figure out min and max radiuses
            cloudMinAltitude = Mathf.Infinity;
            cloudMaxAltitude = 0f;

            for (int i = 0; i < cloudTypes.Count; i++)
            {
                cloudMinAltitude = Mathf.Min(cloudMinAltitude, cloudTypes[i].MinAltitude);
                cloudMaxAltitude = Mathf.Max(cloudMaxAltitude, cloudTypes[i].MaxAltitude);
            }

            //need to get the planet's radius
            innerSphereRadius = planetRadius + cloudMinAltitude;
            outerSphereRadius = planetRadius + cloudMaxAltitude;

            raymarchedCloudMaterial.SetFloat("innerSphereRadius", innerSphereRadius);
            raymarchedCloudMaterial.SetFloat("outerSphereRadius", outerSphereRadius);

            densityCurvesTexture = BakeDensityCurvesTexture();  // must keep a reference to it or it gets yeeted on scene load
            raymarchedCloudMaterial.SetTexture("DensityCurve", densityCurvesTexture);

            Vector4[] cloudTypePropertiesArray0 = new Vector4[10];
            Vector4[] cloudTypePropertiesArray1 = new Vector4[10];
            for (int i = 0; i < cloudTypes.Count && i < 10; i++)
            {
                cloudTypePropertiesArray0[i] = new Vector4(cloudTypes[i].Density, 1f / cloudTypes[i].BaseTiling, cloudTypes[i].CoverageDetailTiling, 0f);   //0f instead of anvilBias
                cloudTypePropertiesArray1[i] = new Vector4(cloudTypes[i].LockHeights ? 1f : 0f, 0f, 0f, 0f);
            }
            raymarchedCloudMaterial.SetVectorArray("cloudTypeProperties0", cloudTypePropertiesArray0);
            raymarchedCloudMaterial.SetVectorArray("cloudTypeProperties1", cloudTypePropertiesArray1);
            raymarchedCloudMaterial.SetInt("numberOfCloudTypes", cloudTypes.Count);
            raymarchedCloudMaterial.SetFloat("planetRadius", planetRadius);
        }

        private Texture2D BakeDensityCurvesTexture()
        {
            int resolution = 128;

            if (cloudTypes.Count == 0)
                return Texture2D.blackTexture;

            Texture2D tex = new Texture2D(cloudTypes.Count, resolution, TextureFormat.R8, false);

            tex.filterMode = FilterMode.Bilinear;
            tex.wrapMode = TextureWrapMode.Clamp; //will need to pass this to the compressor script after

            Color[] colors = new Color[resolution * cloudTypes.Count];

            for (int i = 0; i < cloudTypes.Count; i++)
            {
                for (int j = 0; j < resolution; j++)
                {
                    float currentAltitude = Mathf.Lerp(cloudMinAltitude, cloudMaxAltitude, (float)j / resolution);

                    if (cloudTypes[i].MinAltitude > currentAltitude || cloudTypes[i].MaxAltitude < currentAltitude)
                        colors[i + j * cloudTypes.Count].r = 0f;
                    else
                    {
                        float t = (currentAltitude - cloudTypes[i].MinAltitude) / (cloudTypes[i].MaxAltitude - cloudTypes[i].MinAltitude);
                        colors[i + j * cloudTypes.Count].r = cloudTypes[i].DensityCurve.Evaluate(t);
                    }
                }
            }

            tex.SetPixels(colors);
            tex.Apply(false);

            return tex;
        }

        public void UpdateCloudNoiseOffsets()
        {
            double xOffset = -parentTransform.position.x, yOffset = -parentTransform.position.y, zOffset = -parentTransform.position.z;

            //TODO: add upward wind offset, calculate vector from camera position? or just the direction of the planet center would give you that
            //and give a direction to this offset, maybe tangent to cloud rotation?
            timeXoffset += (double)Time.deltaTime * (double)TimeWarp.CurrentRate * ((double)cloudSpeed);

            xOffset += timeXoffset; yOffset += timeYoffset; zOffset += timeZoffset;

            Vector4[] baseNoiseOffsets   = new Vector4[10];
            Vector4[] noTileNoiseOffsets = new Vector4[10];
            for (int i = 0; i < cloudTypes.Count && i < 10; i++)
            {
                double noiseXOffset = xOffset / (double)cloudTypes[i].BaseTiling, noiseYOffset = yOffset / (double)cloudTypes[i].BaseTiling, noiseZOffset = zOffset / (double)cloudTypes[i].BaseTiling;

                baseNoiseOffsets[i] = new Vector4((float)(noiseXOffset - Math.Truncate(noiseXOffset)), (float) (noiseYOffset - Math.Truncate(noiseYOffset)),
                    (float) (noiseZOffset - Math.Truncate(noiseZOffset)), 0f);

                double noTileXOffset = (xOffset * deTilifyBaseNoise * 0.01) / ((double)cloudTypes[i].BaseTiling);
                double noTileYOffset = (yOffset * deTilifyBaseNoise * 0.01) / ((double)cloudTypes[i].BaseTiling);
                double noTileZOffset = (zOffset * deTilifyBaseNoise * 0.01) / ((double)cloudTypes[i].BaseTiling);

                noTileNoiseOffsets[i] = new Vector4((float)(noTileXOffset - Math.Truncate(noTileXOffset)), (float)(noTileYOffset - Math.Truncate(noTileYOffset)),
                    (float)(noTileZOffset - Math.Truncate(noTileZOffset)), 0f);
            }
            raymarchedCloudMaterial.SetVectorArray("baseNoiseOffsets", baseNoiseOffsets);
            raymarchedCloudMaterial.SetVectorArray("noTileNoiseOffsets", noTileNoiseOffsets);

            double detailXOffset = xOffset / (double) secondaryNoiseTiling, detailYOffset = yOffset / (double)secondaryNoiseTiling, detailZOffset = zOffset / (double)secondaryNoiseTiling;

            raymarchedCloudMaterial.SetVector("detailOffset", new Vector4((float)(detailXOffset - Math.Truncate(detailXOffset)),
                (float)(detailYOffset - Math.Truncate(detailXOffset)), (float)(detailZOffset - Math.Truncate(detailXOffset)), 0f));

            detailXOffset = (xOffset * deTilifyBaseNoise * 0.01) / ((double)secondaryNoiseTiling);
            detailYOffset = (yOffset * deTilifyBaseNoise * 0.01) / ((double)secondaryNoiseTiling);
            detailZOffset = (zOffset * deTilifyBaseNoise * 0.01) / ((double)secondaryNoiseTiling);

            Vector3 noTileNoiseDetailOffset = new Vector3((float)(detailXOffset - Math.Truncate(detailXOffset)),
                (float)(detailYOffset - Math.Truncate(detailXOffset)), (float)(detailZOffset - Math.Truncate(detailXOffset)));

            raymarchedCloudMaterial.SetVector("noTileNoiseDetailOffset", noTileNoiseDetailOffset);
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

        // supposed to be called from CloudsPQS which I won't use because we don't want to be locked to PQS
        internal void UpdatePos(Vector3 WorldPos, Matrix4x4 World2Planet, QuaternionD rotation, QuaternionD detailRotation, Matrix4x4 mainRotationMatrix, Matrix4x4 detailRotationMatrix)
        {
            if (HighLogic.LoadedScene == GameScenes.FLIGHT || HighLogic.LoadedScene == GameScenes.SPACECENTER)
            {
                Matrix4x4 rotationMatrix = mainRotationMatrix * World2Planet;
                raymarchedCloudMaterial.SetMatrix(ShaderProperties.MAIN_ROTATION_PROPERTY, rotationMatrix);
                raymarchedCloudMaterial.SetMatrix(ShaderProperties.DETAIL_ROTATION_PROPERTY, detailRotationMatrix);

                //if (followDetail)
                //{
                  //  rotationMatrix = detailRotationMatrix * mainRotationMatrix * World2Planet;
                  //  volumeHolder.transform.localRotation = rotation * detailRotation;
                 //   RaymarchedCloudMaterial.SetMatrix(ShaderProperties._PosRotation_Property, rotationMatrix);
                //}
                //else
                
                {
                    volumeHolder.transform.localRotation = rotation;
                    raymarchedCloudMaterial.SetMatrix(ShaderProperties._PosRotation_Property, rotationMatrix);
                }

                raymarchedCloudMaterial.SetMatrix("cloudRotation", rotationMatrix);
            }
        }

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