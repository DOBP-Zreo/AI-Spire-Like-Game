# MapNodeUI.gd
# 地图节点 UI — 单个房间的可视化方块
# 使用 get_node_or_null() 而非 @onready，因 setup() 可能在 _ready() 前调用

extends Control

signal node_selected(node_data: MapNodeData)

var node_data: MapNodeData = null
var is_available: bool = false

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_hover_in)
	mouse_exited.connect(_on_hover_out)

func setup(data: MapNodeData, available: bool, current: bool) -> void:
	node_data = data
	is_available = available
	
	var color = data.get_color()
	var bg = get_node_or_null("BG")
	var icon_img = get_node_or_null("NodeIcon")
	var name_label = get_node_or_null("NameLabel")
	
	if current:
		if bg: bg.color = Color.WHITE
		if name_label: name_label.add_theme_color_override("font_color", Color.BLACK)
	elif available:
		if bg: bg.color = color
		if name_label: name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	else:
		if bg: bg.color = color.darkened(0.6)
		if name_label: name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	
	if icon_img:
		var tex = _get_icon_texture(data.room_type)
		if tex: icon_img.texture = tex
	if name_label: name_label.text = data.get_display_name()

func _get_icon_texture(room_type: String) -> Texture2D:
	var path = "res://assets/art/ui/map_nodes/node_" + room_type + ".png"
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _on_hover_in() -> void:
	if is_available:
		scale = Vector2(1.15, 1.15)

func _on_hover_out() -> void:
	scale = Vector2(1.0, 1.0)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and is_available:
			node_selected.emit(node_data)
