@tool
extends PopochiuRoom

const Data := preload("room_mudflats_state.gd")
const HOVER_LABELS := {
	"Silt": "Silt",
	"OwnHands": "Own hands",
	"HarborView": "Harbor view",
	"Coat": "Wet coat",
	"BollardOfTomas": "Bollard of Tomas",
	"MissingBoots": "Missing boots",
	"SaltMarketExit": "Salt Market"
}

@export var show_debug_layout := false

var state: Data = Data.new()
var _hud: CanvasLayer

func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	_apply_real_art_presentation()
	_hud = $PrologueHud
	var narrative := _narrative()
	if narrative:
		narrative.changed.connect(_refresh_narrative_hud)
		_refresh_narrative_hud()
	for hotspot in $Hotspots.get_children():
		if hotspot is Area2D:
			hotspot.input_event.connect(_on_hotspot_input.bind(hotspot))
			hotspot.mouse_entered.connect(_on_hotspot_mouse_entered.bind(hotspot))
			hotspot.mouse_exited.connect(_on_hotspot_mouse_exited)
	_refresh_status()

func _on_hotspot_mouse_entered(hotspot: Area2D) -> void:
	var verb := "look"
	if _hud and "selected_verb" in _hud:
		verb = _hud.selected_verb
	_say("%s: %s" % [verb.capitalize(), _hover_label(hotspot)])

func _on_hotspot_mouse_exited() -> void:
	_refresh_status()

func _refresh_status() -> void:
	_say("R01 / Mudflats")

func _on_room_entered() -> void:
	pass

func _on_room_transition_finished() -> void:
	if Engine.is_editor_hint():
		return
	_play_corvin_runtime_animation("idle_current_side")

func _apply_real_art_presentation() -> void:
	_set_debug_layout_visible(show_debug_layout)

func _set_debug_layout_visible(is_visible: bool) -> void:
	for node_name in ["LeviathanRibs", "MudShelf", "HarborWater", "GreyboxLabels", "WalkableAreas", "Props/CorvinPlaceholder"]:
		var node := get_node_or_null(node_name)
		if node is CanvasItem:
			node.visible = is_visible
	var hotspots := get_node_or_null("Hotspots")
	if hotspots:
		_set_child_labels_visible(hotspots, is_visible)

func _set_child_labels_visible(parent: Node, is_visible: bool) -> void:
	for child in parent.get_children():
		if child is Label:
			child.visible = is_visible
		_set_child_labels_visible(child, is_visible)

func _on_room_exited() -> void:
	pass

func _on_hotspot_input(_viewport: Node, event: InputEvent, _shape_idx: int, hotspot: Area2D) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	var verb := "look"
	if _hud and "selected_verb" in _hud:
		verb = _hud.selected_verb

	_play_corvin_verb_action(verb)
	match hotspot.name:
		"Silt":
			_handle_silt(verb)
		"OwnHands":
			_handle_hands(verb)
		"HarborView":
			_handle_harbor_view(verb)
		"Coat":
			_handle_coat(verb)
		"BollardOfTomas":
			_handle_tomas(verb)
		"MissingBoots":
			_handle_boots(verb)
		"SaltMarketExit":
			_handle_exit(verb)
		_:
			_say("There is probably a clue there. It is shy.")

func _handle_silt(verb: String) -> void:
	_play_ink_knot("mudflats_silt")
	match verb:
		"look":
			_say("Mordida mud. Half of it is mud. The other half is evidence with poor boundaries.")
		"use":
			_say("Corvin has been in it. He is not going back in it voluntarily.")
		"talk":
			_say("Corvin and the mud have said everything they are going to say to each other.")
		"walk":
			_say("Corvin steps around the deeper silt. It seems personally disappointed.")
		"wet":
			_say("Corvin drips into the mud. The mud accepts a professional courtesy.")

func _handle_hands(verb: String) -> void:
	_play_ink_knot("mudflats_hands")
	match verb:
		"look":
			_say("Grey at the nails. That is new. Everything else looks like his, which is worse.")
		"use":
			_say("There is nothing useful to do with them yet. Give the day time to become unreasonable.")
		"talk":
			_say("Not yet. Give it six days.")
		"walk":
			_say("Corvin keeps his hands where he can see them.")
		"wet":
			_say("His hands are already wet. The miracle is that they are still his.")

func _handle_harbor_view(verb: String) -> void:
	_play_ink_knot("mudflats_harbor_view")
	match verb:
		"look":
			_say("The ribs. A town built through a dead thing's chest and apparently proud of the carpentry.")
		"use":
			_say("It is a view. You cannot use a view, though several landlords have tried.")
		"talk":
			_say("Corvin has talked at that harbor his whole life. It has never once answered.")
		"walk":
			_say("The harbor waits behind him, which is rude after everything.")
		"wet":
			_say("Corvin contributes one sleeve of water back to the view.")

func _handle_coat(verb: String) -> void:
	_play_ink_knot("mudflats_coat_wet")
	match verb:
		"look":
			_say("Wool. Was expensive. Is now a sponge with buttons.")
		"use":
			var narrative := _narrative()
			if narrative and narrative.has_method("add_journal"):
				narrative.add_journal("j_corvin_drips")
			_say("Corvin wrings out a sleeve. The puddle forms like it has tenure.")
		"talk":
			_say("It is a coat, and Corvin is not that far gone. Yet.")
		"walk":
			_say("The coat follows him with the loyalty of wet paperwork.")
		"wet":
			_say("Corvin demonstrates the new verb by making the ground worse.")

func _handle_tomas(verb: String) -> void:
	match verb:
		"walk":
			_say("Corvin steps closer. Tomas cannot step anywhere, which is becoming a theme.")
		"look":
			state.learned_returned_rule = true
			_play_ink_knot("old_quay_tomas")
			_say("Tomas used to owe Corvin two reales. Now boats owe Tomas rope burns.")
		"use":
			_say("Corvin drips on Tomas. Tomas, being a bollard, files no formal complaint.")
		"talk":
			state.learned_returned_rule = true
			_play_ink_knot("old_quay_tomas")
			_say("Ink scene: old_quay_tomas")
		"wet":
			_say("Corvin drips on Tomas. Tomas says it still beats rope burn.")

func _handle_boots(verb: String) -> void:
	match verb:
		"walk":
			_say("Bare feet in harbor mud. The glamour of death continues.")
		"look":
			_play_ink_knot("salt_market_arrival")
			_say("Two boot-shaped absences. Somehow the left one looks more judgmental.")
		"use":
			if _hud and _hud.has_method("add_inventory_item"):
				_hud.add_inventory_item("Harbor mud")
			if Engine.has_singleton("I") and I.HarborMud:
				await I.HarborMud.add(false)
			state.recovered_boots = true
			_play_ink_knot("salt_market_arrival")
			_say("No boots. Corvin salvages a useful handful of harbor mud instead.")
		"talk":
			_say("The boots remain silent. Better legal advice than Corvin usually gave.")
		"wet":
			_say("Corvin drips where the boots are not. The absence remains dry in spirit.")

func _handle_exit(verb: String) -> void:
	match verb:
		"walk":
			state.reached_salt_market = true
			_play_ink_knot("old_quay_equipment")
			_play_ink_knot("salt_market_arrival")
			if _hud and _hud.has_method("add_inventory_item"):
				_hud.add_inventory_item("Borrowed boots")
			if Engine.has_singleton("I") and I.BorrowedBoots:
				await I.BorrowedBoots.add(false)
			_say("The Salt Market waits uphill, bright enough for someone to scream properly.")
			_play_corvin_runtime_animation("walk_side_right")
			R.goto_room("SaltMarket", false, true)
		"look":
			_say("Lanterns, awnings, witnesses. Three things Corvin prefers in smaller quantities.")
		"use":
			_say("The road declines to be used. Roads are smug that way.")
		"talk":
			_say("Corvin says hello to commerce. Commerce checks his pulse and looks worried.")
		"wet":
			_say("Corvin wets the road. It had plans to be dirt anyway.")

func _say(message: String) -> void:
	if _hud and _hud.has_method("set_status"):
		_hud.set_status(message)
	else:
		print(message)

func _hover_label(hotspot: Area2D) -> String:
	return String(HOVER_LABELS.get(String(hotspot.name), _format_node_label(String(hotspot.name))))

func _play_ink_knot(knot_name: String) -> void:
	var bridge := get_node_or_null("/root/InkBridge")
	if bridge and bridge.has_method("play_knot"):
		var lines: Array[Dictionary] = bridge.play_knot(knot_name)
		if _hud and _hud.has_method("set_dialogue_lines"):
			_hud.set_dialogue_lines(lines)

func _refresh_narrative_hud() -> void:
	var narrative := _narrative()
	if not narrative or not _hud:
		return
	if _hud.has_method("set_journal_entries"):
		_hud.set_journal_entries(narrative.get_journal_entries())
	if _hud.has_method("set_objective_summary") and narrative.has_method("get_act_i_objective_summary"):
		_hud.set_objective_summary(narrative.get_act_i_objective_summary())
	if _hud.has_method("set_confession_summary"):
		_hud.set_confession_summary(narrative.get_confession_summary())

func _narrative() -> Node:
	return get_node_or_null("/root/N")

func _play_corvin_runtime_animation(animation_name: String) -> bool:
	var characters := get_node_or_null("/root/C")
	if characters == null:
		return false
	var corvin: Node = characters.get("Corvin")
	if corvin == null or not corvin.has_method("play_runtime_animation"):
		return false
	return bool(corvin.call("play_runtime_animation", animation_name))

func _play_corvin_verb_action(verb: String) -> bool:
	match verb:
		"talk":
			return _play_corvin_runtime_animation("talk_current_side")
		"use":
			return _play_corvin_runtime_animation("use_current_side")
		"wet":
			return _play_corvin_runtime_animation("wet_current_side")
		_:
			return false

func _format_node_label(value: String) -> String:
	var words: Array[String] = []
	var current := ""
	for index in value.length():
		var character := value.substr(index, 1)
		if character == "_":
			if not current.is_empty():
				words.append(current)
				current = ""
			continue
		if index > 0 and character == character.to_upper() and character != character.to_lower() and not current.is_empty():
			words.append(current)
			current = character
		else:
			current += character
	if not current.is_empty():
		words.append(current)
	var normalized := " ".join(words).strip_edges()
	if normalized.is_empty():
		return "Hotspot"
	return normalized.capitalize()
