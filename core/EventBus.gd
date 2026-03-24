extends Node
## 事件总线 - 模块间通信
## 
## 快速开始：
##   EventBus.listen("事件名", self, "_回调方法")  # 监听事件
##   EventBus.fire("事件名", 数据)                # 发送事件

var _listeners := {}

## 监听事件
func listen(event_name: String, target: Object, method: String) -> void:
	if not _listeners.has(event_name):
		_listeners[event_name] = []
	
	_listeners[event_name].append({
		"target": target,
		"method": method
	})

## 取消监听
func unlisten(event_name: String, target: Object) -> void:
	if not _listeners.has(event_name):
		return
	
	_listeners[event_name] = _listeners[event_name].filter(
		func(listener): return listener.target != target
	)

## 发送事件
func fire(event_name: String, data = null) -> void:
	if not _listeners.has(event_name):
		return
	
	# 先收集需要移除的无效监听者
	var to_remove: Array = []
	for listener in _listeners[event_name]:
		if not is_instance_valid(listener.target):
			to_remove.append(listener)
	
	# 移除无效监听者
	for listener in to_remove:
		_listeners[event_name].erase(listener)
	
	# 执行有效的监听回调
	for listener in _listeners[event_name]:
		if is_instance_valid(listener.target):
			listener.target.call(listener.method, data)
