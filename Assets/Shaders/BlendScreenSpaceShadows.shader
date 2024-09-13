Shader "EVE/BlendScreenSpaceShadows"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Blend DstColor Zero // Multiplicative

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "DepthDownscaling/FindNearestDepth.cginc"

            sampler2D EVEScreenSpaceShadows;
            sampler2D _CameraDepthTexture;
            sampler2D EVEDownscaledDepth;

            float4 EVEDownscaledDepth_TexelSize;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float zdepth = tex2Dlod(_CameraDepthTexture, float4(i.uv, 0.0, 0.0));

                #if defined(UNITY_REVERSED_Z)
					if (zdepth == 0.0)
				#else
					if (zdepth == 1.0)
				#endif
					return 1.0;

                float2 nearestUV = FindNearestDepthUV(i.uv, zdepth, EVEDownscaledDepth, EVEDownscaledDepth_TexelSize);

                fixed4 col = tex2Dlod(EVEScreenSpaceShadows, float4(nearestUV, 0.0, 0.0));
                return col;
            }
            ENDCG
        }
    }
}
