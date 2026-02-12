extends PlayerState

const MAX_JUMP_TIME := 0.6
const JUMP_SPEED := 8.0
const GRAVITY := -12.0
const JUMP_DELAY := 0.0  # Delay before applying jump force

var jump_timer := 0.0
var is_falling := false
var jump_delay_timer := 0.0
var jump_started := false

func enter():
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	player.velocity.y = 0.0

	jump_timer = 0.0
	is_falling = false
	jump_delay_timer = 0.0
	jump_started = false

	player.velocity.y = 0  # Wait for delay before launching
	player.animation_tree.set("parameters/Locomotion/AnimationNodeBlendTree/JumpStart/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func physics_process(delta):
	player.update_input(delta)

	var has_input: bool = player.raw_input_strength > 0.01

	var cam_basis: Basis = player.get_camera_basis()
	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()

	var move_dir := Vector3.ZERO
	if has_input:
		move_dir = (right * player.input_dir.x + forward * player.input_dir.y)
		if move_dir.length_squared() > 0.0:
			move_dir = move_dir.normalized()

	var s : float = player.move_strength
	player.velocity.x = move_dir.x * player.move_speed * s
	player.velocity.z = move_dir.z * player.move_speed * s


	if move_dir.length() > 0.1:
		var target_rotation = atan2(move_dir.x, move_dir.z)
		player.mesh_holder.rotation.y = lerp_angle(
			player.mesh_holder.rotation.y,
			target_rotation,
			10 * delta
		)

	# Handle jump delay
	if not jump_started:
		jump_delay_timer += delta
		if jump_delay_timer >= JUMP_DELAY:
			player.velocity.y = JUMP_SPEED
			jump_started = true
		else:
			apply_gravity(delta)  # Apply gravity even during delay if needed
			player.move_and_slide()
			return

	# Handle upward jump hold
	if jump_started and Input.is_action_pressed("Jump") and jump_timer < MAX_JUMP_TIME and not is_falling:
		jump_timer += delta
	else:
		if not is_falling:
			is_falling = true
			#player.animation_state.travel("JumpFall")
		apply_gravity(delta)

	player.move_and_slide()

	# Ground check
	if player.is_on_floor():
		if player.input_dir != Vector2.ZERO:
			state_machine.switch_state(player.walk_state)
		else:
			state_machine.switch_state(player.idle_state)

func apply_gravity(delta):
	if not player.is_on_floor():
		player.velocity.y += GRAVITY * delta
