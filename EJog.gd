extends EnemyState

func enter() -> void:
	enemy.playback.travel("locomotion")
	enemy.set_locomotion_jog()

func physics_process(delta: float) -> void:
	var distance : float = enemy.get_distance_to_player()

	if distance > enemy.detection_range:
		state_machine.switch_state(enemy.idle_state)
		return

	if distance <= enemy.attack_range:
		enemy.stop_horizontal_movement()
		enemy.face_player()
		enemy.choose_combat_action()
		return

	enemy.move_toward_player()

	if distance <= enemy.get_stop_distance():
		enemy.set_locomotion_walk()
	else:
		enemy.set_locomotion_jog()
