Shader "EVE/PaintCloudMap"
{
	SubShader
	{
		Pass // 0 Regular painting pass
		{ 
			Tags { "Queue"="Transparent-1" "IgnoreProjector"="True" "RenderType"="Transparent"}

			Cull Off
			ZTest Off
			ZWrite Off

			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			#pragma multi_compile PAINT_CUBEMAP_OFF PAINT_CUBEMAP_ON

			#include "UnityCG.cginc"
			#include "../RaymarchedClouds/RaymarchedCloudUtils.cginc"
			#include "../RaymarchedClouds/RaymarchedCloudShading.cginc"
			#include "PaintUtils.cginc"


			float brushSize;
			float hardness;
			float opacity;
			float3 paintValue;

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

			float4 frag(v2f i) : SV_Target
			{
				float3 planetFragmentPos = 0.0.xxx;
				float3 planetBrushPosition = GetBrushAndFragmentPlanetPositions(i.uv, planetFragmentPos);

				// calc distance to position of brush
				float dist = length(planetBrushPosition - planetFragmentPos);

				// calculate brush opacity
				float brushOpacity = lerp(1.0, 0.0, clamp(dist/brushSize, 0.0, 1.0));

				// apply hardness
				if (abs(hardness) > 0.00001)
				{
					brushOpacity = saturate(brushOpacity / hardness);
				}
				else
				{
					if (brushOpacity > 0.00001) brushOpacity = 1.0;
				}

				return float4(paintValue, brushOpacity * opacity);
			}
			ENDCG
		}

		Pass // 1 Flow vortex painting pass
		{
			Tags { "Queue"="Transparent-1" "IgnoreProjector"="True" "RenderType"="Transparent"}

			Cull Off
			ZTest Off
			ZWrite Off

			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			#pragma multi_compile PAINT_CUBEMAP_OFF PAINT_CUBEMAP_ON

			#include "UnityCG.cginc"
			#include "../RaymarchedClouds/RaymarchedCloudUtils.cginc"
			#include "../RaymarchedClouds/RaymarchedCloudShading.cginc"
			#include "PaintUtils.cginc"

			float brushSize;
			float hardness;
			float opacity;

			float flowValue, upwardsFlowValue, clockWiseRotation;

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

			float4 frag(v2f i) : SV_Target
			{
				float3 planetFragmentPos = 0.0.xxx;
				float3 planetBrushPosition = GetBrushAndFragmentPlanetPositions(i.uv, planetFragmentPos);

				// calc distance to position of brush
				float dist = length(planetBrushPosition - planetFragmentPos);

				// calculate brush opacity
				float brushOpacity = lerp(1.0, 0.0, clamp(dist/brushSize, 0.0, 1.0));

				// apply hardness
				if (abs(hardness) > 0.00001)
				{
					brushOpacity = saturate(brushOpacity / hardness);
				}
				else
				{
					if (brushOpacity > 0.00001) brushOpacity = 1.0;
				}

				// We could do the gradientVector in planetSpace, then project that to TBN

				float3 gradientVector = normalize(planetBrushPosition - planetFragmentPos);

				// Calc TBN vectors at current point
				float3 normal = normalize(planetFragmentPos);

				float3 tangent;
				float3 biTangent;
				if (abs(normal.x) > 0.001) {
					tangent = normalize(cross(float3(0, 1, 0), normal));
				} else {
					tangent = normalize(cross(float3(1, 0, 0), normal));
				}
				biTangent = cross(normal, tangent);
				tangent*= -1;

				// flow vector in TB
				float2 flowVector = normalize(float2(dot(gradientVector, tangent), dot(gradientVector, biTangent)));

				flowVector = clockWiseRotation > 0.5 ? float2(flowVector.y, -flowVector.x) : float2(-flowVector.y, flowVector.x) ;


				return float4(flowValue * flowVector.xy  * 0.5 + 0.5.xx, upwardsFlowValue  * 0.5 + 0.5, brushOpacity * opacity);
			}
			ENDCG
		}

		Pass // 2 Flow bands painting pass
		{
			Tags { "Queue"="Transparent-1" "IgnoreProjector"="True" "RenderType"="Transparent"}

			Cull Off
			ZTest Off
			ZWrite Off

			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			#pragma multi_compile PAINT_CUBEMAP_OFF PAINT_CUBEMAP_ON

			#include "UnityCG.cginc"
			#include "../RaymarchedClouds/RaymarchedCloudUtils.cginc"
			#include "../RaymarchedClouds/RaymarchedCloudShading.cginc"
			#include "PaintUtils.cginc"

			float brushSize;
			float hardness;
			float opacity;

			float flowValue, clockWiseRotation;

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

			float4 frag(v2f i) : SV_Target
			{
				float3 planetFragmentPos = 0.0.xxx;
				float3 planetBrushPosition = GetBrushAndFragmentPlanetPositions(i.uv, planetFragmentPos);

				// get position on the vertical axis
				float axisBrushPosition = dot(planetBrushPosition, float3(0, 1, 0));
				float axisPointPosition = dot(planetFragmentPos, float3(0, 1, 0));

				// calc distance to position of brush
				float dist = length(axisBrushPosition - axisPointPosition);

				// calculate brush opacity
				float brushOpacity = lerp(1.0, 0.0, clamp(dist/brushSize, 0.0, 1.0));

				// apply hardness
				if (abs(hardness) > 0.00001)
				{
					brushOpacity = saturate(brushOpacity / hardness);
				}
				else
				{
					if (brushOpacity > 0.00001) brushOpacity = 1.0;
				}

				// flow for a horizontal band is very simple
				float3 flow  = float3(clockWiseRotation > 0.5 ? -flowValue : flowValue, 0.0, 0.0);
				flow = flow * 0.5 + 0.5.xxx;

				return float4(flow, brushOpacity * opacity);
			}
			ENDCG
		}

		Pass // 3 Tile painting pass
		{ 
			Tags { "Queue"="Transparent-1" "IgnoreProjector"="True" "RenderType"="Transparent"}

			Cull Off
			ZTest Off
			ZWrite Off

			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			#pragma multi_compile PAINT_CUBEMAP_OFF PAINT_CUBEMAP_ON

			#include "UnityLightingCommon.cginc"
			#include "UnityCG.cginc"
			#include "../RaymarchedClouds/RaymarchedCloudUtils.cginc"
			#include "../RaymarchedClouds/RaymarchedCloudShading.cginc"
			#include "PaintUtils.cginc"
			#include "../EVEUtils.cginc"
			#include "../cubeMap.cginc"

			float brushSize;
			float hardness;
			float opacity;

			float3 tileFrameTangent;
			float3 tileFrameBitangent;
			float3 tileFrameNormal;
			float3 tileFrameOrigin;
			float3 tileFrameUVOffset;

			float tileRotation;
			float2 tileOffset;
			float2 remapTile;

			sampler2D inputTile;
			sampler2D inputTypeTile;
			float tileSize;
			int readType;
			int writingType;
			int useGuideMask;

			#pragma multi_compile MAP_TYPE_1 MAP_TYPE_CUBE6_1 MAP_TYPE_CUBE_1
			CUBEMAP_DEF_1(inputMask);
			int useMask;

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

			float2 GetTileUV(float3 sphereRelativePos, float3 frameOrigin, float3 frameTangent, float3 frameBitangent,
				float3 frameNormal, float radius, float inverseTileSize, float2 tileUVOffset)
			{
				float2 projectedPos = float2(dot(sphereRelativePos - frameOrigin, frameTangent), dot(sphereRelativePos - frameOrigin, frameBitangent));

				// Either the frameNormal or the radius are broken
				
				float sinTheta = length(cross(frameNormal, normalize(sphereRelativePos)));
				float arcAngle = asin(clamp(sinTheta, 0.0, 1.0));

				float arcLength = radius * arcAngle;
				projectedPos = normalize(projectedPos) * arcLength;

				projectedPos *= inverseTileSize;
				projectedPos += tileUVOffset;
    
				return projectedPos;
			}

			void CalculateTBVectors(float3 normal, out float3 tangent, out float3 bitangent)
			{
				float3 upVector = abs(normal.z) < 0.999 ? float3(0.0, 0.0, 1.0) : float3(1.0, 0.0, 0.0);
				tangent = normalize(cross(upVector, normal));
				bitangent = cross(normal, tangent);
			}

			float4 frag(v2f i) : SV_Target
			{
				float3 planetFragmentPos = 0.0.xxx;
				float3 planetBrushPosition = GetBrushAndFragmentPlanetPositions(i.uv, planetFragmentPos);

				// calc distance to position of brush
				float dist = length(planetBrushPosition - planetFragmentPos);

				// calculate brush opacity
				float brushOpacity = lerp(1.0, 0.0, clamp(dist/brushSize, 0.0, 1.0));

				// apply hardness
				if (abs(hardness) > 0.00001)
				{
					brushOpacity = saturate(brushOpacity / hardness);
				}
				else
				{
					if (brushOpacity > 0.00001) brushOpacity = 1.0;
				}

				// Sample the tile using the tile grid data I passed
				// Add ints for setting tile mask mode or just regular tile mode
				// We have the brush position, calculate its UV
				float2 projectedBrushPos = GetTileUV(planetFragmentPos, tileFrameOrigin, tileFrameTangent, tileFrameBitangent,
											tileFrameNormal, innerSphereRadius, 1.0 / tileSize, tileFrameUVOffset.xy);

				// Build 2×2 rotation matrix
				float2x2 rot = float2x2(
					cos(tileRotation), -sin(tileRotation),
					sin(tileRotation),  cos(tileRotation)
				);

				// move pivot to center
				float2 centered = projectedBrushPos - 0.5;

				// apply rotation
				float2 rotated = mul(rot, centered);

                projectedBrushPos = rotated + 0.5;

				projectedBrushPos += tileOffset;

				float tile;

				if (readType > 0)
					tile = tex2D(inputTypeTile, projectedBrushPos).r;
				else
					tile = tex2D(inputTile, projectedBrushPos).r;

				tile = RemapClamped(tile, 0.0, 1.0, remapTile.x, remapTile.y);

				if (useGuideMask > 0)
				{
					float mask = GET_CUBE_MAP_1(inputMask, normalize(planetFragmentPos));

					if (writingType < 1)
					{
						float result = clamp((tile * 0.6 + mask - 0.6) * 2.5, 0.0, 1.0);
						tile = result > tile ? tile : result;
					}
					else
					{
						opacity = mask < 1.0 / 255.0 ? 0.0 : opacity;
					}
				}

				return float4(tile.rrr, brushOpacity * opacity);
			}
			ENDCG
		}
	}
	Fallback off
}