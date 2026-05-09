## ADDED Requirements

### Requirement: Camera-view front face depth texture
The shader system SHALL render the cloud mesh's front face (Cull Back) depth into a depth texture `_CameraFrontDepth` from the camera's perspective. This texture captures the nearest cloud surface distance per pixel.

#### Scenario: Front face depth capture
- **WHEN** the depth pre-pass executes with Cull Back from camera
- **THEN** each pixel stores the linear depth of the closest cloud surface facing the camera

### Requirement: Camera-view back face depth texture
The shader system SHALL render the cloud mesh's back face (Cull Front) depth into a depth texture `_CameraBackDepth` from the camera's perspective. This captures the farthest cloud surface distance per pixel.

#### Scenario: Back face depth capture
- **WHEN** the depth pre-pass executes with Cull Front from camera
- **THEN** each pixel stores the linear depth of the farthest cloud surface

### Requirement: Sun-view front face depth texture
The shader system SHALL render the cloud mesh's front face depth into `_SunFrontDepth` from the main light's perspective. This is used to determine sun-side cloud boundary.

#### Scenario: Sun front face depth
- **WHEN** the depth pre-pass executes from the light direction
- **THEN** each pixel stores the nearest cloud surface depth as seen from the sun

### Requirement: Sun-view back face depth texture
The shader system SHALL render the cloud mesh's back face depth into `_SunBackDepth` from the main light's perspective.

#### Scenario: Sun back face depth
- **WHEN** the depth pre-pass executes from the light direction with Cull Front
- **THEN** each pixel stores the farthest cloud surface depth as seen from the sun

### Requirement: Depth-based inside-cloud detection
The main lighting shader SHALL determine if the current fragment's world position is inside the cloud by comparing its depth against the front/back face depth pair from both camera and sun views. A point is inside the cloud if its depth falls between front and back face depths.

#### Scenario: Inside cloud volume
- **WHEN** the fragment's linear depth from camera is between `_CameraFrontDepth` and `_CameraBackDepth`
- **THEN** the fragment is inside the cloud volume and density > 0

#### Scenario: Outside cloud volume
- **WHEN** the fragment's linear depth is outside the front/back depth range
- **THEN** density = 0 (not inside cloud)

### Requirement: Depth-derived thickness for Beer-Lambert
The shader SHALL compute cloud thickness as `thickness = backDepth - frontDepth` for both camera view and sun view. Camera thickness drives view-direction transmittance; sun thickness drives self-shadowing.

#### Scenario: Camera thickness
- **WHEN** the main shader computes view-direction thickness
- **THEN** `viewThickness = _CameraBackDepth - _CameraFrontDepth` gives the total cloud depth along the view ray

#### Scenario: Sun thickness (self-shadowing)
- **WHEN** computing sun occlusion at a point
- **THEN** `sunThickness = _SunBackDepth - _SunFrontDepth` gives the cloud depth along the sun ray, driving Beer-Lambert shadow attenuation
