# event_manager.gd
# 事件房间 — 展示故事 + 选项，多种事件类型

extends Control

var _event_data: Dictionary = {}
var _used: Array = []  # 已用过的事件索引

@onready var title_label: Label = $TitleLabel
@onready var story_label: Label = $StoryLabel
@onready var opt1_btn: Button = $Options/Option1
@onready var opt2_btn: Button = $Options/Option2
@onready var leave_btn: Button = $LeaveBtn
@onready var gold_label: Label = $GoldLabel

@onready var view_deck_btn: Button = $ViewDeckBtn
@onready var view_relic_btn: Button = $ViewRelicBtn
@onready var info_panel: Panel = $InfoPanel
@onready var info_title_lbl: Label = $InfoPanel/InfoTitle
@onready var info_list: VBoxContainer = $InfoPanel/InfoScroll/InfoList
@onready var info_close: Button = $InfoPanel/InfoClose

func _ready() -> void:
	gold_label.text = "金币: %d" % GameState.gold
	leave_btn.pressed.connect(_on_leave)
	view_deck_btn.pressed.connect(_show_deck)
	view_relic_btn.pressed.connect(_show_relics)
	info_close.pressed.connect(func(): info_panel.visible = false)
	_pick_event()
	_refresh_ui()

func _pick_event() -> void:
	_event_data = EventDatabase.get_random_event()
	_refresh_ui()

func _refresh_ui() -> void:
	title_label.text = _event_data.get("title", "???")
	story_label.text = _event_data.get("story", "")
	
	var opts: Array = _event_data.get("options", [])
	opt1_btn.text = opts[0].get("text", "") if opts.size() > 0 else ""
	opt1_btn.visible = opts.size() > 0
	opt2_btn.text = opts[1].get("text", "") if opts.size() > 1 else ""
	opt2_btn.visible = opts.size() > 1
	
	# 断开旧连接
	if opt1_btn.pressed.is_connected(_on_choose.bind(0)):
		opt1_btn.pressed.disconnect(_on_choose.bind(0))
	if opt2_btn.pressed.is_connected(_on_choose.bind(1)):
		opt2_btn.pressed.disconnect(_on_choose.bind(1))
	
	opt1_btn.pressed.connect(_on_choose.bind(0))
	opt2_btn.pressed.connect(_on_choose.bind(1))

func _on_choose(opt_index: int) -> void:
	var opts: Array = _event_data.get("options", [])
	if opt_index >= opts.size(): return
	var opt = opts[opt_index]
	
	# 扣除代价
	var cost_type = opt.get("cost_type", "")
	var cost_val = opt.get("cost_value", 0)
	
	if cost_type == "gold" and GameState.gold < cost_val:
		return  # 不够钱
	if cost_type == "hp" and GameState.current_hp <= cost_val:
		return  # 没血扣
	
	if cost_type == "gold":
		GameState.spend_gold(cost_val)
	elif cost_type == "hp":
		GameState.current_hp -= cost_val
	elif cost_type == "max_hp":
		GameState.max_hp -= cost_val
		GameState.current_hp = min(GameState.current_hp, GameState.max_hp)
	
	# 给予奖励
	_apply_reward(opt.get("reward_type", ""), opt.get("reward_value", 0))
	
	# 特殊奖励不自动返回
	if opt.get("reward_type", "") == "blood_shop":
		gold_label.text = "金币: %d" % GameState.gold
		return  # 留在页面，等退出
	
	# 其他选项：如果是强行通过的伤害事件可返回，其余均可返回
	_go_back()

func _apply_reward(reward_type: String, reward_value: int) -> void:
	match reward_type:
		"random_card":
			var pool = CardDatabase.card_ids.keys()
			var picks: Array = []
			for _i in range(10): picks.append(pool[randi() % pool.size()])
			picks.shuffle()
			for p in picks:
				if p not in ["strike", "defend"]:
					GameState.add_card_to_deck(CardDatabase.create_card(p))
					break
		"random_relic":
			var relic_ids = _get_all_relics()
			relic_ids.shuffle()
			var r = load("res://resources/relics/%s.tres" % relic_ids[0])
			if r: GameState.relics.append(r)
		"relic_x2":
			var relic_ids = _get_all_relics()
			relic_ids.shuffle()
			for i in range(min(2, relic_ids.size())):
				var r = load("res://resources/relics/%s.tres" % relic_ids[i])
				if r: GameState.relics.append(r)
		"heal_30":
			var heal_amt = int(GameState.max_hp * 0.3)
			GameState.current_hp = min(GameState.max_hp, GameState.current_hp + heal_amt)
		"gold_100":
			GameState.add_gold(100)
		"transform":
			if GameState.deck.size() > 0:
				var idx = randi() % GameState.deck.size()
				var pool = CardDatabase.card_ids.keys()
				var picks: Array = []
				for _i in range(10): picks.append(pool[randi() % pool.size()])
				picks.shuffle()
				for p in picks:
					if p not in ["strike", "defend"]:
						GameState.deck[idx] = CardDatabase.create_card(p)
						break
		"blood_shop":
			get_tree().change_scene_to_file("res://scenes/shop/blood_shop_scene.tscn")

func _get_all_relics() -> Array:
	var owned = _owned_ids()
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

func _owned_ids() -> Array:
	var owned: Array = []
	for r in GameState.relics:
		if r.id: owned.append(r.id)
	return owned

func _on_leave() -> void:
	_go_back()

func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_G: GameState.add_gold(100); gold_label.text = "金币: %d" % GameState.gold
			KEY_R: _pick_event()  # 重roll事件
			KEY_ESCAPE:
				if info_panel.visible: info_panel.visible = false

func _show_deck() -> void:
	info_title_lbl.text = "当前牌组"
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
	info_title_lbl.text = "当前遗物"
	for c in info_list.get_children(): c.queue_free()
	if GameState.relics.is_empty():
		var lbl = Label.new(); lbl.text = "暂无遗物"
		lbl.add_theme_font_size_override("font_size", 14); info_list.add_child(lbl)
	else:
		for relic in GameState.relics:
			var lbl = Label.new()
			lbl.text = "%s: %s" % [relic.relic_name, relic.description]
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
			lbl.custom_minimum_size = Vector2(520, 26); info_list.add_child(lbl)
	info_panel.visible = true
