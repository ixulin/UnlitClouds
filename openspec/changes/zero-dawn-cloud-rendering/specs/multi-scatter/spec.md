## ADDED Requirements

### Requirement: Multi-scatter approximation
The shader SHALL approximate multiple scattering with: `multiScatter = exp(-opticalDepth * 0.25) * _MultiScatter`. This compensates for energy lost in single-scatter Beer-Lambert, brightening cloud interiors.

#### Scenario: Cloud bottom brightening
- **WHEN** a sample has high optical depth (deep cloud)
- **THEN** `exp(-opticalDepth * 0.25)` decays much slower than Beer-Lambert's `exp(-opticalDepth)`, providing residual brightness to prevent completely black cloud bottoms

#### Scenario: Energy conservation
- **WHEN** multi-scatter is added to the lighting equation
- **THEN** total scattered light at each sample includes: `(scatter + multiScatterContrib) * _LightMultiplier`, where multi-scatter contribution is: `directLight * multiScatter * 0.5`

### Requirement: Configurable multi-scatter strength
The shader SHALL expose `_MultiScatter` as a material property in Range(0, 1) with default 0.3. Setting to 0 disables multi-scatter.

#### Scenario: Disable multi-scatter
- **WHEN** `_MultiScatter` is set to 0
- **THEN** no multi-scatter contribution is added and only single-scatter Beer-Lambert + Powder is used
