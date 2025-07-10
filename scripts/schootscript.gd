class_name schootscript extends Node2D

@export var accuracy: float = 0.1
@export var projectile_speed: float = 300.0
@export var damage: int = 10
@export var projectile_texture: Texture2D
@export var max_distance: float = 1000.0

var target: Node2D = null
var projectile: Node2D = null

func _ready():
	_find_target()
	if target:
		_shoot_projectile()

func _find_target():
	var closest_distance = max_distance
	for enemy in get_tree().get_nodes_in_group("Enemys"):
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			target = enemy

func _shoot_projectile():
	if not target:
		return
	
	projectile = Sprite2D.new()
	projectile.texture = projectile_texture
	projectile.global_position = global_position
	add_child(projectile)
	
	var direction = (target.global_position - global_position).normalized()
	direction += Vector2(randf() * accuracy - accuracy / 2, randf() * accuracy - accuracy / 2)  # Add some inaccuracy
	projectile.set_meta("direction", direction)
	projectile.set_meta("speed", projectile_speed)

func _process(delta):
	if projectile:
		_move_projectile(delta)
		_check_projectile_collision()

func _move_projectile(delta):
	var direction = projectile.get_meta("direction")
	var speed = projectile.get_meta("speed")
	projectile.global_position += direction * speed * delta
	
	if global_position.distance_to(projectile.global_position) > max_distance:
		projectile.queue_free()
		projectile = null

func _check_projectile_collision():
	for enemy in get_tree().get_nodes_in_group("Enemys"):
		if projectile and enemy.global_position.distance_to(projectile.global_position) < projectile.texture.get_size().length() / 2:
			enemy.take_damage(damage)
			projectile.queue_free()
			projectile = null
			break

func take_damage(amount):
	# Handle taking damage here
	pass
