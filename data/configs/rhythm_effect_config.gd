extends Resource
class_name RhythmEffectConfig
## 节奏轴动效配置
## 可通过外部 .tres 文件配置

## ========== 判定区配置 ==========
var hit_zone_size_multiplier: float = 1.5  # 判定区放大倍数
var hit_zone_extend_distance: float = 50.0  # 判定区往后延伸的距离
var hit_zone_color: Color = Color(1, 0, 0, 0.5)

## ========== 块基础配置（由主配置传入）==========
var block_size: float = 40.0
var block_color: Color = Color.CYAN
var axis_y: float = 300.0
var hit_zone_x: float = 700.0

## ========== 发射动效 ==========
var emit_glow_color: Color = Color(0, 1, 1, 1)
var emit_glow_duration: float = 0.3
var emit_glow_intensity: float = 0.8
var emit_scale_up: float = 1.2
var emit_scale_duration: float = 0.15

## 发光层参数
var glow1_size: float = 8.0
var glow1_offset: float = 4.0
var glow1_alpha: float = 0.3
var glow2_size: float = 16.0
var glow2_offset: float = 8.0
var glow2_alpha: float = 0.15

## ========== 滑动光晕特效（Shader）==========
var sliding_glow_enabled: bool = true        # 是否启用滑动光晕
var sliding_glow_color: Color = Color(0, 1, 1, 0.6)  # 光晕颜色
var sliding_glow_intensity: float = 0.8      # 光晕强度
var sliding_glow_radius: float = 1.3         # 光晕半径（相对于块大小）
var sliding_glow_falloff: float = 0.5        # 衰减速度

## ========== 滑动动效 ==========
var pulse_enabled: bool = true
var pulse_frequency: float = 4.0
var pulse_min_scale: float = 1.0
var pulse_max_scale: float = 1.1

## ========== 判定结果通用 ==========
var judge_color_change_duration: float = 0.05

## --- Perfect ---
var perfect_color: Color = Color(1, 0.84, 0, 1)
var perfect_glow_color: Color = Color(1, 0.9, 0.5, 1)
var perfect_scale: float = 1.3
var perfect_duration: float = 0.4
var perfect_particle_count: int = 12
var perfect_particle_speed: float = 0.4
var perfect_burst_size: float = 24.0
var perfect_text_offset: Vector2 = Vector2(-30, -80)

## --- Good ---
var good_color: Color = Color(0, 1, 0.5, 1)
var good_glow_color: Color = Color(0.5, 1, 0.8, 1)
var good_scale: float = 1.1
var good_duration: float = 0.3
var good_particle_count: int = 6
var good_particle_speed: float = 0.35
var good_burst_size: float = 16.0
var good_text_offset: Vector2 = Vector2(-20, -80)

## --- Miss ---
var miss_color: Color = Color(0.5, 0.5, 0.5, 1)
var miss_fade_out: bool = true
var miss_duration: float = 0.25
var miss_shake: bool = true
var miss_shake_count: int = 6
var miss_shake_duration: float = 0.24
var miss_shake_x: float = 4.0
var miss_shake_y: float = 2.0
var miss_text_offset: Vector2 = Vector2(-15, -80)

## ========== 爆发特效 ==========
var burst_alpha: float = 0.6
var burst_duration: float = 0.3
var burst_expand: float = 20.0

## ========== 粒子特效 ==========
var particle_size: float = 4.0
var particle_end_size: float = 1.0
var particle_spread: float = 0.3
var particle_min_dist: float = 30.0
var particle_max_dist: float = 60.0

## ========== 判定文字 ==========
var text_font_size: int = 24
var text_float_distance: float = 30.0
var text_duration: float = 0.5
