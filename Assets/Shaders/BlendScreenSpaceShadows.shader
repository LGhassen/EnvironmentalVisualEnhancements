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

        Pass    // Pass 0 copy to shadowmask
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

        Pass    // Pass 1 copy to screen in forward rendering
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
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

            float3 getPreciseWorldPosFromDepth(float2 uv, float zdepth)
            {
                float depth = Linear01Depth(zdepth);

            #if defined(UNITY_REVERSED_Z)
		            zdepth = 1 - zdepth;
            #endif

                float4 clipPos = float4(uv, zdepth, 1.0);
                clipPos.xyz = 2.0f * clipPos.xyz - 1.0f;

                float4 camPos = mul(unity_CameraInvProjection, clipPos);
                camPos.xyz /= camPos.w;

                float3 rayDirection = normalize(camPos.xyz);

                float3 cameraForwardDir = float3(0.0, 0.0, -1.0);
                float aa = dot(rayDirection, cameraForwardDir);

                camPos.xyz = rayDirection * depth / aa * _ProjectionParams.z;
                camPos.z = -camPos.z;

                float4 worldPos = mul(unity_CameraToWorld, float4(camPos.xyz, 1.0));
                return (worldPos.xyz / worldPos.w);
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

                float3 worldPos = getPreciseWorldPosFromDepth(i.uv, zdepth);

                //fade value
                float zDist = dot(_WorldSpaceCameraPos - worldPos, UNITY_MATRIX_V[2].xyz);
                float fadeDist = UnityComputeShadowFadeDistance(worldPos, zDist);
                half realtimeToBakedShadowFade = UnityComputeShadowFade(fadeDist);

                if (realtimeToBakedShadowFade == 0.0)
                    return 1.0;

                float2 nearestUV = FindNearestDepthUV(i.uv, zdepth, EVEDownscaledDepth, EVEDownscaledDepth_TexelSize);

                float col = tex2Dlod(EVEScreenSpaceShadows, float4(nearestUV, 0.0, 0.0));

                col = lerp(1.0, col, realtimeToBakedShadowFade);

                return col.xxxx;
            }
            ENDCG
        }
    }
}
