extends RefCounted
class_name BeatStrategy
## 节拍策略基类（接口）
## 所有节拍算法实现此类

func get_beat_data() -> Dictionary:
	## 返回当前节拍的数据 { beat_type, intensity }
	push_error("BeatStrategy.get_beat_data() 需要子类实现")
	return {}

func advance_beat() -> void:
	## 推进到下一拍
	push_error("BeatStrategy.advance_beat() 需要子类实现")
	pass
