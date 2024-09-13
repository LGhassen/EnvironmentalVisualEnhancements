Shader "EVE/InvisibleShadowCaster"
{
	SubShader 
	{
		Tags {"IgnoreProjector"="True" "RenderType"="Invisible"}

		Pass 
		{
			Tags {"LightMode" = "ForwardBase"}
			ZWrite Off
			ZTest Off

			CGPROGRAM
			#include "UnityCG.cginc"
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag

			struct v2f 
			{
				float4 pos : SV_POSITION;
			};

			v2f vert(appdata_base v)
			{
				v2f OUT;
				OUT.pos = float4(2.0, 2.0, 2.0, 1.0); //outside clip space => cull vertex
				return OUT;
			}

			float4 frag(v2f IN) : COLOR
			{
				return float4(0.0,0.0,0.0,0.0);			
			}

			ENDCG
		}

		Pass 
		{
			Tags { "LightMode" = "ShadowCaster" }
			ZWrite On
			ZTest Off

			CGPROGRAM
			#include "UnityCG.cginc"
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag

			 #pragma multi_compile_shadowcaster

			struct v2f 
			{
				float4 pos : SV_POSITION;
			};

			v2f vert(appdata_base v)
			{
				v2f OUT;
				OUT.pos = float4(2.0, 2.0, 2.0, 1.0); //outside clip space => cull vertex
				return OUT;
			}

			float4 frag(v2f IN) : COLOR
			{
				return float4(0.0,0.0,0.0,0.0);			
			}

			ENDCG
		}
	}
	
	Fallback Off
}