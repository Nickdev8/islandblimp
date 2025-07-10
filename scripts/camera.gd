extends Node2D

@onready var phantom_camera_2d: PhantomCamera2D = $PhantomCamera2D

@export var minimumzoom: float = 2.5
@export var maximumzoom: float = 0.8

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mousedown"):
		phantom_camera_2d.set_zoom(phantom_camera_2d.get_zoom() - Vector2(0.1, 0.1))
		if phantom_camera_2d.get_zoom().x < maximumzoom: phantom_camera_2d.set_zoom(Vector2(maximumzoom, maximumzoom))
	if event.is_action_pressed("mouseup"):
		phantom_camera_2d.set_zoom(phantom_camera_2d.get_zoom() + Vector2(0.1, 0.1))
		if phantom_camera_2d.get_zoom().x > minimumzoom: phantom_camera_2d.set_zoom(Vector2(minimumzoom, minimumzoom))
	
	#2.5 untill 0.8
