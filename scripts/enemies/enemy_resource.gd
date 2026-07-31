# EnemyResource.gd
# 敌人数据资源 — 定义敌人的属性、意图模式
# 在 Godot 中作为 .tres 资源文件使用

class_name EnemyResource extends Resource

# 基础信息
@export var id: String = ""
@export var enemy_name: String = ""
@export var type: String = "normal"                  # normal | elite | boss

# 战斗数值
@export var max_hp: int = 30
@export var starting_block: int = 0

# 意图模式
@export var intent_pattern_type: String = "fixed_cycle"  # fixed_cycle | conditional | random_pool
@export var intent_pattern: Array[Dictionary] = []   # [{action, value, type}]

# 条件触发（仅 conditional 模式）
@export var conditional_trigger_hp_percent: float = 0.5
@export var conditional_pattern: Array[Dictionary] = []

# 战斗奖励
@export var gold_reward_min: int = 10
@export var gold_reward_max: int = 20

# 根据当前回合获取意图
# turn_number 从 0 开始
func get_intent(turn_number: int, current_hp: int) -> Dictionary:
	# 条件触发模式
	if intent_pattern_type == "conditional" and current_hp <= max_hp * conditional_trigger_hp_percent:
		if conditional_pattern.size() > 0:
			var idx = turn_number % conditional_pattern.size()
			return conditional_pattern[idx]
	
	match intent_pattern_type:
		"fixed_cycle":
			if intent_pattern.size() > 0:
				var idx = turn_number % intent_pattern.size()
				return intent_pattern[idx]
		"random_pool":
			if intent_pattern.size() > 0:
				return intent_pattern[randi() % intent_pattern.size()]
	
	return {"action": "attack", "value": 1, "type": "attack"}
