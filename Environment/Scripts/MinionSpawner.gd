extends MultiplayerSpawner

const MINION_SCENE = preload("res://Characters/Minion.tscn")
var max_ids:Dictionary

func get_minion(team:int):
	if not max_ids.has(team):
		max_ids[team] = 0
	var id:int = max_ids.get(team)
	var minion = MINION_SCENE.instantiate()
	minion.init(id, team)
	max_ids[team] += 1
	return minion
	
func get_wave(team:int, wave_size:int):
	var minions:Array
	for i in wave_size:
		minions.append(get_minion(team))
	return minions
