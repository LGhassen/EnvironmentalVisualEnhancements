using EVEManager;
using ShaderLoader;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;
using Utils;

namespace Atmosphere
{
    public class WetSurfacesManager : GenericEVEManager<WetSurfacesConfig>
    {
        public override ObjectType objectType { get { return ObjectType.BODY; } }
        public override String configName { get { return "EVE_WET_SURFACES_CONFIG"; } }
        public override int LoadOrder { get { return 20; } }
        public override int DisplayOrder { get { return 60; } }

        private static WetSurfacesRenderer wetSurfacesRenderingManager;

        public static WetSurfacesRenderer RenderingManager { get => wetSurfacesRenderingManager; }

        public static WetSurfacesConfig GetConfig(string configName)
        {
            return GetObjectList().Find(x => x.Name == configName);
        }

        protected override void ApplyConfigNode(ConfigNode node)
        {
            if (!preconditionsPassed)
                return;

            if (!Tools.IsDeferredInstalled())
            {
                Log("[Error] Deferred not installed, wet surface effects won't be available");
                preconditionsPassed = false;
                return;
            }

            WetSurfacesConfig wetSurfacesConfig = new WetSurfacesConfig();
            wetSurfacesConfig.LoadConfigNode(node);

            var celestial = Tools.GetCelestialBody(wetSurfacesConfig.Body);

            if (celestial == null)
            {
                Log($"[Error] Body {celestial.name} not found for wet surfaces config: {wetSurfacesConfig.Name}");
            }

            var existingConfigForPlanet = ObjectList.FirstOrDefault(x => x.Body == wetSurfacesConfig.Body);

            if (existingConfigForPlanet == null)
            {
                wetSurfacesConfig.Apply();
                ObjectList.Add(wetSurfacesConfig);
            }
            else
            {
                Log($"[Error] Wet surfaces config already exists for {wetSurfacesConfig.Body}: {existingConfigForPlanet.Name}");
            }
        }



        bool preconditionsPassed = true;

        protected override void PostApplyConfigNodes()
        {
            if (ObjectList.Count > 0)
            {
                CloudsManager.Instance.Apply();

                if (wetSurfacesRenderingManager == null)
                {
                    wetSurfacesRenderingManager = new WetSurfacesRenderer();
                    wetSurfacesRenderingManager.Initialize();
                }
            }
        }

        public override void Update()
        {
            base.Update();

            if (wetSurfacesRenderingManager != null)
            {
                wetSurfacesRenderingManager.Update();
            }
        }
    }
}
