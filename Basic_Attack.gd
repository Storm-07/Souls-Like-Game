extends Node

var player
var attack_index = 1  # Tracks the current combo step
var attack_timer = Timer.new()
var combo_timeout_timer = Timer.new()  # NEW: Timer to end combo on inactivity
var max_combo = 4  # Extended combo length to 4 attacks
var attack_tween  # Reference to the Tween node

# Define per-attack delays for smoother combos
const attack_delays = [0.1, 0.1, 0.2, 0.4]  # Last attack is heavier
const attack_distance = 72  # Distance to move per attack
const move_duration = 0.25  # Duration of movement per attack
const combo_timeout = 0.5  # NEW: Time before combo cancels if no input

func _ready():
	add_child(attack_timer)
	add_child(combo_timeout_timer)  # NEW: Add combo timeout timer
	attack_timer.one_shot = true
	combo_timeout_timer.one_shot = true  # NEW: Only triggers once
	attack_timer.connect("timeout", Callable(self, "_on_attack_timeout"))
	combo_timeout_timer.connect("timeout", Callable(self, "_on_combo_timeout"))  # NEW: Handles mid-combo timeout

func enter():
	attack_index = 1  # Start with the first attack
	play_attack_animation()
	move_during_attack()
	attack_timer.start(attack_delays[0])  # Start with the first attack's delay
	combo_timeout_timer.start(combo_timeout)  # NEW: Start timeout in case of inactivity
	print("Entered Attack State")

func physics_process(delta):
	# Only allow attacks if the timer has finished
	if Input.is_action_just_pressed("basic_attack") and attack_index < max_combo and attack_timer.is_stopped():
		attack_index += 1  # Move to next attack
		play_attack_animation()
		move_during_attack()  # Move player slightly forward

		# Debug: Check which attack index and delay is used
		print("Attack Index:", attack_index, "Using Delay:", attack_delays[attack_index - 1])

		# Start timer and WAIT for it to finish before allowing next attack
		attack_timer.start(attack_delays[attack_index - 1])
		combo_timeout_timer.start(combo_timeout)  # NEW: Restart timeout timer for each attack
		await attack_timer.timeout  # ✅ This pauses execution until timer finishes

		# Check if combo is done and exit
		if attack_index >= max_combo:
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

# **NEW: Handles automatic combo cancellation due to inactivity**
func _on_combo_timeout():
	if attack_index < max_combo:  # If we haven't finished the combo
		print("Combo timed out, returning to Idle")
		player.state_machine.change_state("Idle")

func _on_attack_timeout():
	# If the player stops attacking, let combo timeout handle it
	if attack_index >= max_combo:
		player.state_machine.change_state("Idle")

func exit():
	attack_index = 0  # Reset combo
	attack_timer.stop()
	combo_timeout_timer.stop()  # NEW: Stop timeout timer to avoid lingering effects
	print("Exited Attack State")
