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
	jump_timer = 0.0
	is_falling = false
	jump_delay_timer = 0.0
	jump_started = false

	player.velocity.y = 0  # Wait for delay before launching
	player.animation_tree.set("parameters/Locomotion/AnimationNodeBlendTree/JumpStart/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func physics_process(delta):
	player.update_input()

	# Horizontal movement & facing
	var cam_transform = player.get_node("SpringArm3D").global_transform.basis
	var forward = -cam_transform.z.normalized()
	var right = cam_transform.x.normalized()
	var move_dir = (right * player.input_dir.x + forward * player.input_dir.y).normalized()

	player.velocity.x = move_dir.x * player.move_speed
	player.velocity.z = move_dir.z * player.move_speed

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
