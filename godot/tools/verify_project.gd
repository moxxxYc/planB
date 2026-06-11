extends SceneTree

const REQUIRED_FILES: Array[String] = [
	"res://project.godot",
	"res://scenes/ui/main_menu.tscn",
	"res://scripts/ui/main_menu.gd",
	"res://addons/godot_mcp_runtime/plugin.cfg",
	"res://addons/godot_mcp_runtime/godot_mcp_runtime.gd",
	"res://addons/godot_mcp_runtime/mcp_runtime_autoload.gd",
]

const GOPEAK_RUNTIME_AUTOLOAD := "*res://addons/godot_mcp_runtime/mcp_runtime_autoload.gd"

func _initialize() -> void:
	var failed := false
	for path: String in REQUIRED_FILES:
		if not FileAccess.file_exists(path):
			push_error("Missing required file: %s" % path)
			failed = true

	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene != "res://scenes/ui/main_menu.tscn":
		push_error("Unexpected main scene: %s" % main_scene)
		failed = true

	var rendering_method: String = ProjectSettings.get_setting("rendering/renderer/rendering_method", "")
	if rendering_method != "gl_compatibility":
		push_error("Expected gl_compatibility rendering method, got: %s" % rendering_method)
		failed = true

	var stretch_aspect: String = ProjectSettings.get_setting("display/window/stretch/aspect", "")
	if stretch_aspect != "keep":
		push_error("Expected display/window/stretch/aspect=keep, got: %s" % stretch_aspect)
		failed = true
	var project_file_text := FileAccess.get_file_as_string("res://project.godot")
	if not project_file_text.contains("window/stretch/aspect=\"keep\""):
		push_error("project.godot must explicitly set window/stretch/aspect=\"keep\".")
		failed = true

	var runtime_autoload: String = ProjectSettings.get_setting("autoload/MCPRuntime", "")
	if runtime_autoload != GOPEAK_RUNTIME_AUTOLOAD:
		push_error("Expected autoload/MCPRuntime=%s, got: %s" % [GOPEAK_RUNTIME_AUTOLOAD, runtime_autoload])
		failed = true

	if failed:
		quit(1)
		return

	print("verify_project: PASS")
	quit(0)
