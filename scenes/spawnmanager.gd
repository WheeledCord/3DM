extends Node

func _ready():
	if NavigationManager.spawn_door_tag != null:
		_on_level_spawn(NavigationManager.spawn_door_tag)
	else:
		# Fallback to a default position if no tag is provided
		NavigationManager.trigger_player_spawn(Vector2(0, 0), "up")

func _on_level_spawn(destination_tag: String):
	var door_path = "Doors/Door_" + destination_tag

	if not has_node(door_path):
		# Fallback to a default position if the door is missing
		NavigationManager.trigger_player_spawn(Vector2(0, 0), "up")
		return

	var door = get_node(door_path) as Door
	if door:
		NavigationManager.trigger_player_spawn(door.global_position, door.spawn_direction)
