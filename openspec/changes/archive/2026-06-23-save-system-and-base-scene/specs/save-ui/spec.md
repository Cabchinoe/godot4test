## ADDED Requirements

### Requirement: 存档槽位列表显示
存档 UI SHALL 显示 10 个槽位，每个槽位展示：槽位编号、保存时间、游戏时长、摘要信息（如玩家等级）。空槽位 SHALL 显示"空槽位"。

#### Scenario: 显示混合槽位
- **WHEN** 打开存档 UI，slot 0 有存档，slot 1 为空
- **THEN** slot 0 显示保存时间和摘要，slot 1 显示"空槽位"

### Requirement: 保存操作
存档 UI SHALL 提供保存按钮。点击保存时 SHALL 将当前游戏数据写入选中的槽位，覆盖已有存档。保存前 SHALL 显示确认提示（若槽位非空）。

#### Scenario: 保存到空槽位
- **WHEN** 选中空槽位 2，点击"保存"
- **THEN** 数据写入 slot 2，UI 刷新显示新存档信息

#### Scenario: 覆盖已有存档
- **WHEN** 选中已有存档的槽位 0，点击"保存"
- **THEN** 弹出确认提示，确认后覆盖写入，UI 刷新

### Requirement: 读取操作
存档 UI SHALL 提供读取按钮。仅当槽位有存档时读取按钮可用。读取后 SHALL 关闭存档 UI。

#### Scenario: 读取已有存档
- **WHEN** 选中槽位 0（有存档），点击"读取"
- **THEN** 调用 SaveManager.load(0)，关闭存档 UI

#### Scenario: 空槽位读取不可用
- **WHEN** 选中空槽位 3
- **THEN** "读取"按钮禁用

### Requirement: 删除操作
存档 UI SHALL 提供删除按钮。仅当槽位有存档时删除按钮可用。删除前 SHALL 显示确认提示。

#### Scenario: 删除已有存档
- **WHEN** 选中槽位 1（有存档），点击"删除"
- **THEN** 弹出确认提示，确认后调用 SaveManager.delete_slot(1)，UI 刷新显示"空槽位"

### Requirement: 存档 UI 打开与关闭
存档 UI SHALL 默认隐藏，通过基地场景的按钮触发打开。关闭按钮或读取成功后 SHALL 关闭 UI。

#### Scenario: 打开存档 UI
- **WHEN** 在基地场景点击"存档"按钮
- **THEN** 存档面板显示，加载所有槽位信息

#### Scenario: 关闭存档 UI
- **WHEN** 点击"返回"按钮
- **THEN** 存档面板隐藏
