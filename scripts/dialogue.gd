# DialogueUI.gd - UI Controller
extends Control

@onready var character_name_label: Label = $Panel/VBox/NameLabel
@onready var dialogue_text_label: Label = $Panel/VBox/DialogueText
@onready var choices_container: VBoxContainer = $Panel/VBox/ChoicesContainer
@onready var continue_button: Button = $Panel/VBox/ContinueButton

var dialogue_manager: Node
var current_choices: Array = []

# Typewriter effect
var typing_speed: float = 0.05
var is_typing: bool = false

func _ready():
	# Find the dialogue manager
	dialogue_manager = DialogueManager  # Using autoload
	
	# Connect signals
	if dialogue_manager:
		dialogue_manager.dialogue_started.connect(_on_dialogue_started)
		dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)
	
	# Hide initially - IMPORTANT!
	hide()
	visible = false
	
	# Connect continue button
	continue_button.pressed.connect(_on_continue_pressed)

func display_dialogue(node_data: Dictionary):
	show()
	
	# Set character name (safely)
	if node_data.has("character") and node_data.character != null and node_data.character != "":
		character_name_label.text = str(node_data.character)
		character_name_label.show()
	else:
		character_name_label.hide()
	
	# Clear previous choices
	clear_choices()
	
	# Display text with typewriter effect (safely)
	if node_data.has("text") and node_data.text != null and node_data.text != "":
		start_typewriter(str(node_data.text))
	else:
		# If no text, just end the dialogue
		dialogue_manager.end_dialogue()
		return
	
	# Set up choices or continue button
	if node_data.has("choices"):
		current_choices = node_data.choices
		continue_button.hide()
		# Wait for typing to finish before showing choices
		if is_typing:
			await typewriter_finished
		show_choices()
	else:
		continue_button.show()

func start_typewriter(text: String):
	is_typing = true
	dialogue_text_label.text = ""
	
	for i in range(text.length()):
		dialogue_text_label.text += text[i]
		await get_tree().create_timer(typing_speed).timeout
	
	is_typing = false
	typewriter_finished.emit()

signal typewriter_finished

func show_choices():
	for i in range(current_choices.size()):
		var choice = current_choices[i]
		
		# Check if choice should be shown (based on conditions)
		if choice.has("condition"):
			if not check_condition(choice.condition):
				continue
		
		# Duplicate the continue button to get exact same styling
		var button = continue_button.duplicate()
		button.text = choice.text
		button.show()  # Make sure it's visible
		
		# Disconnect any existing signals and connect our choice signal
		var connections = button.pressed.get_connections()
		for connection in connections:
			button.pressed.disconnect(connection.callable)
		
		button.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(button)

func check_condition(condition: Dictionary) -> bool:
	# Check flags or other conditions
	if condition.has("flag"):
		return dialogue_manager.has_flag(condition.flag)
	return true

func clear_choices():
	for child in choices_container.get_children():
		child.queue_free()

func _on_choice_selected(choice_index: int):
	clear_choices()
	dialogue_manager.make_choice(choice_index)

func _on_continue_pressed():
	if dialogue_manager and dialogue_manager.dialogue_active:
		dialogue_manager.make_choice(0)  # Continue to next node

func _on_dialogue_started():
	show()

func _on_dialogue_ended():
	hide()

func hide_dialogue():
	hide()
