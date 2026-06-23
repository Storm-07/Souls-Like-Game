extends CharacterBody3D
class_name Enemy

@export var move_speed: float = 12.5
@export var detection_range: float = 25.0
@export var attack_range: float = 2.5
@export var gravity: float = 25.0
@export var stop_buffer: float = 0.5
@export var chase_resume_range: float = 7.0
@export var attack_duration: float = 2.0
@export var block_cooldown: float = 2.0
@export var health: int = 100
@export var parry_chance := 0.5
@export var block_chance := 0.7
@export var defense_chance := 0.35
@export var attack_chance := 0.65

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var visual: Node3D = $Basic_Enemy1
@onready var player: Node3D = get_tree().get_first_node_in_group("player") 

@onready var state_machine = $States
@onready var idle_state = $States/Idle
@onready var jog_state = $States/Jog
@onready var attack1_state = $States/Attack1
@onready var block_state = $States/Block
@onready var hurt_state = $States/Hurt
@onready var staggered_state = $States/Staggered
@onready var parry_state = $States/Parry

var playback: AnimationNodeStateMachinePlayback
var attack_timer: float = 0.0
var block_cooldown_timer: float = 0.0

func _ready() -> void:
	animation_tree.active = true
	playback = animation_tree["parameters/playback"]

	for state in state_machine.get_children():
		if state is EnemyState:
			state.enemy = self
			state.state_machine = state_machine
		else:
			push_warning(str(state.name) + " is not an EnemyState.")

	state_machine.switch_state(idle_state)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)

	if player == null:
		move_and_slide()
		return

	state_machine.physics_process(delta)
	move_and_slide()
	
	if block_cooldown_timer > 0.0:
		block_cooldown_timer -= delta

func apply_gravity(delta: float) -> void:
	if !is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

func get_distance_to_player() -> float:
	return global_position.distance_to(player.global_position)

func get_stop_distance() -> float:
	return attack_range + stop_buffer

func move_toward_player() -> void:
	var to_player := player.global_position - global_position
	to_player.y = 0.0

	if to_player.length() > 0.01:
		var distance := to_player.length()
		var dir := to_player.normalized()

		var speed_multiplier: float = clamp((distance - attack_range) / 1.0, 0.25, 1.0)

		velocity.x = dir.x * move_speed * speed_multiplier
		velocity.z = dir.z * move_speed * speed_multiplier
		face_direction(-dir)
	else:
		stop_horizontal_movement()

func stop_horizontal_movement() -> void:
	velocity.x = 0.0
	velocity.z = 0.0

func face_player() -> void:
	var to_player := player.global_position - global_position
	to_player.y = 0.0

	if to_player.length() > 0.01:
		face_direction(-to_player.normalized())

func can_block() -> bool:
	return block_cooldown_timer <= 0.0
	
func face_direction(dir: Vector3) -> void:
	visual.look_at(global_position + dir, Vector3.UP)

func set_locomotion_idle() -> void:
	animation_tree["parameters/locomotion/IdleWalk/blend_amount"] = 0.0
	animation_tree["parameters/locomotion/WalkJog/blend_amount"] = 0.0

func set_locomotion_walk() -> void:
	animation_tree["parameters/locomotion/IdleWalk/blend_amount"] = 1.0
	animation_tree["parameters/locomotion/WalkJog/blend_amount"] = 0.0

func set_locomotion_jog() -> void:
	animation_tree["parameters/locomotion/IdleWalk/blend_amount"] = 1.0
	animation_tree["parameters/locomotion/WalkJog/blend_amount"] = 1.0
	
func receive_hit(hit_data: Dictionary = {}) -> void:
	if state_machine.current_state in [parry_state, hurt_state, staggered_state]:
		return

	if can_attempt_defense() and randf() < defense_chance:
		if randf() < parry_chance:
			parry_hit(hit_data)
		else:
			block_hit(hit_data)
	else:
		take_hit(hit_data)
		
func can_attempt_defense() -> bool:
	return state_machine.current_state in [
		idle_state,
		jog_state,
		block_state
	]
		
func can_parry_hit(hit_data: Dictionary) -> bool:
	return block_state.block_timer > 0.95
	
func parry_hit(hit_data: Dictionary) -> void:
	print("Enemy parried hit")
	block_cooldown_timer = block_cooldown
	state_machine.switch_state(parry_state)

func block_hit(hit_data: Dictionary) -> void:
	print("Enemy blocked hit")
	block_cooldown_timer = block_cooldown
	
	var knock_dir = (global_position - player.global_position)
	knock_dir.y = 0.0
	knock_dir = knock_dir.normalized()
	
	velocity = knock_dir * 4.0
	
	state_machine.switch_state(block_state)
	
func can_defend_against_hit() -> bool:
	return state_machine.current_state == block_state
	
func choose_defense(hit_data: Dictionary) -> void:
	if randf() < parry_chance:
		parry_hit(hit_data)
	else:
		block_hit(hit_data)
	
func receive_parry() -> void:
	print("Enemy was parried")
	state_machine.switch_state(staggered_state)
	
func take_hit(hit_data: Dictionary) -> void:
	var damage: int = hit_data.get("damage", 10)
	health -= damage
	
	print("Enemy took ", damage, " damage. Health: ", health)
	state_machine.switch_state(hurt_state)
	
func choose_combat_action(allow_block := true) -> void:
	var roll := randf()

	if allow_block and roll < block_chance and can_block():
		state_machine.switch_state(block_state)
	elif roll < block_chance + attack_chance:
		state_machine.switch_state(attack1_state)
	else:
		state_machine.switch_state(jog_state)
