extends SceneTree

const ROOMS := {
	"KaneParlour": "res://game/rooms/kane_parlour/room_kane_parlour.tres",
	"FloatLower": "res://game/rooms/float_lower/room_float_lower.tres",
	"CustomsHouse": "res://game/rooms/customs_house/room_customs_house.tres",
	"KestrelWreck": "res://game/rooms/kestrel_wreck/room_kestrel_wreck.tres",
	"SabineOfficeReturn": "res://game/rooms/sabine_office_return/room_sabine_office_return.tres",
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

const REQUIRED_HOTSPOTS := {
	"KaneParlour": ["Kane", "WaxSeal", "ForgeWrit", "ToFloat", "ToCustoms"],
	"FloatLower": ["Mireille", "SteamScreens", "LampValve", "ToKane", "ToCustoms"],
	"CustomsHouse": ["LedgerCabinet", "TideTable", "HarborAssignment", "ToKane", "ToKestrel", "ToSabine"],
	"KestrelWreck": ["HullRibs", "Strongbox", "CargoHold", "ToCustoms"],
	"SabineOfficeReturn": ["SabineDesk", "DoorOut", "ToCustoms"],
}

const REQUIRED_GATES := {
	"KaneParlour/WaxSeal": {"requires_flags": ["FL_kane_offer_refused"]},
	"KaneParlour/ForgeWrit": {"requires_items": ["IT_kane_seal"]},
	"KaneParlour/ToCustoms": {"requires_items": ["IT_forged_customs_writ"]},
	"CustomsHouse/LedgerCabinet": {"requires_items": ["IT_forged_customs_writ"]},
	"CustomsHouse/TideTable": {"requires_items": ["IT_cut_paper"]},
	"CustomsHouse/ToKestrel": {"requires_items": ["IT_tide_table"]},
	"CustomsHouse/ToSabine": {"requires_flags": ["FL_sabine_reveal_ready"]},
	"KestrelWreck/Strongbox": {"requires_items": ["IT_tide_table"]},
	"KestrelWreck/CargoHold": {"requires_items": ["IT_tomas_papers"]},
	"SabineOfficeReturn/SabineDesk": {"requires_items": ["IT_cut_paper", "IT_tomas_papers"]},
	"SabineOfficeReturn/DoorOut": {"requires_flags": ["FL_act_ii_complete"]},
}

const REQUIRED_REWARDS := {
	"KaneParlour/Kane": {"flags_set": ["FL_act_ii_started", "FL_kane_offer_refused"]},
	"KaneParlour/WaxSeal": {"items_add": ["IT_kane_seal"]},
	"KaneParlour/ForgeWrit": {"items_add": ["IT_forged_customs_writ"]},
	"FloatLower/Mireille": {"items_add": ["IT_mireille_book"], "flags_set": ["FL_memory_decay_tutorial_seen"]},
	"CustomsHouse/LedgerCabinet": {"items_add": ["IT_cut_paper"], "flags_set": ["FL_sabine_signature_seen"]},
	"CustomsHouse/TideTable": {"items_add": ["IT_tide_table"]},
	"CustomsHouse/HarborAssignment": {"confessions_discover": ["cf_bt_harbor"]},
	"KestrelWreck/Strongbox": {"items_add": ["IT_tomas_papers"], "confessions_discover": ["cf_bt_tomas", "cf_pride_kestrel"]},
	"KestrelWreck/CargoHold": {"flags_set": ["FL_sabine_reveal_ready"]},
	"SabineOfficeReturn/SabineDesk": {"flags_set": ["FL_sabine_signed_revealed", "FL_act_ii_complete"]},
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

	for room_name in ROOMS.keys():
		exit_graph[room_name] = []
		if not registered.has(room_name):
			failures.append("Popochiu data missing Act II room registration: %s" % room_name)
			continue
		if registered[room_name] != ROOMS[room_name]:
			failures.append("Act II room %s registered to %s, expected %s" % [room_name, registered[room_name], ROOMS[room_name]])

		var data = load(ROOMS[room_name])
		if data == null:
			failures.append("Could not load Act II room data: %s" % ROOMS[room_name])
			continue

		var scene_path := String(data.get("scene"))
		var packed: PackedScene = load(scene_path)
		if packed == null:
			failures.append("Could not load Act II room scene: %s" % scene_path)
			continue

		var instance := packed.instantiate()
		if instance == null:
			failures.append("Could not instantiate Act II room scene: %s" % scene_path)
			continue

		for child_path in REQUIRED_CHILDREN:
			if instance.get_node_or_null(child_path) == null:
				failures.append("Act II room %s missing required child: %s" % [room_name, child_path])

		var hotspots := instance.get_node_or_null("Hotspots")
		if hotspots == null:
			failures.append("Act II room %s has no Hotspots node." % room_name)
			instance.free()
			continue

		for hotspot_name in REQUIRED_HOTSPOTS[room_name]:
			if hotspots.get_node_or_null(hotspot_name) == null:
				failures.append("Act II room %s missing required hotspot: %s" % [room_name, hotspot_name])

		for child in hotspots.get_children():
			var target := String(child.get("target_room")) if child.get("target_room") != null else ""
			if not target.is_empty():
				if not ROOMS.has(target):
					failures.append("Act II room %s exit %s targets unknown Act II room %s" % [room_name, child.name, target])
				else:
					exit_graph[room_name].append(target)
				_validate_exit_transition_animation(room_name, child, failures)
			_validate_hotspot_responses(room_name, child, failures)
			_validate_gate_contract(room_name, child, failures)
			_validate_reward_contract(room_name, child, failures)

		instance.free()

	_validate_reachability(exit_graph, failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("Act II greybox room validation passed.")
	quit(0)

func _validate_reachability(exit_graph: Dictionary, failures: Array[String]) -> void:
	var start_room := "KaneParlour"
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
			failures.append("Act II room %s is not reachable from %s through actual exits." % [room_name, start_room])

func _validate_hotspot_responses(room_name: String, hotspot: Node, failures: Array[String]) -> void:
	if not hotspot.has_method("handle_room_verb"):
		failures.append("Act II room %s hotspot %s has no verb handler." % [room_name, hotspot.name])
		return

	for verb in REQUIRED_VERBS:
		var result: Dictionary = hotspot.handle_room_verb(verb)
		var message := String(result.get("message", "")).strip_edges()
		if message.is_empty():
			failures.append("Act II room %s hotspot %s has empty %s response." % [room_name, hotspot.name, verb])
		for pattern in PLACEHOLDER_PATTERNS:
			if message.contains(pattern):
				failures.append("Act II room %s hotspot %s %s response contains placeholder pattern: %s" % [room_name, hotspot.name, verb, pattern])

	var requires_items: Array = hotspot.get("requires_items") if hotspot.get("requires_items") != null else []
	var requires_flags: Array = hotspot.get("requires_flags") if hotspot.get("requires_flags") != null else []
	if not requires_items.is_empty() or not requires_flags.is_empty():
		var blocked_text := String(hotspot.get("blocked_text") if hotspot.get("blocked_text") != null else "").strip_edges()
		if blocked_text.is_empty():
			failures.append("Act II room %s gated hotspot %s has no blocked_text." % [room_name, hotspot.name])

func _validate_exit_transition_animation(room_name: String, hotspot: Node, failures: Array[String]) -> void:
	if not hotspot.has_method("handle_room_verb"):
		return
	var result: Dictionary = hotspot.handle_room_verb("walk")
	var transition_animation := String(result.get("transition_animation", ""))
	var expected_animation := "walk_side_left" if hotspot.position.x < 960.0 else "walk_side_right"
	if transition_animation != expected_animation:
		failures.append("Act II room %s exit %s transition animation mismatch: got %s expected %s." % [room_name, hotspot.name, transition_animation, expected_animation])

func _validate_gate_contract(room_name: String, hotspot: Node, failures: Array[String]) -> void:
	var key := "%s/%s" % [room_name, String(hotspot.name)]
	if not REQUIRED_GATES.has(key):
		return
	var expected: Dictionary = REQUIRED_GATES[key]
	for property_name in expected.keys():
		var actual: Array = hotspot.get(property_name) if hotspot.get(property_name) != null else []
		for required_value in expected[property_name]:
			if String(required_value) not in actual:
				failures.append("Act II hotspot %s missing %s gate value %s." % [key, property_name, required_value])

func _validate_reward_contract(room_name: String, hotspot: Node, failures: Array[String]) -> void:
	var key := "%s/%s" % [room_name, String(hotspot.name)]
	if not REQUIRED_REWARDS.has(key):
		return
	var expected: Dictionary = REQUIRED_REWARDS[key]
	for property_name in expected.keys():
		var actual: Array = hotspot.get(property_name) if hotspot.get(property_name) != null else []
		for required_value in expected[property_name]:
			if String(required_value) not in actual:
				failures.append("Act II hotspot %s missing %s reward value %s." % [key, property_name, required_value])

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
