extends Node2D
class_name TestRhythmAxisNew
## 节奏轴测试场景（重新设计版）
##
## 操作说明：
## - A/S/D 键：触发判定（顺序按键策略）
## - R键：重新开始
## - ESC键：退出

# 预加载节奏轴模块
const _RhythmModule = preload("res://modules/battle/rhythm_axis/rhythm_axis_module.gd")

# 模块实例
var _rhythm_module: Node = null

# UI 节点
var _info_label: Label = null
var _status_label: Label = null
var _result_label: Label = null

# 测试状态
var _test_running: bool = false

func _ready() -> void:
	print("[TestRhythmAxisNew] 场景开始")
	_setup_ui()
	_init_module()
	
	# 创建定时器处理 Miss 检查
	var miss_check_timer := Timer.new()
	miss_check_timer.name = "MissCheckTimer"
	miss_check_timer.wait_time = 0.05  # 50ms 检查一次
	miss_check_timer.autostart = true
	miss_check_timer.timeout.connect(_on_miss_check_timer)
	add_child(miss_check_timer)

func _setup_ui() -> void:
	# 标题
	_info_label = Label.new()
	_info_label.name = "InfoLabel"
	_info_label.text = """=== 节奏轴测试 ===
按 A → S → D 顺序按键触发判定
按 R键 重新开始
按 ESC键 退出
"""
	_info_label.position = Vector2(20, 20)
	_info_label.add_theme_font_size_override("font_size", 18)
	add_child(_info_label)
	
	# 状态显示
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.text = "按 R 开始测试"
	_status_label.position = Vector2(20, 200)
	_status_label.add_theme_font_size_override("font_size", 22)
	add_child(_status_label)
	
	# 结果显示
	_result_label = Label.new()
	_result_label.name = "ResultLabel"
	_result_label.text = ""
	_result_label.position = Vector2(20, 250)
	_result_label.add_theme_font_size_override("font_size", 16)
	add_child(_result_label)

func _init_module() -> void:
	_rhythm_module = _RhythmModule.new()
	add_child(_rhythm_module)
	_rhythm_module.initialize()
	# 使用顺序按键策略 (A → S → D)
	_rhythm_module.set_sequential_keys_input([KEY_A, KEY_S, KEY_D], 1.0)
	
	# 订阅事件
	EventBus.listen("rhythm:block_emitted", self, "_on_block_emitted")
	EventBus.listen("rhythm:input_judged", self, "_on_input_judged")
	EventBus.listen("rhythm:block_reached_zone", self, "_on_block_reached_zone")
	
	print("[TestRhythmAxisNew] 模块初始化完成")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				_cleanup()
				get_tree().quit()
			KEY_R:
				_restart_test()
			KEY_A:
				_trigger_judge(KEY_A)
			KEY_S:
				_trigger_judge(KEY_S)
			KEY_D:
				_trigger_judge(KEY_D)
			KEY_SPACE:
				_trigger_judge(KEY_SPACE)

func _trigger_judge(key_code: int = 0) -> void:
	if not _test_running:
		return
	EventBus.fire("rhythm:input_requested", {"key_code": key_code})

func _restart_test() -> void:
	print("[TestRhythmAxisNew] 重新开始测试")
	_rhythm_module.stop()
	_rhythm_module.cleanup()
	_rhythm_module.initialize()
	_rhythm_module.set_sequential_keys_input([KEY_A, KEY_S, KEY_D], 1.0)
	_rhythm_module.start()
	_test_running = true
	_status_label.text = "测试运行中 - 按 A → S → D 顺序按键"
	_add_result("--- 测试重新开始 ---")

func _on_miss_check_timer() -> void:
	if not _test_running:
		return
	var current_time: float = Time.get_ticks_msec() / 1000.0
	EventBus.fire("rhythm:check_miss", {"current_time": current_time})

func _on_block_emitted(block_data: Dictionary) -> void:
	_add_result("发射: " + str(block_data.get("block_id", "")))

func _on_block_reached_zone(_block_data: Dictionary) -> void:
	_add_result("块到达判定区")

func _on_input_judged(data: Dictionary) -> void:
	var result: int = data.get("result", 3)
	var result_text: String
	match result:
		1: result_text = "PERFECT!"
		2: result_text = "GOOD"
		3: result_text = "MISS"
		_: result_text = "未知"
	var delta: float = data.get("delta", 0.0)
	_add_result("判定: " + result_text + " (delta=" + str(delta) + ")")

func _add_result(text: String) -> void:
	# 限制显示的行数
	var lines: Array = _result_label.text.split("\n")
	if lines.size() > 15:
		lines.remove_at(0)
	lines.append(text)
	_result_label.text = "\n".join(lines)

func _cleanup() -> void:
	_test_running = false
	if _rhythm_module:
		_rhythm_module.cleanup()
	EventBus.unlisten("rhythm:block_emitted", self)
	EventBus.unlisten("rhythm:input_judged", self)
	EventBus.unlisten("rhythm:block_reached_zone", self)
