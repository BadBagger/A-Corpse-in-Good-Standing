extends SceneTree

const FRAME_SIZE := Vector2i(640, 720)
const OUT_DIR := "res://docs/art/review/corvin_action_runtime_frames"
const CONTACT_SHEET := "res://docs/art/review/corvin_action_runtime_contact_sheet.png"
const REPORT_JSON := "res://docs/art/corvin_action_runtime_frames.json"
const REPORT_MD := "res://docs/art/corvin_action_runtime_frames.md"
const CHARACTER_SCENE := "res://game/characters/corvin/character_corvin.tscn"
const CASES := [
	{"id": "idle_side_right", "method": "play_idle_side_right", "expected": "idle_side_right", "frames": 12},
	{"id": "talk_side_right", "method": "play_talk_side_right", "expected": "talk_side_right", "frames": 6},
	{"id": "use_side_right", "method": "play_use_side_right", "expected": "use_side_right", "frames": 8},
	{"id": "wet_side_right", "method": "play_wet_side_right", "expected": "wet_side_right", "frames": 8},
	{"id": "idle_side_left", "method": "play_idle_side_left", "expected": "idle_side_left", "frames": 12},
	{"id": "talk_side_left", "method": "play_talk_side_left", "expected": "talk_side_left", "frames": 6},
	{"id": "use_side_left", "method": "play_use_side_left", "expected": "use_side_left", "frames": 8},
	{"id": "wet_side_left", "method": "play_wet_side_left", "expected": "wet_side_left", "frames": 8},
]

var _viewport: SubViewport
var _records: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_prepare_output_dir()
	_setup_viewport()
	for action_case in CASES:
		var record := await _capture_action(action_case, failures)
		if not record.is_empty():
			_records.append(record)
	if failures.is_empty():
		var contact_error := _build_contact_sheet()
		if not contact_error.is_empty():
			failures.append(contact_error)
	if failures.is_empty():
		_write_report()
		print("Corvin action runtime capture passed: frames=%d." % _records.size())
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _prepare_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))


func _setup_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "CorvinActionRuntimeCaptureViewport"
	_viewport.size = FRAME_SIZE
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.transparent_bg = false
	root.add_child(_viewport)


func _capture_action(action_case: Dictionary, failures: Array[String]) -> Dictionary:
	var stage := _make_stage()
	_viewport.add_child(stage)
	var packed: PackedScene = load(CHARACTER_SCENE)
	if packed == null:
		failures.append("Could not load Corvin character scene: %s" % CHARACTER_SCENE)
		stage.queue_free()
		await process_frame
		return {}
	var character := packed.instantiate()
	if character == null:
		failures.append("Could not instantiate Corvin character scene.")
		stage.queue_free()
		await process_frame
		return {}
	character.name = "RuntimeCorvinActionProof"
	character.position = Vector2(FRAME_SIZE.x * 0.5, 602)
	character.z_index = 4
	stage.add_child(character)
	await process_frame
	var method := String(action_case["method"])
	if not character.has_method(method) or not bool(character.call(method)):
		failures.append("Corvin action capture could not play method: %s" % method)
		stage.queue_free()
		await process_frame
		return {}
	await process_frame
	await process_frame
	var runtime_sprite := character.get_node_or_null("RuntimeSprite")
	if runtime_sprite == null or not runtime_sprite.has_method("active_animation_for_test"):
		failures.append("Corvin action capture missing RuntimeSprite test hooks.")
		stage.queue_free()
		await process_frame
		return {}
	var active_animation := String(runtime_sprite.call("active_animation_for_test"))
	if active_animation != String(action_case["expected"]):
		failures.append("Corvin action capture method %s produced %s, expected %s." % [method, active_animation, action_case["expected"]])
		stage.queue_free()
		await process_frame
		return {}
	if int(runtime_sprite.call("frame_count_for_test")) != int(action_case["frames"]):
		failures.append("Corvin action capture method %s loaded wrong frame count." % method)
		stage.queue_free()
		await process_frame
		return {}
	var image := _viewport.get_texture().get_image()
	if image == null or image.is_empty():
		failures.append("Corvin action capture viewport image was empty for %s." % action_case["id"])
		stage.queue_free()
		await process_frame
		return {}
	var output := "%s/%s_runtime_frame.png" % [OUT_DIR, action_case["id"]]
	var err := image.save_png(output)
	if err != OK:
		failures.append("Could not save Corvin action frame %s: %s" % [output, error_string(err)])
		stage.queue_free()
		await process_frame
		return {}
	stage.queue_free()
	await process_frame
	return {
		"id": action_case["id"],
		"method": method,
		"active_animation": active_animation,
		"frame_count": int(action_case["frames"]),
		"output": _project_relative(output),
		"uses_actual_corvin_scene": true,
		"uses_runtime_sprite_loader": true,
	}


func _make_stage() -> Node2D:
	var stage := Node2D.new()
	stage.name = "CorvinActionProofStage"
	var background := ColorRect.new()
	background.name = "InkWashBackplate"
	background.size = Vector2(FRAME_SIZE)
	background.color = Color("#0C1013")
	stage.add_child(background)
	var floor := Polygon2D.new()
	floor.name = "WetFloorReadabilityPlate"
	floor.polygon = PackedVector2Array([
		Vector2(52, 616),
		Vector2(588, 616),
		Vector2(620, 690),
		Vector2(20, 690),
	])
	floor.color = Color(0.164706, 0.227451, 0.25098, 0.72)
	floor.z_index = 1
	stage.add_child(floor)
	var glow := Polygon2D.new()
	glow.name = "WhaleOilActionLight"
	glow.polygon = PackedVector2Array([
		Vector2(74, 110),
		Vector2(566, 96),
		Vector2(548, 628),
		Vector2(96, 636),
	])
	glow.color = Color(0.788235, 0.541176, 0.235294, 0.12)
	glow.z_index = 2
	stage.add_child(glow)
	return stage


func _build_contact_sheet() -> String:
	var columns := 4
	var thumb_size := Vector2i(320, 360)
	var label_height := 0
	var pad := 20
	var rows := int(ceil(float(_records.size()) / float(columns)))
	var sheet_size := Vector2i(columns * thumb_size.x + (columns + 1) * pad, rows * (thumb_size.y + label_height) + (rows + 1) * pad)
	var sheet := Image.create(sheet_size.x, sheet_size.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.0470588, 0.0627451, 0.0745098, 1.0))
	for index in range(_records.size()):
		var record := _records[index]
		var frame := Image.new()
		var err := frame.load("res://%s" % record["output"])
		if err != OK:
			return "Could not load Corvin action frame for contact sheet: %s" % record["output"]
		frame.convert(Image.FORMAT_RGBA8)
		frame.resize(thumb_size.x, thumb_size.y, Image.INTERPOLATE_LANCZOS)
		var x := pad + (index % columns) * (thumb_size.x + pad)
		var y := pad + int(index / columns) * (thumb_size.y + label_height + pad)
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, thumb_size), Vector2i(x, y))
	var err := sheet.save_png(CONTACT_SHEET)
	if err != OK:
		return "Could not save Corvin action runtime contact sheet %s: %s" % [CONTACT_SHEET, error_string(err)]
	return ""


func _write_report() -> void:
	var report := {
		"status": "captured",
		"capture": "godot_subviewport",
		"frame_count": _records.size(),
		"contact_sheet": _project_relative(CONTACT_SHEET),
		"runtime_evidence": "Godot-rendered actual Corvin character scene using RuntimeSprite loader and action bridge methods for idle, talk, use, and wet side animations.",
		"frames": _records,
	}
	var json_file := FileAccess.open(REPORT_JSON, FileAccess.WRITE)
	json_file.store_string(JSON.stringify(report, "\t") + "\n")
	json_file.close()
	var lines: Array[String] = [
		"# Corvin Action Runtime Frames",
		"",
		"Generated by `tools/godot_capture_corvin_action_frames.gd`.",
		"",
		"These frames are captured from Godot SubViewport rendering of the actual `game/characters/corvin/character_corvin.tscn` scene. The capture calls the runtime action bridge methods and verifies the `RuntimeSprite` active animation for idle, talk, use, and wet side actions.",
		"",
		"- Contact sheet: `%s`" % report["contact_sheet"],
		"- Frame count: %d" % _records.size(),
		"",
		"| Action | Method | Active animation | Frames | Captured frame |",
		"|---|---|---|---:|---|",
	]
	for record in _records:
		lines.append("| %s | `%s` | `%s` | %d | `%s` |" % [record["id"], record["method"], record["active_animation"], record["frame_count"], record["output"]])
	var md_file := FileAccess.open(REPORT_MD, FileAccess.WRITE)
	md_file.store_string("\n".join(lines) + "\n")
	md_file.close()


func _project_relative(path: String) -> String:
	if path.begins_with("res://"):
		return path.trim_prefix("res://")
	return path
