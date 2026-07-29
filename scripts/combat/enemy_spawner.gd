extends Node

@export var spawn_distance: float = 100.0
@export var enemy_scenes: Array[PackedScene] = [
	preload("res://scene/enemy.tscn"),
]
@export var spawn_interval := 0.8

signal enemy_destroyed
signal wave_completed

var _rng := RandomNumberGenerator.new()
var _enemies_to_spawn := 0
var _active_enemies := 0
var _night := 0
var _spawn_timer: Timer

func _ready() -> void:
	_rng.randomize()
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.timeout.connect(_spawn_next_enemy)
	add_child(_spawn_timer)

func start_night_wave(enemy_count: int, night: int) -> void:
	stop_wave()
	_enemies_to_spawn = enemy_count
	_night = night
	Global.log_event("Wave %d armed: %d flying enemies incoming." % [night, enemy_count])
	_spawn_timer.start()
	_spawn_next_enemy()

func stop_wave() -> void:
	_enemies_to_spawn = 0
	_spawn_timer.stop()
	for child in get_children():
		if child is Enemy:
			child.queue_free()
	_active_enemies = 0

func _spawn_next_enemy() -> void:
	if _enemies_to_spawn <= 0:
		_spawn_timer.stop()
		_check_wave_complete()
		return
	_enemies_to_spawn -= 1
	spawn_enemy(_random_spawn_position())

func spawn_enemy(at_position: Vector2) -> void:
	var scene := enemy_scenes[_rng.randi() % enemy_scenes.size()]
	var enemy := scene.instantiate() as Enemy
	# Build pressure gradually: an extra attacker each night, modest health growth,
	# and contact damage only increases after the early-game learning curve.
	enemy.StartHealth = 5 + 2 * (_night - 1)
	enemy.contact_damage = 1 + ((_night - 1) / 3)
	enemy.speed_multiplier = 1.0 + 0.03 * (_night - 1)
	add_child(enemy)
	enemy.global_position = at_position
	_active_enemies += 1
	Global.log_event("Enemy spawned at %s. %d still waiting, %d active." % [at_position, _enemies_to_spawn, _active_enemies])
	enemy.tree_exited.connect(_on_enemy_removed.bind(enemy))

func _on_enemy_removed(enemy: Enemy) -> void:
	if not is_instance_valid(enemy) or enemy.Health <= 0:
		enemy_destroyed.emit()
	_active_enemies = max(_active_enemies - 1, 0)
	_check_wave_complete()

func _check_wave_complete() -> void:
	if _enemies_to_spawn == 0 and _active_enemies == 0 and Global.phase == Global.RunPhase.NIGHT:
		Global.log_event("All enemies in wave %d were defeated." % _night)
		wave_completed.emit()

func _random_spawn_position() -> Vector2:
	var angle := _rng.randf_range(0.0, TAU)
	return Vector2(cos(angle), sin(angle)) * spawn_distance
