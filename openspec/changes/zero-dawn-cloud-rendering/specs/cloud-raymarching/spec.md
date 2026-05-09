## ADDED Requirements

### Requirement: Interior ray marching
The shader SHALL perform ray marching from the mesh surface inward along the camera→surface direction. The ray starts at `surfacePos + rayDir * 0.05` (slight offset to avoid self-intersection) and advances by `stepSize = _RaymarchMaxDist / _InteriorSteps` for up to `_InteriorSteps` iterations.

#### Scenario: Ray traversal through cloud
- **WHEN** the fragment shader executes on a cloud surface pixel
- **THEN** a ray is cast from just inside the surface, stepping deeper into the mesh, accumulating scattered light and reducing transmittance at each density sample

#### Scenario: Configurable step count
- **WHEN** `_InteriorSteps` is set higher (e.g., 64-128)
- **THEN** the ray march produces smoother, more detailed density transitions but at higher GPU cost

### Requirement: Shadow ray marching toward sun
At each density sample during the interior ray march, the shader SHALL cast a short shadow ray toward the main light direction. This ray samples `_ShadowSteps` steps over `_ShadowMaxDist`, accumulating occlusion: `occlusion *= exp(-density * stepSize * _Extinction * 2.0)`.

#### Scenario: Self-shadowing
- **WHEN** a cloud sample has dense cloud material between it and the sun
- **THEN** the shadow ray detects this and reduces sun occlusion, making the sample darker

#### Scenario: Shadow ray early exit
- **WHEN** accumulated occlusion drops below 0.01 during shadow ray march
- **THEN** the shadow loop breaks early

### Requirement: Blue noise dithering
The shader SHALL use a 2D blue noise texture (`_DitherNoise`) to jitter the ray march start position: `jitter = ditherValue * stepSize`. The dither is sampled at `screenUV * 4.0` for appropriate tiling.

#### Scenario: Banding artifact removal
- **WHEN** a ray march with fixed step size would produce visible banding in density transitions
- **THEN** the blue noise jitter smooths these bands into imperceptible noise

### Requirement: Configurable ray march parameters
The shader SHALL expose:
- `_InteriorSteps`: Range(2, 128), default 48
- `_RaymarchMaxDist`: Float, default 20
- `_Extinction`: Range(0.1, 5), default 0.5
- `_ShadowSteps`: Range(1, 32), default 8
- `_ShadowMaxDist`: Float, default 15

#### Scenario: Performance tuning
- **WHEN** `_InteriorSteps` is reduced to 16 and `_ShadowSteps` to 3
- **THEN** rendering is faster but cloud interior detail is coarser
