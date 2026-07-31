# MapManager.gd
# 地图管理器 — 楼层地图的显示和交互
# 生成地图、绘制节点和连线、响应点击进入房间

extends Control

const NODE_SCENE = preload("res://scenes/map/map_node_ui.tscn")
const BATTLE_SCENE = "res://scenes/battle/battle_scene.tscn"

var floor_data: MapFloor
var node_uis: Dictionary = {}    # id → MapNodeUI

@onready var map_area: Control = $MapArea
@onready var floor_label: Label = $InfoBar/FloorLabel
@onready var hp_label: Label = $InfoBar/HPLabel
@onready var gold_label: Label = $InfoBar/GoldLabel
@onready var deck_label: Label = $InfoBar/DeckLabel

@onready var settings_btn: Button = $SettingsBtn
@onready var settings_panel: Panel = $SettingsPanel
@onready var return_menu_btn: Button = $SettingsPanel/ReturnMenuBtn
@onready var continue_btn: Button = $SettingsPanel/ContinueBtn

@onready var view_deck_btn: Button = $ViewDeckBtn
@onready var view_relic_btn: Button = $ViewRelicBtn
@onready var info_panel: Panel = $InfoPanel
@onready var info_title: Label = $InfoPanel/InfoTitle
@onready var info_list: VBoxContainer = $InfoPanel/InfoScroll/InfoList
@onready var info_close: Button = $InfoPanel/InfoClose

func _ready() -> void:
	# 连接设置按钮
	settings_btn.pressed.connect(_on_settings_pressed)
	return_menu_btn.pressed.connect(_on_return_menu)
	continue_btn.pressed.connect(_on_settings_close)
	view_deck_btn.pressed.connect(_show_deck)
	view_relic_btn.pressed.connect(_show_relics)
	info_close.pressed.connect(func(): info_panel.visible = false)
	
	# 如果是新游戏，初始化 GameState
	if GameState.current_floor_map == null:
		GameState.initialize_new_game()
	
	# 如果是从战斗返回
	if not GameState.pending_room_id.is_empty():
		floor_data = GameState.current_floor_map
		_refresh_info()
		_return_from_battle(true)
		return
	
	# 生成或恢复楼层
	if GameState.floor_level == 1 and GameState.current_floor_map == null:
		floor_data = MapGenerator.generate_floor(GameState.floor_level)
		GameState.current_floor_map = floor_data
		floor_data.move_to("r0_c1")
	else:
		floor_data = GameState.current_floor_map
	
	_refresh_info()
	_draw_map()

func _refresh_info() -> void:
	floor_label.text = "第 %d 层" % GameState.floor_level
	hp_label.text = "❤ %d / %d" % [GameState.current_hp, GameState.max_hp]
	gold_label.text = "💰 %d" % GameState.gold
	deck_label.text = "牌组: %d 张" % GameState.get_deck_size()

func _draw_map() -> void:
	# 清除旧节点
	for child in map_area.get_children():
		child.queue_free()
	node_uis.clear()
	
	# 计算布局参数
	var area_w = map_area.size.x
	var area_h = map_area.size.y
	var rows = floor_data.rows
	var cols = floor_data.cols
	var node_w = 90
	var node_h = 60
	var row_h = (area_h - 40) / float(rows - 1)
	
	# 当前节点
	var current = floor_data.get_current_node()
	var available_nodes = floor_data.get_available_next_nodes()
	
	# 先绘制连线（放在下层）
	var lines_node = Control.new()
	lines_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_area.add_child(lines_node)
	
	_draw_connections(lines_node, area_w, area_h, rows, cols, row_h, node_w, node_h)
	
	# 再绘制节点（放在上层）
	for r in range(rows):
		for c in range(cols):
			var node_id = "r%d_c%d" % [r, c]
			var node = floor_data.get_node(node_id)
			if node == null:
				continue
			
			var x = (area_w - cols * node_w) / 2.0 + c * (node_w + 20) + node_w / 2.0
			var y = area_h - 20 - r * row_h - node_h / 2.0
			
			var is_current = (node_id == floor_data.current_node_id)
			var is_available = false
			for av in available_nodes:
				if av.id == node_id:
					is_available = true
					break
			
			var node_ui = NODE_SCENE.instantiate()
			node_ui.position = Vector2(x - node_w / 2.0, y - node_h / 2.0)
			node_ui.setup(node, is_available, is_current)
			if is_available:
				node_ui.node_selected.connect(_on_node_selected)
			map_area.add_child(node_ui)
			node_uis[node_id] = node_ui
	
	# 没有可选节点（到达 Boss 或卡住了）
	if available_nodes.is_empty() and current and current.room_type != "boss":
		if current.room_type == "boss":
			pass  # Boss 已经打过
		else:
			# 自动移动到下一层或结束
			pass

func _draw_connections(parent: Control, area_w: float, area_h: float, rows: int, cols: int, row_h: float, node_w: float, node_h: float) -> void:
	# 用简单的 ColorRect 绘制连线（水平+垂直段）
	for r in range(rows - 1):
		for c in range(cols):
			var node_id = "r%d_c%d" % [r, c]
			var node = floor_data.get_node(node_id)
			if node == null:
				continue
			
			var x1 = (area_w - cols * node_w) / 2.0 + c * (node_w + 20) + node_w / 2.0
			var y1 = area_h - 20 - r * row_h
			
			for conn_id in node.connections:
				var target = floor_data.get_node(conn_id)
				if target == null:
					continue
				var x2 = (area_w - cols * node_w) / 2.0 + target.col * (node_w + 20) + node_w / 2.0
				var y2 = area_h - 20 - target.row * row_h + node_h
				
				var line_color = Color(1, 1, 1, 0.3)
				if node.cleared:
					line_color = Color(1, 1, 1, 0.6)
				
				# 垂直线段
				var vline = ColorRect.new()
				vline.position = Vector2(x1 - 1, min(y1, y2))
				vline.size = Vector2(2, abs(y2 - y1) + node_h)
				vline.color = line_color
				vline.mouse_filter = Control.MOUSE_FILTER_IGNORE
				parent.add_child(vline)
				
				# 水平线段（如果需要）
				if abs(x2 - x1) > 2:
					var hline = ColorRect.new()
					var mid_y = min(y1, y2) + abs(y2 - y1) / 2.0
					hline.position = Vector2(min(x1, x2), mid_y - 1)
					hline.size = Vector2(abs(x2 - x1), 2)
					hline.color = line_color
					hline.mouse_filter = Control.MOUSE_FILTER_IGNORE
					parent.add_child(hline)

func _on_node_selected(node_data: MapNodeData) -> void:
	# 标记当前节点为已清除
	floor_data.mark_cleared(floor_data.current_node_id)
	
	# 保存状态
	GameState.current_floor_map = floor_data
	
	# 根据房间类型决定行为
	match node_data.room_type:
		"battle", "elite", "boss":
			_start_battle(node_data)
		"shop":
			_start_shop(node_data)
		"rest":
			_rest_room(node_data)
		"treasure":
			_start_treasure(node_data)
		"event":
			_start_event(node_data)

func _start_battle(node_data: MapNodeData) -> void:
	# 设置敌人
	var enemy_id = "slime_green"
	if not node_data.enemy_pool.is_empty():
		enemy_id = node_data.enemy_pool[randi() % node_data.enemy_pool.size()]
	
	GameState.pending_enemy_id = enemy_id
	GameState.pending_room_id = node_data.id
	
	get_tree().change_scene_to_file(BATTLE_SCENE)

func _rest_room(node_data: MapNodeData) -> void:
	# 回血 30%
	var heal_amount = int(GameState.max_hp * 0.3)
	GameState.heal(heal_amount)
	floor_data.move_to(node_data.id)
	GameState.current_floor_map = floor_data
	_refresh_info()
	_draw_map()

func _pass_room(node_data: MapNodeData) -> void:
	# 暂时直接通过（宝箱/事件未实现）
	floor_data.move_to(node_data.id)
	GameState.current_floor_map = floor_data
	_refresh_info()
	_draw_map()

func _start_shop(node_data: MapNodeData) -> void:
	GameState.pending_room_id = node_data.id
	get_tree().change_scene_to_file("res://scenes/shop/shop_scene.tscn")

func _start_treasure(node_data: MapNodeData) -> void:
	GameState.pending_room_id = node_data.id
	get_tree().change_scene_to_file("res://scenes/treasure/treasure_scene.tscn")

func _start_event(node_data: MapNodeData) -> void:
	GameState.pending_room_id = node_data.id
	get_tree().change_scene_to_file("res://scenes/events/event_scene.tscn")

# 战斗结束后回到地图时调用
func _return_from_battle(victory: bool) -> void:
	if not victory:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	
	var room_id = GameState.pending_room_id
	GameState.pending_room_id = ""
	GameState.pending_enemy_id = ""
	
	var node_data = floor_data.get_node(room_id)
	
	if node_data and node_data.room_type == "boss":
		# Boss 被击败 → 下一层
		GameState.floor_level += 1
		if GameState.floor_level > 3:
			# 通关！
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
			return
		floor_data = MapGenerator.generate_floor(GameState.floor_level)
		GameState.current_floor_map = floor_data
		floor_data.move_to("r0_c1")
		_draw_map()
		_refresh_info()
		return
	
	if room_id:
		floor_data.move_to(room_id)
	
	GameState.current_floor_map = floor_data
	_draw_map()
	_refresh_info()

# ============================================================
# 信息面板
# ============================================================
func _show_deck() -> void:
	info_title.text = "当前牌组 (%d 张)" % GameState.deck.size()
	for c in info_list.get_children(): c.queue_free()
	for card in GameState.deck:
		var lbl = Label.new()
		lbl.text = "%s — %s" % [card.card_name, card.get_formatted_description()]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", card.get_type_color())
		lbl.custom_minimum_size = Vector2(520, 26)
		info_list.add_child(lbl)
	info_panel.visible = true

func _show_relics() -> void:
	info_title.text = "当前遗物 (%d 个)" % GameState.relics.size()
	for c in info_list.get_children(): c.queue_free()
	if GameState.relics.is_empty():
		var lbl = Label.new()
		lbl.text = "暂无遗物"
		lbl.add_theme_font_size_override("font_size", 14)
		info_list.add_child(lbl)
	else:
		for relic in GameState.relics:
			var lbl = Label.new()
			lbl.text = "%s: %s" % [relic.relic_name, relic.description]
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
			lbl.custom_minimum_size = Vector2(520, 26)
			info_list.add_child(lbl)
	info_panel.visible = true

# ============================================================
# 设置面板
# ============================================================
func _on_settings_pressed() -> void:
	settings_panel.visible = true

func _on_settings_close() -> void:
	settings_panel.visible = false

func _on_return_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	_refresh_info()
