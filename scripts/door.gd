extends Area2D

class_name Door

@export var destination_level_tag: String
@export var destination_door_tag: String
@export var spawn_direction = "up"

@onready var spawn = $spawn

var player_nearby = false  # tracks if the player is near the door

func _on_body_entered(body):
	if body is Player:
		player_nearby = true  # mark the player as nearby

func _on_body_exited(body):
	if body is Player:
		player_nearby = false  # mark the player as no longer nearby

func _process(delta):
	if player_nearby and Input.is_action_just_pressed("interact"):
		NavigationManager.go_to_level(destination_level_tag, destination_door_tag)
