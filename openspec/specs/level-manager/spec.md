# level-manager Specification

## Purpose
TBD - created by archiving change add-multi-floor-map. Update Purpose after archive.
## Requirements
### Requirement: LevelManager manages multiple floor layers
The system SHALL provide a LevelManager class that manages multiple floor layers, each containing a ground TileMapLayer and an obstacle TileMapLayer.

#### Scenario: Get ground layer by level
- **WHEN** requesting ground layer for level 1
- **THEN** system returns Ground10 TileMapLayer

#### Scenario: Get obstacle layer by level
- **WHEN** requesting obstacle layer for level 2
- **THEN** system returns Ground21 TileMapLayer

#### Scenario: Get Y offset for level
- **WHEN** requesting Y offset for level 1
- **THEN** system returns 0

#### Scenario: Get Y offset for level 2
- **WHEN** requesting Y offset for level 2
- **THEN** system returns -32

### Requirement: LevelManager provides level enumeration
The system SHALL provide a method to get all available level numbers.

#### Scenario: Get all levels
- **WHEN** requesting all levels
- **THEN** system returns array [1, 2]

### Requirement: LevelManager provides max level
The system SHALL provide a method to get the maximum level number.

#### Scenario: Get max level
- **WHEN** requesting max level
- **THEN** system returns 2

