# cards ↔ rhythm_axis 事件契约

> 定义 cards 模块与 rhythm_axis 模块之间的事件接口
> 版本: 2.0 | 更新日期: 2026-03-20

---

## 一、设计模型

### 模型：共享轴 + 队列

```
rhythm_axis（完全黑盒，节奏轴引擎）
    │
    │  不知道任何卡牌信息，不知道队列，不知道充能
    │  只管自己的节拍时间轴，独立运行
    │
    ├─ rhythm:beat_judged({result, delta})         ← 节拍判定结果
    ├─ rhythm:sequence_completed({})               ← 节拍序列完成
    │
    ▼
CardsModule / RhythmPort（管理队列 + 充能）
    │
    │  接收所有事件，自己维护：
    │  - 哪个卡在队列里（FIFO 顺序）
    │  - 哪张卡正在判定（_current_card）
    │  - 当前卡充了几个（_current_charge）
    │  - 是否可以打下一张（_consecutive_hits）
    │
    │  不向 rhythm_axis 发任何请求
    │  rhythm_axis 自己跑，不需要 cards 告诉它
```

**关键区别（v1.0 vs v2.0）**：

| 对比项 | v1.0（一卡一轴） | v2.0（共享轴+队列）|
|--------|--------------|----------------|
| rhythm 轴数量 | 每张卡一条轴 | 一条全局共享轴 |
| cards → rhythm | 发 `request_rhythm_start` | 不发任何请求 |
| 消息载体 | `context_id`（多轴时必须） | 不需要 `context_id` |
| 多卡同时判定 | 不支持（会冲突） | 队列依次处理 |
| rhythm 是否知道卡 | 是（通过 `card_id`） | 否（完全黑盒） |
| 充能计数位置 | `Card.current_charge` | `RhythmPort._current_charge` |

---

## 二、事件总览

```
rhythm_axis（发）                          CardsModule / RhythmPort（收）
    │
    ├── rhythm:beat_judged ──────────────►  计算充能，维护队列
    │
    └── rhythm:sequence_completed ───────►  检查队列状态

无反向请求！
cards 模块不向 rhythm_axis 发任何事件。
rhythm_axis 自己跑，cards 只管收信号。
```

---

## 三、rhythm_axis → cards

### 3.1 rhythm:beat_judged

**方向**: rhythm_axis → CardsModule / RhythmPort

**触发时机**: 每次节拍判定完成（Perfect / Good / Miss）

**载荷**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `result` | int | ✅ | 判定结果：`1=Perfect, 2=Good, 3=Miss` |
| `delta` | float | ✅ | 实际按键时间与目标时间的差值（秒） |

**接收方**: `RhythmPort._on_beat_judged()`

**处理逻辑**:
1. 如果当前没有卡在判定（`_is_rhythm_busy == false`），忽略
2. 如果 `result == PERFECT || result == GOOD`，`_current_charge += 1`
3. 如果 `result == MISS`，`_consecutive_hits = 0`
4. 发出 `cards:charge_updated({card, current_charge, required_charge, is_completed})`
5. 如果 `_current_charge >= required_charge`，`_finish_current_card()`

---

### 3.2 rhythm:sequence_completed

**方向**: rhythm_axis → CardsModule / RhythmPort

**触发时机**: 一个节拍序列（如一组节拍点）播放完毕

**载荷**: 空

**接收方**: `RhythmPort._on_sequence_completed()`

**处理逻辑**: 当前卡如果已经充能完成，由 `_finish_current_card()` 处理；否则等待下一次 `beat_judged` 自然触发。

---

## 四、CardsModule 内部事件（对外发出）

| 事件 | 方向 | 触发时机 | 关键载荷 |
|------|------|---------|---------|
| `cards:card_drawn` | → 外部 | 抽牌到手牌 | `instance_id`, `card_id`, `stage` |
| `cards:card_played` | → 外部 | 玩家打出卡牌 | `instance_id`, `card_id` |
| `cards:charge_updated` | → 外部 | 充能增加/变化 | `card`, `current_charge`, `required_charge`, `is_completed`, `consecutive_hits` |
| `cards:card_charged` | → 外部 | 充能完成，效果可触发 | `card` |
| `cards:card_discarded` | → 外部 | 卡牌进入弃牌区 | `instance_id` |
| `cards:turn_started` | → 外部 | 回合开始 | `hand_size` |
| `cards:turn_ended` | → 外部 | 回合结束 | `discard_size` |
| `cards:effect_triggered` | → 外部 | 效果触发 | `card`, `effect_id`, `result` |
| `cards:deck_refilled` | → 外部 | 弃牌堆洗入牌堆 | `count` |
| `rhythm:queue_updated` | → 外部 | 队列长度变化 | `queue_size` |
| `rhythm:card_started` | → 外部 | 队列中一张卡开始判定 | `card_instance_id`, `card_id`, `required_charge` |
| `rhythm:queue_cleared` | → 外部 | 队列被清空 | - |
| `combo:detected` | → 外部 | 检测到连携 | `combo_id`, `bonus` |

---

## 五、数据类型约定

### 5.1 Card Stage 枚举值

| 值 | 名称 | 说明 |
|----|------|------|
| `0` | `DECK` | 在牌堆中 |
| `1` | `HAND` | 在手牌中（包括在队列中等待的卡） |
| `2` | `CHARGED` | 充能完成，效果可触发 |
| `3` | `EFFECT_USED` | 效果已触发（已弃牌） |
| `4` | `DISCARD` | 在弃牌区 |

**注意**：v2.0 移除了 `PLAYING` 阶段。卡打出后仍在 `HAND` 阶段。"正在判定"的状态由 `RhythmPort._current_card` 维护，不写在 `Card.stage` 上。

### 5.2 Rhythm Judge 结果

| 值 | 名称 | 充能影响 |
|----|------|---------|
| `1` | `JUDGE_PERFECT` | +1 充能 |
| `2` | `JUDGE_GOOD` | +1 充能 |
| `3` | `JUDGE_MISS` | +0 充能 |

---

## 六、实现要求

1. rhythm_axis 模块**不依赖** cards 模块，完全独立运行
2. rhythm_axis **不接收** cards 发出的任何事件
3. rhythm_axis 发出的 `rhythm:beat_judged` 和 `rhythm:sequence_completed` 中**不包含**任何卡牌相关字段（无 `card_id`、`card_instance_id`、`context_id`）
4. RhythmPort 通过 `RhythmPort.enqueue_card(card)` 接收外部出牌操作，自己维护队列顺序
5. 当 `RhythmPort._current_card == null` 且 `_card_queue` 非空时，自动从队列取下一张开始判定
6. 回合结束时，外部调用 `RhythmPort.clear_queue()` 清空队列
7. 事件载荷使用 `Dictionary`，字段名必须严格匹配

---

## 七、RhythmPort 内部状态

```
_card_queue: Array[Card]        ← 玩家出牌顺序的 FIFO 队列
_current_card: Card             ← 当前正在节奏轴上判定的卡（null = 无）
_current_charge: int            ← 当前卡的充能计数
_consecutive_hits: int          ← 连续命中数（用于连携等扩展）
_is_rhythm_busy: bool           ← 是否有卡正在判定
```

**状态转移**：

```
enqueue_card()      → _card_queue.append(card)
                    → 如果 _is_rhythm_busy == false → _start_next_card()
                    → _is_rhythm_busy = true
                    → _current_card = card
                    → _current_charge = 0

beat_judged(GOOD/PERFECT) → _current_charge += 1
                           → 如果 >= required_charge → _finish_current_card()

beat_judged(MISS)          → _consecutive_hits = 0

_finish_current_card()     → _current_card = null
                           → _is_rhythm_busy = false
                           → 触发 cards:card_charged
                           → _start_next_card()（从队列取下一张）

clear_queue()              → _card_queue.clear()
                           → _current_card = null
                           → _is_rhythm_busy = false
```
