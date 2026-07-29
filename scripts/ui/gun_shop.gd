extends ItemList

@export var texture: Texture2D

func _ready():
	if texture:
		load_guns()

func load_guns():
	clear()  # Clear existing items
	var columns = 4
	var rows = 9
	var tile_width = 32
	var tile_height = 16

	var image = texture.get_image()
	
	for row in range(rows):
		for col in range(columns):
			var region = Rect2(col * tile_width, row * tile_height, tile_width, tile_height)
			var sub_image = Image.new()
			sub_image.create(tile_width, tile_height, false, image.get_format())
			sub_image.blit_rect(image, region, Vector2(0, 0))
			sub_image.flip_y()  # Flip the image vertically because the y-axis is flipped in Godot

			var region_texture = ImageTexture.new()
			region_texture.create_from_image(sub_image)

			add_item("")
			set_item_icon(get_item_count() - 1, region_texture)
