extends SpringArm3D

@export var stick_sensitivity: float = 5.0
@export var lerp_speed: float = 10.0
@export var min_vertical_angle := -PI / 2
@export var max_vertical_angle := PI / 4

var lock_on_target: Node3D = null
@export var lock_on_enabled := false
@export var lock_on_lerp_speed := 8.0
@export var lock_on_min_pitch := deg_to_rad(-25.0)
@export var lock_on_max_pitch := deg_to_rad(15.0)

var target_pitch := 0.0
var target_yaw := 0.0

@onready var yaw_pivot: Node3D = get_parent() as Node3D

func _ready():
	target_pitch = rotation.x
	target_yaw = yaw_pivot.rotation.y

func _process(delta):
	var input_x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	var input_y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")

	if lock_on_enabled and lock_on_target != null:
		var target_point := lock_on_target.global_position + Vector3.UP * 1.4
		var to_target: Vector3 = target_point - yaw_pivot.global_position

		target_yaw = atan2(-to_target.x, -to_target.z)

		var flat_distance := Vector2(to_target.x, to_target.z).length()
		target_pitch = clamp(
			atan2(to_target.y, flat_distance),
			lock_on_min_pitch,
			lock_on_max_pitch
		)
	else:
		target_yaw -= input_x * stick_sensitivity * delta
		target_pitch = clamp(target_pitch - input_y * stick_sensitivity * delta, min_vertical_angle, max_vertical_angle)

	rotation.x = lerp_angle(rotation.x, target_pitch, lerp_speed * delta)
	yaw_pivot.rotation.y = lerp_angle(yaw_pivot.rotation.y, target_yaw, lerp_speed * delta)
