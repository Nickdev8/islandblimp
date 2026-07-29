class_name Chicken extends CharacterBody2D

##states
#1 sitting
#2 walking
#3 bobbing
#4 walking to player
#5 walking to edge of map

@export var activeAnimator: int = 0 # randi_range(0,2)

#timers
@onready var changestate: Timer = $changestate
@onready var teleport_timer: Timer = $TeleportTimer

#tilemaps
var bot_items: TileMapLayer
var hill: TileMapLayer
var stuff_on_ground: TileMapLayer
var grassLayer: TileMapLayer
var underside: TileMapLayer
#rest
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var particleWaitTimer: Timer = $particleWaitTimer

@onready var animsprites: Array[AnimatedSprite2D] = [
	$AnimatedSprite2D,
]

var anim: String
var anim_preframe: String
var state: int
var state_preframe: int
var is_alive: bool
var is_walking: bool
var is_flipped: bool
var is_charging: bool
var started_walking: bool
var nav_velocity: Vector2
var randpos: Vector2
var leader: Node2D
var followleader: bool

const Dic: Dictionary = {
	"null" : Vector2i(-1, -1),
	
	"grass_collision_all" : Vector2i(21, 1),
	"grass_collision_navigation" : Vector2i(19, 2),
	
	"grass" : Vector2i(4, 1),
}
	
const compstats = {
	0: {"speed": 40},
}

func _ready() -> void:
	_on_changestate_timeout()
	followleader = randi_range(0,1) == 1
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	checkifstuck()
	animationsmanager()
	targetlogic()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("2"):
		killme()

func _physics_process(_delta: float) -> void:
	if navigation_agent_2d.is_target_reachable():
		var dir = to_local(navigation_agent_2d.get_next_path_position()).normalized()
		nav_velocity = dir * compstats[activeAnimator]["speed"]
		navigation_agent_2d.velocity = nav_velocity
		is_walking = !navigation_agent_2d.is_target_reached()
		is_flipped = nav_velocity.x < 0

func set_nearest_bot() -> RoBot:
	var bots: Array = get_tree().get_nodes_in_group("Bots")
	if bots.is_empty():
		return null

	var closest_distance = INF
	var closest_bot: RoBot = null

	for bot in bots:
		var distance = self.position.distance_to(bot.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_bot = bot
	
	return closest_bot

func targetlogic():
	var nearestbot: RoBot = set_nearest_bot()
	var current_target_pos: Vector2 = Vector2.ZERO
	var player: Node2D
	var core: Node2D
	var current_sprite = animsprites[activeAnimator]
	
	if get_tree().get_nodes_in_group("player").is_empty() or get_tree().get_nodes_in_group("Core").is_empty() or get_tree().get_nodes_in_group("Bots").is_empty():
		return
	
	player = get_tree().get_nodes_in_group("player")[0]
	core = get_tree().get_nodes_in_group("Core")[0]
	
	var deadbot = isthereadeadbot()
	
	if leader != self && followleader:
		if leader:
			current_target_pos = leader.global_position
			navigation_agent_2d.target_desired_distance = 24
			changestate.wait_time = 5
			if is_walking:
				anim = "walk"
			else:
				anim = leader.anim
	
	elif deadbot != null:
		current_target_pos = deadbot.global_position
		navigation_agent_2d.target_desired_distance = 16
		changestate.wait_time = 5
		if is_walking:
			anim = "walk"
		else:
			anim = "sit"
	
	##states
	#1 sitting
	#2 walking random normal grass
	#3 walking random tall grass
	#4 bobbing
	#5 walking to player
	#6 walking to bot
	elif state == 1:
		current_target_pos = self.global_position
		navigation_agent_2d.target_desired_distance = 8
		anim = "sit"
		changestate.wait_time = 10
	elif state == 2:
		current_target_pos = randpos
		navigation_agent_2d.target_desired_distance = 8
		changestate.wait_time = 30
		if is_walking:
			anim = "walk"
		else:
			anim = "sit"
	elif state == 3:
		current_target_pos = randpos
		navigation_agent_2d.target_desired_distance = 8
		changestate.wait_time = 30
		if is_walking:
			anim = "walk"
		else:
			anim = "sit"
	elif state == 4:
		current_target_pos = self.global_position
		navigation_agent_2d.target_desired_distance = 8
		changestate.wait_time = 3
		anim = "bobbing"
	elif state == 5:
		current_target_pos = player.global_position
		navigation_agent_2d.target_desired_distance = 48
		changestate.wait_time = 20
		if is_walking:
			anim = "walk"
		else:
			anim = "sit"
	elif state == 6:
		current_target_pos = player.global_position
		navigation_agent_2d.target_desired_distance = 32
		changestate.wait_time = 4
		if is_walking:
			anim = "walk"
		else:
			anim = "bobbing"
	elif state == 7:
		current_target_pos = nearestbot.global_position
		navigation_agent_2d.target_desired_distance = 32
		changestate.wait_time = 15
		if is_walking:
			anim = "walk"
		else:
			anim = "sit"
	
	if anim != anim_preframe:
		current_sprite.play(anim)
	
	if state != state_preframe:
		changestate.stop()
		changestate.start()

	
	anim_preframe = anim
	state_preframe = state
	navigation_agent_2d.target_position = current_target_pos + Vector2(0, 2)
	#if current_target_pos != Vector2.ZERO:
	#else:
	#	print("Target is null")

func isthereadeadbot() -> RoBot:
	var bots: Array = get_tree().get_nodes_in_group("Bots")
	if bots.is_empty():
		return null
		
	var botswithhealing: Array[RoBot] = []
		
	for bot in bots:
		var distance = self.position.distance_to(bot.position)
		if distance < 16 * 16:
			if bot.healing == true:
				botswithhealing.append(bot)
	
	var closest_distance = INF
	var closest_bot: RoBot = null

	for bot in botswithhealing:
		var distance = self.position.distance_to(bot.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_bot = bot
	
	return closest_bot
	


func randomposonmap(walktograss: bool) -> Vector2:
	bot_items = get_node("../../BotItems")
	hill = get_node("../../hill")
	stuff_on_ground = get_node("../../stuffOnGround")
	grassLayer = get_node("../../grass")
	
	if !grassLayer or !hill or !stuff_on_ground or !bot_items:
		print(grassLayer)
		print(hill)
		print(stuff_on_ground)
		print(bot_items)
		return Vector2.ZERO

	var returnpos: Vector2 = Vector2.ZERO
	var istherea = false
	
	while !istherea:
		var is_valid = false
		var x = randi_range(Global.islandSize.x/2 * -1, Global.islandSize.x/2)
		var y = randi_range(Global.islandSize.y/2 * -1, Global.islandSize.y/2)
		var setcell = Vector2i(x, y)
		var me_grass = grassLayer.get_cell_atlas_coords(setcell)
		var me_botitems = bot_items.get_cell_atlas_coords(setcell)
		var me_hill = hill.get_cell_atlas_coords(setcell)
		var me_stuffongorund = stuff_on_ground.get_cell_atlas_coords(setcell)
		
		if position.distance_to(Vector2(setcell.x * 16, setcell.y * 16)) < 128:
			if me_grass == Dic["grass"]:
				if me_grass != Dic["grass_collision_all"]:
					if me_grass != Dic["grass_collision_navigation"]:
						if me_hill == Dic["null"]:
							if walktograss == true:
								if me_stuffongorund == Dic["null"]:
									is_valid = true
							else:
								if me_stuffongorund != Dic["null"]:
									is_valid = true
			
		if is_valid:
			returnpos = Vector2(setcell.x * 16, setcell.y * 16)
			istherea = true
		else:
			istherea = false

	return returnpos

func animationsmanager() -> void:
	for sprite in animsprites:
		sprite.visible = false
	var current_sprite = animsprites[activeAnimator]
	current_sprite.visible = true
	current_sprite.flip_h = !is_flipped

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func _on_teleport_timer_timeout() -> void:
	if navigation_agent_2d.is_target_reachable():
		position = Vector2(navigation_agent_2d.target_position.x, navigation_agent_2d.target_position.y +3)

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

func _on_particle_wait_timer_timeout():
	queue_free()

func _on_changestate_timeout() -> void:
	state = randi_range(1, 7)
	if state == 2:
		randpos = randomposonmap(true)
	if state == 3:
		randpos = randomposonmap(false)
