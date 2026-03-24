---
name: code-style
description: 项目代码风格：文件内部结构顺序、组件写法模板、样式方案、格式化配置。写代码时加载。
metadata:
  priority: L3
  category: project
  depends: naming, comments
---

# 代码风格

## 文件内部结构顺序

**每个 GDScript 文件按以下顺序组织（不可打乱）：**

```
1. extends 声明 + class_name（如有）

2. 文档注释（## 开头的模块说明）

3. 信号声明（signal）

4. 枚举定义（enum）

5. 常量定义（const）

6. @export 变量（导出属性）

7. @onready 变量

8. 普通成员变量（公共 → 私有 _前缀）

9. 生命周期方法（_ready, _process, _physics_process, _input 等）

10. 公共方法（对外接口）

11. 私有方法（_前缀，内部实现）

12. 事件回调方法（_on_ 前缀）
```

## 示例

✅ 正确：
```gdscript
extends Node
class_name CardManager
## 卡牌管理器 - 负责卡组管理和手牌操作

# ========== 信号 ==========
signal card_drawn(card_data: Dictionary)
signal hand_updated()

# ========== 枚举 ==========
enum CardType { ATTACK, DEFENSE, BUFF, DEBUFF, SPECIAL }

# ========== 常量 ==========
const MAX_HAND_SIZE: int = 10
const DRAW_ANIMATION_DURATION: float = 0.3

# ========== 导出属性 ==========
@export var initial_hand_size: int = 5

# ========== 成员变量 ==========
var hand: Array[Dictionary] = []
var _deck: Array[Dictionary] = []
var _discard_pile: Array[Dictionary] = []
var _is_initialized: bool = false

# ========== 生命周期 ==========
func _ready() -> void:
	pass

# ========== 公共方法 ==========
func draw_card() -> Dictionary:
	if _deck.is_empty():
		_shuffle_discard_into_deck()
	var card := _deck.pop_back()
	hand.append(card)
	card_drawn.emit(card)
	return card

# ========== 私有方法 ==========
func _shuffle_discard_into_deck() -> void:
	_deck = _discard_pile.duplicate()
	_discard_pile.clear()
	_deck.shuffle()

# ========== 事件回调 ==========
func _on_card_played(data) -> void:
	pass
```

❌ 错误：
```gdscript
extends Node
var hand = []
const MAX = 10
signal drawn
func _ready(): pass
var _deck = []
enum Type { A, B }
func draw(): pass
```

## 模块写法模板

```gdscript
extends Node
## [模块名称] - [功能描述]

# ========== 常量 ==========
const CONFIG_PATH: String = "res://data/configs/your_config.tres"

# ========== 状态 ==========
var _is_initialized: bool = false
var _is_running: bool = false

# ========== 生命周期（属于公共方法，但作为模块核心放在最前）==========

func initialize() -> void:
	if _is_initialized:
		return
	_load_config()
	_setup_components()
	_subscribe_events()
	_is_initialized = true

func start() -> void:
	if not _is_initialized:
		push_error("[ModuleName] 未初始化")
		return
	_is_running = true

func stop() -> void:
	_is_running = false

func cleanup() -> void:
	_unsubscribe_events()
	_is_initialized = false

# ========== 公共方法 ==========

func your_public_method() -> void:
	if not _is_running:
		return

# ========== 私有方法 ==========

func _load_config() -> void:
	pass

func _setup_components() -> void:
	pass

func _subscribe_events() -> void:
	EventBus.listen("event_name", self, "_on_event")

func _unsubscribe_events() -> void:
	EventBus.unlisten("event_name", self)

# ========== 事件回调 ==========

func _on_event(data) -> void:
	pass
```

## 场景与 UI 方案

```
- UI 使用 Godot 内置 Control 节点体系（不使用外部 UI 框架）
- 复杂 UI 使用 .tscn 场景文件组织，脚本与场景同名同目录
- 着色器使用 Godot Shading Language（.gdshader）
- 主题样式通过 Godot Theme 资源统一管理
- 动画优先使用 AnimationPlayer / Tween，避免手动 _process 插值
```

## 格式化配置

```
- 格式化工具: Godot 内置 GDScript 格式化
- 缩进: Tab（Godot 默认，不使用空格缩进）
- 行尾: LF
- 最大行宽: 100字符（建议，非强制）
- 字符串引号: 双引号 "（GDScript 约定）
- 类型注解: 尽量使用静态类型标注（如 var x: int = 0）
```

## GDScript 专属规则

- **使用静态类型标注** — 所有函数参数和返回值必须有类型声明（`func foo(x: int) -> String:`）
- **使用 `class_name`** — 需要跨文件引用的类必须声明 `class_name`
- **`@onready` 替代 `_ready` 赋值** — 需要在场景树就绪后获取节点引用时使用 `@onready`
- **`@export` 暴露编辑器属性** — 需要在编辑器中调整的参数使用 `@export`
- **信号优先于直接调用** — 父子节点间通信优先使用信号（`signal`），跨模块通信使用 `EventBus`
- **避免 `get_node` 硬编码路径** — 使用 `@onready` + `$NodeName` 或 `%UniqueNode`
- **使用 `push_error` / `push_warning`** — 替代 `print` 来报告问题，正式代码中不留 `print` 调试语句
- **`StringName` 用于高频字符串比较** — 如事件名、字典键等高频使用的字符串用 `&"string"` 语法

## 提交前检查清单

- [ ] 文件内部结构按规定顺序排列（extends→信号→枚举→常量→变量→生命周期→公共→私有→回调）
- [ ] 模块写法符合项目模板（initialize/start/stop/cleanup 生命周期）
- [ ] 使用了静态类型标注（函数参数+返回值）
- [ ] 使用 Tab 缩进，代码已通过 Godot 格式化
- [ ] 正式代码中没有遗留的 `print` 调试语句
