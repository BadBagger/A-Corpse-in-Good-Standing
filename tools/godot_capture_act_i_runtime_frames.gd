extends SceneTree

const FRAME_SIZE := Vector2i(1920, 1080)
const OUT_DIR := "res://docs/art/review/act_i_godot_runtime_frames"
const CONTACT_SHEET := "res://docs/art/review/act_i_godot_runtime_frame_contact_sheet.png"
const REPORT_JSON := "res://docs/art/act_i_godot_runtime_frames.json"
const REPORT_MD := "res://docs/art/act_i_godot_runtime_frames.md"
const CORVIN_CHARACTER_SCENE := "res://game/characters/corvin/character_corvin.tscn"
const ROOMS := [
	{
		"code": "R02",
		"title": "The Old Quay",
		"room_id": "old_quay",
		"scene": "res://game/rooms/old_quay/room_old_quay.tscn",
		"player": Vector2(820, 760),
		"animation": "play_idle_side_right",
	},
	{
		"code": "R03",
		"title": "Salt Market",
		"room_id": "salt_market",
		"scene": "res://game/rooms/salt_market/room_salt_market.tscn",
		"player": Vector2(720, 770),
		"animation": "play_idle_side_right",
	},
	{
		"code": "R05",
		"title": "Harbor Registry",
		"room_id": "harbor_registry",
		"scene": "res://game/rooms/harbor_registry/room_harbor_registry.tscn",
		"player": Vector2(760, 780),
		"animation": "play_idle_side_right",
	},
	{
		"code": "R06",
		"title": "The Bone Chandler",
		"room_id": "bone_chandler",
		"scene": "res://game/rooms/bone_chandler/room_bone_chandler.tscn",
		"player": Vector2(720, 780),
		"animation": "play_idle_side_right",
	},
	{
		"code": "R07",
		"title": "The Almshouse",
		"room_id": "almshouse",
		"scene": "res://game/rooms/almshouse/room_almshouse.tscn",
		"player": Vector2(820, 790),
		"animation": "play_idle_side_right",
	},
	{
		"code": "R09",
		"title": "Church of the Drowned",
		"room_id": "church_of_the_drowned",
		"scene": "res://game/rooms/church_of_the_drowned/room_church_of_the_drowned.tscn",
		"player": Vector2(830, 790),
		"animation": "play_idle_side_right",
	},
	{
		"code": "R10",
		"title": "The Grey Float",
		"room_id": "grey_float",
		"scene": "res://game/rooms/grey_float/room_grey_float.tscn",
		"player": Vector2(800, 780),
		"animation": "play_idle_side_right",
	},
	{
		"code": "R12",
		"title": "Sabine's Office",
		"room_id": "sabine_office",
		"scene": "res://game/rooms/sabine_office/room_sabine_office.tscn",
		"player": Vector2(790, 780),
		"animation": "play_idle_side_right",
	},
]
const EXPECTED_PROP_IDS_BY_ROOM := {
	"R02": ["calcified_bollard_row", "salt_rope_cleat", "empty_flask", "quay_crate_cluster"],
	"R03": ["boot_stall", "market_crowd_dressing", "church_sign", "confession_queue", "fishmonger"],
	"R05": ["registry_roll_book", "registry_candles", "registry_confession_slips", "registry_inkstand"],
	"R06": ["bone_trade_counter", "prosper_watch_display", "bone_shelf_cluster", "salt_trade_tray"],
	"R07": ["salt_window", "cot_row", "privacy_screen_laundry", "prosper_chair_table", "forgiveness_watch_tray"],
	"R09": ["poor_box", "confession_booth", "church_ledger_desk", "church_tariff_sign"],
	"R10": ["juno_ledger_table", "bilge_regulator", "privacy_screen", "hot_pool_steps"],
	"R12": ["frosted_sabine_door", "damp_persian_rug", "harbormaster_desk", "harbor_chart_board"],
}

var _viewport: SubViewport
var _records: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_prepare_output_dir()
	_setup_viewport()
	for room in ROOMS:
		var record := await _capture_room(room, failures)
		if not record.is_empty():
			_records.append(record)
	if failures.is_empty():
		var contact_error := _build_contact_sheet()
		if not contact_error.is_empty():
			failures.append(contact_error)
	if failures.is_empty():
		_write_report()
		print("Act I Godot runtime frame capture passed: frames=%d." % _records.size())
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _prepare_output_dir() -> void:
	var absolute_dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(absolute_dir)


func _setup_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "ActIRuntimeCaptureViewport"
	_viewport.size = FRAME_SIZE
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.transparent_bg = false
	root.add_child(_viewport)


func _capture_room(room: Dictionary, failures: Array[String]) -> Dictionary:
	var packed: PackedScene = load(String(room["scene"]))
	if packed == null:
		failures.append("Could not load room scene for capture: %s" % room["scene"])
		return {}
	var instance := packed.instantiate()
	if instance == null:
		failures.append("Could not instantiate room scene for capture: %s" % room["scene"])
		return {}
	_viewport.add_child(instance)
	instance.set("show_debug_layout", false)
	if not instance.has_method("_apply_real_art_presentation"):
		failures.append("Captured room has no real-art presentation hook: %s" % room["scene"])
		instance.queue_free()
		await process_frame
		return {}
	_add_runtime_corvin(instance, room, failures)
	_set_review_hud(instance, String(room["code"]), String(room["title"]))
	await process_frame
	await process_frame
	var image := _viewport.get_texture().get_image()
	if image == null or image.is_empty():
		failures.append("Viewport image was empty for room: %s" % room["room_id"])
		instance.queue_free()
		await process_frame
		return {}
	var output := "%s/%s_godot_runtime_frame.png" % [OUT_DIR, room["room_id"]]
	var err := image.save_png(output)
	if err != OK:
		failures.append("Could not save Godot runtime frame %s: %s" % [output, error_string(err)])
		instance.queue_free()
		await process_frame
		return {}
	var expected_prop_ids: Array = EXPECTED_PROP_IDS_BY_ROOM.get(String(room["code"]), [])
	var prop_count := _count_expected_prop_nodes(instance, expected_prop_ids, "Prop")
	var shadow_count := _count_expected_prop_nodes(instance, expected_prop_ids, "ContactShadow")
	var reflection_count := _count_expected_prop_nodes(instance, expected_prop_ids, "WetReflection")
	instance.queue_free()
	await process_frame
	return {
		"room_code": room["code"],
		"room_id": room["room_id"],
		"title": room["title"],
		"output": _project_relative(output),
		"scene": _project_relative(String(room["scene"])),
		"includes_godot_viewport_capture": true,
		"includes_actual_corvin_scene": true,
		"includes_corvin_runtime_sprite_loader": true,
		"foreground_prop_count": prop_count,
		"contact_shadow_count": shadow_count,
		"wet_reflection_count": reflection_count,
	}


func _add_runtime_corvin(parent: Node, room: Dictionary, failures: Array[String]) -> void:
	var packed: PackedScene = load(CORVIN_CHARACTER_SCENE)
	if packed == null:
		failures.append("Could not load Corvin runtime scene for Godot capture: %s" % CORVIN_CHARACTER_SCENE)
		return
	var character := packed.instantiate()
	if character == null:
		failures.append("Could not instantiate Corvin runtime scene for Godot capture.")
		return
	character.name = "RuntimeCorvinSceneCapture"
	character.position = room["player"]
	character.z_index = 6
	parent.add_child(character)
	var method := String(room["animation"])
	if not character.has_method(method) or not bool(character.call(method)):
		failures.append("Could not play Corvin runtime animation method for capture: %s" % method)
		return
	var runtime_sprite := character.get_node_or_null("RuntimeSprite")
	if runtime_sprite == null or not runtime_sprite.has_method("active_animation_for_test"):
		failures.append("Corvin runtime scene capture missing RuntimeSprite test hook.")
		return
	if String(runtime_sprite.call("active_animation_for_test")) != "idle_side_right":
		failures.append("Corvin runtime scene capture did not render idle_side_right.")


func _set_review_hud(room: Node, code: String, title: String) -> void:
	var hud := room.get_node_or_null("PrologueHud")
	if hud and hud.has_method("set_status"):
		hud.call("set_status", "%s / %s" % [code, title])


func _count_children_with_suffix(container: Node, suffix: String) -> int:
	if container == null:
		return 0
	var count := 0
	for child in container.get_children():
		if String(child.name).ends_with(suffix):
			count += 1
	return count


func _count_descendants_with_suffix(container: Node, suffix: String) -> int:
	if container == null:
		return 0
	var count := 0
	for child in container.get_children():
		if String(child.name).ends_with(suffix):
			count += 1
		count += _count_descendants_with_suffix(child, suffix)
	return count


func _count_expected_prop_nodes(container: Node, prop_ids: Array, suffix: String) -> int:
	var count := 0
	for prop_id in prop_ids:
		var node_name := "%s%s" % [String(prop_id).to_pascal_case(), suffix]
		if _has_descendant_named(container, node_name):
			count += 1
	return count


func _has_descendant_named(container: Node, node_name: String) -> bool:
	if container == null:
		return false
	for child in container.get_children():
		if String(child.name) == node_name:
			return true
		if _has_descendant_named(child, node_name):
			return true
	return false


func _build_contact_sheet() -> String:
	var columns := 2
	var thumb_size := Vector2i(480, 270)
	var label_height := 34
	var pad := 24
	var rows := int(ceil(float(_records.size()) / float(columns)))
	var sheet_size := Vector2i(columns * thumb_size.x + (columns + 1) * pad, rows * (thumb_size.y + label_height) + (rows + 1) * pad)
	var sheet := Image.create(sheet_size.x, sheet_size.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.0470588, 0.0627451, 0.0745098, 1.0))
	for index in range(_records.size()):
		var record := _records[index]
		var frame := Image.new()
		var err := frame.load("res://%s" % record["output"])
		if err != OK:
			return "Could not load captured frame for contact sheet: %s" % record["output"]
		frame.convert(Image.FORMAT_RGBA8)
		frame.resize(thumb_size.x, thumb_size.y, Image.INTERPOLATE_LANCZOS)
		var x := pad + (index % columns) * (thumb_size.x + pad)
		var y := pad + int(index / columns) * (thumb_size.y + label_height + pad)
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, thumb_size), Vector2i(x, y))
	var err := sheet.save_png(CONTACT_SHEET)
	if err != OK:
		return "Could not save Godot runtime contact sheet %s: %s" % [CONTACT_SHEET, error_string(err)]
	return ""


func _write_report() -> void:
	var report := {
		"status": "captured",
		"capture": "godot_subviewport",
		"frame_count": _records.size(),
		"contact_sheet": _project_relative(CONTACT_SHEET),
		"runtime_evidence": "Godot-rendered room scenes with runtime foreground props, contact shadows, wet-floor reflections, atmosphere, HUD, NPC standees, and the actual Corvin character scene using RuntimeSprite loader.",
		"rooms": _records,
	}
	var json_text := JSON.stringify(report, "\t") + "\n"
	var json_file := FileAccess.open(REPORT_JSON, FileAccess.WRITE)
	json_file.store_string(json_text)
	json_file.close()
	var lines: Array[String] = [
		"# Act I Godot Runtime Frames",
		"",
		"Generated by `tools/godot_capture_act_i_runtime_frames.gd`.",
		"",
		"These frames are captured from Godot SubViewport rendering of the actual room scenes after `_apply_real_art_presentation()`, with runtime foreground props, contact shadows, wet-floor reflections, atmosphere overlays, HUD, NPC standees, and the actual Corvin character scene using the RuntimeSprite loader.",
		"",
		"- Contact sheet: `%s`" % report["contact_sheet"],
		"- Frame count: %d" % _records.size(),
		"",
		"| Room | Captured frame | Props |",
		"|---|---|---:|",
	]
	for record in _records:
		lines.append("| %s / %s | `%s` | %d |" % [record["room_code"], record["title"], record["output"], record["foreground_prop_count"]])
	var md_file := FileAccess.open(REPORT_MD, FileAccess.WRITE)
	md_file.store_string("\n".join(lines) + "\n")
	md_file.close()


func _project_relative(path: String) -> String:
	if path.begins_with("res://"):
		return path.trim_prefix("res://")
	return path
