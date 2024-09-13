Shader "EVE/DownscaleDepth"
{
	SubShader
	{
		Pass // Pass 0 downscale camera depth
		{
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			Texture2D _CameraDepthTexture;
			float4 _CameraDepthTexture_TexelSize;

			SamplerState depth_point_clamp_sampler;

			v2f vert( appdata_img v )
			{
				v2f o = (v2f)0;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;

				return o;
			}

			float4 frag(v2f input) : SV_Target
			{
				float2 inverseRenderDimensions = 1.0.xx / max(1.0.xx, _ScreenParams);

				int2 startCoords = (input.uv - 0.5f * inverseRenderDimensions) * _CameraDepthTexture_TexelSize.zw;
				int2 endCoords = (input.uv + 0.5f * inverseRenderDimensions) * _CameraDepthTexture_TexelSize.zw;

				startCoords = clamp(startCoords, 0, _CameraDepthTexture_TexelSize.zw);
				endCoords = clamp(endCoords, 0, _CameraDepthTexture_TexelSize.zw);

	#if defined(UNITY_REVERSED_Z)
				float result = 1.0f;
	#else
				float result = 0.0f;
	#endif

				for (int y = startCoords.y; y < endCoords.y; y++)
				{
					for (int x = startCoords.x; x < endCoords.x; x++)
					{
						float depth = _CameraDepthTexture.Load(int3(x, y, 0));

	#if defined(UNITY_REVERSED_Z)
						result = min(result, depth);
	#else
						result = max(result, depth);
	#endif
					}
				}

				return result;
			}

			ENDCG
		}

		Pass // Pass 1 downscale texture
		{
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			Texture2D _EVETextureToDownscale;
			float4 _EVETextureToDownscale_TexelSize;

			SamplerState depth_point_clamp_sampler;

			v2f vert( appdata_img v )
			{
				v2f o = (v2f)0;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;

				return o;
			}

			float4 frag(v2f input) : SV_Target
			{
				float2 inverseRenderDimensions = 1.0.xx / max(1.0.xx, _ScreenParams);

				int2 startCoords = (input.uv - 0.5f * inverseRenderDimensions) * _EVETextureToDownscale_TexelSize.zw;
				int2 endCoords = (input.uv + 0.5f * inverseRenderDimensions) * _EVETextureToDownscale_TexelSize.zw;

				startCoords = clamp(startCoords, 0, _EVETextureToDownscale_TexelSize.zw);
				endCoords = clamp(endCoords, 0, _EVETextureToDownscale_TexelSize.zw);

	#if defined(UNITY_REVERSED_Z)
				float result = 1.0f;
	#else
				float result = 0.0f;
	#endif

				for (int y = startCoords.y; y < endCoords.y; y++)
				{
					for (int x = startCoords.x; x < endCoords.x; x++)
					{
						float depth = _EVETextureToDownscale.Load(int3(x, y, 0));

	#if defined(UNITY_REVERSED_Z)
						result = min(result, depth);
	#else
						result = max(result, depth);
	#endif
					}
				}

				return result;
			}

			ENDCG
		}

	}
	Fallback off
}