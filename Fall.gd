extends PlayerState

const GRAVITY := -9.8

func enter():
	pass # Or whatever your fall anim is called

func physics_process(delta):
	player.update_input()

	# Apply gravity
	player.velocity.y += GRAVITY * delta

	# Allow horizontal air control
	var cam_transform = player.get_node("SpringArm3D").global_transform.basis
	var forward = -cam_transform.z.normalized()
	var right = cam_transform.x.normalized()
	var move_dir = (right * player.input_dir.x + forward * player.input_dir.y).normalized()

	player.velocity.x = move_dir.x * player.move_speed
	player.velocity.z = move_dir.z * player.move_speed
	player.move_and_slide()

	# Face direction in air
	if move_dir.length() > 0.1:
		var target_rotation = atan2(move_dir.x, move_dir.z)
		player.mesh_holder.rotation.y = lerp_angle(player.mesh_holder.rotation.y, target_rotation, 10 * delta)

	# Landing
	if player.is_on_floor():
		if player.input_dir != Vector2.ZERO:
			state_machine.switch_state(player.walk_state)
		else:
			state_machine.switch_state(player.idle_state)
