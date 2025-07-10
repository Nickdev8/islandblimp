extends Node2D

@onready var white: ColorRect = $White
@onready var red: ColorRect = $Red
@onready var green: ColorRect = $Green
@onready var redextra: ColorRect = $Redextra
@onready var greenextra: ColorRect = $Greenextra

var snapped_value
var remainder

func _ready() -> void:
	get_parent().connect("health_changed", Callable(self, "setHealthrect"))
	get_parent().connect("health_start", Callable(self, "startrect"))

func regenarate():
	print("regenerating")
	
func shooting():
	print("shooting")
	
func startrect(starthealth, snapvalue):
	if starthealth <= snapvalue:
		red.scale.x = starthealth
		green.scale.x = starthealth
		redextra.scale.x = starthealth
		greenextra.scale.x = starthealth
		white.scale.x = 2 + starthealth
		
		red.position.x = -starthealth / 2 - 0.1
		green.position.x = -starthealth / 2 - 0.1
		redextra.position.x = -starthealth / 2 - 0.1
		greenextra.position.x = -starthealth / 2 - 0.1
	else:
		fits_into_fourteen(starthealth, snapvalue)
		white.scale.x = 2 + snapvalue
		white.position.x = 0
		red.scale.x = snapvalue
		green.scale.x = snapvalue
		red.scale.y = snapped_value
		green.scale.y = snapped_value
		redextra.scale.x = remainder
		greenextra.scale.x = remainder
		redextra.position.y = -2 + snapped_value
		greenextra.position.y = -2 + snapped_value
		white.scale.y = 3 + snapped_value
	
func fits_into_fourteen(StartH: int, SNAP_V: int):
	if StartH < 0:
		push_error("WARNING: The function only works with positive integers. Ignoring negative value.")

	snapped_value = StartH / SNAP_V  # Integer division gives the number of times it fits
	remainder = StartH % SNAP_V  # Modulus gives the remainder

func setHealthrect(health, snapvalue):
	if health <= snapvalue:
		green.scale.x = health
		green.scale.y = 1
		greenextra.scale.x = health
		greenextra.position.y = -2
	else:
		fits_into_fourteen(health, snapvalue)
		
		green.scale.x = snapvalue
		green.scale.y = snapped_value
		greenextra.scale.x = remainder
		greenextra.position.y = -2 + snapped_value
