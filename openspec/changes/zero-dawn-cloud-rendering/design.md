## Context

项目是一个 Unity URP 下的 Mesh 云渲染系统。云由 FBX 网格建模，顶点色（RGBA）编码密度和色调。已有 3D 噪声纹理生成管线（`CloudNoiseGenerator.cs`，生成 Perlin-Worley 128³ 和 Worley 32³）。目标是在 Mesh 表面 Shader 基础上，通过内部 Ray Marching 实现接近 Horizon Zero Dawn（Decima/Nubis）的体积云渲染效果。

约束：
- 使用 URP Shader Library（`Core.hlsl`、`Lighting.hlsl`、`Shadows.hlsl`）
- Shader Model 4.0+（3D 纹理采样）
- Mesh 顶点色 RGBA 作为输入（RGB=色调，A=密度遮罩）
- 不修改已有 Shader 文件，创建全新的 `CloudZD.shader`

## Goals / Non-Goals

**Goals:**
- 从零实现一套完整的 ZD 风格体积云 Shader
- Beer-Lambert 指数衰减作为核心透射率模型
- Powder Effect 使云边缘在朝光方向更亮
- Dual-lobe HG 相位函数实现真实感散射分布
- 多散射近似防止云底部全黑
- 内部 Ray Marching 累积散射光
- 蓝噪声抖动消除 banding 伪影
- 提供调试可视化模式（密度、透射率、光照分量）
- 代码清晰，分模块注释，便于逐功能调参

**Non-Goals:**
- 不做全屏体积云 Ray Marching（保持 Mesh 基础）
- 不做时间域重投影（TAA 积累）
- 不做 LOD 系统或距离自适应步进
- 不做云的动态生成/消散动画（仅已有的噪声时间偏移顶点动画）
- 不修改噪声生成器或纹理格式

## Decisions

### 1. 单一 Shader 文件，HLSLINCLUDE 共享函数
**选择**: 所有函数写在 `CloudZD.shader` 的 `HLSLINCLUDE` 块中，Forward 和 Shadow Caster 两个 Pass 共享。
**理由**: Mesh 云不需要 G-Buffer 或 Deferred Pass，保持单文件简洁性，减少维护负担。
**替代方案**: 拆成 `.hlsl` include 文件 → 过度工程化，一个 Shader 不需要。

### 2. Beer-Lambert + Powder + Multi-Scatter 三合一光照模型
**选择**: 在每个 Ray March 样本点计算：
- `beersLaw = exp(-opticalDepth)` — 经典 Beer-Lambert
- `powder = 1.0 - exp(-opticalDepth * 2.0)` — 简化 Powder Effect
- `beersPowder = max(beersLaw, powder * _PowderEffect)` — 取最大值
- `multiScatter = exp(-opticalDepth * 0.25)` — 低次散射近似

**理由**: HZD (Nubis) 论文中这三种效果的组合公式是：
```
lightEnergy = beersPowder + multiScatter * silverLining
```
其中 `silverLining` 是银边效应。简化版直接用 `max(beers, powder)` 已足够产生视觉效果。

**替代方案**: 精确多散射级数展开 → Shader 计算量过大，性价比低。

### 3. Dual-lobe Henyey-Greenstein 相位函数
**选择**: 两个 HG lobes 线性插值：`lerp(HG(g1), HG(g2), blend)`，g1≈0.8（强前向），g2≈-0.5（弱后向）。
**理由**: 单 HG lobe 无法同时表达前向散射的银边和后向散射的灰暗面。Dual-lobe 是 Nubis 论文的标准做法。
**替代方案**: Cornette-Shanks 或 Mie 近似 → 计算更复杂，视觉效果差异微小。

### 4. 密度采样管线
**选择**: 沿用 Perlin-Worley + Worley FBM 侵蚀的经典管线：
1. 高度梯度（cumulus 钟形曲线）
2. Perlin-Worley R 通道采样 → Worley GBA 扰动 Perlin 重映射下界
3. Coverage 重映射
4. Worley FBM 细节侵蚀
5. 乘以 `_DensityMultiplier`

**理由**: 这是 Nubis/Decima 的密度模型核心，已被广泛验证效果良好。
**替代方案**: 纯程序化 Simplex 噪声 → 低频形状不够自然（已在旧 Shader 中验证）。

### 5. 蓝噪声抖动 Offset
**选择**: 使用 2D 蓝噪声纹理（`_DitherNoise`）对 Ray March 起始偏移做 jitter：`offset = dither * stepSize`
**理由**: 消除等间距采样产生的 banding 伪影，比白噪声更均匀。
**替代方案**: 交错帧（interleaved gradient noise）→ 需要额外的 `_ScreenParams` 计算，且本方案已有纹理可用。

### 6. 渲染设置
**选择**: `Blend SrcAlpha OneMinusSrcAlpha`，`ZWrite Off`，`Cull Back`，Queue=Transparent。
**理由**: Ray Marching 产出的 alpha 由透射率决定（`1 - transmittance`），需要正确的 Alpha 混合。ZWrite Off 避免重叠云 Mesh 的深度冲突。

## Risks / Trade-offs

- **[性能]** Ray Marching 在每个片元执行 48+ 步 × (密度采样 + 8 步 Shadow Ray) → **缓解**: 早期退出（transmittance < 0.01），Shadow Ray 步数可调（默认 8 步）
- **[精度]** Mesh 内部 Ray March 方向基于 camera→surface 向量，可能在球体 Mesh 中心方向不精确 → **缓解**: 使用 `_RaymarchMaxDist` 控制深度，避免过度穿透
- **[噪声质量]** 128³ Perlin-Worley 在低频可能产生重复 → **缓解**: 可通过增大 `_NoiseFrequency` 缩放缓解
- **[移动端]** SM 4.0 要求 + 大量纹理采样 → **缓解**: 明确目标为桌面端，移动端需降级步数
