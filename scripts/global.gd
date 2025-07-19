extends Node

var coreIsAlive: bool = true
var islandSize: Vector2i = Vector2i(128, 128)

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
func _process(delta: float) -> void:
	if !companionsleader: setcompanionleader()
	
func setcompanionleader():
	companions = get_tree().get_nodes_in_group("companions")
	if companions.is_empty():
		return
		
	companionsleader = companions[randi_range(0, companions.size() -1)]
	for com in companions:
		com.leader = companionsleader
	print(companionsleader)
