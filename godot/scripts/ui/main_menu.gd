class_name MainMenu
extends Control

const RUN_SESSION_SCENE: String = "res://scenes/run/mvp_run_session.tscn"

@onready var start_button: Button = %StartButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	start_button.grab_focus()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(RUN_SESSION_SCENE)
