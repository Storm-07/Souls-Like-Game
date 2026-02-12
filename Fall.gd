extends PlayerState

const GRAVITY := -9.8

func enter():
	pass # Or whatever your fall anim is called

func physics_process(delta):
	player.update_input(delta)

	# Apply gravity
	player.velocity.y += GRAVITY * delta

	# Allow horizontal air control
		# Allow horizontal air control (camera-relative, flattened)
	var cam_basis: Basis = player.get_camera_basis()

	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()

	var move_dir: Vector3 = (right * player.input_dir.x + forward * player.input_dir.y)
	if move_dir.length_squared() > 0.0:
		move_dir = move_dir.normalized()


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
