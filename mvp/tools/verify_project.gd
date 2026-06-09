extends SceneTree

const Manifest := preload("res://scripts/data/mvp_definition_manifest.gd")

const EXPECTED_TERMS := [
	"Launch",
	"Tuning",
	"Unit",
	"Gate",
	"Prime",
	"Echo",
	"Surge",
	"Deploy Lane",
	"Left",
	"Mid",
	"Right",
]

const EXPECTED_ART_ASSETS := [
	"res://assets/ui/planb_logo.png",
	"res://assets/ui/menu_key_art.png",
	"res://assets/sprites/hive_short_fang.png",
	"res://assets/sprites/hive_shield_shell.png",
	"res://assets/sprites/hive_acid_sac.png",
	"res://assets/sprites/hive_crush_shell_beast.png",
	"res://assets/sprites/enemy_grunt.png",
	"res://assets/sprites/enemy_raider.png",
	"res://assets/sprites/enemy_brute.png",
	"res://assets/sprites/guardian_vein_mother.png",
	"res://assets/sprites/guardian_acid_crown_mother.png",
]


func _init() -> void:
	var failures: Array[String] = []

	_check_file_exists("res://project.godot", failures)
	_check_project_setting(failures)
	_check_required_paths(failures)
	_check_required_terms(failures)
	_check_main_scene_instantiates(failures)
	_check_art_assets(failures)
	_check_resource_category_counts(failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("verify_project.gd passed: main menu, scenes, scripts, data, and demo art assets loaded")
	quit(0)


func _check_file_exists(path: String, failures: Array[String]) -> void:
	if not FileAccess.file_exists(path):
		failures.append("Missing file: %s" % path)


func _check_project_setting(failures: Array[String]) -> void:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene != "res://scenes/ui/main_menu.tscn":
		failures.append("Unexpected main scene: %s" % main_scene)

	var project_name: String = ProjectSettings.get_setting("application/config/name", "")
	if project_name != "PlanB":
		failures.append("Unexpected project name: %s" % project_name)


func _check_required_paths(failures: Array[String]) -> void:
	for path in Manifest.required_paths():
		if not ResourceLoader.exists(path):
			failures.append("Missing Godot resource path: %s" % path)
			continue
		var resource := ResourceLoader.load(path)
		if resource == null:
			failures.append("Could not load Godot resource path: %s" % path)


func _check_required_terms(failures: Array[String]) -> void:
	for term in EXPECTED_TERMS:
		if not Manifest.REQUIRED_TERMS.has(term):
			failures.append("Required term missing from manifest: %s" % term)


func _check_main_scene_instantiates(failures: Array[String]) -> void:
	var packed := ResourceLoader.load("res://scenes/ui/main_menu.tscn")
	if not packed is PackedScene:
		failures.append("Main scene did not load as PackedScene")
		return

	var instance := (packed as PackedScene).instantiate()
	if instance == null:
		failures.append("Main scene could not instantiate")
		return

	if not instance.has_method("verify_menu_build"):
		failures.append("Main scene missing verify_menu_build()")
	elif not instance.verify_menu_build():
		failures.append("Main menu contract failed")

	instance.free()


func _check_art_assets(failures: Array[String]) -> void:
	for path in EXPECTED_ART_ASSETS:
		if not FileAccess.file_exists(path):
			failures.append("Missing art asset file: %s" % path)
			continue
		var image := Image.load_from_file(path)
		if image == null or image.is_empty():
			failures.append("Art asset did not decode as image: %s" % path)


func _check_resource_category_counts(failures: Array[String]) -> void:
	var expected := {
		"res://resources/machine/": 1,
		"res://resources/battlefield/": 3,
		"res://resources/units/": 4,
		"res://resources/guardians/": 2,
		"res://resources/economy/": 9,
		"res://resources/enemies/": 3,
		"res://resources/run/": 1,
	}

	for prefix in expected.keys():
		var count := Manifest.count_required_resources_with_prefix(prefix)
		if count < expected[prefix]:
			failures.append("Not enough placeholder resources for %s: %d" % [prefix, count])
