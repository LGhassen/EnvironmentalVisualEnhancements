// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "EVE/ScreenSpacePlanetLight" {
	Properties{
		_Color("Color Tint", Color) = (1,1,1,1)
			_SpecularColor("Specular tint", Color) = (1,1,1,1)
			_SpecularPower("Shininess", Float) = 0.078125
			_PlanetOpacity("PlanetOpacity", Float) = 1
			_SunPos("_SunPos", Vector) = (0,0,0)
			_SunRadius("_SunRadius", Float) = 1
			_bPos("_bPos", Vector) = (0,0,0)
			_bRadius("_bRadius", Float) = 1
	}
	Category{
		Lighting On
		ZWrite Off
		Cull Back
		Offset 0, 0
		//Blend SrcAlpha OneMinusSrcAlpha
		Blend Zero SrcColor //multiplicative
		Tags{
			"Queue" = "Geometry+2"
				"RenderMode" = "Transparent"
				"IgnoreProjector" = "True"
		}
		SubShader{
			Pass{

				Lighting On
				Tags{ "LightMode" = "ForwardBase" }

				CGPROGRAM

				#include "EVEUtils.cginc"
				#pragma target 3.0
				#pragma glsl
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest
				#pragma multi_compile_fwdbase
				#pragma multi_compile MAP_TYPE_1 MAP_TYPE_CUBE_1 MAP_TYPE_CUBE2_1 MAP_TYPE_CUBE6_1

				fixed4 _Color;
				float _SpecularPower;
				half4 _SpecularColor;

				uniform sampler2D _CameraDepthTexture;
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
#if defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)
					o.pos = float4(v.vertex.x, v.vertex.y *_ProjectionParams.x, -1.0 , 1.0);
#else
					o.pos = float4(v.vertex.x, v.vertex.y *_ProjectionParams.x, 1.0 , 1.0);
#endif
					o.uv = ComputeScreenPos(o.pos);

					return o;
				}


				fixed4 frag(v2f IN) : COLOR
				{
					half4 color = half4(1.0,1.0,1.0,1.0);

					float zdepth = tex2Dlod(_CameraDepthTexture, float4(IN.uv,0,0));

					float3 worldPos = getPreciseWorldPosFromDepth(IN.uv, zdepth, CameraToWorld);

					color.rgb = MultiBodyShadow(worldPos.xyz, _SunRadius, _SunPos, _ShadowBodies);

					float fadeout = (zdepth == 1.0) ? 0.0 : 1.0;				//don't render anything at or near clipping planes

					color.rgb = lerp(1.0,color.rgb,fadeout);

					return color;
				}
				ENDCG

			}
		}
	}
}