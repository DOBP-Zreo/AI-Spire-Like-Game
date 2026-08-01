# CardDatabase.gd
# 卡牌数据库 — 静态数据，提供所有卡牌定义
# 用于按 ID 查找卡牌、生成战利品池

class_name CardDatabase

# 卡牌 ID 映射表（实际卡牌资源从 .tres 文件加载）
static var card_ids: Dictionary = {
	# 基础卡牌
	"strike":       {"name": "挥砍",       "type": "attack", "cost": 1, "rarity": "basic",   "desc": "造成 {damage} 点伤害",                       "dmg": 6, "blk": 0, "draw": 0, "upgraded_dmg": 9, "upgraded_blk": 0, "upgraded_draw": 0, "effect": ""},
	"defend":       {"name": "守势",       "type": "skill",  "cost": 1, "rarity": "basic",   "desc": "获得 {block} 点格挡",                       "dmg": 0, "blk": 5, "draw": 0, "upgraded_dmg": 0, "upgraded_blk": 8, "upgraded_draw": 0, "effect": ""},
	
	# 普通攻击牌
	"heavy_strike": {"name": "猛劈",       "type": "attack", "cost": 2, "rarity": "common",  "desc": "造成 {damage} 点伤害",                       "dmg": 12, "blk": 0, "draw": 0, "upgraded_dmg": 16, "upgraded_blk": 0, "upgraded_draw": 0, "effect": ""},
	"pommel_strike":{"name": "柄击",       "type": "attack", "cost": 1, "rarity": "common",  "desc": "造成 {damage} 点伤害，抽 1 张牌",       "dmg": 5, "blk": 0, "draw": 0, "upgraded_dmg": 8, "upgraded_blk": 0, "upgraded_draw": 0, "effect": "draw_1"},
	"dash":         {"name": "突进",       "type": "attack", "cost": 1, "rarity": "common",  "desc": "造成 {damage} 点伤害，获得 {block} 点格挡",   "dmg": 4, "blk": 4, "draw": 0, "upgraded_dmg": 7, "upgraded_blk": 7, "upgraded_draw": 0, "effect": ""},
	"focus_strike": {"name": "凝神",       "type": "skill",  "cost": 0, "rarity": "common",  "desc": "获得 {block} 点格挡，消耗",                  "dmg": 0, "blk": 3, "draw": 0, "upgraded_dmg": 0, "upgraded_blk": 5, "upgraded_draw": 0, "effect": "",  "keywords": ["exhaust"]},
	
	# 普通技能牌
	"iron_wall":    {"name": "坚壁",       "type": "skill",  "cost": 2, "rarity": "common",  "desc": "获得 {block} 点格挡",                       "dmg": 0, "blk": 10, "draw": 0, "upgraded_dmg": 0, "upgraded_blk": 14, "upgraded_draw": 0, "effect": ""},
	
	# 罕见卡牌
	"shock_strike": {"name": "裂地斩",     "type": "attack", "cost": 2, "rarity": "uncommon","desc": "造成 {damage} 点伤害，给予 2 层易伤",        "dmg": 8, "blk": 0, "draw": 0, "upgraded_dmg": 12, "upgraded_blk": 0, "upgraded_draw": 0, "effect": "vulnerable_2"},
	"fatal_blow":   {"name": "绝杀",       "type": "attack", "cost": 3, "rarity": "uncommon","desc": "造成 {damage} 点伤害，消耗",                  "dmg": 22, "blk": 0, "draw": 0, "upgraded_dmg": 28, "upgraded_blk": 0, "upgraded_draw": 0, "effect": "",  "keywords": ["exhaust"]},
	"burn":         {"name": "焚焰",       "type": "power",  "cost": 2, "rarity": "uncommon","desc": "每回合所有敌人受 3 点中毒",                "dmg": 0, "blk": 0, "draw": 0, "upgraded_dmg": 0, "upgraded_blk": 0, "upgraded_draw": 0, "effect": "poison_3"},
	
	# 剑士专属
	"battle_cry":   {"name": "战吼",       "type": "power",  "cost": 1, "rarity": "uncommon","desc": "获得 2 点力量",                              "dmg": 0, "blk": 0, "draw": 0, "upgraded_dmg": 0, "upgraded_blk": 0, "upgraded_draw": 0, "effect": "strength_2"},
	
	# 罕见攻击
	"cleave":       {"name": "横扫",       "type": "attack", "cost": 1, "rarity": "uncommon","desc": "造成 8 点伤害",                              "dmg": 8, "blk": 0, "draw": 0, "upgraded_dmg": 12, "upgraded_blk": 0, "upgraded_draw": 0, "effect": ""},
	"twin_strike":  {"name": "连斩",       "type": "attack", "cost": 1, "rarity": "uncommon","desc": "造成 5 点伤害 2 次",                       "dmg": 5, "blk": 0, "draw": 0, "upgraded_dmg": 7, "upgraded_blk": 0, "upgraded_draw": 0, "effect": "hit_twice"},
	"hemokinesis":  {"name": "血祭斩",     "type": "attack", "cost": 1, "rarity": "uncommon","desc": "造成 15 点伤害，失去 2 生命",             "dmg": 15, "blk": 0, "draw": 0, "upgraded_dmg": 20, "upgraded_blk": 0, "upgraded_draw": 0, "effect": "lose_hp_2"},
	
	# 罕见技能
	"shrug_off":    {"name": "轻蔑",       "type": "skill",  "cost": 1, "rarity": "uncommon","desc": "获得 8 点格挡，抽 1 张牌",                "dmg": 0, "blk": 8, "draw": 1, "upgraded_dmg": 0, "upgraded_blk": 11, "upgraded_draw": 1, "effect": ""},
	
	# 稀有卡牌
	"demon_form":   {"name": "魔化",       "type": "power",  "cost": 3, "rarity": "rare",    "desc": "每回合获得 2 点力量",                      "dmg": 0, "blk": 0, "draw": 0, "upgraded_dmg": 0, "upgraded_blk": 0, "upgraded_draw": 0, "effect": "strength_per_turn_2"},
	"ghostly_armor":{"name": "幻影甲",     "type": "skill",  "cost": 1, "rarity": "rare",    "desc": "获得 10 点格挡，虚无",                     "dmg": 0, "blk": 10, "draw": 0, "upgraded_dmg": 0, "upgraded_blk": 14, "upgraded_draw": 0, "effect": "", "keywords": ["ethereal"]},
	
	# 新卡牌
	"whirlwind":    {"name": "旋风斩",     "type": "attack", "cost": 2, "rarity": "uncommon","desc": "造成 5 点伤害 3 次",                       "dmg": 5, "blk": 0, "draw": 0, "upgraded_dmg": 7, "upgraded_blk": 0, "upgraded_draw": 0, "effect": "hit_thrice"},
	"dark_pact":    {"name": "暗影契约",   "type": "power",  "cost": 0, "rarity": "rare",    "desc": "失去 3 生命，获得 2 点能量",                "dmg": 0, "blk": 0, "draw": 0, "upgraded_dmg": 0, "upgraded_blk": 0, "upgraded_draw": 0, "effect": "lose_hp_3_gain_2_energy"},
	"frost_ward":   {"name": "冰霜守护",   "type": "skill",  "cost": 3, "rarity": "uncommon","desc": "获得 20 点格挡",                           "dmg": 0, "blk": 20, "draw": 0, "upgraded_dmg": 0, "upgraded_blk": 28, "upgraded_draw": 0, "effect": ""},
	"berserker":    {"name": "狂暴",       "type": "power",  "cost": 1, "rarity": "uncommon","desc": "获得 3 点力量，每回合失去 1 生命",        "dmg": 0, "blk": 0, "draw": 0, "upgraded_dmg": 0, "upgraded_blk": 0, "upgraded_draw": 0, "effect": "strength_3_hp_loss_1"},
	"venom_strike": {"name": "毒刃",       "type": "attack", "cost": 1, "rarity": "uncommon","desc": "造成 4 点伤害，施加 3 层中毒",           "dmg": 4, "blk": 0, "draw": 0, "upgraded_dmg": 6, "upgraded_blk": 0, "upgraded_draw": 0, "effect": "poison_3"},
	"echo_slash":   {"name": "回音斩",     "type": "attack", "cost": 2, "rarity": "common",  "desc": "造成 10 点伤害，抽 1 张牌",             "dmg": 10, "blk": 0, "draw": 1, "upgraded_dmg": 14, "upgraded_blk": 0, "upgraded_draw": 1, "effect": ""},
}

# 根据 ID 创建 CardResource
static func create_card(id: String) -> CardResource:
	if not card_ids.has(id):
		return null
	
	var data = card_ids[id]
	var card = CardResource.new()
	card.id = id
	card.card_name = data["name"]
	card.type = data["type"]
	card.cost = data["cost"]
	card.description = data["desc"]
	card.rarity = data["rarity"]
	var kw = data.get("keywords", [])
	card.keywords.assign(kw)
	card.base_damage = data["dmg"]
	card.base_block = data["blk"]
	card.base_draw = data["draw"]
	card.upgraded_damage = data["upgraded_dmg"]
	card.upgraded_block = data["upgraded_blk"]
	card.upgraded_draw = data["upgraded_draw"]
	card.special_effect = data["effect"]
	card.upgraded = false
	
	return card

# 获取战士初始牌组
static func get_warrior_starter_deck() -> Array[CardResource]:
	var deck: Array[CardResource] = []
	for i in range(5):
		deck.append(create_card("strike"))
	for i in range(4):
		deck.append(create_card("defend"))
	deck.append(create_card("battle_cry"))
	return deck
