# MainScene.gd
# MainScene.gd
extends Node2D

@onready var page_manager: PageManager = $PageManager

# 窗口尺寸
var window_size: Vector2 = Vector2(1152, 648)
var book_size: Vector2 = Vector2(200, 300)
var book_margin: Vector2 = Vector2(20, 20)

func _ready():
	print("窗口大小: ", window_size)
	
	# 计算书本位置
	var book_pos = _get_book_position()
	print("书本位置: ", book_pos)
	
	# 设置背景
	_setup_background()
	
	# 添加书本装饰
	_add_book_decorations(book_pos)
	
	# 设置页面管理器的基础位置
	if page_manager:
		page_manager.base_position = book_pos
		print("页面管理器基础位置已设置: ", book_pos)

# 计算书本位置
func _get_book_position() -> Vector2:
	return Vector2(window_size.x - book_size.x - book_margin.x, 
				   window_size.y - book_size.y - book_margin.y)

# 获取书本区域
func _get_book_rect() -> Rect2:
	var pos = _get_book_position()
	return Rect2(pos, book_size)

# 设置游戏背景
func _setup_background():
	var background = ColorRect.new()
	background.color = Color("#2C3E50")
	background.size = window_size
	background.z_index = -10
	add_child(background)

# 添加书本装饰
func _add_book_decorations(book_pos: Vector2):
	# 书本外框
	var frame = _create_trapezoid_frame()
	frame.color = Color("#9962CC")
	frame.position = book_pos
	frame.z_index = 40
	add_child(frame)
	
	# 装饰方块
	var block_positions = [
		Vector2(30, 270),   # 左下
		Vector2(160, 250),  # 右下
		Vector2(140, 220),  # 中下
		Vector2(50, 200),   # 中左
		Vector2(120, 180)   # 中右
	]
	
	for i in range(block_positions.size()):
		var block = ColorRect.new()
		block.color = Color("#A9DFBF")
		block.size = Vector2(12, 12)
		block.position = book_pos + block_positions[i]
		block.z_index = 50
		add_child(block)
	
	# 翻页提示
	_add_page_turn_hints(book_pos)
	
	# 调试信息提示
	_add_debug_hints(book_pos)

# 创建梯形边框
func _create_trapezoid_frame() -> Polygon2D:
	var polygon = Polygon2D.new()
	polygon.polygon = PackedVector2Array([
		Vector2(-5, 305),    # 外框左下
		Vector2(205, 305),   # 外框右下
		Vector2(185, -5),    # 外框右上
		Vector2(15, -5)      # 外框左上
	])
	return polygon

# 添加翻页提示
func _add_page_turn_hints(book_pos: Vector2):
	# 左侧提示
	var left_hint = Label.new()
	left_hint.text = "◀ 上一页"
	left_hint.position = book_pos + Vector2(-120, 150)
	left_hint.modulate = Color.BLUE.lightened(0.3)
	left_hint.add_theme_font_size_override("font_size", 14)
	add_child(left_hint)
	
	# 右侧提示
	var right_hint = Label.new()
	right_hint.text = "下一页 ▶"
	right_hint.position = book_pos + Vector2(220, 150)
	right_hint.modulate = Color.BLUE.lightened(0.3)
	right_hint.add_theme_font_size_override("font_size", 14)
	add_child(right_hint)
	
	# 书本位置提示
	var pos_hint = Label.new()
	pos_hint.text = "书本位置: %.0f, %.0f" % [book_pos.x, book_pos.y]
	pos_hint.position = Vector2(10, 20)
	pos_hint.modulate = Color.GREEN.lightened(0.3)
	pos_hint.add_theme_font_size_override("font_size", 12)
	add_child(pos_hint)

# 添加调试信息提示
func _add_debug_hints(book_pos: Vector2):
	var debug_hint1 = Label.new()
	debug_hint1.text = "窗口尺寸: 1152×648"
	debug_hint1.position = Vector2(10, 40)
	debug_hint1.modulate = Color.YELLOW
	debug_hint1.add_theme_font_size_override("font_size", 12)
	add_child(debug_hint1)
	
	var debug_hint2 = Label.new()
	debug_hint2.text = "按 F1 查看场景树 | 按 ESC 退出"
	debug_hint2.position = Vector2(10, window_size.y - 30)
	debug_hint2.modulate = Color.WHITE
	debug_hint2.add_theme_font_size_override("font_size", 12)
	add_child(debug_hint2)

# 输入处理
func _input(event):
	# 键盘控制
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_RIGHT, KEY_SPACE:
				page_manager.turn_page_forward()
			KEY_LEFT:
				page_manager.turn_page_backward()
			KEY_ESCAPE:
				get_tree().quit()
			KEY_F1:
				_print_scene_tree()
	
	# 鼠标控制
	if event is InputEventMouseButton and event.pressed:
		var click_pos = get_global_mouse_position()
		var book_rect = _get_book_rect()
		
		if book_rect.has_point(click_pos):
			# 计算书本内相对位置
			var local_x = click_pos.x - book_rect.position.x
			
			# 点击右侧1/4区域翻下一页
			if local_x > 150:  # 150/200 = 3/4
				page_manager.turn_page_forward()
			# 点击左侧1/4区域翻上一页
			elif local_x < 50:  # 50/200 = 1/4
				page_manager.turn_page_backward()
			# 点击中间区域触发当前页面点击
			else:
				if page_manager.current_pages.size() > 0:
					page_manager._on_page_clicked(page_manager.current_pages[0])

# 打印场景树
func _print_scene_tree():
	print("=== 场景树结构 ===")
	_print_node_tree(self, 0)
	print("=================")

func _print_node_tree(node: Node, depth: int):
	var indent = "  ".repeat(depth)
	print("%s%s (%s)" % [indent, node.name, node.get_class()])
	
	for child in node.get_children():
		_print_node_tree(child, depth + 1)
