extends CharacterBody3D

@export var cam_pivot_path: NodePath = NodePath("SpringArm3D")
@onready var cam_pivot: Node3D = get_node_or_null(cam_pivot_path)

@export var move_speed: float = 3.8
@export var sprint_speed: float = 9.7
@export var dodge_cooldown: float = 0.45

var input_dir: Vector2 = Vector2.ZERO
var blend_position: Vector2 = Vector2.ZERO
var raw_input_strength: float = 0.0
var sprint_toggled: bool = false   # L3 toggles this
var last_move_dir: Vector2 = Vector2(0, 1)   # ⬅ NEW (fallback for dodge direction)
var can_dodge: bool = true
var _dodge_cd_timer: float = 0.0

@onready var animation_tree: AnimationTree = $Seigen_Master/AnimationTree
@onready var animation_state := animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
@onready var anim_player: AnimationPlayer = $Seigen_Master/AnimationPlayer
@onready var state_machine = $States
@onready var idle_state = $States/Idle
@onready var walk_state = $States/Walk
@onready var jog_state  = $States/Jog
@onready var jump_state = $States/Jump
@onready var fall_state = $States/Fall
@onready var sprint_state = $States/Sprint
@onready var dodge_state = $States/Dodge
@onready var basic_attack1_state = $States/B_Attack1


@onready var mesh_holder = $Seigen_Master/rig

# --- AnimationTree parameter paths ---
const PATH_IDLE_WALK := "parameters/Locomotion/AnimationNodeBlendTree/IdleWalkBlend/blend_amount"
const PATH_WALK_JOG  := "parameters/Locomotion/AnimationNodeBlendTree/WalkJogBlend/blend_amount"
const PATH_JOG_SPRINT := "parameters/Locomotion/AnimationNodeBlendTree/JogSprintBlend/blend_amount"

# Ground↔Air blend:
const PATH_GROUND_AIR := "parameters/Locomotion/AnimationNodeBlendTree/GroundAir/blend_amount"
# If yours lives at root instead, swap to:
# const PATH_GROUND_AIR := "parameters/GroundAir/blend_amount"

# Damping
const GROUND_AIR_DAMP: float = 12.0
const JOG_SPRINT_DAMP: float = 50.0    # ⬅ moved up, was redeclared each frame

var _ground_air: float = 0.0
var _jog_sprint: float = 0.0           # ⬅ NEW: persist across frames

func _ready():
	animation_tree.active = true

	# wire states
	idle_state.player = self
	walk_state.player = self
	jog_state.player  = self
	jump_state.player = self
	fall_state.player = self
	sprint_state.player = self
	dodge_state.player = self
	basic_attack1_state.player = self
	
	idle_state.state_machine = state_machine
	walk_state.state_machine = state_machine
	jog_state.state_machine  = state_machine
	jump_state.state_machine = state_machine
	fall_state.state_machine = state_machine
	sprint_state.state_machine = state_machine
	dodge_state.state_machine = state_machine
	basic_attack1_state.state_machine = state_machine

	state_machine.switch_state(idle_state)

func update_input() -> void:
	var x_input: float = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var y_input: float = -Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	var raw_input: Vector2 = Vector2(x_input, y_input)
	raw_input_strength = raw_input.length()

	if raw_input_strength > 0.2:
		input_dir = raw_input.normalized()
		last_move_dir = input_dir            # ⬅ NEW: remember last direction
	else:
		input_dir = Vector2.ZERO
		raw_input_strength = 0.0
		
	if Input.is_action_just_pressed("sprint_toggle"):
		sprint_toggled = !sprint_toggled

func _physics_process(delta: float) -> void:
	update_input()
	state_machine.current_state.physics_process(delta)

	# Ground-only dodge; remove is_on_floor() if you want air-dodge
	if can_dodge and is_on_floor() and Input.is_action_just_pressed("Dodge"):
		state_machine.switch_state(dodge_state)
		can_dodge = false
		_dodge_cd_timer = dodge_cooldown
		
	if Input.is_action_just_pressed("B_Attack1"):
		state_machine.switch_state(basic_attack1_state)  # your AttackState node

	# ----- Ground locomotion blends -----
	var x_input: float = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var y_input: float = -Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	var raw_input: Vector2 = Vector2(x_input, y_input)
	raw_input_strength = raw_input.length()

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

	_jog_sprint = lerp(_jog_sprint, target_js, JOG_SPRINT_DAMP * delta)
	animation_tree.set(PATH_JOG_SPRINT, _jog_sprint)

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
	assert(cam_pivot != null, "Player.cam_pivot_path is not set to a valid node. Set it in the Inspector.")
	return cam_pivot.global_transform.basis
