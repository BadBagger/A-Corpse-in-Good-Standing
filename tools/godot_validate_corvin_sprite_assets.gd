extends SceneTree

const FRAME_WIDTH := 256
const FRAME_HEIGHT := 512
const CHARACTER_SCENE := "res://game/characters/corvin/character_corvin.tscn"
const ASSETS := [
	{
		"name": "idle_side_right",
		"path": "res://game/characters/corvin/sprites/act_i_clean/idle_side_right.png",
		"width": 3072,
		"height": 512,
		"frames": 12,
	},
	{
		"name": "idle_side_left",
		"path": "res://game/characters/corvin/sprites/act_i_clean/idle_side_left.png",
		"width": 3072,
		"height": 512,
		"frames": 12,
	},
	{
		"name": "walk_side_right",
		"path": "res://game/characters/corvin/sprites/act_i_clean/walk_side_right.png",
		"width": 2048,
		"height": 512,
		"frames": 8,
	},
	{
		"name": "walk_side_left",
		"path": "res://game/characters/corvin/sprites/act_i_clean/walk_side_left.png",
		"width": 2048,
		"height": 512,
		"frames": 8,
	},
]

func _init() -> void:
	var validation_results: Array[String] = []
	var idle_foreground_pixels := 0
	for asset in ASSETS:
		var foreground_pixels := _validate_sprite_asset(asset)
		validation_results.append("%s=%sframes/%spx" % [asset["name"], asset["frames"], foreground_pixels])
		if asset["name"] == "idle_side_right":
			idle_foreground_pixels = foreground_pixels

	var packed := load(CHARACTER_SCENE)
	if not packed is PackedScene:
		_fail("Unable to load Corvin character scene: %s" % CHARACTER_SCENE)
		return
	var character := (packed as PackedScene).instantiate()
	if not character.has_method("play_runtime_animation"):
		_fail("Corvin character is missing play_runtime_animation().")
		return
	for bridge_method in ["play_idle_side_right", "play_idle_side_left", "play_walk_side_right", "play_walk_side_left", "play_idle_current_side", "active_side_direction_for_test"]:
		if not character.has_method(bridge_method):
			_fail("Corvin character is missing animation bridge method: %s." % bridge_method)
			return
	var runtime_sprite := character.get_node_or_null("RuntimeSprite")
	if runtime_sprite == null:
		_fail("Corvin character scene missing RuntimeSprite node.")
		return
	if not runtime_sprite is Sprite2D:
		_fail("RuntimeSprite is not a Sprite2D.")
		return
	if not runtime_sprite.has_method("_load_sheet"):
		_fail("RuntimeSprite is missing _load_sheet().")
		return
	if not runtime_sprite.has_method("play_animation"):
		_fail("RuntimeSprite is missing play_animation().")
		return
	if not runtime_sprite.has_method("advance_for_test") or not runtime_sprite.has_method("current_frame_for_test"):
		_fail("RuntimeSprite is missing animation test hooks.")
		return
	if not runtime_sprite.has_method("active_animation_for_test") or not runtime_sprite.has_method("frame_count_for_test"):
		_fail("RuntimeSprite is missing animation state test hooks.")
		return
	runtime_sprite.call("_load_sheet")
	if (runtime_sprite as Sprite2D).texture == null:
		_fail("RuntimeSprite did not load its first-frame texture.")
		return
	if String(runtime_sprite.call("active_animation_for_test")) != "idle_side_right":
		_fail("RuntimeSprite did not load idle_side_right by default.")
		return
	if int(runtime_sprite.call("frame_count_for_test")) != 12:
		_fail("RuntimeSprite default idle frame count mismatch.")
		return
	if int(runtime_sprite.call("current_frame_for_test")) != 0:
		_fail("RuntimeSprite did not start on frame 0.")
		return
	var frame_after_tick := int(runtime_sprite.call("advance_for_test", 1.0 / 12.0))
	if frame_after_tick != 1:
		_fail("RuntimeSprite did not advance to frame 1 after one 12fps tick: %s" % frame_after_tick)
		return
	var frame_after_loop := frame_after_tick
	for _i in range(11):
		frame_after_loop = int(runtime_sprite.call("advance_for_test", 1.0 / 12.0))
	if frame_after_loop != 0:
		_fail("RuntimeSprite did not wrap after a full 12-frame loop: %s" % frame_after_loop)
		return
	if not bool(runtime_sprite.call("play_animation", "walk_side_right")):
		_fail("RuntimeSprite could not switch to walk_side_right.")
		return
	if String(runtime_sprite.call("active_animation_for_test")) != "walk_side_right":
		_fail("RuntimeSprite active animation did not change to walk_side_right.")
		return
	if int(runtime_sprite.call("frame_count_for_test")) != 8:
		_fail("RuntimeSprite walk frame count mismatch.")
		return
	if int(runtime_sprite.call("current_frame_for_test")) != 0:
		_fail("RuntimeSprite did not reset to frame 0 when switching to walk.")
		return
	var walk_frame_after_tick := int(runtime_sprite.call("advance_for_test", 1.0 / 12.0))
	if walk_frame_after_tick != 1:
		_fail("RuntimeSprite walk did not advance to frame 1 after one 12fps tick: %s" % walk_frame_after_tick)
		return
	var walk_frame_after_loop := walk_frame_after_tick
	for _i in range(7):
		walk_frame_after_loop = int(runtime_sprite.call("advance_for_test", 1.0 / 12.0))
	if walk_frame_after_loop != 0:
		_fail("RuntimeSprite did not wrap after a full 8-frame walk loop: %s" % walk_frame_after_loop)
		return
	if bool(runtime_sprite.call("play_animation", "missing_animation")):
		_fail("RuntimeSprite accepted an unknown animation.")
		return
	var fallback := character.get_node_or_null("Sprite2D")
	if fallback is CanvasItem and not (fallback as CanvasItem).visible:
		_fail("Polygon fallback did not become visible after unknown animation fallback.")
		return
	if not bool(character.call("play_idle_side_right")):
		_fail("Corvin character bridge could not restore idle_side_right.")
		return
	if String(runtime_sprite.call("active_animation_for_test")) != "idle_side_right":
		_fail("Corvin character bridge did not restore idle_side_right.")
		return
	if fallback is CanvasItem and (fallback as CanvasItem).visible:
		_fail("Polygon fallback stayed visible after character bridge restored a valid animation.")
		return
	if not bool(character.call("play_walk_side_right")):
		_fail("Corvin character bridge could not switch to walk_side_right.")
		return
	if String(runtime_sprite.call("active_animation_for_test")) != "walk_side_right":
		_fail("Corvin character bridge did not switch to walk_side_right.")
		return
	if not bool(character.call("play_idle_side_left")):
		_fail("Corvin character bridge could not switch to idle_side_left.")
		return
	if String(runtime_sprite.call("active_animation_for_test")) != "idle_side_left":
		_fail("Corvin character bridge did not switch to idle_side_left.")
		return
	if int(runtime_sprite.call("frame_count_for_test")) != 12:
		_fail("RuntimeSprite side-left idle frame count mismatch.")
		return
	if not bool(character.call("play_walk_side_left")):
		_fail("Corvin character bridge could not switch to walk_side_left.")
		return
	if String(runtime_sprite.call("active_animation_for_test")) != "walk_side_left":
		_fail("Corvin character bridge did not switch to walk_side_left.")
		return
	if int(runtime_sprite.call("frame_count_for_test")) != 8:
		_fail("RuntimeSprite side-left walk frame count mismatch.")
		return
	if String(character.call("active_side_direction_for_test")) != "side_left":
		_fail("Corvin did not remember side_left after walk_side_left.")
		return
	if not bool(character.call("play_idle_current_side")):
		_fail("Corvin character bridge could not play idle_current_side after side-left walk.")
		return
	if String(runtime_sprite.call("active_animation_for_test")) != "idle_side_left":
		_fail("Corvin idle_current_side did not resolve to idle_side_left.")
		return
	if not bool(character.call("play_walk_side_right")):
		_fail("Corvin character bridge could not switch back to walk_side_right.")
		return
	if String(character.call("active_side_direction_for_test")) != "side_right":
		_fail("Corvin did not remember side_right after walk_side_right.")
		return
	if not bool(character.call("play_idle_current_side")):
		_fail("Corvin character bridge could not play idle_current_side after side-right walk.")
		return
	if String(runtime_sprite.call("active_animation_for_test")) != "idle_side_right":
		_fail("Corvin idle_current_side did not resolve to idle_side_right.")
		return
	if bool(character.call("play_runtime_animation", "missing_animation")):
		_fail("Corvin character bridge accepted an unknown animation.")
		return
	character.free()

	print("Corvin sprite asset validation passed: assets=%s, runtimeSprite=side_right_side_left_idle_walk_switchable, characterBridge=side_right_side_left_idle_walk_switchable, idleForegroundSamples=%s" % [", ".join(validation_results), idle_foreground_pixels])
	quit(0)


func _validate_sprite_asset(asset: Dictionary) -> int:
	var path := String(asset["path"])
	var expected_width := int(asset["width"])
	var expected_height := int(asset["height"])
	var expected_frames := int(asset["frames"])

	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		_fail("Unable to load Corvin sprite sheet: %s err=%s" % [path, err])
		return 0

	if image.get_width() != expected_width or image.get_height() != expected_height:
		_fail("Corvin sprite sheet dimensions mismatch for %s: got %sx%s expected %sx%s" % [path, image.get_width(), image.get_height(), expected_width, expected_height])
		return 0

	if image.get_height() != FRAME_HEIGHT or image.get_width() / FRAME_WIDTH != expected_frames:
		_fail("Corvin sprite sheet frame count mismatch for %s." % path)
		return 0

	var foreground_pixels := 0
	var transparent_pixels := 0
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var color := image.get_pixel(x, y)
			if color.a < 0.1:
				transparent_pixels += 1
			elif color.r > 0.05 or color.g > 0.05 or color.b > 0.05:
				foreground_pixels += 1

	if foreground_pixels < 100:
		_fail("Corvin sprite sheet appears blank: path=%s foreground sample pixels=%s" % [path, foreground_pixels])
		return 0
	if transparent_pixels < 100:
		_fail("Corvin sprite sheet does not appear to have transparent frame padding: %s" % path)
		return 0
	return foreground_pixels


func _fail(message: String) -> void:
	push_error(message)
	print("ERROR: %s" % message)
	quit(1)
