// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X
Shader "_Clouds/Clouds Unlit Vertex Color"
{
    Properties
    {
        _TopTexture0("Top Texture 0", 2D) = "white" {}
        _TessValue("Max Tessellation", Range( 1, 32 ) ) = 21.6
        _TessMin("Tess Min Distance", Float ) = 0.7
        _TessMax("Tess Max Distance", Float ) = 10.94
        _NoiseScaleA("NoiseScale A", Vector) = (1,1,1,0)
        _3dNoiseSizeA("3dNoise Size A", Float) = 0
        _SpeedA("Speed A", Float) = 0
        _DirectionA("Direction A", Vector) = (1,0,0,0)
        _NoiseStrengthA("Noise Strength A", Range( 0 , 1)) = 0
        _3dNoiseSizeB("3dNoise Size B", Float) = 0
        _NoiseScaleB("NoiseScale B", Vector) = (1,1,1,0)
        _SpeedB("Speed B", Float) = 0
        _DirectionB("Direction B", Vector) = (1,0,0,0)
        _NoiseStrengthB("Noise Strength B", Range( 0 , 1)) = 0
        _NoiseScaleC("NoiseScale C", Vector) = (1,1,1,0)
        _3dNoiseSizeC("3dNoise Size C", Float) = 0
        _SpeedC("SpeedC", Float) = 0
        _DirectionC("DirectionC", Vector) = (1,0,0,0)
        _NoiseStrengthC("Noise Strength C", Range( 0 , 1)) = 0
        _textureDetail("textureDetail", Range( 0 , 1)) = 0
        _TextureColor("Texture Color", Color) = (0,0,0,0)
        _Tiling("Tiling", Vector) = (0.04,0.04,0,0)
        _Fallof("Fallof", Float) = 1
        _VertexColorMult("Vertex Color Mult", Float) = 1
        _RimColor("Rim Color", Color) = (0,0,0,0)
        _FresnelBSP("FresnelBSP", Vector) = (0,0,0,0)
        _Absorption("Light Absorption", Range( 0.1 , 10)) = 2.0
        _DensityScale("Density Scale", Range( 0 , 5)) = 1.0
        _PhaseG("HG Phase G", Range( -0.99 , 0.99)) = 0.4
        _PhaseStrength("Phase Strength", Range( 0 , 3)) = 1.0
        _WrapLighting("Wrap Lighting", Range( 0 , 1)) = 0.5
        _AmbientSkyColor("Ambient Sky", Color) = (0.6,0.7,0.9,1)
        _AmbientGroundColor("Ambient Ground", Color) = (0.15,0.12,0.1,1)
        _PowderEffect("Powder Effect", Range( 0 , 2)) = 1.0
        _LightMultiplier("Light Multiplier", Range( 0 , 5)) = 1.0
        _EdgeFade("Edge Fade", Range( 0.01 , 5)) = 1.0
        [HideInInspector] __dirty( "", Int ) = 1
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }

        HLSLINCLUDE
        #pragma prefer_hlslcc gles
        #pragma exclude_renderers d3d11_9x
        #pragma target 3.0

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _NoiseScaleA;
            float4 _NoiseScaleB;
            float4 _NoiseScaleC;
            float4 _DirectionA;
            float4 _DirectionB;
            float4 _DirectionC;
            float4 _TextureColor;
            float4 _Tiling;
            float4 _RimColor;
            float4 _FresnelBSP;
            float4 _AmbientSkyColor;
            float4 _AmbientGroundColor;
            float _TessValue;
            float _TessMin;
            float _TessMax;
            float _3dNoiseSizeA;
            float _SpeedA;
            float _NoiseStrengthA;
            float _3dNoiseSizeB;
            float _SpeedB;
            float _NoiseStrengthB;
            float _3dNoiseSizeC;
            float _SpeedC;
            float _NoiseStrengthC;
            float _textureDetail;
            float _Fallof;
            float _VertexColorMult;
            float _Absorption;
            float _DensityScale;
            float _PhaseG;
            float _PhaseStrength;
            float _WrapLighting;
            float _PowderEffect;
            float _LightMultiplier;
            float _EdgeFade;
        CBUFFER_END

        TEXTURE2D(_TopTexture0);
        SAMPLER(sampler_TopTexture0);

        float3 _LightDirection;

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
            half fogFactor : TEXCOORD3;
            half4 color : COLOR;
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };

        struct ShadowVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS : TEXCOORD0;
            half3 normalWS : TEXCOORD1;
            half4 color : COLOR;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct CloudSurfaceData
        {
            half3 baseColor;
            half alpha;
            half rawDensity;
            half thickness;
            half fresnel;
        };

        float2 Mod289(float2 x)
        {
            return x - floor(x * (1.0 / 289.0)) * 289.0;
        }

        float3 Mod289(float3 x)
        {
            return x - floor(x * (1.0 / 289.0)) * 289.0;
        }

        float4 Mod289(float4 x)
        {
            return x - floor(x * (1.0 / 289.0)) * 289.0;
        }

        float3 Permute(float3 x)
        {
            return Mod289(((x * 34.0) + 1.0) * x);
        }

        float4 Permute(float4 x)
        {
            return Mod289(((x * 34.0) + 1.0) * x);
        }

        float4 TaylorInvSqrt(float4 r)
        {
            return 1.79284291400159 - r * 0.85373472095314;
        }

        float SimplexNoise(float2 v)
        {
            const float4 C = float4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
            float2 i = floor(v + dot(v, C.yy));
            float2 x0 = v - i + dot(i, C.xx);
            float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
            float4 x12 = x0.xyxy + C.xxzz;
            x12.xy -= i1;
            i = Mod289(i);
            float3 p = Permute(Permute(i.y + float3(0.0, i1.y, 1.0)) + i.x + float3(0.0, i1.x, 1.0));
            float3 m = max(0.5 - float3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
            m *= m;
            m *= m;
            float3 x = 2.0 * frac(p * C.www) - 1.0;
            float3 h = abs(x) - 0.5;
            float3 ox = floor(x + 0.5);
            float3 a0 = x - ox;
            m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
            float3 g;
            g.x = a0.x * x0.x + h.x * x0.y;
            g.yz = a0.yz * x12.xz + h.yz * x12.yw;
            return 130.0 * dot(m, g);
        }

        float SimplexNoise(float3 v)
        {
            const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);
            float3 i = floor(v + dot(v, C.yyy));
            float3 x0 = v - i + dot(i, C.xxx);
            float3 g = step(x0.yzx, x0.xyz);
            float3 l = 1.0 - g;
            float3 i1 = min(g.xyz, l.zxy);
            float3 i2 = max(g.xyz, l.zxy);
            float3 x1 = x0 - i1 + C.xxx;
            float3 x2 = x0 - i2 + C.yyy;
            float3 x3 = x0 - 0.5;
            i = Mod289(i);
            float4 p = Permute(Permute(Permute(i.z + float4(0.0, i1.z, i2.z, 1.0)) + i.y + float4(0.0, i1.y, i2.y, 1.0)) + i.x + float4(0.0, i1.x, i2.x, 1.0));
            float4 j = p - 49.0 * floor(p / 49.0);
            float4 x_ = floor(j / 7.0);
            float4 y_ = floor(j - 7.0 * x_);
            float4 x = (x_ * 2.0 + 0.5) / 7.0 - 1.0;
            float4 y = (y_ * 2.0 + 0.5) / 7.0 - 1.0;
            float4 h = 1.0 - abs(x) - abs(y);
            float4 b0 = float4(x.xy, y.xy);
            float4 b1 = float4(x.zw, y.zw);
            float4 s0 = floor(b0) * 2.0 + 1.0;
            float4 s1 = floor(b1) * 2.0 + 1.0;
            float4 sh = -step(h, 0.0);
            float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
            float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
            float3 g0 = float3(a0.xy, h.x);
            float3 g1 = float3(a0.zw, h.y);
            float3 g2 = float3(a1.xy, h.z);
            float3 g3 = float3(a1.zw, h.w);
            float4 norm = TaylorInvSqrt(float4(dot(g0, g0), dot(g1, g1), dot(g2, g2), dot(g3, g3)));
            g0 *= norm.x;
            g1 *= norm.y;
            g2 *= norm.z;
            g3 *= norm.w;
            float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
            m *= m;
            m *= m;
            float4 px = float4(dot(x0, g0), dot(x1, g1), dot(x2, g2), dot(x3, g3));
            return 42.0 * dot(m, px);
        }

        float RemapNoise01(float value)
        {
            return saturate((value + 1.0) * 0.5);
        }

        float Remap(float value, float inMin, float inMax, float outMin, float outMax)
        {
            return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin);
        }

        float4 TriplanarSamplingSF(float3 worldPos, float3 worldNormal, float falloff, float2 tiling)
        {
            float3 projNormal = pow(abs(worldNormal), falloff);
            projNormal /= (projNormal.x + projNormal.y + projNormal.z) + 0.00001;
            float3 normalSign = sign(worldNormal);
            half4 xSample = SAMPLE_TEXTURE2D(_TopTexture0, sampler_TopTexture0, tiling * worldPos.zy * float2(normalSign.x, 1.0));
            half4 ySample = SAMPLE_TEXTURE2D(_TopTexture0, sampler_TopTexture0, tiling * worldPos.xz * float2(normalSign.y, 1.0));
            half4 zSample = SAMPLE_TEXTURE2D(_TopTexture0, sampler_TopTexture0, tiling * worldPos.xy * float2(-normalSign.z, 1.0));
            return xSample * projNormal.x + ySample * projNormal.y + zSample * projNormal.z;
        }

        float HenyeyGreenstein(float g, float cosTheta)
        {
            float g2 = g * g;
            float denom = 1.0 + g2 - 2.0 * g * cosTheta;
            return (1.0 - g2) / (4.0 * 3.14159265 * pow(denom, 1.5));
        }

        float3 ApplyCloudVertexOffset(float3 positionOS)
        {
            float3 positionWS = TransformObjectToWorld(positionOS);
            float timeA = _Time.y * _SpeedA;
            float timeB = _Time.y * _SpeedB;
            float timeC = _Time.y * _SpeedC;

            float noiseA = RemapNoise01(SimplexNoise((_DirectionA.xyz * timeA) + (_3dNoiseSizeA * (positionWS * _NoiseScaleA.xyz))));
            float noiseB = RemapNoise01(SimplexNoise((_DirectionB.xyz * timeB) + (_3dNoiseSizeB * (positionWS * _NoiseScaleB.xyz))));
            float noiseC = RemapNoise01(SimplexNoise((_DirectionC.xyz * timeC) + (_3dNoiseSizeC * (positionWS * _NoiseScaleC.xyz))));

            float offset = noiseA * _NoiseStrengthA + noiseB * _NoiseStrengthB + noiseC * _NoiseStrengthC;
            return positionOS + float3(0.0, offset, 0.0);
        }

        CloudSurfaceData EvaluateCloudSurface(float3 positionWS, half3 normalWS, half4 vertexColor, half3 viewDirWS)
        {
            CloudSurfaceData surface;

            float timeA = _Time.y * _SpeedA;
            float timeC = _Time.y * _SpeedC;
            float noiseA = RemapNoise01(SimplexNoise((_DirectionA.xyz * timeA) + (_3dNoiseSizeA * (positionWS * _NoiseScaleA.xyz))));
            float3 noiseWorldPos = (_DirectionC.xyz * timeC) + (_3dNoiseSizeC * (positionWS * _NoiseScaleC.xyz));
            float4 triplanar = TriplanarSamplingSF(noiseWorldPos, normalWS, _Fallof, _Tiling.xy);
            float worldNoise2D = SimplexNoise(positionWS.xz * 0.1);
            float detailMask = ((1.0 - triplanar.x) * _textureDetail) * saturate(noiseA) * Remap(worldNoise2D, -1.0, 1.0, 0.25, 1.0);

            half4 vertexTint = saturate(pow(saturate(vertexColor), 0.454545) * _VertexColorMult);
            half4 mixedColor = lerp(vertexTint, _TextureColor, saturate(detailMask));

            half ndotV = saturate(dot(normalWS, viewDirWS));
            half fresnel = _FresnelBSP.x + _FresnelBSP.y * pow(1.0h - ndotV, _FresnelBSP.z);
            half rawDensity = saturate(vertexColor.a * _DensityScale * (0.5h + 0.5h * noiseA));
            half viewThickness = saturate(1.0h - ndotV);
            half thickness = rawDensity * (0.3h + 0.7h * viewThickness);
            half edgeAlpha = saturate((1.0h - ndotV) * _EdgeFade + 0.2h);

            surface.baseColor = saturate(mixedColor.rgb);
            surface.rawDensity = rawDensity;
            surface.thickness = thickness;
            surface.alpha = edgeAlpha * saturate(rawDensity + 0.3h);
            surface.fresnel = fresnel;
            return surface;
        }

        half3 EvaluateCloudLighting(float3 positionWS, half3 normalWS, half3 viewDirWS, CloudSurfaceData surface)
        {
            float4 shadowCoord = float4(0.0, 0.0, 0.0, 0.0);
            #if defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                shadowCoord = TransformWorldToShadowCoord(positionWS);
            #endif

            Light mainLight = GetMainLight(shadowCoord);
            half3 lightDir = SafeNormalize(mainLight.direction);
            half3 lightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);

            half beersLaw = exp(-surface.thickness * _Absorption);
            half powder = pow(max(beersLaw, 0.001h), 0.25h) + 1.0h - pow(max(1.0h - beersLaw, 0.001h), 4.0h);
            powder = saturate(powder);

            half ndotL = dot(normalWS, lightDir);
            half wrapDiffuse = saturate((ndotL + _WrapLighting) / (1.0h + _WrapLighting));
            half cosTheta = dot(lightDir, viewDirWS);
            half phase = HenyeyGreenstein(_PhaseG, cosTheta);
            half isotropic = 1.0h / (4.0h * 3.14159265h);
            half phaseBlended = lerp(isotropic, phase, _PhaseStrength);

            half3 directLight = surface.baseColor * lightColor;
            half3 diffuseContrib = directLight * wrapDiffuse * beersLaw;
            half3 scatterContrib = directLight * phaseBlended * 2.0h * (1.0h - beersLaw);
            half3 powderContrib = directLight * powder * _PowderEffect * 0.5h;
            half3 litColor = (diffuseContrib + scatterContrib + powderContrib) * _LightMultiplier;

            half ambientBlend = saturate(normalWS.y * 0.5h + 0.5h);
            half3 ambientColor = lerp(_AmbientGroundColor.rgb, _AmbientSkyColor.rgb, ambientBlend);
            half3 ambientContrib = ambientColor * surface.baseColor * 0.35h;
            half3 rimContrib = surface.fresnel * _RimColor.rgb;

            return litColor + ambientContrib + rimContrib;
        }

        Varyings CloudLitPassVertex(Attributes input)
        {
            Varyings output = (Varyings)0;
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_TRANSFER_INSTANCE_ID(input, output);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

            float3 positionOS = ApplyCloudVertexOffset(input.positionOS.xyz);
            VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS);
            VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
            half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;

            output.positionCS = vertexInput.positionCS;
            output.positionWS = vertexInput.positionWS;
            output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
            output.viewDirWS = viewDirWS;
            output.fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
            output.color = input.color;
            return output;
        }

        half4 CloudLitPassFragment(Varyings input) : SV_Target
        {
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            half3 normalWS = NormalizeNormalPerPixel(input.normalWS);
            half3 viewDirWS = SafeNormalize(input.viewDirWS);
            CloudSurfaceData surface = EvaluateCloudSurface(input.positionWS, normalWS, input.color, viewDirWS);
            half3 color = EvaluateCloudLighting(input.positionWS, normalWS, viewDirWS, surface);
            color = MixFog(color, input.fogFactor);
            return half4(color, surface.alpha);
        }

        float4 GetCloudShadowPositionHClip(float3 positionOS, float3 normalOS)
        {
            float3 positionWS = TransformObjectToWorld(positionOS);
            float3 normalWS = TransformObjectToWorldNormal(normalOS);
            float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

            #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #else
                positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #endif

            return positionCS;
        }

        ShadowVaryings CloudShadowPassVertex(Attributes input)
        {
            ShadowVaryings output = (ShadowVaryings)0;
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_TRANSFER_INSTANCE_ID(input, output);

            float3 positionOS = ApplyCloudVertexOffset(input.positionOS.xyz);
            output.positionCS = GetCloudShadowPositionHClip(positionOS, input.normalOS);
            output.positionWS = TransformObjectToWorld(positionOS);
            output.normalWS = NormalizeNormalPerVertex(TransformObjectToWorldNormal(input.normalOS));
            output.color = input.color;
            return output;
        }

        half4 CloudShadowPassFragment(ShadowVaryings input) : SV_TARGET
        {
            UNITY_SETUP_INSTANCE_ID(input);

            half3 viewDirWS = SafeNormalize(GetCameraPositionWS() - input.positionWS);
            half3 normalWS = NormalizeNormalPerPixel(input.normalWS);
            CloudSurfaceData surface = EvaluateCloudSurface(input.positionWS, normalWS, input.color, viewDirWS);
            clip(surface.alpha - 0.1h);
            return 0;
        }
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Blend One Zero
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
            ENDHLSL
        }

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
            ENDHLSL
        }
    }

    Fallback "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "ASEMaterialInspector"
}
