// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_Projector' with 'unity_Projector'

Shader "EVE/ScreenSpaceCloudShadow" {
	Properties{
		_Color("Color Tint", Color) = (1,1,1,1)
		_MainTex("Main (RGB)", 2D) = "white" {}
		_DetailTex("Detail (RGB)", 2D) = "white" {}
		_UVNoiseTex("UV Noise (RG)", 2D) = "black" {}
		_DetailScale("Detail Scale", float) = 100
		_DetailDist("Detail Distance", Range(0,1)) = 0.00875
		_UVNoiseScale("UV Noise Scale", Range(0,0.1)) = 0.01
		_UVNoiseStrength("UV Noise Strength", Range(0,0.1)) = 0.002
		_UVNoiseAnimation("UV Noise Animation", Vector) = (0.002,0.001,0)

		_PlanetOrigin("Sphere Center", Vector) = (0,0,0,1)
		_SunDir("Sunlight direction", Vector) = (0,0,0,1)
		_Radius("Radius", Float) = 1
		_PlanetRadius("Planet Radius", Float) = 1
		_ShadowFactor("Shadow Factor", Float) = 1
	
		_UniversalTime("Universal Time", Vector) = (0,0,0,0)
	}

	SubShader{
		Tags{ "Queue" = "Geometry+500" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Pass {
			Blend Zero SrcColor //multiplicative
			//Blend SrcAlpha OneMinusSrcAlpha // Traditional transparency
			ZWrite Off
			Offset 0, 0
			CGPROGRAM
			#include "EVEUtils.cginc"
			#pragma target 3.0
			#pragma glsl
			#pragma vertex vert
			#pragma fragment frag
#pragma multi_compile MAP_TYPE_1 MAP_TYPE_CUBE_1 MAP_TYPE_CUBE2_1 MAP_TYPE_CUBE6_1
#ifndef MAP_TYPE_CUBE2_1
#pragma multi_compile ALPHAMAP_N_1 ALPHAMAP_1
#endif

#include "alphaMap.cginc"
#include "cubeMap.cginc"

			CUBEMAP_DEF_1(_MainTex)

			fixed4 _Color;
			uniform sampler2D _DetailTex;
			uniform sampler2D _UVNoiseTex;
			fixed4 _DetailOffset;
			float _DetailScale;
			float _DetailDist;
			float _UVNoiseScale;
			float _UVNoiseStrength;
			float2 _UVNoiseAnimation;
			float4 _SunDir;
			float _Radius;
			float _PlanetRadius;
			float _ShadowFactor;

			float3 _PlanetOrigin;

			uniform sampler2D _CameraDepthTexture;
			float4x4 CameraToWorld;

			struct appdata_t {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2  uv : TEXCOORD0;
			};

			v2f vert(appdata_t v)
			{
				v2f o;
				v.vertex.y = v.vertex.y *_ProjectionParams.x;
				o.pos = float4(v.vertex.xy, 1.0, 1.0);
				o.uv = ComputeScreenPos(o.pos);

				return o;
			}

			fixed4 frag(v2f IN) : COLOR
			{
				float zdepth = tex2Dlod(_CameraDepthTexture, float4(IN.uv,0,0));


#ifdef SHADER_API_D3D11  //#if defined(UNITY_REVERSED_Z)
				zdepth = 1 - zdepth;
#endif

				float4 clipPos = float4(IN.uv, zdepth, 1.0);
				clipPos.xyz = 2.0f * clipPos.xyz - 1.0f;
				float4 camPos = mul(unity_CameraInvProjection, clipPos);

				float4 worldPos = mul(CameraToWorld,camPos);
				worldPos/=worldPos.w;

				float4 vertexPos = worldPos;
				float3 worldOrigin = _PlanetOrigin;

				float3 L = worldOrigin - vertexPos.xyz;
				float originDist = length(L);
				float tc = dot(L,-_SunDir);
				float ntc = dot(normalize(L), _SunDir);
				float d = sqrt(dot(L,L) - (tc*tc));
				float d2 = pow(d,2);
				float td = sqrt(dot(L,L) - d2);
				float sphereRadius = _Radius;
				float shadowCheck = step(originDist, sphereRadius)*saturate(ntc*100);
				//saturate((step(d, sphereRadius)*step(0.0, tc))+
				//(step(originDist, sphereRadius)));
				float tlc = sqrt((sphereRadius*sphereRadius) - d2);
				float sphereDist = lerp(lerp(tlc - td, tc - tlc, step(0.0, tc)),
					lerp(tlc - td, tc + tlc, step(0.0, tc)), step(originDist, sphereRadius));
				float4 planetPos = vertexPos + (-_SunDir*sphereDist);
				planetPos = (mul(_MainRotation, planetPos));
				float3 mainPos = planetPos.xyz;
				float3 detailPos = (mul(_DetailRotation, planetPos)).xyz;			

				//Ocean filter //this thing kills the precision, stock ocean writes to dbuffer anyway
				//shadowCheck *= saturate(.2*((originDist + 5) - _PlanetRadius));

				half4 main = GET_CUBE_MAP_P(_MainTex, mainPos, _UVNoiseTex, _UVNoiseScale, _UVNoiseStrength, _UVNoiseAnimation);
				main = ALPHA_COLOR_1(main);

				half4 detail = GetCubeDetailMap(_DetailTex, detailPos, _DetailScale);

				float viewDist = distance(worldPos.xyz,_WorldSpaceCameraPos);
				half detailLevel = saturate(2 * _DetailDist*viewDist);
				fixed4 color = _Color * main.rgba * lerp(detail.rgba, 1, detailLevel);

				color.rgb = saturate(color.rgb * (1- color.a));
				color.rgb = lerp(1, color.rgb, _ShadowFactor*color.a);
				return lerp(1, color, shadowCheck);
			}

			ENDCG
		}
	}
}