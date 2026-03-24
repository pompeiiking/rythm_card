extends HitInputStrategy
class_name MultiKeyInputStrategy
## 多键输入策略
## 需要同时按下所有指定按键时才触发判定

var _keys: Array = []

func _init(key_codes: Array = []) -> void:
	_keys = key_codes

func set_keys(key_codes: Array) -> void:
	_keys = key_codes

## 获取该策略需要的按键列表（实现接口）
func get_required_keys() -> Array:
	return _keys

## 检查当前输入是否满足判定条件（实现接口）
func check_input() -> bool:
	if _keys.is_empty():
		return false
	for key in _keys:
		if not Input.is_key_pressed(key):
			return false
	return true

## 获取按键描述（实现接口）
func get_input_description() -> String:
	if _keys.is_empty():
		return "无按键"
	var desc: String = "同时按 "
	for i in range(_keys.size()):
		desc += get_key_name_static(_keys[i])
		if i < _keys.size() - 1:
			desc += " + "
	return desc
