## ADDED Requirements

### Requirement: Powder effect computation
The shader SHALL compute powder effect as `powder = 1.0 - exp(-opticalDepth * 2.0)`. This brightens regions with low optical depth (cloud edges), simulating forward scattering off small ice crystals.

#### Scenario: Edge brightening
- **WHEN** a ray march sample has low optical depth (near cloud edge)
- **THEN** powder value is high (approaching 1.0), contributing additional brightness

#### Scenario: Interior darkening
- **WHEN** a ray march sample has high optical depth (deep inside cloud)
- **THEN** powder value is low (approaching 0.0), not adding extra brightness

### Requirement: Beer-Powder combination
The shader SHALL combine Beer's Law and Powder Effect using: `beersPowder = max(beersLaw, powder * _PowderEffect)`. This ensures the brighter of the two effects dominates.

#### Scenario: Balanced rendering
- **WHEN** both Beer's Law and Powder Effect are computed at a sample point
- **THEN** the combined result takes the maximum, preserving Beer-Lambert absorption in dense regions and Powder brightening at edges

### Requirement: Configurable powder strength
The shader SHALL expose `_PowderEffect` as a material property in Range(0, 2) with default 1.0. Setting to 0 disables the powder effect entirely.

#### Scenario: Disable powder effect
- **WHEN** `_PowderEffect` is set to 0
- **THEN** the powder contribution is zero and only Beer-Lambert absorption is used
