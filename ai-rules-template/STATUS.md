# 节奏牌 — 项目状态

> 最后更新: 2026-03-08 by AI:Cursor

## 当前进度

项目处于早期搭建阶段。核心框架（EventBus + GameCore + 模块生命周期）已实现，业务模块尚未开发。AI 开发规范已从通用模板转化为项目专属规范。

### 已完成模块
- core/EventBus.gd — ✅ 完成（事件监听、取消、发送）
- core/GameCore.gd — ✅ 完成（模块添加、获取、移除，含生命周期管理）
- modules/BaseModule.gd — ✅ 完成（模块接口规范文档）
- scenes/main/ — ✅ 完成（主场景骨架，模块注册入口）
- ai-rules-template/ — ✅ 完成（AI 开发规范初始化）

### 进行中
- 无（等待业务模块开发启动）

### 待开始
- modules/run/ — 局外系统（Roguelike 探索、地图生成、随机事件、商店）— 前置：核心框架 ✅
- modules/battle/ — 局内系统（战斗逻辑、节奏判定、工作台、决斗者）— 前置：核心框架 ✅
- modules/cards/ — 卡牌系统（卡牌数据、效果、卡组管理）— 前置：核心框架 ✅
- data/ — 游戏数据（卡牌数据库、敌人数据、事件数据、配置）— 前置：模块接口确定
- assets/ — 音频、美术资源集成 — 前置：对应模块开发

## 活跃STUB清单

| 位置 | 原因 | 替换条件 |
|------|------|---------|
| `scenes/main/main.gd:14-20` _register_modules() | 模块注册为空，等待业务模块开发 | 各业务模块实现后逐步注册 |
| `scenes/main/main.gd:23-28` _on_game_ready() | 游戏就绪回调为空 | 确定启动流程后实现 |
| `assets/shaders/card_shader.gdshader` | 卡牌着色器占位 | 美术方案确定后替换 |

## 已知问题

- main.tscn 中脚本引用路径可能为 `res://main.gd` 而非 `res://scenes/main/main.gd` — 中 — 需验证 Godot 能否正确加载
- project.godot 引用 `res://icon.svg` 但项目中未找到该文件 — 低 — 不影响运行
- 开发指南和 TEAM_WORKFLOW 文档有冗余内容待精简（架构师已知悉）— 低

## 架构备忘

- **核心通信方式**: 模块间通过 EventBus 事件通信，禁止直接调用
- **模块生命周期**: initialize → start → stop → cleanup，由 GameCore 管理
- **Autoload**: EventBus 和 GameCore 通过 Godot Autoload 全局可用
- **事件命名**: `模块名:动作_对象`（如 `card:played`, `battle:phase_changed`）
- **架构日志**: `设计/docs/架构日志.md` 由架构师 Pompeii 手动维护，AI 不可修改

## 下一步建议

1. 确定第一个要实现的业务模块（建议从 cards/ 卡牌系统开始，因为局内局外都依赖它）
2. 在 `contracts/` 中定义模块间接口契约（cards↔battle、cards↔run）
3. 创建卡牌数据结构的 Resource 类型定义
4. 开始实现 CardsModule 基础功能（卡组、手牌、抽牌、出牌）
