# BattleManager.gd
# 战斗管理器 — 控制战斗场景的初始化、回合流转、UI 刷新
# 附着在 battle_scene.tscn 的根节点上

extends Control

const CARD_SCENE = preload("res://scenes/cards/card_scene.tscn")
const CARD_W = 120
const CARD_H = 180
const CARD_GAP = 25   # 牌间距（重叠时用小的间距）

# ============================================================
# UI 引用 — 玩家信息
# ============================================================
@onready var player_hp_bar: ProgressBar = $PlayerArea/HPBar
@onready var player_hp_text: Label = $PlayerArea/HPBar/HPText
@onready var player_block_label: Label = $PlayerArea/BlockLabel
@onready var energy_label: Label = $PlayerArea/EnergyLabel

# ============================================================
# UI 引用 — 状态面板
# ============================================================
@onready var strength_label: Label = $StatusArea/StrengthLabel
@onready var dexterity_label: Label = $StatusArea/DexterityLabel
@onready var vulnerable_label: Label = $StatusArea/VulnerableLabel
@onready var weak_label: Label = $StatusArea/WeakLabel
@onready var poison_label: Label = $StatusArea/PoisonLabel

# ============================================================
# UI 引用 — 牌堆信息
# ============================================================
@onready var deck_label: Label = $DeckInfo/DeckLabel
@onready var exhaust_label: Label = $DeckInfo/ExhaustLabel

# ============================================================
# UI 引用 — 查看牌库/遗物
# ============================================================
@onready var view_deck_btn: Button = $ViewDeckBtn
@onready var view_relic_btn: Button = $ViewRelicBtn
@onready var view_exhaust_btn: Button = $ViewExhaustBtn
@onready var viewer_panel: Panel = $ViewerPanel
@onready var viewer_title: Label = $ViewerPanel/ViewerTitle
@onready var viewer_list: VBoxContainer = $ViewerPanel/ViewerScroll/ViewerList
@onready var viewer_close: Button = $ViewerPanel/ViewerClose

# ============================================================
# UI 引用 — 手牌区 & 按钮
# ============================================================
@onready var hand_area: Control = $HandArea
@onready var end_turn_btn: Button = $EndTurnBtn
@onready var turn_label: Label = $TurnLabel

# ============================================================
# UI 引用 — 结果面板
# ============================================================
@onready var result_panel: Panel = $ResultPanel
@onready var result_label: Label = $ResultPanel/ResultLabel
@onready var result_btn: Button = $ResultPanel/ResultButton

@onready var victory_btn: Button = $VictoryPanel/VictoryBtn

# ============================================================
# UI 引用 — 设置
# ============================================================
@onready var settings_btn: Button = $SettingsBtn
@onready var settings_panel: Panel = $SettingsPanel
@onready var return_menu_btn: Button = $SettingsPanel/ReturnMenuBtn
@onready var continue_btn: Button = $SettingsPanel/ContinueBtn

# 手牌列表
var card_ui_nodes: Array = []

# ============================================================
# 初始化
# ============================================================
func _ready() -> void:
	# 连接信号
	CombatState.state_updated.connect(_on_combat_state_updated)
	CombatState.combat_started.connect(_on_combat_start)
	CombatState.combat_ended.connect(_on_combat_ended)
	
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	result_btn.pressed.connect(_on_result_button_pressed)
	victory_btn.pressed.connect(_on_victory_btn_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	return_menu_btn.pressed.connect(_on_return_menu)
	continue_btn.pressed.connect(_on_settings_close)
	view_deck_btn.pressed.connect(_on_view_deck)
	view_relic_btn.pressed.connect(_on_view_relics)
	view_exhaust_btn.pressed.connect(_on_view_exhaust)
	viewer_close.pressed.connect(_on_viewer_close)
	viewer_panel.gui_input.connect(_on_viewer_panel_gui_input)
	
	# 初始隐藏
	result_panel.visible = false
	end_turn_btn.disabled = true
	
	# 加载敌人（从 GameState 获取，或默认绿色史莱姆）
	var enemy_id = GameState.pending_enemy_id
	if enemy_id.is_empty():
		enemy_id = "slime_green"
	var enemy_path = "res://resources/enemies/%s.tres" % enemy_id
	var enemy_res: EnemyResource = null
	if ResourceLoader.exists(enemy_path):
		enemy_res = load(enemy_path) as EnemyResource
	if enemy_res == null:
		enemy_res = load("res://resources/enemies/slime_green.tres") as EnemyResource
	
	CombatState.player_max_hp = GameState.max_hp
	CombatState.player_hp = GameState.current_hp
	
	# 使用 GameState 的牌组
	var deck: Array = GameState.deck.duplicate()
	if deck.is_empty():
		deck.append_array(CardDatabase.get_warrior_starter_deck())
	
	await get_tree().process_frame
	CombatState.start_combat(deck, enemy_res)

# ============================================================
# 战斗开始
# ============================================================
func _on_combat_start() -> void:
	# 触发战斗开始遗物
	_activate_start_relics()
	end_turn_btn.disabled = false
	_refresh_all()

func _activate_start_relics() -> void:
	for relic in GameState.relics:
		if relic.trigger == "on_combat_start":
			match relic.effect_type:
				"strength":
					CombatState.player_strength += relic.effect_value
				"block":
					CombatState.player_block += relic.effect_value
				"enemy_hp_cut":
					CombatState.enemy_hp = int(CombatState.enemy_hp * (100 - relic.effect_value) / 100.0)
					CombatState.enemy_max_hp = CombatState.enemy_hp
	CombatState.state_updated.emit()

# ============================================================
# 回合流转
# ============================================================
func _on_end_turn_pressed() -> void:
	if not CombatState.is_player_turn:
		return
	
	end_turn_btn.disabled = true
	CombatState.end_player_turn()
	
	await _execute_enemy_turn()
	CombatState.end_enemy_turn()
	
	if CombatState.is_combat_active:
		end_turn_btn.disabled = false

func _execute_enemy_turn() -> void:
	var intent = CombatState.get_enemy_intent()
	await get_tree().create_timer(0.5).timeout
	CombatState.execute_enemy_intent(intent)
	await get_tree().create_timer(0.5).timeout

# ============================================================
# 战斗结束
# ============================================================
func _on_combat_ended(victory: bool) -> void:
	end_turn_btn.disabled = true
	
	if victory:
		var gold_reward = 0
		if CombatState.current_enemy_resource:
			gold_reward = randi_range(
				CombatState.current_enemy_resource.gold_reward_min,
				CombatState.current_enemy_resource.gold_reward_max
			)
			GameState.add_gold(gold_reward)
		
		GameState.current_hp = CombatState.player_hp
		
		for relic in GameState.relics:
			if relic.trigger == "on_combat_end" and relic.effect_type == "heal":
				GameState.heal(relic.effect_value)
		
		# 第三层 Boss → 通关
		if _is_final_boss():
			_show_victory()
			return
		
		# 普通胜利
		result_panel.visible = true
		result_label.text = "胜利！+%d 金币" % gold_reward
		result_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		result_btn.text = "返回地图"
	else:
		GameState.current_hp = 0
		result_panel.visible = true
		result_label.text = "败北..."
		result_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		result_btn.text = "返回菜单"

func _is_final_boss() -> bool:
	var enemy = CombatState.current_enemy_resource
	if enemy == null: return false
	if GameState.floor_level < 3: return false
	return enemy.type == "boss"

func _show_victory() -> void:
	var vp = $VictoryPanel
	var vt: Label = $VictoryPanel/VictoryStats
	vt.text = "当前金币: %d  |  卡牌: %d 张  |  遗物: %d 个" % [GameState.gold, GameState.deck.size(), GameState.relics.size()]
	vp.visible = true

func _on_victory_btn_pressed() -> void:
	GameState.initialize_new_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_result_button_pressed() -> void:
	if CombatState.player_hp <= 0:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

# ============================================================
# 手牌管理
# ============================================================
func _rebuild_hand() -> void:
	_clear_hand()
	
	var cards = CombatState.hand
	if cards.is_empty():
		return
	
	var hand_w = hand_area.size.x
	var card_count = cards.size()
	
	# 计算间距：牌少时分散，牌多时重叠
	var spacing: float
	if card_count <= 5:
		spacing = CARD_W + CARD_GAP
	else:
		spacing = float(hand_w - CARD_W) / max(card_count - 1, 1)
		spacing = min(spacing, CARD_W + CARD_GAP)
	
	var total_w = CARD_W + (card_count - 1) * spacing
	var start_x = (hand_w - total_w) / 2.0
	
	for i in range(card_count):
		var card = cards[i]
		var card_ui = CARD_SCENE.instantiate()
		card_ui.setup(card)
		card_ui.position = Vector2(start_x + i * spacing, 5)
		card_ui.card_clicked.connect(_on_card_clicked)
		hand_area.add_child(card_ui)
		card_ui_nodes.append(card_ui)

func _clear_hand() -> void:
	for node in card_ui_nodes:
		if is_instance_valid(node):
			node.queue_free()
	card_ui_nodes.clear()

func _on_card_clicked(card: CardResource) -> void:
	CombatState.play_card(card)

# ============================================================
# UI 刷新
# ============================================================
func _on_combat_state_updated() -> void:
	_refresh_all()

func _refresh_all() -> void:
	_refresh_player_stats()
	_refresh_pile_info()
	_rebuild_hand()
	
	var who = "你的回合" if CombatState.is_player_turn else "敌人回合"
	turn_label.text = "回合 %d  —  %s" % [CombatState.turn_number, who]

func _refresh_player_stats() -> void:
	var max_hp = CombatState.player_max_hp
	var hp = CombatState.player_hp
	player_hp_bar.max_value = max_hp
	player_hp_bar.value = hp
	player_hp_text.text = "%d / %d" % [hp, max_hp]
	
	if hp <= max_hp * 0.3:
		player_hp_bar.modulate = Color.RED
	elif hp <= max_hp * 0.6:
		player_hp_bar.modulate = Color.ORANGE
	else:
		player_hp_bar.modulate = Color.GREEN
	
	# 格挡
	if CombatState.player_block > 0:
		player_block_label.text = "格挡: %d" % CombatState.player_block
		player_block_label.visible = true
	else:
		player_block_label.visible = false
	
	# 能量
	energy_label.text = "能量: %d / %d" % [CombatState.player_energy, CombatState.player_energy_per_turn]
	
	# Stats
	_show_stat(strength_label, "力量", CombatState.player_strength)
	_show_stat(dexterity_label, "敏捷", CombatState.player_dexterity)
	_show_stat(vulnerable_label, "易伤", CombatState.player_vulnerable)
	_show_stat(weak_label, "虚弱", CombatState.player_weak)
	_show_stat(poison_label, "中毒", CombatState.player_poison)

func _show_stat(label: Label, name: String, value: int) -> void:
	if value > 0:
		label.text = "%s: %d" % [name, value]
		label.visible = true
	else:
		label.visible = false

func _refresh_pile_info() -> void:
	var deck_count = CombatState.draw_pile.size() + CombatState.discard_pile.size()
	deck_label.text = "牌堆: %d" % deck_count
	exhaust_label.text = "消耗: %d" % CombatState.exhaust_pile.size()
	view_exhaust_btn.text = "消耗 %d" % CombatState.exhaust_pile.size()

# ============================================================
# 输入
# ============================================================
func _input(event: InputEvent) -> void:
	# 面板打开时：ESC 关闭，屏蔽其他操作
	if viewer_panel.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_on_viewer_close()
		return
	
	if event.is_action_pressed("end_turn") and CombatState.is_player_turn:
		_on_end_turn_pressed()
	
	# ── 调试快捷键 ──
	
	# ── 调试快捷键 ──
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_K:  # 秒杀敌人
				if CombatState.is_combat_active:
					CombatState.enemy_hp = 0
					CombatState._check_combat_end()
			KEY_H:  # 回满血
				if CombatState.is_combat_active:
					CombatState.player_hp = CombatState.player_max_hp
					GameState.current_hp = CombatState.player_max_hp
					CombatState.state_updated.emit()
			KEY_G:  # 加 100 金币
				GameState.add_gold(100)

# ============================================================
# 设置面板
# ============================================================
func _on_settings_pressed() -> void:
	settings_panel.visible = true
	_disable_hand()

func _on_settings_close() -> void:
	settings_panel.visible = false
	_enable_hand()

func _on_return_menu() -> void:
	# 保存当前状态到 GameState
	GameState.current_hp = CombatState.player_hp
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ============================================================
# 查看牌库 / 遗物
# ============================================================
func _on_view_deck() -> void:
	viewer_title.text = "牌库 (%d 张)" % GameState.deck.size()
	for c in viewer_list.get_children(): c.queue_free()
	for card in GameState.deck:
		var lbl = Label.new()
		lbl.text = "%s — %s" % [card.card_name, card.get_formatted_description()]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", card.get_type_color())
		lbl.custom_minimum_size = Vector2(520, 28)
		viewer_list.add_child(lbl)
	viewer_panel.visible = true
	_disable_hand()

func _on_view_relics() -> void:
	viewer_title.text = "遗物 (%d 个)" % GameState.relics.size()
	for c in viewer_list.get_children(): c.queue_free()
	if GameState.relics.is_empty():
		var lbl = Label.new()
		lbl.text = "暂无遗物"
		lbl.add_theme_font_size_override("font_size", 14)
		viewer_list.add_child(lbl)
	else:
		for relic in GameState.relics:
			var lbl = Label.new()
			lbl.text = "%s: %s" % [relic.relic_name, relic.description]
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
			lbl.custom_minimum_size = Vector2(520, 28)
			viewer_list.add_child(lbl)
	viewer_panel.visible = true
	_disable_hand()

func _on_view_exhaust() -> void:
	viewer_title.text = "消耗牌堆 (%d 张)" % CombatState.exhaust_pile.size()
	for c in viewer_list.get_children(): c.queue_free()
	if CombatState.exhaust_pile.is_empty():
		var lbl = Label.new()
		lbl.text = "暂无消耗的牌"
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		viewer_list.add_child(lbl)
	else:
		for card in CombatState.exhaust_pile:
			var lbl = Label.new()
			lbl.text = "%s (已消耗)" % card.card_name
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			lbl.custom_minimum_size = Vector2(520, 28)
			viewer_list.add_child(lbl)
	viewer_panel.visible = true
	_disable_hand()

func _on_viewer_close() -> void:
	viewer_panel.visible = false
	_enable_hand()

func _disable_hand() -> void:
	for node in card_ui_nodes:
		if is_instance_valid(node):
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _enable_hand() -> void:
	for node in card_ui_nodes:
		if is_instance_valid(node):
			node.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_viewer_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_viewer_close()
