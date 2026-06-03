extends RefCounted

const BANNED_RESTORED_PATHS := [
	"package.json",
	"src",
	"public/assets/generated",
	"scripts/audit-mvp-readiness.mjs",
	"scripts/audit-v12-readiness.mjs",
	"scripts/run-build-probes.mjs",
]

const BANNED_FEATURE_DIRS := [
	"shop",
	"relic",
	"economy",
	"race",
	"races",
	"enemy_roster",
	"node_map",
	"events",
	"elites",
	"bosses",
	"network",
	"backend",
	"steam",
	"matchmaking",
]

const ALLOWED_COUNTER_IDS := [
	"pool_polluter",
	"echo_breaker",
	"stagger_punisher",
]

func test_no_restored_web_mvp_paths() -> bool:
	var repo_root := _repo_root()
	for relative_path in BANNED_RESTORED_PATHS:
		if _path_exists(repo_root.path_join(relative_path)):
			push_error("Restored obsolete Web MVP path: %s" % relative_path)
			return false
	return true

func test_no_banned_feature_directories() -> bool:
	var found: Array[String] = []
	for root in _implementation_roots():
		found.append_array(_find_banned_dirs(root))
	if not found.is_empty():
		push_error("Out-of-scope feature directories found: %s" % ", ".join(found))
		return false
	return true

func test_only_allowed_counter_ids_are_named() -> bool:
	var files: Array[String] = []
	for root in _implementation_roots():
		files.append_array(_list_files(root))
	var banned_counter_terms := [
		"boss",
		"elite",
		"enemy_table",
		"enemy_roster",
		"kill_gold",
	]

	for file_path in files:
		if file_path.get_extension() not in ["gd", "tscn", "md", "csv", "godot"]:
			continue
		var contents := FileAccess.get_file_as_string(file_path)
		for term in banned_counter_terms:
			if contents.find(term) != -1:
				var allowed := false
				for counter_id in ALLOWED_COUNTER_IDS:
					if contents.find(counter_id) != -1:
						allowed = true
				if not allowed:
					push_error("Potential out-of-scope enemy term '%s' in %s" % [term, file_path])
					return false
	return true

func _prototype_root() -> String:
	return ProjectSettings.globalize_path("res://").trim_suffix("/")

func _repo_root() -> String:
	return _prototype_root().get_base_dir().get_base_dir()

func _implementation_roots() -> Array[String]:
	var roots: Array[String] = []
	for relative_root in ["scripts", "scenes"]:
		var full_path := _prototype_root().path_join(relative_root)
		if DirAccess.dir_exists_absolute(full_path):
			roots.append(full_path)
	return roots

func _path_exists(path: String) -> bool:
	return FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path)

func _find_banned_dirs(root: String) -> Array[String]:
	var matches: Array[String] = []
	_scan_dirs(root, matches)
	return matches

func _scan_dirs(path: String, matches: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry == "":
			break
		if entry.begins_with("."):
			continue
		var full_path := path.path_join(entry)
		if dir.current_is_dir():
			if BANNED_FEATURE_DIRS.has(entry):
				matches.append(full_path)
			_scan_dirs(full_path, matches)
	dir.list_dir_end()

func _list_files(root: String) -> Array[String]:
	var files: Array[String] = []
	_collect_files(root, files)
	return files

func _collect_files(path: String, files: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry == "":
			break
		if entry.begins_with("."):
			continue
		var full_path := path.path_join(entry)
		if dir.current_is_dir():
			_collect_files(full_path, files)
		else:
			files.append(full_path)
	dir.list_dir_end()
