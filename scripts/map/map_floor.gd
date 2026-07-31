# MapFloor.gd
# 地图楼层 — 管理一层地图的所有节点和玩家位置

class_name MapFloor extends RefCounted

var nodes: Dictionary = {}             # id → MapNodeData
var rows: int
var cols: int
var current_node_id: String
var floor_number: int

func get_node(id: String) -> MapNodeData:
	return nodes.get(id, null)

func get_current_node() -> MapNodeData:
	return nodes.get(current_node_id, null)

func get_available_next_nodes() -> Array[MapNodeData]:
	var current = get_current_node()
	if current == null:
		return []
	var result: Array[MapNodeData] = []
	for conn_id in current.connections:
		var node = nodes.get(conn_id, null)
		if node:
			result.append(node)
	return result

func mark_cleared(node_id: String) -> void:
	var node = nodes.get(node_id, null)
	if node:
		node.cleared = true

func move_to(node_id: String) -> bool:
	var node = nodes.get(node_id, null)
	if node == null or node.cleared:
		return false
	current_node_id = node_id
	return true
