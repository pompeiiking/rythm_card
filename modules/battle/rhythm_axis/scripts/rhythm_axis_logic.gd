extends RefCounted
## 节奏轴 - 轴逻辑
## 管理"滑动中的音乐块"，推进进度，块到达判定区时通过事件通知

const _MusicBlockScript = preload("res://modules/battle/rhythm_axis/scripts/music_block.gd")

var _sliding_blocks: Array[MusicBlock] = []
var _extend_distance: float = 50.0
var _hit_zone_x: float = 700.0

# ========== 初始化 ==========

func set_extend_params(hit_zone_x: float, extend_distance: float) -> void:
	_hit_zone_x = hit_zone_x
	_extend_distance = extend_distance

func clear_blocks() -> void:
	_sliding_blocks.clear()
	if OS.is_debug_build():
		print("[RhythmAxisLogic] 已清理所有块")

# ========== 块来源 ==========

func add_block(block_data: Dictionary) -> void:
	var block: RefCounted = _MusicBlockScript.from_data(block_data)
	_sliding_blocks.append(block)

func get_sliding_blocks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for block in _sliding_blocks:
		result.append({
			"block_id": block.block_id,
			"emit_time": block.emit_time,
			"hit_target_time": block.hit_target_time,
			"slide_duration": block.slide_duration,
			"is_judged": false
		})
	return result

func mark_block_judged(block_id: String) -> void:
	for i in range(_sliding_blocks.size()):
		var block: MusicBlock = _sliding_blocks[i]
		if block.block_id == block_id:
			_sliding_blocks.remove_at(i)
			break

# ========== 每帧更新 ==========

func update(current_time: float) -> void:
	# 记录本帧到达判定区的块，避免重复触发
	var reached_block_ids: Array[String] = []
	
	var still_sliding: Array[MusicBlock] = []
	for block in _sliding_blocks:
		var reached: bool = block.update_progress(current_time)
		if reached:
			# 块到达判定区，标记但不立即移除
			# 由 mark_block_judged() 显式移除，或由 clear_blocks() 清理
			reached_block_ids.append(block.block_id)
			EventBus.fire("rhythm:block_reached_zone", _block_data_from(block))
		else:
			still_sliding.append(block)
	_sliding_blocks = still_sliding
	
	EventBus.fire("rhythm:check_miss", {"current_time": current_time})

func _block_data_from(block: MusicBlock) -> Dictionary:
	return {
		"block_id": block.block_id,
		"emit_time": block.emit_time,
		"hit_target_time": block.hit_target_time,
		"slide_duration": block.slide_duration
	}
