extends Node2D

@export var genarate : bool
@onready var noise_generator = $NoiseGenerator
@onready var grass: TileMapLayer = $Tilemaps/grass
@onready var underside: TileMapLayer = $Tilemaps/underside


var cliff_data_layer_namel = "cliffl"  # Replace with your custom data layer name
var cliff_data_layer_namem = "cliffm"  # Replace with your custom data layer name
var cliff_data_layer_namer = "cliffr"  # Replace with your custom data layer name
var cliff_data_layer_namec = "cliffc"  # Replace with your custom data layer name
var replacement_tile_atlas_coordsl = Vector2i(16, 1)  # Atlas coordinates for replacement tile
var replacement_tile_atlas_coords2l = Vector2i(16, 2)  # Atlas coordinates for replacement tile
var replacement_tile_atlas_coordsm = Vector2i(18, 1)  # Atlas coordinates for replacement tile
var replacement_tile_atlas_coords2m = Vector2i(18, 2)  # Atlas coordinates for replacement tile
var replacement_tile_atlas_coordsr = Vector2i(19, 1)  # Atlas coordinates for replacement tile
var replacement_tile_atlas_coords2r = Vector2i(19, 2)  # Atlas coordinates for replacement tile

func _ready():
	if genarate == true:
		checkforstartspace()

		if not grass:
			print("Warning: No TileMap assigned in script!")
			return
		else:
			check_and_replace_cliff_tiles()


func check_and_replace_cliff_tiles():
	# Iterate through all used cells in the tile map
	for cell in grass.get_used_cells():
		# Get tile data and check if custom data layer exists
		var cell_data = grass.get_cell_tile_data(Vector2i(cell.x, cell.y))
		if not cell_data:
			continue  # Skip empty cells
		
		#left corner mid right corner check
		var cliff_data_left = cell_data.get_custom_data(cliff_data_layer_namel)
		var cliff_data_mid = cell_data.get_custom_data(cliff_data_layer_namem)
		var cliff_data_right = cell_data.get_custom_data(cliff_data_layer_namer)
		var cliff_data_center = cell_data.get_custom_data(cliff_data_layer_namec)
		
		# Cliff tile found, replace it
		if cliff_data_center == true:
			underside.set_cell(Vector2i(cell.x, cell.y + 1), grass.get_cell_source_id(cell), replacement_tile_atlas_coordsm)
			underside.set_cell(Vector2i(cell.x, cell.y + 2), grass.get_cell_source_id(cell), replacement_tile_atlas_coords2m)

		# Cliff tile found, replace it
		if cliff_data_left == true:
			underside.set_cell(Vector2i(cell.x, cell.y + 1), grass.get_cell_source_id(cell), replacement_tile_atlas_coordsl)
			underside.set_cell(Vector2i(cell.x, cell.y + 2), grass.get_cell_source_id(cell), replacement_tile_atlas_coords2l)

		# Cliff tile found, replace it
		if cliff_data_mid == true:
			underside.set_cell(Vector2i(cell.x, cell.y + 1), grass.get_cell_source_id(cell), replacement_tile_atlas_coordsm)
			underside.set_cell(Vector2i(cell.x, cell.y + 2), grass.get_cell_source_id(cell), replacement_tile_atlas_coords2m)

		# Cliff tile found, replace it
		if cliff_data_right == true:
			underside.set_cell(Vector2i(cell.x, cell.y + 1), grass.get_cell_source_id(cell), replacement_tile_atlas_coordsr)
			underside.set_cell(Vector2i(cell.x, cell.y + 2), grass.get_cell_source_id(cell), replacement_tile_atlas_coords2r)

func checkforstartspace():
	noise_generator.generate()	
	var tile = grass.get_cell_tile_data(Vector2i(64, 64))
	if tile != null:
		if tile.terrain == 0:
			print("Tile at 64, 64 has atlas coords x4, y1 and terrain property 1")
		else:
			checkforstartspace()
	else:
		checkforstartspace()
