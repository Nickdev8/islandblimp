extends Node2D

@export var StartHealth: int
@export var SNAP_VALUE: int = 14
var Health: int
signal health_changed(send_Health: int, send_SNAP_VALUE: int)
signal health_start(send_Start_Health: int, send_SNAP_VALUE: int)

func _ready() -> void:
	Health = StartHealth
	Global.coreIsAlive = Health > 0

func takedamage(DamageAmount: int) -> void:
	Health -= DamageAmount
	if Health <= 0:
		Health = 0
	Global.coreIsAlive = Health > 0
	emit_signal("health_changed", Health, SNAP_VALUE)
