# main_menu.gd
# 主菜单 — 开始界面 + 牌库/遗物/状态查看

extends Control

@onready var title_label: Label = $TitleLabel
@onready var start_btn: Button = $StartBtn
@onready var warrior_info: Control = $WarriorInfo
@onready var version_label: Label = $VersionLabel
@onready var bg: TextureRect = $BG

@onready var view_deck_btn: Button = $ViewDeckBtn
@onready var view_relic_btn: Button = $ViewRelicBtn
@onready var info_btn: Button = $InfoBtn
@onready var info_panel: Panel = $InfoPanel
@onready var info_title: Label = $InfoPanel/InfoTitle
@onready var info_list: VBoxContainer = $InfoPanel/InfoScroll/InfoList
@onready var info_close: Button = $InfoPanel/InfoClose

var battle_scene_path = "res://scenes/map/map_scene.tscn"

func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	view_deck_btn.pressed.connect(_show_deck)
	view_relic_btn.pressed.connect(_show_relics)
	info_btn.pressed.connect(_show_status)
	info_close.pressed.connect(func(): info_panel.visible = false)
	start_btn.grab_focus()
	
	bg.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(bg, "modulate:a", 1.0, 0.8)

func _input(event: InputEvent) -> void:
	if info_panel.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			info_panel.visible = false
		return
	if event.is_action_pressed("ui_accept"):
		_on_start_pressed()

func _on_start_pressed() -> void:
	start_btn.disabled = true
	var tween = create_tween()
	tween.tween_property(bg, "modulate:a", 0.0, 0.4)
	tween.tween_callback(_load_battle)

func _load_battle() -> void:
	GameState.initialize_new_game()
	get_tree().change_scene_to_file(battle_scene_path)

func _show_deck() -> void:
	info_title.text = "当前牌组"
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
	info_title.text = "当前遗物"
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

func _show_status() -> void:
	info_title.text = "角色状态"
	for c in info_list.get_children(): c.queue_free()
	var lines = [
		"职业: 剑士",
		"生命: %d / %d" % [GameState.current_hp, GameState.max_hp],
		"金币: %d" % GameState.gold,
		"牌组数量: %d 张" % GameState.deck.size(),
		"遗物数量: %d 个" % GameState.relics.size(),
		"当前楼层: %d / 3" % GameState.floor_level,
	]
	for line in lines:
		var lbl = Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		lbl.custom_minimum_size = Vector2(520, 30)
		info_list.add_child(lbl)
	info_panel.visible = true
