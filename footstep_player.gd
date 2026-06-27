extends AudioStreamPlayer3D

var footstep_sounds = [
	preload("res://sounds/Footsteps/footstep_01.wav"),
	preload("res://sounds/Footsteps/footstep_02.wav"),
	preload("res://sounds/Footsteps/footstep_03.wav"),
	preload("res://sounds/Footsteps/footstep_04.wav"),
	preload("res://sounds/Footsteps/footstep_05.wav"),
	preload("res://sounds/Footsteps/footstep_06.wav")
]

func play_random_footstep():

	if playing:
		return

	stream = footstep_sounds.pick_random()

	pitch_scale = randf_range(0.97, 1.03)
	play()
