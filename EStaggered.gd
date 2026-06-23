extends EnemyState

@export var stagger_duration := 0.7

func enter() -> void:
	print("ENEMY ENTERED STAGGER")
	enemy.stop_horizontal_movement()
	enemy.playback.travel("Stagger")

	await get_tree().create_timer(stagger_duration).timeout

	if state_machine.current_state == self:
		state_machine.switch_state(enemy.jog_state)
