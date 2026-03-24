extends HitInputStrategy
class_name SingleKeyInputStrategy
## 单键输入策略
## 只有按下指定按键时才触发判定

signal key_pressed

var _key: int = 0

func _init(key_code: int = 0) -> void:
	_key = key_code

func set_key(key_code: int) -> void:
	_key = key_code

## 报告按键按下（由外部调用）
func report_key_pressed(key_code: int) -> bool:
	key_pressed.emit()
	return true

## 获取该策略需要的按键列表（实现接口）
func get_required_keys() -> Array:
	return [_key]

## 检查当前输入是否满足判定条件（实现接口）
## 只有按下配置的单键时才触发判定
func check_input() -> bool:
	if _key == 0:
		return false
	# 直接检测配置的按键是否被按下
	return Input.is_key_pressed(_key)

## 获取按键描述（实现接口）
func get_input_description() -> String:
	return "按 " + get_key_name_static(_key)
