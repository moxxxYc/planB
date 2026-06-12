class_name MvpRunSession
extends Control

const GuardianContractViewScript := preload("res://scripts/ui/run/guardian_contract_view.gd")
const RewardChoiceViewScript := preload("res://scripts/ui/run/reward_choice_view.gd")
const ShopRestViewScript := preload("res://scripts/ui/run/shop_rest_view.gd")
const RunResultViewScript := preload("res://scripts/ui/run/run_result_view.gd")
const RunHudViewScript := preload("res://scripts/ui/run/run_hud_view.gd")
const CounterDefinitionScript := preload("res://scripts/data/counter_definition.gd")

const BATTLE_SCENE_PATH: String = "res://scenes/run/battle_one_vertical.tscn"
const BATTLE_AUTO_ROUTE_DWELL_SECONDS: float = 0.6

@onready var hud_slot: Control = %HudSlot
@onready var screen_slot: Control = %ScreenSlot

var session: RunSessionModel = RunSessionModel.new()
var guardian_defs: Dictionary = {}
var reward_defs: Dictionary = {}
var shop_defs: Dictionary = {}
var counter_defs: Dictionary = {}
var next_counter_override: String = ""
var planned_counter_id: String = ""
var hud_view = null
var active_battle: BattleOneVertical = null
var active_result_view = null
var battle_auto_route_timer: float = 0.0
var shell_styles_applied: bool = false

func _enter_tree() -> void:
	_ensure_catalogs()

func _ready() -> void:
	_ensure_shell_ready()
	_ensure_hud()
	_render_current_node()

func _process(delta: float) -> void:
	_poll_active_battle(delta)

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
	session.confirm_shop_and_rest()
	_render_current_node()

func set_next_counter_for_verifier(counter_id: String) -> void:
	_ensure_catalogs()
	if not counter_defs.has(counter_id):
		push_error("Unknown M3 counter: %s" % counter_id)
		return
	next_counter_override = counter_id
	planned_counter_id = counter_id

func get_counter_scout_text() -> String:
	_ensure_catalogs()
	_ensure_planned_counter()
	var definition: Resource = counter_defs.get(planned_counter_id, null) as Resource
	if definition == null:
		return "反制侦测：暂无"
	return String(definition.call("to_scout_text"))

func get_result_summary_text() -> String:
	if active_result_view != null:
		return active_result_view.get_summary_text()
	return _build_result_summary_text()

func get_result_record() -> Dictionary:
	return session.result_record.duplicate(true)

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

func _show_shop_rest(p_hide_shop: bool) -> void:
	var view = ShopRestViewScript.new()
	_add_screen_child(view)
	view.shop_item_bought.connect(_on_shop_item_bought)
	view.rest_bought.connect(_on_rest_bought)
	view.confirmed.connect(_on_shop_rest_confirmed)
	view.render(shop_defs, session, p_hide_shop)

func _show_result() -> void:
	var view = RunResultViewScript.new()
	active_result_view = view
	_add_screen_child(view)
	view.render(session, guardian_defs, reward_defs, shop_defs)

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

func _on_shop_item_bought(modifier_id: String) -> void:
	buy_shop_item(modifier_id)

func _on_rest_bought() -> void:
	buy_rest()

func _on_shop_rest_confirmed() -> void:
	if session.current_node_id == RunSessionModel.NODE_SHOP_1:
		confirm_shop_and_rest()
	elif session.current_node_id == RunSessionModel.NODE_REST_AFTER_BATTLE_3:
		session.confirm_battle_three_rest()
		_render_current_node()

func _complete_active_battle(battle_result: String) -> void:
	if not _is_battle_node(session.current_node_id):
		push_error("Cannot complete non-battle run node: %s" % session.current_node_id)
		return
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
	hud_view.render(session, guardian_defs, reward_defs, shop_defs)

func _add_screen_child(child: Control) -> void:
	_ensure_shell_ready()
	if screen_slot == null:
		return
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	child.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen_slot.add_child(child)

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
	if guardian_defs.is_empty() or reward_defs.is_empty() or shop_defs.is_empty() or counter_defs.is_empty():
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
			"Pool Pocket",
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
			"Prime Charge",
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
			"Slot Primer",
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
			"Front Recycle",
			ModifierDefinition.SourceType.SHOP,
			"Launch",
			"Launch.Recycle.return_position",
			"回流到队列前段",
			"转向",
			5,
			"Recycle 回到更靠前的位置，服务 Launch 轴的持续供给。"
		),
		"surge_buffer": _make_modifier(
			"surge_buffer",
			"Surge Buffer",
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
			"Queue Brace",
			ModifierDefinition.SourceType.SHOP,
			"Unit",
			"Unit.Queue.empty_gap_response",
			"队列空档时补进度",
			"补洞",
			4,
			"Queue 空档有补强读法，让部署节奏更容易被看懂。"
		),
	}

	counter_defs = {
		"pool_polluter": _make_counter(
			"pool_polluter",
			"Pool Polluter",
			"Pool",
			4.0,
			18.0,
			"Junk 插入 Pool",
			["junk_sieve", "pool_pocket"]
		),
		"echo_breaker": _make_counter(
			"echo_breaker",
			"Echo Breaker",
			"Echo / Surge 价值",
			4.0,
			14.0,
			"Echo 复制降级为 Gate",
			["surge_buffer", "prime_charge"]
		),
		"stagger_punisher": _make_counter(
			"stagger_punisher",
			"Stagger Punisher",
			"Queue 空档",
			3.0,
			16.0,
			"Raider 因 Queue 空档出现",
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
	source_type: int,
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

func _make_counter(
	id: String,
	display_name: String,
	target_component: String,
	warning_seconds: float,
	active_seconds: float,
	visible_effect: String,
	patch_ids: Array[String]
) -> Resource:
	var definition = CounterDefinitionScript.new()
	definition.id = id
	definition.display_name = display_name
	definition.target_component = target_component
	definition.warning_seconds = warning_seconds
	definition.active_seconds = active_seconds
	definition.visible_effect = visible_effect
	definition.patch_ids = patch_ids.duplicate()
	return definition

func _ensure_planned_counter() -> void:
	if not planned_counter_id.is_empty() and counter_defs.has(planned_counter_id):
		return
	if not next_counter_override.is_empty() and counter_defs.has(next_counter_override):
		planned_counter_id = next_counter_override
		return
	planned_counter_id = "pool_polluter"

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
	if markers.is_empty():
		return "本局机器修正：无"
	return "本局机器修正：%s" % ", ".join(markers)

func _battle_modifier_payload() -> Dictionary:
	return {
		"slot_primer": {
			"slot_id": 1,
		},
	}

func _build_result_summary_text() -> String:
	return "守护者：%s\n第一次奖励：%s\n第一次商店：%s\nGold：%d\n休息：第一次商店 %d 次，战斗 3 后 %d 次\n最后战斗：%s\n结果：%s\n下一步：M2 到此结束，等待后续里程碑确认。" % [
		_guardian_name(session.selected_guardian_id),
		_modifier_name(session.reward_one_id, reward_defs),
		_modifier_name(session.shop_purchase_id, shop_defs),
		session.gold,
		session.first_shop_rest_count,
		session.battle_three_rest_count,
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
