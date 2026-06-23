## ADDED Requirements

### Requirement: 基地场景不使用 TurnController
基地场景 SHALL 不创建、不依赖 TurnController。基地场景中无回合概念，玩家可自由移动。TurnController 本身不做修改，仅基地场景不实例化它。

#### Scenario: 基地场景无回合控制
- **WHEN** 在基地场景
- **THEN** TurnController 不存在，无 `turn_started` 信号触发，无 `end_turn()` 调用

#### Scenario: 对局场景 TurnController 不变
- **WHEN** 在对局场景（main）
- **THEN** TurnController 正常工作，行为与之前完全一致
