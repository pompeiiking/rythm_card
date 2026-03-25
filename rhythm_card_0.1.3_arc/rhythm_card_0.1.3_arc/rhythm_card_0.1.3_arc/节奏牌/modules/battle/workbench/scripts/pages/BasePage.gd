# BasePage.gd
class_name BasePage
# BasePage.gd
extends Polygon2D
@export var page_color: Color = Color("#F5F0E3")
# 信号定义
signal page_clicked
signal page_hovered(hovering: bool)
signal turn_animation_finished

# 梯形顶点
@onready var trapezoid_vertices: PackedVector2Array = PackedVector2Array([
	Vector2(0, 300),    # 左下
	Vector2(200, 300),  # 右下
	Vector2(180, 0),    # 右上
	Vector2(20, 0)      # 左上
])

# 页面属性
@export var page_index: int = 0
@export var page_title: String = "未命名"
var is_current: bool = false
var can_interact: bool = true

func _ready():
	# 设置多边形形状
	polygon = trapezoid_vertices
	# 设置页面背景（可选）
	var bg = ColorRect.new()
	bg.size = Vector2(200, 300)
	bg.color = page_color  # 使用你设置的页面颜色
	bg.z_index = 10         # 比外框高
	add_child(bg)
	# 设置默认颜色
	color = Color("#F5F0E3")
	
	# 连接输入信号
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	
	# 初始化页面内容
	_initialize_page_content()

# 初始化页面内容
func _initialize_page_content():
	pass

# 鼠标进入
func _on_mouse_entered():
	if can_interact:
		emit_signal("page_hovered", true)
		_on_hover_enter()

# 鼠标离开
func _on_mouse_exited():
	if can_interact:
		emit_signal("page_hovered", false)
		_on_hover_exit()

# 输入事件处理
func _input_event(_viewport, event, _shape_idx):
	if can_interact and event is InputEventMouseButton and event.pressed:
		emit_signal("page_clicked")
		_on_click()

# 点击效果
func _on_click():
	print("页面被点击: ", page_title)
	# 添加点击动画
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

# 悬停进入效果
func _on_hover_enter():
	modulate = Color(1.1, 1.1, 1.0, 1.0)

# 悬停离开效果
func _on_hover_exit():
	modulate = Color(1.0, 1.0, 1.0, 1.0)

# 翻页开始
func start_turn_animation(direction: String, callback: Callable = Callable()):
	print("开始翻页动画:", direction)
	var effect_scene = load("res://scenes/effects/PageTurnEffect.tscn")
	if effect_scene:
		var effect = effect_scene.instantiate()
		effect.setup(self, direction)
		
		# 添加到场景
		get_parent().add_child(effect)
		
		# 连接完成信号
		effect.connect("animation_finished", Callable(self, "_on_turn_animation_finished").bind(callback))

func _on_turn_animation_finished(callback: Callable):
	emit_signal("turn_animation_finished")
	visible = false
	
	if callback:
		callback.call()
	
	await get_tree().create_timer(0.1).timeout
	queue_free()

func set_layer_color(layer: int):
	var base_color = Color("#F5F0E3")
	match layer:
		0:  # 最上层
			color = base_color
			is_current = true
		1:  # 中间层
			color = base_color.darkened(0.1)
		2:  # 最下层
			color = base_color.darkened(0.2)
