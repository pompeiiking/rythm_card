---
name: type-safety
description: 强类型严格模式的具体规则，禁用any和类型逃生舱，所有公共函数必须有返回类型。写类型声明或遇到类型问题时加载。
metadata:
  priority: L1
  category: principles
---

# 强类型严格模式

## 通用规则（所有语言）

- **不用类型系统的"逃生舱"来绕过编译/检查** — 类型问题必须正面解决
- **所有公共函数必须有明确的参数类型和返回类型声明**
- **类型定义集中管理** — 不在多个文件中重复定义相同类型

## GDScript 专属规则（本项目唯一脚本语言）

- 启用 GDScript 静态类型标注，所有新代码必须使用类型声明
- **所有函数参数必须有类型声明** — `func foo(x: int, name: String) -> void:`
- **所有函数必须有返回类型声明** — 无返回值用 `-> void`
- **变量声明尽量带类型** — `var health: int = 100` 而非 `var health = 100`
- **禁止 `Variant` 滥用** — 不使用无类型的 `var data` 传递结构化数据，应定义明确的 Dictionary 结构或自定义 Resource
- **使用类型化数组** — `var cards: Array[Dictionary] = []` 而非 `var cards = []`
- **`@export` 变量必须有类型** — `@export var speed: float = 100.0`
- **信号参数必须有类型** — `signal damage_dealt(amount: int, target: Node)`

✅ 正确：
```gdscript
func calculate_damage(base_damage: int, multiplier: float) -> int:
	return int(base_damage * multiplier)

var hand: Array[Dictionary] = []
signal card_played(card_data: Dictionary)
```

❌ 错误：
```gdscript
func calculate_damage(base_damage, multiplier):  # 无类型注解
	return base_damage * multiplier

var hand = []  # 无类型声明
signal card_played(card_data)  # 信号参数无类型
```

## 提交前检查清单

- [ ] 所有公共函数都有参数类型和返回类型声明（`-> void` / `-> int` 等）
- [ ] 没有无类型的 `var data` 用于传递结构化数据
- [ ] 新增的枚举/类型定义没有与现有类型重复
- [ ] 复杂类型（自定义 Resource 或 Dictionary 约定）有简短的说明注释
