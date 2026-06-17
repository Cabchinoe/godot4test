# multi-floor-rendering Specification

## Purpose
TBD - created by archiving change add-multi-floor-map. Update Purpose after archive.
## Requirements
### Requirement: Player renders at correct Y offset per floor
The system SHALL render the player at the correct world position based on current floor level, applying Y offset.

#### Scenario: Player on floor 1
- **WHEN** player is at grid (5,3) on level 1
- **THEN** player world position uses Ground10 layer with Y offset 0

#### Scenario: Player on floor 2
- **WHEN** player is at grid (5,3) on level 2
- **THEN** player world position uses Ground20 layer with Y offset -32

### Requirement: Player tracks current floor level
The system SHALL store the player's current floor level as an integer.

#### Scenario: Player starts on floor 1
- **WHEN** player is initialized
- **THEN** current_level is 1

#### Scenario: Player goes upstairs
- **WHEN** player moves from (7,3,level=1) to (8,3,level=2)
- **THEN** current_level becomes 2

#### Scenario: Player goes downstairs
- **WHEN** player moves from (8,3,level=2) to (7,3,level=1)
- **THEN** current_level becomes 1

### Requirement: Player movement animation handles floor transitions
The system SHALL smoothly animate player position when transitioning between floors.

#### Scenario: Animate upstairs transition
- **WHEN** player moves from stairs tile to upper floor
- **THEN** player position updates with new level's Y offset

