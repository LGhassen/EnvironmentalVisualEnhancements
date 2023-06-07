using EVEManager;
using System;

namespace Atmosphere
{
    public class LightningManager : GenericEVEManager<LightningConfig>
    {
        public override ObjectType objectType { get { return ObjectType.STATIC | ObjectType.MULTIPLE; } }
        public override String configName { get { return "EVE_LIGHTNING_CONFIG"; } }
        public override int LoadOrder { get { return 20; } }

        public static LightningConfig GetConfig(string configName)
        {
            return LightningManager.GetObjectList().Find(x => x.Name == configName);
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
