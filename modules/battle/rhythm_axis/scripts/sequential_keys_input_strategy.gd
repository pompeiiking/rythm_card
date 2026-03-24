extends HitInputStrategy
class_name SequentialKeysInputStrategy
## 顺序按键输入策略
## 需要按顺序先后按下所有指定按键才能触发判定

signal key_progress(index: int, total: int)

var _keys: Array = []                    # 按键顺序列表
var _pressed_index: int = 0              # 当前按到了第几个键
var _last_press_time: float = 0          # 上一次按键时间
var _completed_time: float = 0          # 完成所有按键的时间
var _timeout: float = 1.0                # 超时时间（秒），超时后重新开始计数
var _valid_duration: float = 0.5         # 判定有效时长（秒），完成后多久内必须判定

func _init(key_codes: Array = [], timeout: float = 1.0) -> void:
	_keys = key_codes.duplicate()
	_pressed_index = 0
	_timeout = timeout
	_completed_time = 0

## 设置按键顺序
func set_keys(key_codes: Array) -> void:
	_keys = key_codes.duplicate()
	reset()

## 设置超时时间
func set_timeout(timeout: float) -> void:
	_timeout = timeout

## 重置按键计数
func reset() -> void:
	_pressed_index = 0

## 获取当前进度（第几个/总共）
func get_progress() -> Dictionary:
	return {
		"current": _pressed_index,
		"total": _keys.size(),
		"completed": _pressed_index >= _keys.size()
	}

## 获取该策略需要的按键列表（实现接口）
func get_required_keys() -> Array:
	return _keys

## 报告按键按下（由外部调用）
## 返回 true 表示顺序已完成
func report_key_pressed(key_code: int) -> bool:
	if _keys.is_empty():
		return false
	
	var current_time: float = Time.get_ticks_msec() / 1000.0
	
	# 检查是否超时
	if current_time - _last_press_time > _timeout and _last_press_time > 0:
		reset()
	
	# 检查按下的键是否匹配当前需要的键
	if _pressed_index < _keys.size() and key_code == _keys[_pressed_index]:
		_last_press_time = current_time
		_pressed_index += 1
		key_progress.emit(_pressed_index, _keys.size())
		
		# 如果刚按下的是最后一个键，记录完成时间
		if _pressed_index >= _keys.size():
			_completed_time = current_time
			return true
	else:
		# 按错了键，重置顺序
		if _pressed_index > 0:
			reset()
	
	return false

## 设置判定有效时长
func set_valid_duration(duration: float) -> void:
	_valid_duration = duration

## 检查当前输入是否满足判定条件（实现接口）
## 不再需要传入键码，检查是否在有效时间内即可
func check_input() -> bool:
	if _keys.is_empty():
		return false
	
	# 检查是否已完成所有按键
	if _pressed_index >= _keys.size():
		# 检查是否在有效时间内
		var current_time: float = Time.get_ticks_msec() / 1000.0
		return (current_time - _completed_time) <= _valid_duration
	
	return false

## 获取按键描述（实现接口）
func get_input_description() -> String:
	if _keys.is_empty():
		return "无"
	
	var desc: String = "依次按: "
	for i in range(_keys.size()):
		if i > 0:
			desc += " → "
		desc += get_key_name_static(_keys[i])
	return desc
