## ADDED Requirements

### Requirement: Beer-Lambert from depth-derived thickness
The shader SHALL compute transmittance using Beer-Lambert law based on depth-derived thickness: `T = exp(-thickness * density * absorption)`. Thickness comes from front/back face depth pairs, not ray marching.

#### Scenario: View-direction attenuation
- **WHEN** the camera-view thickness `viewThickness` is computed from depth textures
- **THEN** view transmittance is `exp(-viewThickness * _Density * _Absorption)`, making thicker cloud regions more opaque

#### Scenario: Sun-direction attenuation (self-shadowing)
- **WHEN** the sun-view thickness `sunThickness` is computed from depth textures
- **THEN** sun occlusion is `exp(-sunThickness * _Density * _Absorption)`, making regions with more cloud between them and the sun darker

### Requirement: Configurable absorption coefficient
The shader SHALL expose `_Absorption` as a material property in Range(0.1, 10) with default 3.0. It controls the rate of exponential decay per unit thickness.

#### Scenario: Parameter adjustment
- **WHEN** the user adjusts `_Absorption` in the material inspector
- **THEN** higher values produce darker, more opaque clouds; lower values produce more translucent clouds
