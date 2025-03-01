extends Node

var player
var skid_timer = 0.15  # Adjust duration as needed
var old_direction = Vector2.ZERO  # Store direction before skid

func enter():
	if player == null:
		return

	# Correctly retrieve the old movement direction from the player
	old_direction = player.last_direction  # Now this is correctly set before the state transition

	# Reduce speed to emphasize the skid effect
	player.velocity *= 0.4

	# Determine and play the correct skid animation
	var new_direction = player.get_input().normalized()

	# Ensure we only play a skid animation if there’s valid movement input
	if new_direction.length() > 0:
		var skid_animation = get_skid_animation(old_direction, new_direction)
		if skid_animation != "":
			player.animated_sprite.play(skid_animation)

func physics_process(delta):
	skid_timer -= delta
	if skid_timer <= 0:
		player.state_machine.change_state("Walk" if not player.sprinting else "Sprint")
		skid_timer = 0.15

	player.move_and_slide()

func exit():
	pass  # No cleanup needed

# Determine the correct skid animation based on direction change
func get_skid_animation(old_dir: Vector2, new_dir: Vector2) -> String:
	var old_name = get_direction_name(old_dir)
	var new_name = get_direction_name(new_dir)

	# Allow slight variations by treating close directions as valid
	if old_name == "" or new_name == "":
		return ""

	# If the turn isn't perfect, allow nearby skid animations
	if abs(old_dir.angle_to(new_dir)) > deg_to_rad(100):  # Before was strict 180°, now allows ~100°
		return "skid_%s_%s" % [old_name, new_name]
	else:
		return ""


# Helper function to get direction name based on a Vector2
func get_direction_name(direction: Vector2) -> String:
	# Allow slight diagonal movement but still prioritize cardinal directions
	if abs(direction.x) < 0.04:  # Instead of 0.2, try 0.15 for more diagonal detection
		direction.x = 0
	if abs(direction.y) < 0.04:
		direction.y = 0

# If x and y are still both present, register it as a diagonal
	if direction.y > 0 and direction.x > 0:
		return "DR"
	elif direction.y > 0 and direction.x < 0:
		return "DL"
	elif direction.y < 0 and direction.x > 0:
		return "UR"
	elif direction.y < 0 and direction.x < 0:
		return "UL"
	# Prioritize cardinal directions
	if abs(direction.x) > abs(direction.y):  
		if direction.x > 0:
			return "R"
		elif direction.x < 0:
			return "L"
	elif abs(direction.y) > abs(direction.x):  
		if direction.y > 0:
			return "D"
		elif direction.y < 0:
			return "U"

	return ""  # Default fallback

