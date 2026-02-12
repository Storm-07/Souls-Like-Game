extends PlayerState
class_name AttackState

@export var attack_anims: Array[String] = ["BAttack_1", "BAttack_2", "BAttack_3"]
@export var chain_window_start_t: float = 0.6
@export var chain_window_end_t: float = 0.7
@export var combo_cut_t: float = 0.80   # your curated “cut” point
@export var return_to_walk: bool = true
@export var lunge_speed: float = 35
@export var lunge_start_t: float = 0.10
@export var lunge_end_t: float = 0.25
@export var safety_timeout: float = 2.0
@export var recovery_time: float = 0.12
@export var buffer_accept_start_t: float = 0.50  # ignore presses before this
@export var buffer_expire_time: float = 0.2     # optional: seconds to keep the request alive


var _in_recovery := false
var _recovery_t := 0.0
var _combo_index := 0
var _time := 0.0
var _queued_next := false
var _current_anim_length := 0.0
var _current_anim := ""
var _buffer_active: bool = false
var _buffer_age: float = 0.0
var _attack_dir3: Vector3 = Vector3.ZERO
var _press_requested: bool = false
var _buffer_used_this_attack := false


func _compute_attack_dir3() -> Vector3:
	var dir2: Vector2 = player.input_dir
	if dir2 == Vector2.ZERO:
		dir2 = player.last_move_dir

	var basis: Basis = player.get_camera_basis()
	var forward: Vector3 = -basis.z; forward.y = 0.0; forward = forward.normalized()
	var right: Vector3 = basis.x; right.y = 0.0; right = right.normalized()

	var d: Vector3 = (right * dir2.x + forward * dir2.y)
	return d.normalized() if d.length() > 0.001 else -basis.z.normalized()

func buffer_attack() -> void:
	_press_requested = true


func _play_current_attack() -> void:
	_current_anim = attack_anims[_combo_index]
	player.animation_state.travel(_current_anim)

	# pull length from AnimationPlayer
	var a : Animation = player.anim_player.get_animation(_current_anim)
	_current_anim_length = a.length if a else 0.0


func on_animation_finished(anim_name: StringName) -> void:
	if anim_name != _current_anim:
		return

	if _queued_next and _combo_index < attack_anims.size() - 1:
		_start_attack(_combo_index + 1)
	else:
		_end_combo_and_exit()

func enter() -> void:
	_start_attack(0)

func _start_attack(index: int) -> void:
	_combo_index = index
	_time = 0.0
	_queued_next = false
	_attack_dir3 = _compute_attack_dir3()
	_buffer_active = false
	_buffer_age = 0.0
	_press_requested = false
	_buffer_used_this_attack = false


	player.velocity.x = 0.0
	player.velocity.z = 0.0
	# rotate character to face the attack direction (Y-only)
	player.mesh_holder.rotation.y = atan2(_attack_dir3.x, _attack_dir3.z)

	_play_current_attack()

func physics_process(delta: float) -> void:
	_time += delta
	
	var t: float = 0.0
	if _current_anim_length > 0.0:
		t = _time / _current_anim_length
	
	# age buffer
	if _buffer_active:
		_buffer_age += delta
		if _buffer_age > buffer_expire_time:
			_buffer_active = false
			_buffer_age = 0.0

	if _press_requested and t >= buffer_accept_start_t and not _buffer_used_this_attack:
		_buffer_active = true
		_buffer_age = 0.0
		_press_requested = false
		_buffer_used_this_attack = true
	
	if _in_recovery:
		_recovery_t += delta
		# keep body stable during recovery
		player.velocity.x = 0.0
		player.velocity.z = 0.0
		if _recovery_t >= recovery_time:
			_end_combo_and_exit()
		# still apply gravity + move
		if not player.is_on_floor():
			player.velocity.y -= 24.0 * delta
		player.move_and_slide()
		return

	# --- lunge forward for a short window (normalized) ---
	if t >= lunge_start_t and t <= lunge_end_t:
		player.velocity.x = _attack_dir3.x * lunge_speed
		player.velocity.z = _attack_dir3.z * lunge_speed
	else:
		player.velocity.x = 0.0
		player.velocity.z = 0.0

	if not _queued_next and _buffer_active and t >= chain_window_start_t and t <= chain_window_end_t:
		_queued_next = true
		_buffer_active = false
		_buffer_age = 0.0
			
	# apply gravity so you don't float if you leave ground on edges
	if not player.is_on_floor():
		player.velocity.y -= 24.0 * delta  # tweak to match your project
		
	if _queued_next and t >= combo_cut_t:
		_queued_next = false
		if _combo_index < attack_anims.size() - 1:
			_queued_next = false
			_start_attack(_combo_index + 1)
			return
		else:
			# last attack: don't chain further
			_queued_next = false
		return

	# 2) If nothing queued, let the animation finish fully
	if (not _queued_next) and t >= 1.0:
		_in_recovery = true
		_recovery_t = 0.0

	player.move_and_slide()

func _exit_to_locomotion() -> void:
	if return_to_walk and player.input_dir != Vector2.ZERO:
		state_machine.switch_state(player.walk_state)
	else:
		state_machine.switch_state(player.idle_state)

func _end_combo_and_exit() -> void:
	_combo_index = 0
	_time = 0.0
	_queued_next = false
	_in_recovery = false
	_exit_to_locomotion()
