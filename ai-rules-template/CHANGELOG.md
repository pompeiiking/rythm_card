# 节奏牌 — 变更日志

---

### 2026-03-08 — AI:Cursor — 📌规范变更

**任务**: 深度自查修复（两轮）— 将残留的 TypeScript/Web 概念全部替换为 GDScript/Godot 原生概念
**变更文件**:
- `skills/principles/naming.md` — [严重] 代码命名表从 camelCase 改为 snake_case，示例从 TypeScript 改为 GDScript
- `skills/principles/type-safety.md` — [严重] 删除不适用的 TypeScript/Python 段落，仅保留 GDScript 规则
- `skills/principles/error-handling.md` — [严重] 完全重写：GDScript 无 try-catch，改为 push_error + 返回值约定 + assert 模式
- `skills/principles/module-boundary.md` — [严重] 完全重写：去掉 index 文件概念，改为 Godot 的 class_name + 模块主文件入口模式
- `skills/workflow/anti-paranoid.md` — [严重] 示例从 `?.`/try-catch/as any 改为 GDScript 等价模式（空值防御/静默返回/Variant绕过）
- `skills/principles/abstraction.md` — [严重] 示例从 interface/implements 改为 GDScript 基类继承 + duck typing
- `skills/workflow/testing.md` — [严重] 测试模板从 describe/it 改为 Godot 测试场景脚本模式
- `skills/principles/stub-management.md` — [重要] STUB 示例从 TypeScript 改为 GDScript (push_error + pass)
- `skills/principles/comments.md` — [重要] 注释示例从 TypeScript/JSDoc 改为 GDScript ## 文档注释
- `skills/principles/performance.md` — [重要] 示例从 TypeScript/DOM 改为 GDScript (_process/Vector2)，频率表去掉 DOM 概念
- `skills/principles/data-separation.md` — [重要] 示例从 TypeScript 改为 GDScript (load/ResourceLoader)，检查清单去掉 import/require
- `skills/principles/layering.md` — [重要] 检查清单从 import 改为 preload/load/class_name 引用
- `skills/workflow/collaboration.md` — [重要] 依赖管理从 npm/pip/cargo 改为 Godot addons/GDExtension；删除 index 文件引用
- `skills/project/code-style.md` — [中等] 模块模板中公共方法/私有方法顺序修正为与定义一致
- `skills/principles/zero-hardcoding.md` — [中等] 示例从 TypeScript 改为 GDScript

**变更理由**: 初次转化时仅填充了项目专属 TODO 占位符，但通用模板中原有的 TypeScript/Web 示例和概念未替换，与 GDScript/Godot 开发逻辑严重不符（如 try-catch、index 文件导出、DOM 操作、npm 包管理等概念在 GDScript 中不存在）
**授权来源**: 人类开发者明确要求深度自查
**影响范围**: 全局 — 所有 AI 在遵循这些 skill 时将使用正确的 GDScript 模式

---

### 2026-03-08 — AI:Cursor

**任务**: 初始化项目规范，从通用模板转化为节奏牌专属规范
**变更文件**:
- `RULES.md` — 更新 TEMPLATE_STATUS 为 INITIALIZED:节奏牌，替换标题，填充项目专属文档清单
- `skills/project/file-structure.md` — 填充节奏牌项目目录结构、文件放置规则、禁止列表
- `skills/project/code-style.md` — 填充 GDScript 文件结构顺序、模块模板、场景方案、格式化配置、语言专属规则
- `skills/principles/type-safety.md` — 新增 GDScript 静态类型标注规则
- `skills/principles/naming.md` — 填充 GDScript 文件命名（snake_case）、私有前缀（_）、事件命名（模块名:动作_对象）
- `skills/principles/layering.md` — 填充四层架构（场景→模块→核心→数据）及依赖规则
- `skills/principles/data-separation.md` — 填充 data/ 目录结构（cards/characters/events/configs）
- `skills/principles/performance.md` — 填充节奏游戏性能预算（60fps、判定延迟<16ms）
- `skills/workflow/collaboration.md` — 填充技术栈（Godot 4.5 + GDScript + 事件驱动）
- `skills/workflow/git-commit.md` — 填充 scope 定义（core/run/battle/cards/rhythm 等）
- `skills/workflow/testing.md` — 填充测试场景方案（scenes/test_scenes/ 统一目录）
- `contracts/_index.md` — 填充 shared-types 负责人和日期
- `contracts/shared-types.contract.md` — 填充全局共享类型（卡牌数据结构、事件载荷、枚举、错误格式）
- `STATUS.md` — 新建，项目当前状态快照
- `CHANGELOG.md` — 新建（本文件），第一条变更记录

**影响范围**: 全局（AI 开发规范体系初始化）
**关联STUB**: 无新增
