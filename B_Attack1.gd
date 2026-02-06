extends PlayerState
class_name AttackState

@export var attack_anims: Array[String] = [
	"b_slash1",  # first slash
	"b_slash2",  # second slash
	"b_slash3"   # third slash
]

@export var chain_window_start: float = 0.2   # seconds into anim when we start accepting next input
@export var chain_window_end: float = 0.6     # when we stop accepting it
@export var return_to_walk: bool = true       # go back to walk instead of idle if moving
@export var keep_gravity: bool = true

var _combo_index: int = 0
var _time: float = 0.0
var _queued_next: bool = false
var _current_anim_length: float = 0.0

func enter() -> void:
	_combo_index = 0
	_time = 0.0
	_queued_next = false

	# stop manual movement, root motion takes over
	player.velocity.x = 0.0
	player.velocity.z = 0.0

	_play_current_attack()


func _play_current_attack() -> void:
	var anim_name := attack_anims[_combo_index]
	# Tell the AnimationTree's state machine to go to this attack
	if player.animation_state.get_current_node() != anim_name:
		player.animation_state.travel(anim_name)

	# Grab duration from AnimationPlayer so we know when it "ends"
	if player.anim_player.has_animation(anim_name):
		_current_anim_length = player.anim_player.get_animation(anim_name).length
	else:
		_current_anim_length = 0.8  # fallback guess so it still works


func physics_process(delta: float) -> void:
	_time += delta

	# 1) Apply root motion each frame
	#_apply_root_motion(delta)

	# 2) Watch for queued combo input
	if Input.is_action_just_pressed("B_Attack1"):
		if _time >= chain_window_start and _time <= chain_window_end:
			_queued_next = true

	# 3) Decide what happens when this attack is done
	var finished: bool = (_time >= _current_anim_length)

	if finished:
		if _queued_next and _combo_index < attack_anims.size() - 1:
			# go to next attack in combo
			_combo_index += 1
			enter()  # restart state logic with new index
		else:
			# combo ends, reset index and go back to locomotion
			_combo_index = 0
			_exit_to_locomotion()


func _exit_to_locomotion() -> void:
	if return_to_walk and player.input_dir != Vector2.ZERO:
		state_machine.switch_state(player.walk_state)
	else:
		state_machine.switch_state(player.idle_state)
