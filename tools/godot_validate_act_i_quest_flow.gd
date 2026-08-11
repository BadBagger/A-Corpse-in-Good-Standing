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

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var narrative: Node = root.get_node_or_null("/root/N")
	if narrative == null:
		push_error("Narrative autoload N is unavailable.")
		quit(1)
		return

	var previous_snapshot: Dictionary = narrative.to_snapshot()
	narrative.clear_runtime_state(false)
	var ink_bridge := root.get_node_or_null("/root/InkBridge")
	if ink_bridge == null:
		failures.append("InkBridge is unavailable during Act I quest validation.")
	else:
		for knot_name in [
			"chandler_needs_salt",
			"chandler_watch_trade",
			"old_quay_tomas_topics",
			"old_quay_silent_bollards",
			"old_quay_bollard_petra",
			"old_quay_bollard_ledger",
			"old_quay_bollard_bride",
			"old_quay_bollards_all_seen",
			"old_quay_flask",
			"old_quay_rope_cleat",
			"prosper_before_watch",
			"prosper_forgiveness",
			"juno_needs_rate_card",
			"float_juno_table",
			"juno_regulator_trade",
			"juno_pool_before_permission",
			"juno_hot_pool_soak",
			"juno_warmth_expired",
			"float_staff_corner",
			"float_steam_screen",
			"harbormaster_checklist_desk",
			"harbormaster_sabine_door",
			"heartbeat_check_fail",
			"heartbeat_check_pass",
			"salt_market_public_recognition",
			"salt_market_boot_stall_after",
			"salt_market_fishmonger",
			"salt_market_lamp",
			"salt_market_confession_queue",
			"salt_market_church_sign_wet",
			"fish_hall_ice_table",
			"fish_hall_coroner_tag",
			"fish_hall_visitor_book",
			"fish_hall_drain",
			"chandler_wares",
			"chandler_chess_set",
			"church_poor_box",
			"church_stall_sign",
			"church_confession_booth",
			"teodor_needs_chit",
			"teodor_rate_card_booth",
			"registry_ledgers",
			"registry_roll_book",
			"registry_lamp_smoked",
			"registry_ledger_blocked",
			"registry_ledger_page",
			"registry_registrar_needs_manifest",
			"almshouse_cots",
			"almshouse_window",
			"sabine_act_i_audience",
		]:
			if ink_bridge.get_knot_lines(knot_name).is_empty():
				failures.append("Act I Rite Ink beat is unavailable: %s" % knot_name)

	var early_sabine := _play("HarbormasterOffice", "ToSabine", "walk", narrative)
	if bool(early_sabine.get("applied", false)):
		failures.append("Sabine exit applied before all three Rites were complete.")

	var blocked_boot_stall := _play("SaltMarket", "BootStall", "talk", narrative)
	if bool(blocked_boot_stall.get("applied", false)):
		failures.append("Boot stall aftermath was available before the market public-recognition beat.")

	_apply("OldQuay", "Tomas", "talk", narrative, failures)
	_expect_flag(narrative, "FL_tomas_topics_seen", failures)
	_expect_discovered(narrative, "cf_pride_list", failures)
	_expect_discovered(narrative, "cf_cow_leftroom", failures)
	_expect_discovered(narrative, "cf_greed_widows", failures)
	_apply("OldQuay", "SilentBollards", "talk", narrative, failures)
	_expect_flag(narrative, "FL_silent_bollards_seen", failures)
	_apply("OldQuay", "BollardPetra", "talk", narrative, failures)
	_expect_flag(narrative, "FL_bollard_petra_seen", failures)
	_apply("OldQuay", "BollardLedger", "talk", narrative, failures)
	_expect_flag(narrative, "FL_bollard_ledger_seen", failures)
	_apply("OldQuay", "BollardBride", "talk", narrative, failures)
	_expect_flag(narrative, "FL_bollard_bride_seen", failures)
	var row_report := _play("OldQuay", "Tomas", "talk", narrative)
	if String(row_report.get("resolved_ink_knot", "")) != "old_quay_bollards_all_seen":
		failures.append("Tomas did not switch to the all-three-bollards follow-up after Petra/Ledger/Bride were seen.")
	_expect_flag(narrative, "FL_bollard_row_reported", failures)
	_apply("OldQuay", "Flask", "use", narrative, failures)
	_expect_item(narrative, "IT_flask", failures)
	_expect_flag(narrative, "FL_flask_taken", failures)

	_apply("SaltMarket", "MarketCrowd", "use", narrative, failures)
	_expect_item(narrative, "BorrowedBoots", failures)
	_expect_flag(narrative, "FL_market_recognized", failures)
	_expect_flag(narrative, "FL_market_day_hint", failures)
	_expect_discovered(narrative, "cf_pride_voice", failures)
	_expect_not_known(narrative, "cf_cow_drink", failures)

	_apply("SaltMarket", "BootStall", "talk", narrative, failures)
	_expect_flag(narrative, "FL_boot_stall_after_seen", failures)

	_apply("SaltMarket", "Fishmonger", "talk", narrative, failures)
	_expect_flag(narrative, "FL_fishmonger_seen", failures)
	_expect_discovered(narrative, "cf_greed_scales", failures)
	_expect_discovered(narrative, "cf_cow_drink", failures)

	_apply("SaltMarket", "ConfessionQueue", "talk", narrative, failures)
	_expect_discovered(narrative, "cf_cruel_funeral", failures)

	_apply("SaltMarket", "WhaleOilLamp", "use", narrative, failures)
	_expect_flag(narrative, "FL_market_lamp_checked", failures)
	_play("SaltMarket", "ChurchSign", "use", narrative)
	_expect_no_flag(narrative, "FL_church_sign_wet", failures)
	_apply("SaltMarket", "ChurchSign", "wet", narrative, failures)
	_expect_flag(narrative, "FL_church_sign_wet", failures)

	_apply("FishHall", "IceTable", "use", narrative, failures)
	_expect_flag(narrative, "FL_body_fit_confirmed", failures)
	_apply("FishHall", "CoronerTag", "use", narrative, failures)
	_expect_item(narrative, "IT_coroner_tag", failures)
	_expect_flag(narrative, "FL_day_count_proven", failures)
	_expect_flag(narrative, "FL_knows_daycount", failures)
	_apply("FishHall", "VisitorBook", "use", narrative, failures)
	_expect_flag(narrative, "FL_sabine_absent_from_book", failures)
	_expect_discovered(narrative, "cf_pride_twice", failures)
	_expect_not_known(narrative, "cf_pride_eulogy", failures)
	_expect_not_known(narrative, "cf_cow_didntfight", failures)
	_play("FishHall", "Drain", "use", narrative)
	_expect_no_flag(narrative, "FL_fish_hall_drain_seen", failures)
	_apply("FishHall", "Drain", "wet", narrative, failures)
	_expect_flag(narrative, "FL_fish_hall_drain_seen", failures)

	_apply("ChurchOfTheDrowned", "PoorBox", "use", narrative, failures)
	_expect_discovered(narrative, "cf_greed_plate", failures)

	var blocked_rate_card := _play("ChurchOfTheDrowned", "RateCard", "use", narrative)
	if bool(blocked_rate_card.get("applied", false)):
		failures.append("Teodor's rate card was obtainable before Corvin had a confession chit.")

	_apply("ChurchOfTheDrowned", "ConfessionBooth", "use", narrative, failures)
	_expect_item(narrative, "IT_chit", failures)
	_expect_flag(narrative, "FL_church_booth_seen", failures)
	_expect_flag(narrative, "FL_chit_acquired", failures)

	var blocked_watch_before_salt := _play("BoneChandler", "ProsperWatch", "use", narrative)
	if bool(blocked_watch_before_salt.get("applied", false)):
		failures.append("Prosper watch was obtainable before Corvin scraped fresh salt.")
	_expect_no_item(narrative, "IT_watch", failures)

	_apply("OldQuay", "RopeCleat", "wet", narrative, failures)
	_expect_item(narrative, "IT_knuckle_salt", failures)

	var blocked_prosper := _play("Almshouse", "HalfCoinProsper", "use", narrative)
	if bool(blocked_prosper.get("applied", false)):
		failures.append("Prosper forgiveness was obtainable before recovering the watch.")

	_apply("BoneChandler", "Wares", "use", narrative, failures)
	_expect_flag(narrative, "FL_chandler_wares_seen", failures)
	_apply("BoneChandler", "ChessSet", "use", narrative, failures)
	_expect_flag(narrative, "FL_chandler_chess_seen", failures)
	_expect_not_known(narrative, "cf_cruel_receipts", failures)

	_apply("BoneChandler", "ProsperWatch", "use", narrative, failures)
	_expect_item(narrative, "IT_watch", failures)
	_expect_not_known(narrative, "cf_cruel_names", failures)

	_apply("Almshouse", "Cots", "use", narrative, failures)
	_expect_flag(narrative, "FL_almshouse_cots_seen", failures)
	_apply("Almshouse", "Window", "use", narrative, failures)
	_expect_flag(narrative, "FL_almshouse_window_seen", failures)
	_expect_not_known(narrative, "cf_cow_father", failures)

	_apply("Almshouse", "HalfCoinProsper", "use", narrative, failures)
	_expect_item(narrative, "IT_forgiveness", failures)
	_expect_flag(narrative, "FL_rite_debt", failures)
	_expect_not_known(narrative, "cf_greed_ring", failures)

	var blocked_ledger := _play("HarborRegistry", "KestrelLedger", "use", narrative)
	if bool(blocked_ledger.get("applied", false)):
		failures.append("Kestrel ledger page was obtainable before smoking the Registry lamp.")

	var blocked_registrar := _play("HarborRegistry", "Registrar", "talk", narrative)
	if bool(blocked_registrar.get("applied", false)):
		failures.append("Registrar duel was startable before the Kestrel manifest confession was discoverable.")

	_apply("HarborRegistry", "Ledgers", "use", narrative, failures)
	_expect_flag(narrative, "FL_registry_ledgers_seen", failures)

	_apply("HarborRegistry", "RollBook", "use", narrative, failures)
	_expect_not_known(narrative, "cf_pride_handwriting", failures)

	_play("HarborRegistry", "DeskLamp", "use", narrative)
	_expect_no_flag(narrative, "FL_registry_lamp_smoked", failures)
	_apply("HarborRegistry", "DeskLamp", "wet", narrative, failures)
	_expect_flag(narrative, "FL_registry_lamp_smoked", failures)

	_apply("HarborRegistry", "KestrelLedger", "use", narrative, failures)
	_expect_item(narrative, "IT_ledger_page", failures)
	_expect_flag(narrative, "FL_manifest_known", failures)
	_expect_discovered(narrative, "cf_bt_manifest", failures)

	_apply_registrar_duel(narrative, failures)
	_expect_item(narrative, "IT_name_writ", failures)
	_expect_flag(narrative, "FL_rite_name", failures)
	_expect_flag(narrative, "FL_registrar_sold_manifest", failures)
	_expect_spent(narrative, "cf_bt_manifest", failures)

	var blocked_regulator_before_rate_card := _play("GreyFloat", "BilgeRegulator", "use", narrative)
	if bool(blocked_regulator_before_rate_card.get("applied", false)):
		failures.append("Grey Float regulator was acquired before the Church rate card.")
	_expect_no_item(narrative, "IT_regulator", failures)

	_apply("ChurchOfTheDrowned", "RateCard", "use", narrative, failures)
	_expect_item(narrative, "IT_rate_card", failures)
	_expect_flag(narrative, "FL_teodor_owes", failures)
	_expect_flag(narrative, "FL_rate_card", failures)
	_expect_flag(narrative, "FL_kane_seen", failures)

	var blocked_pool := _play("GreyFloat", "HotPool", "use", narrative)
	if bool(blocked_pool.get("applied", false)):
		failures.append("Grey Float hot pool was usable before Juno granted permission.")

	_apply("GreyFloat", "JunoTable", "use", narrative, failures)
	_expect_flag(narrative, "FL_float_juno_table_seen", failures)
	var pool_after_table := _play("GreyFloat", "HotPool", "use", narrative)
	if bool(pool_after_table.get("applied", false)):
		failures.append("Grey Float hot pool was usable after Juno's table conversation but before the regulator trade.")

	_apply("GreyFloat", "BilgeRegulator", "use", narrative, failures)
	_expect_item(narrative, "IT_regulator", failures)
	_expect_flag(narrative, "FL_juno_met", failures)

	_apply("GreyFloat", "StaffCorner", "talk", narrative, failures)
	_expect_opponent_spoken(narrative, "cf_lust_float", failures)
	_expect_discovered(narrative, "cf_cow_apologize", failures)

	_apply("GreyFloat", "SteamScreen", "use", narrative, failures)
	_expect_flag(narrative, "FL_float_steam_seen", failures)

	_apply("HarbormasterOffice", "ChecklistDesk", "use", narrative, failures)
	_expect_flag(narrative, "FL_harbormaster_checklist_seen", failures)
	_apply("HarbormasterOffice", "SabineDoor", "use", narrative, failures)
	_expect_flag(narrative, "FL_harbormaster_sabine_door_seen", failures)

	var cold_heartbeat := _play("HarbormasterOffice", "ChecklistClerk", "use", narrative)
	if bool(cold_heartbeat.get("applied", false)):
		failures.append("Borrowed Heartbeat passed with the regulator but without Float warmth.")

	_apply("GreyFloat", "HotPool", "use", narrative, failures)
	_expect_flag(narrative, "FL_float_warmth_active", failures)

	_consume_warmth_steps(narrative, 3)
	_expect_no_flag(narrative, "FL_float_warmth_active", failures)
	_expect_flag(narrative, "FL_float_warmth_expired", failures)
	var wandered_heartbeat := _play("HarbormasterOffice", "ChecklistClerk", "use", narrative)
	if bool(wandered_heartbeat.get("applied", false)):
		failures.append("Borrowed Heartbeat passed after Float warmth expired across three room transitions.")

	var return_pool := _play("GreyFloat", "HotPool", "use", narrative)
	if String(return_pool.get("resolved_ink_knot", "")) != "juno_warmth_expired":
		failures.append("Returning to the hot pool after warmth expiry did not select the Juno expiry acknowledgement.")
	if not bool(return_pool.get("applied", false)):
		failures.append("Hot pool did not allow re-soak after warmth expiry: %s" % return_pool.get("message", ""))
	_expect_flag(narrative, "FL_float_warmth_active", failures)
	_expect_no_flag(narrative, "FL_float_warmth_expired", failures)
	_consume_warmth_steps(narrative, 1)
	_expect_flag(narrative, "FL_float_warmth_active", failures)
	_apply("HarbormasterOffice", "ChecklistClerk", "use", narrative, failures)
	_expect_flag(narrative, "FL_rite_heartbeat", failures)

	if not narrative.are_act_i_rites_complete():
		failures.append("Act I rites are not complete after simulated route.")

	var late_sabine := _play("HarbormasterOffice", "ToSabine", "walk", narrative)
	if not bool(late_sabine.get("applied", false)):
		failures.append("Sabine exit still blocked after all three Rites were complete.")
	if String(late_sabine.get("target_room", "")) != "SabineOffice":
		failures.append("Sabine exit did not target SabineOffice after completion.")

	_apply("SabineOffice", "SabineDesk", "talk", narrative, failures)
	_expect_flag(narrative, "FL_act_i_complete", failures)

	if not failures.is_empty():
		narrative.apply_snapshot(previous_snapshot, true)
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	narrative.apply_snapshot(previous_snapshot, true)
	print("Act I quest flow validation passed.")
	quit(0)

func _apply(room_name: String, hotspot_name: String, verb: String, narrative: Node, failures: Array[String]) -> void:
	var result := _play(room_name, hotspot_name, verb, narrative)
	if not bool(result.get("applied", false)):
		failures.append("%s/%s %s did not apply: %s" % [room_name, hotspot_name, verb, result.get("message", "")])

func _apply_registrar_duel(narrative: Node, failures: Array[String]) -> void:
	var result := _play("HarborRegistry", "Registrar", "talk", narrative, false)
	if String(result.get("duel_opponent", "")) != "registrar":
		failures.append("Registrar did not open the duel panel contract.")
		return
	var ink_bridge := root.get_node_or_null("/root/InkBridge")
	if ink_bridge == null:
		failures.append("InkBridge is unavailable during Registrar duel validation.")
	elif ink_bridge.get_knot_lines("registrar_duel_start").is_empty() or ink_bridge.get_knot_lines("registrar_duel_win").is_empty() or ink_bridge.get_knot_lines("registrar_duel_loss").is_empty():
		failures.append("Registrar duel Ink beats are not all available.")
	else:
		var start_lines: Array = ink_bridge.get_knot_lines("registrar_duel_start")
		if start_lines.is_empty() or String(start_lines[0].get("text", "")) != "You're the Vale boy.":
			failures.append("Registrar pre-duel staging did not start with the authored Vale-boy line.")

	var DuelPanel := load("res://game/ui/duel_panel.gd")
	var panel: CanvasLayer = DuelPanel.new()
	root.add_child(panel)
	panel.start_duel("registrar", narrative, result.get("duel_pool", []))
	_expect_duel_ui_snapshot(panel.get_ui_snapshot(), 19, "Accusation 1/8", "Salt 0/3", "Pick a confession", failures)

	var won := false
	for index in range(REGISTRAR_SCRIPTED_WIN.size()):
		var confession_id: String = REGISTRAR_SCRIPTED_WIN[index]
		var play_result: Dictionary = panel.play_confession(confession_id)
		if bool(play_result.get("lost", false)):
			failures.append("Registrar duel lost during scripted Godot UI route at %s: %s" % [confession_id, play_result.get("message", "")])
			break
		won = bool(play_result.get("won", false))
		if index == 0:
			_expect_duel_ui_snapshot(panel.get_ui_snapshot(), 17, "Accusation 2/8", "Salt 0/3", "Accepted:", failures)

	panel.queue_free()
	if not won:
		failures.append("Registrar duel did not win after scripted Godot UI route.")
		return

	_apply_reward_result(result, narrative)

func _expect_duel_ui_snapshot(snapshot: Dictionary, expected_options: int, expected_round: String, expected_salt: String, expected_status: String, failures: Array[String]) -> void:
	if not bool(snapshot.get("visible", false)):
		failures.append("Duel panel snapshot is not visible.")
	if not String(snapshot.get("title", "")).contains("Registrar"):
		failures.append("Duel panel title does not name the Registrar.")
	if String(snapshot.get("subtitle", "")).is_empty():
		failures.append("Duel panel subtitle is empty.")
	if String(snapshot.get("round", "")) != expected_round:
		failures.append("Duel panel round text mismatch: expected %s, got %s" % [expected_round, snapshot.get("round", "")])
	if String(snapshot.get("salt", "")) != expected_salt:
		failures.append("Duel panel salt text mismatch: expected %s, got %s" % [expected_salt, snapshot.get("salt", "")])
	if not String(snapshot.get("attack_meta", "")).contains("accusation"):
		failures.append("Duel panel attack metadata is missing accusation context.")
	if String(snapshot.get("attack", "")).length() < 12:
		failures.append("Duel panel attack text is too short to be readable.")
	if not String(snapshot.get("status", "")).contains(expected_status):
		failures.append("Duel panel status does not contain expected text: %s" % expected_status)
	if int(snapshot.get("option_count", -1)) != expected_options:
		failures.append("Duel panel option count mismatch: expected %d, got %s" % [expected_options, snapshot.get("option_count", "")])
	var option_texts: Array = snapshot.get("option_texts", [])
	if option_texts.is_empty():
		failures.append("Duel panel has no option text.")
	else:
		var first_option := String(option_texts[0])
		if not first_option.contains("W") or not first_option.contains("  "):
			failures.append("Duel panel options do not expose category and weight clearly.")
	if String(snapshot.get("option_hint", "")).is_empty():
		failures.append("Duel panel option hint is empty.")
	if String(snapshot.get("close_text", "")) != "Leave duel":
		failures.append("Duel panel close control is missing or mislabeled.")

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
	result = _resolve_alternate_result(result, narrative)
	result["resolved_ink_knot"] = _resolve_ink_knot(result, narrative)
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

func _resolve_ink_knot(result: Dictionary, narrative: Node) -> String:
	var knot_name := String(result.get("ink_knot", ""))
	if knot_name == "juno_hot_pool_soak" and narrative.has_act_i_flag("FL_float_warmth_expired"):
		return "juno_warmth_expired"
	return knot_name

func _resolve_alternate_result(result: Dictionary, narrative: Node) -> Dictionary:
	var alternate_flags: Array = result.get("alternate_requires_flags", [])
	if alternate_flags.is_empty():
		return result
	for flag_id in alternate_flags:
		if not narrative.has_act_i_flag(String(flag_id)):
			return result
	var resolved := result.duplicate(true)
	var alternate_message_text := String(resolved.get("alternate_message", ""))
	if not alternate_message_text.is_empty():
		resolved["message"] = alternate_message_text
	var alternate_knot := String(resolved.get("alternate_ink_knot", ""))
	if not alternate_knot.is_empty():
		resolved["ink_knot"] = alternate_knot
	var alternate_flags_set: Array = resolved.get("alternate_flags_set", [])
	if not alternate_flags_set.is_empty():
		resolved["flags_set"] = alternate_flags_set
		resolved["items_add"] = []
		resolved["confessions_discover"] = []
		resolved["confessions_spend"] = []
	return resolved

func _expect_item(narrative: Node, item_id: String, failures: Array[String]) -> void:
	if not narrative.has_item(item_id):
		failures.append("Missing expected item: %s" % item_id)

func _expect_no_item(narrative: Node, item_id: String, failures: Array[String]) -> void:
	if narrative.has_item(item_id):
		failures.append("Item should not be set yet: %s" % item_id)

func _expect_flag(narrative: Node, flag_id: String, failures: Array[String]) -> void:
	if not narrative.has_act_i_flag(flag_id):
		failures.append("Missing expected flag: %s" % flag_id)

func _expect_no_flag(narrative: Node, flag_id: String, failures: Array[String]) -> void:
	if narrative.has_act_i_flag(flag_id):
		failures.append("Flag should not be set yet: %s" % flag_id)

func _expect_spent(narrative: Node, confession_id: String, failures: Array[String]) -> void:
	if confession_id not in narrative.spent_confessions:
		failures.append("Missing spent confession: %s" % confession_id)

func _expect_discovered(narrative: Node, confession_id: String, failures: Array[String]) -> void:
	if confession_id not in narrative.discovered_confessions:
		failures.append("Missing discovered confession: %s" % confession_id)

func _expect_opponent_spoken(narrative: Node, confession_id: String, failures: Array[String]) -> void:
	if confession_id not in narrative.opponent_spoken_confessions:
		failures.append("Missing opponent-spoken confession: %s" % confession_id)

func _expect_not_known(narrative: Node, confession_id: String, failures: Array[String]) -> void:
	if confession_id in narrative.discovered_confessions:
		failures.append("Confession should not be discovered at this Act I point: %s" % confession_id)
	if confession_id in narrative.spent_confessions:
		failures.append("Confession should not be spent at this Act I point: %s" % confession_id)
	if confession_id in narrative.opponent_spoken_confessions:
		failures.append("Confession should not be opponent-spoken at this Act I point: %s" % confession_id)
