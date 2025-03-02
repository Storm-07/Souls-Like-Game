extends Node

var player
var dodge_duration = 0.3  # Normal dodge duration
var dodge_speed = 500  # Normal dodge speed
var dodge_timer = 0.0  # Tracks time
var dodge_direction = Vector2.ZERO  # Stores dodge direction

func enter():
	if player == null:
		return

	# Check if sprinting to adjust speed and duration
	if player.sprinting:
		dodge_speed = 650  # Faster dodge if sprinting
		dodge_duration = 0.4  # Slightly longer dodge if sprinting
	else:
		dodge_speed = 500  # Normal dodge speed
		dodge_duration = 0.3  # Normal dodge duration

	# **Determine dodge direction**
	var movement_input = player.get_input()
	if movement_input.length() == 0:
		dodge_direction = player.last_direction  # Dodge in facing direction if still
	else:
		dodge_direction = movement_input.normalized()  # Dodge in input direction if moving

	# Apply dodge movement
	player.velocity = dodge_direction * dodge_speed

	# Play dodge animation
	var animated_sprite = player.get_node("AnimatedSprite2D")
	animated_sprite.play("dodge")  # Make sure you have a dodge animation

	# Start dodge timer
	dodge_timer = dodge_duration

func physics_process(delta):
	# Move player during dodge
	player.move_and_slide()

	# Countdown timer
	dodge_timer -= delta
	if dodge_timer <= 0:
		# **Check if movement input exists after dodging**
		var movement_input = player.get_input()
		player.dodged = false  # Allow dodging again
		if movement_input.length() > 0:
			if player.sprinting:
				player.state_machine.change_state("Sprint")  # Return to Sprint if sprinting
			else:
				player.state_machine.change_state("Walk")  # Return to Walk if moving
		else:
			player.state_machine.change_state("Idle")  # Return to Idle if no input

func exit():
	# Stop movement at end of dodge
	player.velocity = Vector2.ZERO
