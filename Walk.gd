extends Node

var player

func enter():
	if player == null:
		return

func physics_process(delta):
	var direction = player.get_input()

	# If no input, apply friction to gradually slow down
	if direction.length() == 0:
		player.velocity = player.velocity.move_toward(Vector2.ZERO, player.deceleration * delta)

		# If speed is very low, transition to idle state
		if player.velocity.length() < 10:
			player.velocity = Vector2.ZERO
			player.state_machine.change_state("Idle")
		player.move_and_slide()
		return

	# Determine speed multiplier (walking or sprinting)
	var speed_mult = 1
	if player.sprinting:
		speed_mult = player.sprintspeed

	# Apply momentum effect for smooth direction changes
	player.velocity = player.velocity.lerp(direction * player.max_speed * speed_mult, 0.2)

	player.move_and_slide()
	update_animation(direction)

	# Toggle sprinting
	if Input.is_action_just_pressed("sprint"):
		player.sprinting = not player.sprinting
		player.state_machine.change_state("Sprint" if player.sprinting else "Walk")

func update_animation(direction):
	var anim = ""
	var animated_sprite = player.get_node("AnimatedSprite2D")

	if direction.y > 0 and direction.x > 0:
		anim = "walk_down_right"
	elif direction.y > 0 and direction.x < 0:
		anim = "walk_down_left"
	elif direction.y < 0 and direction.x > 0:
		anim = "walk_up_right"
	elif direction.y < 0 and direction.x < 0:
		anim = "walk_up_left"
	elif direction.y > 0:
		anim = "walk_down"
	elif direction.y < 0:
		anim = "walk_up"
	elif direction.x > 0:
		anim = "walk_right"
	elif direction.x < 0:
		anim = "walk_left"

	if anim != "" and animated_sprite:
		animated_sprite.play(anim)

func exit():
	pass  # Nothing special needed for now
