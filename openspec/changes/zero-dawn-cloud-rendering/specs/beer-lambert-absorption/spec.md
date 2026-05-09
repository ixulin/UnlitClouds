## ADDED Requirements

### Requirement: Beer-Lambert exponential transmittance
The shader SHALL compute per-sample transmittance using Beer-Lambert law: `T = exp(-density * stepSize * extinction)`. The accumulated transmittance SHALL be multiplied across all ray march samples: `totalTransmittance *= T`.

#### Scenario: Light attenuation through cloud volume
- **WHEN** a ray march sample has density `d > 0` at position `p` with step size `s`
- **THEN** the sample's optical depth is `d * s * _Extinction` and the transmittance contribution is `exp(-opticalDepth)`

#### Scenario: Energy accumulation
- **WHEN** multiple samples with density > 0 are accumulated along the ray
- **THEN** scattered light at each sample is weighted by current transmittance: `scatteredLight += lighting * transmittance * (1.0 - exp(-opticalDepth))`, and transmittance decays: `transmittance *= exp(-opticalDepth)`

### Requirement: Configurable absorption coefficient
The shader SHALL expose `_Absorption` as a material property in Range(0.1, 10) with default 3.0. It controls the rate of exponential decay per unit optical depth.

#### Scenario: Parameter adjustment
- **WHEN** the user adjusts `_Absorption` in the material inspector
- **THEN** higher values produce darker, more opaque clouds; lower values produce more translucent clouds

### Requirement: Early ray termination
The ray march loop SHALL terminate early when accumulated transmittance drops below 0.01 to save computation.

#### Scenario: Thick cloud optimization
- **WHEN** transmittance reaches < 0.01 during ray march
- **THEN** the loop breaks and no further samples are processed
