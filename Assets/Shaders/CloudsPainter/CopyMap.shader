Shader "EVE/CopyMap"
{
	SubShader
	{
		Pass {
			Tags { "Queue" = "Transparent-1" "IgnoreProjector" = "True" "RenderType" = "Transparent"}

			Cull Off
			ZTest Off
			ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "UnityCG.cginc"
			#include "../alphaMap.cginc"

			#pragma multi_compile ALPHAMAP_N_1 ALPHAMAP_1
			#pragma multi_compile CUBEMAP_MODE_OFF CUBEMAP_MODE_ON

			#if defined(CUBEMAP_MODE_OFF)
				sampler2D textureToCopy;
			#else
				TextureCube textureToCopy;
				SamplerState texture_point_clamp_sampler;
			#endif
			
			int cubemapFace;

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert( appdata_img v )
			{
				v2f o = (v2f)0;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;

				return o;
			}

			float3 GetDirectionFromCubemapFaceUV(float2 uv, int face)
			{
				// How cubemaps work: The largest abs(component) determines the faces (x, y, z)
				// Then check if the sign of the component is positive or negative to determine if it's face or -face
				// The uv is then just the remaining two directions divided by the largest component (including sign)
				// Then scale and bias the uv from -1 1 to 0 1
				// See readable algorithm here https://www.gamedev.net/forums/topic/692761-manual-cubemap-lookupfiltering-in-hlsl/5359801/

				// To reverse it start by reverting the scale and bias
				uv = uv * 2.0 - 1.0.xx;

				// Then rebuild directions from their components before normalizing
				float3 direction;
				switch (face)
				{
				case 0: direction = float3(1, -uv.y, -uv.x); break; // +X face
				case 1: direction = float3(-1, -uv.y, uv.x); break; // -X face

				case 2: direction = float3(uv.x, 1, uv.y); break; // +Y face
				case 3: direction = float3(uv.x, -1, -uv.y); break; // -Y face

				case 4: direction = float3(uv.x, -uv.y, 1); break; // +Z face
				case 5: direction = float3(-uv.x, -uv.y, -1); break; // -Z face

				default: direction = float3(0, 0, 0); break; // Invalid face index
				}

				return normalize(direction);
			}

			float4 frag(v2f i) : SV_Target
			{
				float2 uv = i.uv;

				#if defined(CUBEMAP_MODE_OFF)
					float4 col = tex2Dlod(textureToCopy, float4(uv,0.0,0.0));
				#else
					float3 dir = GetDirectionFromCubemapFaceUV(uv, cubemapFace);
					float4 col = textureToCopy.SampleLevel(texture_point_clamp_sampler, dir, 0.0);
				#endif

				col = ALPHA_VECTOR_1(col);

				return col;
			}
			ENDCG
		}
	}
	Fallback off
}