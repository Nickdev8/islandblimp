extends Control
@onready var rich_text_label: RichTextLabel = $VBoxContainer2/Control/VBoxContainer/HBoxContainer/Control2/RichTextLabel
@onready var start: Button = $VBoxContainer2/Control/VBoxContainer/Start
@onready var exit: Button = $VBoxContainer2/Control/VBoxContainer/Exit
@onready var difficulty_slider: HSlider = $"VBoxContainer2/Control/VBoxContainer/HBoxContainer/Difficulty Slider"

const MAIN = "res://scene/main.tscn"

func _ready() -> void:
	_on_difficulty_slider_value_changed(0)

func _on_difficulty_slider_value_changed(value: float) -> void:
	#Global.difficulty = value
	var difftext: String
	if value ==0: difftext = "Normal"
	elif value ==1: difftext = "Medium"
	elif value ==2: difftext = "Harder"
	elif value ==3: difftext = "Extreme"
	rich_text_label.text = difftext
	


func _on_start_button_up() -> void:
	Global.difficulty = difficulty_slider.value
	var new_scene = load(MAIN)
	get_tree().change_scene_to_packed(new_scene)

func _on_exit_button_up() -> void:
	get_tree().quit()
