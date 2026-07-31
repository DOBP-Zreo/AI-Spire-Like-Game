# ShopManager.gd
# 商店 — 购买页 + 删牌页，切换不改变价格

extends Control

const CARD_PRICES = { "basic": 0, "common": 60, "uncommon": 100, "rare": 180 }
const RELIC_PRICES = { "starter": 0, "common": 160, "uncommon": 250, "rare": 350 }
const REMOVE_BASE = 50
const REMOVE_INC = 25

var shop_cards: Array = []
var shop_relics: Array = []
var remove_price: int = REMOVE_BASE

@onready var gold_label: Label = $GoldLabel
@onready var buy_view: Control = $BuyView
@onready var card_slots: HBoxContainer = $BuyView/CardSlots
@onready var relic_slots: HBoxContainer = $BuyView/RelicSlots
@onready var remove_btn: Button = $BuyView/RemoveBtn
@onready var remove_price_label: Label = $BuyView/RemovePriceLabel
@onready var leave_btn: Button = $BuyView/LeaveBtn
@onready var view_deck_btn: Button = $BuyView/ViewDeckBtn
@onready var deck_viewer: Panel = $DeckViewer
@onready var deck_viewer_list: VBoxContainer = $DeckViewer/DeckViewerScroll/DeckViewerList
@onready var deck_viewer_close: Button = $DeckViewer/DeckViewerClose

@onready var remove_view: Control = $RemoveView
@onready var remove_price_lbl: Label = $RemoveView/RemovePriceLbl
@onready var deck_list: VBoxContainer = $RemoveView/ScrollContainer/DeckList
@onready var back_btn: Button = $RemoveView/BackBtn

func _ready() -> void:
	leave_btn.pressed.connect(_on_leave)
	remove_btn.pressed.connect(_open_remove_view)
	back_btn.pressed.connect(_open_buy_view)
	view_deck_btn.pressed.connect(_on_view_deck)
	deck_viewer_close.pressed.connect(_on_deck_viewer_close)
	remove_price = REMOVE_BASE
	_generate_shop()
	_refresh_buy_view()

func _generate_shop() -> void:
	var all_ids = CardDatabase.card_ids.keys()
	var pool: Array = []
	for id in all_ids:
		if id in ["strike", "defend"]: continue
		var data = CardDatabase.card_ids[id]
		var w = 3 if data["rarity"] == "common" else (2 if data["rarity"] == "uncommon" else 1)
		for _i in range(w): pool.append(id)
	pool.shuffle()
	var chosen: Array = []
	for id in pool:
		if chosen.size() >= 4: break
		if id not in chosen: chosen.append(id)
	for id in chosen:
		shop_cards.append(CardDatabase.create_card(id))
	
	var relic_ids = _get_all_relic_ids()
	relic_ids.shuffle()
	for i in range(min(4, relic_ids.size())):
		var r = load("res://resources/relics/%s.tres" % relic_ids[i])
		if r: shop_relics.append(r)

func _get_all_relic_ids() -> Array:
	var owned = _owned_relic_ids()
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

func _owned_relic_ids() -> Array:
	var owned: Array = []
	for r in GameState.relics:
		if r.id: owned.append(r.id)
	return owned

func _open_remove_view() -> void:
	buy_view.visible = false
	gold_label.visible = false
	$TitleLabel.visible = false
	remove_view.visible = true
	_refresh_remove_view()

func _open_buy_view() -> void:
	remove_view.visible = false
	gold_label.visible = true
	$TitleLabel.visible = true
	buy_view.visible = true
	_refresh_buy_view()

func _refresh_buy_view() -> void:
	gold_label.text = "金币: %d" % GameState.gold
	remove_price_label.text = "当前价格: %d G" % remove_price
	
	for c in card_slots.get_children(): c.queue_free()
	for c in relic_slots.get_children(): c.queue_free()
	
	for i in range(shop_cards.size()):
		var card = shop_cards[i]
		var p = CARD_PRICES.get(card.rarity, 60)
		card_slots.add_child(_mk_item(card.card_name, card.get_formatted_description(), p, card.get_type_color(), i, true))
	
	for i in range(shop_relics.size()):
		var relic = shop_relics[i]
		var p = RELIC_PRICES.get(relic.rarity, 160)
		relic_slots.add_child(_mk_item(relic.relic_name, relic.description, p, Color(0.7, 0.5, 0.2), i, false))
	if shop_relics.is_empty():
		var lbl = Label.new()
		lbl.text = "暂无遗物可售"
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		relic_slots.add_child(lbl)

func _refresh_remove_view() -> void:
	remove_price_lbl.text = "当前价格: %d G" % remove_price
	
	for c in deck_list.get_children(): c.queue_free()
	
	for i in range(GameState.deck.size()):
		var card = GameState.deck[i]
		var item = _mk_remove_item(card, i)
		deck_list.add_child(item)

func _mk_item(title: String, desc: String, price: int, tint: Color, index: int, is_card: bool) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(290, 75)
	panel.size = Vector2(290, 75)
	
	var nl = Label.new()
	nl.text = title
	nl.position = Vector2(8, 6); nl.size = Vector2(190, 22)
	nl.add_theme_font_size_override("font_size", 13)
	nl.add_theme_color_override("font_color", tint)
	panel.add_child(nl)
	
	var dl = Label.new()
	dl.text = desc
	dl.position = Vector2(8, 28); dl.size = Vector2(190, 42)
	dl.add_theme_font_size_override("font_size", 10)
	dl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(dl)
	
	var pl = Label.new()
	pl.text = "%d G" % price
	pl.position = Vector2(210, 8); pl.size = Vector2(74, 20)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.add_theme_font_size_override("font_size", 13)
	pl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	panel.add_child(pl)
	
	var btn = Button.new()
	btn.text = "购买"; btn.position = Vector2(210, 34); btn.size = Vector2(74, 30)
	btn.add_theme_font_size_override("font_size", 12)
	btn.disabled = GameState.gold < price
	if not btn.disabled:
		btn.pressed.connect(_on_buy.bind(index, price, is_card))
	panel.add_child(btn)
	return panel

func _mk_remove_item(card: CardResource, index: int) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(1100, 48)
	panel.size = Vector2(1100, 48)
	
	var nl = Label.new()
	nl.text = card.card_name
	nl.position = Vector2(10, 10); nl.size = Vector2(260, 28)
	nl.add_theme_font_size_override("font_size", 14)
	nl.add_theme_color_override("font_color", card.get_type_color())
	panel.add_child(nl)
	
	var dl = Label.new()
	dl.text = card.get_formatted_description()
	dl.position = Vector2(280, 10); dl.size = Vector2(600, 28)
	dl.add_theme_font_size_override("font_size", 13)
	dl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	panel.add_child(dl)
	
	var pl = Label.new()
	pl.text = "%d G" % remove_price
	pl.position = Vector2(900, 10); pl.size = Vector2(70, 28)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.add_theme_font_size_override("font_size", 14)
	pl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	panel.add_child(pl)
	
	var btn = Button.new()
	btn.text = "删除"; btn.position = Vector2(980, 8); btn.size = Vector2(100, 34)
	btn.add_theme_font_size_override("font_size", 14)
	btn.disabled = GameState.gold < remove_price
	if not btn.disabled:
		btn.pressed.connect(_on_remove.bind(index))
	panel.add_child(btn)
	return panel

func _on_buy(index: int, price: int, is_card: bool) -> void:
	if not GameState.spend_gold(price): return
	if is_card:
		GameState.add_card_to_deck(shop_cards[index])
		shop_cards.remove_at(index)
	else:
		GameState.relics.append(shop_relics[index])
		shop_relics.remove_at(index)
	_refresh_buy_view()

func _on_remove(index: int) -> void:
	if not GameState.spend_gold(remove_price): return
	remove_price += REMOVE_INC
	GameState.deck.remove_at(index)
	_refresh_remove_view()

func _on_leave() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _on_view_deck() -> void:
	for c in deck_viewer_list.get_children(): c.queue_free()
	for card in GameState.deck:
		var lbl = Label.new()
		lbl.text = "%s — %s" % [card.card_name, card.get_formatted_description()]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", card.get_type_color())
		lbl.custom_minimum_size = Vector2(520, 28)
		deck_viewer_list.add_child(lbl)
	deck_viewer.visible = true

func _on_deck_viewer_close() -> void:
	deck_viewer.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_G:
			GameState.add_gold(100)
			if buy_view.visible: _refresh_buy_view()
			else: _refresh_remove_view()
		elif event.keycode == KEY_ESCAPE and deck_viewer.visible:
			deck_viewer.visible = false
