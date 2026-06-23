## ADDED Requirements

### Requirement: 多槽位存档管理
SaveManager SHALL 支持 10 个存档槽位（slot 0-9）。每个槽位独立存储为一个 Resource 文件，路径为 `user://saves/slot_<id>/save.res`。SaveManager 作为 Autoload 全局存在。

#### Scenario: 保存到指定槽位
- **WHEN** 调用 `save(3)`
- **THEN** 在 `user://saves/slot_3/save.res` 写入当前游戏数据的 Resource 文件

#### Scenario: 从指定槽位读取
- **WHEN** 调用 `load(3)` 且该槽位存在存档
- **THEN** 返回该槽位的 SaveData Resource

#### Scenario: 读取不存在的槽位
- **WHEN** 调用 `load(5)` 且该槽位无存档
- **THEN** 返回 null，不报错

### Requirement: 删除槽位
SaveManager SHALL 提供 `delete_slot(slot_id)` 方法，删除指定槽位的整个目录。

#### Scenario: 删除已有存档
- **WHEN** 调用 `delete_slot(2)` 且 slot 2 存在存档
- **THEN** `user://saves/slot_2/` 目录及其内容被删除，`slot_exists(2)` 返回 false

#### Scenario: 删除不存在的槽位
- **WHEN** 调用 `delete_slot(7)` 且 slot 7 无存档
- **THEN** 不报错，静默返回

### Requirement: 槽位状态查询
SaveManager SHALL 提供 `list_slots()` 方法，返回 10 个 SlotInfo 对象，包含每个槽位的存在状态、保存时间、游戏时长、摘要信息。

#### Scenario: 查询所有槽位
- **WHEN** 调用 `list_slots()`，slot 0 有存档，其余为空
- **THEN** 返回 10 个 SlotInfo，slot 0 的 `exists = true`，其余 `exists = false`

#### Scenario: 槽位摘要信息
- **WHEN** slot 1 有存档，玩家等级 5
- **THEN** 对应 SlotInfo 的 `summary` 包含等级信息

### Requirement: Provider 注册机制
SaveManager SHALL 提供 `register_provider(provider: SaveProvider)` 方法。存档时遍历所有已注册 Provider 调用 `write_to(data)`，读档时遍历调用 `read_from(data)`。

#### Scenario: 注册 Provider 后存档
- **WHEN** 注册了 PlayerSaveProvider，调用 `save(0)`
- **THEN** PlayerSaveProvider.write_to(data) 被调用，data.player 被填充

#### Scenario: 注册 Provider 后读档
- **WHEN** 注册了 PlayerSaveProvider，调用 `load(0)`
- **THEN** PlayerSaveProvider.read_from(data) 被调用

#### Scenario: 多个 Provider 按注册顺序执行
- **WHEN** 注册了 ProviderA、ProviderB，调用 `save(0)`
- **THEN** ProviderA.write_to(data) 先执行，ProviderB.write_to(data) 后执行

### Requirement: 版本管理
SaveData SHALL 包含 `version` 字段。SaveManager 读档时 SHALL 检查版本号，若低于当前版本则调用 `_migrate()` 方法（当前为空实现，预留入口）。

#### Scenario: 读取当前版本存档
- **WHEN** 读取 version = CURRENT_VERSION 的存档
- **THEN** 直接返回数据，不触发迁移

#### Scenario: 读取旧版本存档
- **WHEN** 读取 version < CURRENT_VERSION 的存档
- **THEN** 调用 `_migrate(data)` 进行版本升级后返回
