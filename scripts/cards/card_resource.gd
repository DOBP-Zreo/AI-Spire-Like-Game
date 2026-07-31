# CardResource.gd
# 卡牌数据资源 — 定义单张卡牌的所有属性
# 在 Godot 中作为 .tres 资源文件使用

class_name CardResource extends Resource

# 基础信息
@export var id: String = ""                         # 唯一标识
@export var card_name: String = ""                  # 显示名称
@export var type: String = "attack"                 # attack | skill | power
@export var cost: int = 1                           # 能量消耗
@export var description: String = ""                # 描述文本（支持 {damage} {block} 占位符）
@export var rarity: String = "basic"                # basic | common | uncommon | rare
@export var keywords: Array[String] = []            # exhaust, retain, ethereal, innate 等

# 基础数值
@export var base_damage: int = 0
@export var base_block: int = 0
@export var base_draw: int = 0
@export var special_effect: String = ""             # 特殊效果标识符

# 升级属性
@export var upgraded: bool = false                  # 是否已升级
@export var upgraded_damage: int = 0
@export var upgraded_block: int = 0
@export var upgraded_draw: int = 0
@export var upgraded_cost: int = 1

# 获取当前伤害（考虑升级）
func get_damage() -> int:
	return upgraded_damage if upgraded and upgraded_damage > 0 else base_damage

# 获取当前格挡
func get_block() -> int:
	return upgraded_block if upgraded and upgraded_block > 0 else base_block

# 获取当前抽牌数
func get_draw() -> int:
	return upgraded_draw if upgraded and upgraded_draw > 0 else base_draw

# 获取当前费用
func get_cost() -> int:
	return upgraded_cost if upgraded else cost

# 获取格式化描述文本
func get_formatted_description() -> String:
	var desc = description
	if base_damage > 0 or upgraded_damage > 0:
		desc = desc.replace("{damage}", str(get_damage()))
	if base_block > 0 or upgraded_block > 0:
		desc = desc.replace("{block}", str(get_block()))
	if base_draw > 0 or upgraded_draw > 0:
		desc = desc.replace("{draw}", str(get_draw()))
	return desc

# 获取卡牌类型对应颜色
func get_type_color() -> Color:
	match type:
		"attack":
			return Color("#C44B4B")  # 红色
		"skill":
			return Color("#4B7FC4")  # 蓝色
		"power":
			return Color("#C4A44B")  # 黄色
		_:
			return Color("#666666")

# 获取稀有度对应颜色
func get_rarity_display() -> String:
	match rarity:
		"basic":   return "基础"
		"common":  return "普通"
		"uncommon": return "罕见"
		"rare":    return "稀有"
		_:         return "未知"
