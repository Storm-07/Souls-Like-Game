extends Area3D

var hit_areas_this_attack := {}
@onready var enemy = $".."
@onready var attack_hitbox: Area3D = $"."
@onready var sword: Node3D = $"../Basic_Enemy1/metarig/Skeleton3D/hand_R/sword"

@export var hitbox_local_offset := Vector3(0, 0, 0.6)

func _ready() -> void:
	monitoring = false
	area_entered.connect(_on_area_entered)
	
func _physics_process(delta):
	var t := sword.global_transform
	t.basis = t.basis.orthonormalized()
	attack_hitbox.global_transform = t
	attack_hitbox.global_position = sword.to_global(hitbox_local_offset)
	attack_hitbox.scale = Vector3.ONE

func start_attack() -> void:
	hit_areas_this_attack.clear()
	disable_hitbox()

func enable_hitbox() -> void:
	print("enemy sword hitbox enabled")
	monitoring = true
	
	await get_tree().physics_frame
	
	var areas := get_overlapping_areas()
	print("Overlapping areas on enable: ", areas)
	
	for area in areas:
		_try_hit_area(area)

func disable_hitbox() -> void:
	monitoring = false

func end_attack() -> void:
	disable_hitbox()
	hit_areas_this_attack.clear()

func _on_area_entered(area: Area3D) -> void:
	_try_hit_area(area)

func _try_hit_area(area: Area3D) -> void:
	if area.name != "PlayerHurtBox":
		return

	if hit_areas_this_attack.has(area):
		return

	print("Enemy sword saw area: ", area.name)

	hit_areas_this_attack[area] = true

	print("Enemy hit player.")

	var player = area.get_parent()

	if player.has_method("receive_hit"):
		player.receive_hit({
			"damage": 10,
			"attacker": enemy
		})
	else:
		print("player parent has no receive_hit method: ", player.name)
