# 全局共享类型契约

> 状态: 草案
> 负责人: Pompeii
> 最后更新: 2026-03-08

## 说明

本文件定义所有模块都必须使用的公共类型。任何模块在实现时，涉及这些类型的地方必须严格使用此处的定义，不得自行定义同名或类似类型。

## 共享类型定义

```gdscript
# 卡牌数据结构（所有模块传递卡牌信息时必须使用此结构）
# Dictionary 结构约定:
# {
#   "id": String,              # 卡牌唯一标识（如 "fireball_01"）
#   "name": String,            # 卡牌显示名称
#   "type": String,            # 卡牌类型："attack" | "defense" | "buff" | "debuff" | "special"
#   "cost": int,               # 费用
#   "description": String,     # 卡牌描述文本
#   "spell_sequence": String,  # 吟唱序列（如 "ASDF"）
#   "effects": Array,          # 效果列表
# }

# 事件数据载荷约定（通过 EventBus 传递）:
# card:played → {"card_id": String, "player_id": int, "cost": int}
# battle:damage_dealt → {"source_id": int, "target_id": int, "amount": int}
# rhythm:input_judged → {"result": String, "timing_offset": float}
#   result 取值: "perfect" | "good" | "miss"
# rhythm:beat → {"beat_index": int, "timestamp": float}
# run:node_selected → {"node_type": String, "node_id": String}
```

## 共享常量/枚举

```gdscript
# 卡牌类型枚举（建议各模块统一使用）
# CardType: ATTACK = 0, DEFENSE = 1, BUFF = 2, DEBUFF = 3, SPECIAL = 4

# 战斗阶段枚举
# BattlePhase: PREPARATION = 0, CHANTING = 1, RESOLUTION = 2

# 节奏判定结果
# RhythmJudge: PERFECT = 0, GOOD = 1, MISS = 2

# Run 节点类型
# NodeType: BATTLE = "battle", EVENT = "event", SHOP = "shop",
#           REST = "rest", ELITE = "elite", BOSS = "boss"
```

## 共享错误类型

```gdscript
# 模块错误信息格式约定:
# push_error("[模块名] 操作描述: 具体原因")
# 示例: push_error("[CardModule] 抽牌失败: 牌库为空")

# 自定义错误应包含:
# - 模块名（方括号包裹）
# - 操作名
# - 原因
```
