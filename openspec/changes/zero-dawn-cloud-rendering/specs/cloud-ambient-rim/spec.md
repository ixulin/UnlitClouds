## ADDED Requirements

### Requirement: Hemisphere ambient lighting
The shader SHALL compute ambient lighting by blending sky and ground colors based on the surface normal's Y component: `ambientBlend = saturate(N.y * 0.5 + 0.5)`, then `ambient = lerp(_AmbientGroundColor, _AmbientSkyColor, ambientBlend)`.

#### Scenario: Cloud top ambient
- **WHEN** the surface normal points upward (N.y ≈ 1)
- **THEN** the ambient color is predominantly `_AmbientSkyColor` (bright, blue-tinted)

#### Scenario: Cloud bottom ambient
- **WHEN** the surface normal points downward (N.y ≈ -1)
- **THEN** the ambient color is predominantly `_AmbientGroundColor` (dim, warm-tinted)

### Requirement: Ambient strength control
The shader SHALL expose `_AmbientStrength` in Range(0, 2) with default 0.35. The ambient contribution is scaled by this value and inversely by local density: `ambientContrib = ambient * _AmbientStrength * max(1.0 - density * 0.5, 0.15)`.

#### Scenario: Density-modulated ambient
- **WHEN** a sample has high density
- **THEN** ambient contribution is reduced (dense regions block ambient light)

### Requirement: Fresnel rim lighting
The shader SHALL compute a Fresnel-based rim effect: `fresnel = _RimBase + _RimScale * pow(1.0 - abs(dot(N, V)), _RimPower)`. The rim contribution is `fresnel * _RimColor * 0.15`.

#### Scenario: Edge highlight
- **WHEN** the view direction is nearly perpendicular to the surface normal (grazing angle)
- **THEN** the Fresnel rim effect is strong, producing a bright edge highlight

### Requirement: Configurable ambient and rim parameters
The shader SHALL expose:
- `_AmbientSkyColor`: Color, default (0.6, 0.7, 0.9, 1)
- `_AmbientGroundColor`: Color, default (0.15, 0.12, 0.1, 1)
- `_AmbientStrength`: Range(0, 2), default 0.35
- `_RimColor`: Color, default (0.86, 0.86, 0.86, 1)
- `_RimBase`: Range(0, 1), default 0.41
- `_RimScale`: Range(0, 2), default 1.0
- `_RimPower`: Range(0.5, 8), default 3.65
