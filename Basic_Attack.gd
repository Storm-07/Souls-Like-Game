extends Node

var player
var attack_index = 0  # Tracks the current combo step
var attack_timer = Timer.new()
var max_combo = 4  # Extended combo length to 4 attacks
var attack_tween  # Reference to the Tween node

# Define per-attack delays for smoother combos
const attack_delays = [0.2, 0.25, 0.7, 1.0]  # Last attack is heavier
const attack_distance = 50  # Distance to move per attack
const move_duration = 0.15  # Duration of movement per attack

func _ready():
	add_child(attack_timer)
	attack_timer.one_shot = true
	attack_timer.connect("timeout", Callable(self, "_on_attack_timeout"))

func enter():
	attack_index = 1  # Start with the first attack
	play_attack_animation()
	move_during_attack()
	attack_timer.start(attack_delays[0])  # Start with the first attack's delay
	print("Entered Attack State")

func physics_process(delta):
	# Check if attack button is pressed and we are still within the combo window
	if Input.is_action_just_pressed("basic_attack") and attack_index < max_combo:
		if attack_timer.time_left > 0:
			attack_index += 1  # Proceed to next attack in the combo
			play_attack_animation()
			move_during_attack()  # Add movement on each attack

			# Stop the timer first to apply new delay correctly
			attack_timer.stop()
			attack_timer.start(attack_delays[attack_index - 1])  # Use appropriate delay per attack
	elif attack_timer.time_left <= 0:
		# If timer runs out, exit to idle
		player.state_machine.change_state("Idle")


func move_during_attack():
	# Create a SceneTreeTween on the fly
	var attack_tween = player.create_tween()
	var start_position = player.position
	var target_position = start_position + player.last_direction * attack_distance

	# Tween the player's position smoothly (only 4 arguments)
	attack_tween.tween_property(player, "position", target_position, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)



func play_attack_animation():
	var anim = "attack_" + str(attack_index)
	var animated_sprite = player.get_node("AnimatedSprite2D")
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)

func _on_attack_timeout():
	# Timer expired, transition back to idle if no further input
	if attack_index >= max_combo:
		player.state_machine.change_state("Idle")

func exit():
	attack_index = 0  # Reset combo
	attack_timer.stop()
	print("Exited Attack State")
