class_name RoBot extends CharacterBody2D
@export var StartHealth: int
@export var SNAP_VALUE: int = 14
@export var gunnumber: int
@export var activeAnimator: int = 0 # randi_range(0,2)
@export var min_rotation_degrees: float = -45.0
@export var max_rotation_degrees: float = 45.0

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var animsprites: Array[AnimatedSprite2D] = [
	$SmallAnimatedSprite2D, 
	$BigAnimatedSprite2D, 
	$BoxAnimatedSprite2D
]
@onready var teleport_timer: Timer = $TeleportTimer
@onready var walkanimation: Timer = $walkanimation
@onready var healtimer: Timer = $Healtimer

@onready var energy_bar: Node2D = $energyBar
@onready var guns: AnimatedSprite2D = $guns

signal health_changed(send_Health: int, send_SNAP_VALUE: int)
signal health_start(send_Start_Health: int, send_SNAP_VALUE: int)

const botstats = {
	0: {"speed": 50, "first": Vector2(2, -7), "second": Vector2(2, -6)},
	1: {"speed": 30, "first": Vector2(3, -7), "second": Vector2(3, -6)},
	2: {"speed": 40, "first": Vector2(3, -8), "second": Vector2(3, -7)},
}

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

var shootingtarget: Node2D = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("1"):
		takedamage(1)

func _ready() -> void:
	Health = StartHealth
	is_alive = Health > 0
	target = null
	targetlogic()
	emit_signal("health_start", StartHealth, SNAP_VALUE)
	healing = false

func _physics_process(_delta: float) -> void:
	if target:
		var dir = to_local(navigation_agent_2d.get_next_path_position()).normalized()
		nav_velocity = dir * botstats[activeAnimator]["speed"]
		navigation_agent_2d.velocity = nav_velocity
		is_walking_preframe = is_walking
		is_walking = !navigation_agent_2d.is_target_reached()
		
		#if is_stooting:
			#if shootingtarget:
				# Flip the node if the target is to the left
				#is_flipped = shootingtarget.position.x < global_position.x
			#else:
				#is_flipped = nav_velocity.x < 0
		#else:
		
		is_flipped = nav_velocity.x < 0

func _process(_delta: float) -> void:
	animationsmanager()
	gunmanager()
	check_health()
	targetlogic()
	#shootintargetlogic()

func animationsmanager() -> void:
	for sprite in animsprites:
		sprite.visible = false
	var current_sprite = animsprites[activeAnimator]
	current_sprite.visible = true
	current_sprite.flip_h = is_flipped
	
	if is_walking == is_walking_preframe:
		if walkanimation.time_left <= 0:
			walkanimation.start()
	
	if is_walking_preframe != is_walking:
		walkanimation.stop()

func gunmanager() -> void:
	guns.flip_h = is_flipped
	var frame = animsprites[activeAnimator].frame
	if frame in [0, 1, 2]:
		guns.set_offset(Vector2(0, botstats[activeAnimator]["first"].y))
		if is_flipped: guns.position.x = botstats[activeAnimator]["first"].x * -1
		else: guns.position.x = botstats[activeAnimator]["first"].x * 1
	else:
		guns.set_offset(Vector2(0, botstats[activeAnimator]["second"].y))
		if is_flipped: guns.position.x = botstats[activeAnimator]["second"].x * -1
		else: guns.position.x = botstats[activeAnimator]["second"].x * 1
	guns.visible = not is_walking
	guns.set_frame(gunnumber)

func check_health() -> void:
	var was_alive = is_alive
	if target:
		if target.is_in_group("Charger"):
			if Health == StartHealth:
				healing = false
				healtimer.stop()
			is_alive = Health == StartHealth
			is_stooting = false
		else:
			is_alive = Health > 0
	else:
		is_alive = Health > 0
	if is_alive != was_alive:
		emit_signal("health_changed")
		#targetlogic()

func _on_walkanimation_timeout():
	var current_sprite = animsprites[activeAnimator]
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
	if target:
		global_position = target.global_position + Vector2(0, 3)

func targetlogic() -> void:
	var group_name
	
	if !is_alive:
		group_name = "Charger"
	else:
		group_name = "Seat" 
		healing == false

	var i: int = 0
	var new_target: Node
	
	new_target = nearest_thing(get_tree().get_nodes_in_group(group_name), i)
	
	while is_occupied_by_another_bot(new_target) == true:
		i += 1
		new_target = nearest_thing(get_tree().get_nodes_in_group(group_name), i)
		if i > get_tree().get_nodes_in_group(group_name).size() +1:
			break
	
	if new_target:
		target = new_target
		navigation_agent_2d.target_position = Vector2(target.global_position.x, target.global_position.y + 2)

func shootintargetlogic() -> void:
	var player = get_tree().get_nodes_in_group("player")[0]
	if player:
		shootingtarget = player
		
	look_at_with_limits(player.global_position)
	
func look_at_with_limits(target_position: Vector2) -> void:
	var direction = (target_position - global_position).normalized()
	var target_angle = direction.angle()

	# Adjust the angle for flipping
	if is_flipped:
		target_angle = 180 - target_angle

	# Convert min and max rotations to radians
	var min_rotation = deg_to_rad(min_rotation_degrees)
	var max_rotation = deg_to_rad(max_rotation_degrees)

	# Calculate clamped rotation
	var clamped_angle = clamp(target_angle, min_rotation, max_rotation)

	# Apply the clamped rotation
	guns.rotation = clamped_angle

func nearest_thing(things: Array, i) -> Node:
	if things.is_empty():
		return null

	var distances = []

	for thing in things:
		var distance = thing.global_position.distance_to(global_position)
		distances.append({"node": thing, "distance": distance})

	distances.sort_custom(_sort_by_distance)

	var sorted_things: Array[Node] = []
	for item in distances:
		sorted_things.append(item["node"])

	return sorted_things[i]

func _sort_by_distance(a: Dictionary, b: Dictionary) -> bool:
	return a["distance"] < b["distance"]

func is_occupied_by_another_bot(thing: Node) -> bool:
	for bot in get_tree().get_nodes_in_group("Bots"):
		if bot != self and bot.target == thing:
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
		if teleport_timer.is_stopped():
			teleport_timer.start()
	else:
		teleport_timer.stop()

func _on_navigation_agent_2d_target_reached() -> void:
	global_position = target.global_position + Vector2(0, 3)
	if target.is_in_group("Charger"):
		if !is_alive:
			if healing == false:
				healtimer.stop()
				healtimer.wait_time = target.healingspeed
				healtimer.stop()
				healtimer.start()
				healing = true
				print(target.healingspeed)
	if target.is_in_group("Seat"):
		if is_alive:
			is_stooting = true
	
func heal(healAmount: int) -> void:
	Health += healAmount
	if Health >= StartHealth:
		Health = StartHealth
	emit_signal("health_changed", Health, SNAP_VALUE)

func _on_healtimer_timeout() -> void:
	if healing == true:
		if target.is_in_group("Charger"):
			heal(target.healingamount)
