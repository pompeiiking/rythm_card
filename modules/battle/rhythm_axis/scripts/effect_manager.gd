extends Node
class_name RhythmEffectManager
## 节奏轴动效管理器
## 负责所有视觉动效的创建和播放
## 所有参数通过 RhythmEffectConfig 配置

# ========== 配置 ==========
var _config: RhythmEffectConfig = null

# 判定区扩展距离（判定后块继续往后滑动的距离）
var _extend_distance: float = 50.0

# ========== 状态 ==========
var _block_nodes: Dictionary = {}  # block_id -> Node
var _judge_text_label: Label = null

# ========== 私有方法 ==========
const _EASING_OUT := Tween.EASE_OUT
const _TRANS_EXPO := Tween.TRANS_EXPO

# ========== 生命周期 ==========

func _ready() -> void:
	_setup_default_config()
	_create_judge_text()

func _setup_default_config() -> void:
	if _config == null:
		_config = RhythmEffectConfig.new()

## 确保配置已初始化（在任何可能用到配置的方法开头调用）
func _ensure_config() -> void:
	if _config == null:
		_config = RhythmEffectConfig.new()

# ========== 配置 ==========

func set_config(config: RhythmEffectConfig) -> void:
	_config = config

func get_config() -> RhythmEffectConfig:
	return _config

# ========== 公共接口 ==========

func create_block_node(block_id: String, _config_dict: Dictionary) -> Node:
	_ensure_config()
	var block_node: ColorRect = ColorRect.new()
	block_node.size = Vector2(_config.block_size, _config.block_size)
	block_node.color = _config.block_color
	block_node.position = Vector2(0, _config.axis_y - _config.block_size / 2)
	
	_add_glow_layers(block_node)
	
	# 应用滑动光晕 Shader（如果启用）
	if _config.sliding_glow_enabled:
		_apply_glow_shader(block_node)
	
	# 先清理可能存在的旧引用
	if _block_nodes.has(block_id):
		var old_node: Node = _block_nodes[block_id]
		if is_instance_valid(old_node):
			old_node.queue_free()
		_block_nodes.erase(block_id)
	
	_block_nodes[block_id] = block_node
	return block_node

## 应用发光 Shader 到块节点
func _apply_glow_shader(block_node: ColorRect) -> void:
	if not ResourceLoader.exists("res://modules/battle/rhythm_axis/shaders/block_glow.gdshader"):
		return
	
	var shader := load("res://modules/battle/rhythm_axis/shaders/block_glow.gdshader") as Shader
	if shader == null:
		return
	
	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("glow_color", _config.sliding_glow_color)
	shader_material.set_shader_parameter("glow_intensity", _config.sliding_glow_intensity)
	shader_material.set_shader_parameter("glow_radius", _config.sliding_glow_radius)
	shader_material.set_shader_parameter("glow_falloff", _config.sliding_glow_falloff)
	
	block_node.material = shader_material

func play_emit_effect(block_node: Node, _block_id: String) -> void:
	if _config.emit_scale_up > 1.0:
		var tween := create_tween()
		tween.set_ease(_EASING_OUT)
		tween.tween_property(block_node, "scale", Vector2(_config.emit_scale_up, _config.emit_scale_up), _config.emit_scale_duration)
	
	if _config.emit_glow_duration > 0:
		_animate_glow_layers(block_node)

func update_block_effects(block_id: String, progress: float) -> void:
	# 性能优化：先检查存在性，避免无效查找
	if not _block_nodes.has(block_id):
		return
	var node: Node = _block_nodes[block_id]
	if not is_instance_valid(node):
		_block_nodes.erase(block_id)
		return
	
	# 使用正弦函数实现周期性缩放效果，频率通过 pulse_frequency 控制
	# progress 范围 0.0-1.0，转换为 0-2π 周期
	if _config.pulse_enabled:
		var pulse := (sin(progress * _config.pulse_frequency * TAU) + 1.0) / 2.0
		var scale: float = _config.pulse_min_scale + pulse * (_config.pulse_max_scale - _config.pulse_min_scale)
		node.scale = Vector2(scale, scale)

func play_judge_effect(block_id: String, result: int, _delta: float) -> void:
	if not _block_nodes.has(block_id):
		return
	var node: Node = _block_nodes[block_id]
	if not is_instance_valid(node):
		_block_nodes.erase(block_id)
		return
	
	# 立即从引用字典中移除，防止后续update_block_effects再次访问
	_block_nodes.erase(block_id)
	
	match result:
		1: _play_perfect_effect(node)
		2: _play_good_effect(node)
		3: _play_miss_effect(node)

func remove_block(block_id: String) -> void:
	# 只移除引用，不销毁节点（由判定效果的 tween 回调负责销毁）
	_block_nodes.erase(block_id)

func add_block(block_id: String, block_node: Node) -> void:
	# 将块节点添加到 effect_manager，用于判定时播放颜色变化效果
	_block_nodes[block_id] = block_node

func clear_all_blocks() -> void:
	for block_id in _block_nodes.keys():
		var node = _block_nodes[block_id]
		if is_instance_valid(node):
			node.queue_free()
	_block_nodes.clear()

func set_hit_zone_info(hit_zone_x: float, axis_y: float) -> void:
	_config.hit_zone_x = hit_zone_x
	_config.axis_y = axis_y

func set_extend_distance(distance: float) -> void:
	_extend_distance = distance

func set_block_config(block_size: float, block_color: Color, axis_y: float) -> void:
	_config.block_size = block_size
	_config.block_color = block_color
	_config.axis_y = axis_y

# ========== 私有方法 ==========

func _add_glow_layers(block_node: ColorRect) -> void:
	var glow1: ColorRect = _create_glow_layer(_config.glow1_size, _config.glow1_offset, _config.emit_glow_color, _config.glow1_alpha)
	block_node.add_child(glow1)
	block_node.set_meta("glow1", glow1)
	
	var glow2: ColorRect = _create_glow_layer(_config.glow2_size, _config.glow2_offset, _config.emit_glow_color, _config.glow2_alpha)
	block_node.add_child(glow2)
	block_node.set_meta("glow2", glow2)

func _create_glow_layer(add_size: float, offset: float, color: Color, alpha: float) -> ColorRect:
	var glow: ColorRect = ColorRect.new()
	glow.size = Vector2(_config.block_size + add_size, _config.block_size + add_size)
	glow.color = color
	glow.color.a = alpha
	glow.position = Vector2(-offset, -offset)
	glow.modulate.a = 0.0
	return glow

func _animate_glow_layers(block_node: Node) -> void:
	var glow1: Node = block_node.get_meta("glow1")
	var glow2: Node = block_node.get_meta("glow2")
	
	if glow1:
		var tween := create_tween()
		tween.set_ease(_EASING_OUT)
		var half_dur := _config.emit_glow_duration * 0.5
		tween.tween_property(glow1, "modulate:a", _config.glow1_alpha * _config.emit_glow_intensity, half_dur)
		tween.tween_property(glow1, "modulate:a", 0.0, half_dur)
	
	if glow2:
		var tween := create_tween()
		tween.set_ease(_EASING_OUT)
		var third_dur := _config.emit_glow_duration * 0.3
		tween.tween_property(glow2, "modulate:a", _config.glow2_alpha * _config.emit_glow_intensity, third_dur)
		tween.tween_property(glow2, "modulate:a", 0.0, _config.emit_glow_duration - third_dur)

func _play_perfect_effect(node: Node) -> void:
	# 改变块颜色为金色
	_change_block_color(node, _config.perfect_color)
	# 完美特效：金色强烈光芒爆发
	_play_glow_burst(node, _config.perfect_glow_color, _config.perfect_burst_size)
	_play_particle_burst(node, _config.perfect_particle_count, _config.perfect_color, _config.perfect_particle_speed)
	_show_judge_text("PERFECT", _config.perfect_color, _config.perfect_text_offset)
	# 延迟后销毁节点，让变色效果可见
	_call_later(_config.perfect_duration, func(): _destroy_block_node(node))

func _play_good_effect(node: Node) -> void:
	# 改变块颜色为绿色
	_change_block_color(node, _config.good_color)
	# 良好特效：绿色中等光芒
	_play_glow_burst(node, _config.good_glow_color, _config.good_burst_size)
	_play_particle_burst(node, _config.good_particle_count, _config.good_color, _config.good_particle_speed)
	_show_judge_text("GOOD", _config.good_color, _config.good_text_offset)
	# 延迟后销毁节点，让变色效果可见
	_call_later(_config.good_duration, func(): _destroy_block_node(node))

func _play_miss_effect(node: Node) -> void:
	# 改变块颜色为灰色
	_change_block_color(node, _config.miss_color)
	# Miss特效：红色暗光
	_play_glow_burst(node, Color(0.5, 0, 0, 0.5), _config.good_burst_size * 0.5)
	_show_judge_text("MISS", _config.miss_color, _config.miss_text_offset)
	# Miss 抖动效果
	if _config.miss_shake:
		_animate_shake(node)
	# 延迟后销毁节点，让变色效果可见
	_call_later(_config.miss_duration, func(): _destroy_block_node(node))

func _animate_shake(node: Node) -> void:
	var orig_pos: Vector2 = node.position
	var shake_count := _config.miss_shake_count
	var shake_duration := _config.miss_shake_duration / shake_count
	
	for i in range(shake_count):
		var offset := Vector2(
			randf_range(-_config.miss_shake_x, _config.miss_shake_x),
			randf_range(-_config.miss_shake_y, _config.miss_shake_y)
		)
		var tween := create_tween()
		tween.tween_property(node, "position", orig_pos + offset, shake_duration)
	
	var return_tween := create_tween()
	return_tween.tween_property(node, "position", orig_pos, _config.miss_shake_duration * 0.3)

func _play_glow_burst(node: Node, glow_color: Color, burst_size: float) -> void:
	var burst: ColorRect = ColorRect.new()
	burst.size = node.size + Vector2(burst_size, burst_size)
	burst.color = glow_color
	burst.color.a = _config.burst_alpha
	burst.position = Vector2(-burst_size / 2, -burst_size / 2)
	node.add_child(burst)
	
	var tween := create_tween()
	tween.set_ease(_EASING_OUT)
	tween.set_trans(_TRANS_EXPO)
	tween.tween_property(burst, "modulate:a", 0.0, _config.burst_duration)
	tween.tween_property(burst, "size", burst.size + Vector2(_config.burst_expand, _config.burst_expand), _config.burst_duration)
	tween.tween_callback(burst.queue_free)

func _play_particle_burst(node: Node, count: int, color: Color, speed: float) -> void:
	var center: Vector2 = node.position + node.size / 2
	
	for i in range(count):
		var particle: ColorRect = ColorRect.new()
		particle.size = Vector2(_config.particle_size, _config.particle_size)
		particle.color = color
		particle.position = center
		get_parent().add_child(particle)
		
		var angle: float = (TAU / count) * i + randf_range(-_config.particle_spread, _config.particle_spread)
		var dist := randf_range(_config.particle_min_dist, _config.particle_max_dist)
		var target := center + Vector2(cos(angle), sin(angle)) * dist
		
		var tween := create_tween()
		tween.set_ease(_EASING_OUT)
		tween.set_trans(_TRANS_EXPO)
		tween.tween_property(particle, "position", target, speed)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, speed)
		tween.parallel().tween_property(particle, "size", Vector2(_config.particle_end_size, _config.particle_end_size), speed)
		tween.tween_callback(particle.queue_free)

func _show_judge_text(text: String, color: Color, offset: Vector2) -> void:
	if _judge_text_label == null:
		return
	
	_judge_text_label.text = text
	_judge_text_label.modulate = color
	_judge_text_label.modulate.a = 1.0
	_judge_text_label.position = Vector2(_config.hit_zone_x, _config.axis_y) + offset
	
	var tween := create_tween()
	tween.set_ease(_EASING_OUT)
	tween.tween_property(_judge_text_label, "position:y", _judge_text_label.position.y + _config.text_float_distance, _config.text_duration)
	tween.parallel().tween_property(_judge_text_label, "modulate:a", 0.0, _config.text_duration)

func _create_judge_text() -> void:
	_judge_text_label = Label.new()
	_judge_text_label.text = ""
	_judge_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_judge_text_label.add_theme_font_size_override("font_size", _config.text_font_size)
	_judge_text_label.add_theme_color_override("font_color", Color.WHITE)
	_judge_text_label.modulate.a = 0.0
	add_child(_judge_text_label)

func _destroy_block_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()

func _call_later(delay: float, callback: Callable) -> void:
	# 使用 await + Timer 实现延迟回调，避免使用 call_deferred 可能导致的引用问题
	# 增加 is_instance_valid 检查，防止节点已被销毁时执行回调导致崩溃
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(self):
		callback.call()

func _change_block_color(node: Node, color: Color) -> void:
	if is_instance_valid(node) and node is ColorRect:
		node.color = color
