---
name: anti-paranoid
description: bug修复的正确流程：追溯根因→修复→清理。区分架构级校验与补丁级校验，禁止防御性冗余代码。修复bug时加载。
metadata:
  priority: L1
  category: workflow
  depends: error-handling, stub-management
---

# 反防御式编程（Anti-Paranoid Coding）

## 问题背景

AI助手修bug时常见的"安全习惯"：遇到空值就到处加 `if x != null` 防御检查，遇到可能失败的操作就静默返回默认值，遇到类型问题就用 `Variant` 绕过。这些做法**掩盖了根因**，代码量膨胀，真正的bug被埋得更深。

**铁律：修完bug后，代码量应持平或减少。如果增加了，说明你在"贴补丁"而不是"修根因"。**

## 规则

### 1. Bug修复三步法

```
Step 1: 追溯根因
  → 这个错误最早从哪里产生？（不是从哪里被发现的）
  → 用调试日志/断点确认，不要猜

Step 2: 在根因处修复
  → 修复点应该尽可能接近错误的产生位置
  → 修完后下游的防御代码应该变得不需要

Step 3: 清理下游防御代码
  → 移除因该bug而添加的临时防御代码
  → 验证移除后功能仍正常
```

### 2. 区分两类校验

| 类型 | 含义 | 示例 | 允许？ |
|------|------|------|--------|
| **架构级校验** | 对外部输入/系统边界的校验，永远需要 | API参数校验、用户输入校验、文件格式校验 | ✅ 永远需要 |
| **补丁级校验** | 对系统内部传值的防御性检查，说明上游有bug | 函数内部 `if (!user) return` 但调用方保证传了user | ❌ 应修上游bug |

### 3. 禁止的"修bug"模式

❌ **空值防御滥用**：
```gdscript
# 问题：card_data 有时是 null
# 错误修法：到处加 null 检查
func _on_card_played(data) -> void:
	if data == null: return
	if not data.has("card_id"): return
	if data.card_id == null: return
	# ... 层层防御
# 正确修法：找到 card_data 为什么是 null，从发送事件的源头修
```

❌ **静默返回默认值**：
```gdscript
# 问题：加载卡牌数据偶尔失败
# 错误修法：静默返回空字典
func load_card(card_id: String) -> Dictionary:
	var resource = load("res://data/cards/" + card_id + ".tres")
	if resource == null:
		return {}  # 吞掉错误，调用方不知道加载失败了
# 正确修法：找到为什么加载失败（路径错？文件不存在？），从数据源修
```

❌ **Variant 绕过类型**：
```gdscript
# 问题：类型不匹配
# 错误修法：去掉类型声明，用 Variant 绕过
var result = broken_function()  # 去掉类型注解来"修"类型错误
# 正确修法：修正函数的返回类型或调用方的期望类型
```

## 示例

✅ 正确的bug修复：
```gdscript
# Bug: 卡牌列表偶尔显示空名称
# 追溯: 数据文件中 card_name 字段有时缺失
# 修复: 在数据加载层统一处理（架构级校验 — 外部数据边界）
func _normalize_card(resource: Resource) -> Dictionary:
	assert(resource.has_method("get"), "无效的卡牌资源")
	return {
		"name": resource.card_name if resource.card_name != "" else resource.card_id,
		"cost": resource.cost,
	}
# 效果: 业务层不需要任何空值防御，数据层保证了数据完整性
```

## 提交前检查清单

- [ ] bug的根因已定位，不是在症状处打补丁
- [ ] 修复点在错误产生位置附近，不在错误发现位置
- [ ] 修改后的代码量持平或减少（不是增加了大量防御代码）
- [ ] 新增的空值检查是架构级校验（外部输入边界），不是补丁级校验
- [ ] 没有通过堆叠 `if x != null` / 静默返回默认值 / 去掉类型注解 来掩盖根因
