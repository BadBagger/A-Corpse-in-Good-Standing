@tool
extends PopochiuHotspot

@export var display_name := ""
@export var interaction_key := ""
@export_multiline var look_text := ""
@export_multiline var use_text := ""
@export_multiline var talk_text := ""
@export_multiline var walk_text := ""
@export_multiline var wet_text := ""
@export var requires_items: Array[String] = []
@export var requires_flags: Array[String] = []
@export var items_add: Array[String] = []
@export var flags_set: Array[String] = []
@export var confessions_discover: Array[String] = []
@export var confessions_spend: Array[String] = []
@export var wet_items_add: Array[String] = []
@export var wet_flags_set: Array[String] = []
@export var wet_confessions_discover: Array[String] = []
@export var wet_confessions_spend: Array[String] = []
@export var wet_ink_knot := ""
@export_multiline var blocked_text := ""
@export var target_room := ""
@export var duel_opponent := ""
@export var duel_pool: Array[String] = []
@export var ink_knot := ""
@export var blocked_ink_knot := ""
@export var alternate_requires_flags: Array[String] = []
@export_multiline var alternate_message := ""
@export var alternate_flags_set: Array[String] = []
@export var alternate_ink_knot := ""

func _ready() -> void:
	if not is_in_group("act_i_interaction_hotspot"):
		add_to_group("act_i_interaction_hotspot")

func get_hover_label() -> String:
	if not display_name.is_empty():
		return display_name
	if not interaction_key.is_empty():
		return _format_hover_label(interaction_key)
	return _format_hover_label(name)

func handle_room_verb(verb: String) -> Dictionary:
	var result := {
		"interaction_key": interaction_key,
		"verb": verb,
		"requires_items": requires_items,
		"requires_flags": requires_flags,
		"items_add": [],
		"flags_set": [],
		"confessions_discover": [],
		"confessions_spend": [],
		"blocked_text": blocked_text,
		"target_room": ""
		,
		"duel_opponent": "",
		"duel_pool": [],
		"ink_knot": "",
		"blocked_ink_knot": blocked_ink_knot,
		"alternate_requires_flags": alternate_requires_flags,
		"alternate_message": alternate_message,
		"alternate_flags_set": alternate_flags_set,
		"alternate_ink_knot": alternate_ink_knot
	}

	match verb:
		"look":
			result["message"] = look_text
		"use":
			result["message"] = use_text
			result["items_add"] = items_add
			result["flags_set"] = flags_set
			result["confessions_discover"] = confessions_discover
			result["confessions_spend"] = confessions_spend
			result["target_room"] = target_room
			result["duel_opponent"] = duel_opponent
			result["duel_pool"] = duel_pool
			result["ink_knot"] = ink_knot
		"talk":
			result["message"] = talk_text
			result["items_add"] = items_add
			result["flags_set"] = flags_set
			result["confessions_discover"] = confessions_discover
			result["confessions_spend"] = confessions_spend
			result["target_room"] = target_room
			result["duel_opponent"] = duel_opponent
			result["duel_pool"] = duel_pool
			result["ink_knot"] = ink_knot
		"walk":
			result["message"] = walk_text
		"wet":
			result["message"] = wet_text
			result["items_add"] = wet_items_add
			result["flags_set"] = wet_flags_set
			result["confessions_discover"] = wet_confessions_discover
			result["confessions_spend"] = wet_confessions_spend
			result["ink_knot"] = wet_ink_knot
		_:
			result["message"] = "Corvin tries a different angle. Mordida, naturally, charges extra for angles."

	if String(result.get("message", "")).is_empty():
		result["message"] = "Corvin studies %s and finds it suspiciously willing to be noticed." % interaction_key
	return result

func _format_hover_label(value: String) -> String:
	var normalized := value.replace("_", " ").strip_edges()
	if normalized.is_empty():
		return "Hotspot"
	return normalized.capitalize()
