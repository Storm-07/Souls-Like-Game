extends SpringArm3D

@export var stick_sensitivity: float = 5.0
@export var lerp_speed: float = 10.0
@export var min_vertical_angle := -PI / 2
@export var max_vertical_angle := PI / 4

var target_pitch := 0.0
var target_yaw := 0.0

@onready var yaw_pivot: Node3D = get_parent() as Node3D

func _ready():
	target_pitch = rotation.x
	target_yaw = yaw_pivot.rotation.y

func _process(delta):
	var input_x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	var input_y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")

	target_yaw -= input_x * stick_sensitivity * delta
	target_pitch = clamp(target_pitch - input_y * stick_sensitivity * delta, min_vertical_angle, max_vertical_angle)

	# pitch on the arm
	rotation.x = lerp_angle(rotation.x, target_pitch, lerp_speed * delta)
	# yaw on the pivot
	yaw_pivot.rotation.y = lerp_angle(yaw_pivot.rotation.y, target_yaw, lerp_speed * delta)
