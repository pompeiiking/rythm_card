extends RefCounted
class_name HitZone
## 节奏轴 - 点击区（判定区）
## 管理进入判定区的音乐块，处理点击判定并发出 rhythm:input_judged

enum JudgeResult { NONE, PERFECT, GOOD, MISS }

# 输入策略（支持自定义单键或多键判定）
var _input_strategy: RefCounted = null

# 运行时配置（必须通过 set_judge_windows 设置，否则报错）
var _judge_perfect_window: float = 0.0
var _judge_good_window: float = 0.0
var _judge_miss_after: float = 0.0

var _is_running: bool = false
var _blocks_in_zone: Array[Dictionary] = []  # 当前在判定区内的块 { block_data, entered_at }

# ========== 配置 ==========

## 设置输入策略（必须在 start() 之前调用）
## 支持单键或多键判定策略
func set_input_strategy(strategy: RefCounted) -> void:
	_input_strategy = strategy

## 获取当前输入策略
func get_input_strategy() -> RefCounted:
	return _input_strategy

## 获取当前输入策略需要的按键列表
func get_required_keys() -> Array:
	if _input_strategy != null:
		return _input_strategy.get_required_keys()
	return []

func set_judge_windows(perfect: float, good: float, miss_after: float) -> void:
	_judge_perfect_window = perfect
	_judge_good_window = good
	_judge_miss_after = miss_after

# ========== 生命周期 ==========

func start() -> void:
	_is_running = true
	_blocks_in_zone.clear()

func stop() -> void:
	_is_running = false
	_blocks_in_zone.clear()

# ========== 块进入/离开 ==========

## 块进入判定区时由轴逻辑调用
func enter_block(block_data: Dictionary) -> void:
	if not _is_running:
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	_blocks_in_zone.append({"block_data": block_data, "entered_at": now})

## 移除已判定或超时的块
func remove_block(block_id: String) -> void:
	var new_list: Array[Dictionary] = []
	for entry in _blocks_in_zone:
		if entry.block_data.get("block_id", "") != block_id:
			new_list.append(entry)
	_blocks_in_zone = new_list

# ========== 判定逻辑 ==========

## 玩家在点击区输入时调用，返回判定结果并发送事件
## key_code: 当前按下的键码（用于顺序按键策略）
func judge_input(key_code: int = 0) -> Dictionary:
	if not _is_running:
		_fire_judge("", JudgeResult.MISS, 0.0)
		_reset_input_strategy_if_sequential()
		return {"result": JudgeResult.MISS, "block_id": "", "delta": 0.0}
	
	# 先报告按键给输入策略（用于顺序按键）
	if _input_strategy != null and key_code != 0:
		_input_strategy.report_key_pressed(key_code)
	
	# 检查输入策略是否满足
	if _input_strategy != null and not _input_strategy.check_input():
		# 输入不满足策略条件，不进行判定（返回空结果，不触发Miss）
		return {"result": JudgeResult.NONE, "block_id": "", "delta": 0.0}
	
	if _blocks_in_zone.is_empty():
		_fire_judge("", JudgeResult.MISS, 0.0)
		_reset_input_strategy_if_sequential()
		return {"result": JudgeResult.MISS, "block_id": "", "delta": 0.0}
	
	# 取最早进入的块做判定
	var entry: Dictionary = _blocks_in_zone[0]
	var block_data: Dictionary = entry.block_data
	var block_id: String = block_data.get("block_id", "")
	var hit_target_time: float = block_data.get("hit_target_time", 0.0)
	var now: float = Time.get_ticks_msec() / 1000.0
	var delta: float = now - hit_target_time
	var result: JudgeResult = _judge_delta(delta)
	remove_block(block_id)
	_fire_judge(block_id, result, delta)
	# 判定完成后重置顺序按键策略
	_reset_input_strategy_if_sequential()
	return {"result": result, "block_id": block_id, "delta": delta}

## 如果是顺序按键策略，重置进度
func _reset_input_strategy_if_sequential() -> void:
	if _input_strategy is SequentialKeysInputStrategy:
		_input_strategy.reset()

func _judge_delta(delta: float) -> JudgeResult:
	var abs_delta: float = abs(delta)
	if abs_delta <= _judge_perfect_window:
		return JudgeResult.PERFECT
	if abs_delta <= _judge_good_window:
		return JudgeResult.GOOD
	return JudgeResult.MISS

func _fire_judge(block_id: String, result: JudgeResult, delta: float) -> void:
	EventBus.fire("rhythm:input_judged", {
		"block_id": block_id,
		"result": result,
		"delta": delta
	})

## 检查未点击的块是否已超时（应自动判 Miss）
func update_miss_check(current_time: float) -> void:
	if not _is_running:
		return
	var to_remove: Array[Dictionary] = []
	for entry in _blocks_in_zone:
		var b: Dictionary = entry.block_data
		var bid: String = b.get("block_id", "")
		var hit_target: float = b.get("hit_target_time", 0.0)
		# 只有当块已经过了目标时间+超时窗口才算Miss
		# 如果玩家提前击打（负delta），不算Miss
		if current_time > hit_target + _judge_miss_after:
			to_remove.append(entry)
			_fire_judge(bid, JudgeResult.MISS, current_time - hit_target)
	for entry in to_remove:
		remove_block(entry.block_data.get("block_id", ""))
