class Page1 extends BasePage:
	
	
	func _ready():
		page_index = 1
		page_title = "第1页 - 红色"
		page_color = Color(0, 1, 0)  # 红色 (R,G,B)
		super._ready()
		_add_specific_content()
	
	func _add_specific_content():
		# 第1页特有内容
		var content_text = TextEdit.new()
		content_text.text = "这是第2页内容\n\n红色页面"
		content_text.editable = false
		content_text.position = Vector2(30, 80)
		content_text.size = Vector2(140, 200)
		content_text.add_theme_font_size_override("font_size", 12)
		add_child(content_text)
