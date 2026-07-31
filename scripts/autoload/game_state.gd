# GameState.gd
# 全局游戏状态 Autoload 单例
# 管理跨房间的持久数据：牌组、生命、金币、遗物、楼层

extends Node

# ============================================================
# 信号
# ============================================================
signal game_started()
signal game_over(victory: bool)
signal deck_changed()
signal gold_changed(amount: int)
signal hp_changed(current: int, max_hp: int)

# ============================================================
# 玩家持久状态
# ============================================================
var deck: Array = []                    # 当前牌组（CardResource 数组）
var relics: Array = []                  # 拥有的遗物
var gold: int = 99                      # 初始金币
var max_hp: int = 70                    # 最大生命（战士 70）
var current_hp: int = 70                # 当前生命
var floor_level: int = 1                # 当前楼层（1-3）
var character_class: String = "warrior" # 角色职业

# ============================================================
# 地图状态
# ============================================================
var current_floor_map = null            # MapFloor 对象（当前楼层地图）
var pending_enemy_id: String = ""       # 即将进入的战斗的敌人 ID
var pending_room_id: String = ""        # 即将进入的房间 ID
var map_seed: int = 0

# ============================================================
# 初始化 — 设置战士初始牌组
# ============================================================
func initialize_new_game() -> void:
	deck.clear()
	relics.clear()
	gold = 99
	max_hp = 70
	current_hp = max_hp
	floor_level = 1
	character_class = "剑士"
	
	# 清除所有旧地图/房间引用，防止残留数据导致从错误楼层开始
	current_floor_map = null
	pending_room_id = ""
	pending_enemy_id = ""
	
	_setup_starter_deck()
	_setup_starter_relics()
	
	game_started.emit()
	deck_changed.emit()

func _setup_starter_relics() -> void:
	var relic = load("res://resources/relics/burning_blood.tres")
	if relic:
		relics.append(relic)

func _setup_starter_deck() -> void:
	var strike_card = load("res://resources/cards/strike.tres")
	var defend_card = load("res://resources/cards/defend.tres")
	
	for i in range(5):
		deck.append(strike_card)
	for i in range(4):
		deck.append(defend_card)
	
	# 尝试加载额外卡牌（如果存在）
	var heavy_strike = load("res://resources/cards/heavy_strike.tres")
	if heavy_strike:
		deck.append(heavy_strike)
	
	var iron_wall = load("res://resources/cards/iron_wall.tres")
	if iron_wall:
		deck.append(iron_wall)

# 添加卡牌到牌组
func add_card_to_deck(card: CardResource) -> void:
	deck.append(card)
	deck_changed.emit()

# 从牌组移除卡牌
func remove_card_from_deck(card: CardResource) -> bool:
	var idx = deck.find(card)
	if idx >= 0:
		deck.remove_at(idx)
		deck_changed.emit()
		return true
	return false

# 修改金币
func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false

# 修改生命
func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)

func take_damage(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)
	hp_changed.emit(current_hp, max_hp)

# 获取牌组数量
func get_deck_size() -> int:
	return deck.size()
