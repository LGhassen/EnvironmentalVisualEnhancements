Shader "EVE/CompositeDeferredClouds" {
	Properties{
	}

	SubShader{
		Tags { "Queue"="Transparent+2" "IgnoreProjector"="True" "RenderType"="Transparent"}
		Pass {
			//Blend One One // Additive
			//Blend OneMinusDstColor One // Soft Additive
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			Offset 0, 0
			ColorMask RGB
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag

			#include"UnityCG.cginc"

			uniform sampler2D cloudTexture;

			struct appdata_t {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert(appdata_t v)
			{
				v2f o;
#if defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)
				o.pos = float4(v.vertex.x, v.vertex.y *_ProjectionParams.x, -1.0 , 1.0);
#else
				o.pos = float4(v.vertex.x, v.vertex.y *_ProjectionParams.x, 1.0 , 1.0);
#endif
				o.uv = ComputeScreenPos(o.pos);

				return o;
			}

			fixed4 frag(v2f IN) : COLOR
			{
				float4 color = tex2D(cloudTexture, IN.uv);

				return float4(color.rgb,1-color.a); //the alpha stored in the texture is 1*(1-alpha1)*(1-alpha2) etc, it's essentially the remaining alpha of the background
			}

			ENDCG
		}
	}
}