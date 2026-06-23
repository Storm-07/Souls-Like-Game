extends EnemyState

@onready var sword_hitbox = $"../../AttackHitBox"

@export var hitbox_start_t := 0.6
@export var hitbox_end_t := 0.9

var hitbox_enabled := false
var hitbox_used := false

func enter() -> void:
	enemy.attack_timer = enemy.attack_duration
	hitbox_enabled = false
	hitbox_used = false

	sword_hitbox.start_attack()
	enemy.playback.travel("attack1")

func physics_process(delta: float) -> void:
	enemy.stop_horizontal_movement()
	enemy.face_player()

	enemy.attack_timer -= delta
	var elapsed := enemy.attack_duration - enemy.attack_timer

	if enemy.attack_timer <= 0.0:
		sword_hitbox.end_attack()
		hitbox_enabled = false
		hitbox_used = false

		var distance: float = enemy.get_distance_to_player()

		if distance <= enemy.attack_range:
			enemy.choose_combat_action()
		elif distance <= enemy.chase_resume_range:
			state_machine.switch_state(enemy.jog_state)
		else:
			state_machine.switch_state(enemy.idle_state)

		return

	if not hitbox_used and elapsed >= hitbox_start_t:
		hitbox_used = true
		hitbox_enabled = true
		sword_hitbox.enable_hitbox()

	if hitbox_enabled and elapsed >= hitbox_end_t:
		hitbox_enabled = false
		sword_hitbox.disable_hitbox()
