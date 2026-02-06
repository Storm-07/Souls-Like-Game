# Jog.gd
extends PlayerState

const WALK_THRESHOLD := 0.9
const ROTATE_DAMP := 10.0

# If your SpringArm path differs, update this:
const CAM_PATH := "../../SpringArm3D"

func enter():
	# Ensure we're in the locomotion state machine node
	if player.animation_state.get_current_node() != "Locomotion":
		player.animation_state.travel("Locomotion")

func physics_process(delta):
	# --- State exits ---
	# Walk if stick eases off
	if player.input_dir.length() < WALK_THRESHOLD:
		return state_machine.switch_state(player.walk_state)

	# Sprint toggle (L3) from Jog
	if player.sprint_toggled and player.input_dir != Vector2.ZERO and player.is_on_floor():
		return state_machine.switch_state(player.sprint_state)

	# Jump
	if Input.is_action_just_pressed("Jump"):
		return state_machine.switch_state(player.jump_state)

	# --- Gravity ---
	var g: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	if player.is_on_floor():
		player.velocity.y = 0.0
	else:
		player.velocity.y -= g * delta

	# --- Move in camera space ---
	# input_dir is Vector2 (x,y); we build a Vector3 move_dir from it
	var cam_basis: Basis = player.get_camera_basis()
	var forward: Vector3 = (-cam_basis.z).normalized()
	var right: Vector3 = cam_basis.x.normalized()


	var move_dir: Vector3 = (right * player.input_dir.x + forward * player.input_dir.y)
	if move_dir.length_squared() > 0.0:
		move_dir = move_dir.normalized()

	# Speed: jog = move_speed * 1.5, scaled by stick magnitude (raw_input_strength in [0..1])
	var jog_speed: float = player.move_speed * 1.5
	var speed: float = jog_speed * clamp(player.raw_input_strength, 0.0, 1.0)

	player.velocity.x = move_dir.x * speed
	player.velocity.z = move_dir.z * speed
	player.move_and_slide()

	# --- Face movement direction (only if we have a direction) ---
	if move_dir.length_squared() > 0.01:
		var target_yaw := atan2(move_dir.x, move_dir.z)  # Vector3 → yaw
		player.mesh_holder.rotation.y = lerp_angle(player.mesh_holder.rotation.y, target_yaw, ROTATE_DAMP * delta)
