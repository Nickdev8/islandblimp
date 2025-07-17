extends Node2D

# Tile Properties
@export var tile_size: Vector2 = Vector2(16, 16)     # Size of each tile in pixels
@export var terrain_threshold: float = 0.2          # Threshold for determining tile placement
@export var mountain_threshold: float = 0.8         # Threshold for mountain placement
@export var grass_threshold: float = 0.5            # Threshold for grass placement
@export var short_grass_threshold: float = 0.5      # Threshold for short grass
@export var rocks_threshold: float = 0.5            # Threshold for rocks
@export var hill_size: Vector2i = Vector2i(5, 5)    # Size of hills
@export var hill_count: int = 5                     # Number of hills to generate
@export var grass_spawn_chance: int = 10            # Chance for grass to spawn (1 in X)

# Layer References
@onready var bottom_items_layer: TileMapLayer = %BotItems
@onready var hill_layer: TileMapLayer = %hill
@onready var ground_decoration_layer: TileMapLayer = %stuffOnGround
@onready var grass_layer: TileMapLayer = $grass
@onready var underside_layer: TileMapLayer = %underside

# Generation State
var core_tile_position: Vector2i = Vector2i.ZERO
var positions_to_set: Array[Vector2i] = []
var positions_id: Array[int] = []
var positions_to_null: Array[Vector2i] = []

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
	
	"underside_Top_Middle" : Vector2i(18, 0),
	"underside_Top_Center" : Vector2i(19, 4),
	"underside_Top_left" : Vector2i(16, 0),
	"underside_Top_right" : Vector2i(19, 0),
	"underside_Bottom_Middle" : Vector2i(18, 1),
	"underside_Bottom_Center" : Vector2i(19, 5),
	"underside_Bottom_left" : Vector2i(16, 1),
	"underside_Bottom_right" : Vector2i(19, 1),
	
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
	"hill_pilar_Center" : Vector2i(6, 7),
}

const NOISE_PARAMETERS = {
	"noise_type": 0,
	"frequency": 0.008,
	"domain_warp_enabled": true,
	"domain_warp_amplitude": 15.01,
	"domain_warp_fractal_gain": 0.5,
	"domain_warp_fractal_type": 1,
	"domain_warp_frequency": 0.02,
	"domain_warp_fractal_octaves": 3.0,
	"domain_warp_type": 0,
	"fractal_type": 1,
	"fractal_gain": 0.5,
	"fractal_lacunarity": 2.12,
	"fractal_octaves": 3.0,
	"fractal_ping_pong_strength": 2.0,
	"fractal_weighted_strength": 0.5,
	"cellular_distance_function": 2,
	"cellular_jitter": 0.45,
	"cellular_return_type": 1,
}

func _ready():
	generate_map_with_timeout()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		generate_map_with_timeout()

func generate_map_with_timeout():
	var start_time = Time.get_ticks_msec()
	var success = false
	
	while not success:
		# Clear previous generation attempt
		bottom_items_layer.clear()
		hill_layer.clear()
		ground_decoration_layer.clear()
		grass_layer.clear()
		underside_layer.clear()
		
		core_tile_position = Vector2i.ZERO
		positions_to_set = []
		positions_id = []
		positions_to_null = []
		
		# Attempt generation
		generate_map()
		
		# Check if generation took too long
		if Time.get_ticks_msec() - start_time < 500:
			success = true
		else:
			print("Generation took too long, retrying...")

func generate_map():
	var noise = create_noise(randf_range(1, 10000000))
	var grass_noise = create_noise(randf_range(1, 10000000))
	
	var seed_value = randf_range(1, 10000000)
	noise.seed = seed_value
	grass_noise.seed = seed_value
	
	configure_noise(noise)
	configure_noise(grass_noise)
	
	var highest_point = find_highest_point(noise)
	var center_offset = Vector2i(Global.islandSize.x / 2, Global.islandSize.y / 2)
	var displacement = highest_point - center_offset
	
	# Generate base terrain
	for x in range(Global.islandSize.x):
		for y in range(Global.islandSize.y):
			var noise_value = noise.get_noise_2d(x + displacement.x, y + displacement.y)
			var distance = distance_between_points(Vector2i(x, y), center_offset)
			
			if noise_value * distance > terrain_threshold:
				grass_layer.set_cell(Vector2i(x - center_offset.x, y - center_offset.x), 0, TILE_ATLAS["grass"])
	
	apply_second_layer_filters()
	
	var random_core_num = randi_range(0, hill_count - 1)
	for hill_index in hill_count:
		var hill_placed = false
		while not hill_placed:
			hill_placed = generate_hill(hill_index, hill_count, random_core_num)
	
	apply_hill_filters()
	generate_grass_variations(grass_noise, center_offset)
	apply_collision_filters()
	
	# Generate scenes/objects
	generate_scene(1)  # Computer
	for i in 4: generate_scene(2)  # Seats
	for i in 5: generate_scene(4 + i)  # Chargers
	for i in 4: generate_scene(4)  # Companions
	
	# Place core
	bottom_items_layer.set_cell(core_tile_position, 1, Vector2i.ZERO, 3)
	
	# Place all other items
	for i in range(positions_to_set.size()):
		bottom_items_layer.set_cell(positions_to_set[i], 1, Vector2i.ZERO, positions_id[i])
		ground_decoration_layer.set_cell(positions_to_null[i], 0, TILE_ATLAS["null"])

func create_noise(seed_value: int) -> FastNoiseLite:
	var noise = FastNoiseLite.new()
	noise.seed = seed_value
	return noise

func configure_noise(noise: FastNoiseLite) -> void:
	noise.set_noise_type(NOISE_PARAMETERS["noise_type"])
	noise.set_frequency(NOISE_PARAMETERS["frequency"])
	noise.domain_warp_enabled = NOISE_PARAMETERS["domain_warp_enabled"]
	noise.domain_warp_amplitude = NOISE_PARAMETERS["domain_warp_amplitude"]
	noise.domain_warp_fractal_gain = NOISE_PARAMETERS["domain_warp_fractal_gain"]
	noise.domain_warp_fractal_type = NOISE_PARAMETERS["domain_warp_fractal_type"]
	noise.domain_warp_frequency = NOISE_PARAMETERS["domain_warp_frequency"]
	noise.domain_warp_fractal_octaves = NOISE_PARAMETERS["domain_warp_fractal_octaves"]
	noise.domain_warp_type = NOISE_PARAMETERS["domain_warp_type"]
	noise.fractal_type = NOISE_PARAMETERS["fractal_type"]
	noise.fractal_gain = NOISE_PARAMETERS["fractal_gain"]
	noise.fractal_lacunarity = NOISE_PARAMETERS["fractal_lacunarity"]
	noise.fractal_octaves = NOISE_PARAMETERS["fractal_octaves"]
	noise.fractal_ping_pong_strength = NOISE_PARAMETERS["fractal_ping_pong_strength"]
	noise.fractal_weighted_strength = NOISE_PARAMETERS["fractal_weighted_strength"]
	noise.cellular_distance_function = NOISE_PARAMETERS["cellular_distance_function"]
	noise.cellular_jitter = NOISE_PARAMETERS["cellular_jitter"]
	noise.cellular_return_type = NOISE_PARAMETERS["cellular_return_type"]

func generate_grass_variations(grass_noise: FastNoiseLite, center_offset: Vector2i):
	for x in range(Global.islandSize.x):
		for y in range(Global.islandSize.y):
			grass_noise.set_frequency(0.06)
			var noise_value = grass_noise.get_noise_2d(x + 1000, y)
			grass_noise.set_frequency(0.08)
			var short_grass_noise_value = grass_noise.get_noise_2d(x + 2000, y)
			
			var set_cell = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2)
			var set_cell_left = Vector2i(x - Global.islandSize.x/2 - 1, y - Global.islandSize.y/2)
			
			var me = grass_layer.get_cell_atlas_coords(set_cell)
			var left = grass_layer.get_cell_atlas_coords(set_cell_left)
			var me_stuff = ground_decoration_layer.get_cell_atlas_coords(set_cell)
			var left_stuff = ground_decoration_layer.get_cell_atlas_coords(set_cell_left)
			
			if me == TILE_ATLAS["grass"]:
				if noise_value > grass_threshold:
					var random_grass = randi_range(1, 3)
					ground_decoration_layer.set_cell(set_cell, 0, TILE_ATLAS["packedgrass" + str(random_grass)])
				elif short_grass_noise_value > short_grass_threshold and short_grass_noise_value < rocks_threshold:
					var random_grass = randi_range(1, 3)
					ground_decoration_layer.set_cell(set_cell, 0, TILE_ATLAS["grass" + str(random_grass)])
				elif short_grass_noise_value > rocks_threshold:
					var random_item = randi_range(1, 5)
					match random_item:
						1: ground_decoration_layer.set_cell(set_cell, 0, TILE_ATLAS["stone1"])
						2: ground_decoration_layer.set_cell(set_cell, 0, TILE_ATLAS["stone2"])
						3: ground_decoration_layer.set_cell(set_cell, 0, TILE_ATLAS["shroom1"])
						4: ground_decoration_layer.set_cell(set_cell, 0, TILE_ATLAS["shroom2"])
						5:
							if left == TILE_ATLAS["grass"] and me_stuff != TILE_ATLAS["stumpl"] and me_stuff != TILE_ATLAS["stumpr"] and left_stuff != TILE_ATLAS["stumpl"] and left_stuff != TILE_ATLAS["stumpr"]:
								ground_decoration_layer.set_cell(set_cell_left, 0, TILE_ATLAS["stumpl"])
								ground_decoration_layer.set_cell(set_cell, 0, TILE_ATLAS["stumpr"])
							else:
								ground_decoration_layer.set_cell(set_cell, 0, TILE_ATLAS["stone2"])

func generate_scene(scene_id: int):
	var placed = false
	while not placed:
		var x = randi_range(0, Global.islandSize.x)
		var y = randi_range(0, Global.islandSize.y)
		var base_pos = Vector2i(x - Global.islandSize.x / 2, y - Global.islandSize.y / 2)
		
		var positions = []
		for dy in range(-1, 3):
			for dx in range(-1, 3):
				positions.append(base_pos + Vector2i(dx, dy))
		
		var valid_position = true
		
		# Check all positions are valid
		for pos in positions:
			if (grass_layer.get_cell_atlas_coords(pos) != TILE_ATLAS["grass"] or
				bottom_items_layer.get_cell_atlas_coords(pos) != TILE_ATLAS["null"] or
				ground_decoration_layer.get_cell_atlas_coords(pos) != TILE_ATLAS["null"] or
				hill_layer.get_cell_atlas_coords(pos) != TILE_ATLAS["null"]):
				valid_position = false
				break
		
		if valid_position:
			bottom_items_layer.set_cell(base_pos, 1, Vector2i.ZERO, scene_id)
			ground_decoration_layer.set_cell(base_pos, 0, TILE_ATLAS["null"])
			positions_to_set.append(base_pos)
			positions_id.append(scene_id)
			positions_to_null.append(base_pos)
			
			# Add surrounding positions to null list
			for dy in range(0, 2):
				for dx in range(0, 2):
					positions_to_null.append(base_pos + Vector2i(dx, dy))
			
			placed = true

func generate_hill(hill_index: int, total_hills: int, random_core_num: int) -> bool:
	var x_pos = randi_range(0, Global.islandSize.x)
	var y_pos = randi_range(0, Global.islandSize.y)
	var all_on_grass = true
	var hill_positions: Array[Vector2i] = []
	var temp_core_pos: Vector2i = Vector2i.ZERO
	
	for x in hill_size.x:
		for y in hill_size.y:
			var set_cell = Vector2i(x_pos + x - Global.islandSize.x/2, y_pos + y - Global.islandSize.y/2)
			var set_cell_up = Vector2i(x_pos + x - Global.islandSize.x/2, y_pos + y - Global.islandSize.y/2 - 1)
			var set_cell_down = Vector2i(x_pos + x - Global.islandSize.x/2, y_pos + y - Global.islandSize.y/2 + 1)
			var set_cell_left = Vector2i(x_pos + x - Global.islandSize.x/2 - 1, y_pos + y - Global.islandSize.y/2)
			var set_cell_right = Vector2i(x_pos + x - Global.islandSize.x/2 + 1, y_pos + y - Global.islandSize.y/2)
			
			var me = grass_layer.get_cell_atlas_coords(set_cell)
			var up = grass_layer.get_cell_atlas_coords(set_cell_up)
			var down = grass_layer.get_cell_atlas_coords(set_cell_down)
			var left = grass_layer.get_cell_atlas_coords(set_cell_left)
			var right = grass_layer.get_cell_atlas_coords(set_cell_right)
			
			# Skip if position is invalid
			if set_cell in [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(0,1), Vector2i(-1,-1), Vector2i(-1,0), Vector2i(0,-1), Vector2i(1,-1), Vector2i(-1,1)]:
				all_on_grass = false
				continue
			
			if is_grass(me) and is_grass(up) and is_grass(down) and is_grass(left) and is_grass(right):
				hill_positions.append(set_cell)
				if hill_index == random_core_num and x == 2 and y == 2:
					temp_core_pos = set_cell
			else:
				all_on_grass = false
	
	if all_on_grass:
		if temp_core_pos != Vector2i.ZERO:
			core_tile_position = temp_core_pos
		for pos in hill_positions:
			hill_layer.set_cell(pos, 0, TILE_ATLAS["hill"])
	
	return all_on_grass

func find_highest_point(noise: FastNoiseLite) -> Vector2i:
	var highest_noise = -INF
	var highest_point: Vector2i
	
	for x in range(Global.islandSize.x):
		for y in range(Global.islandSize.y):
			var noise_value = noise.get_noise_2d(x, y)
			if noise_value > highest_noise:
				highest_noise = noise_value
				highest_point = Vector2i(x, y)
	
	return highest_point

func distance_between_points(point: Vector2, center: Vector2) -> float:
	var max_distance = 40.0
	var distance = point.distance_to(center)
	return 1.0 - clamp(distance / max_distance, 0.0, 1.0)

func apply_second_layer_filters():
	for x in range(Global.islandSize.x):
		for y in range(Global.islandSize.y):
			var set_cell = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2)
			var set_cell_up = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2 - 1)
			var set_cell_up_left = Vector2i(x - Global.islandSize.x/2 - 1, y - Global.islandSize.y/2 - 1)
			var set_cell_up_right = Vector2i(x - Global.islandSize.x/2 + 1, y - Global.islandSize.y/2 - 1)
			var set_cell_down = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2 + 1)
			var set_cell_down_left = Vector2i(x - Global.islandSize.x/2 - 1, y - Global.islandSize.y/2 + 1)
			var set_cell_down_right = Vector2i(x - Global.islandSize.x/2 + 1, y - Global.islandSize.y/2 + 1)
			var set_cell_left = Vector2i(x - Global.islandSize.x/2 - 1, y - Global.islandSize.y/2)
			var set_cell_right = Vector2i(x - Global.islandSize.x/2 + 1, y - Global.islandSize.y/2)
			
			var me = grass_layer.get_cell_atlas_coords(set_cell)
			var up = grass_layer.get_cell_atlas_coords(set_cell_up)
			var up_left = grass_layer.get_cell_atlas_coords(set_cell_up_left)
			var up_right = grass_layer.get_cell_atlas_coords(set_cell_up_right)
			var down = grass_layer.get_cell_atlas_coords(set_cell_down)
			var down_left = grass_layer.get_cell_atlas_coords(set_cell_down_left)
			var down_right = grass_layer.get_cell_atlas_coords(set_cell_down_right)
			var left = grass_layer.get_cell_atlas_coords(set_cell_left)
			var right = grass_layer.get_cell_atlas_coords(set_cell_right)
			
			var underside_up = underside_layer.get_cell_atlas_coords(set_cell_up)
			
			if is_grass(me):
				if is_null(left) or is_null(right) or is_null(up) or is_null(down):
					if not is_null(left) and not is_null(right) and is_null(up) and not is_null(down):
						grass_layer.set_cell(set_cell, 0, TILE_ATLAS["grass_Top"])
					elif not is_null(left) and not is_null(right) and not is_null(up) and is_null(down):
						grass_layer.set_cell(set_cell, 0, TILE_ATLAS["grass_Bottom"])
					elif is_null(left) and not is_null(right) and not is_null(up) and not is_null(down):
						grass_layer.set_cell(set_cell, 0, TILE_ATLAS["grass_Left"])
					elif not is_null(left) and is_null(right) and not is_null(up) and not is_null(down):
						grass_layer.set_cell(set_cell, 0, TILE_ATLAS["grass_Right"])
					elif is_null(left) and is_null(right) and not is_null(up) and not is_null(down):
						grass_layer.set_cell(set_cell, 0, TILE_ATLAS["grass_Center_strait_vertical"])
					elif not is_null(left) and not is_null(right) and is_null(up) and is_null(down):
						grass_layer.set_cell(set_cell, 0, TILE_ATLAS["grass_Center_strait_sideward"])
					elif is_null(left) and is_null(right) and not is_null(up) and is_null(down):
						grass_layer.set_cell(set_cell, 0, TILE_ATLAS["grass_Center_end_Bottom"])
					elif is_null(left) and is_null(right) and is_null(up) and not is_null(down):
						grass_layer.set_cell(set_cell, 0, TILE_ATLAS["grass_Center_end_Top"])
					elif not is_null(left) and is_null(right) and is_null(up) and is_null(down):
						grass_layer.set_cell(set_cell, 0, TILE_ATLAS["grass_Center_end_Right"])
					elif is_null(left) and not is_null(right) and is_null(up) and is_null(down):
						grass_layer.set_cell(set_cell, 0, TILE_ATLAS["grass_Center_end_Left"])
					elif is_null(left) and not is_null(right) and is_null(up) and not is_null(down):
						grass_layer.set_cell(set_cell, 0, TILE_ATLAS["grass_corner_Top_left"])
					elif not is_null(left) and is_null(right) and is_null(up) and not is_null(down):
						grass_layer.set_cell(set_cell, 0, TILE_ATLAS["grass_corner_Top_Right"])
					elif is_null(left) and not is_null(right) and not is_null(up) and is_null(down):
						grass_layer.set_cell(set_cell, 0, TILE_ATLAS["grass_corner_Bottom_Left"])
					elif not is_null(left) and is_null(right) and not is_null(up) and is_null(down):
						grass_layer.set_cell(set_cell, 0, TILE_ATLAS["grass_corner_Bottom_Right"])
					elif is_null(left) and is_null(right) and is_null(up) and is_null(down):
						grass_layer.set_cell(set_cell, 0, TILE_ATLAS["grass_very_center"])
			elif is_null(me):
				if is_grass(up):
					if is_grass(up_left) and is_grass(up_right):
						underside_layer.set_cell(set_cell, 0, TILE_ATLAS["underside_Top_Middle"])
					elif not is_grass(up_left) and is_grass(up_right):
						underside_layer.set_cell(set_cell, 0, TILE_ATLAS["underside_Top_left"])
					elif is_grass(up_left) and not is_grass(up_right):
						underside_layer.set_cell(set_cell, 0, TILE_ATLAS["underside_Top_right"])
					elif not is_grass(up_left) and not is_grass(up_right):
						underside_layer.set_cell(set_cell, 0, TILE_ATLAS["underside_Top_Center"])
				elif underside_up == TILE_ATLAS["underside_Top_Center"]:
					underside_layer.set_cell(set_cell, 0, TILE_ATLAS["underside_Bottom_Center"])
				elif underside_up == TILE_ATLAS["underside_Top_left"]:
					underside_layer.set_cell(set_cell, 0, TILE_ATLAS["underside_Bottom_left"])
				elif underside_up == TILE_ATLAS["underside_Top_Middle"]:
					underside_layer.set_cell(set_cell, 0, TILE_ATLAS["underside_Bottom_Middle"])
				elif underside_up == TILE_ATLAS["underside_Top_right"]:
					underside_layer.set_cell(set_cell, 0, TILE_ATLAS["underside_Bottom_right"])

func apply_hill_filters():
	for x in range(Global.islandSize.x):
		for y in range(Global.islandSize.y):
			var set_cell = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2)
			var set_cell_up = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2 - 1)
			var set_cell_up_left = Vector2i(x - Global.islandSize.x/2 - 1, y - Global.islandSize.y/2 - 1)
			var set_cell_up_right = Vector2i(x - Global.islandSize.x/2 + 1, y - Global.islandSize.y/2 - 1)
			var set_cell_down = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2 + 1)
			var set_cell_down_left = Vector2i(x - Global.islandSize.x/2 - 1, y - Global.islandSize.y/2 + 1)
			var set_cell_down_right = Vector2i(x - Global.islandSize.x/2 + 1, y - Global.islandSize.y/2 + 1)
			var set_cell_left = Vector2i(x - Global.islandSize.x/2 - 1, y - Global.islandSize.y/2)
			var set_cell_right = Vector2i(x - Global.islandSize.x/2 + 1, y - Global.islandSize.y/2)
			
			var hill_me = hill_layer.get_cell_atlas_coords(set_cell)
			var hill_up_left = hill_layer.get_cell_atlas_coords(set_cell_up_left)
			var hill_up_right = hill_layer.get_cell_atlas_coords(set_cell_up_right)
			var hill_up = hill_layer.get_cell_atlas_coords(set_cell_up)
			var hill_down = hill_layer.get_cell_atlas_coords(set_cell_down)
			var hill_left = hill_layer.get_cell_atlas_coords(set_cell_left)
			var hill_right = hill_layer.get_cell_atlas_coords(set_cell_right)
			
			if is_hill(hill_me):				
				if not is_hill(hill_left):
					if not is_hill(hill_up) and is_null(hill_down):
						hill_layer.set_cell(set_cell, 0, TILE_ATLAS["hill_Left"])
					elif not is_hill(hill_up):
						hill_layer.set_cell(set_cell, 0, TILE_ATLAS["hill_Top_left"])
					elif is_null(hill_down):
						hill_layer.set_cell(set_cell, 0, TILE_ATLAS["hill_Bottom_Left"])
					else:
						hill_layer.set_cell(set_cell, 0, TILE_ATLAS["hill_Left"])
				elif is_null(hill_right):
					if not is_hill(hill_up) and is_null(hill_down):
						hill_layer.set_cell(set_cell, 0, TILE_ATLAS["hill_Right"])
					elif not is_hill(hill_up):
						hill_layer.set_cell(set_cell, 0, TILE_ATLAS["hill_Top_Right"])
					elif is_null(hill_down):
						hill_layer.set_cell(set_cell, 0, TILE_ATLAS["hill_Bottom_Right"])
					else:
						hill_layer.set_cell(set_cell, 0, TILE_ATLAS["hill_Right"])
				elif not is_hill(hill_up):
					hill_layer.set_cell(set_cell, 0, TILE_ATLAS["hill_Top"])
				elif is_null(hill_down):
					hill_layer.set_cell(set_cell, 0, TILE_ATLAS["hill_Bottom"])
			
			if is_null(hill_me):
				if is_hill(hill_up):
					if is_hill(hill_up_right) and is_hill(hill_up_left):
						hill_layer.set_cell(set_cell, 0, TILE_ATLAS["hill_pilar"])
					elif is_hill(hill_up_right) and not is_hill(hill_up_left):
						hill_layer.set_cell(set_cell, 0, TILE_ATLAS["hill_pilar_left"])
					elif not is_hill(hill_up_right) and is_hill(hill_up_left):
						hill_layer.set_cell(set_cell, 0, TILE_ATLAS["hill_pilar_right"])
					elif not is_hill(hill_up_right) and not is_hill(hill_up_left):
						hill_layer.set_cell(set_cell, 0, TILE_ATLAS["hill_pilar_Center"])

func apply_collision_filters():
	for x in range(Global.islandSize.x):
		for y in range(Global.islandSize.y):
			var set_cell = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2)
			var set_cell_down = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2 + 1)
			var hill_me = hill_layer.get_cell_atlas_coords(set_cell)
			
			if is_hill(hill_me):
				grass_layer.set_cell(set_cell_down, 0, TILE_ATLAS["grass_collision_all"])

func is_grass(tile: Vector2i) -> bool:
	return tile in [
		TILE_ATLAS["grass"], TILE_ATLAS["grass_Bottom"], TILE_ATLAS["grass_Left"], 
		TILE_ATLAS["grass_Right"], TILE_ATLAS["grass_Top"], TILE_ATLAS["grass_Center_end_Bottom"],
		TILE_ATLAS["grass_Center_end_Left"], TILE_ATLAS["grass_Center_end_Right"], 
		TILE_ATLAS["grass_Center_end_Top"], TILE_ATLAS["grass_Center_strait_sideward"],
		TILE_ATLAS["grass_Center_strait_vertical"], TILE_ATLAS["grass_corner_Bottom_Left"],
		TILE_ATLAS["grass_corner_Bottom_Right"], TILE_ATLAS["grass_corner_Top_left"],
		TILE_ATLAS["grass_corner_Top_Right"]
	]

func is_hill(tile: Vector2i) -> bool:
	return tile in [
		TILE_ATLAS["hill"], TILE_ATLAS["hill_Center"], TILE_ATLAS["hill_Left"],
		TILE_ATLAS["hill_Right"], TILE_ATLAS["hill_Top"], TILE_ATLAS["hill_Bottom"],
		TILE_ATLAS["hill_Bottom_Left"], TILE_ATLAS["hill_Bottom_Right"],
		TILE_ATLAS["hill_Top_left"], TILE_ATLAS["hill_Top_Right"]
	]

func is_null(tile: Vector2i) -> bool:
	return tile == TILE_ATLAS["null"]
