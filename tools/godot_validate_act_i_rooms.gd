extends SceneTree

const ROOMS := {
	"Mudflats": "res://game/rooms/mudflats/room_mudflats.tres",
	"OldQuay": "res://game/rooms/old_quay/room_old_quay.tres",
	"SaltMarket": "res://game/rooms/salt_market/room_salt_market.tres",
	"HarborRegistry": "res://game/rooms/harbor_registry/room_harbor_registry.tres",
	"BoneChandler": "res://game/rooms/bone_chandler/room_bone_chandler.tres",
	"Almshouse": "res://game/rooms/almshouse/room_almshouse.tres",
	"FishHall": "res://game/rooms/fish_hall/room_fish_hall.tres",
	"ChurchOfTheDrowned": "res://game/rooms/church_of_the_drowned/room_church_of_the_drowned.tres",
	"GreyFloat": "res://game/rooms/grey_float/room_grey_float.tres",
	"HarbormasterOffice": "res://game/rooms/harbormaster_office/room_harbormaster_office.tres",
	"SabineOffice": "res://game/rooms/sabine_office/room_sabine_office.tres",
}

const REQUIRED_CHILDREN := [
	"WalkableAreas",
	"Props",
	"Hotspots",
	"Regions",
	"Markers",
	"Markers/PlayerStart",
	"Characters",
	"PrologueHud",
]

const ACT_I_GENERATED_ROOMS := [
	"OldQuay",
	"SaltMarket",
	"HarborRegistry",
	"BoneChandler",
	"Almshouse",
	"FishHall",
	"ChurchOfTheDrowned",
	"GreyFloat",
	"HarbormasterOffice",
	"SabineOffice",
]
const ACT_I_RUNTIME_PROP_COUNTS := {
	"Mudflats": 3,
	"OldQuay": 4,
	"SaltMarket": 5,
	"HarborRegistry": 4,
	"BoneChandler": 4,
	"Almshouse": 5,
	"FishHall": 5,
	"ChurchOfTheDrowned": 4,
	"GreyFloat": 4,
	"HarbormasterOffice": 5,
	"SabineOffice": 4,
}

const MUDFLATS_REQUIRED_HOTSPOTS := [
	"Silt",
	"OwnHands",
	"HarborView",
	"Coat",
	"BollardOfTomas",
	"MissingBoots",
	"SaltMarketExit",
]
const MUDFLATS_SCRIPT_PATH := "res://game/rooms/mudflats/room_mudflats.gd"
const MUDFLATS_HOTSPOT_HANDLERS := {
	"Silt": "_handle_silt",
	"OwnHands": "_handle_hands",
	"HarborView": "_handle_harbor_view",
	"Coat": "_handle_coat",
	"BollardOfTomas": "_handle_tomas",
	"MissingBoots": "_handle_boots",
	"SaltMarketExit": "_handle_exit",
}
const GENERATED_ROOM_SCRIPT_PATH := "res://game/rooms/act_i_greybox_room.gd"
const VERB_ACTION_CONTRACT := {
	"talk": "talk_current_side",
	"use": "use_current_side",
	"wet": "wet_current_side",
}

const REQUIRED_VERBS := ["look", "use", "talk", "walk", "wet"]
const PLACEHOLDER_PATTERNS := [
	"Greybox:",
	"I can't do that",
	"I cant do that",
	"nothing happens",
	"doesn't work",
	"does not work",
	"TODO",
	"TO WRITE",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var registered := _load_registered_rooms()
	var exit_graph := {}

	for room_name in ROOMS:
		exit_graph[room_name] = []
		if not registered.has(room_name):
			failures.append("Popochiu data missing room registration: %s" % room_name)
			continue
		if registered[room_name] != ROOMS[room_name]:
			failures.append("Room %s registered to %s, expected %s" % [room_name, registered[room_name], ROOMS[room_name]])

		var data = load(ROOMS[room_name])
		if data == null:
			failures.append("Could not load room data: %s" % ROOMS[room_name])
			continue

		var scene_path := String(data.get("scene"))
		if scene_path.is_empty():
			failures.append("Room %s has no scene path" % room_name)
			continue

		var packed: PackedScene = load(scene_path)
		if packed == null:
			failures.append("Could not load room scene: %s" % scene_path)
			continue

		var instance := packed.instantiate()
		if instance == null:
			failures.append("Could not instantiate room scene: %s" % scene_path)
			continue

		for child_path in REQUIRED_CHILDREN:
			if instance.get_node_or_null(child_path) == null:
				failures.append("Room %s missing required child: %s" % [room_name, child_path])
		_validate_act_i_runtime_prop_layer(room_name, instance, failures)

		var hotspots := instance.get_node_or_null("Hotspots")
		if hotspots != null:
			if room_name == "Mudflats":
				for required_hotspot in MUDFLATS_REQUIRED_HOTSPOTS:
					if hotspots.get_node_or_null(required_hotspot) == null:
						failures.append("Mudflats missing required tutorial hotspot: %s" % required_hotspot)
				_validate_mudflats_custom_handlers(failures)
			for child in hotspots.get_children():
				var target := String(child.get("target_room")) if child.get("target_room") != null else ""
				if target.is_empty() and room_name == "Mudflats" and String(child.name) == "SaltMarketExit":
					target = "SaltMarket"
				if not target.is_empty() and not ROOMS.has(target):
					failures.append("Room %s exit %s targets unknown room %s" % [room_name, child.name, target])
				elif not target.is_empty():
					exit_graph[room_name].append(target)
				if ACT_I_GENERATED_ROOMS.has(room_name):
					_validate_hotspot_responses(room_name, child, failures)
					_validate_exit_transition_animation(room_name, child, failures)
		elif ACT_I_GENERATED_ROOMS.has(room_name):
			failures.append("Generated Act I room %s has no Hotspots node." % room_name)

		instance.free()

	_validate_reachability(exit_graph, failures)
	_validate_room_verb_action_contract(failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("Act I room graph validation passed.")
	quit(0)

func _validate_reachability(exit_graph: Dictionary, failures: Array[String]) -> void:
	var start_room := "Mudflats"
	var seen := {}
	var queue: Array[String] = [start_room]
	seen[start_room] = true
	while not queue.is_empty():
		var current: String = queue.pop_front()
		for target in exit_graph.get(current, []):
			var target_name := String(target)
			if seen.has(target_name):
				continue
			seen[target_name] = true
			queue.append(target_name)

	for room_name in ROOMS.keys():
		if not seen.has(room_name):
			failures.append("Room %s is not reachable from %s through actual room exits." % [room_name, start_room])

	var expected_market_exits := ["OldQuay", "HarborRegistry", "BoneChandler", "Almshouse", "FishHall", "ChurchOfTheDrowned"]
	for target in expected_market_exits:
		if target not in exit_graph.get("SaltMarket", []):
			failures.append("Salt Market hub is missing expected exit to %s." % target)

func _validate_hotspot_responses(room_name: String, hotspot: Node, failures: Array[String]) -> void:
	if not hotspot.has_method("handle_room_verb"):
		failures.append("Room %s hotspot %s has no verb handler." % [room_name, hotspot.name])
		return

	for verb in REQUIRED_VERBS:
		var result: Dictionary = hotspot.handle_room_verb(verb)
		var message := String(result.get("message", "")).strip_edges()
		if message.is_empty():
			failures.append("Room %s hotspot %s has empty %s response." % [room_name, hotspot.name, verb])
		for pattern in PLACEHOLDER_PATTERNS:
			if message.contains(pattern):
				failures.append("Room %s hotspot %s %s response contains placeholder pattern: %s" % [room_name, hotspot.name, verb, pattern])

	var has_requirements := false
	if hotspot.get("requires_flags") != null and hotspot.get("requires_flags").size() > 0:
		has_requirements = true
	if hotspot.get("requires_items") != null and hotspot.get("requires_items").size() > 0:
		has_requirements = true
	if has_requirements:
		var blocked_text := String(hotspot.get("blocked_text") if hotspot.get("blocked_text") != null else "").strip_edges()
		if blocked_text.is_empty():
			failures.append("Room %s gated hotspot %s has no blocked_text." % [room_name, hotspot.name])
		for pattern in PLACEHOLDER_PATTERNS:
			if blocked_text.contains(pattern):
				failures.append("Room %s gated hotspot %s blocked_text contains placeholder pattern: %s" % [room_name, hotspot.name, pattern])


func _validate_exit_transition_animation(room_name: String, hotspot: Node, failures: Array[String]) -> void:
	var target := String(hotspot.get("target_room")) if hotspot.get("target_room") != null else ""
	if target.is_empty():
		return
	if not hotspot.has_method("handle_room_verb"):
		failures.append("Room %s exit %s has no verb handler for transition animation." % [room_name, hotspot.name])
		return

	var result: Dictionary = hotspot.handle_room_verb("walk")
	var transition_animation := String(result.get("transition_animation", ""))
	var expected_animation := "walk_side_left" if hotspot.position.x < 960.0 else "walk_side_right"
	if transition_animation != expected_animation:
		failures.append("Room %s exit %s transition animation mismatch: got %s expected %s." % [room_name, hotspot.name, transition_animation, expected_animation])

func _validate_mudflats_custom_handlers(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string(MUDFLATS_SCRIPT_PATH)
	if source.is_empty():
		failures.append("Could not read Mudflats room script for custom handler coverage: %s" % MUDFLATS_SCRIPT_PATH)
		return

	for hotspot_name in MUDFLATS_REQUIRED_HOTSPOTS:
		var dispatch_line := "\"%s\":" % hotspot_name
		if not source.contains(dispatch_line):
			failures.append("Mudflats custom dispatch missing hotspot match arm: %s" % hotspot_name)

		var handler_name := String(MUDFLATS_HOTSPOT_HANDLERS.get(hotspot_name, ""))
		if handler_name.is_empty():
			failures.append("Mudflats custom handler map missing hotspot: %s" % hotspot_name)
			continue

		var handler_block := _extract_function_block(source, handler_name)
		if handler_block.is_empty():
			failures.append("Mudflats custom handler missing function: %s" % handler_name)
			continue

		for verb in REQUIRED_VERBS:
			if not handler_block.contains("\"%s\":" % verb):
				failures.append("Mudflats custom handler %s has no explicit %s response." % [handler_name, verb])

func _validate_act_i_runtime_prop_layer(room_name: String, instance: Node, failures: Array[String]) -> void:
	if not ACT_I_RUNTIME_PROP_COUNTS.has(room_name):
		return
	if not instance.has_method("_apply_real_art_presentation"):
		failures.append("Room %s cannot apply real art presentation." % room_name)
		return
	instance.call("_apply_real_art_presentation")
	var container := instance.get_node_or_null("Props/ActIForegroundProps")
	if container == null:
		failures.append("Room %s missing runtime ActIForegroundProps container." % room_name)
		return
	var expected_props := int(ACT_I_RUNTIME_PROP_COUNTS[room_name])
	var prop_sprites := 0
	var contact_shadows := 0
	var wet_reflections := 0
	for child in container.get_children():
		if String(child.name).ends_with("Prop"):
			prop_sprites += 1
		elif String(child.name).ends_with("ContactShadow"):
			contact_shadows += 1
		elif String(child.name).ends_with("WetReflection"):
			wet_reflections += 1
	if room_name == "Mudflats":
		var props := instance.get_node_or_null("Props")
		if props != null:
			for prop_name in ["BrineSiltProp", "TomasBollardProp", "MissingBootsProp"]:
				if props.get_node_or_null(prop_name) is Sprite2D:
					prop_sprites += 1
	if prop_sprites != expected_props:
		failures.append("Room %s runtime prop sprite count mismatch: got %d expected %d." % [room_name, prop_sprites, expected_props])
	if contact_shadows != expected_props:
		failures.append("Room %s runtime prop contact-shadow count mismatch: got %d expected %d." % [room_name, contact_shadows, expected_props])
	if wet_reflections != expected_props:
		failures.append("Room %s runtime wet-reflection count mismatch: got %d expected %d." % [room_name, wet_reflections, expected_props])

func _validate_room_verb_action_contract(failures: Array[String]) -> void:
	_validate_room_source_verb_action_contract(
		"generated Act I room",
		GENERATED_ROOM_SCRIPT_PATH,
		"_on_interaction_hotspot_input",
		failures
	)
	_validate_room_source_verb_action_contract(
		"Mudflats custom room",
		MUDFLATS_SCRIPT_PATH,
		"_on_hotspot_input",
		failures
	)

func _validate_room_source_verb_action_contract(label: String, script_path: String, input_function: String, failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string(script_path)
	if source.is_empty():
		failures.append("Could not read %s script for Corvin verb-action contract: %s" % [label, script_path])
		return
	if not source.contains("func _play_corvin_verb_action(verb: String) -> bool:"):
		failures.append("%s missing _play_corvin_verb_action helper." % label)
	for verb in VERB_ACTION_CONTRACT.keys():
		var animation_name := String(VERB_ACTION_CONTRACT[verb])
		if not source.contains("\"%s\":" % verb):
			failures.append("%s verb-action helper missing %s match arm." % [label, verb])
		if not source.contains("\"%s\"" % animation_name):
			failures.append("%s verb-action helper missing %s animation alias." % [label, animation_name])

	var input_block := _extract_function_block(source, input_function)
	if input_block.is_empty():
		failures.append("%s missing input function %s for verb-action contract." % [label, input_function])
		return
	if not input_block.contains("_play_corvin_verb_action(verb)"):
		failures.append("%s input function %s does not call _play_corvin_verb_action(verb)." % [label, input_function])
	if not _source_order_before(input_block, "_play_corvin_verb_action(verb)", "handle_room_verb") and input_function == "_on_interaction_hotspot_input":
		failures.append("%s must call _play_corvin_verb_action before handle_room_verb." % label)
	if not _source_order_before(input_block, "_play_corvin_verb_action(verb)", "match hotspot.name") and input_function == "_on_hotspot_input":
		failures.append("%s must call _play_corvin_verb_action before hotspot dispatch." % label)

func _source_order_before(source: String, first: String, second: String) -> bool:
	var first_index := source.find(first)
	var second_index := source.find(second)
	return first_index != -1 and second_index != -1 and first_index < second_index

func _extract_function_block(source: String, function_name: String) -> String:
	var start := source.find("func %s(" % function_name)
	if start == -1:
		return ""
	var next := source.find("\nfunc ", start + 1)
	if next == -1:
		return source.substr(start)
	return source.substr(start, next - start)

func _load_registered_rooms() -> Dictionary:
	var config := ConfigFile.new()
	var err := config.load("res://game/popochiu_data.cfg")
	if err != OK:
		push_error("Could not load Popochiu data: %s" % error_string(err))
		return {}

	var rooms := {}
	for room_name in config.get_section_keys("rooms"):
		rooms[room_name] = String(config.get_value("rooms", room_name))
	return rooms
