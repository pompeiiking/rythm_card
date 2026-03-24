---
name: file-structure
description: 项目目录结构、新增文件放置规则、禁止创建的文件、文档封闭清单。新建文件或不确定文件该放哪里时加载。
metadata:
  priority: L2
  category: project
  depends: layering, naming
---

# 项目目录结构

## 项目根目录

```
节奏牌/                         # Godot 项目根目录（project.godot 所在）
├── project.godot               # Godot 项目配置
├── core/                       # 核心层：框架内核、事件系统
│   ├── EventBus.gd             # 事件总线（Autoload）
│   ├── GameCore.gd             # 模块管理器（Autoload）
│   └── managers/               # 核心管理器（如 SceneTransition 等）
│
├── modules/                    # 业务层：按功能模块组织
│   ├── BaseModule.gd           # 模块接口规范（文档性质）
│   ├── run/                    # 局外系统：Roguelike 探索
│   │   ├── RunModule.gd        # 模块主文件
│   │   ├── scenes/             # 模块场景
│   │   ├── scripts/            # 辅助脚本
│   │   └── resources/          # 模块资源
│   ├── battle/                 # 局内系统：节奏卡牌对战
│   │   ├── BattleModule.gd
│   │   ├── combat/             # 战斗逻辑
│   │   ├── rhythm/             # 节奏判定
│   │   ├── workbench/          # 工作台系统
│   │   └── duelists/           # 决斗者系统
│   └── cards/                  # 卡牌系统
│       ├── CardsModule.gd
│       ├── scripts/
│       └── resources/
│
├── scenes/                     # 场景层：所有游戏场景
│   ├── main/                   # 主场景 / 主菜单
│   │   ├── main.tscn
│   │   └── main.gd
│   ├── run/                    # Run 探索场景
│   ├── battle/                 # 战斗场景
│   └── test_scenes/            # 测试场景（开发用）
│
├── data/                       # 数据目录（与源码分离）
│   ├── cards/                  # 卡牌数据库（.tres）
│   ├── characters/             # 角色/敌人数据
│   ├── events/                 # 随机事件数据
│   └── configs/                # 模块配置文件（.tres）
│
├── assets/                     # 共享资源（跨模块复用）
│   ├── fonts/                  # 字体
│   ├── audio/                  # 音频（音乐、音效）
│   ├── shaders/                # 着色器
│   └── ui/                     # 通用 UI 资源
│
└── 设计/                       # 设计文档与美术参考
    ├── docs/                   # 开发文档
    │   ├── 游戏设计文档.md
    │   ├── 开发指南.md
    │   ├── 架构日志.md
    │   └── TEAM_WORKFLOW.md
    └── img/                    # 美术参考图
        └── 美术设计/

ai-rules-template/              # AI 开发规范（项目根目录同级）
├── RULES.md                    # 项目规范主文件
├── STATUS.md                   # 项目状态快照
├── CHANGELOG.md                # 变更日志
├── skills/                     # 模块化规则
└── contracts/                  # 接口契约
```

## 新增文件放置规则

| 文件类型 | 放置位置 | 示例 |
|----------|---------|------|
| 模块主脚本 | `modules/[模块名]/[ModuleName].gd` | `modules/run/RunModule.gd` |
| 模块场景 | `modules/[模块名]/scenes/` | `modules/battle/scenes/battle_ui.tscn` |
| 模块辅助脚本 | `modules/[模块名]/scripts/` | `modules/cards/scripts/card_effect.gd` |
| 模块资源 | `modules/[模块名]/resources/` | `modules/cards/resources/sprites/` |
| 游戏场景 | `scenes/[场景类别]/` | `scenes/battle/battle_main.tscn` |
| 测试场景 | `scenes/test_scenes/` | `scenes/test_scenes/test_cards.tscn` |
| 数据文件（.tres/.json） | `data/[分类]/` | `data/cards/fireball.tres` |
| 模块配置 | `data/configs/` | `data/configs/rhythm_config.tres` |
| 共享资源 | `assets/[资源类别]/` | `assets/audio/bgm_battle.ogg` |
| 核心管理器 | `core/managers/` | `core/managers/SceneTransition.gd` |
| 着色器 | `assets/shaders/` | `assets/shaders/card_glow.gdshader` |

## 禁止创建的文件

- **core/ 或 modules/ 下的数据文件**（.tres/.json 数据文件必须放在 data/ 下，project.godot 除外）
- **未在RULES.md文档体系中登记的文档文件**
- **临时文件/调试文件**（如 `test.gd`, `temp.gd`, `debug.log`）
- **重复的工具脚本**（先搜索 core/ 和已有模块是否已有类似功能）
- **模块目录外的散落脚本**（每个 .gd 文件必须归属于某个模块或 core/）

## 新建文件决策流

```
Q1: "这个文件属于哪个功能模块？"
  → 明确属于某模块（run/battle/cards等） → 放 modules/[模块名]/ 下
  → 多个模块都用 → 放 core/ 或 assets/ 下
  → 属于框架核心 → 放 core/ 下
  → 是游戏场景 → 放 scenes/[场景类别]/ 下

Q2: "是数据还是代码？"
  → 数据（.tres/.json 配置/定义） → 放 data/ 下
  → 代码（.gd 脚本） → 放 core/ 或 modules/ 下
  → 资源（图片/音频/着色器等） → 放模块 resources/ 或 assets/ 下

Q3: "类似功能的文件是否已存在？"
  → 是 → 扩展已有文件而非新建
  → 否 → 创建新文件
```

## 提交前检查清单

- [ ] 新文件放在了正确的目录下（按上方放置规则）
- [ ] 新模块遵循 `modules/[模块名]/` 的标准子目录结构
- [ ] 没有在 core/ 或 modules/ 下创建数据文件（应放 data/）
- [ ] 没有创建未登记的文档文件
- [ ] 检查过 core/ 和已有模块中是否已有类似功能
