---
name: performance
description: 执行频率意识、高频路径禁忌、精确订阅、异步加载策略。涉及渲染循环或高频调用路径时加载。
metadata:
  priority: L3
  category: principles
---

# 性能意识

## 规则

- **新增代码时必须考虑其执行频率** — 一次性初始化 vs 每帧渲染 vs 每次交互，策略完全不同
- **高频执行路径（`_process` / `_physics_process`）禁止**：分配新对象（`.new()`）、创建新 Array/Dictionary、字符串拼接、`load()` 资源、`JSON.parse_string()`
- **EventBus 事件精确订阅** — 只监听模块真正需要的事件，避免无关事件触发回调
- **非关键资源使用 `ResourceLoader.load_threaded_request` 异步加载** — 不阻塞主线程

## 示例

✅ 正确：
```gdscript
# 高频路径 — 预分配变量，避免每帧分配
var _temp_position := Vector2.ZERO  # 复用
var _cached_beat_interval: float = 0.0

func _process(delta: float) -> void:
	_temp_position.x = target_x
	_temp_position.y = target_y
	global_position = _temp_position  # 修改已有对象

# 一次性初始化时预计算
func initialize() -> void:
	_cached_beat_interval = 60.0 / bpm  # 初始化时计算，不在 _process 中重复算

# 精确事件订阅 — 只订阅需要的事件
func _subscribe_events() -> void:
	EventBus.listen("rhythm:beat", self, "_on_beat")  # 只订阅节拍事件
```

❌ 错误：
```gdscript
# 高频路径 — 每帧分配新对象
func _process(delta: float) -> void:
	var pos = Vector2(target_x, target_y)  # 每帧 new！
	var beat_interval = 60.0 / bpm  # 每帧重复计算不变的值
	global_position = pos

# 在 _process 中加载资源
func _process(delta: float) -> void:
	var texture = load("res://assets/card.png")  # 每帧都加载！严重性能问题

# 在 _process 中进行字符串操作
func _process(delta: float) -> void:
	var debug_msg = "Position: " + str(position) + " HP: " + str(hp)  # 每帧拼接字符串
```

## 执行频率分类

| 频率 | 典型场景 | 允许的操作 | 禁止的操作 |
|------|---------|-----------|-----------|
| 一次性 | `_ready()`、`initialize()`、模块加载 | 任何操作（load、new、解析等） | 无限制 |
| 低频 | 按钮点击、出牌、选择节点 | 场景实例化、资源加载、UI更新 | 无限制 |
| 中频 | 节拍事件（BPM 120 = 每0.5秒） | 轻量计算、状态更新、信号发送 | 场景实例化、大量节点操作 |
| 高频 | `_process` / `_physics_process`（60fps） | 纯数学计算、复用变量、位置更新 | `.new()`、`load()`、字符串拼接、Array/Dict创建 |

## 项目专属性能预算

```
- 帧率: 稳定 60fps（节奏系统依赖精确帧时序，掉帧会影响判定）
- 节奏判定延迟: < 16ms（1帧以内，音频与视觉同步）
- 场景切换: < 2s（探索→战斗、战斗→结算）
- 内存占用: 运行时 < 512MB（2D 游戏）
- 卡牌数据加载: 启动时一次性加载全部卡牌数据到内存（数量可控 < 500 张）
```

**节奏系统特别注意**：
- `_process` / `_physics_process` 中的节奏计算是最高频路径（每帧执行）
- 节拍判定窗口计算禁止使用对象分配、字符串操作
- 音频回调和节拍同步必须在主线程完成，避免异步延迟

## 提交前检查清单

- [ ] 新代码已评估执行频率（一次性/低频/中频/高频）
- [ ] `_process` / `_physics_process` 中没有 `.new()`、`load()`、字符串拼接、新建容器
- [ ] EventBus 事件订阅是精确的，只监听真正需要的事件
- [ ] 非关键资源使用了 `ResourceLoader.load_threaded_request` 异步加载
- [ ] 节奏判定相关的高频计算使用了预分配变量
