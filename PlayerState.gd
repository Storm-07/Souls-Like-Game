extends Node

class_name PlayerState  # This makes it reusable from anywhere

@onready var player =  $"." # Reference to the main player node (CharacterBody3D)
var state_machine  # Reference to the state machine controller

func enter(): pass
func exit(): pass
func physics_process(delta): pass

# THIS IS NOT AN ATTACHED SCRIPT PLEASE REMEMBER TO CREATE THIS AS A BASE CLASS FOR ENTITIES 
