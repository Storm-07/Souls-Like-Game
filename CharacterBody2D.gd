extends CharacterBody2D

@onready var state_machine = $StateMachine
@onready var animated_sprite = $AnimatedSprite2D
@onready var walking_sound = $WalkingNoise
@onready var dust_particles = $DustParticles

const max_speed = 400
const sprintspeed = 1.8
const deceleration = 2000
var deadzone = 0.2
var last_direction = Vector2.RIGHT  # Default to right-facing

var paused = false
var sprinting = false

func _physics_process(delta):
	if paused:
		return
	state_machine.process_physics(delta)

func get_input():
	var input_vector = Vector2.ZERO

	# Game controller input
	var joy_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var joy_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)

	# Apply deadzone to joystick input
	if abs(joy_x) > deadzone:
		input_vector.x += joy_x
	if abs(joy_y) > deadzone:
		input_vector.y += joy_y

	# Store the last direction only if there is meaningful movement
	if input_vector.length() > deadzone:
		last_direction = input_vector.normalized()  # Preserve the last moving direction

	return input_vector  # Keep raw joystick movement
