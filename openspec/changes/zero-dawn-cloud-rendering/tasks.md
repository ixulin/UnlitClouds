## 1. 基础渲染

- [x] 1.1 创建 `CloudZD.shader`：顶点色 + 简单方向光 + ambient，能正常渲染云 Mesh

## 2. Ray Marching + 简单密度

- [x] 2.1 添加 Ray March 主循环（从表面沿相机方向穿入 mesh），密度 = 常量（mesh 内实心）
- [x] 2.2 添加 Beer-Lambert 透射率衰减和散射光累积，最终颜色合成

## 3. Beer-Lambert 完善 + Powder Effect

- [ ] 3.1 实现 `SampleSunOcclusion()` 朝日 shadow ray
- [ ] 3.2 实现 Powder Effect（`powder = 1 - exp(-opticalDepth * 2)`，与 Beer 取 max）
- [ ] 3.3 实现 Multi-Scatter 近似（`exp(-opticalDepth * 0.25)`）

## 4. 相位函数 + 环境光

- [ ] 4.1 实现 Dual-lobe Henyey-Greenstein 相位函数
- [ ] 4.2 实现半球环境光（天空/地面混合）+ Fresnel Rim

## 5. Shadow Caster + 调试

- [ ] 5.1 实现 Shadow Caster Pass
- [ ] 5.2 实现调试可视化（Density / Transmittance 模式）

## 6. 验证

- [ ] 6.1 创建 CloudZD.mat 材质，在 CloudScene 中验证
