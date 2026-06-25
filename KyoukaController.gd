extends CharacterBody3D
class_name Player

@export var cam_pivot_path: NodePath
@onready var cam_pivot: Node3D = get_node_or_null(cam_pivot_path) as Node3D
@export var player_camera_path: NodePath
@export var test_lock_target_path: NodePath
@export var lock_on_max_distance := 130.0

@export var move_speed: float = 5.7
@export var dodge_cooldown: float = 0.45
@export var input_deadzone: float = 0.2

# --- Input channels (instant) ---
var input_dir: Vector2 = Vector2.ZERO          # normalized direction (or ZERO)
var raw_input_strength: float = 0.0            # 0..1 magnitude AFTER deadzone mapping
var last_move_dir: Vector2 = Vector2(0, 1)     # fallback for dodge facing

var sprint_toggled: bool = false   # (you can wire this elsewhere)

var can_dodge: bool = true
var _dodge_cd_timer: float = 0.0

var just_spawned := true
var spawn_grace := 0.15

var dodge_jump_dir2d : Vector2 = Vector2.ZERO

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_state := animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
@onready var anim_player: AnimationPlayer = $KyoukaModel_v10/AnimationPlayer
@onready var state_machine = $States
@onready var idle_state = $States/Idle
@onready var walk_state = $States/Walk
@onready var jog_state  = $States/Jog
@onready var jump_state = $States/Jump
@onready var fall_state = $States/Fall
@onready var dodge_state = $States/Dodge
@onready var basic_attack1_state = $States/B_Attack1
@onready var dodge_jump_state = $States/Dodge_Jump
@onready var land_state = $States/Land
@onready var block_state = $States/Block
@onready var attack_state = $States/B_Attack1
@onready var hurt_state = $States/Hurt
@onready var parry_state = $States/Parry

@onready var mesh_holder = $KyoukaModel_v10/rig # update upon reimport potentially

@onready var player_camera = get_node_or_null(player_camera_path)
@onready var test_lock_target: Node3D = get_node_or_null(test_lock_target_path) as Node3D

# --- AnimationTree parameter paths ---
const PATH_IDLE_WALK := "parameters/Locomotion/AnimationNodeBlendTree/IdleWalkBlend/blend_amount"
const PATH_WALK_JOG  := "parameters/Locomotion/AnimationNodeBlendTree/WalkJogBlend/blend_amount"
const PATH_GROUND_AIR := "parameters/Locomotion/AnimationNodeBlendTree/GroundAir/blend_amount"

const GROUND_AIR_DAMP: float = 12.0
var _ground_air: float = 0.0
var parry_active := false

func _ready():
	cam_pivot = get_node_or_null(cam_pivot_path) as Node3D
	assert(cam_pivot != null, "cam_pivot_path is not set to a valid node. Set it on the Player instance in the Main scene Inspector.")
	animation_tree.active = true

	# wire states
	idle_state.player = self
	walk_state.player = self
	jog_state.player  = self
	jump_state.player = self
	fall_state.player = self
	dodge_state.player = self
	basic_attack1_state.player = self
	dodge_jump_state.player = self
	land_state.player = self
	block_state.player = self
	attack_state.player = self
	hurt_state.player = self
	parry_state.player = self

	idle_state.state_machine = state_machine
	walk_state.state_machine = state_machine
	jog_state.state_machine  = state_machine
	jump_state.state_machine = state_machine
	fall_state.state_machine = state_machine
	dodge_state.state_machine = state_machine
	basic_attack1_state.state_machine = state_machine
	dodge_jump_state.state_machine = state_machine
	land_state.state_machine = state_machine
	block_state.state_machine = state_machine
	attack_state.state_machine = state_machine
	hurt_state.state_machine = state_machine
	parry_state.state_machine = state_machine

	state_machine.switch_state(idle_state)
	anim_player.animation_finished.connect(_on_animation_finished)


func _on_animation_finished(anim_name: StringName) -> void:
	# Forward the event to the current state
	if state_machine.current_state == attack_state:
		state_machine.current_state.on_animation_finished(anim_name)


func update_input() -> void:
	var raw := _read_raw_stick()
	var mag := raw.length()

	# deadzone + remap to 0..1
	if mag < input_deadzone:
		raw = Vector2.ZERO
		mag = 0.0
	else:
		mag = clamp((mag - input_deadzone) / (1.0 - input_deadzone), 0.0, 1.0)

	raw_input_strength = mag

	if mag > 0.0:
		var dir := raw.normalized()
		input_dir = dir
		last_move_dir = dir
	else:
		input_dir = Vector2.ZERO


func _physics_process(delta: float) -> void:
	update_input()
	
	if Input.is_action_just_pressed("lock_on"):
		toggle_lock_on()
		
	check_lock_on_distance()
		
	state_machine.current_state.physics_process(delta)

	if is_locked_state():
		move_and_slide()
		return
		
	spawn_grace -= delta
	if spawn_grace <= 0.0:
		just_spawned = false

	# Ground-only dodge
	if can_dodge and is_on_floor() and Input.is_action_just_pressed("Dodge"):
		state_machine.switch_state(dodge_state)
		can_dodge = false
		_dodge_cd_timer = dodge_cooldown

	# Attacks / attack buffering
	if Input.is_action_just_pressed("B_Attack"):
		if state_machine.current_state == attack_state:
			state_machine.current_state.buffer_attack()
		elif is_on_floor() and state_machine.current_state != dodge_state and state_machine.current_state != dodge_jump_state:
			state_machine.switch_state(attack_state)
			
	# Held block
	if is_on_floor() and Input.is_action_pressed("Block"):
		if state_machine.current_state != parry_state \
		and state_machine.current_state != dodge_state \
		and state_machine.current_state != dodge_jump_state \
		and state_machine.current_state != attack_state \
		and state_machine.current_state != hurt_state:
			if state_machine.current_state != block_state:
				state_machine.switch_state(block_state)

	# --- Locomotion blends (based on raw strength) ---
	var s: float = clamp(raw_input_strength, 0.0, 1.0)
	s = pow(s, 1.5)

	var idle_walk: float = clamp(s * 2.0, 0.0, 1.0)
	animation_tree.set(PATH_IDLE_WALK, idle_walk)

	var walk_jog: float = clamp((s - 0.5) * 2.0, 0.0, 1.0)
	animation_tree.set(PATH_WALK_JOG, walk_jog)

	# --- Ground ↔ Air blend ---
	var target_air: float = 0.0 if is_on_floor() else 1.0
	_ground_air = lerp(_ground_air, target_air, GROUND_AIR_DAMP * delta)
	animation_tree.set(PATH_GROUND_AIR, _ground_air)

	# cooldown tick
	if not can_dodge:
		_dodge_cd_timer -= delta
		if _dodge_cd_timer <= 0.0:
			can_dodge = true


func get_camera_basis() -> Basis:
	var b: Basis = cam_pivot.global_transform.basis

	var forward: Vector3 = -b.z
	forward.y = 0.0
	forward = forward.normalized()

	var right: Vector3 = b.x
	right.y = 0.0
	right = right.normalized()

	var up: Vector3 = Vector3.UP
	var back: Vector3 = -forward
	return Basis(right, up, back)


func _read_raw_stick() -> Vector2:
	return Vector2(
		Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
		-Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	)

func set_dodge_jump_dir2d(v: Vector2) -> void:
	dodge_jump_dir2d = v
	
func is_block_held() -> bool:
	return Input.is_action_pressed("Block")
	
func receive_hit(hit_data: Dictionary) -> void:
	if parry_active:
		print("PLAYER PARRIED")
		state_machine.switch_state(parry_state)

		var attacker = hit_data.get("attacker", null)
		print("Attacker received by player: ", attacker)

		if attacker != null and attacker.has_method("receive_parry"):
			attacker.receive_parry()
		else:
			print("No valid attacker found for parry")

		return

	if state_machine.current_state == block_state:
		print("PLAYER BLOCKED")
		return

	print("PLAYER RECEIVED DAMAGE: ", hit_data)
	state_machine.switch_state(hurt_state)

func is_locked_state() -> bool:
	return state_machine.current_state == hurt_state \
	or state_machine.current_state == parry_state
	
func toggle_lock_on() -> void:
	var distance := global_position.distance_to(test_lock_target.global_position)

	if distance > lock_on_max_distance:
		print("Target too far to lock on")
		return
		
	if player_camera == null:
		print("No player_camera assigned")
		return

	if player_camera.lock_on_enabled:
		player_camera.lock_on_enabled = false
		player_camera.lock_on_target = null
		print("LOCK OFF")
	else:
		if test_lock_target == null:
			print("No test_lock_target assigned")
			return

		player_camera.lock_on_target = test_lock_target
		player_camera.lock_on_enabled = true
		print("LOCK ON")

func check_lock_on_distance() -> void:
	if player_camera == null:
		return
	
	if not player_camera.lock_on_enabled:
		return
	
	if player_camera.lock_on_target == null:
		return
	
	var distance := global_position.distance_to(player_camera.lock_on_target.global_position)
	
	if distance > lock_on_max_distance:
		player_camera.lock_on_enabled = false
		player_camera.lock_on_target = null
		print("LOCK BROKEN: target too far")
