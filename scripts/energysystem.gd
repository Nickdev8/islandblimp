extends Control

# ——— the exports now use “: set = …” instead of setget ———
@export var start_health:   int     = 10  : set = _set_max_health
@export var current_health: int     = 10  : set = _set_current_health
@export var offset:         Vector2 = Vector2.ZERO
@export var padding:        int     = 1

var background: ColorRect
var green_bar:    ColorRect
var red_bar:      ColorRect

func _ready() -> void:
	_create_bar()
	# initial sizing
	background.size = Vector2(start_health + padding*2, 1 + padding*2)
	_update_bar()
	if get_parent():
		get_parent().connect("health_start",   Callable(self, "_on_health_start"))
		get_parent().connect("health_changed", Callable(self, "_on_health_changed"))


func _set_max_health(val: int) -> void:
	# clamp to at least 1px wide
	start_health = max(val, 1)
	# resize frame and clamp fill
	background.size   = Vector2(start_health + padding*2, 1 + padding*2)
	current_health    = clamp(current_health, 0, start_health)
	_update_bar()


func _set_current_health(val: int) -> void:
	current_health = clamp(val, 0, start_health)
	print(current_health)
	_update_bar()


func _create_bar() -> void:
	background = ColorRect.new()
	background.name  = "Background"
	background.color = Color(0.1, 0.1, 0.1)
	background.anchor_left   = 0
	background.anchor_top    = 0
	background.anchor_right  = 0
	background.anchor_bottom = 0
	add_child(background)

	green_bar = ColorRect.new()
	green_bar.name  = "GreenBar"
	green_bar.color = Color(0, 1, 0)
	green_bar.anchor_left   = 0
	green_bar.anchor_top    = 0
	green_bar.anchor_right  = 0
	green_bar.anchor_bottom = 0
	background.add_child(green_bar)

	red_bar = ColorRect.new()
	red_bar.name  = "RedBar"
	red_bar.color = Color(1, 0, 0)
	red_bar.anchor_left   = 0
	red_bar.anchor_top    = 0
	red_bar.anchor_right  = 0
	red_bar.anchor_bottom = 0
	background.add_child(red_bar)


func _update_bar() -> void:
	# position the frame so it always has `padding` on all sides
	background.position = offset - Vector2(padding, padding)

	# size the two 1px-tall bars
	green_bar.size = Vector2(current_health, 1)
	red_bar.size   = Vector2(start_health - current_health, 1)

	# and place them inside the padding
	green_bar.position = Vector2(padding, padding)
	red_bar.position   = Vector2(padding + current_health, padding)


# Optional signal handlers, if your parent still emits these:
func _on_health_start(new_max: float, snap_val: float) -> void:
	_set_max_health(int(new_max))
	_set_current_health(int(new_max))

func _on_health_changed(new_health: float, snap_val: float) -> void:
	_set_current_health(int(new_health))
