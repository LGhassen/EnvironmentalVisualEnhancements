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

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			#ifndef SHADER_API_D3D11
				float4 worldPos : TEXCOORD1;
				float4 screenPos : TEXCOORD2;
			#endif
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				int2 intIndexes = randomIndexes* (lightningSheetCount-float2(0.00001,0.00001));

				//transform the UVs to reflect the sheet
				o.uv /= lightningSheetCount;

				//offset by our indexes
				o.uv += intIndexes / lightningSheetCount;

			#ifndef SHADER_API_D3D11
				o.worldPos = mul(unity_ObjectToWorld,v.vertex);
				o.screenPos = ComputeScreenPos(o.pos);

				if ( _ProjectionParams.y < 200.0 && _ProjectionParams.z < 2000.0)
				{
					o.pos.z = (1.0 - 0.00000000000001);
				}
			#endif

				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv) * color;

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
						
				// time fade alpha
				col.a*=alpha;

				return col;
			}
			ENDCG
		}
	}
}
