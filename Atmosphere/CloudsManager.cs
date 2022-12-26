﻿using EVEManager;
using System;
using UnityEngine;
using Utils;

namespace Atmosphere
{
    public class CloudsManager : GenericEVEManager<CloudsObject>
    {
        public override ObjectType objectType { get { return ObjectType.BODY | ObjectType.MULTIPLE; } }
        public override String configName { get{return "EVE_CLOUDS";} }

        public override int DisplayOrder { get { return 90; } }

        public static EventVoid onApply;

        public CloudsManager():base()
        {
            onApply = new EventVoid("onCloudsApply");
        }

        protected override void ApplyConfigNode(ConfigNode node)
        {
            GameObject go = new GameObject("CloudsManager");
            CloudsObject newObject = go.AddComponent<CloudsObject>();
            go.transform.parent = Tools.GetCelestialBody(node.GetValue(ConfigHelper.BODY_FIELD)).bodyTransform;
            newObject.LoadConfigNode(node);
            ObjectList.Add(newObject);
            newObject.Apply();
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
        }
    }
}
