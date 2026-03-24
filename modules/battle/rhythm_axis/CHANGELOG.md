# 节奏牌 — 变更日志

---

### 2026-03-16 — AI:Cursor

**任务**: 根据开发规范进行全面问题修复

**变更文件**:
- `modules/battle/rhythm_axis/scripts/single_key_input_strategy.gd` — [修复] 删除重复的 `_get_key_name()` 方法，改用基类的静态方法 `get_key_name_static()`
- `modules/battle/rhythm_axis/scripts/multi_key_input_strategy.gd` — [修复] 删除重复的 `_get_key_name()` 方法，改用基类的静态方法 `get_key_name_static()`
- `modules/battle/rhythm_axis/scripts/sequential_keys_input_strategy.gd` — [修复] 删除重复的 `_get_key_name()` 方法，改用基类的静态方法 `get_key_name_static()`
- `modules/battle/rhythm_axis/scripts/effect_manager.gd` — [增强] 为性能优化代码添加"为什么"注释（update_block_effects 中的正弦函数计算、_call_later 中的 await 模式）
- `modules/ExampleModule.gd` — [修复] 添加 TODO 标注空实现，调试日志改用 `OS.is_debug_build()` 包裹

**新增文件**:
- `STATUS.md` — 新建，项目状态文件

**变更理由**: 根据 ai-rules-template 开发规范进行自检修复，提升代码质量和可维护性

**影响范围**: 局部 — 修复了重复代码、增强了注释规范

---

### 2026-03-08 — AI:Cursor — 规范变更

**任务**: 深度自查修复（两轮）— 将残留的 TypeScript/Web 概念全部替换为 GDScript/Godot 原生概念

**变更文件**:
- `skills/principles/naming.md` — [严重] 代码命名表从 camelCase 改为 snake_case，示例从 TypeScript 改为 GDScript
- `skills/principles/type-safety.md` — [严重] 删除不适用的 TypeScript/Python 段落，仅保留 GDScript 规则
- `skills/principles/error-handling.md` — [严重] 完全重写：GDScript 无 try-catch，改为 push_error + 返回值约定 + assert 模式
- `skills/principles/module-boundary.md` — [严重] 完全重写：去掉 index 文件概念，改为 Godot 的 class_name + 模块主文件入口模式
- `skills/workflow/anti-paranoid.md` — [严重] 示例从 `?.`/try-catch/as any 改为 GDScript 等价模式
- `skills/principles/abstraction.md` — [严重] 示例从 interface/implements 改为 GDScript 基类继承
- `skills/workflow/testing.md` — [严重] 测试模板改为 Godot 测试场景脚本模式
- `skills/principles/stub-management.md` — [重要] STUB 示例改为 GDScript 模式

**变更理由**: 初次转化时仅填充了项目专属 TODO 占位符，但通用模板中原有的 TypeScript/Web 示例和概念未替换

**影响范围**: 全局 — 所有 AI 在遵循这些 skill 时将使用正确的 GDScript 模式

---

### 2026-03-08 — AI:Cursor

**任务**: 初始化项目规范，从通用模板转化为节奏牌专属规范

**变更文件**:
- `RULES.md` — 更新 TEMPLATE_STATUS 为 INITIALIZED:节奏牌
- `skills/project/file-structure.md` — 填充节奏牌项目目录结构
- `skills/project/code-style.md` — 填充 GDScript 文件结构顺序
- `skills/principles/type-safety.md` — 新增 GDScript 静态类型标注规则
- `skills/principles/naming.md` — 填充 GDScript 文件命名规则
- `skills/principles/layering.md` — 填充四层架构
- `skills/principles/data-separation.md` — 填充 data/ 目录结构
- `skills/principles/performance.md` — 填充节奏游戏性能预算
- `skills/workflow/collaboration.md` — 填充技术栈（Godot 4.5 + GDScript）
- `skills/workflow/git-commit.md` — 填充 scope 定义
- `STATUS.md` — 新建，项目当前状态快照
- `CHANGELOG.md` — 新建（本文件），第一条变更记录

**影响范围**: 全局（AI 开发规范体系初始化）
