# 团队协作工作流程

## 🎯 角色分工

### 项目负责人（你）
- ✅ 维护核心架构（core/）
- ✅ 审查模块设计
- ✅ 管理项目结构
- ✅ 协调团队成员

### 模块开发者
- 在各自模块文件夹内独立开发
- 遵循模块接口规范
- 使用事件总线通信
- 创建测试场景验证功能

### 资源管理者
- 管理 assets/ 文件夹
- 管理 data/ 配置文件
- 确保资源命名规范
- 优化资源文件大小

## 📝 开发流程

### 1. 开始新功能

```bash
# 1. 从主分支创建功能分支
git checkout main
git pull origin main
git checkout -b feature/your-feature-name

# 2. 创建模块文件夹
mkdir -p modules/your_module/{scenes,scripts,resources}

# 3. 开始开发
```

### 2. 模块开发规范

#### 文件组织
```
modules/your_module/
├── YourModule.gd           # 模块主文件
├── scenes/                 # 场景文件
│   ├── main_scene.tscn
│   └── sub_scene.tscn
├── scripts/                # 脚本文件
│   ├── component_a.gd
│   └── component_b.gd
└── resources/              # 资源文件
	├── sprites/
	├── audio/
	└── data/
```

#### 模块模板
```gdscript
extends Node
## [模块名称]
## [功能描述]

# ========== 配置 ==========
const CONFIG_PATH = "res://data/configs/your_module_config.tres"

# ========== 状态 ==========
var _is_initialized: bool = false
var _is_running: bool = false

# ========== 生命周期 ==========

func initialize() -> void:
	"""初始化模块"""
	if _is_initialized:
		return
	
	_load_config()
	_setup_components()
	_subscribe_events()
	
	_is_initialized = true
	print("[YourModule] 初始化完成")

func start() -> void:
	"""启动模块"""
	if not _is_initialized:
		push_error("[YourModule] 未初始化")
		return
	
	_is_running = true
	print("[YourModule] 启动")

func stop() -> void:
	"""停止模块"""
	_is_running = false
	print("[YourModule] 停止")

func cleanup() -> void:
	"""清理模块"""
	_unsubscribe_events()
	_is_initialized = false
	print("[YourModule] 清理完成")

# ========== 私有方法 ==========

func _load_config() -> void:
	# 加载配置
	pass

func _setup_components() -> void:
	# 设置组件
	pass

func _subscribe_events() -> void:
	# 订阅事件
	# EventBus.listen("event_name", self, "_on_event")
	pass

func _unsubscribe_events() -> void:
	# 取消订阅
	# EventBus.unlisten("event_name", self)
	pass

# ========== 公共接口 ==========

func your_public_method() -> void:
	"""对外提供的方法"""
	if not _is_running:
		return
	
	# 实现逻辑
	pass

# ========== 事件处理 ==========

func _on_event(data) -> void:
	"""事件回调"""
	pass
```

### 3. 事件通信规范

#### 事件命名规范
```
模块名:动作_对象
```

示例：
- `card:drawn` - 卡牌被抽取
- `rhythm:beat_hit` - 节奏命中
- `combat:damage_dealt` - 造成伤害
- `ui:button_clicked` - 按钮点击

#### 发送事件
```gdscript
# 简单事件
EventBus.fire("card:drawn")

# 带数据的事件
EventBus.fire("card:played", {
	"card_id": "attack_01",
	"player_id": 1,
	"target_id": 2
})
```

#### 监听事件
```gdscript
func initialize() -> void:
	EventBus.listen("card:played", self, "_on_card_played")

func _on_card_played(data) -> void:
	var card_id = data.card_id
	var player_id = data.player_id
	# 处理逻辑
```

### 4. 测试场景创建

每个模块都应该有独立的测试场景：

```
scenes/test_scenes/test_your_module.tscn
```

测试场景脚本模板：
```gdscript
extends Node
## [模块名称]测试场景

@onready var module = GameCore.get_module("YourModule")

func _ready() -> void:
	print("=== 测试 YourModule ===")
	_test_basic_functionality()
	_test_events()

func _test_basic_functionality() -> void:
	print("测试基础功能...")
	# 测试代码
	print("✓ 基础功能正常")

func _test_events() -> void:
	print("测试事件通信...")
	EventBus.listen("your_module:test_event", self, "_on_test_event")
	EventBus.fire("your_module:test_event", "test_data")

func _on_test_event(data) -> void:
	print("✓ 事件接收成功: ", data)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		print("手动触发测试...")
		module.your_public_method()
```

### 5. 提交代码

```bash
# 1. 检查修改
git status

# 2. 添加文件
git add modules/your_module/

# 3. 提交（使用规范的提交信息）
git commit -m "feat: 实现 YourModule 基础功能"

# 4. 推送到远程
git push origin feature/your-feature-name

# 5. 创建 Pull Request
```

#### 提交信息规范
```
类型: 简短描述

详细描述（可选）

类型：
- feat: 新功能
- fix: 修复bug
- docs: 文档更新
- style: 代码格式调整
- refactor: 重构
- test: 测试相关
- chore: 构建/工具相关
```

示例：
```
feat: 实现卡牌抽取和打出功能

- 添加卡组管理
- 实现手牌系统
- 添加卡牌事件
```
```

## 🤝 协作规范

### 1. 模块独立性原则

**✅ 推荐做法**：
```gdscript
# 通过事件总线通信
EventBus.fire("card:played", card_data)
```

**❌ 避免做法**：
```gdscript
# 直接调用其他模块
var combat_module = GameCore.get_module("Combat")
combat_module.apply_damage(10)  # 强耦合！
```

### 2. 资源管理规范

#### 模块内资源
放在模块文件夹内：
```
modules/card/resources/
├── sprites/
│   ├── card_back.png
│   └── card_frame.png
└── data/
	└── card_templates.tres
```

#### 共享资源
放在 assets/ 文件夹：
```
assets/
├── fonts/
│   └── main_font.ttf
├── audio/
│   └── music/
└── shaders/
	└── outline.gdshader
```

### 3. 数据配置规范

#### 模块配置
```
data/configs/
├── card_config.tres
├── rhythm_config.tres
└── combat_config.tres
```

#### 游戏数据
```
data/
├── cards/
│   ├── card_database.tres
│   └── cards/
│       ├── attack_01.tres
│       └── defense_01.tres
└── levels/
	├── level_01.tres
	└── level_02.tres
```

## 🐛 调试技巧

### 1. 使用调试打印
```gdscript
func _debug_print(message: String) -> void:
	if OS.is_debug_build():
		print("[YourModule] ", message)

# 使用
_debug_print("卡牌已抽取: " + card_id)
```

### 2. 测试场景快速迭代
```gdscript
# 在测试场景中添加快捷键
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select"):  # Space
		_test_basic_functionality()
	
	if event.is_action_pressed("ui_cancel"):  # Esc
		get_tree().reload_current_scene()
```

### 3. 事件调试
```gdscript
# 在 EventBus.gd 中添加调试模式
const DEBUG_EVENTS = true

func fire(event_name: String, data = null) -> void:
	if DEBUG_EVENTS:
		print("[EventBus] 发送事件: %s, 数据: %s" % [event_name, str(data)])
	
	# 原有逻辑...
```

## 📊 代码审查清单

提交 Pull Request 前检查：

### 功能完整性
- [ ] 模块实现了所有必需的接口方法
- [ ] 公共方法都有文档注释
- [ ] 添加了必要的错误处理

### 代码质量
- [ ] 遵循命名规范（snake_case）
- [ ] 没有硬编码的魔法数字
- [ ] 代码有适当的注释
- [ ] 没有调试用的 print 语句（除非在 DEBUG 模式下）

### 架构规范
- [ ] 使用事件总线进行模块间通信
- [ ] 没有直接引用其他模块
- [ ] 资源文件放在正确的位置
- [ ] 更新了事件文档（如果添加了新事件）

### 测试验证
- [ ] 创建了测试场景
- [ ] 测试场景可以正常运行
- [ ] 基础功能已验证
- [ ] 事件通信已验证

## 🚨 常见问题

### Q1: 如何访问其他模块的功能？

**A**: 通过事件总线通信，不要直接调用。

```gdscript
# ❌ 错误做法
var card_module = GameCore.get_module("Card")
card_module.draw_card()

# ✅ 正确做法
EventBus.fire("card:request_draw")
```

### Q2: 模块初始化顺序重要吗？

**A**: 不重要。使用事件总线通信可以避免初始化顺序依赖。

### Q3: 如何在模块间共享数据？

**A**: 通过事件传递数据，或使用共享的 Resource 数据文件。

```gdscript
# 方式1: 事件传递
EventBus.fire("data:updated", {
	"score": 100,
	"level": 5
})

# 方式2: 共享 Resource
var game_data = load("res://data/configs/game_data.tres")
```

### Q4: 如何处理模块间的复杂交互？

**A**: 创建专门的协调模块（如 GameFlowModule）来处理复杂流程。

## 📚 参考资源

- [项目结构文档](PROJECT_STRUCTURE.md)
- [事件列表](docs/EVENTS.md)
- [API 文档](docs/API.md)
- [Godot 官方最佳实践](https://docs.godotengine.org/en/stable/tutorials/best_practices/)

---

**记住**：保持模块独立，使用事件通信，频繁测试！
