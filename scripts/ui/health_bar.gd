extends Control

## World-space health bar shared by Clankers, enemies, and the core.
## It uses a fixed pixel width so every bar stays centered under its entity,
## while the fill accurately represents the entity's current health fraction.
@export var below_entity_offset := 11.0

const BAR_WIDTH := 24.0
const BAR_HEIGHT := 3.0
const BORDER := 1.0

var start_health := 1
var current_health := 1
var background: ColorRect
var missing_health: ColorRect
var health_fill: ColorRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_bar()
	if get_parent():
		if get_parent().has_signal("health_start"):
			get_parent().health_start.connect(_on_health_start)
		if get_parent().has_signal("health_changed"):
			get_parent().health_changed.connect(_on_health_changed)
	call_deferred("_sync_initial_health")

func _sync_initial_health() -> void:
	var entity := get_parent()
	if not entity:
		return
	var maximum = entity.get("StartHealth")
	var current = entity.get("Health")
	if maximum is int and maximum > 0:
		start_health = maximum
		current_health = current if current is int else maximum
		_update_bar()

func _create_bar() -> void:
	background = ColorRect.new()
	background.color = Color("07101a")
	add_child(background)
	missing_health = ColorRect.new()
	missing_health.color = Color("b83b4b")
	background.add_child(missing_health)
	health_fill = ColorRect.new()
	health_fill.color = Color("5ee36e")
	background.add_child(health_fill)
	_update_bar()

func _on_health_start(new_maximum: float, _snap_value: float) -> void:
	start_health = max(int(new_maximum), 1)
	current_health = start_health
	_update_bar()

func _on_health_changed(new_health: float, _snap_value: float) -> void:
	current_health = clampi(int(new_health), 0, start_health)
	_update_bar()

func _update_bar() -> void:
	if not is_instance_valid(background):
		return
	var frame_size := Vector2(BAR_WIDTH + BORDER * 2.0, BAR_HEIGHT + BORDER * 2.0)
	size = frame_size
	position = Vector2(-frame_size.x * 0.5, below_entity_offset)
	background.size = frame_size
	missing_health.position = Vector2(BORDER, BORDER)
	missing_health.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	var health_ratio: float = clampf(float(current_health) / float(max(start_health, 1)), 0.0, 1.0)
	health_fill.position = Vector2(BORDER, BORDER)
	health_fill.size = Vector2(round(BAR_WIDTH * health_ratio), BAR_HEIGHT)
	visible = current_health > 0
