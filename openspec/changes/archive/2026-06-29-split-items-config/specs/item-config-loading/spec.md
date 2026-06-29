## ADDED Requirements

### Requirement: 物品配置按类型分文件存储

物品配置 SHALL 按 `type` 拆分存储于 `conf/items/` 目录，每个有效类型对应一个文件，文件名为类型键的小写形式（如 `WEAPON` → `weapon.json`）。每个文件内容 MUST 为该类型物品对象组成的 JSON 数组，且每条记录 MUST 保留 `type` 字段。

#### Scenario: 拆分后的目录结构
- **WHEN** 查看 `conf/items/` 目录
- **THEN** 存在与 `VALID_TYPES` 各键对应的小写命名文件（`weapon.json`、`ammo.json`、`helmet.json`、`armor.json`、`chestrig.json`、`backpack.json`、`material.json`、`collectible.json`、`consumable.json`、`weapon_attachment.json`）
- **AND** 每个文件根节点为 JSON 数组
- **AND** 数组内每条记录的 `type` 字段与其所属文件类型一致

#### Scenario: 原单文件被移除
- **WHEN** 拆分完成
- **THEN** 原 `conf/items.json` 不再存在

### Requirement: 按类型驱动加载并合并

`ItemDB` SHALL 遍历 `VALID_TYPES` 的每个键，加载 `conf/items/<type_lower>.json` 并将所有记录合并到统一物品表。合并后 `get_item`、`get_items_by_type`、`get_all_items` 的行为 MUST 与拆分前等价。

#### Scenario: 全部类型文件存在
- **WHEN** 启动时所有类型文件均存在且格式正确
- **THEN** 所有物品被加载到统一物品表
- **AND** `get_all_items()` 返回的物品总数与拆分前一致
- **AND** `get_items_by_type("WEAPON")` 返回所有武器类物品

#### Scenario: 某类型文件缺失
- **WHEN** 某个类型对应的 JSON 文件不存在（如 `weapon_attachment.json` 无内容未创建）
- **THEN** 该类型被跳过并打印告警
- **AND** 加载流程继续，不崩溃
- **AND** 其余类型物品正常加载

#### Scenario: 某类型文件解析失败
- **WHEN** 某个类型文件存在但 JSON 解析失败或根节点非数组
- **THEN** 打印该文件的错误信息并跳过该文件
- **AND** 其余类型物品正常加载

### Requirement: 启动期资源路径校验

系统 SHALL 在物品加载完成后校验所有物品的 `icon` 路径，确认对应资源文件真实存在。校验失败 MUST 打印缺失资源清单以便早暴露，但不阻断启动。

#### Scenario: 所有图标资源存在
- **WHEN** 加载完成且所有 `icon` 路径对应文件均存在
- **THEN** 校验通过，无缺失告警

#### Scenario: 存在缺失图标
- **WHEN** 某物品的 `icon` 路径对应文件不存在
- **THEN** 打印包含物品 id 与缺失路径的清单
- **AND** 启动流程继续

### Requirement: 跨平台路径约定

项目资源路径 SHALL 遵循跨平台约定以保证在 mac、windows 及大小写敏感的导出/CI 环境下一致工作。

#### Scenario: 仅使用虚拟路径
- **WHEN** 代码引用配置或资源
- **THEN** 路径使用 `res://` 或 `user://` 前缀，不使用操作系统绝对路径

#### Scenario: 分隔符与大小写规范
- **WHEN** 编写或拼接资源路径
- **THEN** 路径分隔符统一使用 `/`
- **AND** 配置目录与文件名使用小写规范
- **AND** 路径大小写与磁盘上真实文件名精确匹配
