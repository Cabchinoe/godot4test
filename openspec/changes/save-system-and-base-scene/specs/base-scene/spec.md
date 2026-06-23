## ADDED Requirements

### Requirement: 基地场景作为默认入口
Base.tscn SHALL 设为 project.godot 的 main_scene。游戏启动后直接进入基地场景。

#### Scenario: 游戏启动进入基地
- **WHEN** 运行项目
- **THEN** 加载 Base.tscn，显示基地场景

### Requirement: 基地场景地图与玩家
Base 场景 SHALL 包含与 main 相同的多层 TileMap 地图和玩家单位。LevelManager 初始化逻辑与 main 一致。

#### Scenario: 基地场景地图加载
- **WHEN** 进入基地场景
- **THEN** 显示 Ground10、Ground20 两层地图，玩家单位在初始位置

### Requirement: 基地场景自由移动
Base 场景 SHALL 支持玩家自由移动，AP 初始化为 50（等效无限）。寻路高亮 SHALL 正常工作。

#### Scenario: 基地中移动玩家
- **WHEN** 选中玩家，点击可达格子
- **THEN** 玩家沿路径移动，AP 扣除（因 AP=50 等效无限）

#### Scenario: 寻路高亮显示
- **WHEN** 选中玩家
- **THEN** 显示 BFS 可达范围高亮，鼠标悬停显示路径

### Requirement: 基地场景无回合控制
Base 场景 SHALL 不包含 TurnController。无回合 HUD、无结束回合按钮、无右键菜单。

#### Scenario: 无回合相关 UI
- **WHEN** 在基地场景
- **THEN** 不显示 AP/回合 HUD，无"结束回合"按钮

### Requirement: 基地场景功能入口
Base 场景 SHALL 提供以下按钮：存档、读档、进入战斗、返回主菜单。

#### Scenario: 进入战斗
- **WHEN** 点击"进入战斗"按钮
- **THEN** 切换到 main.tscn

#### Scenario: 返回主菜单
- **WHEN** 点击"返回主菜单"按钮
- **THEN** 切换到 MainMenu.tscn

#### Scenario: 打开存档 UI
- **WHEN** 点击"存档"或"读档"按钮
- **THEN** 显示存档/读档面板

### Requirement: 相机拖拽
Base 场景 SHALL 支持鼠标拖拽平移相机，逻辑与 main 一致。

#### Scenario: 拖拽移动相机
- **WHEN** 按住鼠标左键拖动
- **THEN** 相机跟随移动
