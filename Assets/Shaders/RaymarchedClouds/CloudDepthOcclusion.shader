Shader "EVE/CloudDepthOcclusion" {
	SubShader{
		Tags { "Queue" = "Geometry-1000" "IgnoreProjector" = "True" "RenderType" = "Opaque"}

		Pass {

			Cull Off
			ZTest On
			ZWrite On

			Blend SrcAlpha OneMinusSrcAlpha //alpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "UnityCG.cginc"
			#include "RaymarchedCloudUtils.cginc"
			#include "LayerInformation.cginc"

			sampler2D newRaysBuffer;
			sampler2D colorBuffer;
			float rendererEnabled;
			float cloudFade;
			
			sampler2D _CameraDepthTexture;
			float useOrbitMode;
			float4x4 CameraToWorld;

			// TODO
			float useCombinedOpenGLDistanceBuffer;

			struct v2f
			{
				float4 screenPos : TEXCOORD0;
			};

			v2f vert(appdata_base v, out float4 outpos: SV_POSITION)
			{
				v2f o;

				//not sure if keep
				#if defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)
				outpos = float4(2.0 * v.vertex.x, 2.0 * v.vertex.y *_ProjectionParams.x, -1.0 , 1.0);
				#else
				outpos = float4(2.0 * v.vertex.x, 2.0 * v.vertex.y, 0.0 , 1.0);
				#endif
				o.screenPos = ComputeScreenPos(outpos);

				if(rendererEnabled<0.5 || cloudFade<1.0)
					outpos = float4(2.0, 2.0, 2.0, 1.0); //cull

				return o;
			}

			float frag(v2f i) : SV_Depth
			{
				float2 uv = i.screenPos.xy / i.screenPos.w;

				float3 rayDir = getViewDirFromUV(uv, CameraToWorld);

				#if SHADER_API_D3D11 || SHADER_API_D3D || SHADER_API_D3D12
				if (_ProjectionParams.x > 0) {uv.y = 1.0 - uv.y;}
				#endif

				// sample reconstructed image bilinearly, check transmittance
				float4 color = tex2Dlod(colorBuffer, float4(uv, 0.0, 0.0));

				// if transmittance is not zero discard
				if (color.a > 0.002) discard;

				// else read depth from the max depth buffer thing and output it
				float distance = unpackNewRaysMaxDepth(newRaysBuffer, uv) * 100.0; // multiply by 0.01 for storage because half tops out at ~65k, I think it's wrong though R16 seems to be 0-1 for some reason

				// calculate and output z
				float3 worldPos = _WorldSpaceCameraPos + rayDir * distance;

				float4 clipPos = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
				return clipPos.z / clipPos.w;
			}
			ENDCG
		}
	}

}