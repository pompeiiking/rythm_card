extends Node
class_name RhythmAxisModule
## 节奏轴模块
## 发射器发射音乐块 → 块沿轴滑到点击区 → 点击区判定（Perfect/Good/Miss）
## 通过事件与外部协作，不直接依赖其他模块。详见模块内 README.md

# ========== 预加载脚本 ==========
# 使用 preload 预加载所有脚本
const _ScriptEmitter = preload("res://modules/battle/rhythm_axis/scripts/rhythm_emitter.gd")
const _ScriptHitZone = preload("res://modules/battle/rhythm_axis/scripts/hit_zone.gd")
const _ScriptAxisLogic = preload("res://modules/battle/rhythm_axis/scripts/rhythm_axis_logic.gd")
const _ScriptBeatGenerator = preload("res://modules/battle/rhythm_axis/scripts/beat_generator.gd")
const _ScriptEffectManager = preload("res://modules/battle/rhythm_axis/scripts/effect_manager.gd")
const _ScriptSingleKeyInput = preload("res://modules/battle/rhythm_axis/scripts/single_key_input_strategy.gd")
const _ScriptMultiKeyInput = preload("res://modules/battle/rhythm_axis/scripts/multi_key_input_strategy.gd")
const _ScriptSequentialKeysInput = preload("res://modules/battle/rhythm_axis/scripts/sequential_keys_input_strategy.gd")

# ========== 配置 ==========
const _CONFIG_PATH := "res://data/configs/rhythm_axis_config.tres"
const _EFFECT_CONFIG_PATH := "res://data/configs/rhythm_effect_config.tres"

const DEFAULT_CONFIG: Dictionary = {
	"bpm": 120.0,
	"slide_duration": 1.5,
	"axis_length": 800.0,
	"axis_y": 300.0,
	"hit_zone_x": 700.0,
	"block_size": 40.0,
	"axis_line_width": 4.0,
	"axis_line_color": Color(1, 1, 1, 1),
	"hit_zone_color": Color(1, 0, 0, 0.5),
	"hit_zone_size_multiplier": 1.5,
	"hit_zone_extend_distance": 50.0,
	"block_color": Color(0, 1, 1, 1),
	"judge_perfect_window": 0.08,
	"judge_good_window": 0.18,
	"judge_miss_after": 0.3
}

# ========== 状态 ==========
var _is_initialized: bool = false
var _is_running: bool = false
var _config: Dictionary = {}

# ========== 子逻辑 ==========
var _emitter: RefCounted = null
var _hit_zone: RefCounted = null
var _axis_logic: RefCounted = null
var _beat_generator: Node = null
var _effect_manager: Node = null

# ========== 可视化节点 ==========
var _axis_line: Line2D = null
var _hit_zone_marker: ColorRect = null
var _block_nodes: Dictionary = {}  # block_id -> Node

# ========== 生命周期 ==========

func initialize() -> void:
	if _is_initialized:
		return
	_load_config()
	_setup_components()
	_subscribe_events()
	_is_initialized = true
	if OS.is_debug_build():
		print("[RhythmAxisModule] 初始化完成")

func start() -> void:
	if not _is_initialized:
		push_error("[RhythmAxisModule] 未初始化")
		return
	_is_running = true
	if _emitter != null:
		_emitter.start()
	if _hit_zone != null:
		_hit_zone.start()
	if _beat_generator != null:
		_beat_generator.start()
	if OS.is_debug_build():
		print("[RhythmAxisModule] 启动")

func stop() -> void:
	_is_running = false
	if _emitter != null:
		_emitter.stop()
	if _hit_zone != null:
		_hit_zone.stop()
	if _beat_generator != null:
		_beat_generator.stop()
	# 清理所有块节点和动效
	if _effect_manager != null:
		_effect_manager.clear_all_blocks()
	for block_id in _block_nodes.keys():
		var node = _block_nodes[block_id]
		if is_instance_valid(node):
			node.queue_free()
	_block_nodes.clear()
	# 清理轴逻辑中的块数据
	if _axis_logic != null:
		_axis_logic.clear_blocks()
	# 重置节拍策略计数器
	if _beat_generator != null:
		_beat_generator.reset_strategy()
	
	if OS.is_debug_build():
		print("[RhythmAxisModule] 已停止并清理")

func cleanup() -> void:
	# 先调用 stop 确保停止运行
	if _is_running:
		stop()
	
	# 清理可视化节点（必须手动删除，否则会泄漏）
	if is_instance_valid(_axis_line):
		_axis_line.queue_free()
		_axis_line = null
	if is_instance_valid(_hit_zone_marker):
		_hit_zone_marker.queue_free()
		_hit_zone_marker = null
	
	# 清理所有块节点
	for block_id in _block_nodes.keys():
		var node = _block_nodes[block_id]
		if is_instance_valid(node):
			node.queue_free()
	_block_nodes.clear()
	
	# 清理子组件
	if _beat_generator != null:
		_beat_generator.cleanup()
		_beat_generator = null
	if _effect_manager != null:
		_effect_manager.clear_all_blocks()
		if is_instance_valid(_effect_manager):
			_effect_manager.queue_free()
		_effect_manager = null
	
	# 清理内部逻辑对象
	_emitter = null
	_hit_zone = null
	_axis_logic = null
	
	# 最后取消事件订阅
	_unsubscribe_events()
	
	_is_initialized = false

# ========== 私有方法 ==========

func _load_config() -> void:
	_config = DEFAULT_CONFIG.duplicate()

	if ResourceLoader.exists(_CONFIG_PATH):
		var loaded = load(_CONFIG_PATH)
		if loaded != null:
			# 使用 get() 检查 Resource 属性是否存在（返回 null 表示不存在）
			if loaded.get("bpm") != null:
				_config["bpm"] = loaded.bpm
			if loaded.get("slide_duration") != null:
				_config["slide_duration"] = loaded.slide_duration
			if loaded.get("axis_length") != null:
				_config["axis_length"] = loaded.axis_length
			if loaded.get("axis_y") != null:
				_config["axis_y"] = loaded.axis_y
			if loaded.get("hit_zone_x") != null:
				_config["hit_zone_x"] = loaded.hit_zone_x
			if loaded.get("block_size") != null:
				_config["block_size"] = loaded.block_size
			if loaded.get("axis_line_width") != null:
				_config["axis_line_width"] = loaded.axis_line_width
			if loaded.get("axis_line_color") != null:
				_config["axis_line_color"] = loaded.axis_line_color
			if loaded.get("hit_zone_color") != null:
				_config["hit_zone_color"] = loaded.hit_zone_color
			if loaded.get("hit_zone_size_multiplier") != null:
				_config["hit_zone_size_multiplier"] = loaded.hit_zone_size_multiplier
			if loaded.get("hit_zone_extend_distance") != null:
				_config["hit_zone_extend_distance"] = loaded.hit_zone_extend_distance
			if loaded.get("block_color") != null:
				_config["block_color"] = loaded.block_color
			if loaded.get("judge_perfect_window") != null:
				_config["judge_perfect_window"] = loaded.judge_perfect_window
			if loaded.get("judge_good_window") != null:
				_config["judge_good_window"] = loaded.judge_good_window
			if loaded.get("judge_miss_after") != null:
				_config["judge_miss_after"] = loaded.judge_miss_after
			# 加载输入配置
			if loaded.get("input_key") != null:
				_config["input_key"] = loaded.input_key
			if loaded.get("input_keys") != null:
				_config["input_keys"] = loaded.input_keys
			if loaded.get("input_sequence_keys") != null:
				_config["input_sequence_keys"] = loaded.input_sequence_keys
			if loaded.get("input_sequence_timeout") != null:
				_config["input_sequence_timeout"] = loaded.input_sequence_timeout

	if OS.is_debug_build():
		print("[RhythmAxisModule] 加载配置: BPM=", _config["bpm"], " slide_duration=", _config["slide_duration"])

func _setup_components() -> void:
	if _emitter != null:
		return

	# 使用延迟加载获取脚本
	_emitter = _ScriptEmitter.new()
	_emitter.set_bpm(_config["bpm"])
	_emitter.set_slide_duration(_config["slide_duration"])

	_hit_zone = _ScriptHitZone.new()
	_hit_zone.set_judge_windows(
		_config["judge_perfect_window"],
		_config["judge_good_window"],
		_config["judge_miss_after"]
	)
	# 从配置加载输入策略
	_setup_input_strategy()

	_axis_logic = _ScriptAxisLogic.new()
	# 不再直接传入 HitZone，改为事件驱动
	_axis_logic.set_extend_params(_config["hit_zone_x"], _config.get("hit_zone_extend_distance", 50.0))

	_beat_generator = _ScriptBeatGenerator.new()
	add_child(_beat_generator)
	_beat_generator.set_bpm(_config["bpm"])
	_beat_generator.initialize()

	_effect_manager = _ScriptEffectManager.new()
	add_child(_effect_manager)
	_effect_manager.set_block_config(_config["block_size"], _config["block_color"], _config["axis_y"])
	_effect_manager.set_hit_zone_info(_config["hit_zone_x"], _config["axis_y"])
	# 设置判定区扩展距离，让块在判定后继续往后滑动
	_effect_manager.set_extend_distance(_config.get("hit_zone_extend_distance", 50.0))
	_load_effect_config()
	
	_setup_visualization()

func _load_effect_config() -> void:
	if ResourceLoader.exists(_EFFECT_CONFIG_PATH):
		var loaded = load(_EFFECT_CONFIG_PATH)
		if loaded != null:
			_effect_manager.set_config(loaded)
			if OS.is_debug_build():
				print("[RhythmAxisModule] 加载动效配置成功")

func _setup_visualization() -> void:
	_axis_line = Line2D.new()
	_axis_line.add_point(Vector2(0, _config["axis_y"]))
	_axis_line.add_point(Vector2(_config["axis_length"], _config["axis_y"]))
	_axis_line.width = _config["axis_line_width"]
	_axis_line.default_color = _config["axis_line_color"]
	add_child(_axis_line)
	
	_hit_zone_marker = ColorRect.new()
	_hit_zone_marker.position = Vector2(
		_config["hit_zone_x"] - _config["block_size"] * _config.get("hit_zone_size_multiplier", 1.0) / 2,
		_config["axis_y"] - _config["block_size"] * _config.get("hit_zone_size_multiplier", 1.0) / 2
	)
	_hit_zone_marker.size = Vector2(
		_config["block_size"] * _config.get("hit_zone_size_multiplier", 1.0),
		_config["block_size"] * _config.get("hit_zone_size_multiplier", 1.0)
	)
	_hit_zone_marker.color = _config["hit_zone_color"]
	add_child(_hit_zone_marker)
	
	if OS.is_debug_build():
		print("[RhythmAxisModule] 可视化初始化完成，轴长度:", _config["axis_length"])

## 根据配置设置输入策略
func _setup_input_strategy() -> void:
	var input_key: int = _config.get("input_key", 0)
	var input_keys: Array = _config.get("input_keys", [])
	var input_sequence_keys: Array = _config.get("input_sequence_keys", [])
	var input_sequence_timeout: float = _config.get("input_sequence_timeout", 1.0)
	
	if not input_sequence_keys.is_empty():
		# 顺序按键判定模式（优先）
		set_sequential_keys_input(input_sequence_keys, input_sequence_timeout)
		if OS.is_debug_build():
			print("[RhythmAxisModule] 使用顺序按键判定: ", input_sequence_keys, " 超时:", input_sequence_timeout, "秒")
	elif not input_keys.is_empty():
		# 多键判定模式（同时按下）
		set_multi_key_input(input_keys)
		if OS.is_debug_build():
			print("[RhythmAxisModule] 使用多键判定: ", input_keys)
	elif input_key != 0:
		# 单键判定模式
		set_single_key_input(input_key)
		if OS.is_debug_build():
			print("[RhythmAxisModule] 使用单键判定: ", input_key)
	else:
		# 默认空格键
		set_single_key_input(KEY_SPACE)
		if OS.is_debug_build():
			print("[RhythmAxisModule] 使用默认空格键判定")

func _subscribe_events() -> void:
	EventBus.listen("rhythm:block_emitted", self, "_on_block_emitted")
	EventBus.listen("rhythm:beat", self, "_on_beat")
	EventBus.listen("rhythm:input_requested", self, "_on_input_requested")
	EventBus.listen("rhythm:input_judged", self, "_on_input_judged")
	# 新增：块到达判定区事件
	EventBus.listen("rhythm:block_reached_zone", self, "_on_block_reached_zone")
	# 新增：Miss 检查事件
	EventBus.listen("rhythm:check_miss", self, "_on_check_miss")

func _unsubscribe_events() -> void:
	EventBus.unlisten("rhythm:block_emitted", self)
	EventBus.unlisten("rhythm:beat", self)
	EventBus.unlisten("rhythm:input_requested", self)
	EventBus.unlisten("rhythm:input_judged", self)
	EventBus.unlisten("rhythm:block_reached_zone", self)
	EventBus.unlisten("rhythm:check_miss", self)

# ========== 事件处理 ==========

func _on_beat(_data: Dictionary) -> void:
	if not _is_running:
		return
	print("[RhythmAxisModule] 收到节拍事件，发射块")
	_emitter.emit_block()

func _on_block_emitted(block_data: Dictionary) -> void:
	if block_data.is_empty():
		return
	_axis_logic.add_block(block_data)
	
	var block_id: String = block_data.get("block_id", "")
	var block_node = _effect_manager.create_block_node(block_id, _config)
	add_child(block_node)
	_block_nodes[block_id] = block_node
	
	# 将块节点也添加到 effect_manager，用于判定时播放颜色变化效果
	_effect_manager.add_block(block_id, block_node)
	
	_effect_manager.play_emit_effect(block_node, block_id)
	
	if OS.is_debug_build():
		print("[RhythmAxisModule] 创建可视化块:", block_id)

# 新增：块到达判定区事件处理
func _on_block_reached_zone(block_data: Dictionary) -> void:
	if _hit_zone != null:
		_hit_zone.enter_block(block_data)

# 新增：Miss 检查事件处理
func _on_check_miss(data: Dictionary) -> void:
	if _hit_zone != null:
		_hit_zone.update_miss_check(data.get("current_time", 0.0))

func _on_input_requested(data: Dictionary) -> void:
	if not _is_running:
		return
	var key_code: int = data.get("key_code", 0)
	_hit_zone.judge_input(key_code)

func _on_input_judged(data: Dictionary) -> void:
	var block_id: String = data.get("block_id", "")
	var result: int = data.get("result", 3)
	var delta: float = data.get("delta", 0.0)

	# 标记块已判定，轴逻辑会将其移入已判定列表继续滑动
	_axis_logic.mark_block_judged(block_id)

	# 播放判定效果（变色 + 特效），effect_manager 内部会立即从自己的 _block_nodes 中移除
	# 但 rhythm_axis_module 中可能还有对同一 block_id 的引用
	_effect_manager.play_judge_effect(block_id, result, delta)

	# 立即从 rhythm_axis_module 的 _block_nodes 中移除，防止后续 _update_block_visuals 访问已销毁的节点
	_block_nodes.erase(block_id)

# ========== 每帧更新 ==========

func _process(_delta: float) -> void:
	if not _is_running or _axis_logic == null:
		return
	var current_time: float = Time.get_ticks_msec() / 1000.0
	_axis_logic.update(current_time)
	_update_block_visuals(current_time)

func _update_block_visuals(current_time: float) -> void:
	var sliding_data = _axis_logic.get_sliding_blocks()

	for block_data in sliding_data:
		var block_id: String = block_data.get("block_id", "")
		var emit_time: float = block_data.get("emit_time", 0.0)
		var slide_duration: float = block_data.get("slide_duration", 1.0)
		var is_judged: bool = block_data.get("is_judged", false)

		# 只处理未判定的块（已判定的块已经在 effect_manager 中销毁播放动效了）
		if is_judged:
			continue

		# 计算位置：正常滑动块从发射点到判定区
		var progress: float = (current_time - emit_time) / slide_duration
		progress = clamp(progress, 0.0, 1.0)
		var x_pos: float = progress * _config["hit_zone_x"]

		if _block_nodes.has(block_id):
			var node = _block_nodes[block_id]
			if not is_instance_valid(node):
				_block_nodes.erase(block_id)
				continue
			node.position.x = x_pos
			_effect_manager.update_block_effects(block_id, progress)
	
	# 清理无效引用
	var valid_ids: Array[String] = []
	for block_data in sliding_data:
		valid_ids.append(block_data.get("block_id", ""))
	
	var to_remove: Array[String] = []
	for block_id in _block_nodes.keys():
		if not block_id in valid_ids:
			to_remove.append(block_id)
	
	for block_id in to_remove:
		_block_nodes.erase(block_id)

# ========== 公共接口 ==========

## 设置判定输入策略（通用方法）
## 支持单键或多键判定策略
## 使用示例：
##   # 单键判定（空格键）
##   var single_key = SingleKeyInputStrategy.new(KEY_SPACE)
##   rhythm_module.set_input_strategy(single_key)
##   # 多键判定（A + S 同时按下）
##   var multi_key = MultiKeyInputStrategy.new([KEY_A, KEY_S])
##   rhythm_module.set_input_strategy(multi_key)
func set_input_strategy(strategy: RefCounted) -> void:
	if _hit_zone != null:
		_hit_zone.set_input_strategy(strategy)
		if OS.is_debug_build():
			print("[RhythmAxisModule] 设置输入策略: ", strategy.get_input_description())

## 获取当前输入策略
func get_input_strategy() -> RefCounted:
	if _hit_zone != null:
		return _hit_zone.get_input_strategy()
	return null

## 设置单键输入策略（快捷方法）
func set_single_key_input(key_code: int) -> void:
	var strategy = _ScriptSingleKeyInput.new(key_code)
	set_input_strategy(strategy)

## 设置多键输入策略（快捷方法）
func set_multi_key_input(key_codes: Array) -> void:
	var strategy = _ScriptMultiKeyInput.new(key_codes)
	set_input_strategy(strategy)

## 设置顺序按键输入策略（快捷方法）
## key_codes: 按键顺序数组，例如 [KEY_A, KEY_S, KEY_D]
## timeout: 超时时间（秒），超时后重新开始计数
func set_sequential_keys_input(key_codes: Array, timeout: float = 1.0) -> void:
	var strategy = _ScriptSequentialKeysInput.new(key_codes, timeout)
	set_input_strategy(strategy)

func get_effect_manager() -> Node:
	return _effect_manager
	
