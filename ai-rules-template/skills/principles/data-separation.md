---
name: data-separation
description: 数据文件与代码文件严格分离，通过接口访问数据，数据格式变化不影响业务逻辑。涉及数据文件或配置时加载。
metadata:
  priority: L2
  category: principles
  depends: layering
---

# 数据与逻辑分离

## 规则

- **core/ 和 modules/ 下不允许出现数据文件**（.tres/.json 数据应放在 data/ 目录）
- **data/ 目录下不允许出现代码文件**（.gd 脚本）
- **模块不直接硬编码数据文件路径**，通过常量或配置定义数据路径，便于集中管理
- **数据格式变化不应导致业务逻辑代码修改** — 格式转换在数据加载层处理

## 示例

✅ 正确：
```gdscript
# 数据加载器 — 业务层不关心数据文件的具体格式
class_name CardDataLoader
extends RefCounted

const CARD_DATA_DIR: String = "res://data/cards/"

func load_card(card_id: String) -> Dictionary:
	var path := CARD_DATA_DIR + card_id + ".tres"
	if not ResourceLoader.exists(path):
		push_warning("[CardDataLoader] 卡牌不存在: %s" % path)
		return {}
	var resource = load(path)
	return _normalize(resource)

func _normalize(resource: Resource) -> Dictionary:
	# 格式转换封装在数据层，业务层拿到的是统一结构
	return {
		"id": resource.card_id,
		"name": resource.card_name,
		"type": resource.card_type,
		"cost": resource.cost,
	}
```

❌ 错误：
```gdscript
# 业务逻辑直接硬编码路径、直接处理格式
func get_attack_cards() -> Array:
	var data = load("res://data/cards/attack/fireball.tres")  # 硬编码路径
	return [{"name": data.get("n"), "cost": data.get("c")}]  # 业务层处理原始格式
```

## 项目数据目录结构

```
data/
├── cards/           # 卡牌数据库（每张卡一个 .tres 或统一 .json）
│   ├── attack/      # 攻击牌
│   ├── defense/     # 防御牌
│   ├── buff/        # 增益牌
│   ├── debuff/      # 减益牌
│   └── special/     # 特殊牌
├── characters/      # 角色/敌人数据
│   ├── enemies/     # 敌人属性与行为定义
│   └── bosses/      # Boss 数据
├── events/          # 局外随机事件定义
│   ├── encounters/  # 遭遇事件
│   └── shops/       # 商店数据
└── configs/         # 模块运行配置
    ├── rhythm_config.tres   # 节奏系统参数（BPM、判定窗口等）
    ├── battle_config.tres   # 战斗系统参数
    └── run_config.tres      # Run 探索参数
```

**数据格式约定**：
- 静态游戏数据优先使用 Godot Resource（`.tres`），便于编辑器直接编辑
- 批量数据可使用 `.json`，通过数据访问层（DataLoader）加载
- 配置参数使用自定义 Resource 类型，带 `@export` 属性

## 提交前检查清单

- [ ] 新增的数据文件（.tres/.json）放在了 data/ 目录下，不在 core/ 或 modules/ 中
- [ ] 数据文件路径通过常量定义，不在业务代码中硬编码散落的 `"res://data/..."` 路径
- [ ] 数据格式的解析/转换逻辑在数据加载层，不在业务模块中
- [ ] 更换数据格式（如 .tres → .json）只需改数据加载层实现
