class_name ShootScript
extends Node2D

@export var is_Enemys: bool
@export var projectile_scene: PackedScene
@export var shoot_interval: float = 1.0
@export var accuracy: float = 0.1
@export var projectile_speed: float = 300.0
@export var projectile_damage: int = 10
@export var see_distance: float = 100.0
@export var projectile_max_distance: float = 1000.0

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	var t := Timer.new()
	t.wait_time = shoot_interval
	t.one_shot = false
	t.autostart = true
	add_child(t)
	t.timeout.connect(_on_shoot_timeout)

func _on_shoot_timeout() -> void:
	var target = _find_closest_target()
	if target:
		_shoot_at(target)

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
	get_tree().current_scene.add_child(proj)
	proj.from_enimi    = is_Enemys
	proj.scan          = true
	proj.global_position = global_position

	var dir = (target.global_position - global_position).normalized()
	dir += Vector2(
		_rng.randf_range(-accuracy, accuracy),
		_rng.randf_range(-accuracy, accuracy)
	)
	proj.direction    = dir.normalized()
	proj.speed        = projectile_speed
	proj.damage       = projectile_damage
	proj.max_distance = projectile_max_distance
