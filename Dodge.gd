extends PlayerState
class_name DodgeState

@export var max_duration: float = 1.2          # safety cap (was duration)
@export var target_distance: float = 57.0       # <-- main control now
@export var start_speed: float = 18.0
@export var end_speed: float = 2.0
@export var steer_amount: float = 0.25
@export var min_input_for_new_dir: float = 0.15
@export var keep_gravity: bool = true

var _elapsed: float = 0.0
var _base2d: Vector2 = Vector2.ZERO
var _traveled: float = 0.0

func enter() -> void:
	_elapsed = 0.0
	_traveled = 0.0

	var raw := Vector2(
	Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
	-Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
)
	var dir2d: Vector2 = player.input_dir
	if dir2d.length() < min_input_for_new_dir:
		dir2d = player.last_move_dir
	_base2d = dir2d.normalized()

	if player.animation_state.get_current_node() != "Dodge":
		player.animation_state.travel("Dodge")
	# If using OneShot, also fire its request path here

	_set_dodge_blend(_base2d)

func physics_process(delta: float) -> void:
	_elapsed += delta

	# Read input early (good for dodge jump + steering + end transitions)
	player.update_input(delta)

	# Dodge jump check (early exit ONLY if triggered)
	if player.is_on_floor() and Input.is_action_just_pressed("Jump"):
		player.dodge_jump_dir2d = _base2d  # launch in the dodge's direction
		state_machine.switch_state(player.dodge_jump_state)
		return

	var progress: float = 0.0
	if target_distance > 0.0:
		progress = clamp(_traveled / target_distance, 0.0, 1.0)

	var eased: float = 1.0 - pow(1.0 - progress, 3.0)
	var speed: float = lerp(start_speed, end_speed, eased)

	var steer2d: Vector2 = player.input_dir
	if steer2d.length() < min_input_for_new_dir:
		steer2d = _base2d
	else:
		steer2d = _base2d.lerp(steer2d.normalized(), steer_amount).normalized()

	var cam_basis: Basis = player.get_camera_basis()

	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()

	var move_dir: Vector3 = (right * steer2d.x + forward * steer2d.y)
	if move_dir.length_squared() > 0.0:
		move_dir = move_dir.normalized()

	if not keep_gravity:
		player.velocity.y = 0.0
	player.velocity.x = move_dir.x * speed
	player.velocity.z = move_dir.z * speed

	var before: Vector3 = player.global_transform.origin
	player.move_and_slide()
	var after: Vector3 = player.global_transform.origin
	_traveled += (after - before).length()

	_set_dodge_blend(steer2d)

	if move_dir.length() > 0.1:
		var target_yaw: float = atan2(move_dir.x, move_dir.z)
		player.mesh_holder.rotation.y = lerp_angle(player.mesh_holder.rotation.y, target_yaw, 10.0 * delta)

	# End when we hit distance OR time cap
	if _traveled >= target_distance or _elapsed >= max_duration:
		if player.input_dir != Vector2.ZERO:
			state_machine.switch_state(player.walk_state)
		else:
			state_machine.switch_state(player.idle_state)

func _set_dodge_blend(dir2d: Vector2) -> void:
	var paths: Array[String] = [
		"parameters/Dodge/AnimationNodeBlendTree/DodgeBlend/blend_position",
		"parameters/Dodge/DodgeBlend/blend_position",
		"parameters/DodgeBlend/blend_position"
	]
	for p in paths:
		# same note about guarding applies
		player.animation_tree.set(p, dir2d)
		return
