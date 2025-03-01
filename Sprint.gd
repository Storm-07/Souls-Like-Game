extends Node

var player

func enter():
	if player == null:
		return
	
	var direction = player.get_input()
	update_animation(direction)  # Ensure the correct sprint animation plays when entering

func physics_process(delta):
	var direction = player.get_input()

	# If no input, apply friction
	if direction.length() == 0:
		player.velocity = player.velocity.move_toward(Vector2.ZERO, player.deceleration * 0.8 * delta)
		if player.velocity.length() < 10:
			player.velocity = Vector2.ZERO
			player.state_machine.change_state("Idle")
		player.move_and_slide()
		return

	# Detect sharp reversals for skidding
	if should_skid(direction):
		player.state_machine.change_state("Skid")
		return

	# Normal sprinting movement
	player.velocity = player.velocity.lerp(direction * player.max_speed * player.sprintspeed, 0.09)
	player.move_and_slide()
	update_animation(direction)

	# Toggle sprinting
	if Input.is_action_just_pressed("sprint"):
		player.sprinting = false
		player.state_machine.change_state("Walk")

func should_skid(direction) -> bool:
	# Ensure player is moving fast enough
	if player.velocity.length() < player.max_speed * 0.75:
		return false
	
	# Calculate dot product between new input and current velocity
	var dot_product = direction.normalized().dot(player.velocity.normalized())

	# If dot product is negative, player is sharply reversing direction
	if dot_product < -0.9:
		player.last_direction = player.velocity.normalized()  # Store the last true movement direction
		return true
	
	return false


func update_animation(direction):
	var anim = ""
	var animated_sprite = player.get_node("AnimatedSprite2D")

	if direction.y > 0 and direction.x > 0:
		anim = "run_down_right"
	elif direction.y > 0 and direction.x < 0:
		anim = "run_down_left"
	elif direction.y < 0 and direction.x > 0:
		anim = "run_up_right"
	elif direction.y < 0 and direction.x < 0:
		anim = "run_up_left"
	elif direction.y > 0:
		anim = "run_down"
	elif direction.y < 0:
		anim = "run_up"
	elif direction.x > 0:
		anim = "run_right"
	elif direction.x < 0:
		anim = "run_left"

	if anim != "" and animated_sprite:
		animated_sprite.play(anim)

func exit():
	pass  # Nothing special needed for now
