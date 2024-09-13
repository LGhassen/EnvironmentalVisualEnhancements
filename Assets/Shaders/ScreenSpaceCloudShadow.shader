﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

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
			
			ZWrite Off
			ZTest Off
			Cull Off

			CGPROGRAM
			#include "EVEUtils.cginc"
			#pragma target 3.0
			#pragma glsl
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile MAP_TYPE_1 MAP_TYPE_CUBE2_1 MAP_TYPE_CUBE6_1 MAP_TYPE_CUBE_1
			#ifndef MAP_TYPE_CUBE2_1
				#pragma multi_compile ALPHAMAP_N_1 ALPHAMAP_1
			#endif

			#pragma multi_compile VOLUMETRIC_CLOUD_SHADOW_OFF VOLUMETRIC_CLOUD_SHADOW_ON

			#if defined(VOLUMETRIC_CLOUD_SHADOW_ON)
				#define CLOUD_SHADOW_CASTER_OFF
				#define NOISE_MIPS_ON
				#pragma multi_compile NOISE_ON NOISE_OFF
				#pragma multi_compile NOISE_UNTILING_ON NOISE_UNTILING_OFF
				#pragma multi_compile CURL_NOISE_OFF CURL_NOISE_ON
				#pragma multi_compile FLOWMAP_OFF FLOWMAP_ON
			#endif


			#include "alphaMap.cginc"
			#include "cubeMap.cginc"
			#include "RaymarchedClouds/RaymarchedCloudUtils.cginc"
			#include "RaymarchedClouds/RaymarchedCloudShading.cginc"
			#include "RaymarchedClouds/RaymarchedCloudCore.cginc"

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

			float cloudTimeFadeCoverage;
			float cloudTimeFadeDensity;

			float3 _PlanetOrigin;

			uniform sampler2D scattererReconstructedCloud;
			sampler2D EVEDownscaledDepth;

			int BlendBetween2DShadowsAndLightVolume;

			#define DISTANCE_BLEND_START_DISTANCE 1000.0
			#define DISTANCE_BLEND_LENGTH 1500.0

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

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = ComputeScreenPos(o.pos);

				return o;
			}

			fixed4 frag(v2f IN) : COLOR
			{
				#if defined(VOLUMETRIC_CLOUD_SHADOW_ON)
					// sample reconstructed image bilinearly, check transmittance
					float cloudTransmittance = tex2Dlod(scattererReconstructedCloud, float4(IN.uv, 0.0, 0.0)).a;

					// if transmittance is zero exit early
					if (cloudTransmittance == 0.0) return 1.0.xxxx;
				#endif

				float zdepth = tex2Dlod(EVEDownscaledDepth, float4(IN.uv,0,0));

			#if SHADER_API_D3D11
				if (zdepth == 0.0) {discard;}
			#else
				if (zdepth == 1.0) {discard;}
			#endif

				float3 worldPos = getPreciseWorldPosFromDepth(IN.uv, zdepth);

				float dist = distance(worldPos, _WorldSpaceCameraPos);

				[branch]
				if (dist < DISTANCE_BLEND_START_DISTANCE && BlendBetween2DShadowsAndLightVolume > 0)
					return 1.0;

				float4 vertexPos = float4(worldPos,1.0);
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

				float3 cloudPos = planetPos.xyz;

#if !defined(VOLUMETRIC_CLOUD_SHADOW_ON)
				planetPos = (mul(_MainRotation, planetPos));
				float3 mainPos = planetPos.xyz;
				float3 detailPos = (mul(_DetailRotation, planetPos)).xyz;

				half4 main = GET_CUBE_MAP_P(_MainTex, mainPos, _UVNoiseTex, _UVNoiseScale, _UVNoiseStrength, _UVNoiseAnimation);
				main = ALPHA_COLOR_1(main);

				half4 detail = GetCubeDetailMap(_DetailTex, detailPos, _DetailScale);

				float viewDist = distance(worldPos,_WorldSpaceCameraPos);
				half detailLevel = saturate(2 * _DetailDist*viewDist);
				fixed4 color = _Color * main.rgba * lerp(detail.rgba, 1, detailLevel);

				color.a = RemapClamped(color.a, 1.0 - cloudTimeFadeCoverage, 1.0, 0.0, 1.0);

				color.rgb = saturate(color.rgb * (1- color.a));
				color.rgb = lerp(1, color.rgb, _ShadowFactor*color.a);
#endif

				float fadeout = clamp(0.01 * (sphereRadius - originDist), 0.0, 1.0);
				

#if defined(VOLUMETRIC_CLOUD_SHADOW_ON)
				float3 unused;
				float3 localColor;
				float cloudDensity = SampleCloudDensity(cloudPos.xyz, 1.0.xxxx, 0.0, localColor, unused);

				/*
				cloudDensity = saturate(cloudDensity * 4.0) * 0.65;

				float4 color = 1.0.xxxx;

				color.rgb = saturate(localColor.rgb * _Color.rgb * (1.0 - cloudDensity));
				color.rgb = lerp(1, color.rgb, cloudDensity * _ShadowFactor * _Color.a);
				*/

				float finalCloudTransmittance = fakedMultiScatteringBeerAbsorption(cloudDensity * 20.0, 1);

				float4 color = 1.0.xxxx;

				color.rgb = saturate(localColor.rgb * _Color.rgb * finalCloudTransmittance);
				color.rgb = lerp(1, color.rgb, (1.0 - finalCloudTransmittance) * _ShadowFactor * _Color.a);
#endif

				return lerp(1, color, shadowCheck*fadeout*cloudTimeFadeDensity);
			}

			ENDCG
		}
	}
}