extends Resource
class_name RhythmAxisConfig
## 节奏轴配置

# 发射器配置
var bpm: float = 120.0
var slide_duration: float = 1.5  # 滑行时长，越大越慢

# 可视化配置
var axis_length: float = 800.0
var axis_y: float = 300.0
var hit_zone_x: float = 700.0
var block_size: float = 40.0

# 样式配置
var axis_line_width: float = 4.0
var axis_line_color: Color = Color.WHITE
var hit_zone_color: Color = Color(1, 0, 0, 0.5)
var hit_zone_size_multiplier: float = 1.5
var hit_zone_extend_distance: float = 50.0
var block_color: Color = Color.CYAN

# 判定配置（单位：秒）
var judge_perfect_window: float = 0.08   # Perfect 判定窗口 ±80ms
var judge_good_window: float = 0.18      # Good 判定窗口 ±180ms
var judge_miss_after: float = 0.3        # Miss 超时 300ms

# 输入配置（按键码，0 表示使用默认）
var input_key: int = 0                   # 单键判定按键码（0=默认空格键）
var input_keys: Array = []               # 多键判定按键码数组（同时按下）
var input_sequence_keys: Array = [KEY_A, KEY_S, KEY_D]  # 顺序按键数组（默认：依次按 A → S → D）
var input_sequence_timeout: float = 1.0  # 顺序按键超时时间（秒）
