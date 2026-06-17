## ADDED Requirements

### Requirement: Pathfinder supports multi-floor search
The system SHALL support pathfinding in (grid, level) space, where each path node contains both grid position and floor level.

#### Scenario: Find path on same floor
- **WHEN** finding path from (5,3,level=1) to (9,3,level=1)
- **THEN** system returns path with all nodes at level 1

#### Scenario: Find path across floors
- **WHEN** finding path from (5,3,level=1) to (9,3,level=2)
- **THEN** system returns path that includes level transition via stairs

### Requirement: Stairs enable floor transitions
The system SHALL allow pathfinding to transition between floors via stairs tiles marked with `is_stairs` custom data.

#### Scenario: Go upstairs from stairs tile
- **WHEN** current node is stairs tile at (7,3,level=1)
- **THEN** neighbors include walkable tiles at level 2 around (7,3)

#### Scenario: Go downstairs to stairs tile
- **WHEN** current node is at (8,3,level=2)
- **THEN** neighbors include (7,3,level=1) if it is stairs tile

### Requirement: Stairs cost one step
The system SHALL count floor transitions via stairs as one step in pathfinding.

#### Scenario: Stairs transition cost
- **WHEN** path includes stairs transition from (7,3,level=1) to (8,3,level=2)
- **THEN** transition counts as 1 step in max_steps calculation

### Requirement: BFS respects max_steps across floors
The system SHALL count steps correctly when searching across multiple floors.

#### Scenario: BFS with max_steps=5 across floors
- **WHEN** BFS starts at (5,3,level=1) with max_steps=5
- **THEN** reachable cells include cells up to 5 steps away, including floor transitions
