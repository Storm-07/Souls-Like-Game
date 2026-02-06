extends SpringArm3D

@export var stick_sensitivity: float = 5.0
@export var lerp_speed: float = 10.0  # Higher = snappier

# These control vertical tilt limits
@export var min_vertical_angle := -PI / 2
@export var max_vertical_angle := PI / 4

# Internal values
var target_rotation := Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	target_rotation = rotation  


func _process(delta):
	# Read gamepad input from right stick
	var input_x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	var input_y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	
	# Update target rotation
	target_rotation.y -= input_x * stick_sensitivity * delta
	target_rotation.x = clamp(target_rotation.x - input_y * stick_sensitivity * delta, min_vertical_angle, max_vertical_angle)
	
	# Interpolate toward target rotation for smooth movement
	rotation.x = lerp_angle(rotation.x, target_rotation.x, lerp_speed * delta)
	rotation.y = lerp_angle(rotation.y, target_rotation.y, lerp_speed * delta)
