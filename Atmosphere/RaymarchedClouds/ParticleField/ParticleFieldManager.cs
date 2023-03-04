using EVEManager;
using System;

namespace Atmosphere
{

    public class ParticleFieldManager : GenericEVEManager<ParticleFieldConfig>
    {
        public override ObjectType objectType { get { return ObjectType.STATIC | ObjectType.MULTIPLE; } }
        public override String configName { get { return "EVE_PARTICLE_FIELD_CONFIG"; } }
        public override int LoadOrder { get { return 20; } }

        public static ParticleFieldConfig GetConfig(string configName)
        {
            return ParticleFieldManager.GetObjectList().Find(x => x.Name == configName);
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
