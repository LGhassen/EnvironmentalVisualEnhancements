using EVEManager;
using System;
using UnityEngine;
using Utils;
using System.Collections.Generic;
using System.Linq;


namespace Atmosphere
{
    public class CloudsManager : GenericEVEManager<CloudsObject>
    {
        public override ObjectType objectType { get { return ObjectType.BODY | ObjectType.MULTIPLE; } }
        public override String configName { get{return "EVE_CLOUDS";} }

        public override int DisplayOrder { get { return 90; } }

        public static EventVoid onApply;

        private List<CelestialBodyCloudsHandler> celestialBodyCloudsHandlers = new List<CelestialBodyCloudsHandler>();

        int currentBodyIndex = 0;

        public CloudsManager():base()
        {
            onApply = new EventVoid("onCloudsApply");
        }

        public override void Apply()
        {
            Clean();
            PreprocessConfigs();
        }

        private void PreprocessConfigs()
        {
            foreach (UrlDir.UrlConfig config in Configs)
            {
                foreach (ConfigNode node in config.config.nodes)
                {
                    var cb = Tools.GetCelestialBody(node.GetValue(ConfigHelper.BODY_FIELD));

                    if (cb != null)
                    {
                        var handler = celestialBodyCloudsHandlers.Find(x => x.CelestialBody == cb);

                        if (handler != null)
                        {
                            handler.AddConfigNode(node);
                        }
                        else
                        {
                            handler = new CelestialBodyCloudsHandler(cb, new List<ConfigNode>() { node });
                            celestialBodyCloudsHandlers.Add(handler);
                        }
                    }
                }
            }
        }

        public override void Update()
        {
            base.Update();

            bool updated = false;
            
            // update only one body per frame for max scalability
            var celestialBodyCloudsHandlersCount = celestialBodyCloudsHandlers.Count;
            if (celestialBodyCloudsHandlersCount > 0)
            {
                if (currentBodyIndex >= celestialBodyCloudsHandlersCount) currentBodyIndex = 0;
                if (celestialBodyCloudsHandlers[currentBodyIndex].Update(ObjectList))
                    updated = true;

                currentBodyIndex++;
            }

            if (updated)
                PostApplyConfigNodes();
        }

        protected override void ApplyConfigNode(ConfigNode node)
        {
        }

        protected override void PostApplyConfigNodes()
        {
            SetInterCloudShadows();
            onApply.Fire();
        }

        private void SetInterCloudShadows()
        {
            foreach(var cloudsObject in ObjectList)
            {
                if (!String.IsNullOrEmpty(cloudsObject.LayerRaymarchedVolume?.ReceiveShadowsFromLayer))
                {
                    var shadowCaster = ObjectList.Find(x => x.Body == cloudsObject.Body && x.Name == cloudsObject.LayerRaymarchedVolume.ReceiveShadowsFromLayer);

                    if (shadowCaster != null && shadowCaster.LayerRaymarchedVolume != null)
                    {
                        cloudsObject.LayerRaymarchedVolume.SetShadowCasterLayerRaymarchedVolume(shadowCaster.LayerRaymarchedVolume);
                    }
                }
            }

            foreach(CloudPainterManager CloudPainterManager in GlobalEVEManager.GetManagersOfType(typeof(CloudPainterManager)))
            {
                CloudPainterManager.RetargetClouds();
            }
        }

        protected override void Clean()
        {
            CloudsManager.Log("Cleaning Clouds!");
            foreach (CloudsObject obj in ObjectList)
            {
                obj.Remove();
                GameObject go = obj.gameObject;
                go.transform.parent = null;

                GameObject.DestroyImmediate(obj);
                GameObject.DestroyImmediate(go);
            }
            ObjectList.Clear();
            celestialBodyCloudsHandlers.Clear();
        }
    }

    public class CelestialBodyCloudsHandler
    {
        CelestialBody celestialBody;
        Transform scaledTransform;
        GameObject mainMenuGO;
        List<ConfigNode> configNodes;
        bool isLoaded;
        bool hasRaymarchedVolumetrics;
        double loadDistance, unloadDistance;

        static Camera mainMenuCamera = null;

        public CelestialBody CelestialBody { get => celestialBody; }

        public CelestialBodyCloudsHandler(CelestialBody cb, List<ConfigNode> cn)
        {
            celestialBody = cb;
            scaledTransform = Tools.GetScaledTransform(cb.name);
            configNodes = cn;
            isLoaded = false;
            hasRaymarchedVolumetrics = false;

            loadDistance   = 2000.0 * celestialBody.Radius;
            unloadDistance = 4000.0 * celestialBody.Radius;
        }

        public void AddConfigNode(ConfigNode cn)
        {
            configNodes.Add(cn);

            if (cn.HasNode("layerRaymarchedVolume")) hasRaymarchedVolumetrics = true;
        }

        public bool Update(List<CloudsObject> objectList)
        {
            double minDistance = Vector3d.Distance(ScaledCamera.Instance.transform.position, scaledTransform.position) * ScaledSpace.ScaleFactor;

            if (FlightGlobals.ActiveVessel != null)
                minDistance = Math.Min(minDistance, Vector3d.Distance(FlightGlobals.ActiveVessel.transform.position, celestialBody.position));

            minDistance = HandleMainMenu(minDistance);

            if (isLoaded)
            {
                if (minDistance > unloadDistance)
                {
                    UnloadBody(objectList);
                    return true;
                }
            }
            else
            {
                if (minDistance < loadDistance)
                {
                    LoadBody(objectList);
                    return true;
                }
            }

            return false;
        }

        private double HandleMainMenu(double minDistance)
        {
            if (HighLogic.LoadedScene == GameScenes.MAINMENU)
            {
                if (mainMenuCamera == null)
                {
                    mainMenuCamera = Camera.allCameras.Single(_cam => _cam.name == "Landscape Camera");
                }

                if (mainMenuGO == null)
                {
                    mainMenuGO = Tools.GetMainMenuObject(celestialBody.name);
                }

                if (mainMenuCamera != null && mainMenuGO != null && mainMenuGO.activeInHierarchy)
                {
                    // check if the object's position is within the camera frustum
                    Vector3 viewport = mainMenuCamera.WorldToViewportPoint(mainMenuGO.transform.position);

                    if (viewport.x > 0 && viewport.x < 1 && viewport.y > 0 && viewport.y < 1 && viewport.z > 0)
                    {
                        minDistance = 0.0;
                    }
                    else
                    {
                        minDistance = double.PositiveInfinity;
                    }
                }
            }

            return minDistance;
        }

        void LoadBody(List<CloudsObject> objectList)
        {
            CloudsManager.Log("Loading body " + celestialBody.name);

            foreach (ConfigNode node in configNodes)
            {
                if (node.HasNode("layerVolume") && hasRaymarchedVolumetrics) continue;

                try
                {
                    ApplyConfigNode(node, objectList);
                }
                catch (Exception e)
                {
                    Debug.LogError("Unable to parse config node:\n" + node.ToString() + "\nException:\n" + e.ToString());
                }
            }

            isLoaded = true;

            CloudsManager.Log("Loaded body " + celestialBody.name);
        }

        void ApplyConfigNode(ConfigNode node, List<CloudsObject> objectList)
        {
            GameObject go = new GameObject("CloudsManager");
            CloudsObject newObject = go.AddComponent<CloudsObject>();
            go.transform.parent = Tools.GetCelestialBody(node.GetValue(ConfigHelper.BODY_FIELD)).bodyTransform;
            newObject.LoadConfigNode(node);
            objectList.Add(newObject);
            newObject.Apply();
        }

        void UnloadBody(List<CloudsObject> objectList)
        {
            CloudsManager.Log("Unloading body " + celestialBody.name);

            foreach (CloudsObject obj in objectList.Where(x=>x.Body == celestialBody.name).ToList())
            {
                obj.Remove();
                GameObject go = obj.gameObject;
                go.transform.parent = null;

                GameObject.DestroyImmediate(obj);
                GameObject.DestroyImmediate(go);

                objectList.Remove(obj);
            }

            isLoaded = false;

            CloudsManager.Log("Unloaded body " + celestialBody.name);
        }
    }
}
