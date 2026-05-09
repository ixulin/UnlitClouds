## ADDED Requirements

### Requirement: Debug view mode selector
The shader SHALL expose `_DebugView` as a keyword enum material property with three modes: Normal (0), Density (1), Transmittance (2). The default is Normal (0).

#### Scenario: Normal rendering
- **WHEN** `_DebugView` is 0
- **THEN** the shader renders with full lighting, Beer-Lambert, Powder, phase function, etc.

### Requirement: Density visualization mode
The shader SHALL provide a density-only debug mode that accumulates raw density along the ray march and displays it as a grayscale value: `densityVis = saturate(totalDensity * 0.3)`.

#### Scenario: Inspect density distribution
- **WHEN** `_DebugView` is set to 1 (Density)
- **THEN** the fragment output shows accumulated density as a grayscale heatmap, ignoring all lighting

### Requirement: Transmittance visualization mode
The shader SHALL provide a transmittance-only debug mode that computes pure Beer-Lambert transmittance (no lighting) and displays it as grayscale.

#### Scenario: Inspect light penetration
- **WHEN** `_DebugView` is set to 2 (Transmittance)
- **THEN** the fragment output shows how much light penetrates the cloud (white = full, black = opaque), with alpha = `1 - transmittance`
