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

			Blend SrcAlpha OneMinusSrcAlpha //alpha, what about the alpha channel itself though?

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "UnityCG.cginc"
			#include "../RaymarchedClouds/RaymarchedCloudUtils.cginc"
			#include "../RaymarchedClouds/RaymarchedCloudShading.cginc"

			float3 brushPosition;
			float brushSize;
			float hardness;
			float opacity;
			float3 paintValue;

			float4x4 cloudRotationMatrix;

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

			float3 GetDirectionFromEquiRectangularUV(float2 uv)
			{
				float 	phi = (uv.x - 0.5) * TWO_PI;
				float 	theta = (uv.y) * PI;

				float 	sintheta = sin(theta);

				return float3(sin(phi)*sintheta, cos(theta), cos(phi)*sintheta);
			}

			float4 frag(v2f i) : SV_Target
			{
				float2 uv = i.uv;

				// now you have the uv, use it to calculate a worldspace raydirection
				float3 rayDir = GetDirectionFromEquiRectangularUV(uv); // note the y and x here may be inverted

				// compute the world position
				float3 worldPos =  rayDir * innerSphereRadius;

				float4 brushDirection = mul(cloudRotationMatrix, float4(brushPosition,1.0)); // transform the world pos to a planet space direction
				brushDirection.xyz /= brushDirection.w;
				brushDirection.xyz = normalize(brushDirection.xyz);

				float3 planetBrushPosition = brushDirection.xyz*innerSphereRadius;

				// calc distance to position of brush
				float dist = length(planetBrushPosition - worldPos);

				// calculate brush opacity
				float brushOpacity = lerp(1.0, 0.0, clamp(dist/brushSize, 0.0, 1.0));


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

			Blend SrcAlpha OneMinusSrcAlpha //alpha, what about the alpha channel itself though?

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "UnityCG.cginc"
			#include "../RaymarchedClouds/RaymarchedCloudUtils.cginc"
			#include "../RaymarchedClouds/RaymarchedCloudShading.cginc"

			float3 brushPosition;
			float brushSize;
			float hardness;
			float opacity;

			float flowValue, upwardsFlowValue, clockWiseRotation;

			float4x4 cloudRotationMatrix;

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

			float3 GetDirectionFromEquiRectangularUV(float2 uv)
			{
				float 	phi = (uv.x - 0.5) * TWO_PI;
				float 	theta = (uv.y) * PI;

				float 	sintheta = sin(theta);

				return float3(sin(phi)*sintheta, cos(theta), cos(phi)*sintheta);
			}

			float4 frag(v2f i) : SV_Target
			{
				float2 uv = i.uv;

				// now you have the uv, use it to calculate a worldspace raydirection
				float3 rayDir = GetDirectionFromEquiRectangularUV(uv); // note the y and x here may be inverted

				// compute the current world position
				float3 worldPos =  rayDir * innerSphereRadius;

				float4 brushDirection = mul(cloudRotationMatrix, float4(brushPosition,1.0)); // transform the world pos to a planet space direction
				brushDirection.xyz /= brushDirection.w;
				brushDirection.xyz = normalize(brushDirection.xyz);

				float3 planetBrushPosition = brushDirection.xyz*innerSphereRadius; // convert back to equirectangular

				// calc distance to position of brush
				float dist = length(planetBrushPosition - worldPos);

				// calculate brush opacity
				float brushOpacity = lerp(1.0, 0.0, clamp(dist/brushSize, 0.0, 1.0));

				// We could do the gradientVector in planetSpace, then project that to TBN

				float3 gradientVector = normalize(planetBrushPosition - worldPos);

				// Calc TBN vectors at current point
				float3 normal = normalize(rayDir);

				float3 tangent;
				float3 biTangent;
				if (abs(normal.x) > 0.001) {
					tangent = normalize(cross(float3(0, 1, 0), normal));
				} else {
					tangent = normalize(cross(float3(1, 0, 0), normal));
				}
				biTangent = cross(normal, tangent);

				// flow vector in TB
				float2 flowVector = normalize(float2(dot(gradientVector, tangent), dot(gradientVector, biTangent)));

				flowVector = clockWiseRotation < 0.5 ? float2(flowVector.y, -flowVector.x) : float2(-flowVector.y, flowVector.x) ;


				return float4(flowValue * flowVector.xy  * 0.5 + 0.5.xx, upwardsFlowValue  * 0.5 + 0.5, brushOpacity * opacity);
			}
			ENDCG
		}
	}
	Fallback off
}