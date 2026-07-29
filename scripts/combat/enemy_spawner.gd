extends Node

@export var spawn_distance: float = 100.0
@export var wave_sizes: Array[int] = [2, 3, 4]
@export var enemy_scenes: Array[PackedScene] = [
	preload("res://scene/enemy.tscn"),
	# add more variations:
]

@export var time_between_waves: float = 5.0

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	var wave_timer := Timer.new()
	wave_timer.wait_time = time_between_waves
	wave_timer.one_shot = false
	wave_timer.autostart = true
	add_child(wave_timer)
	wave_timer.timeout.connect(_on_wave_timer_timeout)

	_spawn_wave()

func _on_wave_timer_timeout() -> void:
	_spawn_wave()

func _spawn_wave() -> void:
	var count := wave_sizes[_rng.randi() % wave_sizes.size()]
	for i in count:
		spawn_enemy(_random_spawn_position())

func spawn_enemy(at_position: Vector2) -> void:
	var scene := enemy_scenes[_rng.randi() % enemy_scenes.size()]
	var enemy := scene.instantiate()
	enemy.StartHealth = randi_range(1,10)
	add_child(enemy)
	if enemy is Node2D:
		enemy.position = at_position

func _random_spawn_position() -> Vector2:
	var angle := _rng.randf_range(0.0, TAU)
	return Vector2(cos(angle), sin(angle)) * spawn_distance
