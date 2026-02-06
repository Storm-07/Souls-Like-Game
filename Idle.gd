extends PlayerState

func enter():
	# Ensure we're in locomotion blend-tree state
	if player.animation_state.get_current_node() != "Locomotion":
		player.animation_state.travel("Locomotion")

func physics_process(delta):
	player.update_input()

	# Movement transitions
	if player.input_dir != Vector2.ZERO:
		state_machine.switch_state(player.walk_state)
		return

	if Input.is_action_just_pressed("Jump"):
		state_machine.switch_state(player.jump_state)
		return

	# Fall detection
	if not player.is_on_floor():
		state_machine.switch_state(player.fall_state) # <-- NEW transition
		return

	player.velocity.y = 0
