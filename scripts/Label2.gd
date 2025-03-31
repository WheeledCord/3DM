extends Label

var target_word := "Percy"
var current_word := ""
var blip_sound := preload("res://sounds/blipSelect.wav")  # Preload the sound

var audio_player: AudioStreamPlayer

func _ready():
	set_text(current_word)
	grab_focus()

	# Create an AudioStreamPlayer node to play the sound
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = blip_sound
	add_child(audio_player)

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			var text_changed = false
			if event.keycode == KEY_BACKSPACE:
				if current_word.length() > 0:
					current_word = current_word.substr(0, current_word.length() - 1)
					text_changed = true
			elif event.keycode == KEY_ENTER:
				if current_word == target_word:
					get_tree().change_scene_to_file("res://scenes/gregerson.tscn")
			else:
				if current_word.length() < target_word.length():
					current_word += target_word[current_word.length()]
					text_changed = true

			if text_changed:
				set_text(current_word)
				audio_player.play()  # Play the sound
