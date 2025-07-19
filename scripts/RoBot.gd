class_name RoBot
extends CharacterBody2D

@export var StartHealth: int
@export var SNAP_VALUE: int = 14
@export var gunnumber: int
@export var activeAnimator: int = 0
@export var min_rotation_degrees: float = -45.0
@export var max_rotation_degrees: float = 45.0

# instead of listing each sprite here, point at the container:
@onready var bot_sprites_container: Node = get_node_or_null("BotSprites")
@onready var animsprites: Array[AnimatedSprite2D] = []

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var teleport_timer: Timer = $TeleportTimer
@onready var walkanimation: Timer = $walkanimation
@onready var healtimer: Timer = $Healtimer
@onready var energy_bar: Control = $energyBar
@onready var guns: AnimatedSprite2D = $guns

signal health_changed(send_Health: int, send_SNAP_VALUE: int)
signal health_start(send_Start_Health: int, send_SNAP_VALUE: int)

const botstats = {
	0: {"speed": 30},
	1: {"speed": 50},
	2: {"speed": 40},
	3: {"speed": 50},
	4: {"speed": 40},
	5: {"speed": 30},
	6: {"speed": 30},
}

var orininalgunpos
var orininalgunoff

var is_alive: bool
var is_walking: bool
var is_flipped: bool
var is_charging: bool
var is_stooting: bool
var started_walking: bool
var nav_velocity: Vector2
var Health: int
var target: Node2D
var is_walking_preframe: bool
var healing: bool
var bot_id: int = -1  # Unique identifier for each bot

var shootingtarget: Node2D = null

# Static variable to track all bot instances
static var all_bots: Array = []
static var next_bot_id: int = 0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("1"):
		takedamage(1)

func _ready() -> void:
	# Assign unique ID to this bot
	bot_id = RoBot.next_bot_id
	RoBot.next_bot_id += 1
	RoBot.all_bots.append(self)
	orininalgunpos = guns.position
	orininalgunoff = guns.offset
	
	if bot_sprites_container == null:
		push_error("RoBot: could not find a child node called 'BotSprites' — make sure you added it under this scene!")
	else:
		# collect all AnimatedSprite2D under that container
		for child in bot_sprites_container.get_children():
			if child is AnimatedSprite2D:
				animsprites.append(child)
	
	Health = StartHealth
	is_alive = Health > 0
	target = null
	targetlogic()
	emit_signal("health_start", StartHealth, SNAP_VALUE)
	healing = false

func _exit_tree() -> void:
	# Remove this bot from the static array when destroyed
	RoBot.all_bots.erase(self)

func _physics_process(_delta: float) -> void:
	if target and is_instance_valid(target):
		var next_path_pos = navigation_agent_2d.get_next_path_position()
		if next_path_pos:
			var dir = to_local(next_path_pos).normalized()
			nav_velocity = dir * botstats[activeAnimator]["speed"]
			navigation_agent_2d.velocity = nav_velocity
			is_walking_preframe = is_walking
			is_walking = !navigation_agent_2d.is_target_reached()
			if is_walking:
				is_flipped = nav_velocity.x < 0

func _process(_delta: float) -> void:
	animationsmanager()
	gunmanager()
	check_health()
	targetlogic()
	shootintargetlogic()

func animationsmanager() -> void:
	# First hide all sprites if they exist
	for sprite in animsprites:
		if is_instance_valid(sprite):
			sprite.visible = false
	
	# Show only the active sprite if it exists
	if activeAnimator >= 0 and activeAnimator < animsprites.size():
		var current_sprite = animsprites[activeAnimator]
		if is_instance_valid(current_sprite):
			current_sprite.visible = true
			current_sprite.flip_h = is_flipped
	
	# Handle walk animation timer
	if is_instance_valid(walkanimation):
		if is_walking == is_walking_preframe:
			if walkanimation.time_left <= 0:
				walkanimation.start()
				
		if is_walking_preframe != is_walking:
			walkanimation.stop()

func gunmanager() -> void:
	if not is_instance_valid(guns):
		return
		
	guns.flip_h = is_flipped
	
	if activeAnimator >= 0 and activeAnimator < animsprites.size():
		var current_sprite = animsprites[activeAnimator]
		if is_instance_valid(current_sprite):
			var frame = current_sprite.frame
			
			orininalgunpos
			orininalgunoff
			
			if frame in [0, 1, 2]:
				guns.position.y = orininalgunpos.y
			else:
				guns.position.y = orininalgunpos.y-1
			if is_flipped:
				guns.position.x = orininalgunpos.x * -1
				guns.offset.x = orininalgunoff.x * -1
			else:
				guns.position.x = orininalgunpos.x * 1
				guns.offset.x = orininalgunoff.x * 1
			
			guns.visible = not is_walking
			guns.set_frame(gunnumber)

func check_health() -> void:
	var was_alive = is_alive
	if is_instance_valid(target):
		if target.is_in_group("Charger"):
			if Health == StartHealth:
				healing = false
				if is_instance_valid(healtimer):
					healtimer.stop()
			is_alive = Health == StartHealth
			is_stooting = false
		else:
			is_alive = Health > 0
	else:
		is_alive = Health > 0
	if is_alive != was_alive:
		emit_signal("health_changed")

static func get_all_bots() -> Array:
	return all_bots

func _on_walkanimation_timeout():
	if activeAnimator >= 0 and activeAnimator < animsprites.size():
		var current_sprite = animsprites[activeAnimator]
		if is_instance_valid(current_sprite):
			if is_walking:
				if started_walking and not current_sprite.is_playing():
					current_sprite.play("walk")
				elif not started_walking:
					current_sprite.play("start_walk")
					started_walking = true
			else:
				current_sprite.play("idle")
				started_walking = false

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()
	checkifstuck()

func _on_teleport_timer_timeout() -> void:
	if is_instance_valid(target):
		global_position = target.global_position + Vector2(0, 3)

func targetlogic() -> void:
	var group_name
	
	if !is_alive:
		group_name = "Charger"
	else:
		group_name = "Seat"
		healing = false

	var potential_targets = get_tree().get_nodes_in_group(group_name)
	if potential_targets.is_empty():
		return

	var i: int = 0
	var new_target: Node = nearest_thing(potential_targets, i)
	
	while is_occupied_by_another_bot(new_target):
		i += 1
		new_target = nearest_thing(potential_targets, i)
		if i > potential_targets.size() + 1:
			break
	
	if is_instance_valid(new_target):
		target = new_target
		navigation_agent_2d.target_position = Vector2(target.global_position.x, target.global_position.y + 2)

func shootintargetlogic() -> void:
	if target != null:
		if is_instance_valid(target):
			shootingtarget = target
			look_at_with_limits(target.global_position)




func look_at_with_limits(target_position: Vector2) -> void:
	if not is_instance_valid(guns):
		return

	# Vector from gun to target
	var direction = (target_position - guns.global_position).normalized()
	var angle = direction.angle()

	# Determine if target is to the left or right
	is_flipped = (target_position.x < global_position.x)
	guns.flip_h = is_flipped

	# If flipped, mirror the angle horizontally
	if is_flipped:
		angle = PI - angle
		# You might also need to negate for correct sprite pivot
		angle = -angle

	# Clamp the angle to allowed gun rotation limits
	var min_angle = deg_to_rad(min_rotation_degrees)
	var max_angle = deg_to_rad(max_rotation_degrees)

	# Normalize angle to ensure clamping behaves correctly
	angle = wrapf(angle, -PI, PI)
	var clamped_angle = clamp(angle, min_angle, max_angle)

	guns.rotation = clamped_angle





func nearest_thing(things: Array, i) -> Node:
	if things.is_empty() or i >= things.size():
		return null

	var distances = []

	for thing in things:
		if is_instance_valid(thing):
			var distance = thing.global_position.distance_to(global_position)
			distances.append({"node": thing, "distance": distance})

	if distances.is_empty():
		return null

	distances.sort_custom(_sort_by_distance)

	var sorted_things: Array[Node] = []
	for item in distances:
		sorted_things.append(item["node"])

	if i >= sorted_things.size():
		return null

	return sorted_things[i]

func _sort_by_distance(a: Dictionary, b: Dictionary) -> bool:
	return a["distance"] < b["distance"]

func is_occupied_by_another_bot(thing: Node) -> bool:
	if not is_instance_valid(thing):
		return false
		
	for bot in RoBot.all_bots:
		if is_instance_valid(bot) and bot != self and bot.target == thing:
			return true
	return false

func takedamage(DamageAmount: int) -> void:
	Health -= DamageAmount
	if Health <= 0:
		Health = 0
	emit_signal("health_changed", Health, SNAP_VALUE)

func _on_nav_timer_timeout() -> void:
	targetlogic()

func checkifstuck():
	if (Vector2(snapped(velocity.x, 10), snapped(velocity.y, 10)) == Vector2.ZERO and is_walking):
		if is_instance_valid(teleport_timer) and teleport_timer.is_stopped():
			teleport_timer.start()
	elif is_instance_valid(teleport_timer):
		teleport_timer.stop()

func _on_navigation_agent_2d_target_reached() -> void:
	if is_instance_valid(target):
		global_position = target.global_position + Vector2(0, 3)
		if target.is_in_group("Charger"):
			if !is_alive:
				if healing == false and is_instance_valid(healtimer):
					healtimer.stop()
					healtimer.wait_time = target.healingspeed
					healtimer.stop()
					healtimer.start()
					healing = true
		elif target.is_in_group("Seat"):
			if is_alive:
				is_stooting = true
	
func heal(healAmount: int) -> void:
	Health += healAmount
	if Health >= StartHealth:
		Health = StartHealth
	emit_signal("health_changed", Health, SNAP_VALUE)

func _on_healtimer_timeout() -> void:
	if healing == true and is_instance_valid(target) and target.is_in_group("Charger"):
		heal(target.healingamount)
