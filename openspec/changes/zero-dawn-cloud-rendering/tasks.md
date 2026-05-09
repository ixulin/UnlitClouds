## 1. 基础渲染

- [x] 1.1 创建 `CloudZD.shader`：顶点色 + 简单方向光 + ambient，能正常渲染云 Mesh

## 2. 深度图方案

- [ ] 2.1 实现 Camera Front Face Depth Pass（Cull Back，输出线性深度到 `_CameraFrontDepth`）
- [ ] 2.2 实现 Camera Back Face Depth Pass（Cull Front，输出线性深度到 `_CameraBackDepth`）
- [ ] 2.3 实现 Sun Front Face Depth Pass（从灯光方向渲染，输出线性深度到 `_SunFrontDepth`）
- [ ] 2.4 实现 Sun Back Face Depth Pass（从灯光方向 Cull Front，输出线性深度到 `_SunBackDepth`）

## 3. 深度驱动的主渲染 Pass

- [ ] 3.1 在主 Fragment Shader 中采样四张深度图，计算 view thickness 和 sun thickness
- [ ] 3.2 用 thickness 计算 Beer-Lambert 透射率和 sun occlusion，替代 ray march
- [ ] 3.3 实现 Powder Effect（基于 sun thickness）和 Multi-Scatter 近似

## 4. 相位函数 + 环境光

- [ ] 4.1 实现 Dual-lobe Henyey-Greenstein 相位函数
- [ ] 4.2 实现半球环境光（天空/地面混合）+ Fresnel Rim

## 5. Shadow Caster + 调试

- [ ] 5.1 实现 Shadow Caster Pass
- [ ] 5.2 实现调试可视化（Depth / Thickness / Transmittance 模式）

## 6. 验证

- [ ] 6.1 创建 CloudZD.mat 材质，在 CloudScene 中验证
