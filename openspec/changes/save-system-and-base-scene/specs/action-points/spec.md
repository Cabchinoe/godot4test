## ADDED Requirements

### Requirement: 基地场景 AP 初始化
在基地场景中，Unit 初始化时 action_points SHALL 设为 50（等效无限），而非 move_range 值。此行为仅影响基地场景，对局场景（main）行为不变。

#### Scenario: 基地场景 AP 初始化
- **WHEN** 基地场景中 Unit 以 move_range = 5 初始化，AP 参数为 50
- **THEN** `action_points = 50`

#### Scenario: 对局场景 AP 初始化不变
- **WHEN** 对局场景中 Unit 以 move_range = 5 初始化
- **THEN** `action_points = 5`（等于 move_range）
