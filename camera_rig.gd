extends Node3D

@export var player_path: NodePath
@export var follow_offset: Vector3 = Vector3(0, 1.0, 0)

@export var follow_lerp_speed := 8.0
@export var soft_zone_up := 3.6
@export var soft_zone_down := 0.4
@export var recenter_lerp_speed := 3.0

var follow_pos: Vector3
@onready var player: Node3D = get_node_or_null(player_path) as Node3D

func _ready():
	follow_pos = global_position

func _process(delta):
	if player == null:
		return

	var desired := player.global_position + follow_offset

	# Smooth XZ follow
	follow_pos.x = lerp(follow_pos.x, desired.x, follow_lerp_speed * delta)
	follow_pos.z = lerp(follow_pos.z, desired.z, follow_lerp_speed * delta)

	# Vertical soft zone
	var dy := desired.y - follow_pos.y
	if dy > soft_zone_up:
		follow_pos.y += (dy - soft_zone_up)
	elif dy < -soft_zone_down:
		follow_pos.y += (dy + soft_zone_down)
	else:
		follow_pos.y = lerp(follow_pos.y, desired.y, recenter_lerp_speed * delta)

	global_position = follow_pos
