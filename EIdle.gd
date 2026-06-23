extends EnemyState

func enter() -> void:
	enemy.playback.travel("locomotion") 
	enemy.set_locomotion_idle()

func physics_process(delta: float) -> void:
	enemy.stop_horizontal_movement()

	var distance : float = enemy.get_distance_to_player()

	if distance <= enemy.detection_range and distance > enemy.chase_resume_range:
		state_machine.switch_state(enemy.jog_state)
		return

	if distance <= enemy.chase_resume_range:
		enemy.face_player()
