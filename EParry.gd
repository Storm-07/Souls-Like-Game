extends EnemyState

@export var parry_duration := 0.45
var parry_timer := 0.0

func enter() -> void:
	parry_timer = parry_duration
	
	enemy.stop_horizontal_movement()
	enemy.face_player()
	enemy.playback.travel("Parry1")

func physics_process(delta: float) -> void:
	parry_timer -= delta
	
	enemy.stop_horizontal_movement()
	enemy.face_player()

	if parry_timer <= 0.0:
		var distance := enemy.get_distance_to_player()

		if distance <= enemy.attack_range:
			enemy.choose_combat_action(false)
		else:
			state_machine.switch_state(enemy.jog_state)
		return
	
	if parry_timer <= 0.0:
		print("EXITING PARRY STATE")
