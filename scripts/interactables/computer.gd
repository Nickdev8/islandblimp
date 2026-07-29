extends StaticBody2D

@onready var timer: Timer = $Timer
@onready var loadingbar: ColorRect = $animsprite/ColorRect

var timepersentage: int

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	timepersentage = ((timer.wait_time - timer.time_left) / timer.wait_time) * 100
	loadingbar.scale = Vector2(snapped(timepersentage/10, 1), 1)
