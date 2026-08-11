extends Node

const PROLOGUE_STORY := "res://ink/build/prologue.ink.json"

var _story_cache: Dictionary = {}

func apply_knot_tags(knot_name: String, story_path: String = PROLOGUE_STORY) -> Array[String]:
	var tags := get_knot_tags(knot_name, story_path)
	var narrative := get_node_or_null("/root/N")
	if not narrative:
		return tags
	for tag in tags:
		if narrative.has_method("apply_ink_tag"):
			narrative.apply_ink_tag(tag)
	return tags

func play_knot(knot_name: String, story_path: String = PROLOGUE_STORY) -> Array[Dictionary]:
	apply_knot_tags(knot_name, story_path)
	return get_knot_lines(knot_name, story_path)

func get_knot_tags(knot_name: String, story_path: String = PROLOGUE_STORY) -> Array[String]:
	var knots := _load_knots(story_path)
	if not knots.has(knot_name):
		push_warning("Ink knot not found: %s" % knot_name)
		return []
	var tags: Array[String] = []
	_collect_tags(knots[knot_name], tags)
	return tags

func get_knot_lines(knot_name: String, story_path: String = PROLOGUE_STORY) -> Array[Dictionary]:
	var knots := _load_knots(story_path)
	if not knots.has(knot_name):
		push_warning("Ink knot not found: %s" % knot_name)
		return []
	return _extract_lines(knots[knot_name])

func _load_knots(story_path: String) -> Dictionary:
	if _story_cache.has(story_path):
		return _story_cache[story_path]
	if not FileAccess.file_exists(story_path):
		push_warning("Ink story not found: %s" % story_path)
		return {}
	var file := FileAccess.open(story_path, FileAccess.READ)
	if not file:
		push_warning("Ink story could not be opened: %s" % story_path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Ink story is not a JSON object: %s" % story_path)
		return {}
	var root = parsed.get("root", [])
	if typeof(root) != TYPE_ARRAY:
		return {}
	for item in root:
		if typeof(item) == TYPE_DICTIONARY:
			_story_cache[story_path] = item
			return item
	return {}

func _collect_tags(value, tags: Array[String]) -> void:
	if typeof(value) != TYPE_ARRAY:
		return
	for index in value.size():
		var item = value[index]
		if typeof(item) == TYPE_ARRAY:
			_collect_tags(item, tags)
			continue
		if typeof(item) != TYPE_STRING:
			continue
		if item != "#":
			continue
		if index + 1 >= value.size() or typeof(value[index + 1]) != TYPE_STRING:
			continue
		var raw_tag := String(value[index + 1])
		if raw_tag.begins_with("^"):
			tags.append(raw_tag.substr(1))

func _extract_lines(value) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return lines
	var speaker := ""
	var pending_tags: Array[String] = []
	var index := 0
	while index < value.size():
		var item = value[index]
		if typeof(item) == TYPE_ARRAY:
			for nested_line in _extract_lines(item):
				lines.append(nested_line)
			index += 1
			continue
		if typeof(item) != TYPE_STRING:
			index += 1
			continue
		if item == "#":
			if index + 1 < value.size() and typeof(value[index + 1]) == TYPE_STRING:
				var raw_tag := String(value[index + 1])
				if raw_tag.begins_with("^"):
					var tag := raw_tag.substr(1)
					if tag.begins_with("speaker:"):
						speaker = tag.substr("speaker:".length())
					elif not tag.begins_with("location:"):
						pending_tags.append(tag)
				index += 3
				continue
		if item.begins_with("^"):
			var text := String(item).substr(1).strip_edges()
			if not text.is_empty():
				lines.append({
					"speaker": speaker,
					"text": text,
					"tags": pending_tags.duplicate()
				})
				pending_tags.clear()
		index += 1
	return lines
