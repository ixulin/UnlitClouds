## Why

当前项目基于 Mesh（FBX 模型 + 顶点色）实现云渲染，虽然已有基础的 Beer's Law 和 Powder Effect，但渲染效果距离 Horizon Zero Dawn（Decima 引擎）的真实感仍有较大差距。HZD 的云渲染核心技术包括：基于 Beer-Lambert 定律的体积吸收、Powder Effect（前向散射边缘增亮）、Dual-lobe Henyey-Greenstein 相位函数、多散射近似、以及精细的噪声密度模型。用户希望从零开始，逐步构建一套完整的 ZD 风格体积云渲染管线，不受已有实现约束。

## What Changes

- 创建全新的 Mesh 云 Shader（`CloudZD.shader`），采用从零设计的渲染管线
- 实现 Beer-Lambert 体积吸收模型（指数衰减透射率）
- 实现 Powder Effect（低密度区域前向散射增亮，模拟糖粉效果）
- 实现 Dual-lobe Henyey-Greenstein 相位函数（前向 + 后向散射混合）
- 实现多散射近似（Multi-scatter approximation，能量保守）
- 实现基于 3D 噪声的密度采样（Perlin-Worley + Worley FBM 侵蚀）
- 实现内部 Ray Marching（相机方向穿入云体）
- 实现朝日方向的短距 Shadow Ray Marching（自遮挡）
- 实现半球环境光（天空/地面）和 Fresnel 边缘光
- 实现蓝噪声抖动（消除 ray marching banding）
- 创建配套材质（`CloudZD.mat`）
- 保留 Shadow Caster Pass
- 添加调试可视化模式

## Capabilities

### New Capabilities
- `beer-lambert-absorption`: Beer-Lambert 指数衰减体积吸收，驱动云体内部的光线衰减和透射率计算
- `powder-effect`: Powder Effect 前向散射，使云边缘（低密度区）更亮，模拟糖粉/冰晶散射
- `phase-function`: Dual-lobe Henyey-Greenstein 相位函数，控制光线在云体中的散射方向分布
- `multi-scatter`: 多散射近似，补偿单次散射模型丢失的能量，使云底部不会过暗
- `density-sampling`: 基于 3D Perlin-Worley + Worley FBM 的密度采样管线，含高度梯度、Coverage 重映射、细节侵蚀
- `cloud-raymarching`: 内部 Ray Marching + 朝日 Shadow Ray Marching，蓝噪声抖动抗锯齿
- `cloud-ambient-rim`: 半球环境光（天空/地面混合）+ Fresnel 边缘光
- `cloud-debug`: 密度/透射率/光照分量调试可视化

### Modified Capabilities

（无已有 capability 需修改）

## Impact

- 新增文件：`Assets/__CLOUDS/CloudZD.shader`、`Assets/__CLOUDS/CloudZD.mat`
- 依赖已有资源：3D 噪声纹理（`PerlinWorley_128.asset`、`Worley_32.asset`）、蓝噪声纹理（需添加或使用 2D `_DitherNoise`）
- 依赖已有 FBX 网格和顶点色数据（`Clouds_Vcolor_v2.FBX`）
- URP 渲染管线，需 `#include` URP Shader Library
- Shader 编译目标 SM 4.0+（3D 纹理采样需求）
