extends RefCounted
class_name LinearBeatStrategy
## 线性节拍策略
## 每个节拍强度相同，适合基础节奏

# 当前是第几拍（从 0 开始）
var _current_beat: int = 0

# 每小节几拍（默认 4/4 拍）
var _beats_per_measure: int = 4

func _init() -> void:
	pass

func get_beat_data() -> Dictionary:
	# 计算当前拍在小节中的位置（0 到 beats_per_measure-1）
	var beat_in_measure: int = _current_beat % _beats_per_measure
	
	# 线性节奏：每拍强度相同
	var beat_type: String = "normal"
	var intensity: float = 1.0
	
	# 第一拍稍微强一点（可选）
	if beat_in_measure == 0:
		beat_type = "downbeat"
		intensity = 1.2
	
	return {
		"beat_type": beat_type,
		"intensity": intensity,
		"beat_number": _current_beat,
		"beat_in_measure": beat_in_measure
	}

func advance_beat() -> void:
	_current_beat += 1

func reset() -> void:
	_current_beat = 0

func set_beats_per_measure(beats: int) -> void:
	_beats_per_measure = beats
