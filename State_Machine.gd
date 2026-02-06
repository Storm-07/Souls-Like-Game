extends Node

var current_state: PlayerState = null

func switch_state(new_state: PlayerState):
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()

func _physics_process(delta):
	if current_state:
		current_state.physics_process(delta)
