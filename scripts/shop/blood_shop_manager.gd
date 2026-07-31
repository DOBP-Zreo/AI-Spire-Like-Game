# blood_shop_manager.gd
# 血商店 — 用生命上限购买卡牌/遗物

extends Control

const CARD_HP_COST = { "common": 6, "uncommon": 10, "rare": 16 }
const RELIC_HP_COST = { "common": 14, "uncommon": 22, "rare": 34 }

var shop_cards: Array = []
var shop_relics: Array = []

@onready var gold_label: Label = $GoldLabel
@onready var card_slots: HBoxContainer = $BuyView/CardSlots
@onready var relic_slots: HBoxContainer = $BuyView/RelicSlots
@onready var leave_btn: Button = $BuyView/LeaveBtn

func _ready() -> void:
	gold_label.text = "生命上限: %d" % GameState.max_hp
	leave_btn.pressed.connect(_on_leave)
	_generate()
	_refresh()

func _generate() -> void:
	var pool = CardDatabase.card_ids.keys()
	var picks: Array = []
	for _i in range(10): picks.append(pool[randi() % pool.size()])
	picks.shuffle()
	var chosen: Array = []
	for p in picks:
		if chosen.size() >= 4: break
		if p not in ["strike", "defend"] and p not in chosen: chosen.append(p)
	for id in chosen: shop_cards.append(CardDatabase.create_card(id))
	
	var rids = _get_relics()
	rids.shuffle()
	for i in range(min(4, rids.size())):
		var r = load("res://resources/relics/%s.tres" % rids[i])
		if r: shop_relics.append(r)

func _get_relics() -> Array:
	var owned: Array = []
	for r in GameState.relics:
		if r.id: owned.append(r.id)
	var ids: Array = []
	var dir = DirAccess.open("res://resources/relics")
	if dir:
		dir.list_dir_begin(); var fn = dir.get_next()
		while fn != "":
			if fn.ends_with(".tres"):
				var rid = fn.trim_suffix(".tres")
				if rid not in owned: ids.append(rid)
			fn = dir.get_next()
	return ids

func _refresh() -> void:
	gold_label.text = "生命上限: %d" % GameState.max_hp
	for c in card_slots.get_children(): c.queue_free()
	for c in relic_slots.get_children(): c.queue_free()
	
	for i in range(shop_cards.size()):
		var card = shop_cards[i]
		var cost = CARD_HP_COST.get(card.rarity, 6)
		var item = _mk_item(card.card_name, card.get_formatted_description(), cost, card.get_type_color(), true, i)
		card_slots.add_child(item)
	for i in range(shop_relics.size()):
		var relic = shop_relics[i]
		var cost = RELIC_HP_COST.get(relic.rarity, 14)
		var item = _mk_item(relic.relic_name, relic.description, cost, Color(0.7, 0.5, 0.2), false, i)
		relic_slots.add_child(item)

func _mk_item(title: String, desc: String, cost: int, tint: Color, is_card: bool, index: int) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(280, 75)
	var nl = Label.new(); nl.text = title; nl.position = Vector2(8, 6); nl.size = Vector2(180, 22)
	nl.add_theme_font_size_override("font_size", 13); nl.add_theme_color_override("font_color", tint)
	panel.add_child(nl)
	var dl = Label.new(); dl.text = desc; dl.position = Vector2(8, 28); dl.size = Vector2(180, 42)
	dl.add_theme_font_size_override("font_size", 10); dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	panel.add_child(dl)
	var pl = Label.new(); pl.text = "-%d HP" % cost; pl.position = Vector2(200, 8); pl.size = Vector2(74, 20)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.add_theme_font_size_override("font_size", 13); pl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	panel.add_child(pl)
	var btn = Button.new(); btn.text = "购买"; btn.position = Vector2(200, 34); btn.size = Vector2(74, 30)
	btn.add_theme_font_size_override("font_size", 12)
	btn.disabled = GameState.max_hp < cost
	if not btn.disabled: btn.pressed.connect(_on_buy.bind(index, cost, is_card))
	panel.add_child(btn)
	return panel

func _on_buy(index: int, cost: int, is_card: bool) -> void:
	if GameState.max_hp < cost: return
	GameState.max_hp -= cost
	GameState.current_hp = min(GameState.current_hp, GameState.max_hp)
	if is_card: GameState.add_card_to_deck(shop_cards[index]); shop_cards.remove_at(index)
	else: GameState.relics.append(shop_relics[index]); shop_relics.remove_at(index)
	_refresh()

func _on_leave() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		GameState.max_hp += 5
		GameState.current_hp += 5
		_refresh()
