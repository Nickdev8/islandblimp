class_name GameController
extends Node2D

const BOT_SCENE := preload("res://scene/bot.tscn")
const MENU_SCENE := preload("res://scene/main-menu.tscn")
const CLANKER_PREVIEW_SCRIPT := preload("res://scripts/ui/clanker_preview.gd")
const INTERACT_DISTANCE := 42.0

@onready var spawner: Node = $island/enimieSpawner
@onready var player: Node2D = $characters/OldMan

var shop_open := false
var selected_clanker: RoBot
var hud: Label
var prompt: Label
var panel: PanelContainer
var panel_content: VBoxContainer
var game_over_panel: VBoxContainer

func _ready() -> void:
	Global.reset_run()
	await get_tree().process_frame
	_connect_runtime_nodes()
	_build_ui()
	_refresh_ui()

func _connect_runtime_nodes() -> void:
	spawner.wave_completed.connect(_on_wave_completed)
	spawner.enemy_destroyed.connect(_on_enemy_destroyed)
	var core_nodes := get_tree().get_nodes_in_group("Core")
	if not core_nodes.is_empty():
		core_nodes[0].health_changed.connect(_on_core_health_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_9:
		Global.award_credits(50)
		Global.log_event("Cheat activated: received 50 credits.")
		_refresh_ui()
		return
	if event.is_action_pressed("interact"):
		_handle_interact()

func _handle_interact() -> void:
	if Global.phase == Global.RunPhase.GAME_OVER:
		return
	var computer := _nearest_group_node("Computers")
	if computer:
		shop_open = not shop_open
		_refresh_ui()
		return

func _nearest_group_node(group_name: String) -> Node2D:
	if not is_inside_tree() or not is_instance_valid(player):
		return null
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(group_name):
		if node is Node2D and player.global_position.distance_to(node.global_position) <= INTERACT_DISTANCE:
			return node
	return null

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(12, 12)
	layer.add_child(hud)
	prompt = Label.new()
	prompt.position = Vector2(12, 34)
	layer.add_child(prompt)
	panel = PanelContainer.new()
	panel.position = Vector2(14, 56)
	panel.custom_minimum_size = Vector2(390, 0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.visible = false
	layer.add_child(panel)
	panel_content = VBoxContainer.new()
	panel_content.add_theme_constant_override("separation", 8)
	panel.add_child(panel_content)
	game_over_panel = VBoxContainer.new()
	game_over_panel.position = Vector2(260, 150)
	game_over_panel.visible = false
	layer.add_child(game_over_panel)

func _refresh_ui() -> void:
	if not is_inside_tree() or not is_instance_valid(hud) or not is_instance_valid(prompt):
		return
	hud.text = "Credits: %d   %s %d   Clankers: %d" % [Global.credits, "Night" if Global.phase == Global.RunPhase.NIGHT else "Day", Global.night, Global.owned_clankers.size()]
	prompt.text = "[Space] Computer" if _nearest_group_node("Computers") else ""
	panel.visible = shop_open and Global.phase == Global.RunPhase.DAY
	if panel.visible:
		for child in panel_content.get_children():
			child.queue_free()
		_add_panel_label("CLANKER FABRICATOR", 20, Color("d9f6ff"))
		_add_panel_label("Day %d · %d credits · choose a frame, then hold the island." % [Global.night, Global.credits], 12, Color("8ea1b8"))
		var night_button := _add_button("START NIGHT %d  —  %d contacts" % [Global.night, 3 + (Global.night - 1)], _start_night)
		night_button.disabled = Global.owned_clankers.is_empty()
		if night_button.disabled:
			night_button.tooltip_text = "Buy at least one Clanker before starting the night."
		night_button.add_theme_stylebox_override("normal", _button_style(Color("167c8c")))
		var offers := HBoxContainer.new()
		offers.add_theme_constant_override("separation", 6)
		panel_content.add_child(offers)
		for type_name in ["round", "block", "chonker"]:
			offers.add_child(_make_clanker_offer(type_name))
		_add_panel_label("YOUR CLANKERS · %d ONLINE" % Global.owned_clankers.size(), 14, Color("d9f6ff"))
		var shown_clankers := 0
		for clanker in Global.owned_clankers:
			if is_instance_valid(clanker):
				_add_button("%s  ·  HP %d/%d  ·  DEFENDING" % [clanker.display_name, clanker.Health, clanker.StartHealth], _select_clanker.bind(clanker))
				shown_clankers += 1
				if shown_clankers >= 12:
					break
		if Global.owned_clankers.size() > shown_clankers:
			_add_panel_label("+ %d more Clankers defending the island" % [Global.owned_clankers.size() - shown_clankers], 12, Color("8ea1b8"))
		if is_instance_valid(selected_clanker):
			_add_panel_label("TUNING: %s  ·  damage %d  ·  rate %d" % [selected_clanker.display_name, selected_clanker.damage_upgrade_level, selected_clanker.fire_rate_upgrade_level], 13, Color("ffc56e"))
			_add_button("Damage + (%d)" % selected_clanker.upgrade_cost(), _upgrade_damage)
			_add_button("Fire rate + (%d)" % selected_clanker.upgrade_cost(), _upgrade_fire_rate)
		panel.modulate.a = 0.0
		create_tween().tween_property(panel, "modulate:a", 1.0, 0.16)

func _add_panel_label(text: String, font_size := 14, color := Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	panel_content.add_child(label)

func _add_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_stylebox_override("normal", _button_style(Color("26354d")))
	button.pressed.connect(action)
	panel_content.add_child(button)
	return button

func _make_clanker_offer(type_name: String) -> Button:
	var data: Dictionary = Global.CLANKER_TYPES[type_name]
	var button := Button.new()
	button.custom_minimum_size = Vector2(124, 104)
	button.add_theme_stylebox_override("normal", _button_style(Color("26354d")))
	button.pressed.connect(_buy_clanker.bind(type_name))
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)
	var preview: Control = CLANKER_PREVIEW_SCRIPT.new()
	preview.set("clanker_type", type_name)
	preview.custom_minimum_size = Vector2(120, 52)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(preview)
	var name_label := Label.new()
	name_label.text = data.label
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(name_label)
	var details := Label.new()
	details.text = "%d credits · %d HP" % [data.cost, data.health]
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.add_theme_font_size_override("font_size", 11)
	details.add_theme_color_override("font_color", Color("8ea1b8"))
	content.add_child(details)
	return button

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101827e8")
	style.border_color = Color("3bc8d9")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _buy_clanker(type_name: String) -> void:
	var data: Dictionary = Global.CLANKER_TYPES[type_name]
	if not Global.spend_credits(data.cost):
		return
	var clanker := BOT_SCENE.instantiate() as RoBot
	$characters.add_child(clanker)
	clanker.global_position = _next_defence_position()
	clanker.configure_clanker(type_name)
	Global.register_clanker(clanker)
	selected_clanker = clanker
	_refresh_ui()

func _select_clanker(clanker: RoBot) -> void:
	selected_clanker = clanker
	_refresh_ui()

func _upgrade_damage() -> void:
	if is_instance_valid(selected_clanker) and Global.spend_credits(selected_clanker.upgrade_cost()):
		selected_clanker.upgrade_damage()
	_refresh_ui()

func _upgrade_fire_rate() -> void:
	if is_instance_valid(selected_clanker) and Global.spend_credits(selected_clanker.upgrade_cost()):
		selected_clanker.upgrade_fire_rate()
	_refresh_ui()

func _start_night() -> void:
	if Global.phase != Global.RunPhase.DAY:
		return
	if Global.owned_clankers.is_empty():
		Global.log_event("Night cannot start: buy at least one Clanker first.")
		_refresh_ui()
		return
	Global.start_night()
	shop_open = false
	spawner.start_night_wave(3 + (Global.night - 1), Global.night)
	_refresh_ui()

func _on_enemy_destroyed() -> void:
	if not is_inside_tree():
		return
	Global.award_credits(Global.KILL_REWARD)
	_refresh_ui()

func _on_wave_completed() -> void:
	if not is_inside_tree():
		return
	Global.complete_night()
	_refresh_ui()

func _on_core_health_changed(health: int, _snap: int) -> void:
	if health <= 0:
		Global.end_run()
		spawner.stop_wave()
		game_over_panel.visible = true
		var label := Label.new()
		label.text = "CORE LOST\nReached night %d\n[Enter] Return to menu" % Global.night
		game_over_panel.add_child(label)
		var button := Button.new()
		button.text = "Return to menu"
		button.pressed.connect(_return_to_menu)
		game_over_panel.add_child(button)

func _return_to_menu() -> void:
	get_tree().change_scene_to_packed(MENU_SCENE)

func _next_defence_position() -> Vector2:
	var cores := get_tree().get_nodes_in_group("Core")
	if cores.is_empty():
		return player.global_position + Vector2(24, 0)
	var core := cores[0] as Node2D
	var index := Global.owned_clankers.size()
	var angle := TAU * float(index % 8) / 8.0
	var desired := core.global_position + Vector2.from_angle(angle) * 160.0
	var generator := $island.get_node_or_null("Tilemaps")
	if generator and generator.has_method("nearest_open_ground_world_position"):
		return generator.nearest_open_ground_world_position(desired, core.global_position + Vector2(96, 0), core.global_position, 64.0)
	return desired
