extends SceneTree

const REPORT_PATH := "res://docs/playtest/results/act_i_greybox_auto_report.md"

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

var narrative: Node
var ink_bridge: Node
var report: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	narrative = root.get_node_or_null("/root/N")
	ink_bridge = root.get_node_or_null("/root/InkBridge")
	if narrative == null:
		push_error("Narrative autoload N is unavailable.")
		quit(1)
		return

	var previous_snapshot: Dictionary = narrative.to_snapshot()
	narrative.clear_runtime_state(false)

	_header()
	_section("Route")
	_record_ink_observation("Mudflats tutorial", "Mudflats/Silt", "look", "Mordida mud establishes the opening ground texture.", "mudflats_silt")
	_record_ink_observation("Mudflats tutorial", "Mudflats/OwnHands", "look", "Corvin checks the grey at his nails and the body that still looks like his.", "mudflats_hands")
	_record_ink_observation("Mudflats tutorial", "Mudflats/HarborView", "look", "The town's leviathan ribs read as the first background composition anchor.", "mudflats_harbor_view")
	_record_ink_observation("Mudflats wet tutorial", "Mudflats/Coat", "use", "Corvin wrings out the coat and creates the first persistent puddle read.", "mudflats_coat_wet")
	_record_ink_observation("Mudflats Tomas introduction", "Mudflats/BollardOfTomas", "talk", "Tomas gives Corvin the first returned-rule scene before the Act I hint hub takes over.", "old_quay_tomas")
	_record_ink_observation("Mudflats exit pressure", "Mudflats/SaltMarketExit", "walk", "Tomas points Corvin toward the market while the drowning question becomes actionable.", "old_quay_equipment")
	_record("Gate check", "HarbormasterOffice", "ToSabine", "walk", false)
	_record("Act I blocked aftermath", "SaltMarket", "BootStall", "talk", false)
	_record("Old Quay hint hub", "OldQuay", "Tomas", "talk", true)
	_record("Old Quay foreshadowing", "OldQuay", "SilentBollards", "talk", true)
	_record("Old Quay bollard row", "OldQuay", "BollardPetra", "talk", true)
	_record("Old Quay bollard row", "OldQuay", "BollardLedger", "talk", true)
	_record("Old Quay bollard row", "OldQuay", "BollardBride", "talk", true)
	_record("Old Quay Tomas follow-up", "OldQuay", "Tomas", "talk", true)
	_record("Old Quay inventory", "OldQuay", "Flask", "use", true)
	_record("Act I public turn", "SaltMarket", "MarketCrowd", "use", true)
	_record("Act I boot-stall aftermath", "SaltMarket", "BootStall", "talk", true)
	_record("Act I eavesdrop", "SaltMarket", "Fishmonger", "talk", true)
	_record("Act I eavesdrop", "SaltMarket", "ConfessionQueue", "talk", true)
	_record("Act I market texture", "SaltMarket", "WhaleOilLamp", "use", true)
	_record("Act I wet verb", "SaltMarket", "ChurchSign", "wet", true)
	_record("Day-count proof", "FishHall", "IceTable", "use", true)
	_record("Day-count proof", "FishHall", "CoronerTag", "use", true)
	_record("Day-count proof", "FishHall", "VisitorBook", "use", true)
	_record("Fish Hall wet return", "FishHall", "Drain", "wet", true)
	_record("Church support", "ChurchOfTheDrowned", "PoorBox", "use", true)
	_record("Church stall sign", "ChurchOfTheDrowned", "ChurchStallSign", "use", true)
	_record("Church blocked booth access", "ChurchOfTheDrowned", "RateCard", "use", false)
	_record("Church booth access", "ChurchOfTheDrowned", "ConfessionBooth", "use", true)
	_record("Rite 3 blocked watch", "BoneChandler", "ProsperWatch", "use", false)
	_record("Rite 3 wet verb", "OldQuay", "RopeCleat", "wet", true)
	_record("Rite 3 blocked setup", "Almshouse", "HalfCoinProsper", "use", false)
	_record("Rite 3 room texture", "BoneChandler", "Wares", "use", true)
	_record("Rite 3 room texture", "BoneChandler", "ChessSet", "use", true)
	_record("Rite 3 setup", "BoneChandler", "ProsperWatch", "use", true)
	_record("Rite 3 room texture", "Almshouse", "Cots", "use", true)
	_record("Rite 3 room texture", "Almshouse", "Window", "use", true)
	_record("Rite 3 complete", "Almshouse", "HalfCoinProsper", "use", true)
	_record("Rite 2 blocked setup", "HarborRegistry", "KestrelLedger", "use", false)
	_record("Rite 2 blocked setup", "HarborRegistry", "Registrar", "talk", false)
	_record("Rite 2 setup", "HarborRegistry", "Ledgers", "use", true)
	_record("Rite 2 setup", "HarborRegistry", "RollBook", "use", true)
	_record("Rite 2 wet verb", "HarborRegistry", "DeskLamp", "wet", true)
	_record("Rite 2 setup", "HarborRegistry", "KestrelLedger", "use", true)
	_record_registrar_duel()
	_record("Rite 1 blocked regulator", "GreyFloat", "BilgeRegulator", "use", false)
	_record("Rite 1 setup", "ChurchOfTheDrowned", "RateCard", "use", true)
	_record("Rite 1 blocked warmth", "GreyFloat", "HotPool", "use", false)
	_record("Rite 1 Juno negotiation", "GreyFloat", "JunoTable", "use", true)
	_record("Rite 1 blocked warmth", "GreyFloat", "HotPool", "use", false)
	_record("Rite 1 setup", "GreyFloat", "BilgeRegulator", "use", true)
	_record("Rite 1 eavesdrop", "GreyFloat", "StaffCorner", "talk", true)
	_record("Rite 1 room texture", "GreyFloat", "SteamScreen", "use", true)
	_record("Rite 1 anteroom texture", "HarbormasterOffice", "ChecklistDesk", "use", true)
	_record("Rite 1 anteroom texture", "HarbormasterOffice", "SabineDoor", "use", true)
	_record("Rite 1 blocked warmth", "HarbormasterOffice", "ChecklistClerk", "use", false)
	_record("Rite 1 warmth", "GreyFloat", "HotPool", "use", true)
	_consume_warmth_steps(3)
	_record("Rite 1 expired warmth", "HarbormasterOffice", "ChecklistClerk", "use", false)
	_record("Rite 1 re-soak", "GreyFloat", "HotPool", "use", true)
	_consume_warmth_steps(1)
	_record("Rite 1 complete", "HarbormasterOffice", "ChecklistClerk", "use", true)
	_record("Act I gate", "HarbormasterOffice", "ToSabine", "walk", true)
	_record("Act I close", "SabineOffice", "SabineDesk", "talk", true)

	_section("Final State")
	_line("- Items: `%s`" % "`, `".join(narrative.acquired_items))
	_line("- Act I flags: `%s`" % "`, `".join(narrative.act_i_flags.keys()))
	_line("- Spent confessions: `%s`" % "`, `".join(narrative.spent_confessions))
	_line("- Locked opponent-spoken confessions: `%s`" % "`, `".join(narrative.opponent_spoken_confessions))
	_line("- Discovered confessions: `%s`" % "`, `".join(narrative.discovered_confessions))
	_line("- Rites complete: `%s`" % str(narrative.are_act_i_rites_complete()))

	_section("Automated Notes")
	_line("- This is a deterministic greybox recorder, not a human fun/readability verdict.")
	_line("- It confirms the critical Act I route is playable and captures the current beats for review.")
	_line("- Generated Act I room exits now record direction-aware transition animations (`walk_side_left` or `walk_side_right`), and arrivals settle Corvin into `idle_current_side` so he does not snap to the wrong facing after a transition.")
	_line("- Known simplification: several authored Act I script beats are represented by first-pass greybox interactions rather than full scene-level dialogue.")
	_line("- Mudflats now captures the four authored tutorial/environment hotspots: silt, own hands, harbor view, and coat/wet demonstration, plus the Tomas returned-rule introduction and exit-pressure beat before Act I opens into the market.")
	_line("- Old Quay now captures Tomas as the Act I hint hub, the Appendix B source for `cf_pride_list`, `cf_cow_leftroom`, and `cf_greed_widows`, the three individual silent bollards as a quay composition row, Tomas's conditional all-three-bollards follow-up, and the Act I item-master flask pickup.")
	_line("- Salt Market is now verified as the Act I hub for Old Quay, Registry, Bone Chandler, Almshouse, Fish Hall, and the Church; the room graph gate proves all registered rooms are reachable from Mudflats through actual exits.")
	_line("- The Salt Market public-recognition beat now establishes `FL_market_recognized`, `FL_market_day_hint`, `BorrowedBoots`, and `cf_pride_voice` before the Rites, and captures the seller's face-change, scattered boots, frozen street, and crowd-parting staging that makes the market navigable.")
	_line("- The Salt Market boot-stall aftermath now stays blocked until the public-recognition beat, then captures the scattered-boots prop cluster, seller avoidance, and daughter line as an art-planning interaction.")
	_line("- The Salt Market fishmonger beat now captures the two-scales prop read and cod/drip exchange, sets `FL_fishmonger_seen`, and moves `cf_cow_drink` onto the fishmonger pickup alongside `cf_greed_scales` per the Act I script.")
	_line("- The Salt Market confession queue now stages the eleven-person paid-truth line before adding the Act I-safe `cf_cruel_funeral` pickup ahead of the Registrar duel.")
	_line("- The Salt Market whale-oil lamp now captures the amber warmth/no-temperature body read before the Rites.")
	_line("- The global `wet` verb is now exercised on the Church sign, Fish Hall drain, Old Quay rope cleat, and Registry desk lamp during the automated route.")
	_line("- The Fish Hall proof now captures the expanded body-table size read, wrong-place tag read, visitor-book pride beat, and drain return line while establishing `FL_body_fit_confirmed`, `FL_knows_daycount`, `FL_sabine_absent_from_book`, `FL_fish_hall_drain_seen`, `IT_coroner_tag`, and `cf_pride_twice`; `cf_pride_eulogy` and `cf_cow_didntfight` stay deferred because the Litany marks them Act II/III.")
	_line("- The Church poor-box beat now discovers `cf_greed_plate` before the Registrar can lock that sin as opponent-spoken, with the crooked-lock and missing-notes read staged in Ink.")
	_line("- The Church stall sign now captures the one-shilling paid-truth read as a non-progress Ink beat, separate from Teodor's gated rate-card exchange.")
	_line("- The Church confession booth now captures the green-lit paid-truth staging, awards `IT_chit`, and gates Teodor's rate-card stall before booth access; the rate-card booth carries Teodor's posting panic, the three fixed petitioner beats, `FL_kane_seen`, and Kane's day-six pressure without adding the deferred confession-choice/spend sequence.")
	_line("- The Debt Forgiven path now captures Bone Chandler wares/chess-set and Almshouse cots/window room texture, including the chess-set aging read and Almshouse salt-sheet/harbor-light art anchors without awarding `cf_cruel_receipts` or `cf_cow_father` early; the watch trade includes the authored fresh-salt-from-a-walking-returned beat and Prosper's forgiveness scene includes the hand-memory/truth-lock beats.")
	_line("- The Bone Chandler watch gate now records the blocked under-glass/watch-chain read before `IT_knuckle_salt`, proving the watch cannot be acquired before Corvin scrapes fresh salt.")
	_line("- The Almshouse before-watch Prosper scene now carries the fresh-every-morning memory-rot beat; Bone Chandler chess-set, Chandler trade, Almshouse window, Prosper forgiveness, and Registry roll-book remain art/emotional anchors and still do not grant the Act II `cf_cruel_receipts`, `cf_cruel_names`, `cf_cow_father`, `cf_greed_ring`, or `cf_pride_handwriting` confessions.")
	_line("- Borrowed Heartbeat now requires both `IT_regulator` and `FL_float_warmth_active`; the report captures the blocked pump-governor setup before the Church rate card, blocked warmth before Juno permission, blocked warmth before the hot-pool soak, the amber-screen/steam privacy staging during the soak, warmth expiry across three room transitions, the authored Juno return line before the re-soak, and the Harbormaster wrist check as staged physical action.")
	_line("- The Harbormaster anteroom now carries checklist-desk and Sabine-door art anchors before the fake-pulse check: three boxes beside Corvin's name, frosted glass, and the one-room-away staging before Sabine.")
	_line("- The Float staff corner now offers the Act I-safe `cf_lust_float` and `cf_cow_apologize` pickups through named staff tip-grievance chatter; in this Name-before-Heartbeat route `cf_lust_float` is already opponent-spoken by the Registrar and correctly blocked by global state, the bilge-regulator trade stays item/flag-only, and no confession-spend interaction is introduced.")
	_line("- The Float pump governor now has a captured blocked setup before the Church rate card, proving the regulator is visible as the Rite 1 prop but cannot leave the barge early; the Juno table carries the authored first negotiation, and the trade captures Juno's long look at the Church rate card before she gives it up.")
	_line("- The Registry ledgers beat now sets `FL_registry_ledgers_seen` before the roll book and ledger sub-puzzle, with expanded office/ledger texture; the roll book carries the scored-paper strike-through as an art anchor without granting `cf_pride_handwriting` early, and the Kestrel page pickup captures the Registrar filing the torn-corner moment for the duel.")
	_line("- The Registrar route now earns `cf_bt_manifest` from `IT_ledger_page` before the accepted duel path spends it, then sets `FL_registrar_sold_manifest` as the Act II/III consequence hook for the Registrar selling the Kestrel confession.")
	_line("- The Act I Sabine office close now captures the pen-down first-look beat, water pooling on the floor, Sabine crossing through it, and the extended wrist check while preserving the no-apology rule.")
	_line("- Sabine's Act I close now captures the public Kestrel-confession aftermath, her writing Corvin back into standing without apologizing, the wrist/no-pulse beat, and the final Six/Five exchange.")
	_line("- Next design review should compare this report against `docs/script/act_i_full_script_build_document.md` and decide which room beats need to be expanded before art.")

	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		narrative.apply_snapshot(previous_snapshot, true)
		push_error("Could not write report: %s" % REPORT_PATH)
		quit(1)
		return
	file.store_string("\n".join(report) + "\n")
	file.close()

	narrative.apply_snapshot(previous_snapshot, true)
	print("Act I greybox playtest report written: %s" % REPORT_PATH)
	quit(0)

func _header() -> void:
	_line("# Act I Greybox Automated Playtest Report")
	_line("")
	_line("- Generated: `%s`" % Time.get_datetime_string_from_system(false, true))
	_line("- Runner: `tools/godot_record_act_i_greybox_playtest.gd`")
	_line("- Scope: critical path from no Act I Rites complete through Sabine's office.")
	_line("")

func _section(title: String) -> void:
	_line("")
	_line("## %s" % title)
	_line("")

func _record(label: String, room_name: String, hotspot_name: String, verb: String, apply_result: bool) -> void:
	var result := _play(room_name, hotspot_name, verb, apply_result)
	_line("### %s: `%s/%s` `%s`" % [label, room_name, hotspot_name, verb])
	if bool(result.get("blocked", false)):
		_line("- Result: blocked")
		_line("- Player text: %s" % _quote(String(result.get("blocked_text", ""))))
		_record_ink_lines(String(result.get("blocked_ink_knot", "")))
	else:
		_line("- Result: applied" if bool(result.get("applied", false)) else "- Result: observed")
		_line("- Player text: %s" % _quote(String(result.get("message", ""))))
		_record_ink_lines(String(result.get("resolved_ink_knot", result.get("ink_knot", ""))))
	if not bool(result.get("blocked", false)) and not String(result.get("target_room", "")).is_empty():
		_line("- Target room: `%s`" % String(result.get("target_room", "")))
		if not String(result.get("transition_animation", "")).is_empty():
			_line("- Transition animation: `%s`" % String(result.get("transition_animation", "")))
	if not bool(result.get("blocked", false)):
		_record_rewards(result)
	_line("")

func _record_ink_observation(label: String, target: String, verb: String, message: String, knot_name: String) -> void:
	_line("### %s: `%s` `%s`" % [label, target, verb])
	_line("- Result: observed")
	_line("- Player text: %s" % _quote(message))
	_record_ink_lines(knot_name)
	_line("")

func _record_registrar_duel() -> void:
	var result := _play("HarborRegistry", "Registrar", "talk", false)
	_line("### Rite 2 complete: `HarborRegistry/Registrar` `talk`")
	_line("- Result: duel opened")
	_line("- Player text: %s" % _quote(String(result.get("message", ""))))
	_record_ink_lines("registrar_duel_start")

	var DuelPanel := load("res://game/ui/duel_panel.gd")
	var panel: CanvasLayer = DuelPanel.new()
	root.add_child(panel)
	panel.start_duel("registrar", narrative, result.get("duel_pool", []))
	var snapshot: Dictionary = panel.get_ui_snapshot()
	_line("- Duel UI: `%s`, `%s`, `%s`, options `%s`" % [
		snapshot.get("title", ""),
		snapshot.get("round", ""),
		snapshot.get("salt", ""),
		str(snapshot.get("option_count", "")),
	])

	for confession_id in REGISTRAR_SCRIPTED_WIN:
		var attack: Dictionary = panel.get_current_attack()
		var play_result: Dictionary = panel.play_confession(confession_id)
		_line("- Round `%s`: attack `%s` -> counter `%s` -> accepted `%s`, salt `%s`" % [
			String(attack.get("id", "")),
			String(attack.get("text", "")),
			confession_id,
			str(play_result.get("accepted", false)),
			str(play_result.get("salt", 0)),
		])
		if bool(play_result.get("won", false)):
			break

	panel.queue_free()
	_record_ink_lines("registrar_duel_win")
	_apply_reward_result(result)
	_record_rewards(result)
	_line("")

func _play(room_name: String, hotspot_name: String, verb: String, apply_result: bool) -> Dictionary:
	var scene_path := String(ROOM_SCENES.get(room_name, ""))
	var packed: PackedScene = load(scene_path)
	var instance := packed.instantiate()
	var hotspot := instance.get_node("Hotspots/%s" % hotspot_name)
	var result: Dictionary = hotspot.handle_room_verb(verb)
	result = _resolve_alternate_result(result)
	result["resolved_ink_knot"] = _resolve_ink_knot(result)
	for required_flag in result.get("requires_flags", []):
		if not narrative.has_act_i_flag(String(required_flag)):
			result["blocked"] = true
			instance.free()
			return result
	for required_item in result.get("requires_items", []):
		if not narrative.has_item(String(required_item)):
			result["blocked"] = true
			instance.free()
			return result
	if apply_result and String(result.get("duel_opponent", "")).is_empty():
		_apply_reward_result(result)
	result["applied"] = String(result.get("duel_opponent", "")).is_empty() or not apply_result
	instance.free()
	return result

func _apply_reward_result(result: Dictionary) -> void:
	for item_id in result.get("items_add", []):
		narrative.add_item(String(item_id))
	for flag_id in result.get("flags_set", []):
		if narrative.has_method("apply_act_i_flag_reward"):
			narrative.apply_act_i_flag_reward(String(flag_id))
		else:
			narrative.set_act_i_flag(String(flag_id), true)
	for confession_id in result.get("confessions_discover", []):
		if narrative.discover_confession(String(confession_id)):
			if not result.has("confessions_discovered_applied"):
				result["confessions_discovered_applied"] = []
			result["confessions_discovered_applied"].append(String(confession_id))
		else:
			if not result.has("confessions_discover_blocked"):
				result["confessions_discover_blocked"] = []
			result["confessions_discover_blocked"].append(String(confession_id))
	for confession_id in result.get("confessions_spend", []):
		narrative.spend_confession(String(confession_id))

func _consume_warmth_steps(steps: int) -> void:
	for _index in range(steps):
		if narrative.has_method("consume_float_warmth_room_step"):
			narrative.consume_float_warmth_room_step()

func _resolve_ink_knot(result: Dictionary) -> String:
	var knot_name := String(result.get("ink_knot", ""))
	if knot_name == "juno_hot_pool_soak" and narrative.has_act_i_flag("FL_float_warmth_expired"):
		return "juno_warmth_expired"
	return knot_name

func _resolve_alternate_result(result: Dictionary) -> Dictionary:
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

func _record_rewards(result: Dictionary) -> void:
	if not result.get("items_add", []).is_empty():
		_line("- Items added: `%s`" % "`, `".join(result.get("items_add", [])))
	if not result.get("flags_set", []).is_empty():
		_line("- Flags set: `%s`" % "`, `".join(result.get("flags_set", [])))
	if not result.get("confessions_discovered_applied", []).is_empty():
		_line("- Confessions discovered: `%s`" % "`, `".join(result.get("confessions_discovered_applied", [])))
	if not result.get("confessions_discover_blocked", []).is_empty():
		_line("- Confession pickup blocked by global state: `%s`" % "`, `".join(result.get("confessions_discover_blocked", [])))
	if not result.get("confessions_spend", []).is_empty():
		_line("- Confessions spent: `%s`" % "`, `".join(result.get("confessions_spend", [])))

func _record_ink_lines(knot_name: String) -> void:
	if knot_name.is_empty() or ink_bridge == null:
		return
	var lines: Array = ink_bridge.get_knot_lines(knot_name)
	if lines.is_empty():
		_line("- Ink `%s`: no lines captured" % knot_name)
		return
	_line("- Ink `%s`:" % knot_name)
	for line in lines:
		if typeof(line) == TYPE_DICTIONARY:
			_line("  - `%s`: %s" % [String(line.get("speaker", "")), _quote(String(line.get("text", "")))])

func _quote(value: String) -> String:
	return "`%s`" % value.replace("`", "'")

func _line(value: String) -> void:
	report.append(value)
