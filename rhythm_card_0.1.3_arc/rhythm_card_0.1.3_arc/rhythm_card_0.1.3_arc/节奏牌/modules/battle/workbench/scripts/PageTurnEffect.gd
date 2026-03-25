# PageTurnEffect.gd
extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D

# 信号定义
signal animation_finished

# 变量
var target_page: BasePage
var turn_direction: String = "forward"

# 窗口大小参数 (根据您的窗口尺寸设置)
var window_size: Vector2 = Vector2(1152, 648)
var book_size: Vector2 = Vector2(200, 300)  # 书本大小
var book_margin: Vector2 = Vector2(20, 20)  # 书本边距

# 计算书本在窗口中的位置
func _get_book_position() -> Vector2:
	return Vector2(window_size.x - book_size.x - book_margin.x, 
				   window_size.y - book_size.y - book_margin.y)

# 设置翻页效果
func setup(page: BasePage, direction: String):
	print("翻页效果设置: ", direction)
	print("窗口大小: ", window_size)
	print("书本位置: ", _get_book_position())
	
	target_page = page
	turn_direction = direction
	
	# 设置位置为书本位置
	global_position = _get_book_position()
	z_index = 100  # 确保在最上层
	
	# 捕获页面纹理
	_capture_page_texture()

# 捕获页面当前状态为纹理
func _capture_page_texture():
	print("捕获页面纹理...")
	
	# 创建临时Viewport
	var viewport = SubViewport.new()
	viewport.size = Vector2i(200, 300)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	# 复制目标页面
	var page_copy = target_page.duplicate()
	page_copy.position = Vector2(100, 150)  # 居中
	page_copy.z_index = 0
	
	# 添加到Viewport
	viewport.add_child(page_copy)
	
	# 添加到场景
	add_child(viewport)
	
	# 等待一帧确保渲染完成
	await get_tree().process_frame
	
	# 获取Viewport纹理
	var texture = viewport.get_texture()
	if texture:
		sprite_2d.texture = texture
		print("纹理捕获成功")
		
		# 删除viewport
		viewport.queue_free()
		
		# 开始动画
		_start_animation()
	else:
		print("纹理捕获失败")

# 开始翻页动画
func _start_animation():
	print("开始翻页动画播放")
	
	# 创建动画
	_create_animation()
	
	# 连接动画完成信号
	animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))
	
	# 播放动画
	animation_player.play("page_turn")

# 动画完成回调
func _on_animation_finished(_anim_name: String):
	print("翻页动画完成")
	emit_signal("animation_finished")
	queue_free()

# 创建翻页动画
func _create_animation():
	var anim = Animation.new()
	anim.length = 0.8  # 动画时长0.8秒
	
	# 计算动画位置参数
	var center_pos = Vector2(100, 150)  # 书本中心
	var screen_right = Vector2(window_size.x, 150)  # 屏幕右侧
	var screen_left = Vector2(-100, 150)  # 屏幕左侧
	
	if turn_direction == "forward":
		_create_forward_animation(anim, center_pos, screen_right)
	else:
		_create_backward_animation(anim, screen_left, center_pos)
	
	# 添加到AnimationPlayer
	animation_player.add_animation("page_turn", anim)
	print("动画创建完成: ", turn_direction)

# 创建向前翻页动画
func _create_forward_animation(anim: Animation, start_pos: Vector2, end_pos: Vector2):
	# 位置动画：向右飞出
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "Sprite2D:position")
	anim.track_insert_key(track_idx, 0.0, start_pos)
	anim.track_insert_key(track_idx, 0.8, end_pos)
	
	# 旋转动画
	track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "Sprite2D:rotation_degrees")
	anim.track_insert_key(track_idx, 0.0, 0.0)
	anim.track_insert_key(track_idx, 0.8, 90.0)
	
	# 透明度动画
	track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "Sprite2D:modulate:a")
	anim.track_insert_key(track_idx, 0.0, 1.0)
	anim.track_insert_key(track_idx, 0.6, 0.8)
	anim.track_insert_key(track_idx, 0.8, 0.0)
	
	# 缩放动画
	track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "Sprite2D:scale")
	anim.track_insert_key(track_idx, 0.0, Vector2(1.0, 1.0))
	anim.track_insert_key(track_idx, 0.4, Vector2(1.1, 0.9))
	anim.track_insert_key(track_idx, 0.8, Vector2(0.8, 1.2))

# 创建向后翻页动画
func _create_backward_animation(anim: Animation, start_pos: Vector2, end_pos: Vector2):
	# 位置动画：从左侧进入
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "Sprite2D:position")
	anim.track_insert_key(track_idx, 0.0, start_pos)
	anim.track_insert_key(track_idx, 0.8, end_pos)
	
	# 旋转动画
	track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "Sprite2D:rotation_degrees")
	anim.track_insert_key(track_idx, 0.0, -90.0)
	anim.track_insert_key(track_idx, 0.8, 0.0)
	
	# 透明度动画
	track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "Sprite2D:modulate:a")
	anim.track_insert_key(track_idx, 0.0, 0.0)
	anim.track_insert_key(track_idx, 0.2, 0.8)
	anim.track_insert_key(track_idx, 0.8, 1.0)
	
	# 缩放动画
	track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "Sprite2D:scale")
	anim.track_insert_key(track_idx, 0.0, Vector2(0.8, 1.2))
	anim.track_insert_key(track_idx, 0.4, Vector2(1.1, 0.9))
	anim.track_insert_key(track_idx, 0.8, Vector2(1.0, 1.0))

# 获取书本位置（供其他脚本使用）
static func get_book_position_for_window(window_width: int, window_height: int) -> Vector2:
	var book_size = Vector2(200, 300)
	var margin = Vector2(20, 20)
	return Vector2(window_width - book_size.x - margin.x, 
				   window_height - book_size.y - margin.y)
