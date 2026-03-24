---
name: naming
description: 文件、变量、函数、类的命名一致性规范，禁止同义词混用和无意义缩写。新建任何标识符时加载。
metadata:
  priority: L2
  category: principles
---

# 命名一致性

## 规则

- **全项目同一种命名约定**，不混用多种风格
- **同一概念必须使用同一名称** — 不允许一处叫 `user` 另一处叫 `account`
- **禁止无意义缩写** — 用 `eventBus` 不用 `eb`，用 `configuration` 不用 `cfg`
- **禁止无意义命名** — `data`, `info`, `item`, `temp`, `result`, `obj` 不能独立作为变量名

## 项目命名规则

### 文件命名（全项目统一）

- 脚本文件：`snake_case.gd`（如 `rhythm_judge.gd`、`card_effect.gd`）
- 场景文件：`snake_case.tscn`（如 `card_hand.tscn`、`battle_ui.tscn`）
- 资源文件：`snake_case.tres`（如 `fireball_card.tres`）
- 着色器文件：`snake_case.gdshader`（如 `card_glow.gdshader`）
- 模块主文件：`PascalCase.gd`（如 `RunModule.gd`、`BattleModule.gd`，与 class_name 一致）
- 测试场景：`test_[模块名].tscn`（如 `test_cards.tscn`）

### 代码命名

| 类别 | 规则 | 示例 |
|------|------|------|
| 类名（class_name） | PascalCase | `CardManager`, `EventBus`, `BattleModule` |
| 函数/方法 | snake_case | `get_user_by_id()`, `calculate_damage()` |
| 变量 | snake_case | `current_hp`, `hand_size`, `card_data` |
| 常量 | UPPER_SNAKE_CASE | `MAX_HAND_SIZE`, `DEFAULT_BPM` |
| 枚举名 | PascalCase | `CardType`, `BattlePhase` |
| 枚举值 | UPPER_SNAKE_CASE | `CardType.ATTACK`, `BattlePhase.CHANTING` |
| 私有属性/方法 | 前缀下划线 `_` + snake_case | `_cache`, `_is_running`, `_load_config()` |
| 布尔变量 | `is_/has_/can_/should_` 前缀 | `is_loading`, `has_permission`, `can_attack` |
| 信号 | snake_case（动词过去式或名词） | `card_drawn`, `damage_dealt`, `phase_changed` |
| 事件名（EventBus） | `模块名:动作_对象` | `card:played`, `battle:phase_changed`, `rhythm:beat` |
| 节点名 | PascalCase | `CardHand`, `BattleUI`, `ScoreLabel` |

## 示例

✅ 正确：
```gdscript
var is_player_authenticated: bool = check_auth(current_player)
var retry_delay_ms: int = 3000
func calculate_total_damage(cards: Array[Dictionary]) -> int:
	pass
```

❌ 错误：
```gdscript
var d = get_data()              # 无意义命名
var usrAuth = chkA(u)           # 无意义缩写 + camelCase 混用
var flag = true                 # flag是什么flag？
func proc(x):                  # proc什么？x是什么？无类型
	pass
```

## 提交前检查清单

- [ ] 新变量/函数名能让不看上下文的人理解含义
- [ ] 没有使用 `data`, `info`, `temp`, `result` 等作为独立变量名
- [ ] 同一概念在所有文件中使用同一名称
- [ ] 文件命名遵循项目统一约定
- [ ] 布尔变量使用了 `is_/has_/can_/should_` 前缀（snake_case）
