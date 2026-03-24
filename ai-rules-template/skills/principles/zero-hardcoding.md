---
name: zero-hardcoding
description: 所有可变值必须来自配置或常量，禁止魔术数字和魔术字符串。写任何新代码时加载。
metadata:
  priority: L2
  category: principles
  depends: naming
---

# 零硬编码（Zero Hardcoding）

## 规则

- **所有可变值必须来自配置文件、环境变量或命名常量**，组件/函数内部不允许出现裸数字或裸字符串
- **如果一个值在两个以上地方出现，必须提取为常量或配置项**
- **所有配置通过统一的配置读取接口获取**，不直接 `fs.readFile` 或硬编码路径
- **唯一例外**：构建工具的本地配置（如本地开发端口号）、测试中的断言值

## 示例

✅ 正确：
```gdscript
# 常量定义在文件顶部或统一配置中
const MAX_HAND_SIZE: int = 10
const DEFAULT_BPM: float = 120.0
const PERFECT_WINDOW_MS: float = 50.0
const CARD_DATA_DIR: String = "res://data/cards/"

func draw_cards(count: int) -> void:
	for i in range(count):
		if hand.size() >= MAX_HAND_SIZE:
			break
		_draw_single_card()
```

❌ 错误：
```gdscript
func draw_cards(count: int) -> void:
	for i in range(count):
		if hand.size() >= 10:  # 魔术数字：10是什么？最大手牌？
			break

var bpm = 120.0  # 硬编码在业务代码中，应来自配置
var path = "res://data/cards/fireball.tres"  # 硬编码路径散落在业务逻辑中
```

## 判断标准

遇到一个值时问自己：
1. "这个值将来可能变吗？" → 是 → 提取为配置
2. "这个值在别处也用了吗？" → 是 → 提取为常量
3. "看到这个值能立刻理解含义吗？" → 否 → 用命名常量替代

## 提交前检查清单

- [ ] 代码中没有裸数字（除 0、1、-1 用于索引/条件判断）
- [ ] 代码中没有裸字符串（除日志消息和错误消息）
- [ ] URL、颜色值、尺寸、延时等全部来自配置或常量
- [ ] 同一个值没有在多个文件中重复出现
