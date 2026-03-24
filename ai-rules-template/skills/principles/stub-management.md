---
name: stub-management
description: STUB标记的完整规范：格式、必填字段、记录要求、替换流程。写占位代码或新会话搜索STUB时加载。
metadata:
  priority: L1
  category: principles
  depends: changelog
---

# 禁止未标注的假实现（STUB管理）

## 问题背景

AI助手在开发中经常为了快速跑通流程而写假实现：空函数体、硬编码返回值、跳过错误处理。如果不标注，后续开发者/AI无法区分假代码和真实代码，导致隐患长期存在。

**铁律：项目中不允许存在任何未标注的假实现。**

## 规则

### 1. STUB标记格式（三要素缺一不可）

```
# STUB(日期): [原因] — [预计何时/由谁替换]
```

✅ 正确：
```gdscript
# STUB(2026-03-04): 战斗结算逻辑尚未实现 — 预计由 battle 模块开发时替换
func resolve_battle(battle_data: Dictionary) -> Dictionary:
	push_error("[BattleModule] resolve_battle 尚未实现")
	return {}
```

❌ 错误：
```gdscript
func resolve_battle(battle_data: Dictionary) -> Dictionary:
	return {"winner": 1}  # 没有任何标注，后人以为这是真实逻辑
```

### 2. 空函数体必须标注或抛出错误

- ✅ `push_error("[ModuleName] method_name 尚未实现")` → 调用时立刻暴露
- ✅ `# 设计上此方法为可选钩子，基类默认空实现` → 说明空是有意的
- ✅ `pass  # STUB(日期): 原因 — 替换计划` → 标注了的 pass
- ❌ 空函数体只有一个 `pass` 无任何说明 → 无法判断是遗漏还是有意

### 3. STUB必须同步记录到 STATUS.md

每次提交中如果包含STUB代码，在 STATUS.md 的"活跃STUB清单"中登记：
```
- `path/to/file:行号` — 原因 — 替换条件
```

### 4. 新会话STUB扫描

每次新会话开始时，AI应全局搜索 `// STUB` 关键词，检查是否有可以替换为真实实现的STUB。如果当前任务涉及的模块能解决某个STUB，应主动替换。

### 5. 禁止的假实现模式（即使标注STUB也不允许）

- `return {}` / `return null` / `return []` 且无 `push_error` 提示
- `print("TODO")` 当作实现
- 去掉类型注解来绕过类型检查以"快速通过"

## 提交前检查清单

- [ ] 所有占位实现都有 `// STUB(日期): 原因 — 替换计划` 标记
- [ ] 空函数体要么有标注说明，要么抛出 `Not implemented` 错误
- [ ] 新增的STUB已登记到 STATUS.md 的活跃STUB清单
- [ ] 检查了是否有已存在的STUB可以在本次任务中替换
