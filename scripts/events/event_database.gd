# event_database.gd
# 事件数据库 — 定义所有随机事件
class_name EventDatabase extends RefCounted

# 事件结构: {title, story, options[{text, cost_type, cost_value, reward_type, reward_value}]}
# cost_type:  "" | "gold" | "hp" | "max_hp"
# reward_type: "" | "random_card" | "random_relic" | "heal_30" | "gold_100" | "blood_shop" | "transform"

static var events: Array = [
	{
		"title": "神秘宝箱", "story": "你在角落发现一个上锁的宝箱。撬开它？",
		"options": [
			{"text": "撬开宝箱",          "cost_type": "",       "cost_value": 0,   "reward_type": "random_relic", "reward_value": 0},
			{"text": "离开（无事发生）",   "cost_type": "",       "cost_value": 0,   "reward_type": "",            "reward_value": 0},
		]
	},
	{
		"title": "流浪商人", "story": "一位神秘的流浪商人向你兜售药水。喝下它？",
		"options": [
			{"text": "喝下药水（获得随机卡牌）", "cost_type": "",   "cost_value": 0,   "reward_type": "random_card",  "reward_value": 0},
			{"text": "拒绝",                  "cost_type": "",     "cost_value": 0,   "reward_type": "",             "reward_value": 0},
		]
	},
	{
		"title": "强盗拦路", "story": "一伙强盗挡住了去路，要求 80 金币过路费。",
		"options": [
			{"text": "交钱过路（-80 金币）",   "cost_type": "gold",  "cost_value": 80,  "reward_type": "",            "reward_value": 0},
			{"text": "强行通过（受到 15 伤害）","cost_type": "hp",    "cost_value": 15,  "reward_type": "",            "reward_value": 0},
		]
	},
	{
		"title": "废弃铁匠铺", "story": "你发现一间废弃的铁匠铺，可以花费 60 金币打造一件遗物。",
		"options": [
			{"text": "打造遗物（-60 金币）", "cost_type": "gold", "cost_value": 60,   "reward_type": "random_relic", "reward_value": 0},
			{"text": "离开",                "cost_type": "",    "cost_value": 0,    "reward_type": "",            "reward_value": 0},
		]
	},
	{
		"title": "神秘祭坛", "story": "一座古老的祭坛散发诡异光芒。献祭 8 点生命上限可获得一件遗物。",
		"options": [
			{"text": "献祭（-8 生命上限，获得遗物）","cost_type": "max_hp", "cost_value": 8,  "reward_type": "random_relic", "reward_value": 0},
			{"text": "离开",                        "cost_type": "",      "cost_value": 0,  "reward_type": "",            "reward_value": 0},
		]
	},
	{
		"title": "魔法喷泉", "story": "一口魔法喷泉涌出治愈之水。喝一口回复 30% 生命。旁边还有一袋金币。",
		"options": [
			{"text": "喝泉水（回复 30% 生命）", "cost_type": "",  "cost_value": 0,   "reward_type": "heal_30",    "reward_value": 0},
			{"text": "拿金币（+100 金币）",     "cost_type": "",  "cost_value": 0,   "reward_type": "gold_100",   "reward_value": 0},
		]
	},
	{
		"title": "诡异的紫色水晶", "story": "一颗紫色水晶发出脉动的光芒。触碰它会将一张卡牌转化为其他力量。",
		"options": [
			{"text": "触碰水晶（转化一张卡牌）", "cost_type": "",  "cost_value": 0,   "reward_type": "transform",  "reward_value": 0},
			{"text": "离开",                   "cost_type": "",  "cost_value": 0,   "reward_type": "",           "reward_value": 0},
		]
	},
	{
		"title": "血之古书", "story": "一本用血写成的古书摊开在石台上。它似乎能打开通往异界的商店。",
		"options": [
			{"text": "翻阅古书（进入血商店）", "cost_type": "",  "cost_value": 0,   "reward_type": "blood_shop", "reward_value": 0},
			{"text": "离开",                 "cost_type": "",  "cost_value": 0,   "reward_type": "",          "reward_value": 0},
		]
	},
	{
		"title": "沉睡的巨人", "story": "一个巨大石像在沉睡，旁边写着：唤醒者将受诅咒。",
		"options": [
			{"text": "唤醒巨人（受到 20 伤害，获得 2 件遗物）","cost_type": "hp", "cost_value": 20,  "reward_type": "relic_x2",  "reward_value": 0},
			{"text": "悄悄离开",                            "cost_type": "",   "cost_value": 0,   "reward_type": "",          "reward_value": 0},
		]
	},
]

static func get_random_event() -> Dictionary:
	return events[randi() % events.size()]
