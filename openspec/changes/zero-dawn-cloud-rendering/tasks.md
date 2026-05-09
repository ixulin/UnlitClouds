## 1. Shader 脚手架与基础设施

- [ ] 1.1 创建 `Assets/__CLOUDS/CloudZD.shader` 基础结构：Shader 名称 `"_Clouds/Cloud ZD"`，Properties 块声明所有 material 参数（3D 噪声纹理、噪声层参数、密度参数、Ray Marching 参数、光照参数、环境光/Rim 参数、调试参数）
- [ ] 1.2 创建 SubShader 标签（Transparent Queue、URP）、`HLSLINCLUDE` 块、CBUFFER、纹理声明、Attributes/Varyings/ShadowVaryings 结构体
- [ ] 1.3 实现工具函数：`Remap()`、`Mod289()`、`Permute()`（如需要）

## 2. 密度采样管线 (density-sampling)

- [ ] 2.1 实现高度梯度计算：`heightGrad = smoothstep(0, 0.1, h) * (1 - smoothstep(cumulusTop, 1, h))`
- [ ] 2.2 实现 Perlin-Worley 采样：R 通道 Perlin → Worley GBA FBM 扰动 Perlin 重映射下界
- [ ] 2.3 实现 Coverage 重映射：`Remap(cloudShape, 1-_Coverage, 1, 0, 1) * _Coverage`
- [ ] 2.4 实现 Worley FBM 细节侵蚀：采样 `_WorleyTex`，计算 erosionFBM，侵蚀密度
- [ ] 2.5 实现顶点色密度遮罩：`finalDensity = sampledDensity * vertexColorAlpha`

## 3. 相位函数 (phase-function)

- [ ] 3.1 实现 `HGPhase(g, cosTheta)` — 标准 Henyey-Greenstein 公式
- [ ] 3.2 实现 `DualLobeHG(cosTheta, g1, g2, blend)` — 两 lobes 线性插值

## 4. Beer-Lambert 与 Powder Effect (beer-lambert-absorption, powder-effect, multi-scatter)

- [ ] 4.1 实现 `SampleSunOcclusion(pos, sunDir)` — 朝日 Shadow Ray Marching（`_ShadowSteps` 步，累积 occlusion）
- [ ] 4.2 实现核心光照函数 `SampleCloudLighting(pos, N, V, density, stepSize)`，包含：
  - Beer-Lambert: `beersLaw = exp(-opticalDepth)`
  - Powder Effect: `powder = 1.0 - exp(-opticalDepth * 2.0)`，`beersPowder = max(beersLaw, powder * _PowderEffect)`
  - Multi-Scatter: `multiScatter = exp(-opticalDepth * 0.25) * _MultiScatter`
  - 直射光：`directLight * phase * beersPowder * (1 - exp(-opticalDepth))`
  - 多散射光：`directLight * multiScatter * 0.5`

## 5. 环境光与边缘光 (cloud-ambient-rim)

- [ ] 5.1 在 `SampleCloudLighting` 中实现半球环境光：`ambientBlend = saturate(N.y * 0.5 + 0.5)`，密度调制
- [ ] 5.2 在 `SampleCloudLighting` 中实现 Fresnel Rim：`fresnel = _RimBase + _RimScale * pow(1 - |N·V|, _RimPower)`

## 6. Ray Marching 主循环 (cloud-raymarching)

- [ ] 6.1 实现顶点位移函数 `ApplyVertexOffset(positionOS)` — 三层噪声采样（PerlinWorley R/G + Worley R）
- [ ] 6.2 实现 Forward Lit Pass 的 Vertex Shader（位移、变换、传递 varyings）
- [ ] 6.3 实现 Fragment Shader 的 Ray March 主循环：蓝噪声抖动 → 步进采样 → 密度评估 → 光照累积 → 透射率衰减 → 早期退出
- [ ] 6.4 实现最终颜色合成：`color = surfaceAlbedo * transmittance + scatteredLight`，`alpha = (1 - transmittance) * vertexDensity`

## 7. Shadow Caster Pass

- [ ] 7.1 实现 Shadow Caster 的 Vertex/Fragment Shader（顶点位移、密度评估、alpha clip）

## 8. 调试可视化 (cloud-debug)

- [ ] 8.1 实现 `_DebugView` 模式切换：Normal(0) 正常渲染、Density(1) 密度灰度图、Transmittance(2) 透射率灰度图

## 9. 材质创建与验证

- [ ] 9.1 创建 `Assets/__CLOUDS/CloudZD.mat` 材质，指定 `CloudZD` Shader，设置 3D 噪声纹理引用
- [ ] 9.2 在 Unity Editor 中验证 Shader 编译通过、材质 Inspector 显示正确
- [ ] 9.3 在 CloudScene 中应用 CloudZD 材质到云 Mesh，调整参数验证视觉效果
