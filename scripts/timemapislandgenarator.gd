extends Node2D
@export var tile_size: Vector2 = Vector2(16, 16)
@export var terrain_threshold: float = 0.2
@export var mountain_threshold: float = 0.8
@export var hill_size: Vector2i = Vector2i(5, 5)
@export var hill_count: int = 5
@export var grass_threshold: float = 0.5
@export var short_grass_threshold: float = 0.5
@export var rocks_threshold: float = 0.5
@export var packed_grass_threshold: float = 0.5
@export var grass_freq_main: float = 0.06
@export var grass_freq_short: float = 0.08
@export var grass_spawn_chance: int = 10
@export var min_island_area: int = 400
@export var max_generation_attempts: int = 8
@export var bots_count: int = 10
@export var scene_id_computer: int = 1
@export var scene_id_seat: int = 2
@export var scene_id_charger: int = 3
@export var scene_id_bot: int = 4
@export var scene_id_core: int = 5
@onready var bottom_items_layer: TileMapLayer = %BotItems
@onready var hill_layer: TileMapLayer = %hill
@onready var ground_decoration_layer: TileMapLayer = %stuffOnGround
@onready var grass_layer: TileMapLayer = $grass
@onready var underside_layer: TileMapLayer = %underside
const TILE_ATLAS: Dictionary = {
	"null" : Vector2i(-1, -1),
	"stone1" : Vector2i(8, 7),
	"stone2" : Vector2i(9, 7),
	"shroom1" : Vector2i(10, 6),
	"shroom2" : Vector2i(10, 7),
	"stumpl" : Vector2i(11, 7),
	"stumpr" : Vector2i(12, 7),
	"grass_collision_all" : Vector2i(21, 1),
	"grass_collision_navigation" : Vector2i(19, 2),
	"grass1" : Vector2i(13, 7),
	"grass2" : Vector2i(14, 7),
	"grass3" : Vector2i(15, 7),
	"packedgrass1" : Vector2i(19, 6),
	"packedgrass2" : Vector2i(20, 6),
	"packedgrass3" : Vector2i(21, 6),
	"grass" : Vector2i(4, 1),
	"grass_very_center" : Vector2i(2, 2),
	"grass_Top" : Vector2i(1, 0),
	"grass_Bottom" : Vector2i(1, 4),
	"grass_Left" : Vector2i(0, 3),
	"grass_Right" : Vector2i(5, 3),
	"grass_Center_end_Top" : Vector2i(8, 4),
	"grass_Center_end_Bottom" : Vector2i(7, 7),
	"grass_Center_end_Left" : Vector2i(6, 5),
	"grass_Center_end_Right" : Vector2i(9, 6),
	"grass_Center_strait_sideward" : Vector2i(7, 2),
	"grass_Center_strait_vertical" : Vector2i(8, 1),
	"grass_corner_Top_left" : Vector2i(0, 0),
	"grass_corner_Top_Right" : Vector2i(5, 0),
	"grass_corner_Bottom_Left" : Vector2i(0, 4),
	"grass_corner_Bottom_Right" : Vector2i(5, 4),
	"path_Center" : Vector2i(21, 4),
	"underside_Top_Middle" : Vector2i(1, 5),
	"underside_Top_Center" : Vector2i(5, 5),
	"underside_Top_left" : Vector2i(0, 5),
	"underside_Top_right" : Vector2i(2, 5),
	"underside_Center_Middle" : Vector2i(1, 6),
	"underside_Center_Center" : Vector2i(5, 6),
	"underside_Center_left" : Vector2i(0, 6),
	"underside_Center_right" : Vector2i(2, 6),
	"underside_Bottom_Middle" : Vector2i(1, 7),
	"underside_Bottom_Center" : Vector2i(5, 7),
	"underside_Bottom_left" : Vector2i(0, 7),
	"underside_Bottom_right" : Vector2i(2, 7),
	"hill" : Vector2i(17, 7),
	"hill_Center" : Vector2i(6, 6),
	"hill_Top" : Vector2i(17, 6),
	"hill_Bottom" : Vector2i(10, 0),
	"hill_Left" : Vector2i(16, 7),
	"hill_Right" : Vector2i(18, 7),
	"hill_Top_left" : Vector2i(16, 6),
	"hill_Top_Right" : Vector2i(18, 6),
	"hill_Bottom_Left" : Vector2i(9, 0),
	"hill_Bottom_Right" : Vector2i(11, 0),
	"hill_pilar" : Vector2i(10, 1),
	"hill_pilar_left" : Vector2i(9, 1),
	"hill_pilar_right" : Vector2i(11, 1),
	"hill_pilar_Center" : Vector2i(6, 7)
}
enum BaseType { EMPTY, GRASS, HILL }
enum GrassEdge { PLAIN, TOP, BOTTOM, LEFT, RIGHT, STRAIGHT_VERT, STRAIGHT_HOR, END_TOP, END_BOTTOM, END_LEFT, END_RIGHT, CORNER_TL, CORNER_TR, CORNER_BL, CORNER_BR, SINGLE }
enum HillEdge { CORE, TOP, BOTTOM, LEFT, RIGHT, TL, TR, BL, BR, PILLAR, PILLAR_L, PILLAR_R, PILLAR_CENTER }
enum Deco { NONE, PACKED1, PACKED2, PACKED3, SHORT1, SHORT2, SHORT3, STONE1, STONE2, SHROOM1, SHROOM2, STUMP_L, STUMP_R }
var _base: PackedInt32Array
var _grass_edge: PackedInt32Array
var _hill_edge: PackedInt32Array
var _decoration: PackedInt32Array
var _underside: PackedInt32Array
var _collision: PackedInt32Array
var _distance_mask: PackedFloat32Array
var core_tile_position: Vector2i = Vector2i.ZERO
var spawn_index: int = 0
var _seed: int
func _ready():
	_precompute_distance_mask()
	generate_map()
func _input(event):
	if event.is_action_pressed("jump"):
		generate_map()
func generate_map():
	var sx = Global.islandSize.x
	var sy = Global.islandSize.y
	var attempt = 0
	var success = false
	while attempt < max_generation_attempts and not success:
		attempt += 1
		_seed = randi()
		_resize_arrays(sx, sy)
		_clear_layers()
		var terrain_noise = _make_noise(_seed, 0.008)
		var grass_noise_main = _make_noise(_seed + 101, grass_freq_main)
		var grass_noise_short = _make_noise(_seed + 202, grass_freq_short)
		_pass_terrain(terrain_noise, sx, sy)
		_ensure_connectivity(sx, sy)
		var area = _count_grass()
		if area < min_island_area:
			continue
		_success_finalize(sx, sy, grass_noise_main, grass_noise_short)
		success = true
	if not success:
		_success_finalize(sx, sy, _make_noise(_seed + 101, grass_freq_main), _make_noise(_seed + 202, grass_freq_short))
func _success_finalize(sx:int, sy:int, grass_noise_main:FastNoiseLite, grass_noise_short:FastNoiseLite):
	_pass_place_hills(sx, sy)
	_pass_decorations(grass_noise_main, grass_noise_short, sx, sy)
	_pass_edges_and_underside(sx, sy)
	_pass_hill_edges_and_pillars(sx, sy)
	_pass_collision(sx, sy)
	_commit_to_tilemaps(sx, sy)
	_place_scenes_and_core(sx, sy)
func _count_grass() -> int:
	var c = 0
	for i in range(_base.size()):
		if _base[i] == BaseType.GRASS or _base[i] == BaseType.HILL:
			c += 1
	return c
func _pass_terrain(noise: FastNoiseLite, sx:int, sy:int):
	var best_val = -INF
	var best_index = 0
	var half_x = sx/2
	var half_y = sy/2
	spawn_index = half_x + half_y * sx
	for y in range(sy):
		var row = y * sx
		for x in range(sx):
			var idx = x + row
			var n = noise.get_noise_2d(x, y)
			if n > best_val:
				best_val = n
				best_index = idx
			var v = n * _distance_mask[idx]
			if v > mountain_threshold:
				_base[idx] = BaseType.HILL
			elif v > terrain_threshold:
				_base[idx] = BaseType.GRASS
			else:
				_base[idx] = BaseType.EMPTY
	if _base[spawn_index] == BaseType.EMPTY:
		_base[spawn_index] = BaseType.GRASS
func _ensure_connectivity(sx:int, sy:int):
	var labels := PackedInt32Array(); labels.resize(_base.size())
	for i in range(labels.size()): labels[i] = -1
	var queue: Array[int] = []
	var comp_sizes: Array[int] = []
	var comp_id = 0
	for i in range(_base.size()):
		if (_base[i] == BaseType.GRASS or _base[i] == BaseType.HILL) and labels[i] == -1:
			var size = 0
			queue.clear(); queue.append(i); labels[i] = comp_id
			while queue.size() > 0:
				var cur = queue.pop_back(); size += 1
				var cx = cur % sx; var cy = cur / sx
				if cx > 0:
					var ni = cur - 1
					if (_base[ni] == BaseType.GRASS or _base[ni] == BaseType.HILL) and labels[ni] == -1:
						labels[ni] = comp_id; queue.append(ni)
				if cx < sx - 1:
					var ni2 = cur + 1
					if (_base[ni2] == BaseType.GRASS or _base[ni2] == BaseType.HILL) and labels[ni2] == -1:
						labels[ni2] = comp_id; queue.append(ni2)
				if cy > 0:
					var ni3 = cur - sx
					if (_base[ni3] == BaseType.GRASS or _base[ni3] == BaseType.HILL) and labels[ni3] == -1:
						labels[ni3] = comp_id; queue.append(ni3)
				if cy < sy - 1:
					var ni4 = cur + sx
					if (_base[ni4] == BaseType.GRASS or _base[ni4] == BaseType.HILL) and labels[ni4] == -1:
						labels[ni4] = comp_id; queue.append(ni4)
			comp_sizes.append(size)
			comp_id += 1
	if comp_id <= 1: return
	var keep_label = labels[spawn_index]
	if keep_label == -1:
		var max_size = -1
		for cid in range(comp_id):
			if comp_sizes[cid] > max_size:
				max_size = comp_sizes[cid]
				keep_label = cid
	for i in range(_base.size()):
		if (_base[i] == BaseType.GRASS or _base[i] == BaseType.HILL) and labels[i] != keep_label:
			_base[i] = BaseType.EMPTY
func _pass_place_hills(sx:int, sy:int):
	var hsx = hill_size.x
	var hsy = hill_size.y
	var candidates: Array[Vector2i] = []
	for y in range(sy - hsy):
		for x in range(sx - hsx):
			var good = true
			for yy in range(hsy):
				var r = (y + yy) * sx
				for xx in range(hsx):
					var bt = _base[x + xx + r]
					if bt != BaseType.GRASS and bt != BaseType.HILL:
						good = false; break
				if not good: break
			if good: candidates.append(Vector2i(x, y))
	if candidates.is_empty(): return
	candidates.shuffle()
	var to_place = min(hill_count, candidates.size())
	for i in range(to_place):
		var top_left = candidates[i]
		for yy in range(hsy):
			var r2 = (top_left.y + yy) * sx
			for xx in range(hsx):
				_base[top_left.x + xx + r2] = BaseType.HILL
		if i == randi() % to_place:
			core_tile_position = Vector2i(top_left.x + hsx/2, top_left.y + hsy/2)
func _pass_decorations(n_main:FastNoiseLite, n_short:FastNoiseLite, sx:int, sy:int):
	for y in range(sy):
		var row = y * sx
		for x in range(sx):
			var idx = x + row
			if _base[idx] != BaseType.GRASS: continue
			if grass_spawn_chance > 1 and (_hash3(x, y, _seed) % grass_spawn_chance) != 0: continue
			var g_val = n_main.get_noise_2d(x + 1000, y)
			var s_val = n_short.get_noise_2d(x + 2000, y)
			if g_val > packed_grass_threshold:
				_decoration[idx] = Deco.PACKED1 + (_hash3(x, y, _seed) % 3)
			elif s_val > short_grass_threshold and s_val < rocks_threshold:
				_decoration[idx] = Deco.SHORT1 + (_hash3(x, y, _seed+11) % 3)
			elif s_val >= rocks_threshold:
				var h = _hash3(x, y, _seed+99) % 7
				match h:
					0: _decoration[idx] = Deco.STONE1
					1: _decoration[idx] = Deco.STONE2
					2: _decoration[idx] = Deco.SHROOM1
					3: _decoration[idx] = Deco.SHROOM2
					4,5:
						if x > 0 and _base[idx-1] == BaseType.GRASS and _decoration[idx-1] == Deco.NONE:
							_decoration[idx-1] = Deco.STUMP_L
							_decoration[idx] = Deco.STUMP_R
						else:
							_decoration[idx] = Deco.STONE2
					_: _decoration[idx] = Deco.STONE2
func _pass_edges_and_underside(sx:int, sy:int):
	for y in range(sy):
		var row = y * sx
		for x in range(sx):
			var idx = x + row
			var t = _base[idx]
			if t == BaseType.GRASS:
				var up = (y>0) and (_base[idx - sx] == BaseType.GRASS or _base[idx - sx] == BaseType.HILL)
				var down = (y<sy-1) and (_base[idx + sx] == BaseType.GRASS or _base[idx + sx] == BaseType.HILL)
				var left = (x>0) and (_base[idx - 1] == BaseType.GRASS or _base[idx - 1] == BaseType.HILL)
				var right = (x<sx-1) and (_base[idx + 1] == BaseType.GRASS or _base[idx + 1] == BaseType.HILL)
				var count_neighbors = int(up)+int(down)+int(left)+int(right)
				if count_neighbors == 4: _grass_edge[idx] = GrassEdge.PLAIN
				elif count_neighbors == 0: _grass_edge[idx] = GrassEdge.SINGLE
				elif left and right and (not up) and (not down): _grass_edge[idx] = GrassEdge.STRAIGHT_HOR
				elif up and down and (not left) and (not right): _grass_edge[idx] = GrassEdge.STRAIGHT_VERT
				elif (not up) and left and right and down: _grass_edge[idx] = GrassEdge.TOP
				elif (not down) and left and right and up: _grass_edge[idx] = GrassEdge.BOTTOM
				elif (not left) and up and down and right: _grass_edge[idx] = GrassEdge.LEFT
				elif (not right) and up and down and left: _grass_edge[idx] = GrassEdge.RIGHT
				elif (not up) and (not left) and right and down: _grass_edge[idx] = GrassEdge.CORNER_TL
				elif (not up) and (not right) and left and down: _grass_edge[idx] = GrassEdge.CORNER_TR
				elif (not down) and (not left) and right and up: _grass_edge[idx] = GrassEdge.CORNER_BL
				elif (not down) and (not right) and left and up: _grass_edge[idx] = GrassEdge.CORNER_BR
				elif (not up) and (not left) and (not right) and down: _grass_edge[idx] = GrassEdge.END_TOP
				elif (not down) and (not left) and (not right) and up: _grass_edge[idx] = GrassEdge.END_BOTTOM
				elif (not left) and (not up) and (not down) and right: _grass_edge[idx] = GrassEdge.END_LEFT
				elif (not right) and (not up) and (not down) and left: _grass_edge[idx] = GrassEdge.END_RIGHT
				else: _grass_edge[idx] = GrassEdge.PLAIN
			elif t == BaseType.EMPTY:
				if y>0 and (_base[idx - sx] == BaseType.GRASS or _base[idx - sx] == BaseType.HILL):
					var up_left = (x>0) and (_base[idx - sx - 1] == BaseType.GRASS or _base[idx - sx - 1] == BaseType.HILL)
					var up_right = (x<sx-1) and (_base[idx - sx + 1] == BaseType.GRASS or _base[idx - sx + 1] == BaseType.HILL)
					if up_left and up_right: _underside[idx] = 1
					elif (not up_left) and up_right: _underside[idx] = 2
					elif up_left and (not up_right): _underside[idx] = 3
					else: _underside[idx] = 4
				elif y>0:
					match _underside[idx - sx]:
						4: _underside[idx] = 8
						2: _underside[idx] = 6
						1: _underside[idx] = 5
						3: _underside[idx] = 7
						8: _underside[idx] = 12
						6: _underside[idx] = 10
						5: _underside[idx] = 9
						7: _underside[idx] = 11
	for y in range(sy):
		var row2 = y * sx
		for x in range(sx):
			var idx2 = x + row2
			if _base[idx2] == BaseType.GRASS:
				var full = true
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						if ox == 0 and oy == 0: continue
						var nx = x + ox; var ny = y + oy
						if nx < 0 or nx >= sx or ny < 0 or ny >= sy or _base[nx + ny * sx] == BaseType.EMPTY:
							full = false; break
					if not full: break
				if full: _grass_edge[idx2] = GrassEdge.PLAIN
func _pass_hill_edges_and_pillars(sx:int, sy:int):
	for y in range(sy):
		var row = y * sx
		for x in range(sx):
			var idx = x + row
			if _base[idx] == BaseType.HILL:
				var up = (y>0) and _base[idx - sx] == BaseType.HILL
				var down = (y<sy-1) and _base[idx + sx] == BaseType.HILL
				var left = (x>0) and _base[idx - 1] == BaseType.HILL
				var right = (x<sx-1) and _base[idx + 1] == BaseType.HILL
				if not left and not right and not up and not down:
					_hill_edge[idx] = HillEdge.CORE
				elif not up and left and right and down:
					_hill_edge[idx] = HillEdge.TOP
				elif not down and left and right and up:
					_hill_edge[idx] = HillEdge.BOTTOM
				elif not left and up and down and right:
					_hill_edge[idx] = HillEdge.LEFT
				elif not right and up and down and left:
					_hill_edge[idx] = HillEdge.RIGHT
				elif not up and not left and right and down:
					_hill_edge[idx] = HillEdge.TL
				elif not up and not right and left and down:
					_hill_edge[idx] = HillEdge.TR
				elif not down and not left and right and up:
					_hill_edge[idx] = HillEdge.BL
				elif not down and not right and left and up:
					_hill_edge[idx] = HillEdge.BR
				else:
					_hill_edge[idx] = HillEdge.CORE
			elif _base[idx] == BaseType.EMPTY:
				if y>0 and _base[idx - sx] == BaseType.HILL:
					var up_left = (x>0) and _base[idx - sx - 1] == BaseType.HILL
					var up_right = (x<sx-1) and _base[idx - sx + 1] == BaseType.HILL
					if up_left and up_right: _hill_edge[idx] = HillEdge.PILLAR
					elif up_left and not up_right: _hill_edge[idx] = HillEdge.PILLAR_R
					elif up_right and not up_left: _hill_edge[idx] = HillEdge.PILLAR_L
					else: _hill_edge[idx] = HillEdge.PILLAR_CENTER
	for y in range(sy-1):
		var rowb = y * sx
		for x in range(sx):
			var idxb = x + rowb
			if _base[idxb] == BaseType.HILL and _base[idxb + sx] != BaseType.HILL:
				if _hill_edge[idxb] == HillEdge.CORE:
					_hill_edge[idxb] = HillEdge.BOTTOM
func _pass_collision(sx:int, sy:int):
	for y in range(sy - 1):
		var row = y * sx
		for x in range(sx):
			var idx = x + row
			if _base[idx] == BaseType.HILL:
				var below = idx + sx
				if below < _base.size() and _base[below] == BaseType.GRASS:
					_collision[below] = 1
func _commit_to_tilemaps(sx:int, sy:int):
	var half_x = sx/2
	var half_y = sy/2
	for y in range(sy):
		var row = y * sx
		for x in range(sx):
			var idx = x + row
			var local = Vector2i(x - half_x, y - half_y)
			if _base[idx] == BaseType.GRASS:
				var atlas: Vector2i
				match _grass_edge[idx]:
					GrassEdge.TOP: atlas = TILE_ATLAS["grass_Top"]
					GrassEdge.BOTTOM: atlas = TILE_ATLAS["grass_Bottom"]
					GrassEdge.LEFT: atlas = TILE_ATLAS["grass_Left"]
					GrassEdge.RIGHT: atlas = TILE_ATLAS["grass_Right"]
					GrassEdge.STRAIGHT_HOR: atlas = TILE_ATLAS["grass_Center_strait_sideward"]
					GrassEdge.STRAIGHT_VERT: atlas = TILE_ATLAS["grass_Center_strait_vertical"]
					GrassEdge.END_TOP: atlas = TILE_ATLAS["grass_Center_end_Top"]
					GrassEdge.END_BOTTOM: atlas = TILE_ATLAS["grass_Center_end_Bottom"]
					GrassEdge.END_LEFT: atlas = TILE_ATLAS["grass_Center_end_Left"]
					GrassEdge.END_RIGHT: atlas = TILE_ATLAS["grass_Center_end_Right"]
					GrassEdge.CORNER_TL: atlas = TILE_ATLAS["grass_corner_Top_left"]
					GrassEdge.CORNER_TR: atlas = TILE_ATLAS["grass_corner_Top_Right"]
					GrassEdge.CORNER_BL: atlas = TILE_ATLAS["grass_corner_Bottom_Left"]
					GrassEdge.CORNER_BR: atlas = TILE_ATLAS["grass_corner_Bottom_Right"]
					GrassEdge.SINGLE: atlas = TILE_ATLAS["grass_very_center"]
					_: atlas = TILE_ATLAS["grass"]
				if _collision[idx] == 1: atlas = TILE_ATLAS["grass_collision_all"]
				grass_layer.set_cell(local, 0, atlas)
			elif _base[idx] == BaseType.HILL:
				var hatlas: Vector2i
				match _hill_edge[idx]:
					HillEdge.TOP: hatlas = TILE_ATLAS["hill_Top"]
					HillEdge.BOTTOM: hatlas = TILE_ATLAS["hill_Bottom"]
					HillEdge.LEFT: hatlas = TILE_ATLAS["hill_Left"]
					HillEdge.RIGHT: hatlas = TILE_ATLAS["hill_Right"]
					HillEdge.TL: hatlas = TILE_ATLAS["hill_Top_left"]
					HillEdge.TR: hatlas = TILE_ATLAS["hill_Top_Right"]
					HillEdge.BL: hatlas = TILE_ATLAS["hill_Bottom_Left"]
					HillEdge.BR: hatlas = TILE_ATLAS["hill_Bottom_Right"]
					HillEdge.CORE: hatlas = TILE_ATLAS["hill"]
					HillEdge.PILLAR: hatlas = TILE_ATLAS["hill_pilar"]
					HillEdge.PILLAR_L: hatlas = TILE_ATLAS["hill_pilar_left"]
					HillEdge.PILLAR_R: hatlas = TILE_ATLAS["hill_pilar_right"]
					HillEdge.PILLAR_CENTER: hatlas = TILE_ATLAS["hill_pilar_Center"]
					_: hatlas = TILE_ATLAS["hill"]
				hill_layer.set_cell(local, 0, hatlas)
			if _underside[idx] != 0:
				var uatlas: Vector2i
				match _underside[idx]:
					1: uatlas = TILE_ATLAS["underside_Top_Middle"]
					2: uatlas = TILE_ATLAS["underside_Top_left"]
					3: uatlas = TILE_ATLAS["underside_Top_right"]
					4: uatlas = TILE_ATLAS["underside_Top_Center"]
					5: uatlas = TILE_ATLAS["underside_Center_Middle"]
					6: uatlas = TILE_ATLAS["underside_Center_left"]
					7: uatlas = TILE_ATLAS["underside_Center_right"]
					8: uatlas = TILE_ATLAS["underside_Center_Center"]
					9: uatlas = TILE_ATLAS["underside_Bottom_Middle"]
					10: uatlas = TILE_ATLAS["underside_Bottom_left"]
					11: uatlas = TILE_ATLAS["underside_Bottom_right"]
					12: uatlas = TILE_ATLAS["underside_Bottom_Center"]
					_: uatlas = TILE_ATLAS["underside_Center_Center"]
				underside_layer.set_cell(local, 0, uatlas)
			if _decoration[idx] != Deco.NONE:
				match _decoration[idx]:
					Deco.PACKED1: ground_decoration_layer.set_cell(local, 0, TILE_ATLAS["packedgrass1"])
					Deco.PACKED2: ground_decoration_layer.set_cell(local, 0, TILE_ATLAS["packedgrass2"])
					Deco.PACKED3: ground_decoration_layer.set_cell(local, 0, TILE_ATLAS["packedgrass3"])
					Deco.SHORT1: ground_decoration_layer.set_cell(local, 0, TILE_ATLAS["grass1"])
					Deco.SHORT2: ground_decoration_layer.set_cell(local, 0, TILE_ATLAS["grass2"])
					Deco.SHORT3: ground_decoration_layer.set_cell(local, 0, TILE_ATLAS["grass3"])
					Deco.STONE1: ground_decoration_layer.set_cell(local, 0, TILE_ATLAS["stone1"])
					Deco.STONE2: ground_decoration_layer.set_cell(local, 0, TILE_ATLAS["stone2"])
					Deco.SHROOM1: ground_decoration_layer.set_cell(local, 0, TILE_ATLAS["shroom1"])
					Deco.SHROOM2: ground_decoration_layer.set_cell(local, 0, TILE_ATLAS["shroom2"])
					Deco.STUMP_L: ground_decoration_layer.set_cell(local, 0, TILE_ATLAS["stumpl"])
					Deco.STUMP_R: ground_decoration_layer.set_cell(local, 0, TILE_ATLAS["stumpr"])
func _place_scenes_and_core(sx:int, sy:int):
	var half_x = sx/2
	var half_y = sy/2
	if core_tile_position == Vector2i.ZERO:
		core_tile_position = _select_core_hill_center(sx, sy)
	var local_core = Vector2i(core_tile_position.x - half_x, core_tile_position.y - half_y)
	bottom_items_layer.set_cell(local_core, 1, Vector2i.ZERO, scene_id_core)
	var placed_computer = false
	var attempts = 0
	while not placed_computer and attempts < 300:
		attempts += 1
		var x = randi() % sx
		var y = randi() % sy
		var local = Vector2i(x - half_x, y - half_y)
		if bottom_items_layer.get_cell_source_id(local) == -1 and grass_layer.get_cell_atlas_coords(local) != TILE_ATLAS["null"] and hill_layer.get_cell_atlas_coords(local) == TILE_ATLAS["null"]:
			bottom_items_layer.set_cell(local, 1, Vector2i.ZERO, scene_id_computer)
			placed_computer = true
	var bots = bots_count
	for i in range(bots): _place_scene(scene_id_bot)
	for i in range(bots): _place_scene(scene_id_seat)
	for i in range(bots): _place_scene(scene_id_charger)
func _select_core_hill_center(sx:int, sy:int) -> Vector2i:
	var hsx = hill_size.x
	var hsy = hill_size.y
	var centers: Array[Vector2i] = []
	for y in range(sy - hsy):
		for x in range(sx - hsx):
			var all_hill = true
			for yy in range(hsy):
				var r = (y + yy) * sx
				for xx in range(hsx):
					if _base[x + xx + r] != BaseType.HILL:
						all_hill = false; break
				if not all_hill: break
			if all_hill:
				centers.append(Vector2i(x + hsx/2, y + hsy/2))
	if centers.size() == 0:
		return Vector2i(sx/2, sy/2)
	return centers[randi() % centers.size()]
func _place_scene(scene_id:int):
	var sx = Global.islandSize.x
	var sy = Global.islandSize.y
	var half_x = sx/2
	var half_y = sy/2
	var attempts = 0
	while attempts < 300:
		attempts += 1
		var x = randi() % sx
		var y = randi() % sy
		var base_local = Vector2i(x - half_x, y - half_y)
		if not _is_valid_scene_anchor(base_local): continue
		bottom_items_layer.set_cell(base_local, 1, Vector2i.ZERO, scene_id)
		ground_decoration_layer.set_cell(base_local, 0, TILE_ATLAS["null"])
		return
func _is_valid_scene_anchor(base_local:Vector2i) -> bool:
	for dy in range(-1, 3):
		for dx in range(-1, 3):
			var p = base_local + Vector2i(dx, dy)
			if grass_layer.get_cell_atlas_coords(p) == TILE_ATLAS["null"]: return false
			if bottom_items_layer.get_cell_source_id(p) != -1: return false
			if ground_decoration_layer.get_cell_atlas_coords(p) != TILE_ATLAS["null"]: return false
			if hill_layer.get_cell_atlas_coords(p) != TILE_ATLAS["null"]: return false
	return true
func _resize_arrays(sx:int, sy:int):
	var total = sx * sy
	_base.resize(total)
	_grass_edge.resize(total)
	_hill_edge.resize(total)
	_decoration.resize(total)
	_underside.resize(total)
	_collision.resize(total)
	for i in range(total):
		_base[i] = 0; _grass_edge[i] = 0; _hill_edge[i] = 0; _decoration[i] = 0; _underside[i] = 0; _collision[i] = 0
func _make_noise(seed:int, freq:float) -> FastNoiseLite:
	var n = FastNoiseLite.new(); n.seed = seed; n.noise_type = FastNoiseLite.TYPE_SIMPLEX; n.frequency = freq; n.domain_warp_enabled = false; return n
func _precompute_distance_mask():
	var sx = Global.islandSize.x
	var sy = Global.islandSize.y
	_distance_mask = PackedFloat32Array(); _distance_mask.resize(sx * sy)
	var center = Vector2(sx * 0.5, sy * 0.5)
	var max_r = max(sx, sy) * 0.5
	for y in range(sy):
		var row = y * sx
		for x in range(sx):
			var d = Vector2(x, y).distance_to(center)
			_distance_mask[x + row] = 1.0 - clamp(d / max_r, 0.0, 1.0)
func _hash3(x:int, y:int, seed:int) -> int:
	var h = seed
	h = (h ^ (x * 374761393)) & 0xffffffff
	h = (h ^ (y * 668265263)) & 0xffffffff
	h = (h ^ (h >> 13)) * 1274126177 & 0xffffffff
	return int(h & 0x7fffffff)
func _clear_layers():
	bottom_items_layer.clear(); hill_layer.clear(); ground_decoration_layer.clear(); grass_layer.clear(); underside_layer.clear()
