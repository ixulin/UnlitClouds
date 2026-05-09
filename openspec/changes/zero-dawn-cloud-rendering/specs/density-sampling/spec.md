## ADDED Requirements

### Requirement: Height-based density gradient
The shader SHALL compute a height gradient: `heightGrad = smoothstep(0, 0.1, h) * (1 - smoothstep(cumulusTop, 1, h))`, where `h` is the normalized height within the cloud layer `[0,1]` and `cumulusTop = 0.3 + _CloudType * 0.65`.

#### Scenario: Cloud base transition
- **WHEN** a sample position is below `_CloudBaseY`
- **THEN** density returns 0 (below cloud layer)

#### Scenario: Cloud top falloff
- **WHEN** a sample position is above the cumulus top threshold
- **THEN** density smoothly falls to 0, creating the characteristic anvil shape

### Requirement: Perlin-Worley shape noise
The shader SHALL sample `_PerlinWorleyTex` 3D texture at `_NoiseFrequency`. R channel (Perlin) provides large-scale shape; GBA channels (Worley FBM) perturb the Perlin remap lower bound via: `cloudShape = Remap(perlin, -(1 - worleyFBM), 1, 0, 1)`.

#### Scenario: Large-scale cloud shape
- **WHEN** the Perlin noise value is high at a position
- **THEN** that position is more likely to be inside the cloud volume

### Requirement: Coverage remap
The shader SHALL remap cloud shape using coverage: `cloudShape = Remap(cloudShape, 1 - _Coverage, 1, 0, 1) * _Coverage`. Higher coverage fills more sky.

#### Scenario: Sparse clouds
- **WHEN** `_Coverage` is low (e.g., 0.3)
- **THEN** only positions with the highest noise values produce cloud density

### Requirement: Worley FBM detail erosion
The shader SHALL sample `_WorleyTex` at `_DetailFrequency` and compute erosion FBM: `erosionFBM = w.r * 0.625 + w.g * 0.25 + w.b * 0.125`. This erodes the cloud shape: `density = Remap(density, erosionFBM * _ErosionStrength * 0.5, 1, 0, 1)`.

#### Scenario: Fine detail on cloud edges
- **WHEN** `_ErosionStrength` is increased
- **THEN** cloud edges show more detailed, wispy erosion patterns

### Requirement: Vertex color density masking
The sampled density SHALL be multiplied by the mesh vertex color alpha channel: `finalDensity = sampledDensity * vertexColorAlpha`. This uses the mesh's baked density data to shape the cloud.

#### Scenario: Mesh-defined cloud boundary
- **WHEN** vertex color alpha is 0 at a fragment
- **THEN** the density is 0 regardless of noise values, keeping the cloud within the mesh shape
