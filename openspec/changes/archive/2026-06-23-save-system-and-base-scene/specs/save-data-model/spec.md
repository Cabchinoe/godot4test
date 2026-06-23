## ADDED Requirements

### Requirement: SaveData 顶层 Resource
SaveData SHALL 继承 Resource，包含版本号、槽位 ID、保存时间、游戏时长，以及各子系统的 SaveData 引用。

#### Scenario: 创建新 SaveData
- **WHEN** 实例化 SaveData
- **THEN** `version = 1`，`slot_id = 0`，`timestamp = ""`，`play_time = 0.0`，各子数据为 null

### Requirement: PlayerSaveData
PlayerSaveData SHALL 继承 Resource，包含玩家等级、属性等可序列化状态。不保存玩家在基地或对局中的位置（位置由场景初始化决定）。

#### Scenario: 保存玩家属性
- **WHEN** 玩家 level = 3，move_range = 5
- **THEN** PlayerSaveData 中 `level = 3`，`move_range = 5`

### Requirement: 预留子系统 SaveData
SaveData SHALL 预留 InventorySaveData、QuestSaveData、StorySaveData 的字段，当前为空 Resource 实现。

#### Scenario: 预留字段存在
- **WHEN** 实例化 SaveData
- **THEN** `inventory`、`quest`、`story` 字段存在，值为对应空 Resource 或 null

### Requirement: SaveProvider 基类
SaveProvider SHALL 继承 RefCounted，定义 `write_to(data: SaveData)` 和 `read_from(data: SaveData)` 虚方法，以及 `get_provider_name() -> String` 方法。

#### Scenario: 实现自定义 Provider
- **WHEN** 创建 PlayerSaveProvider 继承 SaveProvider
- **THEN** MUST 实现 `write_to`、`read_from`、`get_provider_name` 三个方法

### Requirement: SlotInfo 数据结构
SlotInfo SHALL 继承 RefCounted，包含 `slot_id: int`、`exists: bool`、`timestamp: String`、`play_time: float`、`summary: Dictionary`。

#### Scenario: 空槽位 SlotInfo
- **WHEN** 槽位 3 无存档
- **THEN** SlotInfo 为 `{ slot_id: 3, exists: false, timestamp: "", play_time: 0.0, summary: {} }`

#### Scenario: 有存档的 SlotInfo
- **WHEN** 槽位 0 有存档，保存时间 "2026-06-23 15:00"
- **THEN** SlotInfo 为 `{ slot_id: 0, exists: true, timestamp: "2026-06-23 15:00", play_time: 120.5, summary: { ... } }`
