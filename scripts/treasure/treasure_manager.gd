# TreasureManager.gd
# 宝箱房间 — 2 卡牌 + 2 遗物中选 1 个获取

extends Control

var treasure_cards: Array = []
var treasure_relics: Array = []

@onready var card1: Control = $CardRow/Card1
@onready var card2: Control = $CardRow/Card2
@onready var relic1: Control = $RelicRow/Relic1
@onready var relic2: Control = $RelicRow/Relic2
@onready var hint_label: Label = $HintLabel
@onready var view_deck_btn: Button = $ViewDeckBtn
@onready var view_relic_btn: Button = $ViewRelicBtn
@onready var info_panel: Panel = $InfoPanel
@onready var info_title: Label = $InfoPanel/InfoTitle
@onready var info_list: VBoxContainer = $InfoPanel/InfoScroll/InfoList
@onready var info_close: Button = $InfoPanel/InfoClose

func _ready() -> void:
	view_deck_btn.pressed.connect(_show_deck)
	view_relic_btn.pressed.connect(_show_relics)
	info_close.pressed.connect(func(): info_panel.visible = false)
	_generate_treasure()
	_build_ui()

func _generate_treasure() -> void:
	var pool = CardDatabase.card_ids.keys()
	var picks: Array = []
	for _i in range(10):
		picks.append(pool[randi() % pool.size()])
	picks.shuffle()
	var chosen: Array = []
	for p in picks:
		if chosen.size() >= 2: break
		if p not in ["strike", "defend"] and p not in chosen:
			chosen.append(p)
	for id in chosen:
		treasure_cards.append(CardDatabase.create_card(id))
	
	var relic_ids = _get_unowned_relic_ids()
	relic_ids.shuffle()
	for i in range(2):
		var r = load("res://resources/relics/%s.tres" % relic_ids[i])
		if r: treasure_relics.append(r)

func _build_ui() -> void:
	for i in range(2):
		if i < treasure_cards.size():
			var c = treasure_cards[i]
			_setup_slot(card1 if i == 0 else card2, c.card_name, c.get_formatted_description(), c.get_type_color(), "card", i)
		if i < treasure_relics.size():
			var r = treasure_relics[i]
			_setup_slot(relic1 if i == 0 else relic2, r.relic_name, r.description, Color(0.7, 0.5, 0.2), "relic", i)

func _setup_slot(container: Control, name: String, desc: String, tint: Color, kind: String, index: int) -> void:
	for c in container.get_children(): c.queue_free()
	var btn = Button.new()
	btn.text = "选择"
	btn.position = Vector2(5, 5)
	btn.size = Vector2(60, 30)
	btn.add_theme_font_size_override("font_size", 13)
	btn.pressed.connect(_on_pick.bind(kind, index))
	container.add_child(btn)
	
	var nl = Label.new()
	nl.text = name
	nl.position = Vector2(5, 40)
	nl.size = Vector2(190, 22)
	nl.add_theme_font_size_override("font_size", 14)
	nl.add_theme_color_override("font_color", tint)
	container.add_child(nl)
	
	var dl = Label.new()
	dl.text = desc
	dl.position = Vector2(5, 62)
	dl.size = Vector2(190, 40)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.add_theme_font_size_override("font_size", 11)
	dl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	container.add_child(dl)

func _on_pick(kind: String, index: int) -> void:
	if kind == "card":
		GameState.add_card_to_deck(treasure_cards[index])
	else:
		GameState.relics.append(treasure_relics[index])
	# 选择后退出
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _get_unowned_relic_ids() -> Array:
	var owned: Array = []
	for r in GameState.relics:
		if r.id: owned.append(r.id)
	var ids: Array = []
	var dir = DirAccess.open("res://resources/relics")
	if dir:
		dir.list_dir_begin()
		var fn = dir.get_next()
		while fn != "":
			if fn.ends_with(".tres"):
				var rid = fn.trim_suffix(".tres")
				if rid not in owned: ids.append(rid)
			fn = dir.get_next()
	return ids

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
