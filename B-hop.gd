extends Node

var player
var bhop_duration = 0.67  # How long the b-hop lasts
var bhop_timer = 0.0  # Tracks time
var max_jump_height = -2500  # Maximum height for b-hop
var min_jump_height = -400  # Ground level for b-hop

func enter():
	if player == null:
		return
	
	# Start b-hop
	bhop_timer = bhop_duration
	
	# Play b-hop animation based on direction
	var animated_sprite = player.get_node("AnimatedSprite2D")
	var bhop_animation = get_bhop_animation(player.last_direction)
	animated_sprite.play(bhop_animation)

func physics_process(delta):
	# Check if b-hop is still ongoing
	if bhop_timer > 0:
		bhop_timer -= delta
		
		# Calculate progress of the b-hop (0.0 to 1.0)
		var progress = 1.0 - bhop_timer / bhop_duration
		
		# Apply ease-out effect to simulate fast rise and slow fall
		var height_offset = lerp(min_jump_height, max_jump_height, sin(progress * PI))
		
		# Adjust Y position of AnimatedSprite2D to simulate jump
		player.get_node("AnimatedSprite2D").position.y = height_offset
		
	else:
		# End of b-hop, reset Y position
		player.get_node("AnimatedSprite2D").position.y = min_jump_height
		
		# Change state back to Idle
		player.state_machine.change_state("Idle")

# Determine b-hop animation based on direction
func get_bhop_animation(direction: Vector2) -> String:
	if direction.x > 0.5 and abs(direction.y) < 0.5:
		return "bhop_right"
	elif direction.x < -0.5 and abs(direction.y) < 0.5:
		return "bhop_left"
	elif direction.y > 0.5 and abs(direction.x) < 0.5:
		return "bhop_down"
	elif direction.y < -0.5 and abs(direction.x) < 0.5:
		return "bhop_up"
	elif direction.x > 0 and direction.y > 0:
		return "bhop_down_right"
	elif direction.x > 0 and direction.y < 0:
		return "bhop_up_right"
	elif direction.x < 0 and direction.y > 0:
		return "bhop_down_left"
	elif direction.x < 0 and direction.y < 0:
		return "bhop_up_left"
	else:
		return "bhop_down"  # Default animation if direction is ambiguous

func exit():
	# Reset Y position to ground level
	player.get_node("AnimatedSprite2D").position.y = min_jump_height
