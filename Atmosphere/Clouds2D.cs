using EVEManager;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using ShaderLoader;
using UnityEngine;
using Utils;

namespace Atmosphere
{
    public class Clouds2DMaterial : MaterialManager
    {
#pragma warning disable 0169
#pragma warning disable 0414
        [ConfigItem]
        float _FalloffPow = 2f;
        [ConfigItem]
        float _FalloffScale = 3f;
        [ConfigItem]
        float _MinLight = 0f;
        [ConfigItem, InverseScaled]
        float _RimDist = 0.0001f;
        [ConfigItem, InverseScaled]
        float _RimDistSub = 1.01f;
        [ConfigItem, InverseScaled]
        float _InvFade = .008f;
        [Scaled]
        float _Radius = 1000f;

        public float Radius { set { _Radius = value; } }
    }

    public class CloudShadowMaterial : MaterialManager
    {
        [ConfigItem]
        float _ShadowFactor = .75f;
    }

    public class Clouds2D
    {
        GameObject CloudMesh;
        Material CloudMaterial;
        Projector ShadowProjector = null;
        GameObject ShadowProjectorGO = null;
        CloudsMaterial cloudsMat = null;

        ScreenSpaceShadow screenSpaceShadow;
        GameObject screenSpaceShadowGO = null;

        [ConfigItem]
        Clouds2DMaterial macroCloudMaterial = null;
        [ConfigItem, Optional]
        CloudShadowMaterial shadowMaterial = null;

        Tools.Layer scaledLayer = Tools.Layer.Scaled;
        Light Sunlight;
        bool isScaled = false;

        float flowLoopTime = 0f;
        Matrix4x4 mainRotationMatrix = Matrix4x4.identity;


        public bool Scaled
        {
            get { return isScaled; }
            set
            {
                CloudsManager.Log("Clouds2D is now " + (value ? "SCALED" : "MACRO"));
                if (isScaled != value)
                {
                    if (value)
                    {
                        Reassign(scaledLayer, scaledCelestialTransform, ScaledSpace.InverseScaleFactor);
                    }
                    else
                    {                                                
                        Reassign(Tools.Layer.Local, celestialBody.transform, 1);
                    }
                    isScaled = value;
                }
            }
        }
        CelestialBody celestialBody = null;
        Transform scaledCelestialTransform = null;
        float radius;
        float arc;
        public float Altitude() { return celestialBody == null ? radius : (float)(radius - celestialBody.Radius); }
        float radiusScaleLocal;
        private bool isMainMenu = false;
        
        // Used to calculate the scale of the clouds in the mainmenu
        private const float joolRadius = 6000000f;

        private static Shader cloudShader = null;

        internal Clouds2D CloneForMainMenu(GameObject mainMenuBody)
        {
            Clouds2D mainMenu = new Clouds2D();
            mainMenu.macroCloudMaterial = this.macroCloudMaterial;
            mainMenu.shadowMaterial = this.shadowMaterial;
            mainMenu.isMainMenu = true;

            if (mainMenuBody.name.EndsWith("(Clone)")) {
                // There is a race condition with Kopernicus. Sometimes, it
                // will have cloned a body that already had clouds. Hide old clouds.
                for (var c=0; c<mainMenuBody.transform.childCount; ++c) {
                    var child = mainMenuBody.transform.GetChild(c).gameObject;
                    if (child.name.StartsWith("EVE ") && child.name.EndsWith("(Clone)"))
                        child.SetActive(false);
                }
            }

            mainMenu.Apply(this.celestialBody, mainMenuBody.transform, this.cloudsMat, this.CloudMesh.name, this.radius, this.arc, (Tools.Layer)mainMenuBody.layer);
            
            return mainMenu;
        }

        private static Shader CloudShader
        {
            get
            {
                if (cloudShader == null)
                {
                    cloudShader = ShaderLoaderClass.FindShader("EVE/Cloud");
                } return cloudShader;
            }
        }

        private static Shader cloudShadowShader = null;
        private static Shader CloudShadowShader
        {
            get
            {
                if (cloudShadowShader == null)
                {
                    cloudShadowShader = ShaderLoaderClass.FindShader("EVE/CloudShadow");
                } return cloudShadowShader;
            }
        }

        private static Shader screenSpaceCloudShadowShader = null;
        private static Shader ScreenSpaceCloudShadowShader
        {
            get
            {
                if (screenSpaceCloudShadowShader == null)
                {
                    screenSpaceCloudShadowShader = ShaderLoaderClass.FindShader("EVE/ScreenSpaceCloudShadow");
                }
                return screenSpaceCloudShadowShader;
            }
        }

        private bool _enabled = true;

        public bool enabled { get {return _enabled; }
            set
            {
                _enabled = value;
                if (CloudMesh != null)
                {
                    CloudMesh.SetActive(value);
                }
                if (ShadowProjector != null)
                {
                    ShadowProjector.enabled = value;
                }
                if (screenSpaceShadowGO != null)
                {
                    screenSpaceShadowGO.SetActive(value);
                }
            }
        }

        public CloudsMaterial CloudsMat { get => cloudsMat; }
        public Material CloudRenderingMaterial { get => CloudMaterial; }
        public Matrix4x4 MainRotationMatrix { get => mainRotationMatrix; }

        public void setCloudMeshEnabled(bool value)
        {
            if (CloudMesh != null)
            {
                CloudMesh.SetActive(value);
            }
        }

        internal void Apply(CelestialBody celestialBody, Transform scaledCelestialTransform, CloudsMaterial cloudsMaterial, string name, float radius, float arc, Tools.Layer layer = Tools.Layer.Scaled)
        {
            CloudsManager.Log("Applying 2D clouds...");
            Remove();
            this.celestialBody = celestialBody;
            this.scaledCelestialTransform = scaledCelestialTransform;
            if (arc == 360) {
                HalfSphere hp = new HalfSphere(radius, ref CloudMaterial, CloudShader);
                CloudMesh = hp.GameObject;
            } else {
                UVSphere hp = new UVSphere(radius, arc, ref CloudMaterial, CloudShader);
                CloudMesh = hp.GameObject;
            }
            CloudMesh.name = name;
            CloudMaterial.name = "Clouds2D";
            this.radius = radius;
            this.arc = arc;
            macroCloudMaterial.Radius = radius;
            this.cloudsMat = cloudsMaterial;
            this.scaledLayer = layer;

            CloudMaterial.SetMatrix(ShaderProperties._ShadowBodies_PROPERTY, Matrix4x4.zero);

            if (shadowMaterial != null)
            {
                ShadowProjectorGO = new GameObject("EVE ShadowProjector");
                ShadowProjector = ShadowProjectorGO.AddComponent<Projector>();
                ShadowProjector.nearClipPlane = 10;
                ShadowProjector.fieldOfView = 60;
                ShadowProjector.aspectRatio = 1;
                ShadowProjector.orthographic = true;
                ShadowProjector.transform.parent = celestialBody.transform;
                ShadowProjector.material = new Material(CloudShadowShader);
                shadowMaterial.ApplyMaterialProperties(ShadowProjector.material);

                // Workaround Unity bug (Case 841236) 
                ShadowProjector.enabled = false;
                ShadowProjector.enabled = true;

                // Here create the screenSpaceShadowMaterialStuff
                screenSpaceShadowGO = new GameObject("EVE ScreenSpaceShadow");
                screenSpaceShadowGO.transform.parent = celestialBody.transform;
                screenSpaceShadow = screenSpaceShadowGO.AddComponent<ScreenSpaceShadow>(); //can this be a single class that will handle the mesh, and meshrenderer and everything?
                screenSpaceShadow.material = new Material(ScreenSpaceCloudShadowShader);
                shadowMaterial.ApplyMaterialProperties(screenSpaceShadow.material); 
                screenSpaceShadow.Init();
                screenSpaceShadowGO.SetActive(false);
                screenSpaceShadow.SetActive(false);
            }


            Scaled = true;
        }

        public void Reassign(Tools.Layer layer, Transform parent, float worldScale)
        {
            CloudMesh.transform.parent = parent;
            CloudMesh.transform.localPosition = Vector3.zero;

            float localScale;
            if (isMainMenu)
            {
                localScale = worldScale * (joolRadius / (float) celestialBody.Radius);
            }
            else
            {
                localScale = (worldScale / parent.lossyScale.x);
            }

            CloudMesh.transform.localScale = (Vector3.one)*localScale;
            CloudMesh.layer = (int)layer;

            float radiusScaleWorld = radius * worldScale;
            radiusScaleLocal = radius * localScale;


            macroCloudMaterial.ApplyMaterialProperties(CloudMaterial, worldScale);
            cloudsMat.ApplyMaterialProperties(CloudMaterial, worldScale);

            if (layer == Tools.Layer.Local)
            {
                Sunlight = Sun.Instance.GetComponent<Light>();
                
                CloudMaterial.SetFloat("_OceanRadius", (float)celestialBody.Radius * worldScale);
                CloudMaterial.EnableKeyword("WORLD_SPACE_ON");
                CloudMaterial.EnableKeyword("SOFT_DEPTH_ON");
                CloudMaterial.renderQueue = (int)Tools.Queue.Transparent - 1;
            }
            else
            {
                //hack to get protected variable
                FieldInfo field = typeof(Sun).GetFields(BindingFlags.Instance | BindingFlags.NonPublic).First(
                    f => f.Name == "scaledSunLight" );
                Sunlight = (Light)field.GetValue(Sun.Instance);
                CloudMaterial.DisableKeyword("WORLD_SPACE_ON");
                CloudMaterial.DisableKeyword("SOFT_DEPTH_ON");
                CloudMaterial.renderQueue = (int)Tools.Queue.Transparent -1;
            }

            CloudMaterial.SetFloat("scaledCloudFade", 1f);
            CloudMaterial.SetFloat("cloudTimeFadeDensity", 1f);
            CloudMaterial.SetFloat("cloudTimeFadeCoverage", 1f);

            if (isMainMenu)
            {
                try
                {
                    Sunlight = GameObject.FindObjectsOfType<Light>().Last(l => l.isActiveAndEnabled);
                }
                catch { }
            }

            if (ShadowProjector != null)
            {

                float dist = (float)(2 * radiusScaleWorld);
                ShadowProjector.farClipPlane = dist;
                ShadowProjector.orthographicSize = radiusScaleWorld;

                macroCloudMaterial.ApplyMaterialProperties(ShadowProjector.material, worldScale);
                cloudsMat.ApplyMaterialProperties(ShadowProjector.material, worldScale);

                ShadowProjector.material.SetFloat("_Radius", (float)radiusScaleLocal);
                ShadowProjector.material.SetFloat("_PlanetRadius", (float)celestialBody.Radius*worldScale);
                ShadowProjector.transform.parent = parent;

                ShadowProjector.material.SetFloat("cloudTimeFadeDensity", 1f);
                ShadowProjector.material.SetFloat("cloudTimeFadeCoverage", 1f);
                screenSpaceShadow.material.SetFloat("cloudTimeFadeDensity", 1f);
                screenSpaceShadow.material.SetFloat("cloudTimeFadeCoverage", 1f);

                ShadowProjectorGO.layer = (int)Tools.Layer.Scaled; //move these to init since no longer need to change
                if (layer == Tools.Layer.Scaled)
                {
                    ShadowProjector.ignoreLayers = ~layer.Mask();
                    ShadowProjector.material.DisableKeyword("WORLD_SPACE_ON");
                    ShadowProjector.enabled = true;
                }
                else
                    ShadowProjector.enabled = false;

                if (screenSpaceShadowGO != null)
                {
                    macroCloudMaterial.ApplyMaterialProperties(screenSpaceShadow.material, worldScale);
                    cloudsMat.ApplyMaterialProperties(screenSpaceShadow.material, worldScale);

                    screenSpaceShadow.material.SetFloat("_Radius", (float)radiusScaleLocal);
                    screenSpaceShadow.material.SetFloat("_PlanetRadius", (float)celestialBody.Radius * worldScale);

                    screenSpaceShadowGO.SetActive(layer == Tools.Layer.Local);
                    screenSpaceShadow.SetActive(layer == Tools.Layer.Local);
                }
            }
        }

        public void Remove()
        {
            if (CloudMesh != null)
            {
                CloudsManager.Log("Removing 2D clouds...");
                CloudMesh.transform.parent = null;
                GameObject.DestroyImmediate(CloudMesh);
                CloudMesh = null;
            }
            if(ShadowProjectorGO != null)
            {
                ShadowProjectorGO.transform.parent = null;
                ShadowProjector.transform.parent = null;
                GameObject.DestroyImmediate(ShadowProjector);
                GameObject.DestroyImmediate(ShadowProjectorGO);
                ShadowProjector = null;
                ShadowProjectorGO = null;
            }

            if (screenSpaceShadowGO != null)
            {
                screenSpaceShadowGO.transform.parent = null;
                GameObject.DestroyImmediate(screenSpaceShadowGO);
                screenSpaceShadowGO = null;
            }
        }

        internal void UpdateRotation(QuaternionD rotation, Matrix4x4 World2Planet, Matrix4x4 mainRotationMatrix, Matrix4x4 detailRotationMatrix)
        {
            if (rotation != null)
            {
                if (arc == 360) {
                    CloudMesh.transform.localRotation = rotation;
                } else {
                    var mat = mainRotationMatrix;
                    float w = Mathf.Sqrt(1.0f + mat.m00 + mat.m11 + mat.m22) / 2.0f;
                    CloudMesh.transform.localRotation = new Quaternion((mat.m21 - mat.m12) / (4.0f * w), (mat.m02 - mat.m20) / (4.0f * w), (mat.m10 - mat.m01) / (4.0f * w), w);
                }
                if (ShadowProjector != null && Sunlight != null)
                {
                    Vector3 worldSunDir;
                    Vector3 sunDirection;
                    //AtmosphereManager.Log("light: " + Sunlight.intensity);
                    //AtmosphereManager.Log("light: " + Sunlight.color);

                    worldSunDir = Vector3.Normalize(Sunlight.transform.forward);
                    sunDirection = Vector3.Normalize(ShadowProjector.transform.parent.InverseTransformDirection(worldSunDir));

                    ShadowProjector.transform.localPosition = radiusScaleLocal * -sunDirection;
                    ShadowProjector.transform.forward = worldSunDir;

                    if (Scaled)
                    {
                        ShadowProjector.material.SetVector(ShaderProperties.SUNDIR_PROPERTY, sunDirection); 
                    }
                    else if (screenSpaceShadowGO != null)
                    {
                        screenSpaceShadow.material.SetVector(ShaderProperties.SUNDIR_PROPERTY, worldSunDir);
                    }

                }
            }
            CloudMaterial.SetVector(ShaderProperties.PLANET_ORIGIN_PROPERTY, CloudMesh.transform.position);
            CloudMaterial.SetVector(ShaderProperties._UniveralTime_PROPERTY, UniversalTimeVector());
            
            SetRotations(World2Planet, mainRotationMatrix, detailRotationMatrix);

            if (cloudsMat.FlowMap != null && cloudsMat.FlowMap.Texture != null)
            {
                flowLoopTime += Time.deltaTime * TimeWarp.CurrentRate * cloudsMat.FlowMap.Speed;
                flowLoopTime = flowLoopTime % 1;

                CloudMaterial.SetFloat(ShaderProperties.flowLoopTime_PROPERTY, flowLoopTime);
            }
        }

        internal void SetOrbitFade(float fade)
        {
            CloudMaterial.SetFloat(ShaderProperties.scaledCloudFade_PROPERTY, fade);
        }

        internal void SetTimeFade(float fade, TimeFadeMode mode)
        {
            if (mode == TimeFadeMode.Density)
            { 
                CloudMaterial.SetFloat(ShaderProperties.cloudTimeFadeDensity_PROPERTY, fade);

                if (ShadowProjector != null)
                {
                    ShadowProjector.material.SetFloat(ShaderProperties.cloudTimeFadeDensity_PROPERTY, fade);
                    screenSpaceShadow.material.SetFloat(ShaderProperties.cloudTimeFadeDensity_PROPERTY, fade);
                }
            }
            if (mode == TimeFadeMode.Coverage)
            {
                CloudMaterial.SetFloat(ShaderProperties.cloudTimeFadeCoverage_PROPERTY, fade);

                if (ShadowProjector != null)
                {
                    ShadowProjector.material.SetFloat(ShaderProperties.cloudTimeFadeCoverage_PROPERTY, fade);
                    screenSpaceShadow.material.SetFloat(ShaderProperties.cloudTimeFadeCoverage_PROPERTY, fade);
                }
            }
        }

        // TODO: move to utils
        public static Vector4 UniversalTimeVector()
        {
            // We need to keep within low float exponents.
            float ut = (float)(Planetarium.GetUniversalTime() % 1000000); // will cause discontinuity every 46.3 game days.
            return new Vector4(ut / 20, ut, ut * 2, ut * 3);
        }

        private void SetRotations(Matrix4x4 World2Planet, Matrix4x4 mainRotation, Matrix4x4 detailRotation)
        {
            mainRotationMatrix = mainRotation;
            Matrix4x4 rotation = (mainRotation * World2Planet) * CloudMesh.transform.localToWorldMatrix;
            CloudMaterial.SetMatrix(ShaderProperties.MAIN_ROTATION_PROPERTY, rotation);
            CloudMaterial.SetMatrix(ShaderProperties.DETAIL_ROTATION_PROPERTY, detailRotation);

            if (ShadowProjector != null)
            {
                if(Scaled)
                {
                    ShadowProjector.material.SetMatrix(ShaderProperties.MAIN_ROTATION_PROPERTY, mainRotation);
                }
                else if (screenSpaceShadowGO != null)
                {
                    screenSpaceShadow.material.SetMatrix(ShaderProperties.MAIN_ROTATION_PROPERTY, mainRotation * screenSpaceShadowGO.transform.parent.worldToLocalMatrix);
                    screenSpaceShadow.material.SetVector(ShaderProperties.PLANET_ORIGIN_PROPERTY, screenSpaceShadowGO.transform.parent.position);

                    screenSpaceShadow.material.SetVector(ShaderProperties._UniveralTime_PROPERTY, UniversalTimeVector());
                    screenSpaceShadow.material.SetMatrix(ShaderProperties.DETAIL_ROTATION_PROPERTY, detailRotation);
                }
                ShadowProjector.material.SetVector(ShaderProperties._UniveralTime_PROPERTY, UniversalTimeVector());
                ShadowProjector.material.SetMatrix(ShaderProperties.DETAIL_ROTATION_PROPERTY, detailRotation);
            }
        }

    }
}
