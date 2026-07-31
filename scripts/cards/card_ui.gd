# CardUI.gd
# 卡牌 UI 节点 — 显示单张卡牌，处理悬停/点击交互
# 附着在 card_scene.tscn 上
# 使用 get_node_or_null() 而非 @onready，因为 setup() 可能在 _ready() 之前被调用

extends Control

signal card_clicked(card_data: CardResource)

var card_data: CardResource = null
var original_position: Vector2
var is_hovered: bool = false
var is_playable: bool = true

var target_scale: Vector2 = Vector2(1.0, 1.0)
var target_position: Vector2

func _ready() -> void:
	original_position = position
	target_position = position
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func setup(card: CardResource) -> void:
	card_data = card
	_refresh_display()

func _refresh_display() -> void:
	if card_data == null:
		return
	
	var type_color = card_data.get_type_color()
	
	# 使用 get_node_or_null：setup() 可能在 _ready() 前调用
	var bg = get_node_or_null("BG")
	if bg:
		bg.color = type_color.darkened(0.3)
	
	var tb = get_node_or_null("TypeBar")
	if tb:
		tb.color = type_color
	
	var cl = get_node_or_null("CostLabel")
	if cl:
		cl.text = str(card_data.get_cost())
	
	var nl = get_node_or_null("NameLabel")
	if nl:
		nl.text = card_data.card_name
	
	var dl = get_node_or_null("DescLabel")
	if dl:
		dl.text = card_data.get_formatted_description()
	
	# 加载卡牌插图
	var ci = get_node_or_null("CardImage")
	if ci:
		var img_path = "res://assets/art/cards/art/%s.png" % card_data.id
		if ResourceLoader.exists(img_path):
			ci.texture = load(img_path)
		else:
			ci.texture = null
	
	_update_playable()

func _update_playable() -> void:
	if card_data == null:
		return
	is_playable = CombatState.can_play_card(card_data)
	modulate = Color(0.5, 0.5, 0.5, 0.7) if not is_playable else Color(1, 1, 1, 1)

func _on_mouse_entered() -> void:
	if not is_playable:
		return
	is_hovered = true
	target_scale = Vector2(1.15, 1.15)
	target_position = original_position + Vector2(0, -40)
	z_index = 10

func _on_mouse_exited() -> void:
	is_hovered = false
	target_scale = Vector2(1.0, 1.0)
	target_position = original_position
	z_index = 0

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if card_data != null and is_playable:
			card_clicked.emit(card_data)

func _process(delta: float) -> void:
	scale = scale.lerp(target_scale, 10.0 * delta)
	position = position.lerp(target_position, 10.0 * delta)
