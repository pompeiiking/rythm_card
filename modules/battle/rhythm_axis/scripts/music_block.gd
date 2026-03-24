extends RefCounted
class_name MusicBlock
## 节奏轴 - 音乐块
## 表示一个在轴上滑动的音乐块（数据与逻辑），不负责显示

var block_id: String = ""
var emit_time: float = 0.0
var hit_target_time: float = 0.0
var slide_duration: float = 1.0

# 当前逻辑进度 [0.0, 1.0]，0=刚发射，1=到达判定区
var _progress: float = 0.0

# ========== 工厂 ==========

static func from_data(data: Dictionary) -> RefCounted:
	var block := MusicBlock.new()
	block.block_id = data.get("block_id", "")
	block.emit_time = data.get("emit_time", 0.0)
	block.hit_target_time = data.get("hit_target_time", 0.0)
	block.slide_duration = data.get("slide_duration", 1.0)
	return block

# ========== 滑动逻辑 ==========

## 根据当前时间更新块在轴上的进度，返回是否已到达判定区
func update_progress(current_time: float) -> bool:
	if current_time <= emit_time:
		_progress = 0.0
		return false
	if current_time >= hit_target_time:
		_progress = 1.0
		return true
	_progress = (current_time - emit_time) / slide_duration
	return false

func get_progress() -> float:
	return _progress

