extends PlayerState

const IDLE_THRESHOLD := 0.1
const JOG_THRESHOLD := 0.75

func enter():
	if player.animation_state.get_current_node() != "Locomotion":
		player.animation_state.travel("Locomotion")

func physics_process(delta):
	player.update_input()

	var input_strength = player.raw_input_strength
	
	if player.is_on_floor():
		player.velocity.y = 0
	else:
		player.velocity.y += -9.8 * delta


	if Input.is_action_just_pressed("Jump"):
		state_machine.switch_state(player.jump_state)
		return

	# Transition logic
	if input_strength < IDLE_THRESHOLD:
		state_machine.switch_state(player.idle_state)
		return
	elif input_strength >= JOG_THRESHOLD:
		state_machine.switch_state(player.jog_state)
		return

	# Movement direction relative to camera
	var cam_transform = player.get_node("SpringArm3D").global_transform.basis
	var forward = -cam_transform.z.normalized()
	var right = cam_transform.x.normalized()
	var move_dir = (right * player.input_dir.x + forward * player.input_dir.y).normalized()

	var scaled_speed = player.move_speed * input_strength

	player.velocity.x = move_dir.x * scaled_speed
	player.velocity.z = move_dir.z * scaled_speed

	player.move_and_slide()

	# Face movement direction
	if move_dir.length() > 0.1:
		var target_rotation = atan2(move_dir.x, move_dir.z)
		player.mesh_holder.rotation.y = lerp_angle(player.mesh_holder.rotation.y, target_rotation, 10 * delta)
