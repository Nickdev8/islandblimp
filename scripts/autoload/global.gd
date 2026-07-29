extends Node

var coreIsAlive: bool = true
var islandSize: Vector2i = Vector2i(128, 128)
var difficulty: int = 0
enum RunPhase { DAY, NIGHT, GAME_OVER }

signal credits_changed(value: int)
signal phase_changed(value: RunPhase)
signal night_changed(value: int)
signal clanker_roster_changed
signal event_logged(message: String)

const STARTING_CREDITS := 80
const KILL_REWARD := 8
const CLANKER_TYPES := {
	"round": {"label": "Round Clanker", "cost": 60, "health": 10, "animator": 2, "gun": 0},
	"block": {"label": "Block Clanker", "cost": 100, "health": 14, "animator": 0, "gun": 1},
	"chonker": {"label": "Chonker Clanker", "cost": 150, "health": 18, "animator": 1, "gun": 2},
}

var credits := STARTING_CREDITS
var night := 1
var phase: RunPhase = RunPhase.DAY
var owned_clankers: Array[RoBot] = []
const TEAM_ASSIGNMENT_REFRESH_MSEC := 250
var _team_assignments: Dictionary = {}
var _team_assignment_refresh_msec := 0

var gunDictionary: Dictionary = {
##"index" 	= [lvl, shootingspeed, type of projectile]
	"1" 	= [3, 5, "4ball"],
	"2" 	= [2, 8, "2ball"],
	"3" 	= [1, 8, "2ball"],
	"4" 	= [3, 8, "4ball"],
	"5" 	= [3, 6, "4ball"],
	"6" 	= [2, 6, "6ball"],
	"7" 	= [2, 10, "2ball"],
	"8" 	= [4, 10, "6ball"],
}

var companions
var companionsleader: Node2D

func reset_run() -> void:
	credits = STARTING_CREDITS
	night = 1
	phase = RunPhase.DAY
	coreIsAlive = true
	owned_clankers.clear()
	_team_assignments.clear()
	_team_assignment_refresh_msec = 0
	credits_changed.emit(credits)
	night_changed.emit(night)
	phase_changed.emit(phase)
	clanker_roster_changed.emit()
	log_event("New run started with %d credits." % credits)

func log_event(message: String) -> void:
	var entry := "[Blipstorm] %s" % message
	print(entry)
	event_logged.emit(entry)

func can_afford(amount: int) -> bool:
	return credits >= amount

func spend_credits(amount: int) -> bool:
	if amount < 0 or not can_afford(amount):
		return false
	credits -= amount
	credits_changed.emit(credits)
	log_event("Spent %d credits. Balance: %d." % [amount, credits])
	return true

func award_credits(amount: int) -> void:
	credits += max(amount, 0)
	credits_changed.emit(credits)
	log_event("Earned %d credits. Balance: %d." % [amount, credits])

func register_clanker(clanker: RoBot) -> void:
	if not owned_clankers.has(clanker):
		owned_clankers.append(clanker)
		_team_assignment_refresh_msec = 0
		clanker_roster_changed.emit()
		log_event("%s joined the island defence." % clanker.display_name)

func unregister_clanker(clanker: RoBot) -> void:
	owned_clankers.erase(clanker)
	_team_assignment_refresh_msec = 0
	clanker_roster_changed.emit()

func get_assigned_threat(clanker: RoBot, core: Node2D) -> Node2D:
	if Time.get_ticks_msec() - _team_assignment_refresh_msec >= TEAM_ASSIGNMENT_REFRESH_MSEC:
		_rebuild_team_assignments(core)
	var assigned = _team_assignments.get(clanker.get_instance_id())
	return assigned as Node2D if is_instance_valid(assigned) else null

func _rebuild_team_assignments(core: Node2D) -> void:
	_team_assignment_refresh_msec = Time.get_ticks_msec()
	_team_assignments.clear()
	if not is_instance_valid(core):
		return
	var remaining_bots: Array[RoBot] = []
	for clanker in owned_clankers:
		if is_instance_valid(clanker) and clanker.is_alive:
			remaining_bots.append(clanker)
	var remaining_enemies: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group("Enemys"):
		if is_instance_valid(enemy) and enemy is Node2D:
			remaining_enemies.append(enemy as Node2D)
	var all_enemies: Array[Node2D] = remaining_enemies.duplicate()
	while not remaining_bots.is_empty() and not remaining_enemies.is_empty():
		var best_bot_index := -1
		var best_enemy_index := -1
		var best_score := INF
		for bot_index in range(remaining_bots.size()):
			var candidate_bot := remaining_bots[bot_index]
			for enemy_index in range(remaining_enemies.size()):
				var candidate_enemy := remaining_enemies[enemy_index]
				var score := candidate_bot.global_position.distance_to(candidate_enemy.global_position) + candidate_enemy.global_position.distance_to(core.global_position) * 0.35
				if score < best_score:
					best_score = score
					best_bot_index = bot_index
					best_enemy_index = enemy_index
		var assigned_bot := remaining_bots[best_bot_index]
		var assigned_enemy := remaining_enemies[best_enemy_index]
		_team_assignments[assigned_bot.get_instance_id()] = assigned_enemy
		remaining_bots.remove_at(best_bot_index)
		remaining_enemies.remove_at(best_enemy_index)
	# More defenders than enemies reinforce the closest assigned fight.
	for clanker in remaining_bots:
		var closest_enemy: Node2D
		var closest_distance := INF
		for enemy in all_enemies:
			var distance := clanker.global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_enemy = enemy
		if is_instance_valid(closest_enemy):
			_team_assignments[clanker.get_instance_id()] = closest_enemy

func start_night() -> void:
	phase = RunPhase.NIGHT
	phase_changed.emit(phase)
	log_event("Night %d started." % night)

func complete_night() -> void:
	award_credits(40 * night)
	night += 1
	phase = RunPhase.DAY
	night_changed.emit(night)
	phase_changed.emit(phase)
	for clanker in owned_clankers:
		if is_instance_valid(clanker):
			clanker.restore_full_health()
	log_event("Night cleared. Day %d begins." % night)

func end_run() -> void:
	if phase == RunPhase.GAME_OVER:
		return
	phase = RunPhase.GAME_OVER
	phase_changed.emit(phase)
	log_event("YOUR DEAD — the island core was destroyed.")

func _process(_delta: float) -> void:
	if !companionsleader: setcompanionleader()
	
func setcompanionleader():
	companions = get_tree().get_nodes_in_group("companions")
	if companions.is_empty():
		return
		
	companionsleader = companions[randi_range(0, companions.size() -1)]
	for com in companions:
		if com is Chicken:
			com.leader = companionsleader
	log_event("Chicken flock leader assigned.")
