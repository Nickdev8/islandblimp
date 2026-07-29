class_name RoBot
extends CharacterBody2D

@export var StartHealth: int
@export var SNAP_VALUE: int = 14
@export var gunnumber: int
@export var activeAnimator: int = 0
@export var see_distance: float = 96.0
@export var min_rotation_degrees: float = -45.0
@export var max_rotation_degrees: float = 45.0
@export var clanker_type := "block"

# instead of listing each sprite here, point at the container:
@onready var bot_sprites_container: Node = get_node_or_null("BotSprites")
@onready var animsprites: Array[AnimatedSprite2D] = []

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var teleport_timer: Timer = $TeleportTimer
@onready var walkanimation: Timer = $walkanimation
@onready var healtimer: Timer = $Healtimer
@onready var energy_bar: Control = $energyBar
@onready var guns: AnimatedSprite2D = $guns
@onready var shooter: ShootScript = $shooter

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
var damage_upgrade_level := 0
var fire_rate_upgrade_level := 0
var display_name := "Block Clanker"
var body_color := Color.WHITE
var patrol_position := Vector2.ZERO
var has_patrol_position := false
var bot_id: int = -1  # Unique identifier for each bot
const DESTINATION_FAILURE_LOG_DELAY_MSEC := 5000
var _blocked_destination := Vector2.INF
var _blocked_since_msec := -1

var shootingtarget: Node2D = null

# Static variable to track all bot instances
static var all_bots: Array = []
static var next_bot_id: int = 0

func _ready() -> void:
	shooter.see_distance = see_distance
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
	_apply_clanker_visuals()

func _exit_tree() -> void:
	# Remove this bot from the static array when destroyed
	RoBot.all_bots.erase(self)

func _physics_process(_delta: float) -> void:
	if (target and is_instance_valid(target)) or has_patrol_position:
		if not navigation_agent_2d.is_target_reachable():
			velocity = Vector2.ZERO
			is_walking = false
			_note_destination_blocked("navigation has no route")
			return
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
				guns.offset.y = orininalgunoff.y
			else:
				guns.offset.y = orininalgunoff.y-1
			
			if is_flipped:
				guns.position.x = orininalgunpos.x * -1
				guns.offset.x = orininalgunoff.x * -1
			else:
				guns.position.x = orininalgunpos.x * 1
				guns.offset.x = orininalgunoff.x * 1
			
			guns.visible = not is_walking and can_shoot()
			guns.set_frame(gunnumber)

func check_health() -> void:
	var was_alive = is_alive
	is_alive = Health > 0
	is_stooting = is_alive
	if is_alive != was_alive:
		emit_signal("health_changed", Health, SNAP_VALUE)

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
		if target.global_position.distance_to(global_position) < see_distance:
			global_position = target.global_position + Vector2(0, 3)

func targetlogic() -> void:
	if !is_alive:
		target = null
		has_patrol_position = false
		velocity = Vector2.ZERO
		is_walking = false
		return

	healing = false
	target = null
	var cores := get_tree().get_nodes_in_group("Core")
	if cores.is_empty():
		return
	var core := cores[0] as Node2D
	# Build a shared defence assignment. Each active Clanker is given a different
	# enemy when possible, while still favouring threats that are near the core.
	var threat: Node2D = _assigned_threat(core)
	if is_instance_valid(threat):
		var direction: Vector2 = (threat.global_position - core.global_position).normalized()
		var threat_distance: float = threat.global_position.distance_to(core.global_position)
		var intercept_distance: float = clamp(threat_distance - 40.0, 80.0, 224.0)
		patrol_position = core.global_position + direction * intercept_distance
	else:
		var guard_angle := TAU * float(bot_id % 8) / 8.0
		patrol_position = core.global_position + Vector2.from_angle(guard_angle) * 160.0
	has_patrol_position = true
	_set_safe_navigation_target(patrol_position, core.global_position, 64.0)

func _set_safe_navigation_target(desired: Vector2, avoid_position: Vector2, avoid_radius: float) -> void:
	var generator := get_tree().root.find_child("Tilemaps", true, false)
	var safe_target := desired
	if generator and generator.has_method("nearest_open_ground_world_position"):
		safe_target = generator.nearest_open_ground_world_position(desired, global_position, avoid_position, avoid_radius)
	if safe_target.distance_to(navigation_agent_2d.target_position) > 4.0:
		_clear_destination_block()
	navigation_agent_2d.target_position = safe_target

func _assigned_threat(core: Node2D) -> Node2D:
	return Global.get_assigned_threat(self, core)

func get_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("Enemys")
	if enemies.is_empty():
		return null

	var nearest = null
	var nearest_dist = INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest

func shootintargetlogic() -> void:
	if not can_shoot():
		return
	var nearest_enemy = get_nearest_enemy()
	if is_instance_valid(nearest_enemy):
		if nearest_enemy.global_position.distance_to(global_position) < see_distance:
			look_at_with_limits(nearest_enemy.global_position)
			shooter.try_shoot_at(nearest_enemy)
		else:
			var players = get_tree().get_nodes_in_group("player")
			if not players.is_empty():
				var player = players[0]
				if is_instance_valid(player):
					shootingtarget = player
					look_at_with_limits(player.global_position)
	


func look_at_with_limits(target_position: Vector2) -> void:
	if not is_instance_valid(guns):
		return

	var direction = (target_position - guns.global_position).normalized()
	var angle = direction.angle()

	is_flipped = (target_position.x < global_position.x)
	guns.flip_h = is_flipped

	if is_flipped:
		angle = PI - angle
		angle = -angle

	var min_angle = deg_to_rad(min_rotation_degrees)
	var max_angle = deg_to_rad(max_rotation_degrees)

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
	_validate_island_position()
	targetlogic()

func _validate_island_position() -> void:
	var generator := get_tree().root.find_child("Tilemaps", true, false)
	if not generator or not generator.has_method("is_world_position_on_island"):
		return
	if generator.is_world_position_on_island(global_position):
		return
	var core_nodes := get_tree().get_nodes_in_group("Core")
	var core: Node2D = core_nodes[0] as Node2D if not core_nodes.is_empty() else null
	var desired_respawn := core.global_position + Vector2.from_angle(TAU * float(bot_id % 8) / 8.0) * 112.0 if is_instance_valid(core) else Vector2.ZERO
	var respawn_position: Vector2 = generator.nearest_open_ground_world_position(desired_respawn, Vector2.ZERO, core.global_position if is_instance_valid(core) else Vector2.ZERO, 64.0)
	var target_label: String = target.name if is_instance_valid(target) else "guard patrol"
	Global.log_event("%s left the island and was recovered. why=no walkable ground at %s; how=velocity %s, target %s, nav destination %s; respawned at %s." % [display_name, global_position, velocity, target_label, navigation_agent_2d.target_position, respawn_position])
	global_position = respawn_position
	velocity = Vector2.ZERO
	_clear_destination_block()
	targetlogic()

func checkifstuck():
	if (Vector2(snapped(velocity.x, 10), snapped(velocity.y, 10)) == Vector2.ZERO and is_walking):
		_note_destination_blocked("movement remained blocked")
		if is_instance_valid(teleport_timer) and teleport_timer.is_stopped():
			teleport_timer.start()
	else:
		_clear_destination_block()
		if is_instance_valid(teleport_timer):
			teleport_timer.stop()

func _note_destination_blocked(reason: String) -> void:
	var destination := navigation_agent_2d.target_position
	if destination.distance_to(_blocked_destination) > 4.0:
		_blocked_destination = destination
		_blocked_since_msec = Time.get_ticks_msec()
		return
	if _blocked_since_msec < 0 or Time.get_ticks_msec() - _blocked_since_msec < DESTINATION_FAILURE_LOG_DELAY_MSEC:
		return
	var terrain := "Tile data unavailable"
	var generator := get_tree().root.find_child("Tilemaps", true, false)
	if generator and generator.has_method("describe_tiles_around_world_position"):
		terrain = generator.describe_tiles_around_world_position(destination)
	Global.log_event("%s cannot reach destination after 5 seconds (%s). bot=%s destination=%s; 3x3 destination tiles: %s" % [display_name, reason, global_position, destination, terrain])
	# Mark this destination as reported. A new target or successful movement
	# resets the watch, so the terminal receives one actionable report per issue.
	_blocked_since_msec = -1

func _clear_destination_block() -> void:
	_blocked_destination = Vector2.INF
	_blocked_since_msec = -1

func _on_navigation_agent_2d_target_reached() -> void:
	if is_instance_valid(target):
		global_position = target.global_position + Vector2(0, 3)
		if target.is_in_group("Seat"):
			if is_alive:
				is_stooting = true
	
func configure_clanker(type_name: String) -> void:
	if not Global.CLANKER_TYPES.has(type_name):
		return
	clanker_type = type_name
	var data: Dictionary = Global.CLANKER_TYPES[type_name]
	display_name = data.label
	StartHealth = data.health
	Health = StartHealth
	activeAnimator = data.animator
	gunnumber = data.gun
	see_distance = 96.0
	shooter.see_distance = see_distance
	# Every Clanker receives a clearly distinct, high-energy paint colour.
	body_color = Color.from_hsv(randf(), randf_range(0.8, 1.0), randf_range(0.9, 1.0))
	if is_inside_tree():
		_apply_clanker_visuals()
		emit_signal("health_start", StartHealth, SNAP_VALUE)

func _apply_clanker_visuals() -> void:
	for sprite in animsprites:
		if is_instance_valid(sprite):
			sprite.modulate = body_color

func can_shoot() -> bool:
	return is_alive and Global.phase == Global.RunPhase.NIGHT

func consume_shot_energy() -> void:
	pass

func restore_full_health() -> void:
	Health = StartHealth
	is_alive = true
	healing = false
	emit_signal("health_changed", Health, SNAP_VALUE)
	targetlogic()

func upgrade_cost() -> int:
	return 40 * (max(damage_upgrade_level, fire_rate_upgrade_level) + 1)

func upgrade_damage() -> void:
	damage_upgrade_level += 1
	shooter.projectile_damage += 1

func upgrade_fire_rate() -> void:
	fire_rate_upgrade_level += 1
	shooter.set_shoot_interval(max(shooter.shoot_interval * 0.9, 0.6))
