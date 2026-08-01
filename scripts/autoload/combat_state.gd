# CombatState.gd
# 战斗状态 Autoload 单例
# 管理核心战斗逻辑：回合流转、牌堆操作、伤害结算、Buff/Debuff

extends Node

# ============================================================
# 信号
# ============================================================
signal combat_started()
signal combat_ended(victory: bool)
signal turn_started(turn_number: int)
signal player_turn_started()
signal enemy_turn_started()
signal card_played(card: CardResource)
signal card_drawn(card: CardResource)
signal damage_dealt(target: String, amount: int)
signal block_gained(target: String, amount: int)
signal hp_changed(target: String, current_hp: int, max_hp: int)
signal energy_changed(current: int, max_energy: int)
signal state_updated()  # UI 刷新信号

# ============================================================
# 玩家战斗数值
# ============================================================
var player_hp: int = 70
var player_max_hp: int = 70
var player_block: int = 0
var player_energy: int = 3
var player_energy_per_turn: int = 3
var player_strength: int = 0       # 力量：+攻击伤害
var player_dexterity: int = 0      # 敏捷：+格挡获得
var player_vulnerable: int = 0     # 易伤层数（回合数）
var player_weak: int = 0           # 虚弱层数
var player_poison: int = 0         # 中毒层数

# ============================================================
# 敌人战斗数值
# ============================================================
var enemy_hp: int = 30
var enemy_max_hp: int = 30
var enemy_block: int = 0
var enemy_vulnerable: int = 0
var enemy_weak: int = 0
var enemy_poison: int = 0
var enemy_strength: int = 0
var cached_enemy_intent: Dictionary = {}   # 缓存当前回合敌人意图

# ============================================================
# 牌堆管理
# ============================================================
var draw_pile: Array = []          # 抽牌堆
var hand: Array = []               # 手牌
var discard_pile: Array = []       # 弃牌堆
var exhaust_pile: Array = []       # 消耗堆
var max_hand_size: int = 10
var cards_per_turn: int = 5

# ============================================================
# 战斗状态
# ============================================================
var turn_number: int = 0
var is_player_turn: bool = true
var is_combat_active: bool = false
var current_enemy_resource: EnemyResource = null
var player_relics: Array = []      # 玩家当前遗物

# ============================================================
# 战斗初始化
# ============================================================
func start_combat(deck: Array, enemy_res: EnemyResource) -> void:
	# 清空所有堆
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	
	# 初始化牌组（复制以避免修改原数据）
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	
	# 设置敌人
	current_enemy_resource = enemy_res
	enemy_max_hp = enemy_res.max_hp
	enemy_hp = enemy_max_hp
	enemy_block = enemy_res.starting_block
	enemy_vulnerable = 0
	enemy_weak = 0
	enemy_poison = 0
	enemy_strength = 0
	
	# 重置玩家战斗状态
	player_block = 0
	player_energy = player_energy_per_turn
	player_strength = 0
	player_dexterity = 0
	player_vulnerable = 0
	player_weak = 0
	player_poison = 0
	
	# 战斗开始
	turn_number = 1
	is_combat_active = true
	is_player_turn = true
	
	combat_started.emit()
	
	# 初始抽牌
	draw_initial_hand()
	
	player_turn_started.emit()
	state_updated.emit()

# 初始手牌
func draw_initial_hand() -> void:
	for i in range(cards_per_turn):
		_draw_one_card()

# 抽一张牌
func _draw_one_card() -> bool:
	if hand.size() >= max_hand_size:
		return false
	
	if draw_pile.is_empty():
		_reshuffle_discard_into_draw()
	
	if draw_pile.is_empty():
		return false
	
	var card = draw_pile.pop_back()
	hand.append(card)
	card_drawn.emit(card)
	return true

# 洗牌
func _reshuffle_discard_into_draw() -> void:
	if discard_pile.is_empty():
		return
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()

# ============================================================
# 出牌
# ============================================================
func play_card(card: CardResource) -> bool:
	if not is_player_turn or not is_combat_active:
		return false
	
	var cost = card.get_cost()
	if player_energy < cost:
		return false
	
	if not hand.has(card):
		return false
	
	# 扣除能量
	player_energy -= cost
	
	# 从手牌移除
	hand.erase(card)
	
	# 执行卡牌效果
	_execute_card_effect(card)
	
	# 根据关键词决定去向
	if "exhaust" in card.keywords or card.type == "power":
		exhaust_pile.append(card)
	else:
		discard_pile.append(card)
	
	card_played.emit(card)
	state_updated.emit()
	
	# 检查战斗结束
	_check_combat_end()
	
	return true

func _execute_card_effect(card: CardResource) -> void:
	# 力量加成
	var strength_bonus = max(0, player_strength)
	
	# 伤害
	var dmg = card.get_damage()
	if dmg > 0:
		dmg += strength_bonus
		deal_damage_to_enemy(dmg)
	
	# 格挡
	var blk = card.get_block()
	if blk > 0:
		blk += player_dexterity
		gain_block("player", blk)
	
	# 抽牌
	var draw = card.get_draw()
	for i in range(draw):
		_draw_one_card()
	
	# 特殊效果
	match card.special_effect:
		"vulnerable_2":  apply_vulnerable("enemy", 2)
		"vulnerable_1":  apply_vulnerable("enemy", 1)
		"weak_2":        apply_weak("enemy", 2)
		"weak_1":        apply_weak("enemy", 1)
		"poison_3":      apply_poison("enemy", 3)
		"strength_2":    player_strength += 2
		"draw_1":        _draw_one_card()
		"draw_2":        for _i in range(2): _draw_one_card()
		"hit_twice":     
			for _i in range(2):
				deal_damage_to_enemy(dmg)
		"hit_thrice":
			for _i in range(3):
				deal_damage_to_enemy(dmg)
		"lose_hp_2":
			player_hp = max(0, player_hp - 2)
			hp_changed.emit("player", player_hp, player_max_hp)
		"lose_hp_3_gain_2_energy":
			player_hp = max(0, player_hp - 3)
			player_energy += 2
			hp_changed.emit("player", player_hp, player_max_hp)
		"strength_3_hp_loss_1":
			player_strength += 3
			# berserker per-turn hp loss handled in _apply_power_effects

# ============================================================
# 伤害与格挡
# ============================================================
func deal_damage_to_enemy(amount: int) -> void:
	var final_dmg = amount
	
	# 易伤乘算
	if enemy_vulnerable > 0:
		final_dmg = int(ceil(final_dmg * 1.5))
	
	# 先扣格挡
	if enemy_block > 0:
		if final_dmg >= enemy_block:
			final_dmg -= enemy_block
			enemy_block = 0
		else:
			enemy_block -= final_dmg
			final_dmg = 0
	
	enemy_hp -= final_dmg
	damage_dealt.emit("enemy", final_dmg)
	hp_changed.emit("enemy", enemy_hp, enemy_max_hp)

func deal_damage_to_player(amount: int) -> void:
	var final_dmg = amount
	
	# 虚弱减算
	if player_weak > 0:
		final_dmg = int(ceil(final_dmg * 0.75))
	
	# 先扣格挡
	if player_block > 0:
		if final_dmg >= player_block:
			final_dmg -= player_block
			player_block = 0
		else:
			player_block -= final_dmg
			final_dmg = 0
	
	player_hp -= final_dmg
	damage_dealt.emit("player", final_dmg)
	hp_changed.emit("player", player_hp, player_max_hp)
	
	# 荆棘斗篷：玩家受伤时敌人受反伤
	if enemy_hp > 0:
		for relic in GameState.relics:
			if relic.trigger == "on_hit" and relic.effect_type == "thorns":
				enemy_hp -= relic.effect_value
				hp_changed.emit("enemy", enemy_hp, enemy_max_hp)
				break

func gain_block(target: String, amount: int) -> void:
	if target == "player":
		player_block += amount
		block_gained.emit("player", amount)
	else:
		enemy_block += amount
		block_gained.emit("enemy", amount)

# ============================================================
# Buff/Debuff
# ============================================================
func apply_vulnerable(target: String, stacks: int) -> void:
	if target == "enemy":
		enemy_vulnerable = max(enemy_vulnerable, stacks)  # 不叠加，取最大值
	else:
		player_vulnerable = max(player_vulnerable, stacks)

func apply_weak(target: String, stacks: int) -> void:
	if target == "enemy":
		enemy_weak = max(enemy_weak, stacks)
	else:
		player_weak = max(player_weak, stacks)

func apply_poison(target: String, stacks: int) -> void:
	if target == "enemy":
		enemy_poison += stacks
	else:
		player_poison += stacks

# 回合计时器递减
func _tick_debuffs(target: String) -> void:
	if target == "player":
		if player_vulnerable > 0: player_vulnerable -= 1
		if player_weak > 0: player_weak -= 1
		if player_poison > 0:
			player_hp -= player_poison
			player_poison = max(0, player_poison - 1)
			hp_changed.emit("player", player_hp, player_max_hp)
	else:
		if enemy_vulnerable > 0: enemy_vulnerable -= 1
		if enemy_weak > 0: enemy_weak -= 1
		if enemy_poison > 0:
			enemy_hp -= enemy_poison
			enemy_poison = max(0, enemy_poison - 1)
			hp_changed.emit("enemy", enemy_hp, enemy_max_hp)

# ============================================================
# 回合管理
# ============================================================
func end_player_turn() -> void:
	if not is_player_turn or not is_combat_active:
		return
	
	# 玩家回合结束 → 清除敌人上一轮的格挡（新一轮敌人行动即将开始）
	enemy_block = 0
	
	# 回合结束：手牌进弃牌堆
	var cards_to_discard: Array = []
	for card in hand:
		if "retain" in card.keywords:
			continue  # 保留牌留在手中
		elif "ethereal" in card.keywords:
			exhaust_pile.append(card)
			cards_to_discard.append(card)
		else:
			discard_pile.append(card)
			cards_to_discard.append(card)
	
	for card in cards_to_discard:
		hand.erase(card)
	
	# 进入敌人回合
	is_player_turn = false
	enemy_turn_started.emit()
	state_updated.emit()

# 敌人回合结束时调用（由 BattleManager 在敌人行动后调用）
func end_enemy_turn() -> void:
	if is_player_turn or not is_combat_active:
		return
	
	# 计时 debuff
	_tick_debuffs("player")
	_tick_debuffs("enemy")
	
	# 格挡清零（仅玩家）
	player_block = 0
	
	# 应用能力牌每回合效果
	_apply_power_effects()
	
	# 检查战斗结束
	if _check_combat_end():
		return
	
	# 清空意图缓存，下回合重新生成
	cached_enemy_intent.clear()
	
	# 进入玩家回合
	turn_number += 1
	is_player_turn = true
	
	# 恢复能量
	player_energy = player_energy_per_turn
	
	# 立刻生成并缓存下一轮敌人意图（玩家回合内不再变化）
	cached_enemy_intent = _generate_raw_intent()
	
	# 抽牌
	for i in range(cards_per_turn):
		_draw_one_card()
	
	player_turn_started.emit()
	state_updated.emit()

# 应用能力牌每回合效果（demon_form, berserker, burn 等）
func _apply_power_effects() -> void:
	for card in exhaust_pile:
		match card.special_effect:
			"strength_per_turn_2":
				player_strength += 2
			"strength_3_hp_loss_1":
				player_hp = max(0, player_hp - 1)
				hp_changed.emit("player", player_hp, player_max_hp)
			"poison_3":
				if enemy_hp > 0:
					apply_poison("enemy", 3)

# 战斗结束检查
func _check_combat_end() -> bool:
	if player_hp <= 0:
		# 凤凰羽毛：致命伤害时复活
		for relic in GameState.relics:
			if relic.trigger == "on_death" and relic.effect_type == "revive_30":
				player_hp = int(player_max_hp * 0.3)
				GameState.relics.erase(relic)  # 一次性，用后移除
				hp_changed.emit("player", player_hp, player_max_hp)
				state_updated.emit()
				return false  # 继续战斗
		is_combat_active = false
		is_player_turn = false
		combat_ended.emit(false)
		state_updated.emit()
		return true
	
	if enemy_hp <= 0:
		# 亡者印记：击杀敌人回血
		for relic in GameState.relics:
			if relic.trigger == "on_enemy_killed" and relic.effect_type == "heal":
				player_hp = min(player_max_hp, player_hp + relic.effect_value)
		is_combat_active = false
		is_player_turn = false
		combat_ended.emit(true)
		state_updated.emit()
		return true
	
	return false

# ============================================================
# 敌人意图查询
# ============================================================
func get_enemy_intent() -> Dictionary:
	if not cached_enemy_intent.is_empty():
		return cached_enemy_intent
	return _generate_raw_intent()

# 内部：从敌人资源生成原始意图（会受 randi 影响）
func _generate_raw_intent() -> Dictionary:
	if current_enemy_resource == null:
		return {"action": "attack", "value": 1, "type": "attack"}
	
	# duplicate 防止修改资源里的原始 Dictionary
	var intent = current_enemy_resource.get_intent(turn_number - 1, enemy_hp).duplicate()
	
	# 力量加成（现在改的是副本，不会污染 .tres）
	if enemy_strength > 0 and intent.get("action", "") == "attack":
		intent["value"] = intent.get("value", 0) + enemy_strength
	
	return intent

# 执行敌人意图
func execute_enemy_intent(intent: Dictionary) -> void:
	match intent.get("action", ""):
		"attack":
			var dmg = intent.get("value", 0)
			if enemy_strength > 0:
				dmg += enemy_strength
			deal_damage_to_player(dmg)
		"block":
			var blk = intent.get("value", 0)
			gain_block("enemy", blk)
		"buff":
			match intent.get("buff_type", ""):
				"strength": enemy_strength += intent.get("buff_amount", 0)
		"debuff":
			match intent.get("buff_type", ""):
				"vulnerable": apply_vulnerable("player", intent.get("buff_amount", 0))
				"weak": apply_weak("player", intent.get("buff_amount", 0))
	
	state_updated.emit()

# ============================================================
# 工具函数
# ============================================================
func can_play_card(card: CardResource) -> bool:
	return is_player_turn and is_combat_active and player_energy >= card.get_cost()
