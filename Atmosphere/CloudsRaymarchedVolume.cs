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
        float baseTiling = 1000f;
        [ConfigItem]
        float detailTiling = 100f;

        //these aren't used yet, using global for now
        [ConfigItem]
        float detailHeightGradient;
        [ConfigItem]
        float detailStrength;

        [ConfigItem]
        float density = 0.15f;

        [ConfigItem]
        bool interpolateCloudHeights = true;

        [ConfigItem]
        FloatCurve densityCurve;

        /*
        [ConfigItem]
        float curlNoiseTiling;
        [ConfigItem]
        float curlNoiseStrength;
        */

        public FloatCurve DensityCurve { get => densityCurve; }
        public float MinAltitude { get => minAltitude; }
        public float MaxAltitude { get => maxAltitude; }
        public bool InterpolateCloudHeights { get => interpolateCloudHeights; }
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
        float lightMarchSteps = 8;

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
        CloudTexture cloudTypeMap;

        ///cloud params
        [ConfigItem]
        Color cloudColor = Color.white;
        [ConfigItem]
        float absorptionMultiplier = 1.0f;
        [ConfigItem]
        float skylightMultiplier = 0.5f;

        [ConfigItem]
        float cloudTypeTiling = 5f;
        
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
        //[ConfigItem]
        //float secondaryNoiseGradient = 1f;

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
        public Transform ParentTransform { get => parentTransform; }

        private double timeXoffset = 0.0, timeYoffset = 0.0, timeZoffset = 0.0;

        private Matrix4x4 oppositeFrameDeltaRotationMatrix = Matrix4x4.identity;
        public Matrix4x4 OppositeFrameDeltaRotationMatrix { get => oppositeFrameDeltaRotationMatrix; }

        private Vector3 noiseReprojectionOffset = Vector3.zero;

        public Vector3 NoiseReprojectionOffset { get => noiseReprojectionOffset; }

        Matrix4x4 cloudRotationMatrix = Matrix4x4.identity;

        public void Apply(CloudsMaterial material, float cloudLayerRadius, Transform parent, float parentRadius)//, Vector3 speed, Matrix4x4 rotationAxis)
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

            ApplyCloudTexture(cloudTypeMap, "CloudType", raymarchedCloudMaterial);
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

            mat.SetFloat("detailTiling", 1f / secondaryNoiseTiling);
            mat.SetFloat("detailStrength", secondaryNoiseStrength);
            //mat.SetFloat("detailHeightGradient", secondaryNoiseGradient);
            mat.SetFloat("absorptionMultiplier", absorptionMultiplier);
            mat.SetFloat("lightMarchAttenuationMultiplier", 1.0f);
            mat.SetFloat("baseMipLevel", baseMipLevel);
            mat.SetFloat("lightRayMipLevel", lightRayMipLevel);

            mat.SetFloat("baseStepSize", baseStepSize);
            mat.SetFloat("maxStepSize", maxStepSize);
            mat.SetFloat("adaptiveStepSizeFactor", adaptiveStepSizeFactor);

            mat.SetFloat("lightMarchDistance", lightMarchDistance);
            mat.SetInt("lightMarchSteps", (int)lightMarchSteps);

            Texture2D tex = GameDatabase.Instance.GetTexture("EnvironmentalVisualEnhancements/Blue16b", false); //TODO: remove/replace with lower res texture?
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

            densityCurvesTexture = BakeDensityCurvesTexture();
            raymarchedCloudMaterial.SetTexture("DensityCurve", densityCurvesTexture);

            Vector4[] cloudTypePropertiesArray0 = new Vector4[cloudTypes.Count];
            Vector4[] cloudTypePropertiesArray1 = new Vector4[cloudTypes.Count];
            for (int i = 0; i < cloudTypes.Count; i++)
            {
                cloudTypePropertiesArray0[i] = new Vector4(cloudTypes[i].Density, 1f / cloudTypes[i].BaseTiling, 0f, 0f);
                cloudTypePropertiesArray1[i] = new Vector4(0f, 0f, 0f, 0f);
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

        float EvaluateCloudValue(int cloudIndex, float currentAltitude, float interpolatedMinAltitude, float interpolatedMaxAltitude)
        {
            float minAltitude = cloudTypes[cloudIndex].InterpolateCloudHeights ? interpolatedMinAltitude : cloudTypes[cloudIndex].MinAltitude;
            float maxAltitude = cloudTypes[cloudIndex].InterpolateCloudHeights ? interpolatedMaxAltitude : cloudTypes[cloudIndex].MaxAltitude;

            if (currentAltitude <= maxAltitude && currentAltitude >= minAltitude)
            {
                float t = (currentAltitude - minAltitude) / (maxAltitude - minAltitude);
                return cloudTypes[cloudIndex].DensityCurve.Evaluate(t);
            }

            return 0f;
        }

        // TODO: refactor/simplify
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
        internal void UpdatePos(Vector3 WorldPos, Matrix4x4 World2Planet, QuaternionD rotation, QuaternionD detailRotation, Matrix4x4 mainRotationMatrix, Matrix4x4 inOppositeFrameDeltaRotationMatrix, Matrix4x4 detailRotationMatrix)
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
                cloudRotationMatrix = rotationMatrix;
                oppositeFrameDeltaRotationMatrix = inOppositeFrameDeltaRotationMatrix;
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