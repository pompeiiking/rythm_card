---
name: testing
description: 测试文件位置、命名、最小覆盖要求、临时调试测试的处理规范。写测试或改测试时加载。
metadata:
  priority: L2
  category: workflow
  depends: naming
---

# 测试规范

## 规则

- **统一使用测试场景目录** — `scenes/test_scenes/`，每个模块至少一个测试场景
- **测试场景命名**: `test_[模块名].tscn`，脚本与场景同名
- **每个公共方法至少有一个正例和一个反例测试**
- **测试只测行为，不测实现细节** — 重构不应导致测试失败

## 测试文件位置

```
统一测试场景目录:
  节奏牌/scenes/test_scenes/
    test_cards.tscn          # 卡牌模块测试场景
    test_cards.gd            # 卡牌模块测试脚本
    test_battle.tscn         # 战斗模块测试场景
    test_rhythm.tscn         # 节奏系统测试场景
    test_run.tscn            # 局外系统测试场景

每个模块至少一个测试场景，场景命名: test_[模块名].tscn
测试脚本与测试场景同名同目录。
在 Godot 编辑器中可直接运行测试场景进行验证。
```

## 测试场景模板

```gdscript
extends Node
## [模块名称] 测试场景

func _ready() -> void:
	print("=== 测试 [ModuleName] ===")
	_test_basic_functionality()
	_test_edge_cases()
	_test_events()
	print("=== 测试完成 ===")

func _test_basic_functionality() -> void:
	# 正例：正常路径
	print("测试: 抽牌功能...")
	var card: Dictionary = card_module.draw_card()
	assert(card.has("id"), "抽到的卡牌应有 id 字段")
	assert(card.has("name"), "抽到的卡牌应有 name 字段")
	print("✓ 抽牌功能正常")

func _test_edge_cases() -> void:
	# 反例：边界情况
	print("测试: 牌库为空时抽牌...")
	var card: Dictionary = card_module.draw_card()
	assert(card.is_empty(), "牌库为空时应返回空字典")
	print("✓ 空牌库处理正常")

func _test_events() -> void:
	# 事件通信测试
	print("测试: 事件通信...")
	EventBus.listen("card:drawn", self, "_on_test_card_drawn")
	card_module.draw_card()

var _event_received: bool = false
func _on_test_card_drawn(data) -> void:
	_event_received = true
	print("✓ 事件接收成功: ", data)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_test_basic_functionality()
	if event.is_action_pressed("ui_cancel"):
		get_tree().reload_current_scene()
```

## 临时调试测试

开发过程中写的临时测试（用于调试、验证假设）：
- 用 `# DEBUG-TEST` 标记
- **不允许合并到主分支** — 提交前删除或转化为正式测试
- 转化：去掉 `DEBUG-TEST` 标记，补充 `assert` 断言，使其成为正式测试

## 示例

✅ 正确：
```gdscript
# 测试行为，不测实现
func _test_draw_card() -> void:
	var card: Dictionary = card_module.draw_card()
	assert(card.has("id"), "抽到的卡牌应有id")
	assert(card_module.hand.size() > 0, "抽牌后手牌应增加")
```

❌ 错误：
```gdscript
# 测试实现细节 — 重构时会无故失败
func _test_draw_card() -> void:
	card_module.draw_card()
	assert(card_module._deck.size() == 9, "牌库应减少1张")  # 依赖内部变量 _deck 的具体数量
```

## 提交前检查清单

- [ ] 测试文件命名和位置符合项目约定
- [ ] 新增的公共函数/方法有正例和反例测试
- [ ] 测试验证行为而非实现细节
- [ ] 没有残留的 `DEBUG-TEST` 临时测试
- [ ] 所有测试通过
