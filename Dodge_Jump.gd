extends PlayerState
class_name DodgeJumpState

@export var jump_up_speed: float = 11.5
@export var forward_boost_speed: float = 21.5 # controls launch distance
@export var boost_time: float = 0.18
@export var air_control_speed: float = 5.7
@export var gravity: float = -12.0
@export var steer_amount: float = 0.35
@export var air_turn_speed: float = 1.5  # lower = less sensitive (try 1.5–3.5)
@export var air_brake_strength: float = 10.0  # how hard opposite input can slow you
@export var deadzone: float = 0.2
@export var lock_time: float = 0.22          # protect momentum for first 0.2s
@export var max_turn_during_lock: float = 0.05 # tiny wiggle during lock
@export var brake_strength: float = 1.2      # lower = less braking (start 1.5–3.0)
@export var min_speed_factor: float = 0.88   # even full opposite can't reduce below 65% instantly
@export var opposite_hold_time: float = 0.14   # must hold opposite this long to brake


var _opposite_timer: float = 0.0
var _t := 0.0
var _launch_dir2d: Vector2 = Vector2(0, 1)

func enter() -> void:
	_opposite_timer = 0.0
	_t = 0.0
	_launch_dir2d = player.dodge_jump_dir2d
	if _launch_dir2d.length() < 0.01:
		_launch_dir2d = player.last_move_dir
	_launch_dir2d = _launch_dir2d.normalized()

	# vertical pop
	player.velocity.y = jump_up_speed

	# play dodge jump animation
	if player.animation_state.get_current_node() != "Dodge_Jump":
		player.animation_state.travel("Dodge_Jump")


func physics_process(delta: float) -> void:
	_t += delta
	player.update_input(delta)

	# camera-relative basis
	var cam_basis: Basis = player.get_camera_basis()

	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()

	# During the initial "boost" window, launch mostly in dodge direction
	var dir2d: Vector2
	if _t <= boost_time:
		var input2d: Vector2 = player.input_dir
		if input2d.length() > 0.15:
			dir2d = _launch_dir2d.lerp(input2d.normalized(), steer_amount).normalized()
		else:
			dir2d = _launch_dir2d

		var move_dir: Vector3 = (right * dir2d.x + forward * dir2d.y).normalized()
		player.velocity.x = move_dir.x * forward_boost_speed
		player.velocity.z = move_dir.z * forward_boost_speed
	else:
		var input2d: Vector2 = player.input_dir
		if input2d.length() > deadzone:
			var desired_dir2d: Vector2 = input2d.normalized()
			var desired_move: Vector3 = (right * desired_dir2d.x + forward * desired_dir2d.y).normalized()

			var current_h: Vector3 = Vector3(player.velocity.x, 0, player.velocity.z)
			var current_speed: float = current_h.length()
			if current_speed < 0.01:
				current_speed = forward_boost_speed

			var current_dir: Vector3 = current_h.normalized()
			var dot: float = clamp(current_dir.dot(desired_move), -1.0, 1.0) # -1..1

			# ---- 1) turning: during lock window, severely limit steering ----
			var turn_rate: float = air_turn_speed
			var steer_weight: float = 1.0
			if _t < lock_time:
				turn_rate = air_turn_speed * 0.25
				steer_weight = max_turn_during_lock

			# If stick is opposite, NEVER let it fully redirect mid-air—just a small bend.
			if dot < 0.0:
				steer_weight = min(steer_weight, 0.12)

			# target direction (but we lerp toward it slowly)
			var target_dir: Vector3 = current_dir.lerp(desired_move, steer_weight).normalized()
			var target_h: Vector3 = target_dir * current_speed
			var new_h: Vector3 = current_h.lerp(target_h, turn_rate * delta)

			# ---- 2) braking: requires sustained opposite input ----
			if _t < lock_time:
				_opposite_timer = 0.0
			else:
				if dot < -0.35:
					_opposite_timer += delta
				else:
					# decay the timer quickly when not opposite
					_opposite_timer = max(0.0, _opposite_timer - 4.0 * delta)

				if _opposite_timer >= opposite_hold_time:
					var oppose: float = clamp((-dot - 0.35) / 0.65, 0.0, 1.0) # remap [-0.35..-1] -> [0..1]
					var target_factor: float = lerp(1.0, min_speed_factor, oppose)
					var factor: float = lerp(1.0, target_factor, brake_strength * delta)
					new_h *= factor



			player.velocity.x = new_h.x
			player.velocity.z = new_h.z

	# gravity
	if not player.is_on_floor():
		player.velocity.y += gravity * delta

	player.move_and_slide()

	# Optional facing (same style as your other states)
	var horiz := Vector3(player.velocity.x, 0, player.velocity.z)
	if horiz.length() > 0.1:
		var target_yaw: float = atan2(horiz.x, horiz.z)
		player.mesh_holder.rotation.y = lerp_angle(player.mesh_holder.rotation.y, target_yaw, 10.0 * delta)

	# End condition: once we land
	if player.is_on_floor() and player.velocity.y <= 0.0:
		if player.input_dir != Vector2.ZERO:
			state_machine.switch_state(player.walk_state)
		else:
			state_machine.switch_state(player.idle_state)
