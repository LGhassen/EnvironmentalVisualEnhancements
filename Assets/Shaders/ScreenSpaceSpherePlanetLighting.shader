// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "EVE/ScreenSpacePlanetLight"
{
	Properties
	{
		_Color("Color Tint", Color) = (1,1,1,1)
			_SpecularColor("Specular tint", Color) = (1,1,1,1)
			_SpecularPower("Shininess", Float) = 0.078125
			_PlanetOpacity("PlanetOpacity", Float) = 1
			_SunPos("_SunPos", Vector) = (0,0,0)
			_SunRadius("_SunRadius", Float) = 1
			_bPos("_bPos", Vector) = (0,0,0)
			_bRadius("_bRadius", Float) = 1
	}
	Category
	{	
		ZWrite Off
		Cull Off
		ZTest Off
		
		Blend Zero SrcColor //multiplicative

		Tags{ "Queue" = "Geometry+2" "RenderMode" = "Transparent" "IgnoreProjector" = "True" }

		SubShader
		{
			Pass
			{
				CGPROGRAM

				#include "EVEUtils.cginc"
				#pragma target 3.0
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest

				fixed4 _Color;
				float _SpecularPower;
				half4 _SpecularColor;

				uniform sampler2D EVEDownscaledDepth;
				float4x4 CameraToWorld;

				struct appdata_t {
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float4 tangent : TANGENT;
				};

				struct v2f {
					float4 pos : SV_POSITION;
					float2  uv : TEXCOORD0;
				};

				v2f vert(appdata_t v)
				{
					v2f o;
					
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv = ComputeScreenPos(o.pos);

					return o;
				}


				fixed4 frag(v2f IN) : COLOR
				{
					half4 color = half4(1.0,1.0,1.0,1.0);

					float zdepth = tex2Dlod(EVEDownscaledDepth, float4(IN.uv,0,0));

				#if SHADER_API_D3D11
					if (zdepth == 0.0) {discard;}
				#else
					if (zdepth == 1.0) {discard;}
				#endif

					float3 worldPos = getPreciseWorldPosFromDepth(IN.uv, zdepth);

					color.rgb = MultiBodyShadow(worldPos.xyz, _SunRadius, _SunPos, _ShadowBodies);

					return color;
				}
				ENDCG

			}
		}
	}
}