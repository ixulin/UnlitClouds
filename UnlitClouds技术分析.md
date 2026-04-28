# UnlitClouds 项目 — 主要算法与技术分析

## 项目概述

这是一个基于 Unity 的风格化云渲染项目，使用 **Amplify Shader Editor** 创建的自定义 Surface Shader 实现程序化云朵效果。整个项目**无任何 C# 脚本**，完全由 Shader 驱动。

**核心文件**: `Assets/__CLOUDS/Cloud_unlit_vertex_color.shader`（499行）

---

## 核心算法

### 1. 三层 3D Simplex Noise（程序化噪声变形）

**算法**: 标准 3D Simplex Noise（Ashima Arts 实现）

**三层噪声各自独立运行**:

| 层 | 噪声尺寸 | 强度 | 速度 | 方向 | 用途 |
|---|---|---|---|---|---|
| A（主层）| 0.8 | 0.472 | 0.5 | (1.5, 0, 0) | 大尺度云体变形 |
| B（中层）| 1.49 | 0.182 | 1.0 | (1.48, -0.86, -0.36) | 中等细节翻涌 |
| C（细节层）| 5.0 | 0.071 | 10.36 | (1, 0, 0) | 高频细节波动 |

**噪声计算公式**（以层A为例）:
```
noiseInput = DirectionA * (Time * SpeedA) + NoiseSizeA * (WorldPos * NoiseScaleA)
noiseValue = snoise(noiseInput)          // 范围 [-1, 1]
displacement = remap(noiseValue, -1~1 -> 0~1)
vertexOffset = WorldUp * displacement * NoiseStrengthA
```

三层噪声的位移沿**世界空间 Y 轴**叠加到顶点位置上，模拟云的垂直翻涌。

**对应代码位置**: shader 第194-208行 `vertexDataFunc()`

### 2. 距离自适应曲面细分（Distance-Based Tessellation）

**算法**: `UnityDistanceBasedTess()`
- 近距离细分数: **21.6**（最大）
- 最小距离: **0.7**（低于此距离获得最大细分）
- 最大距离: **10.94**（超过此距离无细分）

这确保了云朵近看时拥有足够的几何细节来表现噪声变形，远处则减少面数节省性能。

**对应代码位置**: shader 第189-192行 `tessFunction()`

### 3. 三平面纹理映射（Triplanar Mapping）

**函数**: `TriplanarSamplingSF()`（shader 第144-154行）

将噪声纹理沿 X/Y/Z 三个轴投影，根据世界法线方向加权混合:
```
weight = pow(abs(worldNormal), falloff)   // falloff 控制混合锐度
weight /= sum(weight) + 0.00001           // 归一化
result = texX * weight.x + texY * weight.y + texZ * weight.z
```

纹理坐标使用**噪声层C的输出**作为采样位置（`NoiseWorldPos`），使得纹理细节随云的动画一起流动。

### 4. Fresnel 边缘光（Rim Lighting）

**公式**: `Fresnel = base + scale * pow(1 - NdotV, power)`
- 参数: `(0.41, 1.0, 3.65)`（base, scale, power）
- Rim 颜色: 暗黄绿色 `(0.142, 0.142, 0.075)`

在云的边缘产生半透明发光效果，增强体积感和层次感。

**对应代码位置**: shader 第232-234行

### 5. Vertex Color 驱动的着色

云的基础颜色由模型顶点色（vertex color）驱动:
```
baseColor = pow(vertexColor, 0.4545) * VertexColorMult   // gamma 校正 + 乘数
```
顶点色经过 gamma 解码（0.4545 ≈ 1/2.2），然后与纹理色通过 `lerp` 混合，lerp 因子由三平面纹理、噪声A和2D噪声共同决定。

**对应代码位置**: shader 第231行

### 6. 2D Simplex Noise 细节调制

片段着色器中使用一个额外的 2D Simplex Noise，以世界空间 XZ 平面为输入，为 lerp 混合因子增加空间变化（范围 [0.25, 1.0]），避免纹理细节分布过于均匀。

**对应代码位置**: shader 第163-186行（2D snoise 定义），第229-230行（使用）

---

## 渲染管线

```
输入网格 (FBX, 带顶点色)
     │
     ▼
曲面细分 (距离自适应, tessFunction)
     │
     ▼
顶点着色器 (vertexDataFunc):
  三层 3D Simplex Noise 各自计算
  noiseInput = direction * (time * speed) + noiseSize * (worldPos * noiseScale)
  noiseValue = snoise(noiseInput) → remap [-1,1] → [0,1]
  顶点沿世界Y轴位移 += worldUp * noiseValue * noiseStrength（三层叠加）
     │
     ▼
片段着色器 (surf):
  1. 三平面纹理采样 (用噪声C坐标驱动, TriplanarSamplingSF)
  2. 顶点色 gamma 校正: pow(vertexColor, 0.4545) * VertexColorMult
  3. Lerp 混合: 顶点色 ↔ TextureColor
     - 混合因子 = (1 - triplanar) * textureDetail * saturate(noiseA) * remap(noise2D)
  4. Fresnel 边缘光叠加: color + fresnel * rimColor
  5. 输出自发光颜色 (Unlit, 无光照计算)
```

---

## Shader 参数速查表

| 参数 | 默认值 | 说明 |
|---|---|---|
| `_TessValue` | 21.6 | 最大曲面细分级别 |
| `_TessMin` | 0.7 | 最小细分距离 |
| `_TessMax` | 10.94 | 最大细分距离 |
| `_3dNoiseSizeA/B/C` | 0.8 / 1.49 / 5.0 | 噪声空间缩放 |
| `_NoiseScaleA/B/C` | (1,1,1) | 噪声 XYZ 轴缩放 |
| `_SpeedA/B/C` | 0.5 / 1.0 / 10.36 | 噪声动画速度 |
| `_DirectionA/B/C` | 各不相同 | 噪声流动方向 |
| `_NoiseStrengthA/B/C` | 0.472 / 0.182 / 0.071 | 顶点位移强度 |
| `_VertexColorMult` | 1.16 | 顶点色乘数 |
| `_TextureColor` | (0.509, 0.435, 0.505) | 纹理叠加色 |
| `_FresnelBSP` | (0.41, 1.0, 3.65) | Fresnel 参数 (base, scale, power) |
| `_RimColor` | (0.142, 0.142, 0.075) | 边缘光颜色 |
| `_Fallof` | 1.0 | 三平面混合锐度 |
| `_textureDetail` | 1.0 | 纹理细节强度 |
| `_Tiling` | (0.04, 0.04) | 纹理平铺 |

## 关键技术特点

| 技术 | 实现方式 |
|---|---|
| **渲染模式** | 完全 Unlit（自定义 LightingUnlit 返回0），通过自发光输出颜色 |
| **Shader Model** | 4.6（需要 DX11+ 硬件） |
| **动画** | 三层独立噪声以不同速度和方向运动，产生复杂翻涌效果 |
| **风格** | 非真实感渲染(NPR)，追求艺术化/风格化效果 |
| **性能优化** | 距离细分 + 无光照计算 + 高效噪声算法 |
| **后处理** | Bloom (0.85) + Color Grading (饱和度4) + AO (0.11) 增强氛围 |

## 辅助资源

- **Skybox Gradient Shader**: 简单的渐变天空盒，支持屏幕空间和世界空间模式
- **CloudNoise.jpg**: 用于三平面映射的噪声纹理
- **Clouds_Vcolor_v2.FBX**: 带顶点色的云朵基础几何体
