extends Node
## 游戏核心 - 模块管理器
## 
## 快速开始：
##   GameCore.add_module("模块名", 模块实例)  # 添加并自动初始化
##   GameCore.get_module("模块名")           # 获取模块

var _modules := {}

## 添加模块（自动初始化和启动）
func add_module(module_name: String, module: Node) -> void:
	_modules[module_name] = module
	add_child(module)
	
	if module.has_method("initialize"):
		module.initialize()
	if module.has_method("start"):
		module.start()

## 获取模块
func get_module(module_name: String) -> Node:
	return _modules.get(module_name)

## 移除模块（自动清理）
func remove_module(module_name: String) -> void:
	var module = _modules.get(module_name)
	if not module:
		return
	
	if module.has_method("stop"):
		module.stop()
	if module.has_method("cleanup"):
		module.cleanup()
	
	remove_child(module)
	module.queue_free()
	_modules.erase(module_name)
