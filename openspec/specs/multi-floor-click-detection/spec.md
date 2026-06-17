# multi-floor-click-detection Specification

## Purpose
TBD - created by archiving change add-multi-floor-map. Update Purpose after archive.
## Requirements
### Requirement: Click detection supports multiple floors
The system SHALL detect clicks on all floor layers and select the target based on visual proximity.

#### Scenario: Click on floor 1 tile
- **WHEN** user clicks at screen position corresponding to floor 1 tile
- **THEN** system returns grid position and level 1

#### Scenario: Click on floor 2 tile
- **WHEN** user clicks at screen position corresponding to floor 2 tile
- **THEN** system returns grid position and level 2

### Requirement: Click detection selects visually closest floor
The system SHALL select the floor whose tile world position is visually closest to the mouse click position.

#### Scenario: Overlapping tiles selection
- **WHEN** user clicks at position where floor 1 and floor 2 tiles visually overlap
- **THEN** system selects the floor with smaller Y distance to click position

### Requirement: Click detection validates walkability
The system SHALL only return valid click targets that are walkable.

#### Scenario: Click on unwalkable tile
- **WHEN** user clicks on tile marked as unwalkable
- **THEN** system does not return that tile as valid target

### Requirement: Move range highlight supports multiple floors
The system SHALL display move range highlights on the correct floor based on reachable cells.

#### Scenario: Highlight reachable cells on floor 2
- **WHEN** player is on floor 2 and move range includes floor 2 cells
- **THEN** highlights appear on floor 2's HUD layer

