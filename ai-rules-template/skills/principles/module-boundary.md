---
name: module-boundary
description: 模块入口出口规范，资源获取释放对称，模块主文件作为唯一公共入口，外部不直接引用内部脚本。新建模块时加载。
metadata:
  priority: L2
  category: principles
  depends: naming
---

# 单一入口，单一出口

## 规则

- **每个模块有一个主文件作为唯一公共入口**（如 `RunModule.gd`），外部只通过模块主文件和 EventBus 与模块交互
- **资源获取和释放必须对称** — 获取了就必须释放，在对称位置（initialize↔cleanup, listen↔unlisten, add_child↔remove_child）
- **模块内部脚本是实现细节** — `scripts/` 目录下的辅助脚本不应被其他模块直接引用
- **模块间通信只通过 EventBus** — 不通过 `GameCore.get_module()` 调用其他模块的方法

## 示例

✅ 正确：
```gdscript
# 模块主文件 BattleModule.gd — 唯一的公共入口
extends Node
class_name BattleModule

func initialize() -> void:
	EventBus.listen("run:battle_entered", self, "_on_battle_entered")
	_setup_combat_system()

func cleanup() -> void:
	EventBus.unlisten("run:battle_entered", self)  # 释放（与 listen 对称）
	_teardown_combat_system()

# 资源获取/释放对称
func _setup_combat_system() -> void:
	_combat_node = CombatSystem.new()
	add_child(_combat_node)

func _teardown_combat_system() -> void:
	if _combat_node:
		remove_child(_combat_node)
		_combat_node.queue_free()
		_combat_node = null

# 模块间通过事件通信
func _on_battle_entered(data) -> void:
	EventBus.fire("battle:started", {"enemy_id": data.enemy_id})
```

❌ 错误：
```gdscript
# 直接引用另一个模块的内部脚本 — 重构时会破坏
var rhythm_judge = preload("res://modules/battle/scripts/rhythm_judge.gd").new()

# 通过 GameCore 直接调用另一个模块的方法 — 强耦合
var card_module = GameCore.get_module("Cards")
card_module.draw_card()  # 应通过 EventBus.fire("card:request_draw")

# 资源不对称 — 只有 listen 没有 unlisten
func initialize() -> void:
	EventBus.listen("game:started", self, "_on_game_started")
	# cleanup() 中忘记 unlisten → 模块移除后事件仍会尝试调用已销毁的对象
```

## Godot 模块入口约定

```
modules/battle/
├── BattleModule.gd      ← 唯一公共入口（class_name: BattleModule）
├── combat/              ← 内部实现，其他模块不应直接引用
├── rhythm/              ← 内部实现
├── scenes/              ← 内部场景
└── scripts/             ← 内部辅助脚本
```

- 外部通过 `GameCore.add_module("Battle", BattleModule.new())` 注册
- 外部通过 `EventBus` 与模块通信
- 模块内部如何组织子系统是模块自己的事，外部不依赖

## 提交前检查清单

- [ ] 新模块有一个主文件作为公共入口（声明了 `class_name`）
- [ ] 外部不直接引用模块 `scripts/` 下的内部脚本
- [ ] 每个 `EventBus.listen` 都有对应的 `EventBus.unlisten`（在 cleanup 中）
- [ ] 每个 `add_child` 都有对应的 `remove_child` + `queue_free`（在 cleanup 中）
- [ ] 模块间通信通过 EventBus 事件，不通过 `get_module().method()` 直接调用
