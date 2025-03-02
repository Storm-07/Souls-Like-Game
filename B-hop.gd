extends Node

var player
var bhop_duration = 0.67  # B-hop duration
var bhop_timer = 0.0  # Tracks time
var max_jump_height = -2500  # Max height for b-hop
var min_jump_height = -250  # Ground level
var base_bhop_speed = 500  # Default speed
var boost_bhop_speed = 650  # Boosted speed for perfect timing
var current_bhop_speed = 500  # Track current speed
var can_chain_bhop = false  # Check if chaining is allowed
var hop_window = 0.2  # Time window to chain b-hop perfectly

func enter():
	if player == null:
		return
	
	# Start b-hop with default speed
	bhop_timer = bhop_duration
	current_bhop_speed = base_bhop_speed
	can_chain_bhop = false  # Reset chain flag
	
	# Play b-hop animation based on direction
	var animated_sprite = player.get_node("AnimatedSprite2D")
	var bhop_animation = get_bhop_animation(player.last_direction)
	animated_sprite.play(bhop_animation)
	
	print("Started B-hop")

func physics_process(delta):
	# Check if b-hop is still ongoing
	if bhop_timer > 0:
		bhop_timer -= delta
		
		# Capture horizontal movement input
		var direction = player.get_input().normalized()
		
		# Apply horizontal movement based on input direction
		if direction.length() > 0:
			player.velocity = direction * current_bhop_speed
		else:
			# Maintain forward momentum if no input
			player.velocity = player.last_direction * current_bhop_speed

		# Move player based on updated velocity
		player.move_and_slide()

		# Calculate progress of the b-hop (0.0 to 1.0)
		var progress = 1.0 - bhop_timer / bhop_duration
		
		# Enable chaining if within the hop_window before hop ends
		if bhop_timer < hop_window:
			can_chain_bhop = true
		
		# Apply ease-out effect to simulate fast rise and slow fall
		var height_offset = lerp(min_jump_height, max_jump_height, sin(progress * PI))
		player.get_node("AnimatedSprite2D").position.y = height_offset
		
		# Detect b-hop input during the chain window
		if can_chain_bhop and Input.is_action_just_pressed("bhop"):
			print("Chained B-hop!")
			current_bhop_speed = boost_bhop_speed  # Boost speed for chained b-hop
			player.state_machine.change_state("B-hop")  # Chain b-hop
			return

	else:
		# End of b-hop, reset Y position
		player.get_node("AnimatedSprite2D").position.y = min_jump_height
		
		# Check if input is pressed immediately after landing
		if Input.is_action_just_pressed("bhop"):
			print("New B-hop with default speed")
			current_bhop_speed = base_bhop_speed  # Reset speed for normal b-hop
			player.state_machine.change_state("B-hop")
		else:
			player.state_machine.change_state("Idle")

func exit():
	# Reset Y position to ground level
	player.get_node("AnimatedSprite2D").position.y = min_jump_height

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
