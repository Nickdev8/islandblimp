extends Node2D

# Properties
@export var tileSize = Vector2(16, 16)     # Size of each tile in pixels
@export var threshold = 0.2                # Threshold for determining tile placement
@export var mounten_threshold = 0.8                # Threshold for determining tile placement
@export var grass_threshold = 0.5
@export var shortgrass_threshold = 0.5
@export var rocks_threshold = 0.5
@export var hillsize: Vector2i = Vector2i(5, 5)
@export var hillamount: int
@export var grasschance: int

@onready var bot_items: TileMapLayer = %BotItems
@onready var hill: TileMapLayer = %hill
@onready var stuff_on_ground: TileMapLayer = %stuffOnGround
@onready var grassLayer: TileMapLayer = $grass
@onready var underside: TileMapLayer = %underside

var coretilemapposision: Vector2i = Vector2i.ZERO
var postoset: Array[Vector2i] = []
var postoid: Array[int] = []
var postonull: Array[Vector2i] = []

const Dic: Dictionary = {
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

const noiseParameters = {
	"noise_type": 0,
	"frequency": 0.008000,
	"domain_warp_enabled": true,
	"domain_warp_amplitude": 15.010000,
	"domain_warp_fractal_gain": 0.500000,
	"domain_warp_fractal_type": 1,
	"domain_warp_frequency": 0.020000,
	"domain_warp_fractal_octaves": 3.000000,
	"domain_warp_type": 0,
	"fractal_type": 1,
	"fractal_gain": 0.500000,
	"fractal_lacunarity": 2.120000,
	"fractal_octaves": 3.000000,
	"fractal_ping_pong_strength": 2.000000,
	"fractal_weighted_strength": 0.500000,
	"cellular_distance_function": 2,
	"cellular_jitter": 0.450000,
	"cellular_return_type": 1,
}

func _ready():
	generate_map()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		generate_map()

func generate_map():
	if grassLayer == null:
		printerr("TileMap node reference is not set!")
		return
	
	bot_items.clear()
	hill.clear()
	stuff_on_ground.clear()
	grassLayer.clear()
	underside.clear()
	
	coretilemapposision = Vector2i.ZERO
	postoset = []
	postoid = []
	postonull = []
	
	var noise = create_noise(randf_range(1, 10000000))
	var grass_noise = create_noise(randf_range(1, 10000000))
	
	var seed = randf_range(1, 10000000)
	noise.seed = seed
	grass_noise.seed = seed
	noise.set_noise_type(noiseParameters["noise_type"])
	grass_noise.set_noise_type(noiseParameters["noise_type"])
	noise.set_frequency(noiseParameters["frequency"])
	noise.domain_warp_enabled = noiseParameters["domain_warp_enabled"]
	grass_noise.domain_warp_enabled = noiseParameters["domain_warp_enabled"]
	noise.domain_warp_amplitude = noiseParameters["domain_warp_amplitude"]
	grass_noise.domain_warp_amplitude = noiseParameters["domain_warp_amplitude"]
	noise.domain_warp_fractal_gain = noiseParameters["domain_warp_fractal_gain"]
	grass_noise.domain_warp_fractal_gain = noiseParameters["domain_warp_fractal_gain"]
	noise.domain_warp_fractal_type = noiseParameters["domain_warp_fractal_type"]
	grass_noise.domain_warp_fractal_type = noiseParameters["domain_warp_fractal_type"]
	noise.domain_warp_frequency = noiseParameters["domain_warp_frequency"]
	grass_noise.domain_warp_frequency = noiseParameters["domain_warp_frequency"]
	noise.domain_warp_fractal_octaves = noiseParameters["domain_warp_fractal_octaves"]
	grass_noise.domain_warp_fractal_octaves = noiseParameters["domain_warp_fractal_octaves"]
	noise.domain_warp_type = noiseParameters["domain_warp_type"]
	grass_noise.domain_warp_type = noiseParameters["domain_warp_type"]
	noise.fractal_type = noiseParameters["fractal_type"]
	grass_noise.fractal_type = noiseParameters["fractal_type"]
	noise.fractal_gain = noiseParameters["fractal_gain"]
	grass_noise.fractal_gain = noiseParameters["fractal_gain"]
	noise.fractal_lacunarity = noiseParameters["fractal_lacunarity"]
	grass_noise.fractal_lacunarity = noiseParameters["fractal_lacunarity"]
	noise.fractal_octaves = noiseParameters["fractal_octaves"]
	grass_noise.fractal_octaves = noiseParameters["fractal_octaves"]
	noise.fractal_ping_pong_strength = noiseParameters["fractal_ping_pong_strength"]
	grass_noise.fractal_ping_pong_strength = noiseParameters["fractal_ping_pong_strength"]
	noise.fractal_weighted_strength = noiseParameters["fractal_weighted_strength"]
	grass_noise.fractal_weighted_strength = noiseParameters["fractal_weighted_strength"]
	noise.cellular_distance_function = noiseParameters["cellular_distance_function"]
	grass_noise.cellular_distance_function = noiseParameters["cellular_distance_function"]
	noise.cellular_jitter = noiseParameters["cellular_jitter"]
	grass_noise.cellular_jitter = noiseParameters["cellular_jitter"]
	noise.cellular_return_type = noiseParameters["cellular_return_type"]
	grass_noise.cellular_return_type = noiseParameters["cellular_return_type"]
	
	var highest_point = find_highest_point(noise)
	var center_offset = Vector2i(Global.islandSize.x / 2, Global.islandSize.y / 2)
	var displacement = highest_point - center_offset
	
	for x in range(Global.islandSize.x):
		for y in range(Global.islandSize.y):
			var noise_value = noise.get_noise_2d(x + displacement.x, y + displacement.y)
			var distance = distance_between_points(Vector2i(x,y), center_offset)
			
			if noise_value * distance > threshold:
				grassLayer.set_cell(Vector2i(x - center_offset.x, y - center_offset.x), 0, Dic["grass"])
	
	secondlayerfilter()
	
	var randomcorenum = randi_range(0, hillamount -1)
	for t in hillamount:
		var istherehill = false
		while istherehill == false:
			istherehill = genaratehill(t, hillamount, randomcorenum)
	
	hillsecondlayerfilter()
	
	makegrassrandom(grass_noise, center_offset)
	collsionlayerfilter()
	
	#computer
	generate_scene(1)
	#seat
	generate_scene(2)
	generate_scene(2)
	generate_scene(2)
	generate_scene(2)
	#charger
	generate_scene(5)
	generate_scene(6)
	generate_scene(7)
	generate_scene(8)
	generate_scene(9)
	
	#companion
	generate_scene(4)
	generate_scene(4)
	generate_scene(4)
	generate_scene(4)
	
	#core
	bot_items.set_cell(coretilemapposision, 1, Vector2i.ZERO, 3)
	
	for i in range(postoset.size()):
		bot_items.set_cell(postoset[i], 1, Vector2i.ZERO, postoid[i])
		stuff_on_ground.set_cell(postonull[i], 0, Dic["null"])
	
func create_noise(seed: int) -> FastNoiseLite:
	var noise = FastNoiseLite.new()
	noise.seed = seed
	noise.set_noise_type(noiseParameters["noise_type"])
	noise.set_frequency(noiseParameters["frequency"])
	noise.domain_warp_enabled = noiseParameters["domain_warp_enabled"]
	noise.domain_warp_amplitude = noiseParameters["domain_warp_amplitude"]
	noise.domain_warp_fractal_gain = noiseParameters["domain_warp_fractal_gain"]
	noise.domain_warp_fractal_type = noiseParameters["domain_warp_fractal_type"]
	noise.domain_warp_frequency = noiseParameters["domain_warp_frequency"]
	noise.domain_warp_fractal_octaves = noiseParameters["domain_warp_fractal_octaves"]
	noise.domain_warp_type = noiseParameters["domain_warp_type"]
	noise.fractal_type = noiseParameters["fractal_type"]
	noise.fractal_gain = noiseParameters["fractal_gain"]
	noise.fractal_lacunarity = noiseParameters["fractal_lacunarity"]
	noise.fractal_octaves = noiseParameters["fractal_octaves"]
	noise.fractal_ping_pong_strength = noiseParameters["fractal_ping_pong_strength"]
	noise.fractal_weighted_strength = noiseParameters["fractal_weighted_strength"]
	noise.cellular_distance_function = noiseParameters["cellular_distance_function"]
	noise.cellular_jitter = noiseParameters["cellular_jitter"]
	noise.cellular_return_type = noiseParameters["cellular_return_type"]
	return noise
	
func makegrassrandom(grass_noise, center_offset):
	for x in range(Global.islandSize.x):
		for y in range(Global.islandSize.y):
			grass_noise.set_frequency(0.06)
			var noise_value = grass_noise.get_noise_2d(x + 1000, y)
			grass_noise.set_frequency(0.08)
			var noise_value_shortgrass = grass_noise.get_noise_2d(x + 2000, y)
			var setcell = Vector2i(x - Global.islandSize.x/2,y - Global.islandSize.y/2)
			var setcell_left = Vector2i(x - Global.islandSize.x/2 - 1,y - Global.islandSize.y/2)
			var me = grassLayer.get_cell_atlas_coords(setcell)
			var left = grassLayer.get_cell_atlas_coords(setcell_left)
			var me_stuff = stuff_on_ground.get_cell_atlas_coords(setcell)
			var left_stuff = stuff_on_ground.get_cell_atlas_coords(setcell_left)
			#var randomnormalgrasschange: int = randi_range(1,grasschance)
			
			if me == Dic["grass"]:
					if noise_value > grass_threshold:
						var randomgrass: int = randi_range(1,3)
						if randomgrass == 1: stuff_on_ground.set_cell(Vector2i(x - center_offset.x, y - center_offset.x), 0, Dic["packedgrass1"])
						elif randomgrass == 2: stuff_on_ground.set_cell(Vector2i(x - center_offset.x, y - center_offset.x), 0, Dic["packedgrass2"])
						elif randomgrass == 3: stuff_on_ground.set_cell(Vector2i(x - center_offset.x, y - center_offset.x), 0, Dic["packedgrass3"])
					elif noise_value_shortgrass > shortgrass_threshold and noise_value_shortgrass < rocks_threshold:
						var randomgrass: int = randi_range(1,3)
						if randomgrass == 1: stuff_on_ground.set_cell(Vector2i(x - center_offset.x, y - center_offset.x), 0, Dic["grass1"])
						elif randomgrass == 2: stuff_on_ground.set_cell(Vector2i(x - center_offset.x, y - center_offset.x), 0, Dic["grass2"])
						elif randomgrass == 3: stuff_on_ground.set_cell(Vector2i(x - center_offset.x, y - center_offset.x), 0, Dic["grass3"])
					elif noise_value_shortgrass > rocks_threshold:
						var randomgrass: int = randi_range(1,5)
						if randomgrass == 1: stuff_on_ground.set_cell(Vector2i(x - center_offset.x, y - center_offset.x), 0, Dic["stone1"])
						elif randomgrass == 2: stuff_on_ground.set_cell(Vector2i(x - center_offset.x, y - center_offset.x), 0, Dic["stone2"])
						elif randomgrass == 3: stuff_on_ground.set_cell(Vector2i(x - center_offset.x, y - center_offset.x), 0, Dic["shroom1"])
						elif randomgrass == 4: stuff_on_ground.set_cell(Vector2i(x - center_offset.x, y - center_offset.x), 0, Dic["shroom2"])
						elif randomgrass == 5:
							if left == Dic["grass"] and me_stuff != Dic["stumpl"] and me_stuff != Dic["stumpr"] and left_stuff != Dic["stumpl"] and left_stuff != Dic["stumpr"]:
								stuff_on_ground.set_cell(Vector2i(x - center_offset.x - 1, y - center_offset.x), 0, Dic["stumpl"])
								stuff_on_ground.set_cell(Vector2i(x - center_offset.x, y - center_offset.x), 0, Dic["stumpr"])
							else: stuff_on_ground.set_cell(Vector2i(x - center_offset.x, y - center_offset.x), 0, Dic["stone2"])

func generate_scene(sceneid: int):
	var istherea = false
	while istherea == false:
		var x = randi_range(0, Global.islandSize.x)
		var y = randi_range(0, Global.islandSize.y)
		var all_is_on_grass: bool = false

		var base_pos = Vector2i(x - Global.islandSize.x / 2, y - Global.islandSize.y / 2)
		var positions = [
			base_pos + Vector2i(-1, -1), base_pos + Vector2i(0, -1), base_pos + Vector2i(1, -1), base_pos + Vector2i(2, -1),
			base_pos + Vector2i(-1, 0),  base_pos + Vector2i(0, 0),  base_pos + Vector2i(1, 0),  base_pos + Vector2i(2, 0),
			base_pos + Vector2i(-1, 1),  base_pos + Vector2i(0, 1),  base_pos + Vector2i(1, 1),  base_pos + Vector2i(2, 1),
			base_pos + Vector2i(-1, 2),  base_pos + Vector2i(0, 2),  base_pos + Vector2i(1, 2),  base_pos + Vector2i(2, 2)
		]

		var grass_cell_data = []
		var botitems_cell_data = []
		var stuffonground_cell_data = []
		var hill_cell_data = []
		for pos in positions:
			grass_cell_data.append(grassLayer.get_cell_atlas_coords(pos))
			botitems_cell_data.append(bot_items.get_cell_atlas_coords(pos))
			stuffonground_cell_data.append(stuff_on_ground.get_cell_atlas_coords(pos))
			hill_cell_data.append(hill.get_cell_atlas_coords(pos))
		
		var collision_indices = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
		var navigation_indices = collision_indices

		if grass_cell_data[5] == Dic["grass"]:
			var is_valid = true
			for idx in collision_indices:
				if grass_cell_data[idx] == Dic["grass_collision_all"]:
					is_valid = false
					break

			if is_valid:
				for idx in navigation_indices:
					if grass_cell_data[idx] == Dic["grass_collision_navigation"]:
						is_valid = false
						break

			if is_valid:
				for idx in navigation_indices:
					if botitems_cell_data[idx] != Dic["null"]:
						is_valid = false
						break

			if is_valid:
				for idx in navigation_indices:
					if stuffonground_cell_data[idx] != Dic["null"]:
						is_valid = false
						break

			if is_valid:
				for idx in navigation_indices:
					if hill_cell_data[idx] != Dic["null"]:
						is_valid = false
						break

			if is_valid:
				for idx in navigation_indices:
					if grass_cell_data[idx] != Dic["grass"]:
						is_valid = false
						break

			if is_valid:
				bot_items.set_cell(base_pos, 1, Vector2i.ZERO, sceneid)
				stuff_on_ground.set_cell(base_pos, 0, Dic["null"])
				postoset.append(base_pos)
				postoid.append(sceneid)
				postonull.append(base_pos)
				postonull.append(base_pos + Vector2i(0, 1))
				postonull.append(base_pos + Vector2i(1, 0))
				postonull.append(base_pos + Vector2i(1, 1))
				bot_items.set_cell(base_pos, 1, Vector2i.ZERO, sceneid)
				stuff_on_ground.set_cell(base_pos, 0, Dic["null"])
				istherea = true

func genaratehill(i, i_tot, i_random) -> bool:
	var x_pos = randi_range(0, Global.islandSize.x)
	var y_pos = randi_range(0, Global.islandSize.y)
	var allisongrass: bool = true
	var hillposisions: Array[Vector2i]
	var temp_corepos: Vector2i = Vector2i.ZERO
	
	hillposisions.clear()
	
	if true:
		for x in hillsize.x:
			for y in hillsize.y:
				var setcell = Vector2i(x_pos + x - Global.islandSize.x/2, y_pos + y - Global.islandSize.y/2)
				var setcell_up = Vector2i(x_pos + x - Global.islandSize.x/2, y_pos + y - Global.islandSize.y/2 - 1)
				var setcell_down = Vector2i(x_pos + x - Global.islandSize.x/2, y_pos + y - Global.islandSize.y/2 + 1)
				var setcell_left = Vector2i(x_pos + x - Global.islandSize.x/2 - 1, y_pos + y - Global.islandSize.y/2)
				var setcell_right = Vector2i(x_pos + x - Global.islandSize.x/2 + 1, y_pos + y - Global.islandSize.y/2)
				var me = grassLayer.get_cell_atlas_coords(setcell)
				var up = grassLayer.get_cell_atlas_coords(setcell_up)
				var down = grassLayer.get_cell_atlas_coords(setcell_down)
				var left = grassLayer.get_cell_atlas_coords(setcell_left)
				var right = grassLayer.get_cell_atlas_coords(setcell_right)
				
				if setcell != Vector2i(0,0) and setcell != Vector2i(1,0) and setcell != Vector2i(1,1) and setcell != Vector2i(0,1) and setcell != Vector2i(-1,-1) and setcell != Vector2i(-1, 0) and setcell != Vector2i(0, -1) and setcell != Vector2i(1, -1) and setcell != Vector2i(-1, 1):
					if isgrass(me) and isgrass(up) and isgrass(down) and isgrass(left) and isgrass(right):
						hillposisions.append(setcell)
						if i == i_random:
							if x == 2 && y == 2:
								temp_corepos = setcell
							 
					else: allisongrass = false
				else: allisongrass = false
	
	if allisongrass == true:
		if temp_corepos != Vector2i.ZERO:
			coretilemapposision = temp_corepos
		for pos in hillposisions:
			hill.set_cell(pos, 0, Dic["hill"])

	return allisongrass

func find_highest_point(noise: FastNoiseLite) -> Vector2i:
	var highest_noise_value = -INF
	var highest_point: Vector2i
	
	for x in range(Global.islandSize.x):
		for y in range(Global.islandSize.y):
			var noise_value = noise.get_noise_2d(x, y)
			if noise_value > highest_noise_value:
				highest_noise_value = noise_value
				highest_point = Vector2i(x, y)
	
	return highest_point

func distance_between_points(vectori: Vector2, center_offset: Vector2) -> float:
	var max_distance = 40.0  # Maximum distance to scale against
	var distance = vectori.distance_to(center_offset)

	# Scale the distance between 0 and 1
	var scaled_distance = 1.0 - clamp(distance / max_distance, 0.0, 1.0)

	return scaled_distance

func secondlayerfilter():
	for x in range(Global.islandSize.x):
		for y in range(Global.islandSize.y):
			var setcell = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2)
			var setcell_up = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2 - 1)
			var setcell_up_left = Vector2i(x - Global.islandSize.x/2 - 1, y - Global.islandSize.y/2 - 1)
			var setcell_up_right = Vector2i(x - Global.islandSize.x/2 + 1, y - Global.islandSize.y/2 - 1)
			var setcell_down = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2 + 1)
			var setcell_down_left = Vector2i(x - Global.islandSize.x/2 - 1, y - Global.islandSize.y/2 + 1)
			var setcell_down_right = Vector2i(x - Global.islandSize.x/2 + 1, y - Global.islandSize.y/2 + 1)
			var setcell_left = Vector2i(x - Global.islandSize.x/2 - 1, y - Global.islandSize.y/2)
			var setcell_right = Vector2i(x - Global.islandSize.x/2 + 1, y - Global.islandSize.y/2)
			var me = grassLayer.get_cell_atlas_coords(setcell)
			var up = grassLayer.get_cell_atlas_coords(setcell_up)
			var up_left = grassLayer.get_cell_atlas_coords(setcell_up_left)
			var up_right = grassLayer.get_cell_atlas_coords(setcell_up_right)
			var down = grassLayer.get_cell_atlas_coords(setcell_down)
			var down_left = grassLayer.get_cell_atlas_coords(setcell_down_left)
			var down_right = grassLayer.get_cell_atlas_coords(setcell_down_right)
			var left = grassLayer.get_cell_atlas_coords(setcell_left)
			var right = grassLayer.get_cell_atlas_coords(setcell_right)
			
			var underside_up = underside.get_cell_atlas_coords(setcell_up)
			

			
			#set the edges of the grass
			if isgrass(me):
				if isn(left) or isn(right) or isn(up) or isn(down): #something everywhere
					if !isn(left) && !isn(right) && isn(up) && !isn(down): #nothing up
						grassLayer.set_cell(setcell, 0, Dic["grass_Top"])
					elif !isn(left) && !isn(right) && !isn(up) && isn(down): #nothing down
						grassLayer.set_cell(setcell, 0, Dic["grass_Bottom"])
					elif isn(left) && !isn(right) && !isn(up) && !isn(down): #nothing left
						grassLayer.set_cell(setcell, 0, Dic["grass_Left"])
					elif !isn(left) && isn(right) && !isn(up) && !isn(down): #nothing right
						grassLayer.set_cell(setcell, 0, Dic["grass_Right"])
						
					elif isn(left) && isn(right) && !isn(up) && !isn(down): #some up and down
						grassLayer.set_cell(setcell, 0, Dic["grass_Center_strait_vertical"])
					elif !isn(left) && !isn(right) && isn(up) && isn(down): #some left and right
						grassLayer.set_cell(setcell, 0, Dic["grass_Center_strait_sideward"])
					
					elif isn(left) && isn(right) && !isn(up) && isn(down): #something up
						grassLayer.set_cell(setcell, 0, Dic["grass_Center_end_Bottom"])
					elif isn(left) && isn(right) && isn(up) && !isn(down): #something down
						grassLayer.set_cell(setcell, 0, Dic["grass_Center_end_Top"])
					elif !isn(left) && isn(right) && isn(up) && isn(down): #something left
						grassLayer.set_cell(setcell, 0, Dic["grass_Center_end_Right"])
					elif isn(left) && !isn(right) && isn(up) && isn(down): #something right 
						grassLayer.set_cell(setcell, 0, Dic["grass_Center_end_Left"])
					
					elif isn(left) && !isn(right) && isn(up) && !isn(down): #nothing up and left
						grassLayer.set_cell(setcell, 0, Dic["grass_corner_Top_left"])
					elif !isn(left) && isn(right) && isn(up) && !isn(down): #nothing up and right
						grassLayer.set_cell(setcell, 0, Dic["grass_corner_Top_Right"])
					elif isn(left) && !isn(right) && !isn(up) && isn(down): #nothing down left
						grassLayer.set_cell(setcell, 0, Dic["grass_corner_Bottom_Left"])
					elif !isn(left) && isn(right) && !isn(up) && isn(down): #nothing down right
						grassLayer.set_cell(setcell, 0, Dic["grass_corner_Bottom_Right"])
						
					elif isn(left) && isn(right) && isn(up) && isn(down):
						grassLayer.set_cell(setcell, 0, Dic["grass_very_center"])
				
			#underside peaces
			elif isn(me):
				#first layer of underside
				if isgrass(up):
					#underside_Top_Middle
					if isgrass(up_left) and isgrass(up_right):
						underside.set_cell(setcell, 0, Dic["underside_Top_Middle"])
					#underside_Top_left
					elif !isgrass(up_left) and isgrass(up_right):
						underside.set_cell(setcell, 0, Dic["underside_Top_left"])
					#underside_Top_right
					elif isgrass(up_left) and !isgrass(up_right):
						underside.set_cell(setcell, 0, Dic["underside_Top_right"])
					#underside_Top_Center
					elif !isgrass(up_left) and !isgrass(up_right):
						underside.set_cell(setcell, 0, Dic["underside_Top_Center"])
				
				#second layer of underside
				elif underside_up == Dic["underside_Top_Center"]:
					underside.set_cell(setcell, 0, Dic["underside_Bottom_Center"])
				elif underside_up == Dic["underside_Top_left"]:
					underside.set_cell(setcell, 0, Dic["underside_Bottom_left"])
				elif underside_up == Dic["underside_Top_Middle"]:
					underside.set_cell(setcell, 0, Dic["underside_Bottom_Middle"])
				elif underside_up == Dic["underside_Top_right"]:
					underside.set_cell(setcell, 0, Dic["underside_Bottom_right"])

func hillsecondlayerfilter():
	for x in range(Global.islandSize.x):
		for y in range(Global.islandSize.y):
			var setcell = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2)
			var setcell_up = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2 - 1)
			var setcell_up_left = Vector2i(x - Global.islandSize.x/2 - 1, y - Global.islandSize.y/2 - 1)
			var setcell_up_right = Vector2i(x - Global.islandSize.x/2 + 1, y - Global.islandSize.y/2 - 1)
			var setcell_down = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2 + 1)
			var setcell_down_left = Vector2i(x - Global.islandSize.x/2 - 1, y - Global.islandSize.y/2 + 1)
			var setcell_down_right = Vector2i(x - Global.islandSize.x/2 + 1, y - Global.islandSize.y/2 + 1)
			var setcell_left = Vector2i(x - Global.islandSize.x/2 - 1, y - Global.islandSize.y/2)
			var setcell_right = Vector2i(x - Global.islandSize.x/2 + 1, y - Global.islandSize.y/2)
			var hill_me = hill.get_cell_atlas_coords(setcell)
			var hill_up_left = hill.get_cell_atlas_coords(setcell_up_left)
			var hill_up_right = hill.get_cell_atlas_coords(setcell_up_right)
			var hill_up = hill.get_cell_atlas_coords(setcell_up)
			var hill_down = hill.get_cell_atlas_coords(setcell_down)
			var hill_left = hill.get_cell_atlas_coords(setcell_left)
			var hill_right = hill.get_cell_atlas_coords(setcell_right)
			
			#set the edges of the hill
			if ishill(hill_me):				
				if !ishill(hill_left):
					if !ishill(hill_up) && hill_down == Dic["null"]:
						hill.set_cell(setcell, 0, Dic["hill_Left"])
					elif !ishill(hill_up):
						hill.set_cell(setcell, 0, Dic["hill_Top_left"])
					elif hill_down == Dic["null"]:
						hill.set_cell(setcell, 0, Dic["hill_Bottom_Left"])
					else:
						hill.set_cell(setcell, 0, Dic["hill_Left"])
				elif hill_right == Dic["null"]:
					if !ishill(hill_up) && hill_down == Dic["null"]:
						hill.set_cell(setcell, 0, Dic["hill_Right"])
					elif !ishill(hill_up):
						hill.set_cell(setcell, 0, Dic["hill_Top_Right"])
					elif hill_down == Dic["null"]:
						hill.set_cell(setcell, 0, Dic["hill_Bottom_Right"])
					else:
						hill.set_cell(setcell, 0, Dic["hill_Right"])
				elif !ishill(hill_up):
					hill.set_cell(setcell, 0, Dic["hill_Top"])
				elif hill_down == Dic["null"]:
					hill.set_cell(setcell, 0, Dic["hill_Bottom"])
			
			#set the pilats inder the hill
			if hill_me == Dic["null"]:
				if ishill(hill_up):
					if ishill(hill_up_right) and ishill(hill_up_left):
						hill.set_cell(setcell, 0, Dic["hill_pilar"])
					#underside_Top_left
					elif ishill(hill_up_right) and  !ishill(hill_up_left):
						hill.set_cell(setcell, 0, Dic["hill_pilar_left"])
					#underside_Top_right
					elif !ishill(hill_up_right) and  ishill(hill_up_left):
						hill.set_cell(setcell, 0, Dic["hill_pilar_right"])
					#underside_Top_Center
					elif !ishill(hill_up_right) and  !ishill(hill_up_left):
						hill.set_cell(setcell, 0, Dic["hill_pilar_Center"])

func collsionlayerfilter():
	for x in range(Global.islandSize.x):
		for y in range(Global.islandSize.y):
			var setcell = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2)
			var setcell_down = Vector2i(x - Global.islandSize.x/2, y - Global.islandSize.y/2 + 1)
			var hill_me = hill.get_cell_atlas_coords(setcell)
			
			if ishill(hill_me):
				grassLayer.set_cell(setcell_down, 0, Dic["grass_collision_all"])

#checks if the given atlascoords is any type of grass
func isgrass(grassmaybe: Vector2i) -> bool:
	if grassmaybe == Dic["grass"]: return true
	elif grassmaybe == Dic["grass_Bottom"]: return true
	elif grassmaybe == Dic["grass_Left"]: return true
	elif grassmaybe == Dic["grass_Right"]: return true
	elif grassmaybe == Dic["grass_Top"]: return true
	elif grassmaybe == Dic["grass_Center_end_Bottom"]: return true
	elif grassmaybe == Dic["grass_Center_end_Left"]: return true
	elif grassmaybe == Dic["grass_Center_end_Right"]: return true
	elif grassmaybe == Dic["grass_Center_end_Top"]: return true
	elif grassmaybe == Dic["grass_Center_strait_sideward"]: return true
	elif grassmaybe == Dic["grass_Center_strait_vertical"]: return true
	elif grassmaybe == Dic["grass_corner_Bottom_Left"]: return true
	elif grassmaybe == Dic["grass_corner_Bottom_Right"]: return true
	elif grassmaybe == Dic["grass_corner_Top_left"]: return true
	elif grassmaybe == Dic["grass_corner_Top_Right"]: return true
	
	else:
		return false

func ishill(grassmaybe: Vector2i) -> bool:
	if grassmaybe == Dic["hill"]: return true
	elif grassmaybe == Dic["hill_Center"]: return true
	elif grassmaybe == Dic["hill_Left"]: return true
	elif grassmaybe == Dic["hill_Right"]: return true
	elif grassmaybe == Dic["hill_Top"]: return true
	elif grassmaybe == Dic["hill_Bottom"]: return true
	elif grassmaybe == Dic["hill_Bottom_Left"]: return true
	elif grassmaybe == Dic["hill_Bottom_Right"]: return true
	elif grassmaybe == Dic["hill_Top_left"]: return true
	elif grassmaybe == Dic["hill_Top_Right"]: return true
	
	else:
		return false

func isn(isnull: Vector2i) -> bool:
	return isnull == Dic["null"]
