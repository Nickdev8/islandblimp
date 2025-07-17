class_name Enemy extends CharacterBody2D

@export var StartHealth: int
@export var SNAP_VALUE: int = 14
@export var activeAnimator: int = 0 # randi_range(0,2)

@onready var animsprites: Array[AnimatedSprite2D] = [
	$AnimatedSprite2D,
]
@onready var energy_bar: Control = $energyBar

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var teleport_timer: Timer = $TeleportTimer
@onready var walkanimation: Timer = $walkanimation
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var particleWaitTimer: Timer = $particleWaitTimer

signal health_changed(send_Health: int, send_SNAP_VALUE: int)
signal health_start(send_Start_Health: int, send_SNAP_VALUE: int)

const birbstats = {
	0: {"speed": 50},
	1: {"speed": 40},
}

var is_alive: bool
var is_walking: bool
var is_walking_preframe: bool
var is_flipped: bool
var is_charging: bool
var started_walking: bool
var nav_velocity: Vector2
var Health: int
var target: Node2D

func _ready() -> void:
	Health = StartHealth
	is_alive = Health > 0
	target = null
	targetlogic()
	emit_signal("health_start", StartHealth, SNAP_VALUE)

func _process(_delta: float) -> void:	
	checkifstuck()
	animationsmanager()
	check_health()
	targetlogic()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("1"):
		takedamage(1)

func _physics_process(_delta: float) -> void:
	if target:
		scale = Vector2(1,1)
		var dir = to_local(navigation_agent_2d.get_next_path_position()).normalized()
		nav_velocity = dir * birbstats[activeAnimator]["speed"]
		navigation_agent_2d.velocity = nav_velocity
		is_walking_preframe = is_walking
		is_walking = !navigation_agent_2d.is_target_reached()
		is_flipped = nav_velocity.x < 0


func set_nearest_bot() -> RoBot:
	if get_tree().get_nodes_in_group("Bots").is_empty():
		return null

	var closest_distance = INF
	var closest_bot: RoBot = null

	for bot in get_tree().get_nodes_in_group("Bots"):
		var distance = self.position.distance_to(bot.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_bot = bot
	
	return closest_bot

func targetlogic():
	var nearestbot: RoBot = set_nearest_bot()
	var current_target: Node2D
	var player: Node
	var core: Node
	
	if get_tree().get_nodes_in_group("player").is_empty() or get_tree().get_nodes_in_group("Core").is_empty() or get_tree().get_nodes_in_group("Bots").is_empty():
		return
	
	player = get_tree().get_nodes_in_group("player")[0]
	core = get_tree().get_nodes_in_group("Core")[0]

	var dist_to_nearbot = global_position.distance_to(nearestbot.global_position)
	var dist_to_player = global_position.distance_to(player.global_position) - 8
	var dist_to_core = global_position.distance_to(core.global_position) - 16

	# Determine the nearest player
	var min_distance = min(dist_to_nearbot, dist_to_player, dist_to_core)

	if min_distance == dist_to_player:
		current_target = player
	elif min_distance == dist_to_core:
		current_target = core
	elif min_distance == dist_to_nearbot:
		current_target = nearestbot
	else: 
		return
	
	
	target = current_target
	navigation_agent_2d.target_position = Vector2(target.global_position.x, target.global_position.y + 2)


func animationsmanager() -> void:
	for sprite in animsprites:
		sprite.visible = false
	var current_sprite = animsprites[activeAnimator]
	current_sprite.visible = true
	current_sprite.flip_h = is_flipped
	
	if is_walking == is_walking_preframe:
		if walkanimation.is_stopped() == false:
			walkanimation.start()
	
	if is_walking_preframe != is_walking:
		walkanimation.stop()

func check_health() -> void:
	var was_alive = is_alive
	is_alive = Health > 0
	if is_alive != was_alive:
		emit_signal("health_changed")
	if is_alive == false:
		killme()
		
func _on_walkanimation_timeout():
	var current_sprite = animsprites[activeAnimator]
	if is_walking:
		current_sprite.play("walk")
	else:
		current_sprite.play("idle")

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func _on_teleport_timer_timeout() -> void:
	if target:
		position = Vector2(target.position.x, target.position.y +3)

func takedamage(DamageAmount: int) -> void:
	Health -= DamageAmount
	if Health <= 0:
		Health = 0
	emit_signal("health_changed", Health, SNAP_VALUE)

func _on_nav_timer_timeout() -> void:
	targetlogic()

func checkifstuck():
	if (Vector2(snapped(velocity.x, 1), snapped(velocity.y, 1)) == Vector2.ZERO and is_walking):
		if teleport_timer.is_stopped():
			teleport_timer.start()
	else:
		teleport_timer.stop()

func killme():
	if particleWaitTimer.is_stopped() == true:
		particleWaitTimer.start()
	gpu_particles_2d.emitting = true
	if particleWaitTimer.time_left < 0.5:
		for sprite in animsprites:
			sprite.visible = false
		energy_bar.visible = false

func _on_particle_wait_timer_timeout():
	queue_free()
