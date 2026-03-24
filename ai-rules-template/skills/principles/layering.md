---
name: layering
description: 严格分层架构，只允许向下依赖，禁止跨层引用和同层具体实现互相依赖。新建文件或添加import时加载。
metadata:
  priority: L2
  category: principles
  depends: module-boundary
---

# 严格分层，禁止跨层依赖

## 规则

- **依赖方向只允许向下** — 上层可以依赖下层，下层绝不能依赖上层
- **同层之间禁止通过具体实现互相依赖** — 应通过接口、事件总线或依赖注入解耦
- **每个文件的 import 语句必须符合分层方向** — 违反即为架构破坏
- **跨层通信必须通过架构规划的通道**（事件、回调、接口），不允许直接引用

## 项目分层结构

```
场景层 (scenes/)
  UI场景、游戏场景、测试场景
  ↓ 可依赖
模块层 (modules/)
  run/、battle/、cards/ 等功能模块
  模块间禁止直接引用，通过 EventBus 通信
  ↓ 可依赖
核心层 (core/)
  EventBus.gd、GameCore.gd、managers/
  ↓ 可依赖
数据层 (data/)
  卡牌数据、配置文件、事件数据
  纯数据，不含逻辑代码
```

**依赖规则**：
- 场景 → 可引用模块和核心层
- 模块 → 可引用核心层，**不可直接引用其他模块**（通过 EventBus 事件通信）
- 核心 → 不可引用模块层和场景层
- 数据 → 纯数据文件，不引用任何代码层

## 示例

✅ 正确：
```gdscript
# 模块层 → 引用核心层（向下依赖）
EventBus.listen("card:played", self, "_on_card_played")
EventBus.fire("battle:damage_dealt", {"amount": 10})

# 场景层 → 引用模块和核心（向下依赖）
GameCore.add_module("Battle", BattleModule.new())

# 模块间通过事件通信（同层解耦）
# CardModule 发事件：
EventBus.fire("card:played", card_data)
# BattleModule 收事件：
EventBus.listen("card:played", self, "_on_card_played")
```

❌ 错误：
```gdscript
# 核心层 → 引用模块层（向上依赖，严重违规！）
# 在 EventBus.gd 中直接引用 BattleModule — 不可以

# 模块间直接调用（同层强耦合！）
var card_module = GameCore.get_module("Cards")
card_module.draw_card()  # 直接调用另一模块的方法 — 应通过事件
```

## 判断方法

添加 `preload()` / `load()` / `class_name` 引用时问自己：
1. "被引用的文件在哪一层？我在哪一层？" → 必须是我引用下层
2. "如果被引用的模块被删除/重写，我需要改吗？" → 是 → 耦合过紧，应通过 EventBus 解耦

## 提交前检查清单

- [ ] 所有新增的 `preload()` / `load()` / 类引用都符合向下依赖方向
- [ ] 核心层（core/）没有引用模块层（modules/）或场景层（scenes/）的文件
- [ ] 同层模块之间没有直接 `preload` / `load` 另一模块的脚本
- [ ] 跨模块通信使用了 EventBus 事件，不通过 `GameCore.get_module().method()` 直接调用
