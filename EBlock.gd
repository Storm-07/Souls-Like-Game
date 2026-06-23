extends EnemyState

var _blend_pos: Vector2 = Vector2.ZERO
var block_timer: float = 0.0

const PATH_BLOCK_BLEND_POS := "parameters/Block/Block Blend Space/blend_position"

func enter() -> void:
	block_timer = 1.25
	
	enemy.playback.travel("Block") 
	enemy.stop_horizontal_movement()
	enemy.face_player()

	_blend_pos = Vector2.ZERO
	enemy.animation_tree.set(PATH_BLOCK_BLEND_POS, _blend_pos)

func physics_process(delta: float) -> void:
	block_timer -= delta
	
	enemy.stop_horizontal_movement()
	enemy.face_player()

	_blend_pos = _blend_pos.lerp(Vector2.ZERO, 12.0 * delta)
	enemy.animation_tree.set(PATH_BLOCK_BLEND_POS, _blend_pos)

	if block_timer <= 0.0:
		enemy.block_cooldown_timer = enemy.block_cooldown
		
		var distance := enemy.get_distance_to_player()
		if distance <= enemy.attack_range:
			enemy.choose_combat_action(false)
		else:
			state_machine.switch_state(enemy.jog_state)
		return
		
		# ok so he just doesn't have any condition to block yet huh. maybe it can be after an initial attack? or like he'll get within a certain
		#range and then starts blocking, as if he's cautiously approaching you

func apply_block_knockback(hit_data: Dictionary) -> void:
	var knock_dir = (enemy.global_position - enemy.player.global_position)
	knock_dir.y = 0.0
	
	if knock_dir.length() > 0.01:
		enemy.velocity = knock_dir.normalized() * 4.0
