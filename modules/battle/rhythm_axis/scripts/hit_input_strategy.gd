extends RefCounted
class_name HitInputStrategy
## 输入策略基类
## 定义判定输入的接口，支持单键、多键或顺序按键判定

## 获取该策略需要的按键列表（用于显示或输入绑定）
func get_required_keys() -> Array:
	push_error("HitInputStrategy.get_required_keys() 必须由子类实现")
	return []

## 检查当前输入是否满足判定条件
## 返回 true 表示可以进行判定
func check_input() -> bool:
	push_error("HitInputStrategy.check_input() 必须由子类实现")
	return false

## 获取按键描述（用于UI显示）
func get_input_description() -> String:
	return ""

## 报告按键按下（用于顺序按键策略）
## key_code: 按下的键码
## 返回 true 表示顺序判定已完成
func report_key_pressed(_key_code: int) -> bool:
	return false

## 获取当前进度（用于顺序按键策略）
func get_progress() -> Dictionary:
	return {"current": 0, "total": 0, "completed": false}

## 重置进度（用于顺序按键策略）
func reset() -> void:
	pass

## 提取公共的按键名称转换方法
static func get_key_name_static(key_code: int) -> String:
	match key_code:
		KEY_SPACE:
			return "空格"
		KEY_A:
			return "A"
		KEY_S:
			return "S"
		KEY_D:
			return "D"
		KEY_F:
			return "F"
		KEY_J:
			return "J"
		KEY_K:
			return "K"
		KEY_L:
			return "L"
		KEY_W:
			return "W"
		KEY_E:
			return "E"
		KEY_R:
			return "R"
		KEY_T:
			return "T"
		KEY_Y:
			return "Y"
		KEY_U:
			return "U"
		KEY_I:
			return "I"
		KEY_O:
			return "O"
		KEY_P:
			return "P"
		_:
			return "键(" + str(key_code) + ")"
