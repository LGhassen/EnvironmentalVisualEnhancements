using EVEManager;
using System;

namespace Atmosphere
{

    public class WetSurfacesManager : GenericEVEManager<WetSurfacesConfig>
    {
        public override ObjectType objectType { get { return ObjectType.STATIC | ObjectType.MULTIPLE; } }
        public override String configName { get { return "EVE_WET_SURFACES_CONFIG"; } }
        public override int LoadOrder { get { return 20; } }

        public static WetSurfacesConfig GetConfig(string configName)
        {
            return WetSurfacesManager.GetObjectList().Find(x => x.Name == configName);
        }

        protected override void PostApplyConfigNodes()
        {
            if (ObjectList.Count > 0)
            {
                CloudsManager.Instance.Apply();
            }
        }
    }
}
