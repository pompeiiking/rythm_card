# 节奏牌 — 卡牌模块变更日志

---

### 2026-03-21 — AI:Cursor — CardManager 核心逻辑实现

**任务**: 完成 CardManager 核心逻辑

**实现内容**:
1. 生命周期管理: `initialize()`, `is_initialized()`
2. 回合管理: `_current_turn` 计数器，`start_turn()`/`end_turn()` 增强
3. 增强 `_build_initial_deck()`: null 检查和错误处理
4. 丰富查询接口: `find_card_by_data_id()`, `find_all_cards_by_data_id()`, `get_cards_by_type()`, `get_hand_by_type()`
5. 弃牌堆管理: `rebuild_deck_from_discard()`, `get_effect_used_cards()`
6. 出牌管理: `cancel_card()` 取消出牌
7. 统计功能: `get_deck_info()`, `get_hand_cost()`, `get_hand_summary()`, `get_cards_needing_charge()`
8. 完整卡牌信息: `get_card_full_info()`, 增强 `_card_to_dict()`
9. 改进事件发射: 所有事件携带更完整的数据

**CardManager 现在包含**:
- 基础状态管理 (DECK/HAND/CHARGED/EFFECT_USED/DISCARD)
- Fisher-Yates 洗牌算法
- 随机抽牌（非固定取末尾）
- 弃牌堆自动重建
- 丰富的查询接口
- 完整的事件系统

---

### 2026-03-20 — AI:Cursor — 📌架构变更

**任务**: 卡牌系统架构 v3.0 → v3.1，微内核架构重构

**变更文件**:
- `架构文件夹/发牌系统架构书v3.1` — 新增（微内核架构完全重写）
- `架构文件夹/发牌系统架构书v3.0` — 保留（作为历史参考）

**v3.0 核心问题**:

| 问题 | 描述 |
|------|------|
| 把流水线拆成子系统 | CardFactory / CardPile / HandManager / CardDealer / ChargeManager / RhythmPort / ComboKeeper / EffectDispatcher 8 个子系统，业务逻辑仍然分散 |
| 充能逻辑分裂 | 充能被拆到 ChargeManager + RhythmPort + PlayContext 三个地方 |
| stage 转换没有集中管理 | 谁负责更新 charge？谁负责检测完成？答案分散 |
| 文件数量仍过多 | ~19 个文件，子系统思维本身就是错的 |

**v3.1 核心决策：微内核架构**

微内核原则：**内核只做最小必要的事：管理实体生命周期 + 传递消息。所有其他业务逻辑都在内核之外，通过消息通信。**

| 操作系统概念 | 卡牌系统对应 |
|------------|------------|
| 进程/线程 | Card 实例 |
| 进程调度 | Card stage 转换 |
| 消息传递 | EventBus 事件 |
| 文件系统（内核外） | 效果处理器 |
| 网络协议（内核外） | 充能规则、连携检测 |

**v3.1 关键改进**:

1. **内核极简**：只有 `CardManager`（容器+stage转换）+ `Card`（自包含实体）+ `CardData`（静态数据）三个核心类
2. **Card 自包含充能**：charge 状态直接存在 Card 对象上，不在任何"子系统"里
3. **事件驱动业务逻辑**：效果、连携都是独立的服务，订阅事件工作，不直接调用核心
4. **Card.stage 作为唯一位置来源**：消除双重复位问题，`get_cards_by_stage()` 派生查询
5. **深度自查修复 9 个严重/中等问题**（详见架构书第七节）

**深度自查修复清单（FIX-1~FIX-9）**:

| # | 问题 | 严重程度 | 修复 |
|---|------|---------|------|
| FIX-1 | `Card` 创建流程缺失，整个游戏无法运行 | 严重 | `_build_initial_deck()` 从 `CardData.quantity` 创建实例 |
| FIX-2 | `_all_cards` 从未被填充 | 严重 | `_build_initial_deck()` 中 `append(card)` |
| FIX-3 | `end_turn()` 逻辑 bug + stage 双重复位 | 严重 | `Card.stage` 唯一来源 + `get_cards_by_stage()` 派生查询 |
| FIX-4 | 效果触发事件流断裂 | 严重 | `EffectRegistry` + `CardsModule._on_card_charged()` 调用 |
| FIX-5 | `_find_card_by_context()` O(n) 查找 | 中等 | `_playing_by_context: Dictionary` O(1) 查找表 |
| FIX-6 | `ClickDrawDriver.start()` 空函数 | 中等 | `_is_active` 状态 + `start()/stop()` 管理信号连接 |
| FIX-7 | `end_turn()` 循环空数组副本 | 中等 | 由 FIX-3 统一解决 |
| FIX-8 | 内部服务泄漏到模块边界 | 低 | 确认所有内部字段有 `_` 前缀 |
| FIX-9 | `context_id` 从未回填，停止节奏轴无法定位 | 中等 | `rhythm:context_started` 事件 + `RhythmPort` 回填 |

**文件变化**:

| | v2.0 | v3.0 | v3.1 |
|--|------|------|------|
| 总脚本数 | ~22 | ~19 | **~16** |
| 接口文件 | 7 | 0 | 0 |
| 状态机类 | 4 | 0 | 0 |
| 核心类 | 10+ | 8+ | **3** |
| 服务/驱动 | 7 | 7 | **4 + EffectRegistry** |

**v3.1 最终结构**:

```
_core/          → 3 个文件：CardManager + Card + CardData
_services/      → DrawDriver 接口 + 3 种驱动 + RhythmPort + ComboTracker
_services/_effects/ → EffectHandler 基类 + EffectRegistry + 5 个效果处理器
总计 ~16 个脚本 + 2 个数据 + 1 个契约
```

**关键设计决策**：
- `Card.stage` 是唯一位置信息来源，`_all_cards` 是唯一容器，`_playing_by_context` 是 O(1) 查找表——三者各司其职
- `rhythm_context_id` 在 `rhythm:context_started` 事件中由 `RhythmPort` 回填到 `Card`，不在 `play_card()` 中直接设置
- 运行时切换：`CardsModule.set_draw_driver(new_driver)` — 完全热插拔

---

### 2026-03-20 — AI:Cursor — 📌架构变更

**任务**: 卡牌系统架构 v2.0 → v3.0 深度优化

**变更文件**:
- `架构文件夹/发牌系统架构书v3.0` — 新增（深度优化版）

**核心问题（v2.0）**:

| 问题 | 描述 |
|------|------|
| 接口层过度设计 | 7 个 `*_interface.gd` 接口文件，每个都只是原样转发，无额外抽象 |
| 子系统划分过细 | 7 个子系统各只有 2-3 个文件，架构宽而浅，不足以独立承担职责 |
| 分层过深 | CardsModule → PlayPhaseManager → PlayContext → ChargeMediator → RhythmAdapter → RhythmAdapterImpl |
| 两套状态机并行 | PlayContext.ChargeState + PlayPhaseManager 状态描述同一件事 |
| 状态机杀鸡用牛刀 | PhaseState 基类 + 3 个子类，只管理 3 个阶段 |

---

*日志按时间倒序排列*
