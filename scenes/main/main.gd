extends Node
## 游戏入口
##
## 使用流程：
## 1. 在 _register_modules() 中注册所有模块
## 2. 模块会自动初始化和启动
## 3. 在 _ready() 中发送游戏启动事件

func _ready() -> void:
	_register_modules()
	_on_game_ready()

## 注册所有游戏模块
func _register_modules() -> void:
	# 在这里添加你的模块
	# 示例：
	# GameCore.add_module("Card", CardModule.new())
	# GameCore.add_module("Score", ScoreModule.new())
	# GameCore.add_module("UI", UIModule.new())
	pass

## 游戏就绪回调
func _on_game_ready() -> void:
	# 所有模块已加载完成
	# 在这里发送游戏启动事件
	# 示例：
	# EventBus.fire("game:ready")
	pass
