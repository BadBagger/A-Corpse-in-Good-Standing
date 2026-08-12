@tool
extends PopochiuHotspot

@export var display_name := ""
@export var target_room := ""
@export_multiline var look_text := ""
@export_multiline var use_text := ""
@export_multiline var talk_text := ""
@export_multiline var walk_text := ""
@export var requires_items: Array[String] = []
@export var requires_flags: Array[String] = []
@export_multiline var blocked_text := ""
@export var room_midpoint_x := 960.0

func _ready() -> void:
	if not is_in_group("act_i_exit_hotspot"):
		add_to_group("act_i_exit_hotspot")

func get_hover_label() -> String:
	if not display_name.is_empty():
		return display_name
	if not target_room.is_empty():
		return _format_hover_label(target_room)
	return _format_hover_label(name)

func handle_room_verb(verb: String) -> Dictionary:
	match verb:
		"walk":
			return {
				"message": walk_text if not walk_text.is_empty() else "Corvin goes that way, because the plot has manners.",
				"target_room": target_room,
				"transition_animation": _transition_animation(),
				"requires_items": requires_items,
				"requires_flags": requires_flags,
				"blocked_text": blocked_text
			}
		"look":
			return {"message": look_text if not look_text.is_empty() else "A way through Mordida. None of them look innocent."}
		"use":
			return {"message": use_text if not use_text.is_empty() else "Corvin considers making this more complicated. Growth is declining."}
		"talk":
			return {"message": talk_text if not talk_text.is_empty() else "No answer. The architecture keeps counsel."}
		_:
			return {"message": "Corvin tries a different approach. The route remains a route."}


func _transition_animation() -> String:
	if position.x < room_midpoint_x:
		return "walk_side_left"
	return "walk_side_right"

func _format_hover_label(value: String) -> String:
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
		return "Exit"
	return normalized.capitalize()
