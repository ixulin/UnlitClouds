Shader "_Clouds/Cloud ZD"
{
    Properties
    {
        _VertexColorMult("Vertex Color Mult", Range(0, 3)) = 1.16

        // Ray Marching
        _Density("Base Density", Range(0.1, 5)) = 1.0
        _InteriorSteps("Interior Steps", Range(2, 128)) = 32
        _RaymarchMaxDist("Raymarch Max Distance", Float) = 10
        _Extinction("Extinction", Range(0.1, 5)) = 1.0
        _Absorption("Light Absorption", Range(0.1, 10)) = 2.0
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
                float _Density;
                float _InteriorSteps;
                float _RaymarchMaxDist;
                float _Extinction;
                float _Absorption;
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

            // Simple density: constant inside mesh
            float SampleDensity(float3 positionWS)
            {
                return _Density;
            }

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

                // Surface albedo from vertex color
                half4 tint = saturate(pow(saturate(input.color), 0.454545) * _VertexColorMult);
                half3 surfaceAlbedo = tint.rgb;
                half vertexDensity = saturate(input.color.a);

                // Simple directional light for scattering
                Light mainLight = GetMainLight();
                half3 L = SafeNormalize(mainLight.direction);
                half3 lightColor = mainLight.color * mainLight.distanceAttenuation * mainLight.shadowAttenuation;

                // Ray setup: camera -> surface, then march inward
                float3 rayOrigin = GetCameraPositionWS();
                float3 rayDir = SafeNormalize(input.positionWS - rayOrigin);
                float3 marchStart = input.positionWS + rayDir * 0.05;

                float stepSize = _RaymarchMaxDist / _InteriorSteps;
                int maxSteps = (int)_InteriorSteps;

                float transmittance = 1.0;
                half3 scatteredLight = half3(0, 0, 0);

                // Ray march loop
                for (int i = 0; i < 128; i++)
                {
                    if (i >= maxSteps) break;

                    float3 pos = marchStart + rayDir * ((float)i + 0.5) * stepSize;
                    float d = SampleDensity(pos) * vertexDensity;

                    if (d > 0.001)
                    {
                        // Beer-Lambert: optical depth drives attenuation
                        float opticalDepth = d * stepSize * _Extinction;
                        float beersLaw = exp(-opticalDepth);

                        // Simple lighting per sample: N·L wrap diffuse
                        half ndotL = saturate(dot(N, L));
                        half3 sampleLight = lightColor * (ndotL * 0.8 + 0.2);

                        // Accumulate scattered light weighted by transmittance
                        scatteredLight += sampleLight * surfaceAlbedo * transmittance * (1.0 - beersLaw);

                        // Beer-Lambert transmittance decay
                        transmittance *= beersLaw;

                        if (transmittance < 0.01) break;
                    }
                }

                // Final compositing
                half3 color = surfaceAlbedo * transmittance + scatteredLight;

                // Simple ambient
                half3 ambient = half3(0.4, 0.45, 0.55) * surfaceAlbedo * 0.35;
                color += ambient;

                color = MixFog(color, input.fogFactor);
                float alpha = saturate(1.0 - transmittance) * vertexDensity;
                alpha = max(alpha, 0.05);

                return half4(color, alpha);
            }
            ENDHLSL
        }
    }

    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
