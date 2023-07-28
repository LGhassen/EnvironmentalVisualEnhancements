using EVEManager;
using System;

namespace Atmosphere
{

    public class DropletsManager : GenericEVEManager<DropletsConfig>
    {
        public override ObjectType objectType { get { return ObjectType.STATIC | ObjectType.MULTIPLE; } }
        public override String configName { get { return "EVE_DROPLETS_CONFIG"; } }
        public override int LoadOrder { get { return 20; } }

        public static DropletsConfig GetConfig(string configName)
        {
            return DropletsManager.GetObjectList().Find(x => x.Name == configName);
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
