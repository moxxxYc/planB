extends SceneTree

const TEST_FILES := [
	"res://tests/test_scope_guard.gd",
	"res://tests/test_preset_defs.gd",
	"res://tests/test_battle_sequence.gd",
	"res://tests/test_machine_events.gd",
	"res://tests/test_counter_states.gd",
	"res://tests/test_overdrive_directionality.gd",
]

var _filter := ""
var _failures := 0
var _total := 0

func _initialize() -> void:
	_filter = _read_filter()
	for test_file in TEST_FILES:
		_run_file(test_file)

	if _failures == 0:
		print("PASS: %d tests, 0 failures" % _total)
		quit(0)
	else:
		push_error("FAIL: %d tests, %d failures" % [_total, _failures])
		quit(1)

func _read_filter() -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for i in range(args.size()):
		if args[i] == "--filter" and i + 1 < args.size():
			return args[i + 1]
	return ""

func _run_file(path: String) -> void:
	if _filter != "" and path.find(_filter) == -1:
		return

	var script := load(path)
	if script == null or not script.can_instantiate():
		_failures += 1
		push_error("Could not load test file: %s" % path)
		return

	var suite = script.new()
	for method_info in suite.get_method_list():
		var method_name := String(method_info.name)
		if not method_name.begins_with("test_"):
			continue
		if _filter != "" and method_name.find(_filter) == -1 and path.find(_filter) == -1:
			continue

		_total += 1
		if suite.call(method_name):
			print("PASS %s::%s" % [path, method_name])
		else:
			_failures += 1
			push_error("FAIL %s::%s" % [path, method_name])
