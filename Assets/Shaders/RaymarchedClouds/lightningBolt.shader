Shader "EVE/LightningBolt"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" }

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha

			Cull Off
			ZTest On
			ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float alpha;
			float2 lightningSheetCount;
			float2 randomIndexes;

			float4 color;

			sampler2D combinedOpenGLDistanceBuffer;
			sampler2D lightningOcclusion;
			float lightningIndex;
			float maxConcurrentLightning;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 lightningSheetUV : TEXCOORD0;
				float2 occlusionUV : TEXCOORD1;
			#ifndef SHADER_API_D3D11
				float4 worldPos : TEXCOORD2;
				float4 screenPos : TEXCOORD3;
			#endif
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				int2 intIndexes = randomIndexes * (lightningSheetCount-float2(0.00001,0.00001));
				o.lightningSheetUV = (TRANSFORM_TEX(v.uv, _MainTex) + intIndexes) / lightningSheetCount;

				o.occlusionUV = v.vertex.xy * 0.5 + 0.5.xx;
				o.occlusionUV.x = (o.occlusionUV.x + lightningIndex) / maxConcurrentLightning;

			#if SHADER_API_D3D11 || SHADER_API_D3D || SHADER_API_D3D12
				if (_ProjectionParams.x > 0) {o.occlusionUV.y = 1.0 - o.occlusionUV.y;}
			#endif

			#ifndef SHADER_API_D3D11
				o.worldPos = mul(unity_ObjectToWorld,v.vertex);
				o.screenPos = ComputeScreenPos(o.pos);
				if ( _ProjectionParams.y < 200.0 && _ProjectionParams.z < 2000.0) o.pos.z = (1.0 - 0.00000000000001);
			#endif
				
				return o;
			}

			float4 frag (v2f i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.lightningSheetUV) * color;

			#ifndef SHADER_API_D3D11
				if ( _ProjectionParams.y < 200.0 && _ProjectionParams.z < 2000.0) // only on the near camera
				{
					float terrainDistance = tex2Dlod(combinedOpenGLDistanceBuffer, float4(i.screenPos.xy/i.screenPos.w,0,0)).r* 750000;
					
					float3 worldPos = i.worldPos.xyz/i.worldPos.w;
					float fragDistance = length(worldPos - _WorldSpaceCameraPos.xyz);

					if (fragDistance >= terrainDistance)
						discard;
				}
			#endif

				float occlusion = tex2Dlod(lightningOcclusion, float4(i.occlusionUV,0,0)).r;
				occlusion = 1.0-exp(-15.0 * occlusion); // make it so that bolts can mostly cut through most fog and thin areas, but still get fully occluded by fully opaque clouds
				
				//time fade alpha and apply occlusion
				col.a*=alpha * occlusion;

				return col;
			}
			ENDCG
		}
	}
}
