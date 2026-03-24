extends Node
class_name BeatGenerator
## 节拍生成器
## 按固定 BPM 发送 rhythm:beat 事件
## 可通过 set_generator_strategy() 切换不同的节奏算法

# ========== 配置 ==========
const DEFAULT_BPM: float = 120.0
const _LinearBeatStrategy = preload("res://modules/battle/rhythm_axis/scripts/linear_beat_strategy.gd")

# ========== 状态 ==========
var _is_initialized: bool = false
var _is_running: bool = false
var _bpm: float = DEFAULT_BPM

# 节拍策略（抽象接口，可替换）
var _strategy: RefCounted = null

# 定时器
var _beat_timer: Timer = null

# ========== 生命周期 ==========

func initialize() -> void:
	if _is_initialized:
		return
	_setup_strategy()
	_setup_timer()
	_subscribe_events()
	_is_initialized = true
	if OS.is_debug_build():
		print("[BeatGenerator] 初始化完成, BPM=", _bpm)

func start() -> void:
	if not _is_initialized:
		push_error("[BeatGenerator] 未初始化")
		return
	_is_running = true
	_beat_timer.start()
	if OS.is_debug_build():
		print("[BeatGenerator] 启动")

func stop() -> void:
	_is_running = false
	if _beat_timer != null:
		_beat_timer.stop()

func reset_strategy() -> void:
	if _strategy != null:
		_strategy.reset()
	if OS.is_debug_build():
		print("[BeatGenerator] 策略已重置")

func cleanup() -> void:
	_unsubscribe_events()
	_beat_timer.stop()
	_beat_timer.queue_free()
	_beat_timer = null
	_strategy = null
	_is_initialized = false

# ========== 配置 ==========

func set_bpm(new_bpm: float) -> void:
	_bpm = new_bpm
	# 只有在定时器已创建后才更新间隔
	if _beat_timer != null:
		_update_timer_interval()

func get_bpm() -> float:
	return _bpm

# ========== 私有方法 ==========

func _setup_strategy() -> void:
	# 默认使用线性节拍策略
	# 以后可以通过 set_generator_strategy() 替换为其他算法
	_strategy = _LinearBeatStrategy.new()

func _setup_timer() -> void:
	_beat_timer = Timer.new()
	_beat_timer.autostart = false
	_beat_timer.one_shot = false
	add_child(_beat_timer)
	_beat_timer.timeout.connect(_on_beat_timer_timeout)
	_update_timer_interval()

func _update_timer_interval() -> void:
	# BPM 转间隔：60 / BPM = 每拍的秒数
	var interval: float = 60.0 / _bpm
	_beat_timer.wait_time = interval
	if OS.is_debug_build():
		print("[BeatGenerator] 节拍间隔: ", interval, "秒")

func _subscribe_events() -> void:
	pass

func _unsubscribe_events() -> void:
	pass

# ========== 事件处理 ==========

func _on_beat_timer_timeout() -> void:
	if not _is_running:
		return
	
	# 让策略计算当前节拍的强度/类型
	var beat_data: Dictionary = {}
	if _strategy != null:
		beat_data = _strategy.get_beat_data()
	
	# 发送节拍事件
	print("[BeatGenerator] 发送节拍事件, 数据: ", beat_data)
	EventBus.fire("rhythm:beat", beat_data)
	
	# 让策略推进到下一拍
	if _strategy != null:
		_strategy.advance_beat()
	
	if OS.is_debug_build():
		print("[BeatGenerator] 节拍触发: ", beat_data)
