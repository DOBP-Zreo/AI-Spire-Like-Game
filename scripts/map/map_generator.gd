# MapGenerator.gd
# 地图生成器 — 生成有向无环图（DAG）楼层地图
# 保证 2-3 条可用路径，满足房间分布规则

class_name MapGenerator extends RefCounted

const ROWS = 8       # 含起点和 Boss
const COLS = 3

# 敌人池（按楼层分配）
static var enemy_pools: Dictionary = {
	1: ["slime_green", "slime_red", "skeleton"],
	2: ["slime_green", "slime_red", "skeleton", "fire_elemental"],
	3: ["slime_red", "skeleton", "fire_elemental", "goblin_captain"],
}

static var elite_pools: Dictionary = {
	1: ["goblin_captain"],
	2: ["goblin_captain", "dark_knight"],
	3: ["dark_knight"],
}

static var boss_pools: Dictionary = {
	1: ["slime_king"],
	2: ["fire_lord"],
	3: ["spire_heart"],
}

# 生成一个楼层地图
static func generate_floor(floor_number: int) -> MapFloor:
	var floor = MapFloor.new()
	floor.rows = ROWS
	floor.cols = COLS
	floor.floor_number = floor_number
	
	# Step 1: 创建所有节点（先全部设为 battle）
	var grid: Array = []   # grid[row][col]
	for r in range(ROWS):
		var row_nodes: Array = []
		for c in range(COLS):
			var node_id = "r%d_c%d" % [r, c]
			var node = MapNodeData.new(node_id, "battle", r, c)
			floor.nodes[node_id] = node
			row_nodes.append(node)
		grid.append(row_nodes)
	
	# Step 2: 合并第 0 行和第 7 行为单节点（起点和 Boss 居中）
	_setup_start_and_boss(floor, grid, floor_number)
	
	# Step 3: 分配房间类型
	_assign_room_types(floor, grid, floor_number)
	
	# Step 4: 生成连接
	_generate_connections(floor, grid)
	
	# Step 5: 设置起点
	floor.current_node_id = "r0_c1"
	
	return floor

# 设置起点和 Boss
static func _setup_start_and_boss(floor: MapFloor, grid: Array, floor_num: int) -> void:
	# 起点：第 0 行居中
	var start = grid[0][1]
	start.room_type = "start"
	# 移除两边
	floor.nodes.erase(grid[0][0].id)
	floor.nodes.erase(grid[0][2].id)
	grid[0][0] = null
	grid[0][2] = null
	
	# Boss：最后一行居中
	var boss = grid[ROWS - 1][1]
	boss.room_type = "boss"
	boss.enemy_pool = boss_pools.get(floor_num, ["slime_king"])
	floor.nodes.erase(grid[ROWS - 1][0].id)
	floor.nodes.erase(grid[ROWS - 1][2].id)
	grid[ROWS - 1][0] = null
	grid[ROWS - 1][2] = null

# 分配房间类型
static func _assign_room_types(floor: MapFloor, grid: Array, floor_num: int) -> void:
	# 可用行：1 到 ROWS-2（排除起点和 Boss）
	var available_rows = range(1, ROWS - 1)
	var used_positions: Array = []  # [[row, col], ...]
	
	# 精英（1 个，不能和 Boss 同行，第一层 1 个）
	var elite_count = 1 if floor_num == 1 else 2
	for _i in range(elite_count):
		var pos = _pick_available(available_rows, COLS, used_positions, {"exclude_last_row": true})
		if pos:
			used_positions.append(pos)
			grid[pos[0]][pos[1]].room_type = "elite"
			grid[pos[0]][pos[1]].enemy_pool = elite_pools.get(floor_num, ["goblin_captain"])
	
	# 商店（1 个）
	var pos = _pick_available(available_rows, COLS, used_positions, {"exclude_last_row": true})
	if pos:
		used_positions.append(pos)
		grid[pos[0]][pos[1]].room_type = "shop"
	
	# 休息点（1 个，不能紧挨 Boss）
	pos = _pick_available(available_rows, COLS, used_positions, {"exclude_last_two_rows": true})
	if pos:
		used_positions.append(pos)
		grid[pos[0]][pos[1]].room_type = "rest"
	
	# 宝箱（1 个）
	pos = _pick_available(available_rows, COLS, used_positions, {})
	if pos:
		used_positions.append(pos)
		grid[pos[0]][pos[1]].room_type = "treasure"
	
	# 事件（2 个）
	for _i in range(2):
		pos = _pick_available(available_rows, COLS, used_positions, {})
		if pos:
			used_positions.append(pos)
			grid[pos[0]][pos[1]].room_type = "event"
	
	# 剩余全部是普通战斗
	var enemy_pool_list = enemy_pools.get(floor_num, ["slime_green"])
	for r in range(1, ROWS - 1):
		for c in range(COLS):
			if grid[r][c] and grid[r][c].room_type == "battle":
				grid[r][c].enemy_pool = enemy_pool_list.duplicate()

# 选择可用位置
static func _pick_available(rows: Array, cols: int, used: Array, rules: Dictionary) -> Array:
	var candidates: Array = []
	for r in rows:
		if rules.get("exclude_last_row", false) and r == rows[-1]:
			continue
		if rules.get("exclude_last_two_rows", false) and r >= rows[-2]:
			continue
		for c in range(cols):
			var is_used = false
			for u in used:
				if u[0] == r and u[1] == c:
					is_used = true
					break
			if not is_used:
				candidates.append([r, c])
	
	if candidates.is_empty():
		return []
	
	candidates.shuffle()
	return candidates[0]

# 生成 DAG 连接 — 每个节点优先连正上方（同列），形成路线，可分支到相邻列
static func _generate_connections(floor: MapFloor, grid: Array) -> void:
	for r in range(ROWS - 1):
		for c in range(COLS):
			var cur = grid[r][c]
			if cur == null:
				continue
			
			# 1. 始终连接正上方节点（同列，保持路线）
			var above = grid[r + 1][c]
			if above:
				cur.connections.append(above.id)
			else:
				# 上方无节点：在相邻列找最近的
				for delta in [1, -1]:
					var nc = c + delta
					if nc >= 0 and nc < COLS:
						var nbr = grid[r + 1][nc]
						if nbr:
							cur.connections.append(nbr.id)
							break
			
			# 2. 50% 概率额外分支到相邻列
			if randi() % 2 == 0:
				if c > 0:
					var left = grid[r + 1][c - 1]
					if left and left.id not in cur.connections:
						cur.connections.append(left.id)
			
			if randi() % 2 == 0:
				if c < COLS - 1:
					var right = grid[r + 1][c + 1]
					if right and right.id not in cur.connections:
						cur.connections.append(right.id)
		
		# 3. 确保每列的下排节点至少有 1 个入度
		for c2 in range(COLS):
			var nxt = grid[r + 1][c2]
			if nxt == null:
				continue
			var has_incoming = false
			for c3 in range(COLS):
				var src = grid[r][c3]
				if src and nxt.id in src.connections:
					has_incoming = true
					break
			if not has_incoming:
				# 从最近的邻居补一条连接
				for c3 in range(COLS):
					var src = grid[r][c3]
					if src:
						src.connections.append(nxt.id)
						break
		
		# 4. 去重
		for c2 in range(COLS):
			var cur2 = grid[r][c2]
			if cur2 == null:
				continue
			var seen: Array = []
			var unique_conns: Array[String] = []
			for conn in cur2.connections:
				if conn not in seen:
					seen.append(conn)
					unique_conns.append(conn)
			cur2.connections.assign(unique_conns)
