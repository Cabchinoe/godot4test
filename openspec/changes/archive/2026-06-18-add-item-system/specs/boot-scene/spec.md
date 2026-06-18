## ADDED Requirements

### Requirement: Boot scene as game entry point
系统 SHALL 提供 Boot.tscn 作为游戏启动第一个场景。project.godot 的 run/main_scene MUST 设置为 Boot.tscn。Boot 场景负责加载配置后跳转主菜单。

#### Scenario: 游戏启动进入 Boot 场景
- **WHEN** 游戏启动
- **THEN** 进入 Boot.tscn

#### Scenario: Boot 场景加载配置
- **WHEN** Boot 场景 _ready() 执行
- **THEN** 调用 ItemDB.load_from_file("res://Data/items.json")

#### Scenario: 配置加载完成后跳转
- **WHEN** 配置加载完成
- **THEN** 调用 change_scene_to_file("res://MainMenu.tscn")

### Requirement: MainMenu scene with start button
系统 SHALL 提供 MainMenu.tscn 简单主菜单场景，包含"开始游戏"按钮。点击后进入 main.tscn。

#### Scenario: 主菜单显示
- **WHEN** 从 Boot 场景跳转
- **THEN** 显示主菜单界面，包含"开始游戏"按钮

#### Scenario: 点击开始游戏
- **WHEN** 用户点击"开始游戏"按钮
- **THEN** 调用 change_scene_to_file("res://main.tscn")

### Requirement: project.godot configuration
project.godot SHALL 配置正确的启动流程和 Autoload。

#### Scenario: main_scene 设置
- **WHEN** 查看 project.godot
- **THEN** run/main_scene 为 Boot.tscn 的 uid

#### Scenario: ItemDB Autoload 注册
- **WHEN** 查看 project.godot
- **THEN** [autoload] 段包含 ItemDB=*res://Script/item_db.gd
