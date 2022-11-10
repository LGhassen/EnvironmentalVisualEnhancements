using System;
using EVEManager;

namespace CityLights
{

    public class CityLightsManager: GenericEVEManager<CityLightsObject>   
    {
        public override ObjectType objectType { get { return ObjectType.BODY; } }
        public override String configName { get { return "EVE_CITY_LIGHTS"; } }

        protected override void PostApplyConfigNodes()
        {

        }

        public CityLightsManager()
        { }

    }
}
