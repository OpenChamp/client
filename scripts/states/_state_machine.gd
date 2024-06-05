extends Node

@export var initial_state: State
var current_state: State
var states: Dictionary = {}
@onready var entity = get_parent();

func _ready():
	for state in get_children():
		if state is State:
			states[state.name] = state
			state.change.connect(change_state)
			
	if initial_state:
		initial_state.enter(entity);
		current_state = initial_state
	
func _process(delta):
	current_state.update(entity, delta);
	
func _physics_process(delta):
	if not multiplayer.is_server(): return;
	current_state.update_tick(entity, delta)
	

func change_state(new_state_name, args=null):
	print("Changing to " + new_state_name);
	var new_state = states[new_state_name]
	if not new_state:
		return;
	if current_state == new_state:
		return;
	
	current_state.exit(entity);
	new_state.enter(entity, args);
	current_state = new_state;
	
