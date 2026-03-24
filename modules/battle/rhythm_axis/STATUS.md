# 节奏牌 — 项目状态

> 最后更新: 2026-03-16 by AI:Cursor

## 当前进度

项目处于开发阶段。节奏轴模块已实现核心功能，包括发射器、判定区、节拍生成器、动效管理等。AI 开发规范已从通用模板转化为项目专属规范。

### 已完成模块
- core/EventBus.gd — 完成（事件监听、取消、发送）
- core/GameCore.gd — 完成（模块添加、获取、移除，含生命周期管理）
- modules/BaseModule.gd — 完成（模块接口规范文档）
- modules/battle/rhythm_axis/ — 完成（节奏轴核心模块）
  - rhythm_axis_module.gd — 模块主入口
  - scripts/rhythm_emitter.gd — 发射器
  - scripts/hit_zone.gd — 判定区
  - scripts/rhythm_axis_logic.gd — 轴逻辑
  - scripts/beat_generator.gd — 节拍生成器
  - scripts/effect_manager.gd — 动效管理器
  - scripts/*_input_strategy.gd — 输入策略（单键/多键/顺序按键）
- scenes/main/ — 完成（主场景骨架，模块注册入口）
- ai-rules-template/ — 完成（AI 开发规范初始化）
- data/configs/ — 完成（节奏系统配置）

### 进行中
- 无

### 待开始
- modules/run/ — 局外系统（Roguelike 探索、地图生成、随机事件、商店）
- modules/cards/ — 卡牌系统（卡牌数据、效果、卡组管理）
- assets/ — 音频、美术资源集成

## 活跃STUB清单

| 位置 | 原因 | 替换条件 |
|------|------|---------|
| `scenes/main/main.gd` | 游戏主流程待实现 | 确定启动流程后实现 |
| `modules/cards/` | 卡牌系统未开发 | 业务需求确定后实现 |

## 已知问题

- 暂无

## 架构备忘

- **核心通信方式**: 模块间通过 EventBus 事件通信，禁止直接调用
- **模块生命周期**: initialize → start → stop → cleanup，由 GameCore 管理
- **Autoload**: EventBus 和 GameCore 通过 Godot Autoload 全局可用
- **事件命名**: `模块名:动作_对象`（如 `card:played`, `battle:phase_changed`）

## 下一步建议

1. 确定第一个要实现的业务模块（建议从 cards/ 卡牌系统开始）
2. 在 `contracts/` 中定义模块间接口契约
3. 创建卡牌数据结构的 Resource 类型定义
4. 开始实现 CardsModule 基础功能
