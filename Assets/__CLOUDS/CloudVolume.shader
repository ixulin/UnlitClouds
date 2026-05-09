Shader "_Clouds/Clouds Volumetric Vertex"
{
    Properties
    {
        // 3D Noise Textures
        [NoScaleOffset] _PerlinWorleyTex("Perlin-Worley Noise", 3D) = "white" {}
        [NoScaleOffset] _WorleyTex("Worley Detail Noise", 3D) = "white" {}

        // Noise Layer A (large scale displacement)
        _NoiseScaleA("NoiseScale A", Vector) = (1, 1, 1, 0)
        _NoiseSizeA("Noise Size A", Float) = 0.8
        _SpeedA("Speed A", Float) = 0.5
        _DirectionA("Direction A", Vector) = (1.5, 0, 0, 0)
        _NoiseStrengthA("Noise Strength A", Range(0, 1)) = 0.472

        // Noise Layer B (medium scale displacement)
        _NoiseScaleB("NoiseScale B", Vector) = (1, 1, 1, 0)
        _NoiseSizeB("Noise Size B", Float) = 1.49
        _SpeedB("Speed B", Float) = 1.0
        _DirectionB("Direction B", Vector) = (1.48, -0.86, -0.36, 0)
        _NoiseStrengthB("Noise Strength B", Range(0, 1)) = 0.182

        // Noise Layer C (fine scale displacement)
        _NoiseScaleC("NoiseScale C", Vector) = (1, 1, 2.02, 0)
        _NoiseSizeC("Noise Size C", Float) = 5.0
        _SpeedC("Speed C", Float) = 10.36
        _DirectionC("DirectionC", Vector) = (1, 0, 0, 0)
        _NoiseStrengthC("Noise Strength C", Range(0, 1)) = 0.071

        // Vertex Noise
        _VertexNoiseFrequency("Vertex Noise Freq", Float) = 0.02

        // Noise Sampling
        _NoiseFrequency("Noise Frequency", Float) = 0.02
        _DetailFrequency("Detail Frequency", Float) = 0.08

        // Cloud Shape
        _CloudBaseY("Cloud Base Y", Float) = 0
        _CloudTopY("Cloud Top Y", Float) = 5
        _Coverage("Coverage", Range(0, 1)) = 0.6
        _CloudType("Cloud Type", Range(0, 1)) = 0.4
        _DensityMultiplier("Density Multiplier", Range(0, 5)) = 1.0
        _ErosionStrength("Erosion Strength", Range(0, 1)) = 0.3

        // Interior Raymarching
        _InteriorSteps("Interior Steps", Range(2, 64)) = 16
        _RaymarchMaxDist("Raymarch Max Distance", Float) = 20
        _Extinction("Extinction", Range(0.1, 5)) = 0.5
        _ShadowSteps("Shadow Steps", Range(1, 16)) = 5
        _ShadowMaxDist("Shadow Max Distance", Float) = 15

        // Lighting
        _Absorption("Light Absorption", Range(0.1, 10)) = 3.0
        _PhaseG1("Phase G1 (Forward)", Range(-0.99, 0.99)) = 0.8
        _PhaseG2("Phase G2 (Backward)", Range(-0.99, 0.99)) = -0.5
        _PhaseBlend("Phase Blend", Range(0, 1)) = 0.2
        _PowderEffect("Powder Effect", Range(0, 2)) = 1.0
        _LightMultiplier("Light Multiplier", Range(0, 5)) = 1.5

        // Ambient
        _AmbientSkyColor("Ambient Sky", Color) = (0.6, 0.7, 0.9, 1)
        _AmbientGroundColor("Ambient Ground", Color) = (0.15, 0.12, 0.1, 1)

        // Rim
        _RimColor("Rim Color", Color) = (0.86, 0.86, 0.86, 1)
        _FresnelBase("Fresnel Base", Range(0, 1)) = 0.41
        _FresnelScale("Fresnel Scale", Range(0, 2)) = 1.0
        _FresnelPower("Fresnel Power", Range(0, 8)) = 3.65

        // Vertex Color
        _VertexColorMult("Vertex Color Mult", Range(0, 3)) = 1.16

        // Misc
        _DitherNoise("Dither Noise", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }

        HLSLINCLUDE
        #pragma prefer_hlslcc gles
        #pragma exclude_renderers d3d11_9x
        #pragma target 4.0

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

        // Material properties
        CBUFFER_START(UnityPerMaterial)
            float4 _NoiseScaleA; float _NoiseSizeA; float _SpeedA; float4 _DirectionA; float _NoiseStrengthA;
            float4 _NoiseScaleB; float _NoiseSizeB; float _SpeedB; float4 _DirectionB; float _NoiseStrengthB;
            float4 _NoiseScaleC; float _NoiseSizeC; float _SpeedC; float4 _DirectionC; float _NoiseStrengthC;
            float _CloudBaseY; float _CloudTopY; float _Coverage; float _CloudType;
            float _DensityMultiplier; float _ErosionStrength;
            float _NoiseFrequency; float _DetailFrequency;
            float _InteriorSteps; float _RaymarchMaxDist; float _Extinction;
            float _ShadowSteps; float _ShadowMaxDist;
            float _Absorption; float _PhaseG1; float _PhaseG2; float _PhaseBlend;
            float _PowderEffect; float _LightMultiplier;
            float4 _AmbientSkyColor; float4 _AmbientGroundColor;
            float4 _RimColor; float _FresnelBase; float _FresnelScale; float _FresnelPower;
            float _VertexColorMult;
            float _VertexNoiseFrequency;
        CBUFFER_END

        TEXTURE3D(_PerlinWorleyTex);       SAMPLER(sampler_PerlinWorleyTex);
        TEXTURE3D(_WorleyTex);             SAMPLER(sampler_WorleyTex);
        TEXTURE2D(_DitherNoise);           SAMPLER(sampler_DitherNoise);

        float4 _PerlinWorleyTex_TexelSize;
        float4 _WorleyTex_TexelSize;

        struct Attributes
        {
            float4 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 color : COLOR;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS : TEXCOORD0;
            half3 normalWS : TEXCOORD1;
            half3 viewDirWS : TEXCOORD2;
            half4 vertexColor : COLOR;
            half fogFactor : TEXCOORD3;
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };

        struct ShadowVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS : TEXCOORD0;
            half3 normalWS : TEXCOORD1;
            half4 vertexColor : COLOR;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        // ============================================================
        // Utility
        // ============================================================
        float Remap(float value, float inMin, float inMax, float outMin, float outMax)
        {
            return outMin + (value - inMin) * (outMax - outMin) / max(inMax - inMin, 0.0001);
        }

        // ============================================================
        // Henyey-Greenstein Phase Functions
        // ============================================================
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

        // ============================================================
        // Nubis Density Model
        // ============================================================
        float EvaluateCloudDensity(float3 positionWS)
        {
            float h = (positionWS.y - _CloudBaseY) / max(_CloudTopY - _CloudBaseY, 0.01);
            if (h < 0.0 || h > 1.0) return 0.0;

            // Height gradient: Nubis-style profile
            float cumulusTop = 0.3 + _CloudType * 0.65;
            float heightGrad = smoothstep(0.0, 0.1, h) * (1.0 - smoothstep(cumulusTop, 1.0, h));

            // Sample Perlin-Worley texture
            float4 pw = SAMPLE_TEXTURE3D_LOD(_PerlinWorleyTex, sampler_PerlinWorleyTex, positionWS * _NoiseFrequency, 0);
            // R channel stores Perlin [0,1], remap to [-1,1]
            float perlin = pw.r * 2.0 - 1.0;
            // GBA store Worley FBM (F1 distance, normalized [0,1])
            float worleyFBM = pw.g * 0.625 + pw.b * 0.25 + pw.a * 0.125;

            // Perlin-Worley dilation: Worley perturbs Perlin's remap lower bound
            float cloudShape = Remap(perlin, -(1.0 - worleyFBM), 1.0, 0.0, 1.0);

            // Coverage remap
            float coverageMask = 1.0 - _Coverage;
            cloudShape = Remap(cloudShape, coverageMask, 1.0, 0.0, 1.0) * _Coverage;

            // Apply height gradient
            float density = cloudShape * heightGrad;

            // High-frequency Worley erosion (detail texture)
            float3 w = SAMPLE_TEXTURE3D_LOD(_WorleyTex, sampler_WorleyTex, positionWS * _DetailFrequency, 0);
            float erosionFBM = w.r * 0.625 + w.g * 0.25 + w.b * 0.125;
            density = Remap(density, erosionFBM * _ErosionStrength * 0.5, 1.0, 0.0, 1.0);

            return saturate(density) * _DensityMultiplier;
        }

        // ============================================================
        // Sun Occlusion (short raymarch toward sun)
        // ============================================================
        float SampleSunOcclusion(float3 pos, float3 sunDir)
        {
            float occlusion = 1.0;
            float stepSize = _ShadowMaxDist / _ShadowSteps;
            int steps = (int)_ShadowSteps;
            for (int i = 0; i < 16; i++)
            {
                if (i >= steps) break;
                float d = ((float)i + 0.5) * stepSize;
                float3 samplePos = pos + sunDir * d;
                float density = EvaluateCloudDensity(samplePos);
                occlusion *= exp(-density * stepSize * _Extinction * 2.0);
                if (occlusion < 0.05) break;
            }
            return occlusion;
        }

        // ============================================================
        // Cloud Lighting
        // ============================================================
        half3 EvaluateCloudLighting(float3 pos, half3 N, half3 V)
        {
            Light mainLight = GetMainLight();
            half3 L = SafeNormalize(mainLight.direction);
            half3 lightColor = mainLight.color * mainLight.distanceAttenuation * mainLight.shadowAttenuation;

            float cosTheta = dot(L, V);
            float phase = DualLobeHG(cosTheta, _PhaseG1, _PhaseG2, _PhaseBlend);

            float sunOcclusion = SampleSunOcclusion(pos, L);

            // Beer-Lambert + Powder effect (multi-scatter approximation)
            float beers = exp(-_Absorption * 0.5); // per-sample absorption
            float powder = saturate(pow(max(beers, 0.001), 0.25) + 1.0 - pow(max(1.0 - beers, 0.001), 4.0));

            half3 singleScatter = lightColor * sunOcclusion * phase * (1.0 - beers);
            half3 powderContrib = lightColor * sunOcclusion * powder * _PowderEffect * 0.5;

            // Ambient (sky/ground hemisphere)
            float ambientBlend = saturate(N.y * 0.5 + 0.5);
            half3 ambient = lerp(_AmbientGroundColor.rgb, _AmbientSkyColor.rgb, ambientBlend);

            // Rim light (Fresnel approximation)
            float ndotV = abs(dot(N, V));
            float fresnel = _FresnelBase + _FresnelScale * pow(1.0 - ndotV, _FresnelPower);
            half3 rim = fresnel * _RimColor.rgb;

            return (singleScatter + powderContrib) * _LightMultiplier + ambient * 0.3 + rim * 0.15;
        }

        // ============================================================
        // Surface Albedo (from vertex color)
        // ============================================================
        half3 EvaluateSurfaceAlbedo(half4 vertexColor)
        {
            // Gamma decode vertex color and apply multiplier
            half4 tint = saturate(pow(saturate(vertexColor), 0.454545) * _VertexColorMult);
            return tint.rgb;
        }

        // ============================================================
        // Vertex Displacement using 3D noise textures
        // ============================================================
        float3 ApplyCloudVertexOffset(float3 positionOS)
        {
            float3 positionWS = TransformObjectToWorld(positionOS);
            float timeA = _Time.y * _SpeedA;
            float timeB = _Time.y * _SpeedB;
            float timeC = _Time.y * _SpeedC;

            // Layer A: Sample Perlin-Worley R channel (Perlin, large scale)
            float3 sampleCoordA = (positionWS * _NoiseScaleA.xyz * _NoiseSizeA + _DirectionA.xyz * timeA) * _VertexNoiseFrequency;
            float noiseA = SAMPLE_TEXTURE3D_LOD(_PerlinWorleyTex, sampler_PerlinWorleyTex, sampleCoordA, 0).r;

            // Layer B: Sample Perlin-Worley G channel (Worley, medium scale)
            float3 sampleCoordB = (positionWS * _NoiseScaleB.xyz * _NoiseSizeB + _DirectionB.xyz * timeB) * _VertexNoiseFrequency;
            float noiseB = SAMPLE_TEXTURE3D_LOD(_PerlinWorleyTex, sampler_PerlinWorleyTex, sampleCoordB, 0).g;

            // Layer C: Sample Worley detail R channel (high freq)
            float3 sampleCoordC = (positionWS * _NoiseScaleC.xyz * _NoiseSizeC + _DirectionC.xyz * timeC) * _VertexNoiseFrequency;
            float noiseC = SAMPLE_TEXTURE3D_LOD(_WorleyTex, sampler_WorleyTex, sampleCoordC, 0).r;

            float offset = noiseA * _NoiseStrengthA + noiseB * _NoiseStrengthB + noiseC * _NoiseStrengthC;
            return positionOS + float3(0.0, offset, 0.0);
        }

        // ============================================================
        // Shadow Caster Helper
        // ============================================================
        float4 GetCloudShadowPositionHClip(float3 positionOS, float3 normalOS, float3 lightDir)
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

        // ============================================================
        // PASS 1: Forward Rendering
        // ============================================================
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma vertex CloudLitPassVertex
            #pragma fragment CloudLitPassFragment

            Varyings CloudLitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float3 positionOS = ApplyCloudVertexOffset(input.positionOS.xyz);
                VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);

                float3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;

                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
                output.viewDirWS = viewDirWS;
                output.fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
                output.vertexColor = input.color;
                return output;
            }

            half4 CloudLitPassFragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half3 N = NormalizeNormalPerPixel(input.normalWS);
                half3 V = SafeNormalize(input.viewDirWS);
                half3 surfaceAlbedo = EvaluateSurfaceAlbedo(input.vertexColor);

                // Interior raymarching: from surface, deeper into mesh along view ray
                float3 rayOrigin = GetCameraPositionWS();
                float3 rayDir = SafeNormalize(input.positionWS - rayOrigin); // camera → surface
                float3 marchStart = input.positionWS + rayDir * 0.05;       // slight offset inward

                float stepSize = _RaymarchMaxDist / _InteriorSteps;
                float transmittance = 1.0;
                half3 accumulatedLight = half3(0, 0, 0);

                for (int i = 0; i < 64; i++)
                {
                    if (i >= (int)_InteriorSteps) break;

                    float3 pos = marchStart + rayDir * ((float)i + 0.5) * stepSize;
                    float d = EvaluateCloudDensity(pos);

                    if (d > 0.001)
                    {
                        float opticalDepth = d * stepSize * _Extinction;
                        half3 lighting = EvaluateCloudLighting(pos, N, V);
                        accumulatedLight += lighting * transmittance * (1.0 - exp(-opticalDepth));
                        transmittance *= exp(-opticalDepth);
                        if (transmittance < 0.01) break;
                    }
                }

                // Blend surface albedo through transmittance
                half3 color = surfaceAlbedo * transmittance + accumulatedLight;
                color = MixFog(color, input.fogFactor);

                float alpha = saturate(1.0 - transmittance) * saturate(input.vertexColor.a);
                alpha = max(alpha, 0.05); // prevent fully invisible pixels

                return half4(color, alpha);
            }
            ENDHLSL
        }

        // ============================================================
        // PASS 2: Shadow Caster
        // ============================================================
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
            #pragma vertex CloudShadowPassVertex
            #pragma fragment CloudShadowPassFragment

            ShadowVaryings CloudShadowPassVertex(Attributes input)
            {
                ShadowVaryings output = (ShadowVaryings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                float3 positionOS = ApplyCloudVertexOffset(input.positionOS.xyz);
                float3 worldPos = TransformObjectToWorld(positionOS);
                output.positionCS = GetCloudShadowPositionHClip(positionOS, input.normalOS, _MainLightPosition.xyz);
                output.positionWS = worldPos;
                output.normalWS = NormalizeNormalPerVertex(TransformObjectToWorldNormal(input.normalOS));
                output.vertexColor = input.color;
                return output;
            }

            half4 CloudShadowPassFragment(ShadowVaryings input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);

                half3 V = SafeNormalize(GetCameraPositionWS() - input.positionWS);
                half3 N = NormalizeNormalPerPixel(input.normalWS);

                // Evaluate cloud density at surface for shadow alpha
                float density = EvaluateCloudDensity(input.positionWS);
                float alpha = saturate(density * 0.5 + 0.3) * saturate(input.vertexColor.a);
                clip(alpha - 0.15);
                return 0;
            }
            ENDHLSL
        }
    }

    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
