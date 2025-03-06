extends Node
class_name NetworkRandomNumberGenerator

var generator: RandomNumberGenerator

func _ready() -> void:
	generator = RandomNumberGenerator.new()
	add_to_group('network_sync')

func set_seed(new_seed: int) -> void:
	generator.seed = new_seed

func get_seed() -> int:
	return generator.seed

func _save_state() -> Dictionary:
	return {
		state = generator.state,
	}

func _load_state(state: Dictionary) -> void:
	generator.state = state['state']

func randomize() -> void:
	generator.randomize()

func randi() -> int:
	return generator.randi()

func randi_range(from: int, to: int) -> int:
	return generator.randi_range(from, to)

func shuffle(t: Array) -> void:
	var n: = t.size()
	for i in range(n - 1, 0, -1):
		var j: = randi_range(0, i)
		var e = t[j]
		t[j] = t[i]
		t[i] = e
