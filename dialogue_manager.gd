# DialogueManager.gd - Main dialogue controller
extends Node

signal dialogue_started
signal dialogue_ended
signal choice_made(choice_index: int)

var current_dialogue: Dictionary = {}
var current_node: String = ""
var dialogue_active: bool = false
var dialogue_flags: Dictionary = {}  # For tracking story progress

# Reference to UI (set this from your scene)
var dialogue_ui: Control

func start_dialogue(dialogue_data: Dictionary, starting_node: String = "start"):
	current_dialogue = dialogue_data
	current_node = starting_node
	dialogue_active = true
	dialogue_started.emit()
	show_current_node()

func show_current_node():
	if not current_dialogue.has(current_node):
		end_dialogue()
		return
	
	var node_data = current_dialogue[current_node]
	
	# Display the dialogue text
	if dialogue_ui:
		dialogue_ui.display_dialogue(node_data)

func make_choice(choice_index: int):
	if not dialogue_active:
		return
	
	var node_data = current_dialogue[current_node]
	
	if node_data.has("choices") and choice_index < node_data.choices.size():
		var choice = node_data.choices[choice_index]
		
		# Set any flags this choice might set
		if choice.has("set_flag"):
			for flag_name in choice.set_flag:
				dialogue_flags[flag_name] = choice.set_flag[flag_name]
		
		# Move to next node
		if choice.has("next"):
			current_node = choice.next
			choice_made.emit(choice_index)
			show_current_node()
		else:
			end_dialogue()
	else:
		# If no choices, just continue to next node
		if node_data.has("next"):
			current_node = node_data.next
			show_current_node()
		else:
			end_dialogue()

func end_dialogue():
	dialogue_active = false
	current_dialogue = {}
	current_node = ""
	dialogue_ended.emit()
	if dialogue_ui:
		dialogue_ui.hide_dialogue()

func has_flag(flag_name: String) -> bool:
	return dialogue_flags.has(flag_name) and dialogue_flags[flag_name]

func set_flag(flag_name: String, value: bool):
	dialogue_flags[flag_name] = value
