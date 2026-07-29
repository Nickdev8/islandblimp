class_name ShootScript
extends Node2D

@export var is_Enemys: bool
@export var projectile_scene: PackedScene
@export var shoot_interval: float = 1.2
@export var accuracy: float = 0.1
@export var projectile_speed: float = 160.0
@export var projectile_damage: int = 3
var projectile_sprite: int = 0
var see_distance: float = 96.0
@export var projectile_max_distance: float = 1000.0

var _rng := RandomNumberGenerator.new()
var _shot_timer: Timer
var _shot_cooldown := 0.0

func _ready() -> void:
	_rng.randomize()
	_shot_timer = Timer.new()
	_shot_timer.wait_time = shoot_interval
	_shot_timer.one_shot = false
	_shot_timer.autostart = true
	add_child(_shot_timer)
	_shot_timer.timeout.connect(_on_shoot_timeout)

func set_shoot_interval(value: float) -> void:
	shoot_interval = value
	if is_instance_valid(_shot_timer):
		_shot_timer.wait_time = shoot_interval

func _process(delta: float) -> void:
	_shot_cooldown = maxf(_shot_cooldown - delta, 0.0)

func _on_shoot_timeout() -> void:
	if get_parent().has_method("can_shoot") and not get_parent().can_shoot():
		return
	var target = _find_closest_target()
	if target:
		try_shoot_at(target)

func try_shoot_at(target: Node2D) -> bool:
	if not is_instance_valid(target) or _shot_cooldown > 0.0:
		return false
	if get_parent().has_method("can_shoot") and not get_parent().can_shoot():
		return false
	if global_position.distance_to(target.global_position) >= see_distance:
		return false
	_shoot_at(target)
	_shot_cooldown = shoot_interval
	if get_parent().has_method("consume_shot_energy"):
		get_parent().consume_shot_energy()
	return true

func _find_closest_target() -> Node2D:
	var best: Node2D
	var best_dist := see_distance
	var targets: Array = []
	if is_Enemys:
		targets = get_tree().get_nodes_in_group("Bots")
		targets.append_array(get_tree().get_nodes_in_group("Core"))
	else:
		targets = get_tree().get_nodes_in_group("Enemys")

	for enemy in targets:
		var d = global_position.distance_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			best = enemy

	return best

func _shoot_at(target: Node2D) -> void:
	var proj = projectile_scene.instantiate()
	proj.from_enimi    = is_Enemys
	proj.scan          = true
	proj.global_position = global_position
	proj.spriteindex = projectile_sprite
	proj.spawned_by = _spawn_source_label()

	var dir = (target.global_position - global_position).normalized()
	dir += Vector2(
		_rng.randf_range(-accuracy, accuracy),
		_rng.randf_range(-accuracy, accuracy)
	)
	proj.direction    = dir.normalized()
	proj.speed        = projectile_speed
	proj.damage       = projectile_damage
	proj.max_distance = projectile_max_distance
	get_tree().current_scene.add_child(proj)

func _spawn_source_label() -> String:
	var source := get_parent()
	if source is RoBot:
		return source.display_name
	if source is Enemy:
		return "flying enemy"
	return source.name if source else name
