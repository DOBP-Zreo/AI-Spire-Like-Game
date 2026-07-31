# MapData.gd
# 地图数据结构 — MapNode、MapFloor
# 用于地图生成和状态管理

class_name MapNodeData extends RefCounted

var id: String
var room_type: String       # "battle" | "elite" | "shop" | "rest" | "treasure" | "event" | "boss" | "start"
var row: int
var col: int
var connections: Array[String] = []   # 下一行可到达的节点 ID
var cleared: bool = false
var enemy_pool: Array = []             # 敌人 ID 列表（仅 battle/elite/boss）

func _init(p_id: String, p_type: String, p_row: int, p_col: int) -> void:
	id = p_id
	room_type = p_type
	row = p_row
	col = p_col

func get_display_name() -> String:
	match room_type:
		"battle":   return "战斗"
		"elite":    return "精英"
		"boss":     return "首领"
		"shop":     return "商店"
		"rest":     return "休息"
		"treasure": return "宝箱"
		"event":    return "事件"
		"start":    return "起点"
	return "未知"

func get_color() -> Color:
	match room_type:
		"battle":   return Color(0.7, 0.3, 0.3)     # 红色
		"elite":    return Color(0.8, 0.5, 0.1)     # 橙色
		"boss":     return Color(0.6, 0.1, 0.1)     # 深红
		"shop":     return Color(0.2, 0.6, 0.8)     # 蓝色
		"rest":     return Color(0.3, 0.7, 0.3)     # 绿色
		"treasure": return Color(0.8, 0.7, 0.2)     # 金色
		"event":    return Color(0.6, 0.3, 0.8)     # 紫色
		"start":    return Color(0.4, 0.8, 0.4)     # 亮绿
	return Color(0.5, 0.5, 0.5)


