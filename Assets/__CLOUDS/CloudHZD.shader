Shader "_Clouds/HZD Volumetric Cloud"
{
    Properties
    {
        // ========================================
        // 3D Noise Textures
        // ========================================
        [NoScaleOffset] _PerlinWorleyTex("Perlin-Worley Noise", 3D) = "white" {}
        [NoScaleOffset] _WorleyTex("Worley Detail Noise", 3D) = "white" {}
        [NoScaleOffset] _DitherNoise("Dither Noise", 2D) = "white" {}

        // ========================================
        // Noise Layers (vertex displacement)
        // ========================================
        _NoiseScaleA("Noise Scale A", Vector) = (1, 1, 1, 0)
        _NoiseSizeA("Noise Size A", Float) = 0.8
        _SpeedA("Speed A", Float) = 0.5
        _DirectionA("Direction A", Vector) = (1.5, 0, 0, 0)
        _NoiseStrengthA("Noise Strength A", Range(0, 1)) = 0.472

        _NoiseScaleB("Noise Scale B", Vector) = (1, 1, 1, 0)
        _NoiseSizeB("Noise Size B", Float) = 1.49
        _SpeedB("Speed B", Float) = 1.0
        _DirectionB("Direction B", Vector) = (1.48, -0.86, -0.36, 0)
        _NoiseStrengthB("Noise Strength B", Range(0, 1)) = 0.182

        _NoiseScaleC("Noise Scale C", Vector) = (1, 1, 2.02, 0)
        _NoiseSizeC("Noise Size C", Float) = 5.0
        _SpeedC("Speed C", Float) = 10.36
        _DirectionC("Direction C", Vector) = (1, 0, 0, 0)
        _NoiseStrengthC("Noise Strength C", Range(0, 1)) = 0.071

        _VertexNoiseFreq("Vertex Noise Frequency", Float) = 0.02

        // ========================================
        // Cloud Shape / Density
        // ========================================
        _NoiseFrequency("Noise Frequency", Float) = 0.02
        _DetailFrequency("Detail Frequency", Float) = 0.08
        _CloudBaseY("Cloud Base Y", Float) = 0
        _CloudTopY("Cloud Top Y", Float) = 5
        _Coverage("Coverage", Range(0, 1)) = 0.6
        _CloudType("Cloud Type", Range(0, 1)) = 0.4
        _DensityMultiplier("Density Multiplier", Range(0, 5)) = 1.0
        _ErosionStrength("Erosion Strength", Range(0, 1)) = 0.3
        _VertexColorMult("Vertex Color Mult", Range(0, 3)) = 1.16

        // ========================================
        // Raymarching
        // ========================================
        _InteriorSteps("Interior Steps", Range(2, 128)) = 48
        _RaymarchMaxDist("Raymarch Max Distance", Float) = 20
        _Extinction("Extinction", Range(0.1, 5)) = 0.5

        // ========================================
        // Lighting
        // ========================================
        _ShadowSteps("Shadow Steps", Range(1, 32)) = 8
        _ShadowMaxDist("Shadow Max Distance", Float) = 15
        _Absorption("Light Absorption", Range(0.1, 10)) = 3.0
        _PhaseG1("Phase G1 (Forward)", Range(-0.99, 0.99)) = 0.8
        _PhaseG2("Phase G2 (Backward)", Range(-0.99, 0.99)) = -0.5
        _PhaseBlend("Phase Blend", Range(0, 1)) = 0.2
        _PowderEffect("Powder Effect", Range(0, 2)) = 1.0
        _MultiScatter("Multi-Scatter Strength", Range(0, 1)) = 0.3
        _LightMultiplier("Light Multiplier", Range(0, 5)) = 1.5

        // ========================================
        // Ambient / Rim
        // ========================================
        _AmbientSkyColor("Ambient Sky", Color) = (0.6, 0.7, 0.9, 1)
        _AmbientGroundColor("Ambient Ground", Color) = (0.15, 0.12, 0.1, 1)
        _AmbientStrength("Ambient Strength", Range(0, 2)) = 0.35
        _RimColor("Rim Color", Color) = (0.86, 0.86, 0.86, 1)
        _RimBase("Rim Base", Range(0, 1)) = 0.41
        _RimScale("Rim Scale", Range(0, 2)) = 1.0
        _RimPower("Rim Power", Range(0.5, 8)) = 3.65

        // ========================================
        // Debug
        // ========================================
        [KeywordEnum(Normal, Density, Transmittance)] _DebugView("Debug View", Float) = 0
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

        HLSLINCLUDE
        #pragma prefer_hlslcc gles
        #pragma exclude_renderers d3d11_9x
        #pragma target 4.0

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

        // ========================================
        // Material Constants
        // ========================================
        CBUFFER_START(UnityPerMaterial)
            // Noise layers
            float4 _NoiseScaleA; float _NoiseSizeA; float _SpeedA; float4 _DirectionA; float _NoiseStrengthA;
            float4 _NoiseScaleB; float _NoiseSizeB; float _SpeedB; float4 _DirectionB; float _NoiseStrengthB;
            float4 _NoiseScaleC; float _NoiseSizeC; float _SpeedC; float4 _DirectionC; float _NoiseStrengthC;
            float _VertexNoiseFreq;

            // Density
            float _NoiseFrequency; float _DetailFrequency;
            float _CloudBaseY; float _CloudTopY;
            float _Coverage; float _CloudType;
            float _DensityMultiplier; float _ErosionStrength;
            float _VertexColorMult;

            // Raymarching
            float _InteriorSteps; float _RaymarchMaxDist; float _Extinction;

            // Lighting
            float _ShadowSteps; float _ShadowMaxDist;
            float _Absorption;
            float _PhaseG1; float _PhaseG2; float _PhaseBlend;
            float _PowderEffect; float _MultiScatter;
            float _LightMultiplier;

            // Ambient / Rim
            float4 _AmbientSkyColor; float4 _AmbientGroundColor;
            float _AmbientStrength;
            float4 _RimColor; float _RimBase; float _RimScale; float _RimPower;

            // Debug
            float _DebugView;
        CBUFFER_END

        TEXTURE3D(_PerlinWorleyTex);   SAMPLER(sampler_PerlinWorleyTex);
        TEXTURE3D(_WorleyTex);         SAMPLER(sampler_WorleyTex);
        TEXTURE2D(_DitherNoise);       SAMPLER(sampler_DitherNoise);

        // ========================================
        // Structs
        // ========================================
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
            half4  vertexColor : COLOR;
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };

        struct ShadowVaryings
        {
            float4 positionCS  : SV_POSITION;
            float3 positionWS  : TEXCOORD0;
            half3  normalWS    : TEXCOORD1;
            half4  vertexColor : COLOR;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        // ========================================
        // Utility
        // ========================================
        float Remap(float value, float inMin, float inMax, float outMin, float outMax)
        {
            return outMin + (value - inMin) * (outMax - outMin) / max(inMax - inMin, 0.0001);
        }

        // ========================================
        // Vertex Displacement
        // ========================================
        float3 ApplyVertexOffset(float3 positionOS)
        {
            float3 positionWS = TransformObjectToWorld(positionOS);
            float tA = _Time.y * _SpeedA;
            float tB = _Time.y * _SpeedB;
            float tC = _Time.y * _SpeedC;

            float3 coordA = (positionWS * _NoiseScaleA.xyz * _NoiseSizeA + _DirectionA.xyz * tA) * _VertexNoiseFreq;
            float nA = SAMPLE_TEXTURE3D_LOD(_PerlinWorleyTex, sampler_PerlinWorleyTex, coordA, 0).r;

            float3 coordB = (positionWS * _NoiseScaleB.xyz * _NoiseSizeB + _DirectionB.xyz * tB) * _VertexNoiseFreq;
            float nB = SAMPLE_TEXTURE3D_LOD(_PerlinWorleyTex, sampler_PerlinWorleyTex, coordB, 0).g;

            float3 coordC = (positionWS * _NoiseScaleC.xyz * _NoiseSizeC + _DirectionC.xyz * tC) * _VertexNoiseFreq;
            float nC = SAMPLE_TEXTURE3D_LOD(_WorleyTex, sampler_WorleyTex, coordC, 0).r;

            float offset = nA * _NoiseStrengthA + nB * _NoiseStrengthB + nC * _NoiseStrengthC;
            return positionOS + float3(0.0, offset, 0.0);
        }

        // ========================================
        // Density Sampling
        // ========================================
        float SampleDensity(float3 positionWS)
        {
            float h = (positionWS.y - _CloudBaseY) / max(_CloudTopY - _CloudBaseY, 0.01);
            if (h < 0.0 || h > 1.0) return 0.0;

            // Height gradient
            float cumulusTop = 0.3 + _CloudType * 0.65;
            float heightGrad = smoothstep(0.0, 0.1, h) * (1.0 - smoothstep(cumulusTop, 1.0, h));

            // Perlin-Worley: R = Perlin (large scale shape), GBA = Worley FBM
            float4 pw = SAMPLE_TEXTURE3D_LOD(_PerlinWorleyTex, sampler_PerlinWorleyTex, positionWS * _NoiseFrequency, 0);
            float perlin = pw.r * 2.0 - 1.0;
            float worleyFBM = pw.g * 0.625 + pw.b * 0.25 + pw.a * 0.125;

            // Worley dilates Perlin's remap lower bound
            float cloudShape = Remap(perlin, -(1.0 - worleyFBM), 1.0, 0.0, 1.0);

            // Coverage remap
            float coverageMask = 1.0 - _Coverage;
            cloudShape = Remap(cloudShape, coverageMask, 1.0, 0.0, 1.0) * _Coverage;

            // Apply height gradient
            float density = cloudShape * heightGrad;

            // High-frequency Worley erosion
            float3 w = SAMPLE_TEXTURE3D_LOD(_WorleyTex, sampler_WorleyTex, positionWS * _DetailFrequency, 0);
            float erosionFBM = w.r * 0.625 + w.g * 0.25 + w.b * 0.125;
            density = Remap(density, erosionFBM * _ErosionStrength * 0.5, 1.0, 0.0, 1.0);

            return saturate(density) * _DensityMultiplier;
        }

        // ========================================
        // Henyey-Greenstein Phase Function
        // ========================================
        float HGPhase(float g, float cosTheta)
        {
            float g2 = g * g;
            float denom = 1.0 + g2 - 2.0 * g * cosTheta;
            return (1.0 - g2) / max(4.0 * 3.14159265 * pow(abs(denom), 1.5), 0.0001);
        }

        float DualLobeHG(float cosTheta, float g1, float g2, float blend)
        {
            return lerp(HGPhase(g1, cosTheta), HGPhase(g2, cosTheta), blend);
        }

        // ========================================
        // Sun Occlusion (light raymarch)
        // ========================================
        float SampleSunOcclusion(float3 pos, float3 sunDir)
        {
            float occlusion = 1.0;
            float stepSize = _ShadowMaxDist / _ShadowSteps;
            int steps = (int)_ShadowSteps;
            for (int i = 0; i < 32; i++)
            {
                if (i >= steps) break;
                float d = ((float)i + 0.5) * stepSize;
                float density = SampleDensity(pos + sunDir * d);
                occlusion *= exp(-density * stepSize * _Extinction * 2.0);
                if (occlusion < 0.01) break;
            }
            return occlusion;
        }

        // ========================================
        // Cloud Lighting
        // ========================================
        half3 SampleCloudLighting(float3 pos, half3 N, half3 V, float density, float stepSize)
        {
            Light mainLight = GetMainLight();
            half3 L = SafeNormalize(mainLight.direction);
            half3 lightColor = mainLight.color * mainLight.distanceAttenuation * mainLight.shadowAttenuation;

            float cosTheta = dot(L, V);

            // Phase function (dual-lobe HG)
            float phase = DualLobeHG(cosTheta, _PhaseG1, _PhaseG2, _PhaseBlend);
            float isotropic = 1.0 / (4.0 * 3.14159265);
            phase = max(phase, isotropic);

            // Sun occlusion
            float sunOcclusion = SampleSunOcclusion(pos, L);

            // Optical depth for this sample
            float opticalDepth = density * stepSize * _Absorption;

            // Beer's Law
            float beersLaw = exp(-opticalDepth);

            // Powder Effect: brightens low-density (edge) regions
            float powder = 1.0 - exp(-opticalDepth * 2.0);
            float beersPowder = max(beersLaw, powder * _PowderEffect);

            // Multi-scatter approximation
            float multiScatter = exp(-opticalDepth * 0.25) * _MultiScatter;

            // Direct lighting
            half3 directLight = lightColor * sunOcclusion;
            half3 scatter = directLight * phase * beersPowder * (1.0 - exp(-opticalDepth));
            half3 multiScatterContrib = directLight * multiScatter * 0.5;

            // Ambient (hemisphere)
            float ambientBlend = saturate(N.y * 0.5 + 0.5);
            half3 ambientColor = lerp(_AmbientGroundColor.rgb, _AmbientSkyColor.rgb, ambientBlend);
            half3 ambientContrib = ambientColor * _AmbientStrength * max(1.0 - density * 0.5, 0.15);

            // Rim (Fresnel)
            float ndotV = abs(dot(N, V));
            float fresnel = _RimBase + _RimScale * pow(1.0 - ndotV, _RimPower);
            half3 rimContrib = fresnel * _RimColor.rgb * 0.15;

            return (scatter + multiScatterContrib) * _LightMultiplier + ambientContrib + rimContrib;
        }

        // ========================================
        // Shadow Caster Helper
        // ========================================
        float4 GetShadowPositionHClip(float3 positionOS, float3 normalOS, float3 lightDir)
        {
            float3 positionWS = TransformObjectToWorld(positionOS);
            float3 normalWS = TransformObjectToWorldNormal(normalOS);
            float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDir));

            #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #else
                positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #endif
            return positionCS;
        }

        ENDHLSL

        // ========================================
        // PASS 1: Forward Lit
        // ========================================
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back

            HLSLPROGRAM
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma vertex CloudVert
            #pragma fragment CloudFrag

            Varyings CloudVert(Attributes input)
            {
                Varyings o = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float3 positionOS = ApplyVertexOffset(input.positionOS.xyz);
                VertexPositionInputs vertPos = GetVertexPositionInputs(positionOS);
                VertexNormalInputs vertNorm = GetVertexNormalInputs(input.normalOS);

                o.positionCS  = vertPos.positionCS;
                o.positionWS  = vertPos.positionWS;
                o.normalWS    = NormalizeNormalPerVertex(vertNorm.normalWS);
                o.viewDirWS   = GetCameraPositionWS() - vertPos.positionWS;
                o.fogFactor   = ComputeFogFactor(vertPos.positionCS.z);
                o.vertexColor = input.color;
                return o;
            }

            half4 CloudFrag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half3 N = NormalizeNormalPerPixel(input.normalWS);
                half3 V = SafeNormalize(input.viewDirWS);

                // Surface albedo from vertex color
                half4 tint = saturate(pow(saturate(input.vertexColor), 0.454545) * _VertexColorMult);
                half3 surfaceAlbedo = tint.rgb;
                half  vertexDensity = saturate(input.vertexColor.a);

                // Ray setup: camera -> surface point
                float3 rayOrigin = GetCameraPositionWS();
                float3 rayDir    = SafeNormalize(input.positionWS - rayOrigin);
                float3 marchStart = input.positionWS + rayDir * 0.05;

                float stepSize = _RaymarchMaxDist / _InteriorSteps;
                int maxSteps = (int)_InteriorSteps;

                // Blue noise dither
                float2 screenUV = input.positionCS.xy * 0.5 + 0.5;
                float dither = SAMPLE_TEXTURE2D(_DitherNoise, sampler_DitherNoise, screenUV * 4.0).r;
                float jitter = dither * stepSize;

                float transmittance = 1.0;
                half3  scatteredLight = half3(0, 0, 0);

                // DEBUG VIEW: Density only
                if (_DebugView < 0.5)
                {
                    // Normal rendering
                    for (int i = 0; i < 128; i++)
                    {
                        if (i >= maxSteps) break;

                        float3 pos = marchStart + rayDir * ((float)i * stepSize + jitter);
                        float d = SampleDensity(pos) * vertexDensity;

                        if (d > 0.001)
                        {
                            float opticalDepth = d * stepSize * _Extinction;
                            half3 lighting = SampleCloudLighting(pos, N, V, d, stepSize);
                            scatteredLight += lighting * transmittance * (1.0 - exp(-opticalDepth));
                            transmittance *= exp(-opticalDepth);
                            if (transmittance < 0.01) break;
                        }
                    }

                    half3 color = surfaceAlbedo * transmittance + scatteredLight;
                    color = MixFog(color, input.fogFactor);
                    float alpha = saturate(1.0 - transmittance) * vertexDensity;
                    alpha = max(alpha, 0.05);
                    return half4(color, alpha);
                }
                else if (_DebugView < 1.5)
                {
                    // Density visualization
                    float totalDensity = 0;
                    for (int i = 0; i < 128; i++)
                    {
                        if (i >= maxSteps) break;
                        float3 pos = marchStart + rayDir * ((float)i * stepSize + jitter);
                        totalDensity += SampleDensity(pos) * stepSize;
                    }
                    half3 densityVis = saturate(totalDensity * 0.3).xxx;
                    densityVis = MixFog(densityVis, input.fogFactor);
                    return half4(densityVis, 1.0);
                }
                else
                {
                    // Transmittance visualization
                    float trans = 1.0;
                    for (int i = 0; i < 128; i++)
                    {
                        if (i >= maxSteps) break;
                        float3 pos = marchStart + rayDir * ((float)i * stepSize + jitter);
                        float d = SampleDensity(pos) * vertexDensity;
                        trans *= exp(-d * stepSize * _Extinction);
                        if (trans < 0.01) break;
                    }
                    half3 transVis = trans.xxx;
                    transVis = MixFog(transVis, input.fogFactor);
                    return half4(transVis, 1.0 - trans);
                }
            }
            ENDHLSL
        }

        // ========================================
        // PASS 2: Shadow Caster
        // ========================================
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma multi_compile_instancing
            #pragma vertex ShadowVert
            #pragma fragment ShadowFrag

            ShadowVaryings ShadowVert(Attributes input)
            {
                ShadowVaryings o = (ShadowVaryings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, o);

                float3 positionOS = ApplyVertexOffset(input.positionOS.xyz);
                o.positionCS = GetShadowPositionHClip(positionOS, input.normalOS, _MainLightPosition.xyz);
                o.positionWS = TransformObjectToWorld(positionOS);
                o.normalWS   = NormalizeNormalPerVertex(TransformObjectToWorldNormal(input.normalOS));
                o.vertexColor = input.color;
                return o;
            }

            half4 ShadowFrag(ShadowVaryings input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);

                float density = SampleDensity(input.positionWS);
                float alpha = saturate(density * 0.5 + 0.3) * saturate(input.vertexColor.a);
                clip(alpha - 0.15);
                return 0;
            }
            ENDHLSL
        }
    }

    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
