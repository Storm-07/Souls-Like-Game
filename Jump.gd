extends PlayerState

const MAX_JUMP_TIME := 0.6
const JUMP_SPEED := 8.0
const GRAVITY := -12.0
const JUMP_DELAY := 0.0  # Delay before applying jump force
const AIR_ACCEL := 14.0  # higher = snappier. Try 10–18 for "tiny" lag.

var horiz_vel: Vector3 = Vector3.ZERO
var jump_timer := 0.0
var is_falling := false
var jump_delay_timer := 0.0
var jump_started := false

func enter():
	horiz_vel = Vector3(player.velocity.x, 0.0, player.velocity.z)
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
	# player.update_input(delta)  <-- remove this

	var cam_basis: Basis = player.get_camera_basis()
	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()

	# Use buffered direction when input_dir is zero (this is your "movement buffer" behavior)
	var dir2 : Vector2 = player.input_dir
	if dir2 == Vector2.ZERO:
		dir2 = player.last_move_dir

	var move_dir := Vector3.ZERO
	if dir2 != Vector2.ZERO:
		move_dir = (right * dir2.x + forward * dir2.y).normalized()

	# Use smoothed strength (already buffered)
	var s: float = player.move_strength
	var target_h : Vector3 = move_dir * player.move_speed * s

	# Smooth horizontal velocity toward target (this is the “tiny lag”)
	var t := 1.0 - exp(-AIR_ACCEL * delta)
	horiz_vel = horiz_vel.lerp(target_h, t)

	player.velocity.x = horiz_vel.x
	player.velocity.z = horiz_vel.z

	# Rotation (optional): rotate toward move_dir OR toward horiz_vel (feels nicer midair)
	var face_dir := horiz_vel
	if face_dir.length() > 0.1:
		var target_rotation = atan2(face_dir.x, face_dir.z)
		player.mesh_holder.rotation.y = lerp_angle(player.mesh_holder.rotation.y, target_rotation, 10 * delta)

	# ...keep the rest of your jump logic (delay, hold, gravity, move_and_slide, landing) unchanged


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
