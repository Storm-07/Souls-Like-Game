extends Area3D

@export var spawn_path: NodePath
@onready var spawn: Node3D = get_node(spawn_path) as Node3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# If you use groups, this is the cleanest filter:
	if not body.is_in_group("player"):
		return

	# Teleport:
	if body is Node3D:
		body.global_position = spawn.global_position

	# Reset motion (common for CharacterBody3D / RigidBody3D)
	if body is CharacterBody3D:
		body.velocity = Vector3.ZERO
	elif body is RigidBody3D:
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
# collision layer: 3
# mask layer 2
