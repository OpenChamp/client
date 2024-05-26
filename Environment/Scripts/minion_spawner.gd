extends MultiplayerSpawner

const MinionScene: PackedScene = preload("res://Characters/minion.tscn")
var max_ids: Dictionary

func get_minion(team: int):
	if not max_ids.has(team):
		max_ids[team] = 0
	var id: int = max_ids.get(team)
	var minion = MinionScene.instantiate()
	minion.id = id
	minion.team = team
	max_ids[team] += 1
	return minion
	
func get_wave(team: int, wave_size: int) -> Array:
	var minions: Array
	for i in wave_size:
		minions.append(get_minion(team))
	return minions
