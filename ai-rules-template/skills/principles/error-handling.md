---
name: error-handling
description: 错误信息规范、错误报告方式、故障隔离策略。写错误处理逻辑时加载。
metadata:
  priority: L1
  category: principles
---

# 错误处理一致性

## GDScript 错误处理特点

**GDScript 没有 try-catch 异常机制。** 错误处理通过以下方式实现：
- `push_error()` / `push_warning()` — 输出错误/警告到控制台，不中断执行
- `assert()` — 调试断言，仅在 debug 模式生效
- 返回值约定 — 函数通过返回 `null` / 错误码 / `Result` 模式表示失败
- 信号 — 异步操作通过信号通知成功/失败

## 规则

- **错误信息必须包含上下文** — 格式：`[模块名] 操作描述: 具体原因`
- **使用 `push_error` 报告错误，不用 `print`** — `push_error` 在编辑器中显示为红色，便于定位
- **使用 `push_warning` 报告非致命警告** — 不影响运行但需关注
- **核心模块的错误不能导致整个游戏崩溃** — 故障隔离，非核心功能失败不影响主流程
- **函数失败时返回明确的失败值** — 不静默失败

## 示例

✅ 正确：
```gdscript
## 模块管理器 — 错误信息包含上下文
func add_module(module_name: String, module: Node) -> bool:
	if _modules.has(module_name):
		push_error("[GameCore] 添加模块失败: '%s' 已注册，不能重复注册" % module_name)
		return false
	_modules[module_name] = module
	add_child(module)
	return true

## 数据加载 — 返回值表示成功/失败
func load_card_data(card_id: String) -> Dictionary:
	var path := "res://data/cards/%s.tres" % card_id
	if not ResourceLoader.exists(path):
		push_warning("[CardModule] 卡牌数据不存在: %s" % path)
		return {}
	var resource = load(path)
	return resource.data

## 调试断言 — 仅开发时生效，帮助尽早发现问题
func deal_damage(amount: int, target: Node) -> void:
	assert(amount >= 0, "伤害值不能为负数: %d" % amount)
	assert(is_instance_valid(target), "目标节点无效")
	target.take_damage(amount)
```

❌ 错误：
```gdscript
## 无上下文的错误信息
func add_module(module_name: String, module: Node) -> void:
	if _modules.has(module_name):
		print("already registered")  # 用print报告错误，没有模块名和操作名
		return

## 静默失败 — 问题被隐藏
func load_card_data(card_id: String) -> Dictionary:
	var path := "res://data/cards/%s.tres" % card_id
	if not ResourceLoader.exists(path):
		return {}  # 静默返回空，调用方不知道加载失败了

## 不检查返回值
func start_battle() -> void:
	var enemy_data = load_enemy("boss_01")  # 没有检查是否加载成功就直接使用
	enemy_data.hp -= 10  # 如果加载失败，这里会崩溃
```

## 错误处理策略

| 错误类型 | GDScript 处理方式 |
|----------|-----------------|
| 可预期的业务错误（如卡组为空） | `push_warning` + 返回失败值 + 向玩家显示提示 |
| 数据加载失败（如资源不存在） | `push_error` + 返回默认值/空值 + 优雅降级 |
| 编程错误（如参数违反约定） | `assert()` 在开发时捕获 + `push_error` 在发布版记录 |
| 模块初始化失败 | `push_error` + 跳过该模块 + 游戏继续运行 |
| 不可恢复的错误（如核心数据损坏） | `push_error` + 安全返回主菜单 |

## 返回值约定

```gdscript
# 方案1: 返回 null 表示失败（适用于返回对象的函数）
func get_module(module_name: String) -> Node:
	if not _modules.has(module_name):
		return null  # 调用方需检查 null

# 方案2: 返回 bool 表示成功/失败（适用于操作型函数）
func add_module(module_name: String, module: Node) -> bool:
	if _modules.has(module_name):
		push_error("[GameCore] 模块已存在: %s" % module_name)
		return false
	# ...
	return true

# 方案3: 返回空容器表示无数据（适用于返回集合的函数）
func get_hand_cards() -> Array[Dictionary]:
	if not _is_initialized:
		push_warning("[CardModule] 未初始化，返回空手牌")
		return []
	return _hand
```

## 提交前检查清单

- [ ] 错误信息格式：`[模块名] 操作描述: 具体原因`
- [ ] 使用 `push_error` / `push_warning` 而非 `print` 报告错误
- [ ] 可能失败的函数有明确的失败返回值（null / false / 空容器）
- [ ] 调用可能失败的函数后检查了返回值
- [ ] 非核心功能的错误不会导致游戏崩溃
- [ ] 开发阶段的关键假设使用了 `assert()` 校验
