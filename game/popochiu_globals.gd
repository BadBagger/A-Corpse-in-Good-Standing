extends Node

func on_save() -> Dictionary:
	var narrative := get_node_or_null("/root/N")
	if not narrative or not narrative.has_method("to_snapshot"):
		return {}
	return {
		"narrative": narrative.to_snapshot()
	}

func on_load(data: Dictionary) -> void:
	if not data.has("narrative"):
		return
	var narrative := get_node_or_null("/root/N")
	if narrative and narrative.has_method("apply_snapshot"):
		narrative.apply_snapshot(data.narrative)
