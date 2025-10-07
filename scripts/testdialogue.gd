# NPC.gd - Example NPC that can start dialogue
extends CharacterBody2D

@export var dialogue_file: String = "res://dialogues/npc_example.json"
var dialogue_data: Dictionary
var player_in_range: bool = false
var player_body: Node = null  # Track the specific player

func _ready():
	# Load dialogue data
	load_dialogue()

func load_dialogue():
	if dialogue_file != "":
		var file = FileAccess.open(dialogue_file, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				dialogue_data = json.data
				print("Dialogue loaded successfully!")
			else:
				print("Error parsing dialogue JSON: ", json_string)
		else:
			print("Could not open dialogue file: ", dialogue_file)

func _input(event):
	if event.is_action_pressed("interact") and player_in_range and player_body:
		start_dialogue()

func start_dialogue():
	var dialogue_manager = DialogueManager  # Using autoload
	if dialogue_manager and dialogue_data:
		print("Starting dialogue...")
		dialogue_manager.start_dialogue(dialogue_data)
	else:
		print("Error: DialogueManager or dialogue_data not found")

func _on_interaction_area_body_entered(body):
	if body.is_in_group("player") and not player_in_range:
		player_in_range = true
		player_body = body
		print("Player entered interaction area")
		# Show interaction prompt if you want

func _on_interaction_area_body_exited(body):
	if body.is_in_group("player") and body == player_body:
		player_in_range = false
		player_body = null
		print("Player left interaction area")
