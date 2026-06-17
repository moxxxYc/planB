class_name MainMenu
extends Control

const RUN_SESSION_SCENE: String = "res://scenes/run/mvp_run_session.tscn"
const GAME_WINDOW_TITLE: String = "PlanB 三仓球机"

@onready var start_button: Button = %StartButton

func _ready() -> void:
	_apply_game_window_title()
	start_button.pressed.connect(_on_start_button_pressed)
	start_button.grab_focus()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(RUN_SESSION_SCENE)

func _apply_game_window_title() -> void:
	get_window().title = GAME_WINDOW_TITLE
	await RenderingServer.frame_post_draw
	DisplayServer.window_set_title(GAME_WINDOW_TITLE, get_window().get_window_id())
