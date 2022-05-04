using EVEManager;
using ShaderLoader;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using UnityEngine;
using UnityEngine.Rendering;
using Utils;

namespace Atmosphere
{
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
        float density = 1f;
        [ConfigItem]
        FloatCurve densityCurve;


        /*//these aren't used yet, using global for now
        [ConfigItem]
        float detailHeightGradient;
        [ConfigItem]
        float detailStrength;
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

        public Shader shader, compositeCloudShader, reconstructCloudsShader;

        private static Shader raymarchedCloudShader = null;
        private static Shader RaymarchedCloudShader
        {
            get
            {
                if (raymarchedCloudShader == null)
                {
                    raymarchedCloudShader = ShaderLoaderClass.FindShader("EVE/RaymarchCloud");
                }
                return raymarchedCloudShader;
            }
        }

        private static Shader invisibleShader = null;
        private static Shader InvisibleShader
        {
            get
            {
                if (invisibleShader == null)
                {
                    invisibleShader = ShaderLoaderClass.FindShader("EVE/Invisible");
                }
                return invisibleShader;
            }
        }

        private int baseTextureDimension = 128;
        private int detailTextureDimension = 32;

        private RenderTexture baseNoise, localCoverage, cloudType, cloudMaxHeight, cloudMinHeight;


        /////// Global quality settings /////// 
        //public int reprojectionXfactor = 4;
        //public int reprojectionYfactor = 2;

        //public int reprojectionXfactor = 1;
        //public int reprojectionYfactor = 1;

        //temporary, make it a relative path later, put in shaders folder
        private string stbnPath = "C:\\Steam\\steamapps\\common\\Kerbal Space Program\\GameData\\EnvironmentalVisualEnhancements\\stbn.R8"; 

        static private int stbnWidth = 128;
        static private int stbnHeight = 128;
        static private int stbnSlices = 64;

        public int lightMarchSteps = 4;
        public float lightMarchDistance = 800f;

        public float baseStepSize = 32f;
        public float adaptiveStepSizeFactor = 0.0075f;
        public float maxStepSize = 250f;

        public float maxVisibility = 50000000f;

        public float baseMipLevel = 0f, lightRayMipLevel = 0f;
        //////////////////////////////

        float planetRadius, innerSphereRadius, outerSphereRadius, cloudMinAltitude, cloudMaxAltitude;

        ///noise params
        [ConfigItem]
        NoiseMode baseNoiseMode;
        [ConfigItem]
        NoiseSettings PWPerlin;
        [ConfigItem]
        NoiseSettings PWWorley;

        [ConfigItem]
        NoiseMode localCoverageMode;
        [ConfigItem]
        NoiseSettings localCoverageSettings;

        [ConfigItem]
        NoiseMode cloudTypeMode;
        [ConfigItem]
        NoiseSettings cloudTypeSettings;

        [ConfigItem]
        NoiseMode cloudMaxHeightMode;
        [ConfigItem]
        NoiseSettings cloudMaxHeightSettings;

        [ConfigItem]
        NoiseMode cloudMinHeightMode;
        [ConfigItem]
        NoiseSettings cloudMinHeightSettings;

        ///cloud params
        [ConfigItem]
        Color cloudColor = Color.white;
        [ConfigItem]
        float absorptionMultiplier = 1.0f;
        [ConfigItem]
        float lightMarchAttenuationMultiplier = 1.0f;

        [ConfigItem]
        float cloudTypeTiling = 5f;
        [ConfigItem]
        float cloudMaxHeightTiling = 5f;
        [ConfigItem]
        float cloudSpeed = 11.0f;
        [ConfigItem]
        float curlNoiseTiling = 1f;
        [ConfigItem]
        float curlNoiseStrength = 1f;
        [ConfigItem]
        float detailTiling = 1f;
        [ConfigItem]
        float detailStrength = 1f;
        [ConfigItem]
        float detailHeightGradient = 1f;
        
        [ConfigItem]
        List<CloudType> cloudTypes = new List<CloudType> { };

        protected Quaternion axis = Quaternion.identity;
        ///////////

        protected Material raymarchedCloudMaterial, compositeCloudsMaterial, reconstructCloudsMaterial;

        private Texture2D cloudCoverage, curlNoise;
        private Texture2D stbn;

        //probably this shouldn't be here but static in the DeferredRaymarchedVolumetricCloudsRenderer class
        private Dictionary<Camera, DeferredRaymarchedVolumetricCloudsRenderer> CameraToDeferredRenderer = new Dictionary<Camera, DeferredRaymarchedVolumetricCloudsRenderer>();
        
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

        public float InnerSphereRadius { get => innerSphereRadius;}
        public float OuterSphereRadius { get => outerSphereRadius; }

        public float PlanetRadius { get => planetRadius; }

        public Material RaymarchedCloudMaterial { get => raymarchedCloudMaterial; }

        Transform parentTransform;

        public void Apply(CloudsMaterial material, float radius, Transform parent)
        {
            planetRadius = radius;
            parentTransform = parent;

            raymarchedCloudMaterial = new Material(RaymarchedCloudShader);

            stbn = new Texture2D(stbnWidth, stbnHeight * stbnSlices, TextureFormat.R8, false);
            stbn.filterMode = FilterMode.Point;
            stbn.wrapMode = TextureWrapMode.Repeat;
            stbn.LoadRawTextureData(System.IO.File.ReadAllBytes(stbnPath));
            stbn.Apply();
            raymarchedCloudMaterial.SetTexture("StbnBlueNoise", stbn);
            raymarchedCloudMaterial.SetFloat("blueNoiseResolution", stbnWidth);
            raymarchedCloudMaterial.SetFloat("blueNoiseSlices", stbnSlices);

            GenerateNoiseTextures();

            ProcessCloudTypes();

            SetShaderParams(raymarchedCloudMaterial);

            //check if need this
            Remove();

            volumeHolder = GameObject.CreatePrimitive(PrimitiveType.Quad);
            volumeHolder.name = "CloudsRaymarchedVolume";
            GameObject.Destroy(volumeHolder.GetComponent<Collider>());

            var updater = volumeHolder.AddComponent<Updater>();
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

            volumeHolder.transform.parent = parent;
            volumeHolder.transform.localPosition = Vector3.zero;
            volumeHolder.transform.localScale = Vector3.one;
            volumeHolder.transform.localRotation = Quaternion.identity;
            volumeHolder.layer = (int)Tools.Layer.Local;
        }
        
        public void ProcessCloudTypes()
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

            raymarchedCloudMaterial.SetTexture("DensityCurve", BakeDensityCurvesTexture());

            //not sure I need to initialize this to 10 but trying to avoid the bug mentioned here: https://www.alanzucconi.com/2016/10/24/arrays-shaders-unity-5-4/
            Vector4[] cloudTypePropertiesArray0 = new Vector4[10];
            Vector4[] cloudTypePropertiesArray1 = new Vector4[10];
            for (int i = 0; i < cloudTypes.Count; i++)
            {
                cloudTypePropertiesArray0[i] = new Vector4(cloudTypes[i].Density, 1f / cloudTypes[i].BaseTiling, cloudTypes[i].CoverageDetailTiling, 0f);   //0f instead of anvilBias
                cloudTypePropertiesArray1[i] = new Vector4(cloudTypes[i].LockHeights ? 1f : 0f, 0f, 0f, 0f);
            }
            raymarchedCloudMaterial.SetVectorArray("cloudTypeProperties0", cloudTypePropertiesArray0);
            raymarchedCloudMaterial.SetVectorArray("cloudTypeProperties1", cloudTypePropertiesArray1);
            raymarchedCloudMaterial.SetInt("numberOfCloudTypes", cloudTypes.Count);
            raymarchedCloudMaterial.SetFloat("planetRadius", planetRadius);
        }

        public void SetShaderParams(Material mat)
        {
            mat.SetColor("cloudColor", cloudColor);
            mat.SetFloat("cloudTypeTiling", cloudTypeTiling);
            mat.SetFloat("cloudMaxHeightTiling", cloudMaxHeightTiling);
            mat.SetFloat("maxVisibility", maxVisibility);

            mat.SetFloat("detailTiling", 1f / detailTiling);
            mat.SetFloat("detailStrength", detailStrength);
            mat.SetFloat("detailHeightGradient", detailHeightGradient);
            mat.SetFloat("absorptionMultiplier", absorptionMultiplier);
            mat.SetFloat("lightMarchAttenuationMultiplier", lightMarchAttenuationMultiplier);
            mat.SetFloat("baseMipLevel", baseMipLevel);
            mat.SetFloat("lightRayMipLevel", lightRayMipLevel);
            mat.SetFloat("cloudSpeed", cloudSpeed);

            mat.SetFloat("baseStepSize", baseStepSize);
            mat.SetFloat("maxStepSize", maxStepSize);
            mat.SetFloat("adaptiveStepSizeFactor", adaptiveStepSizeFactor);

            mat.SetFloat("lightMarchDistance", lightMarchDistance);
            mat.SetInt("lightMarchSteps", lightMarchSteps);
        }

        //TODO: decouple generation from setting them in the material
        public void GenerateNoiseTextures()
        {
            baseNoise = CreateRT(baseTextureDimension, baseTextureDimension, baseTextureDimension, RenderTextureFormat.R8);

            CloudNoiseGen.RenderNoiseToTexture(baseNoise, PWPerlin, PWWorley, baseNoiseMode);
            raymarchedCloudMaterial.SetTexture("BaseNoiseTexture", baseNoise);

            localCoverage = CreateRT(512, 512, 0, RenderTextureFormat.R8);
            CloudNoiseGen.RenderNoiseToTexture(localCoverage, localCoverageSettings, localCoverageSettings, localCoverageMode);
            //Texture2D compressedLocalCoverage = TextureUtils.CompressSingleChannelRenderTextureToBC4(LocalCoverage, true);	//compress to BC4, increases fps a tiny bit, just disabled for now because it's slow
            raymarchedCloudMaterial.SetTexture("CloudCoverageDetail", localCoverage);

            cloudType = CreateRT(512, 512, 0, RenderTextureFormat.R8);
            CloudNoiseGen.RenderNoiseToTexture(cloudType, cloudTypeSettings, cloudTypeSettings, cloudTypeMode);
            //Texture2D compressedCloudType = TextureUtils.CompressSingleChannelRenderTextureToBC4(cloudType, true);
            raymarchedCloudMaterial.SetTexture("CloudType", cloudType);

            cloudMaxHeight = CreateRT(512, 512, 0, RenderTextureFormat.R8);
            CloudNoiseGen.RenderNoiseToTexture(cloudMaxHeight, cloudMaxHeightSettings, cloudMaxHeightSettings, cloudMaxHeightMode);
            //Texture2D compressedCloudMaxHeight = TextureUtils.CompressSingleChannelRenderTextureToBC4(cloudMaxHeight, true);
            raymarchedCloudMaterial.SetTexture("CloudMaxHeight", cloudMaxHeight);

            /*
            cloudMinHeight = CreateRT(512, 512, 0, RenderTextureFormat.R8);
            CloudNoiseGen.RenderNoiseToTexture(cloudMinHeight, cloudMinHeightSettings, cloudMinHeightSettings, cloudMinHeightMode);
            //Texture2D compressedCloudMinHeight= TextureUtils.CompressSingleChannelRenderTextureToBC4(cloudMinHeight, true);
            */
            //Debug.Log("16");
            //raymarchedCloudMaterial.SetTexture("CloudMinHeight", cloudMinHeight);
        }

        public Texture2D BakeDensityCurvesTexture()
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

        public void Remove()
        {
            if (volumeHolder != null)
            {
                volumeHolder.transform.parent = null;
                GameObject.Destroy(volumeHolder);
                volumeHolder = null;
            }
        }

        
        // rotates the main texture I think
        internal void UpdatePos(Vector3 WorldPos, Matrix4x4 World2Planet, QuaternionD rotation, QuaternionD detailRotation, Matrix4x4 mainRotationMatrix, Matrix4x4 detailRotationMatrix)
        {
            //search for camera 01 and
            //no just add a script with onWillRenderObject
            //material.SetMatrix("CameraToWorld", cam.cameraToWorldMatrix);

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
            }
        }

        public RenderTexture CreateRT(int height, int width, int volume, RenderTextureFormat format)
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

            public void OnWillRenderObject()
            {
                Camera cam = Camera.current;
                if (!cam || !mat)
                    return;

                mat.SetVector("sphereCenter", parent.position); //this needs to be moved to deferred renderer
            }
        }
    }
}