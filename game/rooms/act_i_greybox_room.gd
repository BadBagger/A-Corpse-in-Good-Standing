@tool
extends PopochiuRoom

@export var room_code := ""
@export var room_title := ""
@export var room_notes := ""
@export var show_debug_layout := false

const ACT_I_STANDEE_BASE := "res://game/standees/act_i/%s.png"
const ACT_I_STANDEES_BY_ROOM := {
	"R02": [
		{"id": "tomas_bollard", "position": Vector2(400, 735), "z": 4},
	],
	"R03": [
		{"id": "market_crowd", "position": Vector2(1010, 790), "z": 4},
	],
	"R05": [
		{"id": "registrar", "position": Vector2(1230, 705), "z": 4},
	],
	"R06": [
		{"id": "bone_chandler", "position": Vector2(1200, 760), "z": 4},
	],
	"R07": [
		{"id": "prosper", "position": Vector2(1190, 775), "z": 4},
	],
	"R09": [
		{"id": "teodor", "position": Vector2(1230, 740), "z": 4},
	],
	"R10": [
		{"id": "juno", "position": Vector2(1250, 745), "z": 4},
	],
	"R12": [
		{"id": "sabine", "position": Vector2(1260, 735), "z": 4},
	],
}

var _hud: CanvasLayer
var _duel_panel: CanvasLayer
var _pending_duel_result: Dictionary = {}

func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	_apply_real_art_presentation()
	_hud = get_node_or_null("PrologueHud")
	var narrative := _narrative()
	if narrative:
		narrative.changed.connect(_refresh_narrative_hud)
		_refresh_narrative_hud()
	for hotspot in get_tree().get_nodes_in_group("act_i_exit_hotspot"):
		if is_ancestor_of(hotspot) and hotspot is Area2D:
			_bind_hotspot_feedback(hotspot, _on_exit_hotspot_input)
	for hotspot in get_tree().get_nodes_in_group("act_i_interaction_hotspot"):
		if is_ancestor_of(hotspot) and hotspot is Area2D:
			_bind_hotspot_feedback(hotspot, _on_interaction_hotspot_input)
	_refresh_status()

func _apply_real_art_presentation() -> void:
	_set_debug_layout_visible(show_debug_layout)
	_add_act_i_standees()

func _set_debug_layout_visible(is_visible: bool) -> void:
	for node_name in ["Floor", "WalkableAreas", "TitleLabel", "NotesLabel"]:
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

func _add_act_i_standees() -> void:
	if not ACT_I_STANDEES_BY_ROOM.has(room_code):
		return
	var props := get_node_or_null("Props")
	if props == null:
		props = self
	var container := props.get_node_or_null("ActIStandees")
	if container:
		container.queue_free()
	container = Node2D.new()
	container.name = "ActIStandees"
	props.add_child(container)
	for standee in ACT_I_STANDEES_BY_ROOM[room_code]:
		_add_act_i_standee(container, standee)

func _add_act_i_standee(container: Node, standee: Dictionary) -> void:
	var standee_id := String(standee.get("id", ""))
	if standee_id.is_empty():
		return
	var path := ACT_I_STANDEE_BASE % standee_id
	if not FileAccess.file_exists(path):
		push_warning("Missing Act I standee: %s" % path)
		return
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_warning("Could not load Act I standee %s: %s" % [path, error_string(err)])
		return
	var sprite := Sprite2D.new()
	sprite.name = "%sStandee" % standee_id.to_pascal_case()
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = false
	var foot_position: Vector2 = standee.get("position", Vector2.ZERO)
	sprite.position = Vector2(foot_position.x - float(image.get_width()) / 2.0, foot_position.y - float(image.get_height()))
	sprite.z_index = int(standee.get("z", 0))
	container.add_child(sprite)

func _bind_hotspot_feedback(hotspot: Area2D, input_handler: Callable) -> void:
	var input_callable := input_handler.bind(hotspot)
	var entered_callable := _on_hotspot_mouse_entered.bind(hotspot)
	if not hotspot.input_event.is_connected(input_callable):
		hotspot.input_event.connect(input_callable)
	if not hotspot.mouse_entered.is_connected(entered_callable):
		hotspot.mouse_entered.connect(entered_callable)
	if not hotspot.mouse_exited.is_connected(_on_hotspot_mouse_exited):
		hotspot.mouse_exited.connect(_on_hotspot_mouse_exited)

func _on_hotspot_mouse_entered(hotspot: Area2D) -> void:
	var verb := "look"
	if _hud and "selected_verb" in _hud:
		verb = _hud.selected_verb
	_say("%s: %s" % [verb.capitalize(), _hover_label(hotspot)])

func _on_hotspot_mouse_exited() -> void:
	_refresh_status()

func _on_exit_hotspot_input(_viewport: Node, event: InputEvent, _shape_idx: int, hotspot: Area2D) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	var verb := "look"
	if _hud:
		verb = _hud.selected_verb

	_play_corvin_verb_action(verb)
	if hotspot.has_method("handle_room_verb"):
		var result: Dictionary = hotspot.handle_room_verb(verb)
		_apply_interaction_result(result)

func _on_interaction_hotspot_input(_viewport: Node, event: InputEvent, _shape_idx: int, hotspot: Area2D) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	var verb := "look"
	if _hud:
		verb = _hud.selected_verb

	_play_corvin_verb_action(verb)
	if hotspot.has_method("handle_room_verb"):
		var result: Dictionary = hotspot.handle_room_verb(verb)
		_apply_interaction_result(result)

func _on_room_transition_finished() -> void:
	if Engine.is_editor_hint():
		return
	_play_corvin_runtime_animation("idle_current_side")
	_refresh_status()

func _refresh_status() -> void:
	if room_code.is_empty() and room_title.is_empty():
		return
	_say("%s / %s" % [room_code, room_title])

func _say(message: String) -> void:
	if message.is_empty():
		return
	if _hud and _hud.has_method("set_status"):
		_hud.set_status(message)
	else:
		print(message)

func _hover_label(hotspot: Area2D) -> String:
	if hotspot.has_method("get_hover_label"):
		return String(hotspot.call("get_hover_label"))
	return _format_node_label(hotspot.name)

func _apply_interaction_result(result: Dictionary) -> void:
	var narrative := _narrative()
	if narrative:
		result = _resolve_alternate_result(result, narrative)
		for required_flag in result.get("requires_flags", []):
			if not narrative.has_act_i_flag(String(required_flag)):
				_play_ink_knot(String(result.get("blocked_ink_knot", "")))
				_say(String(result.get("blocked_text", "That is not ready yet.")))
				return
		for required_item in result.get("requires_items", []):
			if not narrative.has_item(String(required_item)):
				_play_ink_knot(String(result.get("blocked_ink_knot", "")))
				_say(String(result.get("blocked_text", "Corvin is missing the right bad idea.")))
				return
		var duel_opponent := String(result.get("duel_opponent", ""))
		if not duel_opponent.is_empty():
			_start_duel(duel_opponent, result)
			return
		_play_ink_knot(_resolve_ink_knot(result, narrative))
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

	_say(String(result.get("message", "")))
	var target := String(result.get("target_room", ""))
	if not target.is_empty():
		var transition_animation := String(result.get("transition_animation", "walk_side_right"))
		if transition_animation.is_empty():
			transition_animation = "walk_side_right"
		_play_corvin_runtime_animation(transition_animation)
		if narrative and narrative.has_method("consume_float_warmth_room_step"):
			narrative.consume_float_warmth_room_step()
		R.goto_room(target, false, true)
	_refresh_narrative_hud()

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

func _start_duel(opponent_id: String, result: Dictionary) -> void:
	var narrative := _narrative()
	if not narrative:
		_say("The Litany is unavailable.")
		return
	if _duel_panel and is_instance_valid(_duel_panel):
		_duel_panel.queue_free()
	var DuelPanel := load("res://game/ui/duel_panel.gd")
	_duel_panel = DuelPanel.new()
	add_child(_duel_panel)
	_pending_duel_result = result.duplicate(true)
	_duel_panel.duel_won.connect(_on_duel_won)
	_duel_panel.duel_lost.connect(_on_duel_lost)
	_duel_panel.start_duel(opponent_id, narrative, result.get("duel_pool", []))
	_play_ink_knot("%s_duel_start" % opponent_id)
	_say("The Registrar opens the Litany.")

func _on_duel_won(_opponent_id: String) -> void:
	var result := _pending_duel_result.duplicate(true)
	result["duel_opponent"] = ""
	result["duel_pool"] = []
	_pending_duel_result.clear()
	_play_ink_knot("%s_duel_win" % _opponent_id)
	_apply_interaction_result(result)

func _on_duel_lost(_opponent_id: String) -> void:
	_pending_duel_result.clear()
	_play_ink_knot("%s_duel_loss" % _opponent_id)
	_say("The Registrar closes the book. Salt wins the room.")

func _play_ink_knot(knot_name: String) -> void:
	var bridge := get_node_or_null("/root/InkBridge")
	if bridge and bridge.has_method("play_knot"):
		var lines: Array[Dictionary] = bridge.play_knot(knot_name)
		if _hud and _hud.has_method("set_dialogue_lines"):
			_hud.set_dialogue_lines(lines)

func _resolve_ink_knot(result: Dictionary, narrative: Node) -> String:
	var knot_name := String(result.get("ink_knot", ""))
	if knot_name == "juno_hot_pool_soak" and narrative and narrative.has_act_i_flag("FL_float_warmth_expired"):
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
	if _hud.has_method("set_inventory_items"):
		_hud.set_inventory_items(narrative.acquired_items)

func _narrative() -> Node:
	return get_node_or_null("/root/N")

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
