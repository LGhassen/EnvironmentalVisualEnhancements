﻿using EVEManager;
using System;
using UnityEngine;
using Utils;

namespace Atmosphere
{
    public class CloudsMaterial : MaterialManager
    {
#pragma warning disable 0169
#pragma warning disable 0414
        [ConfigItem, Tooltip("Color to be applied to clouds.")]
        Color _Color = 255*Color.white;
        [ConfigItem, Index(1), ValueFilter("isClamped|format|type|alphaMask"), Tooltip("Main texture used with clouds.")]
        TextureWrapper _MainTex;
        [ConfigItem, ValueFilter("isClamped|format|type"), Tooltip("Normal map texture used with clouds.")]
        TextureWrapper _BumpMap;
        [ConfigItem]
        float _BumpScale = 0.1f;
        [ConfigItem, Index(999)]
        TextureWrapper _FlowMap;
        [ConfigItem]
        float _flowSpeed = 100f;
        [ConfigItem]
        float _flowStrength = 10f;
        [ConfigItem]
        TextureWrapper _DetailTex;
        [ConfigItem]
        TextureWrapper _UVNoiseTex;
        [ConfigItem]
        float _DetailScale = 200f;
        [ConfigItem, InverseScaled]
        float _DetailDist = 0.000002f;
        [ConfigItem, InverseScaled]
        float _DistFade = 1.0f;
        [ConfigItem, InverseScaled]
        float _DistFadeVert = 0.000085f;
        [ConfigItem]
        float _UVNoiseScale = 0.01f;
        [ConfigItem]
        float _UVNoiseStrength = 0.002f;
        [ConfigItem]
        Vector2 _UVNoiseAnimation = new Vector2(0.4f, 0.2f);

        public float DetailScale { get => _DetailScale; }
        public TextureWrapper DetailTex { get => _DetailTex; }

        public TextureWrapper FlowMap { get => _FlowMap; }

        
        public override void ApplyMaterialProperties(Material material, float scale = 1.0f)
        {
            base.ApplyMaterialProperties(material, scale);
            if (_FlowMap != null && material != null)
            {
                material.EnableKeyword("FLOWMAP_ON");
                material.DisableKeyword("FLOWMAP_OFF");
            }
            else
            {
                material.EnableKeyword("FLOWMAP_OFF");
                material.DisableKeyword("FLOWMAP_ON");
            }
        }
    }

    public enum TimeFadeMode
    {
        Coverage,
        Density,
    }

    public class TimeSettings   // all in seconds for now
    {
        [ConfigItem]
        float duration = 5400f; // 1.5 hours

        [ConfigItem]
        float offset = 0f;

        [ConfigItem]
        float repeatInterval = 66960f; // 3.1 Kerbin days

        [ConfigItem]
        float fadeTime = 300f;

        [ConfigItem]
        TimeFadeMode fadeMode = TimeFadeMode.Density;

        public bool IsEnabled(out float currentFade)
        {
            double ut = 0.0;

            if (HighLogic.LoadedScene == GameScenes.MAINMENU)
            {
                ut = Time.time;
            }
            else
            {
                ut = Planetarium.GetUniversalTime();
            }

            ut += repeatInterval - offset;

            ut = ut % repeatInterval;

            if (ut > duration)
            {
                currentFade = 0f;
                return false;
            }

            if (ut < fadeTime)
                currentFade = (float)(ut / fadeTime);
            else if (ut > duration - fadeTime)
                currentFade = (float)(1.0 - (ut - (duration - fadeTime)) / fadeTime);
            else
                currentFade = 1.0f;

            return true;
        }

        public TimeFadeMode GetFadeMode()
        {
            return fadeMode;
        }
    }

    [ConfigName("name")]
    public class CloudsObject : MonoBehaviour, IEVEObject
    {
#pragma warning disable 0649
        [ConfigItem, GUIHidden]
        new String name;
        [ConfigItem, GUIHidden]
        String body;

        public string Name { get => name; }
        public string Body { get => body; }

        [ConfigItem, Tooltip("Altitude above sea level for clouds.")]
        float altitude = 1000f;
        [ConfigItem, Tooltip("Enabling this will stop the cloud from moving with the celestial body.")]
        bool killBodyRotation = false;
        [ConfigItem, Tooltip("Speed of rotation (m/s) applied to main texture of"+
                             "\n each axis of rotation." +
                             "\n First value is applied to axis0, etc.")]
        Vector3 speed = new Vector3(0, 30, 0);
        [ConfigItem, Tooltip("Speed of detail rotation (m/s) applied to XYZ axis of rotation.")]
        Vector3 detailSpeed = new Vector3(0,5,0);
        [ConfigItem, Tooltip("Offset of texturing in degrees around Axis below")]
        Vector3 offset = new Vector3(0, 0, 0);
        [ConfigItem, Tooltip("Axis0 [Default is X-Axis]")]
        Vector3 rotationAxis0 = new Vector3(1,0,0);
        [ConfigItem, Tooltip("Axis1 [Default is Y-Axis]")]
        Vector3 rotationAxis1 = new Vector3(0, 1, 0);
        [ConfigItem, Tooltip("Axis2 [Default is Z-Axis]")]
        Vector3 rotationAxis2 = new Vector3(0, 0, 1);
        [ConfigItem, Tooltip("Amount of sphere covered")]
        float arc = 360f;

        [ConfigItem, Tooltip("Settings for the cloud rendering")]
        CloudsMaterial settings = null;

        [ConfigItem, Optional, Tooltip("Settings to enable/disable clouds temporally")]
        TimeSettings timeSettings = null;

        [ConfigItem, Optional]
        Clouds2D layer2D = null;

        [ConfigItem, Optional]
        CloudsVolume layerVolume = null;

        [ConfigItem, Optional]
        CloudsRaymarchedVolume layerRaymarchedVolume = null;

        public CloudsRaymarchedVolume LayerRaymarchedVolume { get => layerRaymarchedVolume;}

        private CloudsPQS cloudsPQS = null;
        private CelestialBody celestialBody;
        private Transform scaledCelestialTransform;


        public void LoadConfigNode(ConfigNode node)
        {
            ConfigHelper.LoadObjectFromConfig(this, node);
        }

        public void Apply()
        {
            celestialBody = Tools.GetCelestialBody(body);
            scaledCelestialTransform = Tools.GetScaledTransform(body);
            
            GameObject go = new GameObject();
            cloudsPQS = go.AddComponent<CloudsPQS>();
            go.name = "EVE Clouds: "+ this.name;
            Matrix4x4 rotationAxis = new Matrix4x4();
            rotationAxis.SetRow(0, rotationAxis0);
            rotationAxis.SetRow(1, rotationAxis1);
            rotationAxis.SetRow(2, rotationAxis2);
            cloudsPQS.Apply(body, settings, layer2D, layerVolume, layerRaymarchedVolume, altitude, arc, speed, detailSpeed, offset, rotationAxis, killBodyRotation, timeSettings);
        }

        public void Remove()
        {
            cloudsPQS.Remove();
            GameObject go = cloudsPQS.gameObject;
            GameObject.DestroyImmediate(cloudsPQS);
            GameObject.DestroyImmediate(go);

        }

    }
}
