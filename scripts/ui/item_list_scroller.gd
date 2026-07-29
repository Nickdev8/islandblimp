extends ItemList

@onready var v_box_container: VBoxContainer = $".."

func _ready():	
	v_box_container.connect("mouse_exited", _on_ItemList_mouse_exited)

func _on_ItemList_mouse_exited():
	pass
	#deselect_all()
