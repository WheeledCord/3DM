extends Node

const scene_gregerson = preload("res://scenes/gregerson.tscn")
const scene_gregersoninside = preload("res://scenes/gregersoninside.tscn")
const scene_cave = preload("res://scenes/cave.tscn")
const scene_greg2 = preload("res://scenes/greg2.tscn")
const scene_meat = preload("res://scenes/meat.tscn")

signal on_trigger_player_spawn

var spawn_door_tag

func go_to_level(level_tag, destination_tag):
	var scene_to_load

	match level_tag:
		"gregerson":
			scene_to_load = scene_gregerson
		"gregersoninside":
			scene_to_load = scene_gregersoninside
		"cave":
			scene_to_load = scene_cave
		"greg2":
			scene_to_load = scene_greg2
		"meat":
			scene_to_load = scene_meat

	if scene_to_load != null:
		spawn_door_tag = destination_tag
		get_tree().change_scene_to_packed(scene_to_load)

func trigger_player_spawn(position: Vector2, direction: String):
	on_trigger_player_spawn.emit(position, direction)
