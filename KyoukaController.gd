extends CharacterBody3D

@export var cam_pivot_path: NodePath
@onready var cam_pivot: Node3D = get_node_or_null(cam_pivot_path) as Node3D

@export var move_speed: float = 5.7
@export var dodge_cooldown: float = 0.45
@export var input_deadzone: float = 0.2
@export var input_rise_speed: float = 14.0   # accel (higher = snappier)
@export var input_fall_speed: float = 18.0   # decel (higher = snappier)

var _smoothed_dir: Vector2 = Vector2(0, 1)
var _smoothed_strength: float = 0.0
var input_dir: Vector2 = Vector2.ZERO
var blend_position: Vector2 = Vector2.ZERO
var raw_input_strength: float = 0.0
var sprint_toggled: bool = false   # L3 toggles this
var last_move_dir: Vector2 = Vector2(0, 1)   # ⬅ NEW (fallback for dodge direction)
var can_dodge: bool = true
var _dodge_cd_timer: float = 0.0
var dodge_jump_dir2d: Vector2 = Vector2(0, 1)
var move_strength: float = 0.0 # smoothed 0..1


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


@onready var mesh_holder = $KyoukaModel_v10/rig

# --- AnimationTree parameter paths ---
const PATH_IDLE_WALK := "parameters/Locomotion/AnimationNodeBlendTree/IdleWalkBlend/blend_amount"
const PATH_WALK_JOG  := "parameters/Locomotion/AnimationNodeBlendTree/WalkJogBlend/blend_amount"

# Ground↔Air blend:
const PATH_GROUND_AIR := "parameters/Locomotion/AnimationNodeBlendTree/GroundAir/blend_amount"
# If yours lives at root instead, swap to:
# const PATH_GROUND_AIR := "parameters/GroundAir/blend_amount"

# Damping
const GROUND_AIR_DAMP: float = 12.0

var _ground_air: float = 0.0

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
	
	idle_state.state_machine = state_machine
	walk_state.state_machine = state_machine
	jog_state.state_machine  = state_machine
	jump_state.state_machine = state_machine
	fall_state.state_machine = state_machine
	dodge_state.state_machine = state_machine
	basic_attack1_state.state_machine = state_machine
	dodge_jump_state.state_machine = state_machine
	

	state_machine.switch_state(idle_state)
	anim_player.animation_finished.connect(_on_animation_finished)
	
func _on_animation_finished(anim_name: StringName) -> void:
	# Forward the event to the current state
	if state_machine.current_state is AttackState:
		state_machine.current_state.on_animation_finished(anim_name)


func update_input(delta: float = 0.0) -> void:
	var raw := _read_raw_stick()
	var mag := raw.length()

	# deadzone
	if mag < input_deadzone:
		raw = Vector2.ZERO
		mag = 0.0
	else:
		mag = clamp((mag - input_deadzone) / (1.0 - input_deadzone), 0.0, 1.0)

	var target_dir := Vector2.ZERO
	if mag > 0.0:
		target_dir = raw.normalized()

	# If called without delta (e.g., from enter()), just take a snapshot:
	if delta <= 0.0:
		raw_input_strength = mag              # RAW (unsmoothed)
		move_strength = mag                   # ✅ NEW: smoothed channel mirrors raw on snapshot
		if target_dir != Vector2.ZERO:
			_smoothed_dir = target_dir
			last_move_dir = target_dir
			input_dir = target_dir            # ✅ CHANGED: PURE direction
		else:
			input_dir = Vector2.ZERO
		return

	# Smooth strength
	var speed := input_rise_speed if mag > _smoothed_strength else input_fall_speed
	_smoothed_strength = lerp(_smoothed_strength, mag, 1.0 - exp(-speed * delta))

	# Clamp tiny tail
	if _smoothed_strength < 0.02:
		_smoothed_strength = 0.0

	# Smooth direction (don’t change dir when stopping)
	if target_dir != Vector2.ZERO:
		_smoothed_dir = _smoothed_dir.lerp(target_dir, 1.0 - exp(-input_rise_speed * delta)).normalized()

	# ✅ Outputs
	raw_input_strength = mag                # ✅ CHANGED: keep this truly raw (post-deadzone)
	move_strength = _smoothed_strength      # ✅ NEW: smoothed 0..1 for speed/transitions

	if move_strength > 0.01:
		input_dir = _smoothed_dir            # ✅ CHANGED: PURE direction
		last_move_dir = _smoothed_dir
	else:
		input_dir = Vector2.ZERO


		

func _physics_process(delta: float) -> void:
	update_input(delta)
	state_machine.current_state.physics_process(delta)

	# Ground-only dodge; remove is_on_floor() if you want air-dodge
	if can_dodge and is_on_floor() and Input.is_action_just_pressed("Dodge"):
		state_machine.switch_state(dodge_state)
		can_dodge = false
		_dodge_cd_timer = dodge_cooldown
		
	if Input.is_action_just_pressed("B_Attack"):
	# don't restart attack if we're already attacking
		if state_machine.current_state is AttackState:
			(state_machine.current_state as AttackState).buffer_attack()
		# basic guard: only allow starting attacks from grounded + not dodging
		elif is_on_floor() and state_machine.current_state != dodge_state and state_machine.current_state != dodge_jump_state:
			state_machine.switch_state(basic_attack1_state)

	var s: float = clamp(raw_input_strength, 0.0, 1.0)
	s = pow(s, 1.5)
	var idle_walk: float = clamp(s * 2.0, 0.0, 1.0)
	animation_tree.set(PATH_IDLE_WALK, idle_walk)

	var walk_jog: float = clamp((s - 0.5) * 2.0, 0.0, 1.0)
	animation_tree.set(PATH_WALK_JOG, walk_jog)

	var target_js: float
	if raw_input_strength <= 0.08:
		target_js = 0.0
		animation_tree.set(PATH_IDLE_WALK, idle_walk)
	else:
		target_js = 1.0 if sprint_toggled else 0.0

	# ----- Ground ↔ Air blend -----
	var target_air: float = 0.0 if is_on_floor() else 1.0
	_ground_air = lerp(_ground_air, target_air, GROUND_AIR_DAMP * delta)
	animation_tree.set(PATH_GROUND_AIR, _ground_air)

	# ----- ⬅ NEW: keep Dodge Blend2D facing the current (or last) move dir -----
	# It’s safe to update this every frame; it only matters while the "Dodge" state is active.
	# cooldown tick
	if not can_dodge:
		_dodge_cd_timer -= delta
		if _dodge_cd_timer <= 0.0:
			can_dodge = true

func get_camera_basis() -> Basis:
	var b: Basis = cam_pivot.global_transform.basis

	# Flatten forward/right onto the XZ plane so camera pitch doesn't affect movement strength
	var forward: Vector3 = -b.z
	forward.y = 0.0
	forward = forward.normalized()

	var right: Vector3 = b.x
	right.y = 0.0
	right = right.normalized()

	# Rebuild a clean orthonormal basis (Godot bases are x=right, y=up, z=back)
	var up: Vector3 = Vector3.UP
	var back: Vector3 = -forward

	return Basis(right, up, back)
	
func _read_raw_stick() -> Vector2:
	return Vector2(
		Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
		-Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	)
