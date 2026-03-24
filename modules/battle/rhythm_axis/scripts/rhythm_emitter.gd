extends RefCounted
class_name RhythmEmitter
## 节奏轴 - 发射器
## 按节拍向节奏轴发射音乐块，发出 rhythm:block_emitted 事件

var _is_running: bool = false
var _block_id_counter: int = 0
var _bpm: float = 120.0           # 默认值，会被配置覆盖
var _slide_duration: float = 1.0   # 默认值，会被配置覆盖

# ========== 生命周期（由主模块调用） ==========

func start() -> void:
	_is_running = true
	_block_id_counter = 0

func stop() -> void:
	_is_running = false

# ========== 配置 ==========

func set_bpm(bpm: float) -> void:
	_bpm = bpm

func set_slide_duration(seconds: float) -> void:
	_slide_duration = seconds

# ========== 发射逻辑 ==========

## 在节拍点调用，发射一个音乐块
## 返回该块的 hit_target_time（到达判定区的目标时间）
func emit_block() -> Dictionary:
	if not _is_running:
		return {}
	_block_id_counter += 1
	var block_id: String = "block_%d" % _block_id_counter
	var emit_time: float = Time.get_ticks_msec() / 1000.0
	var hit_target_time: float = emit_time + _slide_duration
	var block_data := {
		"block_id": block_id,
		"emit_time": emit_time,
		"hit_target_time": hit_target_time,
		"slide_duration": _slide_duration
	}
	print("[RhythmEmitter] 发射块: ", block_id, " 目标时间: ", hit_target_time)
	EventBus.fire("rhythm:block_emitted", block_data)
	return block_data
