using EVEManager;
using ShaderLoader;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using UnityEngine;
using Utils;

namespace CelestialShadows
{
    
    public class ScaledShadowComponent : MonoBehaviour
    {
        Material shadowMat;
        CelestialBody body;
        List<CelestialBody> shadowList;
        public String GUID { get { return shadowMat.name; } }

        internal void Apply(Material mat, CelestialBody cb, List<CelestialBody> list)
        {
            shadowMat = mat;
            body = cb;
            shadowList = list;
        }

        internal void OnWillRenderObject()
        {
            if (HighLogic.LoadedScene != GameScenes.MAINMENU)
            {
                Matrix4x4 bodies = Matrix4x4.zero;
                int i = 0;
                foreach (CelestialBody cb in shadowList)
                {
                    if (cb != null && cb.transform != null)
                    {
                        bodies.SetRow(i, cb.scaledBody.transform.position);
                        bodies[i, 3] = (float)(ScaledSpace.InverseScaleFactor * cb.Radius);
                        i++;
                        if (i == 4)
                            break;
                    }
                }
                if (shadowMat != null)
                {
                    shadowMat.SetVector(ShaderProperties._SunPos_PROPERTY, Sun.Instance.sun.scaledBody.transform.position);
                    shadowMat.SetMatrix(ShaderProperties._ShadowBodies_PROPERTY, bodies);
                }

                foreach (Transform child in body.scaledBody.transform)
                {
                    Renderer cr = child.GetComponent<Renderer>();
                    if (cr != null && cr.sharedMaterial != null)
                    {
                        cr.sharedMaterial.SetFloat(ShaderProperties._SunRadius_PROPERTY, (float)(ScaledSpace.InverseScaleFactor * Sun.Instance.sun.Radius));
                        cr.sharedMaterial.SetVector(ShaderProperties._SunPos_PROPERTY, Sun.Instance.sun.scaledBody.transform.position);
                        cr.sharedMaterial.SetMatrix(ShaderProperties._ShadowBodies_PROPERTY, bodies);
                    }
                }
            }
        }
    }

    public class LocalShadowComponent : MonoBehaviour
    {
        Material shadowMat;
        CelestialBody body;
        List<CelestialBody> shadowList;
        public String GUID { get { return shadowMat.name; } }
        GameObject screenSpaceShadowGO;
        ScreenSpaceShadow screenSpaceShadow;

        internal void Apply(Material mat, CelestialBody cb, List<CelestialBody> list, GameObject go, ScreenSpaceShadow scShadow)
        {
            shadowMat = mat;
            body = cb;
            shadowList = list;
            screenSpaceShadowGO = go;
            screenSpaceShadow = scShadow;
        }

        internal void OnPreCull()
        {
            if (HighLogic.LoadedScene != GameScenes.MAINMENU && screenSpaceShadowGO != null && body.pqsController != null)
            {
                Matrix4x4 bodies = Matrix4x4.zero;
                int i = 0;
                foreach (CelestialBody cb in shadowList)
                {
                    if (cb != null && cb.transform != null)
                    {
                        bodies.SetRow(i, cb.transform.position);
                        bodies[i, 3] = (float)(cb.Radius);
                        i++;
                        if (i == 4)
                            break;
                    }
                }

                if (shadowMat != null)
                {
                    shadowMat.SetVector(ShaderProperties._SunPos_PROPERTY, Sun.Instance.sun.transform.position);
                    shadowMat.SetMatrix(ShaderProperties._ShadowBodies_PROPERTY, bodies);
                }

                screenSpaceShadowGO.SetActive(body.pqsController.isActive);
                screenSpaceShadow.SetActive(body.pqsController.isActive);
            }
        }
    }

    internal class ShadowMat : MaterialManager
    {
        float _SunRadius = 0f;
        Vector3 _SunPos = Vector3.zero;
        Matrix4x4 _ShadowBodies = Matrix4x4.zero;
    } 

    public class ShadowObject : IEVEObject
    {
#pragma warning disable 0649
        [ConfigItem, GUIHidden]
        private String body;
        /* [ConfigItem]
         ShadowMaterial shadowMaterial = null;
         */
        [ConfigItem]
        List<String> caster = null;
        [ConfigItem]
        bool hasSurface = true;

        String materialName = Guid.NewGuid().ToString();
        Material shadowMat;
        Material localShadowMat;
        ScreenSpaceShadow screenSpaceShadow;
        GameObject screenSpaceShadowGO = null;

        private static Shader shadowShader;
        private static Shader ShadowShader
        {
            get
            {
                if (shadowShader == null)
                {
                    shadowShader = ShaderLoaderClass.FindShader("EVE/PlanetLight");
                }
                return shadowShader;
            }
        }

        private static Shader screenSpaceShadowShader;
        private static Shader ScreenSpaceShadowShader
        {
            get
            {
                if (screenSpaceShadowShader == null)
                {
                    screenSpaceShadowShader = ShaderLoaderClass.FindShader("EVE/ScreenSpacePlanetLight");
                }
                return screenSpaceShadowShader;
            }
        }


        public void LoadConfigNode(ConfigNode node)
        {
            ConfigHelper.LoadObjectFromConfig(this, node);
        }

        public void Apply()
        {
            ShadowManager.Log("Applying to " + body);
            CelestialBody celestialBody = Tools.GetCelestialBody(body);
            
            Transform transform = Tools.GetScaledTransform(body);
            if (transform != null )
            {
                Renderer mr = transform.GetComponent<Renderer>();
                if (mr != null && hasSurface)
                {
                    shadowMat = new Material(ShadowShader);
                    GameObject go = new GameObject();
                    go.name = "EVE Shadows";

                    localShadowMat = new Material(ScreenSpaceShadowShader);

                    screenSpaceShadowGO = new GameObject("EVE Celestial ScreenSpaceShadow");
                    screenSpaceShadowGO.transform.parent = celestialBody.transform;
                    screenSpaceShadow = screenSpaceShadowGO.AddComponent<ScreenSpaceShadow>();
                    screenSpaceShadow.material = localShadowMat;
                    screenSpaceShadow.Init();
                    screenSpaceShadowGO.SetActive(false);
                    screenSpaceShadow.SetActive(false);

                    shadowMat.SetFloat(ShaderProperties._SunRadius_PROPERTY, (float)(ScaledSpace.InverseScaleFactor * Sun.Instance.sun.Radius));
                    localShadowMat.SetFloat(ShaderProperties._SunRadius_PROPERTY, (float)(Sun.Instance.sun.Radius));

                    shadowMat.name = materialName;
                    shadowMat.renderQueue = (int)Tools.Queue.Geometry + 1;

                    localShadowMat.name = materialName;
                    localShadowMat.renderQueue = (int)Tools.Queue.Geometry + 3;

                    DeferredRenderer.Add(mr.gameObject, shadowMat);
                }
                
                ScaledShadowComponent sc = transform.gameObject.AddComponent<ScaledShadowComponent>();
                LocalShadowComponent lsc = FlightCamera.fetch.mainCamera.gameObject.AddComponent<LocalShadowComponent>();

                List<CelestialBody> casters = new List<CelestialBody>();
                if (caster != null)
                {
                    foreach (String b in caster)
                    {
                        casters.Add(Tools.GetCelestialBody(b));
                    }
                }
                sc.Apply(shadowMat, celestialBody, casters);
                lsc.Apply(localShadowMat, celestialBody, casters, screenSpaceShadowGO, screenSpaceShadow);
            }

            ApplyToMainMenu();

            GameEvents.onGameSceneLoadRequested.Add(SceneLoaded);
            if (HighLogic.LoadedScene == GameScenes.MAINMENU)
            {
                ApplyToMainMenu();
            }
        }

        private void SceneLoaded(GameScenes scene)
        {
            if (scene == GameScenes.MAINMENU)
            {
                ApplyToMainMenu();
            }
        }

        private void ApplyToMainMenu()
        {
            if (HighLogic.LoadedScene == GameScenes.MAINMENU)
            {
                GameObject go = Tools.GetMainMenuObject(body);
                
                if(go != null)
                {
                    foreach (Transform child in go.transform)
                    {
                        Renderer cr = child.GetComponent<Renderer>();
                        if (cr != null)
                        {
                            cr.sharedMaterial.SetMatrix("_ShadowBodies", Matrix4x4.zero);
                        }
                    }
                }
            }
        }


        public void Remove()
        {
            CelestialBody celestialBody = Tools.GetCelestialBody(body);
            ShadowManager.Log("Removing Shadow obj");
            Transform transform = Tools.GetScaledTransform(body);
            if (transform != null)
            {
                GameObject.DestroyImmediate(transform.gameObject.GetComponents<ScaledShadowComponent>().First(sc => sc.GUID == materialName));
                
                LocalShadowComponent lc = FlightCamera.fetch.mainCamera.gameObject.GetComponents<LocalShadowComponent>().FirstOrDefault(sc => sc.GUID == materialName);
                if (lc != null)
                {
                    GameObject.DestroyImmediate(lc);
                }

                DeferredRenderer.Remove(transform.gameObject, shadowMat);
            }

            GameObject.DestroyImmediate(screenSpaceShadowGO);
            GameEvents.onGameSceneLoadRequested.Remove(SceneLoaded);
        }
    }
}
