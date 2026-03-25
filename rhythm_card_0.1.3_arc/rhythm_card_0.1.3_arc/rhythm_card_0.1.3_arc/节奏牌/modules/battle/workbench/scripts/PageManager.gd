# PageManager.gd
class_name PageManager
# PageManager.gd
extends Node

# 页面场景数组
@export var page_scenes: Array[PackedScene] = [
	preload("res://scenes/pages/Page1.tscn"),
	preload("res://scenes/pages/Page2.tscn"),
	preload("res://scenes/pages/Page3.tscn"),
]

# 当前显示的页面
var current_pages: Array[BasePage] = []
var current_index: int = 0
var is_turning: bool = false

# 位置配置
@export var base_position: Vector2 = Vector2(1152 - 200 - 20, 648 - 300 - 20)  # 默认位置
var page_offsets: Array[Vector2] = [
	Vector2(0, 0),      # 最上层
	Vector2(5, 5),      # 中间层
	Vector2(10, 10)     # 最下层
]
var z_indices: Array[int] = [30, 20, 10]

func _ready():
	print("页面管理器初始化")
	print("基础位置: ", base_position)
	initialize()

# 初始化页面
func initialize():
	# 清除已有页面
	for page in current_pages:
		page.queue_free()
	current_pages.clear()
	
	print("加载页面，当前位置索引: ", current_index)
	
	# 在 PageManager._initialize_page_content() 中
	for i in range(min(3, page_scenes.size())):
		var page = page_scenes[i].instantiate()
		page.position = base_position + page_offsets[i]
		page.visible = true  # 确保可见
		add_child(page)      # 确保添加到场景
		current_pages.append(page)
# 加载单个页面
func _load_page(index: int) -> BasePage:
	if index < page_scenes.size():
		var page_instance: BasePage = page_scenes[index].instantiate() as BasePage
		if page_instance:
			page_instance.page_index = index + 1
			print("加载页面 %d: %s" % [index + 1, page_instance.page_title])
			return page_instance
	return null

# 设置页面属性
func _setup_page(page: BasePage, layer: int):
	# 设置位置
	page.position = base_position + page_offsets[layer]
	page.z_index = z_indices[layer]
	
	# 设置颜色
	page.set_layer_color(layer)
	
	# 连接信号
	page.page_clicked.connect(_on_page_clicked.bind(page))

# 向前翻页
func turn_page_forward():
	if is_turning or current_index + 3 >= page_scenes.size():
		print("无法向前翻页: 已在最后一页")
		return
	
	print("开始向前翻页")
	is_turning = true
	
	# 最上层页面开始翻页动画
	var top_page = current_pages[0]
	print("顶部页面开始动画: ", top_page.page_title)
	
	top_page.start_turn_animation("forward", Callable(self, "_on_forward_complete"))

# 向前翻页完成
func _on_forward_complete():
	print("向前翻页动画完成")
	
	# 移除最上层页面
	var removed_page = current_pages[0]
	current_pages.remove_at(0)
	print("移除页面: ", removed_page.page_title)
	
	# 移动索引
	current_index += 1
	print("当前索引: ", current_index)
	
	# 添加新页面到最下层
	var new_page_index = current_index + 2
	if new_page_index < page_scenes.size():
		var new_page = _load_page(new_page_index)
		if new_page:
			_setup_page(new_page, 2)
			get_parent().add_child(new_page)
			current_pages.append(new_page)
			print("添加新页面: ", new_page.page_title)
	
	# 重新调整层级
	_reorder_pages()
	is_turning = false
	print("翻页完成")

# 向后翻页
func turn_page_backward():
	if is_turning or current_index <= 0:
		print("无法向后翻页: 已在第一页")
		return
	
	print("开始向后翻页")
	is_turning = true
	
	# 最下层页面开始翻页动画
	var bottom_page = current_pages[2]
	print("底部页面开始动画: ", bottom_page.page_title)
	
	bottom_page.start_turn_animation("backward", Callable(self, "_on_backward_complete"))

# 向后翻页完成
func _on_backward_complete():
	print("向后翻页动画完成")
	
	# 移除最下层页面
	var removed_page = current_pages[2]
	current_pages.remove_at(2)
	print("移除页面: ", removed_page.page_title)
	
	# 移动索引
	current_index -= 1
	print("当前索引: ", current_index)
	
	# 添加新页面到最上层
	var new_page = _load_page(current_index)
	if new_page:
		_setup_page(new_page, 0)
		get_parent().add_child(new_page)
		current_pages.insert(0, new_page)
		print("添加新页面: ", new_page.page_title)
	
	# 重新调整层级
	_reorder_pages()
	is_turning = false
	print("翻页完成")

# 重新排序页面
func _reorder_pages():
	for i in range(current_pages.size()):
		var page = current_pages[i]
		page.position = base_position + page_offsets[i]
		page.z_index = z_indices[i]
		
		# 更新当前页面状态
		page.is_current = (i == 0)
		
		if i == 0:
			print("当前页面: ", page.page_title)

# 页面点击处理
func _on_page_clicked(page: BasePage):
	print("点击了页面: ", page.page_title)
	
	# 只有当前页面可交互
	if current_pages.size() > 0 and page == current_pages[0]:
		print("当前页面被点击，可以执行特殊操作")
