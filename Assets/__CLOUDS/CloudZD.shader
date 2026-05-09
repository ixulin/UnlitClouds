Shader "_Clouds/Cloud ZD"
{
    Properties
    {
        _VertexColorMult("Vertex Color Mult", Range(0, 3)) = 1.16
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
        }

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
            CBUFFER_END

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

                // Vertex color as base
                half4 tint = saturate(pow(saturate(input.color), 0.454545) * _VertexColorMult);

                // Simple directional light
                Light mainLight = GetMainLight();
                half ndotL = saturate(dot(N, SafeNormalize(mainLight.direction)));
                half3 color = tint.rgb * mainLight.color * (ndotL * 0.8 + 0.2);

                // Simple ambient
                half3 ambient = half3(0.4, 0.45, 0.55) * tint.rgb * 0.35;
                color += ambient;

                color = MixFog(color, input.fogFactor);
                return half4(color, tint.a);
            }
            ENDHLSL
        }
    }

    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
