class_name MvpRunSession
extends Control

const GuardianContractViewScript := preload("res://scripts/ui/run/guardian_contract_view.gd")
const RewardChoiceViewScript := preload("res://scripts/ui/run/reward_choice_view.gd")
const SecondRewardChoiceViewScript := preload("res://scripts/ui/run/second_reward_choice_view.gd")
const ShopRestViewScript := preload("res://scripts/ui/run/shop_rest_view.gd")
const RunResultViewScript := preload("res://scripts/ui/run/run_result_view.gd")
const EndpointPrepViewScript := preload("res://scripts/ui/run/endpoint_prep_view.gd")
const FinalResultViewScript := preload("res://scripts/ui/run/final_result_view.gd")
const RunHudViewScript := preload("res://scripts/ui/run/run_hud_view.gd")
const CounterDefinitionScript := preload("res://scripts/data/counter_definition.gd")

const BATTLE_SCENE_PATH: String = "res://scenes/run/battle_one_vertical.tscn"
const BATTLE_AUTO_ROUTE_DWELL_SECONDS: float = 0.6
const GAME_WINDOW_TITLE: String = "PlanB 三仓球机"

@onready var hud_slot: Control = %HudSlot
@onready var screen_slot: Control = %ScreenSlot

var session: RunSessionModel = RunSessionModel.new()
var guardian_defs: Dictionary = {}
var reward_defs: Dictionary = {}
var shop_defs: Dictionary = {}
var second_reward_defs: Dictionary = {}
var counter_defs: Dictionary = {}
var next_counter_override: String = ""
var planned_counter_id: String = ""
var visible_shop_item_ids: Array[String] = []
var second_reward_candidate_ids: Array[String] = []
var second_reward_candidate_records: Array[Dictionary] = []
var hud_view = null
var active_battle: BattleOneVertical = null
var active_result_view = null
var battle_auto_route_timer: float = 0.0
var shell_styles_applied: bool = false

func _enter_tree() -> void:
	_ensure_catalogs()

func _ready() -> void:
	_apply_game_window_title()
	_ensure_shell_ready()
	_ensure_hud()
	_render_current_node()

func _process(delta: float) -> void:
	_poll_active_battle(delta)

func _apply_game_window_title() -> void:
	get_window().title = GAME_WINDOW_TITLE
	await RenderingServer.frame_post_draw
	DisplayServer.window_set_title(GAME_WINDOW_TITLE, get_window().get_window_id())

func get_current_node_id() -> String:
	return session.current_node_id

func get_guardian_card_text(guardian_id: String) -> String:
	_ensure_catalogs()
	if not guardian_defs.has(guardian_id):
		return ""
	var definition: GuardianDefinition = guardian_defs[guardian_id] as GuardianDefinition
	if definition == null:
		return ""
	return definition.to_card_text()

func select_guardian(guardian_id: String) -> void:
	_ensure_catalogs()
	if not guardian_defs.has(guardian_id):
		push_error("Unknown Guardian: %s" % guardian_id)
		return
	session.select_guardian(guardian_id)
	_render_current_node()

func confirm_guardian() -> void:
	session.confirm_guardian()
	_render_current_node()

func get_selected_guardian_id() -> String:
	return session.selected_guardian_id

func complete_current_battle_for_verifier(battle_result: String) -> void:
	_complete_active_battle(battle_result)

func get_gold() -> int:
	return session.gold

func get_reward_card_text(modifier_id: String) -> String:
	_ensure_catalogs()
	if not reward_defs.has(modifier_id):
		return ""
	var definition: ModifierDefinition = reward_defs[modifier_id] as ModifierDefinition
	if definition == null:
		return ""
	return definition.to_card_text()

func choose_reward_one(modifier_id: String) -> void:
	_ensure_catalogs()
	if not reward_defs.has(modifier_id):
		push_error("Unknown Reward 1 modifier: %s" % modifier_id)
		return
	session.choose_reward_one(modifier_id)
	_ensure_planned_counter()
	_render_current_node()

func get_reward_one_id() -> String:
	return session.reward_one_id

func get_battle_modifier_marker_text() -> String:
	if active_battle != null and active_battle.has_method("get_battle_modifier_marker_text"):
		return String(active_battle.call("get_battle_modifier_marker_text"))
	return _selected_modifier_marker_text()

func get_shop_card_text(modifier_id: String) -> String:
	_ensure_catalogs()
	if not shop_defs.has(modifier_id):
		return ""
	var definition: ModifierDefinition = shop_defs[modifier_id] as ModifierDefinition
	if definition == null:
		return ""
	return definition.to_card_text()

func buy_shop_item(modifier_id: String) -> bool:
	_ensure_catalogs()
	if not shop_defs.has(modifier_id):
		push_error("Unknown Shop modifier: %s" % modifier_id)
		return false
	var definition: ModifierDefinition = shop_defs[modifier_id] as ModifierDefinition
	if definition == null:
		return false
	var did_buy: bool = session.buy_shop_item(modifier_id, definition.gold_cost)
	_render_current_node()
	return did_buy

func get_shop_purchase_id() -> String:
	return session.shop_purchase_id

func damage_guardian_for_verifier(amount: int) -> void:
	session.damage_guardian(amount)
	_render_current_node()

func can_buy_rest() -> bool:
	return session.can_buy_rest()

func buy_rest() -> bool:
	var did_buy: bool = session.buy_rest()
	_render_current_node()
	return did_buy

func get_guardian_hp() -> int:
	return session.guardian_hp

func get_guardian_max_hp() -> int:
	return session.guardian_max_hp

func get_rest_count() -> int:
	return session.get_rest_count()

func confirm_shop_and_rest() -> void:
	if session.current_node_id == RunSessionModel.NODE_SHOP_1:
		session.confirm_shop_and_rest()
	elif session.current_node_id == RunSessionModel.NODE_REST_AFTER_BATTLE_3:
		session.confirm_battle_three_rest()
	else:
		push_error("Shop / Rest confirm is not available at: %s" % session.current_node_id)
	_render_current_node()

func confirm_endpoint_prep() -> void:
	session.confirm_endpoint_prep()
	_render_current_node()

func set_next_counter_for_verifier(counter_id: String) -> void:
	_ensure_catalogs()
	if not counter_defs.has(counter_id):
		push_error("Unknown M3 counter: %s" % counter_id)
		return
	next_counter_override = counter_id
	planned_counter_id = counter_id
	visible_shop_item_ids = []
	session.set_planned_counter(counter_id)

func get_counter_scout_text() -> String:
	_ensure_catalogs()
	_ensure_planned_counter()
	var definition: Resource = counter_defs.get(planned_counter_id, null) as Resource
	if definition == null:
		return "反制侦测：暂无"
	return String(definition.call("to_scout_text"))

func get_visible_shop_item_ids() -> Array[String]:
	_ensure_visible_shop_item_ids()
	return visible_shop_item_ids.duplicate()

func get_counter_record() -> Dictionary:
	if active_battle != null and active_battle.has_method("get_active_counter_record"):
		var active_record: Dictionary = active_battle.call("get_active_counter_record") as Dictionary
		if not active_record.is_empty():
			return active_record.duplicate(true)
	return session.counter_record.duplicate(true)

func get_active_counter_banner_text() -> String:
	if active_battle != null and active_battle.has_method("get_active_counter_banner_text"):
		return String(active_battle.call("get_active_counter_banner_text"))
	return "反制：无"

func get_active_machine_log_text() -> String:
	if active_battle != null and active_battle.has_method("get_active_machine_log_text"):
		return String(active_battle.call("get_active_machine_log_text"))
	return ""

func get_lane_button_text(lane: String) -> String:
	if active_battle != null and active_battle.has_method("get_lane_button_text"):
		return String(active_battle.call("get_lane_button_text", lane))
	return ""

func advance_active_battle_for_verifier(seconds: float) -> void:
	if active_battle != null and active_battle.has_method("advance_for_verifier"):
		active_battle.call("advance_for_verifier", seconds)

func get_result_summary_text() -> String:
	if active_result_view != null:
		return active_result_view.get_summary_text()
	return _build_result_summary_text()

func get_result_record() -> Dictionary:
	return session.result_record.duplicate(true)

func get_second_reward_current_axis() -> String:
	_ensure_second_reward_offer()
	return session.second_offer_current_axis

func get_second_reward_candidate_ids() -> Array[String]:
	_ensure_second_reward_offer()
	return second_reward_candidate_ids.duplicate()

func get_second_reward_card_text(modifier_id: String) -> String:
	_ensure_second_reward_offer()
	if not second_reward_defs.has(modifier_id):
		return ""
	var definition: ModifierDefinition = second_reward_defs[modifier_id] as ModifierDefinition
	if definition == null:
		return ""
	var record: Dictionary = _second_reward_record_for(modifier_id)
	return "%s\n%s\n候选来源：%s" % [
		definition.to_card_text(),
		String(record.get("offer_role_label", "")),
		String(record.get("reason", "")),
	]

func choose_second_reward(modifier_id: String) -> void:
	_ensure_catalogs()
	_ensure_second_reward_offer()
	if not second_reward_candidate_ids.has(modifier_id):
		push_error("Unknown Second Reward candidate: %s" % modifier_id)
		return
	var record: Dictionary = _second_reward_record_for(modifier_id)
	session.choose_second_reward(modifier_id, String(record.get("offer_role", "")))
	_render_current_node()

func _render_current_node() -> void:
	_ensure_shell_ready()
	if screen_slot == null:
		return
	_clear_screen()
	_update_hud()

	match session.current_node_id:
		RunSessionModel.NODE_GUARDIAN_CONTRACT:
			_show_guardian_contract()
		RunSessionModel.NODE_BATTLE_1:
			_show_battle(1)
		RunSessionModel.NODE_REWARD_1:
			_show_reward_one()
		RunSessionModel.NODE_BATTLE_2:
			_show_battle(2)
		RunSessionModel.NODE_SHOP_1:
			_show_shop_rest(false)
		RunSessionModel.NODE_BATTLE_3:
			_show_battle(3)
		RunSessionModel.NODE_REST_AFTER_BATTLE_3:
			_show_shop_rest(true)
		"battle_4":
			_show_battle(4)
		"reward_2":
			_show_second_reward()
		RunSessionModel.NODE_BATTLE_5:
			_show_battle(5)
		RunSessionModel.NODE_ENDPOINT_PREP:
			_show_endpoint_prep()
		RunSessionModel.NODE_ENDPOINT:
			_show_battle(6)
		RunSessionModel.NODE_FINAL_RESULT:
			_show_final_result()
		RunSessionModel.NODE_RESULT_ROUTING:
			_show_result()
		_:
			push_error("Unknown run node: %s" % session.current_node_id)

func _show_guardian_contract() -> void:
	var view = GuardianContractViewScript.new()
	_add_screen_child(view)
	view.guardian_selected.connect(_on_guardian_selected)
	view.guardian_confirmed.connect(_on_guardian_confirmed)
	view.render(guardian_defs, session.selected_guardian_id)

func _show_reward_one() -> void:
	var view = RewardChoiceViewScript.new()
	_add_screen_child(view)
	view.reward_chosen.connect(_on_reward_chosen)
	view.render(reward_defs)

func _show_second_reward() -> void:
	_ensure_second_reward_offer()
	var view = SecondRewardChoiceViewScript.new()
	_add_screen_child(view)
	view.reward_chosen.connect(_on_second_reward_chosen)
	view.render(session.second_offer_current_axis, second_reward_candidate_records, second_reward_defs)

func _show_endpoint_prep() -> void:
	var view = EndpointPrepViewScript.new()
	_add_screen_child(view)
	view.rest_bought.connect(_on_rest_bought)
	view.confirmed.connect(_on_endpoint_prep_confirmed)
	view.render(session)

func _show_shop_rest(p_hide_shop: bool) -> void:
	var view = ShopRestViewScript.new()
	_add_screen_child(view)
	view.shop_item_bought.connect(_on_shop_item_bought)
	view.rest_bought.connect(_on_rest_bought)
	view.confirmed.connect(_on_shop_rest_confirmed)
	var visible_ids: Array[String] = []
	var scout_text: String = ""
	if not p_hide_shop:
		visible_ids = get_visible_shop_item_ids()
		scout_text = get_counter_scout_text()
	view.render(shop_defs, session, p_hide_shop, visible_ids, scout_text)

func _show_result() -> void:
	var view = RunResultViewScript.new()
	active_result_view = view
	_add_screen_child(view)
	view.render(session, guardian_defs, reward_defs, shop_defs, second_reward_defs)

func _show_final_result() -> void:
	var view = FinalResultViewScript.new()
	active_result_view = view
	_add_screen_child(view)
	view.render(session, guardian_defs, reward_defs, shop_defs, second_reward_defs)

func _show_battle(battle_number: int) -> void:
	var battle_scene: PackedScene = load(BATTLE_SCENE_PATH)
	if battle_scene == null:
		push_error("Missing battle scene: %s" % BATTLE_SCENE_PATH)
		return

	var battle: BattleOneVertical = battle_scene.instantiate() as BattleOneVertical
	if battle == null:
		push_error("Could not instantiate BattleOneVertical.")
		return

	active_battle = battle
	_add_screen_child(battle)
	battle.configure_for_run(battle_number, session, _battle_modifier_payload())

func _on_guardian_selected(guardian_id: String) -> void:
	select_guardian(guardian_id)

func _on_guardian_confirmed() -> void:
	confirm_guardian()

func _on_reward_chosen(modifier_id: String) -> void:
	choose_reward_one(modifier_id)

func _on_second_reward_chosen(modifier_id: String) -> void:
	choose_second_reward(modifier_id)

func _on_shop_item_bought(modifier_id: String) -> void:
	buy_shop_item(modifier_id)

func _on_rest_bought() -> void:
	buy_rest()

func _on_shop_rest_confirmed() -> void:
	confirm_shop_and_rest()

func _on_endpoint_prep_confirmed() -> void:
	confirm_endpoint_prep()

func _complete_active_battle(battle_result: String) -> void:
	if not _is_battle_node(session.current_node_id):
		push_error("Cannot complete non-battle run node: %s" % session.current_node_id)
		return
	if active_battle != null and active_battle.has_method("get_active_counter_record"):
		var record: Dictionary = active_battle.call("get_active_counter_record") as Dictionary
		if not record.is_empty():
			if session.current_node_id == RunSessionModel.NODE_BATTLE_5 or session.current_node_id == RunSessionModel.NODE_ENDPOINT:
				session.set_counter_two_record(record)
			else:
				session.set_counter_record(record)
	if active_battle != null and active_battle.has_method("get_battlefield_record"):
		var battle_record: Dictionary = active_battle.call("get_battlefield_record") as Dictionary
		session.set_battle_record(session.current_node_id, battle_record)
	if active_battle != null and active_battle.has_method("get_player_guardian_hp"):
		session.guardian_hp = int(active_battle.call("get_player_guardian_hp"))
	if active_battle != null and active_battle.has_method("get_endpoint_guardian_hp"):
		session.endpoint_guardian_hp = int(active_battle.call("get_endpoint_guardian_hp"))
	session.complete_battle(battle_result)
	_render_current_node()

func _poll_active_battle(delta: float) -> void:
	if active_battle == null or not _is_battle_node(session.current_node_id):
		return

	var battle_result: String = active_battle.get_battle_result()
	if battle_result == BattleLaneState.RESULT_RUNNING:
		battle_auto_route_timer = 0.0
		return

	battle_auto_route_timer += delta
	if battle_auto_route_timer >= BATTLE_AUTO_ROUTE_DWELL_SECONDS:
		_complete_active_battle(battle_result)

func _is_battle_node(node_id: String) -> bool:
	return [
		RunSessionModel.NODE_BATTLE_1,
		RunSessionModel.NODE_BATTLE_2,
		RunSessionModel.NODE_BATTLE_3,
		"battle_4",
		RunSessionModel.NODE_BATTLE_5,
		RunSessionModel.NODE_ENDPOINT,
	].has(node_id)

func _ensure_hud() -> void:
	_ensure_shell_ready()
	if hud_slot == null:
		return
	if hud_view != null:
		return
	hud_view = RunHudViewScript.new()
	hud_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_view.size_flags_vertical = Control.SIZE_FILL
	hud_slot.add_child(hud_view)
	hud_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _update_hud() -> void:
	_ensure_hud()
	hud_view.render(session, guardian_defs, reward_defs, shop_defs, second_reward_defs)

func _add_screen_child(child: Control) -> void:
	_ensure_shell_ready()
	if screen_slot == null:
		return
	var wrapper := Control.new()
	wrapper.name = "%sWrapper" % child.name
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen_slot.add_child(wrapper)
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	child.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrapper.add_child(child)
	child.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _clear_screen() -> void:
	_ensure_shell_ready()
	if screen_slot == null:
		return
	active_battle = null
	active_result_view = null
	battle_auto_route_timer = 0.0
	for child: Node in screen_slot.get_children():
		screen_slot.remove_child(child)
		child.queue_free()

func _ensure_shell_ready() -> void:
	_ensure_catalogs()
	if hud_slot == null:
		hud_slot = get_node_or_null("SafeArea/RootRows/HudSlot") as Control
	if screen_slot == null:
		screen_slot = get_node_or_null("SafeArea/RootRows/ScreenSlot") as Control
	_apply_shell_styles()

func _apply_shell_styles() -> void:
	if shell_styles_applied:
		return
	if screen_slot == null:
		return

	var screen_panel: PanelContainer = screen_slot as PanelContainer
	if screen_panel != null:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#161a17")
		style.border_color = Color("#9b7a4a")
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		style.content_margin_left = 24.0
		style.content_margin_top = 22.0
		style.content_margin_right = 24.0
		style.content_margin_bottom = 22.0
		screen_panel.add_theme_stylebox_override("panel", style)
	shell_styles_applied = true

func _ensure_catalogs() -> void:
	if (
		guardian_defs.is_empty()
		or reward_defs.is_empty()
		or shop_defs.is_empty()
		or second_reward_defs.is_empty()
		or counter_defs.is_empty()
	):
		_build_catalogs()

func _build_catalogs() -> void:
	guardian_defs = {
		"hive_vein_mother": _make_guardian(
			"hive_vein_mother",
			"巢脉母",
			"Launch",
			"偏向前置供给和路线支援。",
			"契约要求先读 Launch，再把 Queue 推到受压路线。",
			"如果 Pool 和路线节奏断开，前线会先失守。"
		),
		"hive_acid_crown_mother": _make_guardian(
			"hive_acid_crown_mother",
			"酸冠母",
			"Tuning",
			"偏向 Tuning 结果和强化节奏。",
			"契约要求围绕 Prime / Surge 读机器变化。",
			"如果强化没有进入 Unit 槽，优势会停在机器内部。"
		),
	}

	reward_defs = {
		"pool_pocket": _make_modifier(
			"pool_pocket",
			"Pool 扩容袋",
			ModifierDefinition.SourceType.REWARD,
			"Launch",
			"Launch.Pool.capacity",
			"容量 +1",
			"奖励",
			0,
			"Pool 多容纳 1 颗净球，降低早期供给溢出。"
		),
		"prime_charge": _make_modifier(
			"prime_charge",
			"Prime 充能",
			ModifierDefinition.SourceType.REWARD,
			"Tuning",
			"Tuning.Prime.value_bonus",
			"数值 +1 提升到 +2",
			"奖励",
			0,
			"Prime 命中时强化更明显，帮助 Unit 槽更快形成 Queue。"
		),
		"slot_primer": _make_modifier(
			"slot_primer",
			"S1 打底",
			ModifierDefinition.SourceType.REWARD,
			"Unit",
			"Unit.S1.progress_floor",
			"S1 底线进度 = 1",
			"奖励",
			0,
			"固定让 S1 保留 1 点底线进度，减少短牙槽空转感。"
		),
	}

	shop_defs = {
		"front_recycle": _make_modifier(
			"front_recycle",
			"前置回流",
			ModifierDefinition.SourceType.SHOP,
			"Launch",
			"Launch.Recycle.return_position",
			"回流到队列前段",
			"转向",
			5,
			"回流球回到更靠前的位置，服务 Launch 轴的持续供给。"
		),
		"surge_buffer": _make_modifier(
			"surge_buffer",
			"Surge 缓冲",
			ModifierDefinition.SourceType.SHOP,
			"Tuning",
			"Tuning.Surge.charge_buffer",
			"最多保留 1 层缓冲",
			"补洞",
			4,
			"Surge 获得缓冲读法，减少一次结果落空的挫败。"
		),
		"queue_brace": _make_modifier(
			"queue_brace",
			"Queue 支撑",
			ModifierDefinition.SourceType.SHOP,
			"Unit",
			"Unit.Queue.empty_gap_response",
			"队列空档时补进度",
			"补洞",
			4,
			"Queue 空档有补强读法，让部署节奏更容易被看懂。"
		),
		"junk_sieve": _make_modifier(
			"junk_sieve",
			"废球筛",
			ModifierDefinition.SourceType.SHOP,
			"Launch",
			"Launch.Pool.junk_filter",
			"过滤 Pool 头部 Junk",
			"补洞",
			4,
			"回应 Pool 污染：Junk 发射前被筛掉，减少无效结算。"
		),
		"muster_pair": _make_modifier(
			"muster_pair",
			"成对集结",
			ModifierDefinition.SourceType.SHOP,
			"Unit",
			"Unit.Queue.same_slot_pair",
			"同槽成对出兵",
			"转向",
			5,
			"让 Unit 轴从单个队列条目转向成对释放。"
		),
	}

	second_reward_defs = {
		"front_recycle": _make_second_reward_modifier_from_shop("front_recycle"),
		"junk_sieve": _make_second_reward_modifier_from_shop("junk_sieve"),
		"surge_buffer": _make_second_reward_modifier_from_shop("surge_buffer"),
		"queue_brace": _make_second_reward_modifier_from_shop("queue_brace"),
		"muster_pair": _make_second_reward_modifier_from_shop("muster_pair"),
		"echo_latch": _make_modifier(
			"echo_latch",
			"Echo 锁存",
			ModifierDefinition.SourceType.REWARD,
			"Tuning",
			"Tuning.Echo.copy_latch",
			"Echo 复制锁存",
			"Tuning 深化",
			0,
			"第二次奖励专属深化：让 Echo 重复结算更集中、更容易被复盘。"
		),
	}

	counter_defs = {
		"pool_polluter": _make_counter(
			"pool_polluter",
			"Pool 污染者",
			"Pool",
			4.0,
			18.0,
			"Junk 插入 Pool",
			["junk_sieve", "pool_pocket"]
		),
		"echo_breaker": _make_counter(
			"echo_breaker",
			"Echo 破坏者",
			"Echo / Surge 价值",
			4.0,
			14.0,
			"Echo 复制降级为 Gate",
			["surge_buffer", "prime_charge"]
		),
		"stagger_punisher": _make_counter(
			"stagger_punisher",
			"断档惩罚者",
			"Queue 空档",
			3.0,
			16.0,
			"敌方突袭虫因 Queue 空档出现",
			["queue_brace", "slot_primer"]
		),
	}

func _make_guardian(
	id: String,
	display_name: String,
	axis: String,
	tactical_read: String,
	strategic_read: String,
	risk_read: String
) -> GuardianDefinition:
	var definition: GuardianDefinition = GuardianDefinition.new()
	definition.id = id
	definition.display_name = display_name
	definition.axis = axis
	definition.tactical_read = tactical_read
	definition.strategic_read = strategic_read
	definition.risk_read = risk_read
	return definition

func _make_modifier(
	id: String,
	display_name: String,
	source_type: ModifierDefinition.SourceType,
	warehouse: String,
	target_component: String,
	operation: String,
	role: String,
	gold_cost: int,
	player_read: String
) -> ModifierDefinition:
	var definition: ModifierDefinition = ModifierDefinition.new()
	definition.id = id
	definition.display_name = display_name
	definition.source_type = source_type
	definition.warehouse = warehouse
	definition.target_component = target_component
	definition.operation = operation
	definition.role = role
	definition.gold_cost = gold_cost
	definition.player_read = player_read
	return definition

func _make_second_reward_modifier_from_shop(modifier_id: String) -> ModifierDefinition:
	var source: ModifierDefinition = shop_defs.get(modifier_id, null) as ModifierDefinition
	if source == null:
		return _make_modifier(
			modifier_id,
			modifier_id,
			ModifierDefinition.SourceType.REWARD,
			"",
			"",
			"",
			"",
			0,
			""
		)
	return _make_modifier(
		source.id,
		source.display_name,
		ModifierDefinition.SourceType.REWARD,
		source.warehouse,
		source.target_component,
		source.operation,
		source.role,
		0,
		source.player_read
	)

func _make_counter(
	id: String,
	display_name: String,
	target_component: String,
	warning_seconds: float,
	active_seconds: float,
	visible_effect: String,
	patch_ids: Array[String],
	first_warning_start_seconds: float = 30.0
) -> Resource:
	var definition = CounterDefinitionScript.new()
	definition.id = id
	definition.display_name = display_name
	definition.target_component = target_component
	definition.first_warning_start_seconds = first_warning_start_seconds
	definition.warning_seconds = warning_seconds
	definition.active_seconds = active_seconds
	definition.visible_effect = visible_effect
	definition.patch_ids = patch_ids.duplicate()
	return definition

func _ensure_planned_counter() -> void:
	if not planned_counter_id.is_empty():
		if counter_defs.has(planned_counter_id):
			session.set_planned_counter(planned_counter_id)
			return
		planned_counter_id = ""
	if not next_counter_override.is_empty() and counter_defs.has(next_counter_override):
		planned_counter_id = next_counter_override
	elif session.reward_one_id == "pool_pocket":
		planned_counter_id = "pool_polluter"
	elif session.reward_one_id == "slot_primer":
		planned_counter_id = "stagger_punisher"
	else:
		planned_counter_id = "echo_breaker"
	session.set_planned_counter(planned_counter_id)

func _ensure_visible_shop_item_ids() -> void:
	if not visible_shop_item_ids.is_empty():
		return
	_ensure_planned_counter()
	var ids: Array[String] = []
	var counter: Resource = counter_defs.get(planned_counter_id, null) as Resource
	if counter != null:
		var patch_ids: Array = counter.get("patch_ids") as Array
		for patch_id_variant: Variant in patch_ids:
			var patch_id: String = String(patch_id_variant)
			if shop_defs.has(patch_id) and not ids.has(patch_id):
				ids.append(patch_id)
	for fallback_id: String in ["front_recycle", "surge_buffer", "queue_brace", "muster_pair", "junk_sieve"]:
		if ids.size() >= 3:
			break
		if shop_defs.has(fallback_id) and not ids.has(fallback_id):
			ids.append(fallback_id)
	visible_shop_item_ids = ids.slice(0, 3)

func _ensure_second_reward_offer() -> void:
	_ensure_catalogs()
	if not second_reward_candidate_ids.is_empty():
		return

	var axis: String = _current_main_axis()
	second_reward_candidate_records = _second_reward_candidates_for_axis(axis)
	second_reward_candidate_ids = []
	for record: Dictionary in second_reward_candidate_records:
		var modifier_id: String = String(record.get("modifier_id", ""))
		if not modifier_id.is_empty():
			second_reward_candidate_ids.append(modifier_id)
	session.set_second_offer(axis, second_reward_candidate_records)

func _current_main_axis() -> String:
	if not session.reward_one_id.is_empty():
		var reward: ModifierDefinition = reward_defs.get(session.reward_one_id, null) as ModifierDefinition
		if reward != null:
			return reward.warehouse
	if not session.shop_purchase_id.is_empty():
		var shop: ModifierDefinition = shop_defs.get(session.shop_purchase_id, null) as ModifierDefinition
		if shop != null:
			return shop.warehouse
	return "Launch"

func _second_reward_candidates_for_axis(axis: String) -> Array[Dictionary]:
	match axis:
		"Launch":
			return [
				_make_second_reward_record("front_recycle", "deepen_current_axis", "深化当前主轴", "因为当前主轴是 Launch，继续强化持续补线。"),
				_make_second_reward_record("junk_sieve", "patch", "补洞", "因为 Pool 污染或 Junk 风险需要机器补洞。"),
				_make_second_reward_record("muster_pair", "pivot", "转向", "转向 Unit 批量部署，让持续供给有更清晰的战场出口。"),
			]
		"Tuning":
			return [
				_make_second_reward_record("echo_latch", "deepen_current_axis", "深化当前主轴", "因为当前主轴是 Tuning，继续强化 Echo 重复结算。"),
				_make_second_reward_record("surge_buffer", "patch", "补洞", "补上 Surge 未立刻落地的节奏空档。"),
				_make_second_reward_record("front_recycle", "pivot", "转向", "转向 Launch 回流，让高价值命中有更稳定供给。"),
			]
		"Unit":
			return [
				_make_second_reward_record("muster_pair", "deepen_current_axis", "深化当前主轴", "因为当前主轴是 Unit，继续强化同槽成对出兵。"),
				_make_second_reward_record("queue_brace", "patch", "补洞", "补上 Queue 空档和断档风险。"),
				_make_second_reward_record("front_recycle", "pivot", "转向", "转向 Launch 补线，减少 Unit 槽等待期间的空线。"),
			]
		_:
			return [
				_make_second_reward_record("front_recycle", "deepen_current_axis", "深化当前主轴", "默认强化 Launch 持续供给。"),
				_make_second_reward_record("queue_brace", "patch", "补洞", "默认补 Queue 空档。"),
			]

func _make_second_reward_record(
	modifier_id: String,
	offer_role: String,
	offer_role_label: String,
	reason: String
) -> Dictionary:
	var definition: ModifierDefinition = second_reward_defs.get(modifier_id, null) as ModifierDefinition
	return {
		"modifier_id": modifier_id,
		"display_name": definition.display_name if definition != null else modifier_id,
		"axis": definition.warehouse if definition != null else "",
		"offer_role": offer_role,
		"offer_role_label": offer_role_label,
		"reason": reason,
	}

func _second_reward_record_for(modifier_id: String) -> Dictionary:
	for record: Dictionary in second_reward_candidate_records:
		if String(record.get("modifier_id", "")) == modifier_id:
			return record.duplicate(true)
	return {}

func _selected_modifier_marker_text() -> String:
	var markers := PackedStringArray()
	if not session.reward_one_id.is_empty() and reward_defs.has(session.reward_one_id):
		var reward: ModifierDefinition = reward_defs[session.reward_one_id] as ModifierDefinition
		if reward != null:
			markers.append("%s (%s)" % [reward.display_name, reward.warehouse])
	if not session.shop_purchase_id.is_empty() and shop_defs.has(session.shop_purchase_id):
		var shop: ModifierDefinition = shop_defs[session.shop_purchase_id] as ModifierDefinition
		if shop != null:
			markers.append("%s (%s)" % [shop.display_name, shop.warehouse])
	if not session.second_reward_id.is_empty() and second_reward_defs.has(session.second_reward_id):
		var second_reward: ModifierDefinition = second_reward_defs[session.second_reward_id] as ModifierDefinition
		if second_reward != null:
			markers.append("%s (%s)" % [second_reward.display_name, second_reward.warehouse])
	if markers.is_empty():
		return "本局机器修正：无"
	return "本局机器修正：%s" % ", ".join(markers)

func _battle_modifier_payload() -> Dictionary:
	var payload: Dictionary = {
		"slot_primer": {
			"slot_id": 1,
		},
	}
	if not session.reward_one_id.is_empty():
		_ensure_planned_counter()
	if not planned_counter_id.is_empty() and counter_defs.has(planned_counter_id):
		payload["counter_definition"] = counter_defs[planned_counter_id]
		payload["counter_response_link"] = _counter_response_link()
	return payload

func _counter_response_link() -> String:
	if session.shop_purchase_id.is_empty():
		return "无"
	return _modifier_name(session.shop_purchase_id, shop_defs)

func _build_result_summary_text() -> String:
	return "守护者：%s\n第一次奖励：%s\n第一次商店：%s\n第二次奖励：%s | 当前主轴：%s | 定位：%s\nGold：%d\n休息：第一次商店 %d 次，战斗 3 后 %d 次，终点前 %d 次\n最后战斗：%s\n结果：%s" % [
		_guardian_name(session.selected_guardian_id),
		_modifier_name(session.reward_one_id, reward_defs),
		_modifier_name(session.shop_purchase_id, shop_defs),
		_modifier_name(session.second_reward_id, second_reward_defs),
		"未到达" if session.second_offer_current_axis.is_empty() else session.second_offer_current_axis,
		_second_reward_role_label(session.second_offer_choice_role),
		session.gold,
		session.first_shop_rest_count,
		session.battle_three_rest_count,
		session.endpoint_prep_rest_count,
		_battle_display_name(session.last_battle),
		_result_display_name(session.last_battle_result),
	]

func _battle_display_name(battle_id: String) -> String:
	match battle_id:
		RunSessionModel.NODE_BATTLE_1:
			return "战斗 1"
		RunSessionModel.NODE_BATTLE_2:
			return "战斗 2"
		RunSessionModel.NODE_BATTLE_3:
			return "战斗 3"
		"battle_4":
			return "战斗 4"
		RunSessionModel.NODE_BATTLE_5:
			return "战斗 5"
		RunSessionModel.NODE_ENDPOINT:
			return "终点战"
		_:
			return "未记录"

func _result_display_name(result: String) -> String:
	match result:
		RunSessionModel.RESULT_WIN:
			return "胜利"
		RunSessionModel.RESULT_LOSS:
			return "失败"
		_:
			return "未记录"

func _guardian_name(guardian_id: String) -> String:
	if guardian_id.is_empty() or not guardian_defs.has(guardian_id):
		return "未选择"
	var definition: GuardianDefinition = guardian_defs[guardian_id] as GuardianDefinition
	if definition == null:
		return guardian_id
	return definition.display_name

func _modifier_name(modifier_id: String, modifier_defs: Dictionary) -> String:
	if modifier_id.is_empty():
		return "无"
	if not modifier_defs.has(modifier_id):
		return modifier_id
	var definition: ModifierDefinition = modifier_defs[modifier_id] as ModifierDefinition
	if definition == null:
		return modifier_id
	return definition.display_name

func _second_reward_role_label(role_id: String) -> String:
	match role_id:
		"deepen_current_axis":
			return "深化当前主轴"
		"patch":
			return "补洞"
		"pivot":
			return "转向"
		_:
			return "未选择"
