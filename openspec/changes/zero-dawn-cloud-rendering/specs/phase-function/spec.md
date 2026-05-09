## ADDED Requirements

### Requirement: Dual-lobe Henyey-Greenstein phase function
The shader SHALL compute a dual-lobe HG phase function: `phase = lerp(HG(g1, cosTheta), HG(g2, cosTheta), blend)`, where `cosTheta = dot(lightDir, viewDir)`.

#### Scenario: Forward scattering
- **WHEN** the view direction is roughly aligned with the light direction (cosTheta ≈ 1)
- **THEN** the forward lobe (g1 ≈ 0.8) produces a strong bright silver lining effect

#### Scenario: Backward scattering
- **WHEN** the view direction opposes the light direction (cosTheta ≈ -1)
- **THEN** the backward lobe (g2 ≈ -0.5) produces moderate back-scattering, preventing the dark side from being completely dark

### Requirement: HG phase function formula
Each lobe SHALL use the standard Henyey-Greenstein formula: `(1 - g²) / (4π * (1 + g² - 2g·cosθ)^1.5)`. The denominator SHALL be clamped to avoid division by zero.

#### Scenario: Isotropic fallback
- **WHEN** g = 0
- **THEN** the phase function returns `1 / (4π)` (uniform scattering)

### Requirement: Configurable phase parameters
The shader SHALL expose three material properties:
- `_PhaseG1`: Range(-0.99, 0.99), default 0.8 — forward scattering lobe eccentricity
- `_PhaseG2`: Range(-0.99, 0.99), default -0.5 — backward scattering lobe eccentricity
- `_PhaseBlend`: Range(0, 1), default 0.2 — blend factor between lobes (0 = full forward, 1 = full backward)

#### Scenario: Silver lining tuning
- **WHEN** `_PhaseG1` is increased toward 0.99
- **THEN** the silver lining effect becomes more concentrated and intense around the sun direction
