extends Area2D

@export var speed: float = 300.0
@export var damage: int = 10
@export var max_distance: float = 1000.0

var direction: Vector2 = Vector2.ZERO
var _start_position: Vector2

func _ready() -> void:
	_start_position = global_position
	connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	if global_position.distance_to(_start_position) > max_distance:
		queue_free()

func _on_body_entered(body: Node) -> void:
	print("shot" + str(body.is_in_group("Bots")) + str(body.has_method("takedamage")))
	if body.is_in_group("Bots") and body.has_method("takedamage"):
		body.takedamage(damage)
		queue_free()
