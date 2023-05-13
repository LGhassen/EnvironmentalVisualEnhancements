Shader "EVE/PaintCloudMap"
{
	SubShader
	{
		Pass // regular painting pass
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
				float3 worldPos = 0.0.xxx;
				float3 planetBrushPosition = GetBrushAndWorldPositions(i.uv, worldPos);

				// calc distance to position of brush
				float dist = length(planetBrushPosition - worldPos);

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

		Pass // swirls painting pass
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
				float3 worldPos = 0.0.xxx;
				float3 planetBrushPosition = GetBrushAndWorldPositions(i.uv, worldPos);

				// calc distance to position of brush
				float dist = length(planetBrushPosition - worldPos);

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

				float3 gradientVector = normalize(planetBrushPosition - worldPos);

				// Calc TBN vectors at current point
				float3 normal = normalize(worldPos);

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

		Pass // bands painting pass
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
				float3 worldPos = 0.0.xxx;
				float3 planetBrushPosition = GetBrushAndWorldPositions(i.uv, worldPos);

				// get position on the vertical axis
				float axisBrushPosition = dot(planetBrushPosition, float3(0, 1, 0));
				float axisPointPosition = dot(worldPos, float3(0, 1, 0));

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
	}
	Fallback off
}