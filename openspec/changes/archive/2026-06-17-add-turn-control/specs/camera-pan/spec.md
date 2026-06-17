## ADDED Requirements

### Requirement: Camera2D 节点
场景 SHALL 包含 Camera2D 节点作为地图视口控制器。所有地图内容（TileMap 层、单位）为 Camera2D 的子节点或受其影响。

#### Scenario: 场景包含 Camera2D
- **WHEN** 场景加载完成
- **THEN** 存在 Camera2D 节点，控制地图视口位置

### Requirement: 左键拖拽平移
左键按下并拖动时 SHALL 平移 Camera2D，使地图跟随鼠标移动。拖拽方向与鼠标移动方向一致（鼠标往右拖 → 地图往右移）。

#### Scenario: 向右拖拽地图
- **WHEN** 鼠标向右移动 50px（超过拖拽阈值）
- **THEN** Camera2D.position.x 相应左移，地图视觉上向右跟随

#### Scenario: 拖拽平滑跟随
- **WHEN** 持续拖拽鼠标
- **THEN** 地图每帧跟随鼠标位置，无延迟感

### Requirement: 点击与拖拽阈值区分
系统 SHALL 使用 5px 拖拽阈值区分点击和拖拽。左键按下后鼠标移动距离未超过阈值时视为点击（触发选中/移动逻辑），超过阈值时视为拖拽（触发地图平移）。

#### Scenario: 短距离移动视为点击
- **WHEN** 左键按下，鼠标移动 3px 后释放
- **THEN** 触发点击逻辑（选中 unit 或移动），不触发地图平移

#### Scenario: 长距离移动视为拖拽
- **WHEN** 左键按下，鼠标移动 10px 后释放
- **THEN** 触发地图平移，不触发点击逻辑

### Requirement: 拖拽状态追踪
系统 SHALL 追踪拖拽状态：`is_dragging`（是否正在拖拽）、`press_pos`（按下位置）、`last_mouse_pos`（上一帧鼠标位置）。释放时根据 `is_dragging` 决定是否触发点击。

#### Scenario: 拖拽中不触发点击
- **WHEN** `is_dragging = true`，释放左键
- **THEN** 不执行任何选中或移动操作，`is_dragging` 重置为 false
