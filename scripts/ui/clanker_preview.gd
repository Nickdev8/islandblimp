class_name ClankerPreview
extends Control

## Uses the same 16×16 source frames as the in-world Clankers. Keeping the
## terminal previews on the real sprite sheet prevents the shop from drifting
## away from the game's pixel-art language.
const ROBOT_SHEET := preload("res://assets/robotsheet.png")
const IDLE_FRAMES := {
	"chonker": Rect2(0, 0, 16, 16),
	"round": Rect2(0, 16, 16, 16),
	"block": Rect2(0, 32, 16, 16),
}

@export var clanker_type := "round":
	set(value):
		clanker_type = value
		queue_redraw()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func _draw() -> void:
	var source: Rect2 = IDLE_FRAMES.get(clanker_type, IDLE_FRAMES["round"])
	var pixel_scale := 3.0
	var preview_size := Vector2(16, 16) * pixel_scale
	var destination := Rect2((size - preview_size) * 0.5, preview_size)
	# A low-key shadow keeps the small pixel sprite legible on the blue-black
	# terminal without inventing a new illustration style.
	draw_rect(Rect2(destination.position + Vector2(4, 5), preview_size), Color("09111d66"))
	draw_texture_rect_region(ROBOT_SHEET, destination, source)
