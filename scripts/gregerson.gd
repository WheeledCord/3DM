extends Node2D

var spawn_sound := preload("res://sounds/doom.wav")
func _ready():
	print("game.tscn loaded")
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = spawn_sound
	add_child(audio_player)
	audio_player.play()
	# Connect DialogueManager to DialogueUI
	var dialogue_manager = DialogueManager  # Since it's an autoload
	var dialogue_ui = $UI/DialogueUI  # Adjust this path to match your scene
	
	if dialogue_manager and dialogue_ui:
		dialogue_manager.dialogue_ui = dialogue_ui
		print("Dialogue system connected!")
	else:
		print("Error: Could not connect dialogue system")

	if NavigationManager.spawn_door_tag != null:
		_on_level_spawn(NavigationManager.spawn_door_tag)
		
func _on_level_spawn(destination_tag: String):
	var door_path = "Doors/Door_" + destination_tag
	var door = get_node(door_path) as Door
	NavigationManager.trigger_player_spawn(door.global_position, door.spawn_direction)
