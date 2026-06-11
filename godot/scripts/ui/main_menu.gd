class_name MainMenu
extends Control

const BATTLE_ONE_VERTICAL: String = "res://scenes/run/battle_one_vertical.tscn"

@onready var start_button: Button = %StartButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	start_button.grab_focus()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(BATTLE_ONE_VERTICAL)
