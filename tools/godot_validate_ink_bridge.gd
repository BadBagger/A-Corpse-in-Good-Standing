extends SceneTree

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	await process_frame
	var failed := false
	var ink_bridge := root.get_node_or_null("InkBridge")
	var narrative := root.get_node_or_null("N")
	if not ink_bridge:
		push_error("Missing InkBridge autoload.")
		failed = true
	if not narrative:
		push_error("Missing N narrative autoload.")
		failed = true
	if failed:
		quit(1)
		return

	_reset_narrative(narrative)

	var tomas_tags: Array[String] = ink_bridge.get_knot_tags("old_quay_tomas")
	failed = _expect_tag(tomas_tags, "journal:add:j_returned_nine_days") or failed
	failed = _expect_tag(tomas_tags, "confession:discover:cf_cow_leftroom") or failed
	var tomas_lines: Array[Dictionary] = ink_bridge.get_knot_lines("old_quay_tomas")
	if tomas_lines.size() < 5:
		push_error("InkBridge extracted too few old_quay_tomas dialogue lines.")
		failed = true
	elif tomas_lines[0].get("speaker", "") != "TOMAS" or tomas_lines[0].get("text", "") != "Corvin?":
		push_error("InkBridge extracted unexpected first old_quay_tomas line.")
		failed = true

	var played_lines: Array[Dictionary] = ink_bridge.play_knot("old_quay_tomas")
	if not narrative.journal.has("j_returned_nine_days"):
		push_error("InkBridge did not apply journal tag.")
		failed = true
	if "cf_cow_leftroom" not in narrative.discovered_confessions:
		push_error("InkBridge did not apply confession discovery tag.")
		failed = true
	if played_lines.size() != tomas_lines.size():
		push_error("InkBridge play_knot did not return extracted dialogue lines.")
		failed = true

	var salt_tags: Array[String] = ink_bridge.get_knot_tags("salt_market_arrival")
	failed = _expect_tag(salt_tags, "item:add:BorrowedBoots") or failed
	ink_bridge.apply_knot_tags("salt_market_arrival")
	if "BorrowedBoots" not in narrative.acquired_items:
		push_error("InkBridge did not apply item tag.")
		failed = true

	failed = _expect_knot_line(ink_bridge, "mudflats_silt", "CORVIN", "Mordida mud.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "mudflats_silt", "CORVIN", "Half of it's mud. The other half is evidence with poor boundaries.") or failed
	failed = _expect_knot_line(ink_bridge, "mudflats_hands", "CORVIN", "Grey at the nails.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "mudflats_hands", "CORVIN", "Everything else looks like mine, which is somehow worse.") or failed
	failed = _expect_knot_line(ink_bridge, "mudflats_harbor_view", "CORVIN", "The ribs.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "mudflats_harbor_view", "CORVIN", "Whole town's built through a dead thing's chest and nobody finds that remarkable but me.") or failed
	failed = _expect_knot_line(ink_bridge, "mudflats_coat_wet", "CORVIN", "Wool.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "mudflats_coat_wet", "NARRATION", "He wrings one sleeve. A puddle forms and stays formed.") or failed

	failed = _expect_knot_line(ink_bridge, "registrar_duel_start", "REGISTRAR", "You're the Vale boy.") or failed
	failed = _expect_knot_line(ink_bridge, "registrar_duel_win", "REGISTRAR", "...Say the rest.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "registrar_duel_win", "REGISTRAR", "And Mr. Vale? What you told me in there, I'll be selling by supper.") or failed
	failed = _expect_knot_line(ink_bridge, "registrar_duel_loss", "REGISTRAR", "Enough. The salt has more patience than I do.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "old_quay_tomas_topics", "TOMAS", "The memory goes first. Oldest to newest, like lamps going out down a street.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "old_quay_tomas_topics", "TOMAS", "She won't do it as a favour. She's never done anything as a favour in her life. You'll have to duel her for it.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "old_quay_tomas_topics", "TOMAS", "Unless. Half-Coin Prosper's in the almshouse with the rot. He meets everyone fresh every morning.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "old_quay_tomas_topics", "TOMAS", "Warmth and a pulse. That's all anyone checks, because that's all there is.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "old_quay_tomas_topics", "TOMAS", "You keep a list of everyone who's ever been wrong about you.") or failed
	failed = _expect_knot_line(ink_bridge, "old_quay_silent_bollards", "CORVIN", "Grey. Person-shaped if you're not careful about it.") or failed
	failed = _expect_knot_line(ink_bridge, "old_quay_bollard_petra", "CORVIN", "Petra.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "old_quay_bollard_petra", "TOMAS", "On the end. Used to sing.") or failed
	failed = _expect_knot_line(ink_bridge, "old_quay_bollard_ledger", "CORVIN", "There's a rope groove across this one's throat.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "old_quay_bollard_ledger", "TOMAS", "Collar, then rope. The island likes a promotion ladder.") or failed
	failed = _expect_knot_line(ink_bridge, "old_quay_bollard_bride", "CORVIN", "Still wearing a ring.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "old_quay_bollard_bride", "TOMAS", "She set on day nine waiting for a husband who'd already sailed.") or failed
	failed = _expect_knot_line(ink_bridge, "old_quay_bollards_all_seen", "TOMAS", "You've done the rounds.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "old_quay_bollards_all_seen", "TOMAS", "For Mordida. Most conversations here are with people who stopped listening before you arrived.") or failed
	failed = _expect_knot_line(ink_bridge, "old_quay_flask", "CORVIN", "Somebody's flask.") or failed
	failed = _expect_knot_line(ink_bridge, "old_quay_rope_cleat", "CORVIN", "Sharp edge.") or failed
	failed = _expect_knot_line(ink_bridge, "salt_market_public_recognition", "BOOT_SELLER", "Morning. Size?") or failed
	failed = _expect_knot_contains_line(ink_bridge, "salt_market_public_recognition", "NARRATION", "The seller looks up. Looks properly. His face does something complicated.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "salt_market_public_recognition", "NARRATION", "He backs into his own table. Boots go everywhere.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "salt_market_public_recognition", "NARRATION", "The street stops.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "salt_market_public_recognition", "NARRATION", "He picks up boots off the ground, unhurried, and walks out through a crowd that parts without anyone deciding to.") or failed
	failed = _expect_knot_line(ink_bridge, "salt_market_boot_stall_after", "CORVIN", "He's rearranging boots that don't need it.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "salt_market_boot_stall_after", "BOOT_SELLER", "She thought it was interesting.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "salt_market_boot_stall_after", "CORVIN", "Kids are better at this than we are.") or failed
	failed = _expect_knot_line(ink_bridge, "salt_market_fishmonger", "CORVIN", "Two sets of scales under that table.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "salt_market_fishmonger", "MONGER", "You're dripping on the cod.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "salt_market_fishmonger", "CORVIN", "It's a marinade.") or failed
	failed = _expect_knot_line(ink_bridge, "salt_market_lamp", "CORVIN", "Whale oil.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "salt_market_confession_queue", "NARRATION", "Eleven people wait to ask a dead man a question. Eight of them look like money.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "salt_market_confession_queue", "NARRATION", "A boy in a collar takes shillings under a sign that promises truth by the minute.") or failed
	failed = _expect_knot_line(ink_bridge, "salt_market_confession_queue", "WOMAN", "He laughed at the funeral.") or failed
	failed = _expect_knot_line(ink_bridge, "salt_market_church_sign_wet", "CORVIN", "Petty.") or failed
	failed = _expect_knot_line(ink_bridge, "fish_hall_ice_table", "CORVIN", "That's the table.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "fish_hall_ice_table", "CORVIN", "I always thought I'd take up more room.") or failed
	failed = _expect_knot_line(ink_bridge, "fish_hall_coroner_tag", "CORVIN", "VALE, C. THURS. RECOVERED, QUAY. NO MARKS.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "fish_hall_coroner_tag", "CORVIN", "They got the place wrong, unless the quay learned to hold a man's head under.") or failed
	failed = _expect_knot_line(ink_bridge, "fish_hall_visitor_book", "CORVIN", "Forty-one names.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "fish_hall_visitor_book", "CORVIN", "Good turnout. Terrible host.") or failed
	failed = _expect_knot_line(ink_bridge, "fish_hall_drain", "CORVIN", "It all goes back to the harbor eventually.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "fish_hall_drain", "CORVIN", "Just gravity, brine, and somewhere lower to be.") or failed
	failed = _expect_knot_line(ink_bridge, "chandler_wares", "CORVIN", "Buttons. Needles. A chess set.") or failed
	failed = _expect_knot_line(ink_bridge, "chandler_chess_set", "CORVIN", "White pieces are older stock.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "chandler_chess_set", "CORVIN", "They go pale after twenty years.") or failed
	failed = _expect_knot_line(ink_bridge, "chandler_watch_trade", "CHANDLER", "Oh, you're new.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "chandler_watch_trade", "CHANDLER", "No. That's rather the point, isn't it.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "chandler_watch_trade", "CHANDLER", "I'd rather you didn't. But come back.") or failed
	failed = _expect_knot_line(ink_bridge, "chandler_needs_salt", "CORVIN", "Prosper's watch.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "chandler_needs_salt", "CHANDLER", "Until then the glass and I are both watching you.") or failed
	failed = _expect_knot_line(ink_bridge, "almshouse_cots", "CORVIN", "Twelve cots.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "almshouse_cots", "CORVIN", "The sheets are folded back from their feet so the salt doesn't glue them down.") or failed
	failed = _expect_knot_line(ink_bridge, "almshouse_window", "CORVIN", "The window faces the water.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "almshouse_window", "CORVIN", "Every bed gets a stripe of harbor light. Equal shares of a bad idea.") or failed
	failed = _expect_knot_line(ink_bridge, "prosper_before_watch", "PROSPER", "Morning! Have we met?") or failed
	failed = _expect_knot_contains_line(ink_bridge, "prosper_before_watch", "PROSPER", "It's cheap. I get to spend it fresh every morning.") or failed
	failed = _expect_knot_line(ink_bridge, "prosper_forgiveness", "CORVIN", "I've got something of yours.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "prosper_forgiveness", "PROSPER", "Look. I've done that ten thousand times and I couldn't tell you once.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "prosper_forgiveness", "PROSPER", "They all think I won't notice, and they're right, but I notice that.") or failed
	failed = _expect_knot_line(ink_bridge, "float_juno_table", "JUNO", "You're dripping on my deck, and my deck is already wet, so I want you to understand that I noticed anyway.") or failed
	failed = _expect_knot_line(ink_bridge, "juno_needs_rate_card", "JUNO", "That pump is the only reason this barge is a barge and not a wreck with opinions.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "juno_needs_rate_card", "CORVIN", "I need something in my chest that ticks for an hour.") or failed
	failed = _expect_knot_line(ink_bridge, "juno_regulator_trade", "JUNO", "Thirty years I ran that trade. Thirty.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "juno_regulator_trade", "NARRATION", "Juno does not touch it. She looks at it a long time.") or failed
	failed = _expect_knot_line(ink_bridge, "juno_pool_before_permission", "CORVIN", "The pool's warm.") or failed
	failed = _expect_knot_line(ink_bridge, "juno_hot_pool_soak", "JUNO", "Ten minutes.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "juno_hot_pool_soak", "NARRATION", "The amber screen slides shut. Steam turns the room into voices and shoulders.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "juno_hot_pool_soak", "NARRATION", "His skin takes the warmth before he does. That feels worse than cold.") or failed
	failed = _expect_knot_line(ink_bridge, "juno_warmth_expired", "JUNO", "You wandered off, didn't you.") or failed
	failed = _expect_knot_line(ink_bridge, "float_staff_corner", "ADELA", "He said sorry and left two buttons.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "float_staff_corner", "MARIN", "Men come here to feel forgiven and leave us the small change.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "float_staff_corner", "ADELA", "Don't flatter yourself. We charge for silence too.") or failed
	failed = _expect_knot_line(ink_bridge, "float_steam_screen", "CORVIN", "Steam, backlight, silhouettes.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "float_steam_screen", "JUNO", "Then respect the shadow.") or failed
	failed = _expect_knot_line(ink_bridge, "harbormaster_checklist_desk", "CORVIN", "Three boxes beside my name.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "harbormaster_checklist_desk", "CLERK", "All three. In ink. No pencil for the dead.") or failed
	failed = _expect_knot_line(ink_bridge, "harbormaster_sabine_door", "CORVIN", "SABINE CROIX, HARBORMASTER.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "harbormaster_sabine_door", "NARRATION", "Black letters on frosted glass. Her office is one room away and still somehow uphill.") or failed
	failed = _expect_knot_line(ink_bridge, "heartbeat_check_pass", "CLERK", "Name.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "heartbeat_check_pass", "NARRATION", "He takes Corvin's wrist and waits.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "heartbeat_check_pass", "NARRATION", "The regulator ticks under the coat, four inches off and slightly too regular.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "heartbeat_check_pass", "NARRATION", "The clerk feels Corvin's hand.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "heartbeat_check_pass", "CLERK", "Your pulse is four inches left of your wrist.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "heartbeat_check_pass", "CLERK", "Your hand's warm.") or failed
	failed = _expect_knot_line(ink_bridge, "heartbeat_check_fail", "CLERK", "You're cold.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "heartbeat_check_fail", "CLERK", "You have absence issues. Out twice.") or failed
	failed = _expect_knot_line(ink_bridge, "church_poor_box", "CORVIN", "Poor box.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "church_poor_box", "NARRATION", "The lock sits crooked, scraped bright around the screws.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "church_poor_box", "NARRATION", "Coins remain in the bottom. The folded notes are gone.") or failed
	failed = _expect_knot_line(ink_bridge, "church_stall_sign", "CORVIN", "THE DROWNED CANNOT LIE. ONE SHILLING.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "church_stall_sign", "NARRATION", "The queue is eleven deep. Teodor is sweating through doctrine.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "church_stall_sign", "CORVIN", "That's not theology. That's inventory pressure.") or failed
	failed = _expect_knot_line(ink_bridge, "church_confession_booth", "CORVIN", "A green-lit box with a queue.") or failed
	failed = _expect_knot_line(ink_bridge, "teodor_needs_chit", "TEODOR", "I can't put you in the stall without a chit.") or failed
	failed = _expect_knot_line(ink_bridge, "teodor_rate_card_booth", "TEODOR", "We're closed. We're... I'm sorry, we're closed.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "teodor_rate_card_booth", "CORVIN", "Nobody. You've got eleven people out there and one returned on your books, and I passed him on the quay this morning and he's a bollard now.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "teodor_rate_card_booth", "NARRATION", "Teodor sits down on the step. Puts his head in his hands.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "teodor_rate_card_booth", "TEODOR", "They'll take the stall off me.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "teodor_rate_card_booth", "WOMAN", "That's kinder than I paid for.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "teodor_rate_card_booth", "BOY", "Why did you tell me that?") or failed
	failed = _expect_knot_contains_line(ink_bridge, "teodor_rate_card_booth", "CORVIN", "Because you asked and I'm made this way now.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "teodor_rate_card_booth", "KANE", "I'll have my question now.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "teodor_rate_card_booth", "KANE", "I like to know when a man's going to be reasonable, and it's never on day six.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "teodor_rate_card_booth", "NARRATION", "He goes. The queue lets him through without being asked.") or failed
	failed = _expect_knot_line(ink_bridge, "registry_ledgers", "CORVIN", "Four thousand names.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "registry_ledgers", "REGISTRAR", "Paper has the decency not to beg.") or failed
	failed = _expect_knot_line(ink_bridge, "registry_roll_book", "CORVIN", "There. VALE, CORVIN.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "registry_roll_book", "NARRATION", "The line through it has bitten into the paper, not just crossed it.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "registry_roll_book", "REGISTRAR", "Names are vanity until someone takes yours away.") or failed
	failed = _expect_knot_line(ink_bridge, "registry_lamp_smoked", "CORVIN", "Terribly sorry.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "registry_lamp_smoked", "REGISTRAR", "You dream professionally, Mr. Vale. Stay professionally still.") or failed
	failed = _expect_knot_line(ink_bridge, "registry_ledger_blocked", "CORVIN", "The Kestrel ledger is behind her desk.") or failed
	failed = _expect_knot_line(ink_bridge, "registry_ledger_page", "CORVIN", "Kestrel. Hold listed as freight.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "registry_ledger_page", "NARRATION", "The Registrar sees the torn corner. She does not rise.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "registry_ledger_page", "NARRATION", "She files the moment somewhere quiet and reachable.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "registry_ledger_page", "REGISTRAR", "I know where every body is, Mr. Vale. The living just file them creatively.") or failed
	failed = _expect_knot_line(ink_bridge, "registry_registrar_needs_manifest", "REGISTRAR", "You can duel me when you know what you're here to say.") or failed
	failed = _expect_knot_line(ink_bridge, "sabine_act_i_audience", "SABINE", "You're dripping on the Persian.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "sabine_act_i_audience", "NARRATION", "She writes another line, sets down the pen, and looks at him for the first time.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "sabine_act_i_audience", "CORVIN", "You can't blackmail a man with a thing he shouted.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "sabine_act_i_audience", "CORVIN", "She wrote my name back in. Didn't say anything about it.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "sabine_act_i_audience", "NARRATION", "Water pools on Sabine's floor. She crosses through it like it isn't there.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "sabine_act_i_audience", "NARRATION", "Two fingers to the inside of his wrist. Four seconds. Nothing. Her hand stays.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "sabine_act_i_audience", "SABINE", "I noticed.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "sabine_act_i_audience", "SABINE", "Don't make me say a thing badly when I'm doing it correctly.") or failed
	failed = _expect_knot_contains_line(ink_bridge, "sabine_act_i_audience", "SABINE", "Six days.") or failed
	failed = _expect_knot_speaker_omits_terms(ink_bridge, "sabine_act_i_audience", "SABINE", ["sorry", "apolog"]) or failed

	var snapshot: Dictionary = narrative.to_snapshot()
	narrative.clear_runtime_state(false)
	if narrative.journal.has("j_returned_nine_days") or "cf_cow_leftroom" in narrative.discovered_confessions:
		push_error("Narrative clear_runtime_state did not clear runtime data.")
		failed = true
	narrative.apply_snapshot(snapshot, false)
	if not narrative.journal.has("j_returned_nine_days") or "cf_cow_leftroom" not in narrative.discovered_confessions or "BorrowedBoots" not in narrative.acquired_items:
		push_error("Narrative snapshot restore did not restore Ink-applied state.")
		failed = true

	var globals := root.get_node_or_null("Globals")
	if not globals or not globals.has_method("on_save") or not globals.has_method("on_load"):
		push_error("Popochiu Globals narrative save hooks are missing.")
		failed = true
	else:
		var saved: Dictionary = globals.on_save()
		narrative.clear_runtime_state(false)
		globals.on_load(saved)
		if not narrative.journal.has("j_returned_nine_days") or "cf_cow_leftroom" not in narrative.discovered_confessions:
			push_error("Popochiu Globals hooks did not roundtrip narrative state.")
			failed = true

	failed = await _validate_popochiu_slot_roundtrip(narrative) or failed

	_reset_narrative(narrative)
	print("Godot Ink bridge validation passed.")
	quit(1 if failed else 0)

func _expect_tag(tags: Array[String], expected: String) -> bool:
	if expected in tags:
		return false
	push_error("InkBridge missing expected tag: %s" % expected)
	return true

func _expect_knot_line(ink_bridge: Node, knot_name: String, speaker: String, text: String) -> bool:
	var lines: Array[Dictionary] = ink_bridge.get_knot_lines(knot_name)
	if lines.is_empty():
		push_error("InkBridge extracted no lines for knot: %s" % knot_name)
		return true
	if lines[0].get("speaker", "") != speaker or lines[0].get("text", "") != text:
		push_error("InkBridge extracted unexpected first line for %s." % knot_name)
		return true
	return false

func _expect_knot_contains_line(ink_bridge: Node, knot_name: String, speaker: String, text: String) -> bool:
	var lines: Array[Dictionary] = ink_bridge.get_knot_lines(knot_name)
	if lines.is_empty():
		push_error("InkBridge extracted no lines for knot: %s" % knot_name)
		return true
	for line in lines:
		if line.get("speaker", "") == speaker and line.get("text", "") == text:
			return false
	push_error("InkBridge did not extract expected line for %s." % knot_name)
	return true

func _expect_knot_speaker_omits_terms(ink_bridge: Node, knot_name: String, speaker: String, forbidden_terms: Array[String]) -> bool:
	var lines: Array[Dictionary] = ink_bridge.get_knot_lines(knot_name)
	if lines.is_empty():
		push_error("InkBridge extracted no lines for knot: %s" % knot_name)
		return true
	for line in lines:
		if line.get("speaker", "") != speaker:
			continue
		var text := String(line.get("text", "")).to_lower()
		for term in forbidden_terms:
			if text.contains(term):
				push_error("%s line in %s contains forbidden term '%s': %s" % [speaker, knot_name, term, line.get("text", "")])
				return true
	return false

func _validate_popochiu_slot_roundtrip(narrative: Node) -> bool:
	var failed := false
	var engine := root.get_node_or_null("E")
	var rooms := root.get_node_or_null("R")
	var globals := root.get_node_or_null("Globals")
	if not engine or not engine.has_method("save_game") or not rooms or not globals:
		push_error("Popochiu save slot validation missing E, R, or Globals.")
		return true

	for attempt in 20:
		if rooms.get("current") != null:
			break
		await process_frame
	if rooms.get("current") == null and rooms.has_method("goto_room"):
		rooms.goto_room("Mudflats", false, false)
		for attempt in 20:
			if rooms.get("current") != null:
				break
			await process_frame
	if rooms.get("current") == null:
		var mudflats: Node = load("res://game/rooms/mudflats/room_mudflats.tscn").instantiate()
		mudflats.set("has_player", false)
		engine.add_child(mudflats)
		await process_frame
	if rooms.get("current") == null:
		push_error("Popochiu save slot validation could not provide Mudflats before saving.")
		return true

	var save_path := "user://save_4.json"
	var had_previous_save := FileAccess.file_exists(save_path)
	var previous_save := ""
	if had_previous_save:
		var previous_file := FileAccess.open(save_path, FileAccess.READ)
		if previous_file:
			previous_save = previous_file.get_as_text()
	if previous_save.is_empty():
		had_previous_save = false

	engine.save_game(4, "STEP3_NARRATIVE_VALIDATION")
	await process_frame

	if not FileAccess.file_exists(save_path):
		push_error("Popochiu E.save_game did not create save slot 4.")
		failed = true
	else:
		var file := FileAccess.open(save_path, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text()) if file else null
		if typeof(parsed) != TYPE_DICTIONARY:
			push_error("Popochiu save slot 4 is not valid JSON.")
			failed = true
		elif not parsed.has("globals") or not parsed.globals.has("custom_data") or not parsed.globals.custom_data.has("narrative"):
			push_error("Popochiu save slot 4 does not contain custom_data.narrative.")
			failed = true
		else:
			var slot_narrative: Dictionary = parsed.globals.custom_data.narrative
			if not slot_narrative.get("journal", {}).has("j_returned_nine_days"):
				push_error("Popochiu save slot narrative is missing journal state.")
				failed = true
			if "cf_cow_leftroom" not in slot_narrative.get("discovered_confessions", []):
				push_error("Popochiu save slot narrative is missing Litany state.")
				failed = true
			if "BorrowedBoots" not in slot_narrative.get("acquired_items", []):
				push_error("Popochiu save slot narrative is missing item state.")
				failed = true

			narrative.clear_runtime_state(false)
			globals.on_load(parsed.globals.custom_data)
			if not narrative.journal.has("j_returned_nine_days") or "cf_cow_leftroom" not in narrative.discovered_confessions or "BorrowedBoots" not in narrative.acquired_items:
				push_error("Popochiu slot custom data did not restore narrative state.")
				failed = true

			narrative.clear_runtime_state(false)
			engine.load_game(4)
			for attempt in 20:
				if narrative.journal.has("j_returned_nine_days"):
					break
				await process_frame
			if not narrative.journal.has("j_returned_nine_days") or "cf_cow_leftroom" not in narrative.discovered_confessions or "BorrowedBoots" not in narrative.acquired_items:
				push_error("Popochiu E.load_game did not restore narrative state from slot 4.")
				failed = true

	if had_previous_save:
		var restore_file := FileAccess.open(save_path, FileAccess.WRITE)
		if restore_file:
			restore_file.store_string(previous_save)
	elif FileAccess.file_exists(save_path):
		var user_path := ProjectSettings.globalize_path(save_path)
		DirAccess.remove_absolute(user_path)

	return failed

func _reset_narrative(narrative: Node) -> void:
	narrative.clear_runtime_state()
