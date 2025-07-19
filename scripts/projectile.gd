extends Area2D

@export var spriteindex: int
@export var speed: float = 300.0
@export var damage: int = 10
@export var max_distance: float = 1000.0
@export var from_enimi: bool
@export var scan: bool = false
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


var direction: Vector2 = Vector2.ZERO
var _start_position: Vector2

func _ready() -> void:
	_start_position = global_position
	animated_sprite_2d.frame = spriteindex
	connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	if global_position.distance_to(_start_position) > max_distance:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if scan:
		var targets: Array
		if from_enimi:
			targets = get_tree().get_nodes_in_group("Bots")
			targets.append_array(get_tree().get_nodes_in_group("Core"))
		else:
			targets = get_tree().get_nodes_in_group("Enemys")
		if targets.has(body) and body.has_method("takedamage"):
			body.takedamage(damage)
			queue_free()
