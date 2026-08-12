extends SceneTree

const CHARACTER_SCENE := "res://game/characters/corvin/character_corvin.tscn"
const MUDFLATS_SCENE := "res://game/rooms/mudflats/room_mudflats.tscn"
const GENERATED_ROOM_SCENE := "res://game/rooms/salt_market/room_salt_market.tscn"

var _character: Node

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_character = _instantiate_scene(CHARACTER_SCENE)
	if _character == null:
		return
	root.add_child(_character)
	_register_corvin(_character)

	var runtime_sprite := _character.get_node_or_null("RuntimeSprite")
	if runtime_sprite == null or not runtime_sprite.has_method("active_animation_for_test"):
		_fail("Corvin RuntimeSprite is missing animation test hooks.")
		return

	var mudflats := _instantiate_scene(MUDFLATS_SCENE)
	if mudflats == null:
		return
	root.add_child(mudflats)
	mudflats.call("_on_room_transition_finished")
	if String(runtime_sprite.call("active_animation_for_test")) != "idle_side_right":
		_fail("Mudflats transition-finished hook did not set Corvin current-side idle to idle_side_right.")
		return

	if not bool(mudflats.call("_play_corvin_runtime_animation", "walk_side_right")):
		_fail("Mudflats room helper could not call Corvin walk_side_right.")
		return
	if String(runtime_sprite.call("active_animation_for_test")) != "walk_side_right":
		_fail("Mudflats room helper did not switch Corvin to walk_side_right.")
		return
	if not bool(_character.call("play_idle_side_right")):
		_fail("Corvin bridge could not reset to side-right idle before Mudflats pending verb validation.")
		return
	for verb in ["talk", "use", "wet"]:
		if bool(mudflats.call("_play_corvin_verb_action", verb)):
			_fail("Mudflats room helper accepted pending Corvin %s action." % verb)
			return
		if String(runtime_sprite.call("active_animation_for_test")) != "idle_side_right":
			_fail("Mudflats pending Corvin %s action changed the active animation." % verb)
			return
	if not bool(_character.call("play_idle_side_right")):
		_fail("Corvin bridge could not reset to idle before generated-room validation.")
		return

	var generated_room := _instantiate_scene(GENERATED_ROOM_SCENE)
	if generated_room == null:
		return
	root.add_child(generated_room)
	generated_room.call("_on_room_transition_finished")
	if String(runtime_sprite.call("active_animation_for_test")) != "idle_side_right":
		_fail("Generated Act I room transition-finished hook did not set Corvin current-side idle to idle_side_right.")
		return

	if not bool(generated_room.call("_play_corvin_runtime_animation", "walk_side_right")):
		_fail("Generated Act I room helper could not call Corvin walk_side_right.")
		return
	if String(runtime_sprite.call("active_animation_for_test")) != "walk_side_right":
		_fail("Generated Act I room helper did not switch Corvin to walk_side_right.")
		return
	if not bool(_character.call("play_idle_side_right")):
		_fail("Corvin bridge could not reset to side-right idle before generated pending verb validation.")
		return
	for verb in ["talk", "use", "wet"]:
		if bool(generated_room.call("_play_corvin_verb_action", verb)):
			_fail("Generated Act I room helper accepted pending Corvin %s action." % verb)
			return
		if String(runtime_sprite.call("active_animation_for_test")) != "idle_side_right":
			_fail("Generated Act I pending Corvin %s action changed the active animation." % verb)
			return
	generated_room.call("_on_room_transition_finished")
	if String(runtime_sprite.call("active_animation_for_test")) != "idle_side_right":
		_fail("Generated Act I room transition-finished hook did not preserve side-right idle after rightward walk.")
		return
	if not bool(generated_room.call("_play_corvin_runtime_animation", "walk_side_left")):
		_fail("Generated Act I room helper could not call Corvin walk_side_left.")
		return
	if String(runtime_sprite.call("active_animation_for_test")) != "walk_side_left":
		_fail("Generated Act I room helper did not switch Corvin to walk_side_left.")
		return
	generated_room.call("_on_room_transition_finished")
	if String(runtime_sprite.call("active_animation_for_test")) != "idle_side_left":
		_fail("Generated Act I room transition-finished hook did not preserve side-left idle after leftward walk.")
		return
	print("Corvin room animation hook validation passed: mudflats=current-side-idle/walk/pending-verb-actions, generatedActIRoom=current-side-idle/walk-left/walk-right/pending-verb-actions.")
	quit(0)


func _instantiate_scene(path: String) -> Node:
	var packed := load(path)
	if not packed is PackedScene:
		_fail("Unable to load scene: %s" % path)
		return null
	var instance := (packed as PackedScene).instantiate()
	if instance == null:
		_fail("Unable to instantiate scene: %s" % path)
	return instance


func _register_corvin(character: Node) -> void:
	if character.get("script_name") == null or String(character.get("script_name")).is_empty():
		character.set("script_name", "Corvin")
	var characters: Node = root.get_node_or_null("C")
	if characters == null:
		_fail("Popochiu character autoload C is unavailable.")
		return
	var registry: Dictionary = characters.get("_characters")
	registry["Corvin"] = character
	characters.set("_characters", registry)


func _fail(message: String) -> void:
	push_error(message)
	print("ERROR: %s" % message)
	quit(1)
