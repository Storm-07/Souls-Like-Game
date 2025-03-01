extends Node

var player

func enter():
	if player == null:
		return

	# Ensure a smooth transition instead of snapping to stop
	player.velocity = player.velocity.move_toward(Vector2.ZERO, player.deceleration * 0.5)

	var animated_sprite = player.get_node("AnimatedSprite2D")
	var direction = player.last_direction
	var idle_animation = get_idle_animation(direction)
	animated_sprite.play(idle_animation)

func physics_process(delta):
	# Check if sprint toggle is pressed
	if Input.is_action_just_pressed("sprint"):
		player.sprinting = not player.sprinting  # Toggle sprint mode

	# Movement input check
	if player.get_input().length() > 0:
		if player.sprinting:
			player.state_machine.change_state("Sprint")
		else:
			player.state_machine.change_state("Walk")

func exit():
	pass  # Nothing special needed for now

# Determine correct idle animation
func get_idle_animation(direction: Vector2) -> String:
	if direction.y < -0.5:
		if direction.x < -0.5:
			return "idle_up_left"
		elif direction.x > 0.5:
			return "idle_up_right"
		else:
			return "idle_up"
	elif direction.y > 0.5:
		if direction.x < -0.5:
			return "idle_down_left"
		elif direction.x > 0.5:
			return "idle_down_right"
		else:
			return "idle_down"
	else:
		if direction.x < -0.5:
			return "idle_left"
		elif direction.x > 0.5:
			return "idle_right"
		else:
			return "idle_right"
