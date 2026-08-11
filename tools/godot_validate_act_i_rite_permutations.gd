extends SceneTree

const ROOM_SCENES := {
	"OldQuay": "res://game/rooms/old_quay/room_old_quay.tscn",
	"SaltMarket": "res://game/rooms/salt_market/room_salt_market.tscn",
	"FishHall": "res://game/rooms/fish_hall/room_fish_hall.tscn",
	"HarborRegistry": "res://game/rooms/harbor_registry/room_harbor_registry.tscn",
	"BoneChandler": "res://game/rooms/bone_chandler/room_bone_chandler.tscn",
	"Almshouse": "res://game/rooms/almshouse/room_almshouse.tscn",
	"ChurchOfTheDrowned": "res://game/rooms/church_of_the_drowned/room_church_of_the_drowned.tscn",
	"GreyFloat": "res://game/rooms/grey_float/room_grey_float.tscn",
	"HarbormasterOffice": "res://game/rooms/harbormaster_office/room_harbormaster_office.tscn",
	"SabineOffice": "res://game/rooms/sabine_office/room_sabine_office.tscn",
}

const REGISTRAR_SCRIPTED_WIN := [
	"cf_cruel_sentences",
	"cf_greed_boots",
	"cf_pride_list",
	"cf_cow_bigger",
	"cf_cow_passive",
	"cf_lust_schedule",
	"cf_pride_counselor",
	"cf_bt_manifest",
]

const PERMUTATIONS := [
	["name", "debt", "heartbeat"],
	["name", "heartbeat", "debt"],
	["debt", "name", "heartbeat"],
	["debt", "heartbeat", "name"],
	["heartbeat", "name", "debt"],
	["heartbeat", "debt", "name"],
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var narrative: Node = root.get_node_or_null("/root/N")
	if narrative == null:
		push_error("Narrative autoload N is unavailable.")
		quit(1)
		return

	var previous_snapshot: Dictionary = narrative.to_snapshot()
	var failures: Array[String] = []
	for order in PERMUTATIONS:
		narrative.clear_runtime_state(false)
		_run_permutation(order, narrative, failures)

	narrative.apply_snapshot(previous_snapshot, true)
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("Act I Rite permutation validation passed: %d orders." % PERMUTATIONS.size())
	quit(0)

func _run_permutation(order: Array, narrative: Node, failures: Array[String]) -> void:
	var label := " -> ".join(order)
	_expect_blocked(label, "initial Sabine gate", _play("HarbormasterOffice", "ToSabine", "walk", narrative), failures)
	_apply_common_discovery(label, narrative, failures)

	for index in range(order.size()):
		var rite := String(order[index])
		match rite:
			"name":
				_complete_name_rite(label, narrative, failures)
				_expect_flag(label, narrative, "FL_rite_name", failures)
				_expect_flag(label, narrative, "FL_registrar_sold_manifest", failures)
			"debt":
				_complete_debt_rite(label, narrative, failures)
				_expect_flag(label, narrative, "FL_rite_debt", failures)
			"heartbeat":
				_complete_heartbeat_rite(label, narrative, failures)
				_expect_flag(label, narrative, "FL_rite_heartbeat", failures)
			_:
				failures.append("%s has unknown Rite id: %s" % [label, rite])

		if index < order.size() - 1:
			_expect_blocked(label, "Sabine gate after %s" % rite, _play("HarbormasterOffice", "ToSabine", "walk", narrative), failures)

	if not narrative.are_act_i_rites_complete():
		failures.append("%s did not complete all three Rites." % label)

	var sabine_exit := _play("HarbormasterOffice", "ToSabine", "walk", narrative)
	if not bool(sabine_exit.get("applied", false)):
		failures.append("%s left Sabine gate blocked after all Rites: %s" % [label, sabine_exit.get("message", "")])
	if String(sabine_exit.get("target_room", "")) != "SabineOffice":
		failures.append("%s Sabine exit target mismatch: %s" % [label, sabine_exit.get("target_room", "")])

	_apply(label, "SabineOffice", "SabineDesk", "talk", narrative, failures)
	_expect_flag(label, narrative, "FL_act_i_complete", failures)

func _apply_common_discovery(label: String, narrative: Node, failures: Array[String]) -> void:
	_apply(label, "OldQuay", "Tomas", "talk", narrative, failures)
	_expect_discovered(label, narrative, "cf_pride_list", failures)
	_expect_discovered(label, narrative, "cf_cow_leftroom", failures)
	_expect_discovered(label, narrative, "cf_greed_widows", failures)
	_apply(label, "SaltMarket", "MarketCrowd", "use", narrative, failures)
	_apply(label, "SaltMarket", "Fishmonger", "talk", narrative, failures)
	_apply(label, "SaltMarket", "ConfessionQueue", "talk", narrative, failures)
	_apply(label, "SaltMarket", "WhaleOilLamp", "use", narrative, failures)
	_expect_no_flag(label, narrative, "FL_church_sign_wet", failures)
	_apply(label, "SaltMarket", "ChurchSign", "wet", narrative, failures)
	_expect_flag(label, narrative, "FL_church_sign_wet", failures)

	_apply(label, "FishHall", "IceTable", "use", narrative, failures)
	_apply(label, "FishHall", "CoronerTag", "use", narrative, failures)
	_apply(label, "FishHall", "VisitorBook", "use", narrative, failures)
	_expect_no_flag(label, narrative, "FL_fish_hall_drain_seen", failures)
	_apply(label, "FishHall", "Drain", "wet", narrative, failures)

	_apply(label, "ChurchOfTheDrowned", "PoorBox", "use", narrative, failures)
	_expect_blocked(label, "Teodor rate card before confession chit", _play("ChurchOfTheDrowned", "RateCard", "use", narrative), failures)
	_apply(label, "ChurchOfTheDrowned", "ConfessionBooth", "use", narrative, failures)
	_expect_item(label, narrative, "IT_chit", failures)
	_apply(label, "OldQuay", "RopeCleat", "wet", narrative, failures)
	_expect_item(label, narrative, "IT_knuckle_salt", failures)

func _complete_name_rite(label: String, narrative: Node, failures: Array[String]) -> void:
	if not narrative.has_act_i_flag("FL_registry_lamp_smoked"):
		_expect_blocked(label, "Kestrel ledger before lamp", _play("HarborRegistry", "KestrelLedger", "use", narrative), failures)
	if not narrative.has_act_i_flag("FL_manifest_known"):
		_expect_blocked(label, "Registrar before manifest", _play("HarborRegistry", "Registrar", "talk", narrative), failures)

	_apply(label, "HarborRegistry", "Ledgers", "use", narrative, failures)
	_apply(label, "HarborRegistry", "RollBook", "use", narrative, failures)
	if not narrative.has_act_i_flag("FL_registry_lamp_smoked"):
		_expect_no_flag(label, narrative, "FL_registry_lamp_smoked", failures)
		_apply(label, "HarborRegistry", "DeskLamp", "wet", narrative, failures)
	_expect_flag(label, narrative, "FL_registry_lamp_smoked", failures)
	_apply(label, "HarborRegistry", "KestrelLedger", "use", narrative, failures)
	_expect_item(label, narrative, "IT_ledger_page", failures)
	_expect_discovered(label, narrative, "cf_bt_manifest", failures)

	_apply_registrar_duel(label, narrative, failures)

func _complete_debt_rite(label: String, narrative: Node, failures: Array[String]) -> void:
	if not narrative.has_item("IT_watch"):
		_expect_blocked(label, "Prosper before watch", _play("Almshouse", "HalfCoinProsper", "use", narrative), failures)
		_apply(label, "BoneChandler", "Wares", "use", narrative, failures)
		_apply(label, "BoneChandler", "ChessSet", "use", narrative, failures)
		_apply(label, "BoneChandler", "ProsperWatch", "use", narrative, failures)
		_expect_item(label, narrative, "IT_watch", failures)

	_apply(label, "Almshouse", "Cots", "use", narrative, failures)
	_apply(label, "Almshouse", "Window", "use", narrative, failures)
	_apply(label, "Almshouse", "HalfCoinProsper", "use", narrative, failures)
	_expect_item(label, narrative, "IT_forgiveness", failures)

func _complete_heartbeat_rite(label: String, narrative: Node, failures: Array[String]) -> void:
	if not narrative.has_item("IT_rate_card"):
		_apply(label, "ChurchOfTheDrowned", "RateCard", "use", narrative, failures)
		_expect_item(label, narrative, "IT_rate_card", failures)

	if not narrative.has_act_i_flag("FL_juno_met"):
		_expect_blocked(label, "Hot pool before Juno permission", _play("GreyFloat", "HotPool", "use", narrative), failures)
		_apply(label, "GreyFloat", "JunoTable", "use", narrative, failures)
		_expect_blocked(label, "Hot pool after Juno table but before regulator trade", _play("GreyFloat", "HotPool", "use", narrative), failures)
		_apply(label, "GreyFloat", "BilgeRegulator", "use", narrative, failures)
		_expect_item(label, narrative, "IT_regulator", failures)
		_expect_flag(label, narrative, "FL_juno_met", failures)

	var lust_float_locked_before_staff: bool = "cf_lust_float" in narrative.opponent_spoken_confessions
	_apply(label, "GreyFloat", "StaffCorner", "talk", narrative, failures)
	if lust_float_locked_before_staff:
		if "cf_lust_float" in narrative.discovered_confessions:
			failures.append("%s StaffCorner discovered cf_lust_float after Registrar had locked it as opponent-spoken." % label)
	else:
		_expect_discovered(label, narrative, "cf_lust_float", failures)
	_apply(label, "GreyFloat", "SteamScreen", "use", narrative, failures)

	if not narrative.has_act_i_flag("FL_float_warmth_active"):
		_expect_blocked(label, "clerk before Float warmth", _play("HarbormasterOffice", "ChecklistClerk", "use", narrative), failures)
		_apply(label, "GreyFloat", "HotPool", "use", narrative, failures)
		_expect_flag(label, narrative, "FL_float_warmth_active", failures)

	_consume_warmth_steps(narrative, 1)
	_expect_flag(label, narrative, "FL_float_warmth_active", failures)
	_apply(label, "HarbormasterOffice", "ChecklistClerk", "use", narrative, failures)

func _apply_registrar_duel(label: String, narrative: Node, failures: Array[String]) -> void:
	var result := _play("HarborRegistry", "Registrar", "talk", narrative, false)
	if String(result.get("duel_opponent", "")) != "registrar":
		failures.append("%s Registrar did not open duel contract." % label)
		return

	var DuelPanel := load("res://game/ui/duel_panel.gd")
	var panel: CanvasLayer = DuelPanel.new()
	root.add_child(panel)
	panel.start_duel("registrar", narrative, result.get("duel_pool", []))

	var won := false
	for confession_id in REGISTRAR_SCRIPTED_WIN:
		var play_result: Dictionary = panel.play_confession(String(confession_id))
		if bool(play_result.get("lost", false)):
			failures.append("%s Registrar duel lost at %s: %s" % [label, confession_id, play_result.get("message", "")])
			break
		won = bool(play_result.get("won", false))
	panel.queue_free()

	if not won:
		failures.append("%s Registrar duel did not win after scripted route." % label)
		return
	_apply_reward_result(result, narrative)

func _apply(label: String, room_name: String, hotspot_name: String, verb: String, narrative: Node, failures: Array[String]) -> void:
	var result := _play(room_name, hotspot_name, verb, narrative)
	if not bool(result.get("applied", false)):
		failures.append("%s %s/%s %s did not apply: %s" % [label, room_name, hotspot_name, verb, result.get("message", "")])

func _play(room_name: String, hotspot_name: String, verb: String, narrative: Node, apply_result := true) -> Dictionary:
	var scene_path := String(ROOM_SCENES.get(room_name, ""))
	if scene_path.is_empty():
		return {"applied": false, "message": "Unknown room %s" % room_name}
	var packed: PackedScene = load(scene_path)
	if packed == null:
		return {"applied": false, "message": "Could not load %s" % scene_path}
	var instance := packed.instantiate()
	var hotspot := instance.get_node_or_null("Hotspots/%s" % hotspot_name)
	if hotspot == null:
		instance.free()
		return {"applied": false, "message": "Missing hotspot %s/%s" % [room_name, hotspot_name]}
	if not hotspot.has_method("handle_room_verb"):
		instance.free()
		return {"applied": false, "message": "Hotspot has no handle_room_verb: %s/%s" % [room_name, hotspot_name]}

	var result: Dictionary = hotspot.handle_room_verb(verb)
	for required_flag in result.get("requires_flags", []):
		if not narrative.has_act_i_flag(String(required_flag)):
			result["applied"] = false
			instance.free()
			return result
	for required_item in result.get("requires_items", []):
		if not narrative.has_item(String(required_item)):
			result["applied"] = false
			instance.free()
			return result
	if apply_result and String(result.get("duel_opponent", "")).is_empty():
		_apply_reward_result(result, narrative)

	result["applied"] = String(result.get("duel_opponent", "")).is_empty() or not apply_result
	instance.free()
	return result

func _apply_reward_result(result: Dictionary, narrative: Node) -> void:
	for item_id in result.get("items_add", []):
		narrative.add_item(String(item_id))
	for flag_id in result.get("flags_set", []):
		if narrative.has_method("apply_act_i_flag_reward"):
			narrative.apply_act_i_flag_reward(String(flag_id))
		else:
			narrative.set_act_i_flag(String(flag_id), true)
	for confession_id in result.get("confessions_discover", []):
		narrative.discover_confession(String(confession_id))
	for confession_id in result.get("confessions_spend", []):
		narrative.spend_confession(String(confession_id))

func _consume_warmth_steps(narrative: Node, steps: int) -> void:
	for _index in range(steps):
		if narrative.has_method("consume_float_warmth_room_step"):
			narrative.consume_float_warmth_room_step()

func _expect_blocked(label: String, context: String, result: Dictionary, failures: Array[String]) -> void:
	if bool(result.get("applied", false)):
		failures.append("%s expected blocked interaction applied: %s" % [label, context])

func _expect_item(label: String, narrative: Node, item_id: String, failures: Array[String]) -> void:
	if not narrative.has_item(item_id):
		failures.append("%s missing expected item: %s" % [label, item_id])

func _expect_flag(label: String, narrative: Node, flag_id: String, failures: Array[String]) -> void:
	if not narrative.has_act_i_flag(flag_id):
		failures.append("%s missing expected flag: %s" % [label, flag_id])

func _expect_no_flag(label: String, narrative: Node, flag_id: String, failures: Array[String]) -> void:
	if narrative.has_act_i_flag(flag_id):
		failures.append("%s flag should not be set yet: %s" % [label, flag_id])

func _expect_discovered(label: String, narrative: Node, confession_id: String, failures: Array[String]) -> void:
	if confession_id not in narrative.discovered_confessions:
		failures.append("%s missing discovered confession: %s" % [label, confession_id])
