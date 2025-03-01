extends Node

var states = {}
var current_state = null
var player

func _ready():
	player = get_parent()  # Set player reference

	for child in get_children():
		states[child.name] = child
		child.player = player  # Assign player reference to each state

	current_state = states.get("Idle")  # Default state
	current_state.enter()

func change_state(new_state_name):
	if current_state:
		current_state.exit()

	current_state = states.get(new_state_name)
	if current_state:
		current_state.enter()

func process_physics(delta):
	if current_state:
		current_state.physics_process(delta)
