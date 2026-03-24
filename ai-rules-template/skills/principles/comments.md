---
name: comments
description: 注释最小化原则，只注释"为什么"不注释"做什么"，禁止注释掉的代码。添加注释或文档时加载。
metadata:
  priority: L3
  category: principles
---

# 注释与文档最小化

## 规则

- **代码应该是自解释的** — 好的命名胜过注释
- 只在以下场景添加注释：
  1. **"为什么"而非"做什么"** — 解释设计决策，不解释代码逻辑
  2. **非直觉的性能优化** — 说明为什么选择了看起来不直觉的写法
  3. **公共方法的文档注释** — 使用 `##` 文档注释说明参数和返回值
  4. **TODO/STUB标记** — 格式：`# TODO(日期): 具体内容` / `# STUB(日期): 原因 — 替换计划`
- **禁止注释掉的代码** — 直接删除，git有历史记录
- **禁止与代码不一致的注释** — 比不注释更糟糕

## 示例

✅ 正确：
```gdscript
# 使用 Dictionary 而非自定义 Resource，因为卡牌数据需要在运行时动态修改，Resource 不适合频繁写入
var _card_cache: Dictionary = {}

## 计算玩家的活跃分数
## [br]参数: activities — 近30天内的活动记录数组
## [br]返回: 0-100之间的活跃分数
func calculate_activity_score(activities: Array[Dictionary]) -> int:
	pass
```

❌ 错误：
```gdscript
# 获取玩家（废话注释，代码本身已说明）
var player = get_player()

# i += 1（逐行注释，说明代码不够清晰）
i += 1

# var old_api = load("res://old_module.gd")  ← 注释掉的代码，应直接删除

# 造成伤害（但代码其实是治疗 — 注释与代码不一致）
target.heal(amount)
```

## 提交前检查清单

- [ ] 新增注释解释的是"为什么"而非"做什么"
- [ ] 没有注释掉的代码残留
- [ ] 现有注释与修改后的代码仍然一致
- [ ] 公共API有参数和返回值文档
