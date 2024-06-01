extends Node

@export var initial_state: State
var current_state: State
var states: Dictionary = {}

func _ready():
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.swap.connect(swap_state)
			
	if initial_state:
		initial_state.enter()
		current_state = initial_state

func _process(delta):
	if current_state:
		current_state.update(delta);
	pass

func _physics_process(delta):
	if current_state:
		current_state.tick(delta);

func swap_state(old, new):
	if current_state != old:
		return
	current_state.exit()
	new.enter()
	current_state = new
	
