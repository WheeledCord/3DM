extends Node2D

var spawn_sound := preload("res://sounds/doom.wav")
func _ready():
	print("game.tscn loaded")
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = spawn_sound
	add_child(audio_player)
	audio_player.play()

	if NavigationManager.spawn_door_tag != null:
		_on_level_spawn(NavigationManager.spawn_door_tag)
		
func _on_level_spawn(destination_tag: String):
	var door_path = "Doors/Door_" + destination_tag
	var door = get_node(door_path) as Door
	NavigationManager.trigger_player_spawn(door.global_position, door.spawn_direction)
