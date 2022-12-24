using EVEManager;
using System;
using System.Collections.Generic;
using UnityEngine;
using Utils;
using System.Linq;

namespace Atmosphere
{
    public class CloudPainterManager : EVEManagerBase
    {
        public override bool DelayedLoad { get { return true; } }
        public override GameScenes SceneLoad { get { return GameScenes.MAINMENU; } }
        public override int LoadOrder { get { return 100; } }

        public override String ToString() { return this.GetType().Name; }
        
        protected static UrlDir.UrlConfig[] configs;
        protected override UrlDir.UrlConfig[] Configs { get { return configs; } set { configs = value; } }
        protected static List<ConfigWrapper> configFiles = new List<ConfigWrapper>();
        protected override List<ConfigWrapper> ConfigFiles { get { return configFiles; } }

        public override String configName { get { return "EVE_CLOUDS_PAINTER"; } }

        Dictionary<Tuple<string, string>, CloudsPainter> paintersDictionary = new Dictionary<Tuple<string, string>, CloudsPainter>(); // cloud painters by body and layername

        int selectedObjIndex;

        protected override void Clean()
        {

        }

        public void RetargetClouds()
        {
            foreach (var painter in paintersDictionary.Values)
            {
                painter.RetargetClouds();
            }
        }

        public override void DrawGUI(Rect placementBase, Rect placement)
        {
            placement.height = 1;
            string body = GUIHelper.DrawBodySelector(placementBase, ref placement);
            placement.y += 1 + GUIHelper.spacingOffset;

            var layerList = CloudsManager.GetObjectList().Where(x => x.Body == body).ToList();

            placement.height = layerList.Count + 1;
            Rect selectBoxRect = GUIHelper.GetRect(placementBase, ref placement);
            placement.height = layerList.Count;
            Rect selectBoxItemsRect = GUIHelper.GetRect(placementBase, ref placement);

            int oldselectedObjIndex = selectedObjIndex;
            if (selectedObjIndex == -1)
            {
                selectedObjIndex = 0;
            }
            selectedObjIndex = GUI.SelectionGrid(selectBoxItemsRect, selectedObjIndex, layerList.Select(x => x.Name).ToArray(), 1);
            placement.y += placement.height + 1 + 2.0f * GUIHelper.spacingOffset;


            if (selectedObjIndex > -1)
            {
                var key = new Tuple<string, string>(body, layerList[selectedObjIndex].Name);

                if (paintersDictionary.ContainsKey(key))
                {
                    var painter = paintersDictionary[key];
                    painter.DrawGUI(placementBase, ref placement);
                    painter.Paint();
                }
                else
                {
                    placement.height = 1;
                    Rect buttonRect = GUIHelper.GetRect(placementBase, ref placement);

                    if (GUI.Button(buttonRect, "Paint selected layer"))
                    {
                        var cloudsPainter = new CloudsPainter();
                        cloudsPainter.Init(body, layerList[selectedObjIndex]);

                        paintersDictionary[key] = cloudsPainter;
                    }

                }
            }
        }

        protected override void ApplyConfigNode(ConfigNode node)
        {

        }

        public override void Setup()
        {
        }

        protected override void PostApplyConfigNodes()
        {

        }

        public override ObjectType objectType { get { return ObjectType.BODY | ObjectType.MULTIPLE; } }
    }
}
