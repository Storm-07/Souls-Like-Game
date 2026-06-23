# EnemyHurtState.gd
extends EnemyState

@export var hurt_duration: float = 0.35
var timer: float = 0.0

func enter() -> void:
	timer = hurt_duration
	enemy.stop_horizontal_movement()
	print("Entered Hurt State")

	# Temporary: use block animation or idle until you import a hurt animation
	enemy.playback.travel("Hurt")

func physics_process(delta: float) -> void:
	timer -= delta
	enemy.face_player()

	if timer <= 0.0:
		state_machine.switch_state(enemy.idle_state)

func exit() -> void:
	pass
