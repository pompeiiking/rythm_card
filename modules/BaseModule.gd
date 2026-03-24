## 模块接口规范
## 
## 任何节点都可以作为模块，只需实现以下方法：
##   initialize() - 初始化（加载资源、订阅事件）
##   start()      - 启动（开始运行）
##   stop()       - 停止（暂停运行）
##   cleanup()    - 清理（释放资源、取消订阅）
##
## 示例：
##   extends Control  # 或 Node2D, RigidBody2D 等任何节点
##   func initialize(): pass
##   func start(): pass
##   func stop(): pass
##   func cleanup(): pass
