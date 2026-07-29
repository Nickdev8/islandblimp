extends Node

func _ready() -> void:
	Global.phase_changed.connect(_on_phase_changed)
	_on_phase_changed(Global.phase)

func _on_phase_changed(phase: Global.RunPhase) -> void:
	if phase == Global.RunPhase.NIGHT:
		RenderingServer.set_default_clear_color(Color("15213d"))
	elif phase == Global.RunPhase.GAME_OVER:
		RenderingServer.set_default_clear_color(Color("230c18"))
	else:
		RenderingServer.set_default_clear_color(Color("76b8d7"))
