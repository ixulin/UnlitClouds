Shader "_Clouds/Cloud ZD"
{
    Properties
    {
        _VertexColorMult("Vertex Color Mult", Range(0, 3)) = 1.16
        _Density("Base Density", Range(0.1, 5)) = 1.0
        _Absorption("Light Absorption", Range(0.1, 10)) = 2.0
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        // ========================================
        // Pass 0: Depth Front Face (nearest)
        // ========================================
        Pass
        {
            Name "DepthFront"
            Tags { "LightMode" = "DepthFront" }
            Cull Back
            ZWrite Off
            ZTest Always
            ColorMask R
            BlendOp Min
            Blend One One

            HLSLPROGRAM
            #pragma vertex DepthVert
            #pragma fragment DepthFrag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct DepthVaryings
            {
                float4 positionCS : SV_POSITION;
                float linearDepth : TEXCOORD0;
            };

            DepthVaryings DepthVert(float4 positionOS : POSITION)
            {
                DepthVaryings o;
                float3 positionWS = TransformObjectToWorld(positionOS.xyz);
                o.positionCS = TransformWorldToHClip(positionWS);
                o.linearDepth = -TransformWorldToView(positionWS).z;
                return o;
            }

            float DepthFrag(DepthVaryings input) : SV_Target
            {
                return input.linearDepth;
            }
            ENDHLSL
        }

        // ========================================
        // Pass 1: Depth Back Face (farthest)
        // ========================================
        Pass
        {
            Name "DepthBack"
            Tags { "LightMode" = "DepthBack" }
            Cull Front
            ZWrite Off
            ZTest Always
            ColorMask R
            BlendOp Max
            Blend One One

            HLSLPROGRAM
            #pragma vertex DepthVert
            #pragma fragment DepthFrag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct DepthVaryings
            {
                float4 positionCS : SV_POSITION;
                float linearDepth : TEXCOORD0;
            };

            DepthVaryings DepthVert(float4 positionOS : POSITION)
            {
                DepthVaryings o;
                float3 positionWS = TransformObjectToWorld(positionOS.xyz);
                o.positionCS = TransformWorldToHClip(positionWS);
                o.linearDepth = -TransformWorldToView(positionWS).z;
                return o;
            }

            float DepthFrag(DepthVaryings input) : SV_Target
            {
                return input.linearDepth;
            }
            ENDHLSL
        }

        // ========================================
        // Pass 2: Forward Lit (depth-driven)
        // ========================================
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.0
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float _VertexColorMult;
                float _Density;
                float _Absorption;
            CBUFFER_END

            TEXTURE2D(_CameraFrontDepth); SAMPLER(sampler_CameraFrontDepth);
            TEXTURE2D(_CameraBackDepth);   SAMPLER(sampler_CameraBackDepth);
            TEXTURE2D(_SunFrontDepth);     SAMPLER(sampler_SunFrontDepth);
            TEXTURE2D(_SunBackDepth);      SAMPLER(sampler_SunBackDepth);
            float4x4 _LightViewProj;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 color      : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS  : SV_POSITION;
                float3 positionWS  : TEXCOORD0;
                half3  normalWS    : TEXCOORD1;
                half3  viewDirWS   : TEXCOORD2;
                half   fogFactor   : TEXCOORD3;
                half4  color       : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes input)
            {
                Varyings o = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                VertexPositionInputs vp = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs vn = GetVertexNormalInputs(input.normalOS);

                o.positionCS = vp.positionCS;
                o.positionWS = vp.positionWS;
                o.normalWS   = NormalizeNormalPerVertex(vn.normalWS);
                o.viewDirWS  = GetCameraPositionWS() - vp.positionWS;
                o.fogFactor  = ComputeFogFactor(vp.positionCS.z);
                o.color      = input.color;
                return o;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half3 N = NormalizeNormalPerPixel(input.normalWS);
                half3 V = SafeNormalize(input.viewDirWS);

                half4 tint = saturate(pow(saturate(input.color), 0.454545) * _VertexColorMult);
                half3 albedo = tint.rgb;

                // Camera thickness
                float2 screenUV = input.positionCS.xy / _ScreenParams.xy;
                float camFront = SAMPLE_TEXTURE2D(_CameraFrontDepth, sampler_CameraFrontDepth, screenUV).r;
                float camBack  = SAMPLE_TEXTURE2D(_CameraBackDepth, sampler_CameraBackDepth, screenUV).r;
                float viewThickness = max(camBack - camFront, 0.0);

                // Sun thickness
                float4 lightClip = mul(_LightViewProj, float4(input.positionWS, 1.0));
                float2 lightUV = lightClip.xy * 0.5 + 0.5;
                float sunFront = SAMPLE_TEXTURE2D(_SunFrontDepth, sampler_SunFrontDepth, lightUV).r;
                float sunBack  = SAMPLE_TEXTURE2D(_SunBackDepth, sampler_SunBackDepth, lightUV).r;
                float sunThickness = max(sunBack - sunFront, 0.0);

                // Beer-Lambert
                float viewTransmittance = exp(-viewThickness * _Density * _Absorption);
                float sunOcclusion = exp(-sunThickness * _Density * _Absorption);

                // Simple lighting
                Light mainLight = GetMainLight();
                half3 L = SafeNormalize(mainLight.direction);
                half ndotL = saturate(dot(N, L));
                half3 directLight = mainLight.color * (ndotL * 0.8 + 0.2) * sunOcclusion;
                half3 ambient = half3(0.4, 0.45, 0.55) * albedo * 0.35;

                half3 color = albedo * directLight * viewTransmittance + ambient;

                color = MixFog(color, input.fogFactor);
                float alpha = saturate(1.0 - viewTransmittance) * tint.a;
                alpha = max(alpha, 0.05);

                return half4(color, alpha);
            }
            ENDHLSL
        }
    }

    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
