extends CanvasLayer

@export var smallitemamount: int
@export var bigitemamount: int
@export var guntexture: Texture2D

@onready var robot_list: ItemList = $HBoxContainer/background/VBoxContainer/HBoxContainer/robot/VBoxContainer/RoBotlist
@onready var inventory_list: ItemList = $HBoxContainer/background/VBoxContainer/HBoxContainer/inventory/VBoxContainer2/inventorylist
@onready var gun_shop_list: ItemList = $HBoxContainer/background/VBoxContainer/HBoxContainer/guns/VBoxContainer2/GunShopList
@onready var buy_button: Button = $HBoxContainer/background/VBoxContainer/HBoxContainer/guns/VBoxContainer2/buygun

var selected_robot: int = -1
var selected_gun: int = -1

func _ready():
	robot_list.connect("item_selected", _on_robot_selected)
	inventory_list.connect("item_selected", _on_inventory_item_selected)
	gun_shop_list.connect("item_selected", _on_gun_shop_item_selected)
	buy_button.connect("pressed", _on_give_gun_pressed)
	
	for index in smallitemamount:
		gun_shop_list.add_icon_item(guntexture)
	
	
	var x: int = 0
	var y: int = 0

	for index in range(gun_shop_list.item_count):
		x = (index % 4)
		y = index / 4

		var pos: Rect2i = Rect2i(32 * x, 16 * y, 32, 16)
		gun_shop_list.set_item_icon_region(index, pos)

func _on_robot_selected(index: int) -> void:
	selected_robot = index
	_try_equip_selected_items()

func _on_inventory_item_selected(index: int) -> void:
	selected_gun = index
	_try_equip_selected_items()

func _on_gun_shop_item_selected(index: int) -> void:
	selected_gun = index

func _try_equip_selected_items() -> void:
	if selected_robot != -1 and selected_gun != -1:
		_equip_gun_to_robot(selected_robot, selected_gun)
		selected_robot = -1
		selected_gun = -1

func _equip_gun_to_robot(robot_index: int, gun_index: int) -> void:
	# Implement the logic to equip the gun to the selected robot
	var robot = robot_list.get_item_text(robot_index)
	var gun = inventory_list.get_item_text(gun_index)
	var random_color = Color(randf(), randf(), randf())
	print("Equipping gun '%s' to robot '%s'" % [gun, robot])
	robot_list.set_item_icon_modulate(robot_index, random_color)
	inventory_list.set_item_icon_modulate(gun_index, random_color)
	# Add your custom logic here

func _on_give_gun_pressed() -> void:
	if selected_gun != -1:		
		var gun_text = gun_shop_list.get_item_text(selected_gun)
		var gun_icon = gun_shop_list.get_item_icon(selected_gun)
		var gun_rect = gun_shop_list.get_item_icon_region(selected_gun)
		inventory_list.add_item(gun_text, gun_icon)
		inventory_list.set_item_icon_region(inventory_list.item_count -1, gun_rect)
		
		gun_shop_list.deselect_all()
		print("Bought gun '%s'" % selected_gun)
