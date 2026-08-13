@tool
extends PopochiuRoom

@export var room_code := ""
@export var room_title := ""
@export var room_notes := ""
@export var show_debug_layout := false

const ACT_I_STANDEE_BASE := "res://game/standees/act_i/%s.png"
const SECTIONAL_SETPIECE_PLAYER := preload("res://game/rooms/sectional_setpiece_player.gd")
const ACT_I_CHARACTER_INTEGRATION_RIM_COLOR := Color(0.788235, 0.541176, 0.235294, 0.14)
const ACT_I_CHARACTER_INTEGRATION_RIM_OFFSETS := [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1)]
const ACT_I_PROPS_BY_ROOM := {
	"R01": [
		{"id": "brine_silt", "path": "res://game/rooms/mudflats/props/brine_silt.png", "position": Vector2(846, 825), "z": 3},
		{"id": "tomas_bollard", "path": "res://game/rooms/mudflats/props/tomas_bollard.png", "position": Vector2(268, 405), "z": 3},
		{"id": "missing_boots", "path": "res://game/rooms/mudflats/props/missing_boots.png", "position": Vector2(897, 785), "z": 3},
	],
	"R02": [
		{"id": "calcified_bollard_row", "path": "res://game/rooms/old_quay/props/calcified_bollard_row.png", "position": Vector2(760, 620), "z": 3},
		{"id": "salt_rope_cleat", "path": "res://game/rooms/old_quay/props/salt_rope_cleat.png", "position": Vector2(655, 740), "z": 3},
		{"id": "empty_flask", "path": "res://game/rooms/old_quay/props/empty_flask.png", "position": Vector2(1115, 735), "z": 3},
		{"id": "quay_crate_cluster", "path": "res://game/rooms/old_quay/props/quay_crate_cluster.png", "position": Vector2(1365, 700), "z": 3},
	],
	"R03": [
		{"id": "boot_stall", "path": "res://game/rooms/salt_market/props/boot_stall.png", "position": Vector2(92, 548), "z": 3},
		{"id": "market_crowd_dressing", "path": "res://game/rooms/salt_market/props/market_crowd_dressing.png", "position": Vector2(760, 545), "z": 3},
		{"id": "church_sign", "path": "res://game/rooms/salt_market/props/church_sign.png", "position": Vector2(1295, 405), "z": 3},
		{"id": "confession_queue", "path": "res://game/rooms/salt_market/props/confession_queue.png", "position": Vector2(1165, 500), "z": 3},
		{"id": "fishmonger", "path": "res://game/rooms/salt_market/props/fishmonger.png", "position": Vector2(430, 625), "z": 3},
	],
	"R05": [
		{"id": "registry_roll_book", "path": "res://game/rooms/harbor_registry/props/registry_roll_book.png", "position": Vector2(520, 555), "z": 3},
		{"id": "registry_candles", "path": "res://game/rooms/harbor_registry/props/registry_candles.png", "position": Vector2(910, 642), "z": 3},
		{"id": "registry_confession_slips", "path": "res://game/rooms/harbor_registry/props/registry_confession_slips.png", "position": Vector2(1065, 720), "z": 3},
		{"id": "registry_inkstand", "path": "res://game/rooms/harbor_registry/props/registry_inkstand.png", "position": Vector2(790, 720), "z": 3},
	],
	"R06": [
		{"id": "bone_trade_counter", "path": "res://game/rooms/bone_chandler/props/bone_trade_counter.png", "position": Vector2(690, 545), "z": 3},
		{"id": "prosper_watch_display", "path": "res://game/rooms/bone_chandler/props/prosper_watch_display.png", "position": Vector2(1018, 612), "z": 3},
		{"id": "bone_shelf_cluster", "path": "res://game/rooms/bone_chandler/props/bone_shelf_cluster.png", "position": Vector2(1325, 500), "z": 3},
		{"id": "salt_trade_tray", "path": "res://game/rooms/bone_chandler/props/salt_trade_tray.png", "position": Vector2(650, 760), "z": 3},
	],
	"R07": [
		{"id": "salt_window", "path": "res://game/rooms/almshouse/props/salt_window.png", "position": Vector2(705, 420), "z": 3},
		{"id": "cot_row", "path": "res://game/rooms/almshouse/props/cot_row.png", "position": Vector2(350, 560), "z": 3},
		{"id": "privacy_screen_laundry", "path": "res://game/rooms/almshouse/props/privacy_screen_laundry.png", "position": Vector2(1245, 540), "z": 3},
		{"id": "prosper_chair_table", "path": "res://game/rooms/almshouse/props/prosper_chair_table.png", "position": Vector2(890, 585), "z": 3},
		{"id": "forgiveness_watch_tray", "path": "res://game/rooms/almshouse/props/forgiveness_watch_tray.png", "position": Vector2(1055, 655), "z": 3},
	],
	"R08": [
		{"id": "ice_table_body_outline", "path": "res://game/rooms/fish_hall/props/ice_table_body_outline.png", "position": Vector2(330, 565), "z": 3},
		{"id": "day_count_board", "path": "res://game/rooms/fish_hall/props/day_count_board.png", "position": Vector2(1350, 510), "z": 3},
		{"id": "coroner_tag_tray", "path": "res://game/rooms/fish_hall/props/coroner_tag_tray.png", "position": Vector2(900, 645), "z": 3},
		{"id": "visitor_book", "path": "res://game/rooms/fish_hall/props/visitor_book.png", "position": Vector2(1110, 610), "z": 3},
		{"id": "floor_drain_grate", "path": "res://game/rooms/fish_hall/props/floor_drain_grate.png", "position": Vector2(1410, 725), "z": 3},
	],
	"R09": [
		{"id": "poor_box", "path": "res://game/rooms/church_of_the_drowned/props/poor_box.png", "position": Vector2(545, 690), "z": 3},
		{"id": "confession_booth", "path": "res://game/rooms/church_of_the_drowned/props/confession_booth.png", "position": Vector2(705, 535), "z": 3},
		{"id": "church_ledger_desk", "path": "res://game/rooms/church_of_the_drowned/props/church_ledger_desk.png", "position": Vector2(875, 665), "z": 3},
		{"id": "church_tariff_sign", "path": "res://game/rooms/church_of_the_drowned/props/church_tariff_sign.png", "position": Vector2(1105, 645), "z": 3},
	],
	"R10": [
		{"id": "juno_ledger_table", "path": "res://game/rooms/grey_float/props/juno_ledger_table.png", "position": Vector2(290, 560), "z": 3},
		{"id": "bilge_regulator", "path": "res://game/rooms/grey_float/props/bilge_regulator.png", "position": Vector2(860, 465), "z": 3},
		{"id": "privacy_screen", "path": "res://game/rooms/grey_float/props/privacy_screen.png", "position": Vector2(1335, 440), "z": 3},
		{"id": "hot_pool_steps", "path": "res://game/rooms/grey_float/props/hot_pool_steps.png", "position": Vector2(1135, 665), "z": 3},
	],
	"R11": [
		{"id": "permit_board", "path": "res://game/rooms/harbormaster_office/props/permit_board.png", "position": Vector2(420, 425), "z": 3},
		{"id": "sabine_door_panel", "path": "res://game/rooms/harbormaster_office/props/sabine_door_panel.png", "position": Vector2(1340, 415), "z": 3},
		{"id": "checklist_desk", "path": "res://game/rooms/harbormaster_office/props/checklist_desk.png", "position": Vector2(540, 575), "z": 3},
		{"id": "clerk_counter", "path": "res://game/rooms/harbormaster_office/props/clerk_counter.png", "position": Vector2(880, 575), "z": 3},
		{"id": "queue_rail_sign", "path": "res://game/rooms/harbormaster_office/props/queue_rail_sign.png", "position": Vector2(1185, 690), "z": 3},
	],
	"R12": [
		{"id": "frosted_sabine_door", "path": "res://game/rooms/sabine_office/props/frosted_sabine_door.png", "position": Vector2(110, 220), "z": 3},
		{"id": "damp_persian_rug", "path": "res://game/rooms/sabine_office/props/damp_persian_rug.png", "position": Vector2(430, 760), "z": 3},
		{"id": "harbormaster_desk", "path": "res://game/rooms/sabine_office/props/harbormaster_desk.png", "position": Vector2(845, 565), "z": 3},
		{"id": "harbor_chart_board", "path": "res://game/rooms/sabine_office/props/harbor_chart_board.png", "position": Vector2(1495, 495), "z": 3},
	],
}
const ACT_I_CHARACTER_OCCLUDERS_BY_ROOM := {
	"R05": [
		{"id": "registry_roll_book", "path": "res://game/rooms/harbor_registry/props/registry_roll_book.png", "position": Vector2(520, 555), "crop_top_ratio": 0.52},
	],
	"R06": [
		{"id": "bone_trade_counter", "path": "res://game/rooms/bone_chandler/props/bone_trade_counter.png", "position": Vector2(690, 545), "crop_top_ratio": 0.42},
	],
	"R07": [
		{"id": "prosper_chair_table", "path": "res://game/rooms/almshouse/props/prosper_chair_table.png", "position": Vector2(890, 585), "crop_top_ratio": 0.48},
	],
	"R09": [
		{"id": "church_ledger_desk", "path": "res://game/rooms/church_of_the_drowned/props/church_ledger_desk.png", "position": Vector2(875, 665), "crop_top_ratio": 0.46},
	],
	"R10": [
		{"id": "juno_ledger_table", "path": "res://game/rooms/grey_float/props/juno_ledger_table.png", "position": Vector2(290, 560), "crop_top_ratio": 0.45},
		{"id": "hot_pool_steps", "path": "res://game/rooms/grey_float/props/hot_pool_steps.png", "position": Vector2(1135, 665), "crop_top_ratio": 0.58},
	],
	"R12": [
		{"id": "harbormaster_desk", "path": "res://game/rooms/sabine_office/props/harbormaster_desk.png", "position": Vector2(845, 565), "crop_top_ratio": 0.44},
		{"id": "damp_persian_rug", "path": "res://game/rooms/sabine_office/props/damp_persian_rug.png", "position": Vector2(430, 760), "crop_top_ratio": 0.64},
	],
}
const ACT_I_STANDEES_BY_ROOM := {
	"R02": [
		{"id": "tomas_bollard", "position": Vector2(400, 735), "z": 4},
	],
	"R03": [],
	"R05": [
		{"id": "registrar", "position": Vector2(1230, 705), "z": 4, "scale": 0.78},
	],
	"R06": [
		{"id": "bone_chandler", "position": Vector2(1200, 760), "z": 4, "scale": 0.78},
	],
	"R07": [
		{"id": "prosper", "position": Vector2(1190, 775), "z": 4, "scale": 0.82},
	],
	"R09": [
		{"id": "teodor", "position": Vector2(1230, 740), "z": 4, "scale": 0.78},
	],
	"R10": [
		{"id": "juno", "position": Vector2(1250, 745), "z": 4, "scale": 0.75},
	],
	"R12": [
		{"id": "sabine", "position": Vector2(1260, 735), "z": 4, "scale": 0.76},
	],
}
const ACT_I_SETPIECES_BY_ROOM := {
	"R03": [
		{
			"id": "salt_market_crowd",
			"position": Vector2(1070, 455),
			"z": 4,
			"default_state": "idle_murmur",
			"states": {
				"idle_murmur": {
					"path": "res://game/rooms/salt_market/setpieces/salt_market_crowd_idle_murmur.png",
					"frames": 8,
					"fps": 8.0,
					"width": 520,
					"height": 330,
					"loop": true,
				},
				"turn_to_corvin": {
					"path": "res://game/rooms/salt_market/setpieces/salt_market_crowd_turn_to_corvin.png",
					"frames": 10,
					"fps": 10.0,
					"width": 520,
					"height": 330,
					"loop": false,
					"return_state": "settle",
				},
				"settle": {
					"path": "res://game/rooms/salt_market/setpieces/salt_market_crowd_settle.png",
					"frames": 6,
					"fps": 10.0,
					"width": 520,
					"height": 330,
					"loop": false,
					"return_state": "idle_murmur",
				},
			},
		},
	],
}
const ACT_I_ATMOSPHERE_BY_ROOM := {
	"R02": [
		{
			"id": "old_quay_water_glint",
			"position": Vector2(0, 650),
			"z": 2,
			"default_state": "loop",
			"states": {
				"loop": {
					"path": "res://game/rooms/old_quay/atmosphere/old_quay_water_glint.png",
					"frames": 8,
					"fps": 6.0,
					"width": 1920,
					"height": 310,
					"loop": true,
				},
			},
		},
	],
	"R03": [
		{
			"id": "salt_market_lamp_flicker",
			"position": Vector2(1210, 210),
			"z": 3,
			"default_state": "loop",
			"states": {
				"loop": {
					"path": "res://game/rooms/salt_market/atmosphere/salt_market_lamp_flicker.png",
					"frames": 8,
					"fps": 7.0,
					"width": 540,
					"height": 500,
					"loop": true,
				},
			},
		},
	],
	"R05": [
		{
			"id": "harbor_registry_lamp_smoke",
			"position": Vector2(700, 300),
			"z": 3,
			"default_state": "loop",
			"states": {
				"loop": {
					"path": "res://game/rooms/harbor_registry/atmosphere/harbor_registry_lamp_smoke.png",
					"frames": 10,
					"fps": 8.0,
					"width": 520,
					"height": 430,
					"loop": true,
				},
			},
		},
	],
	"R10": [
		{
			"id": "grey_float_steam_drift",
			"position": Vector2(120, 330),
			"z": 5,
			"default_state": "loop",
			"states": {
				"loop": {
					"path": "res://game/rooms/grey_float/atmosphere/grey_float_steam_drift.png",
					"frames": 10,
					"fps": 6.0,
					"width": 1640,
					"height": 470,
					"loop": true,
				},
			},
		},
	],
	"R12": [
		{
			"id": "sabine_office_window_rain",
			"position": Vector2(900, 90),
			"z": 3,
			"default_state": "loop",
			"states": {
				"loop": {
					"path": "res://game/rooms/sabine_office/atmosphere/sabine_office_window_rain.png",
					"frames": 8,
					"fps": 6.0,
					"width": 650,
					"height": 470,
					"loop": true,
				},
			},
		},
	],
}
const ACT_I_INTERACTION_PULSES := {
	"R02": {
		"rope_cleat": {"position": Vector2(655, 740), "radius": 82.0, "color": Color(0.894118, 0.862745, 0.784314, 0.58), "effect": "rope"},
	},
	"R03": {
		"church_sign": {"position": Vector2(1380, 540), "radius": 95.0, "color": Color(0.788235, 0.541176, 0.235294, 0.62), "effect": "ink"},
	},
	"R05": {
		"desk_lamp": {"position": Vector2(890, 650), "radius": 108.0, "color": Color(0.494118, 0.607843, 0.305882, 0.60), "effect": "smoke"},
	},
	"R08": {
		"drain": {"position": Vector2(1410, 725), "radius": 96.0, "color": Color(0.894118, 0.862745, 0.784314, 0.54), "effect": "drain"},
	},
}
const ACT_I_ROOM_STATUS_LINES := {
	"R02": "The Old Quay. The water gives everything back except mercy.",
	"R03": "Salt Market. Commerce resumes once the screaming stops.",
	"R05": "Harbor Registry. The dead wait politely to be denied standing.",
	"R06": "The Bone Chandler. Everything here used to belong to someone.",
	"R07": "The Almshouse. Charity, itemized and badly lit.",
	"R08": "The Fish Hall. The cold keeps better records than the Church.",
	"R09": "Church of the Drowned. Forgiveness has office hours.",
	"R10": "The Grey Float. Warmth for rent, sensation not guaranteed.",
	"R11": "Harbormaster's Office. Process with a knife behind it.",
	"R12": "Sabine's Office. Dry carpet. Bad odds.",
}

var _hud: CanvasLayer
var _duel_panel: CanvasLayer
var _pending_duel_result: Dictionary = {}
var _hover_focus_layer: Node2D
var _hover_focus_tween: Tween

func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	_apply_real_art_presentation()
	_hud = get_node_or_null("PrologueHud")
	var narrative := _narrative()
	if narrative:
		narrative.changed.connect(_refresh_narrative_hud)
		_refresh_narrative_hud()
	for hotspot in get_tree().get_nodes_in_group("act_i_exit_hotspot"):
		if is_ancestor_of(hotspot) and hotspot is Area2D:
			_bind_hotspot_feedback(hotspot, _on_exit_hotspot_input)
	for hotspot in get_tree().get_nodes_in_group("act_i_interaction_hotspot"):
		if is_ancestor_of(hotspot) and hotspot is Area2D:
			_bind_hotspot_feedback(hotspot, _on_interaction_hotspot_input)
	_refresh_status()

func _apply_real_art_presentation() -> void:
	_set_debug_layout_visible(show_debug_layout)
	_add_act_i_props()
	_add_act_i_standees()
	_add_act_i_setpieces()
	_add_act_i_atmosphere()
	_add_act_i_character_occluders()
	_add_act_i_interaction_pulse_layer()
	_add_act_i_hover_focus_layer()

func _set_debug_layout_visible(is_visible: bool) -> void:
	for node_name in ["Floor", "WalkableAreas", "TitleLabel", "NotesLabel"]:
		var node := get_node_or_null(node_name)
		if node is CanvasItem:
			node.visible = is_visible
	var hotspots := get_node_or_null("Hotspots")
	if hotspots:
		_set_child_labels_visible(hotspots, is_visible)

func _set_child_labels_visible(parent: Node, is_visible: bool) -> void:
	for child in parent.get_children():
		if child is Label:
			child.visible = is_visible
		_set_child_labels_visible(child, is_visible)

func _add_act_i_props() -> void:
	if not ACT_I_PROPS_BY_ROOM.has(room_code):
		return
	var props := get_node_or_null("Props")
	if props == null:
		props = self
	var container := props.get_node_or_null("ActIForegroundProps")
	if container:
		container.queue_free()
	container = Node2D.new()
	container.name = "ActIForegroundProps"
	props.add_child(container)
	for prop in ACT_I_PROPS_BY_ROOM[room_code]:
		_add_act_i_prop(container, prop)

func _add_act_i_prop(container: Node, prop: Dictionary) -> void:
	var prop_id := String(prop.get("id", ""))
	var path := String(prop.get("path", ""))
	if prop_id.is_empty() or path.is_empty():
		return
	if not FileAccess.file_exists(path):
		push_warning("Missing Act I foreground prop: %s" % path)
		return
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_warning("Could not load Act I foreground prop %s: %s" % [path, error_string(err)])
		return
	var texture := ImageTexture.create_from_image(image)
	var position: Vector2 = prop.get("position", Vector2.ZERO)
	var z := int(prop.get("z", 3))

	var shadow := _make_act_i_prop_shadow(prop_id, image)
	shadow.position = Vector2(position.x + float(image.get_width()) * 0.5, position.y + float(image.get_height()) * 0.90)
	shadow.z_index = z - 1
	container.add_child(shadow)

	var reflection := Sprite2D.new()
	reflection.name = "%sWetReflection" % prop_id.to_pascal_case()
	reflection.texture = texture
	reflection.centered = false
	reflection.flip_v = true
	reflection.position = Vector2(position.x, position.y + float(image.get_height()) * 0.90)
	reflection.scale = Vector2(1.0, 0.28)
	reflection.modulate = Color(0.43, 0.48, 0.46, 0.13)
	reflection.z_index = z - 1
	container.add_child(reflection)

	var sprite := Sprite2D.new()
	sprite.name = "%sProp" % prop_id.to_pascal_case()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = position
	sprite.z_index = z
	container.add_child(sprite)

func _make_act_i_prop_shadow(prop_id: String, image: Image) -> Polygon2D:
	var shadow := Polygon2D.new()
	shadow.name = "%sContactShadow" % prop_id.to_pascal_case()
	var width := clampf(float(image.get_width()) * 0.32, 32.0, 170.0)
	var height := clampf(float(image.get_height()) * 0.045, 8.0, 32.0)
	shadow.polygon = PackedVector2Array([
		Vector2(-width, 0.0),
		Vector2(-width * 0.58, -height),
		Vector2(width * 0.58, -height),
		Vector2(width, 0.0),
		Vector2(width * 0.58, height),
		Vector2(-width * 0.58, height)
	])
	shadow.color = Color(0.0470588, 0.0627451, 0.0745098, 0.36)
	return shadow

func _add_act_i_standees() -> void:
	if not ACT_I_STANDEES_BY_ROOM.has(room_code):
		return
	var props := get_node_or_null("Props")
	if props == null:
		props = self
	var container := props.get_node_or_null("ActIStandees")
	if container:
		container.queue_free()
	container = Node2D.new()
	container.name = "ActIStandees"
	props.add_child(container)
	for standee in ACT_I_STANDEES_BY_ROOM[room_code]:
		_add_act_i_standee(container, standee)

func _add_act_i_standee(container: Node, standee: Dictionary) -> void:
	var standee_id := String(standee.get("id", ""))
	if standee_id.is_empty():
		return
	var path := ACT_I_STANDEE_BASE % standee_id
	if not FileAccess.file_exists(path):
		push_warning("Missing Act I standee: %s" % path)
		return
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_warning("Could not load Act I standee %s: %s" % [path, error_string(err)])
		return
	var visual_scale := float(standee.get("scale", 1.0))
	var foot_position: Vector2 = standee.get("position", Vector2.ZERO)
	var shadow := _make_act_i_standee_shadow(standee_id, image, visual_scale)
	shadow.position = foot_position
	shadow.z_index = int(standee.get("z", 0)) - 1
	container.add_child(shadow)
	var reflection := _make_act_i_standee_reflection(standee_id, image, visual_scale)
	reflection.position = Vector2(
		foot_position.x - (float(image.get_width()) * visual_scale * 0.44),
		foot_position.y + 5.0
	)
	reflection.z_index = int(standee.get("z", 0)) - 1
	container.add_child(reflection)
	for rim_offset in ACT_I_CHARACTER_INTEGRATION_RIM_OFFSETS:
		var rim := _make_act_i_standee_integration_rim(standee_id, image, visual_scale, rim_offset)
		rim.position = Vector2(
			foot_position.x - (float(image.get_width()) * visual_scale) / 2.0,
			foot_position.y - float(image.get_height()) * visual_scale
		) + rim_offset
		rim.z_index = int(standee.get("z", 0)) - 1
		container.add_child(rim)
	var sprite := Sprite2D.new()
	sprite.name = "%sStandee" % standee_id.to_pascal_case()
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = false
	sprite.scale = Vector2(visual_scale, visual_scale)
	sprite.position = Vector2(
		foot_position.x - (float(image.get_width()) * visual_scale) / 2.0,
		foot_position.y - float(image.get_height()) * visual_scale
	)
	sprite.z_index = int(standee.get("z", 0))
	container.add_child(sprite)

func _make_act_i_standee_shadow(standee_id: String, image: Image, visual_scale: float) -> Polygon2D:
	var shadow := Polygon2D.new()
	shadow.name = "%sContactShadow" % standee_id.to_pascal_case()
	var width := clampf(float(image.get_width()) * visual_scale * 0.34, 42.0, 128.0)
	var height := clampf(float(image.get_height()) * visual_scale * 0.045, 10.0, 28.0)
	shadow.polygon = PackedVector2Array([
		Vector2(-width, 0.0),
		Vector2(-width * 0.58, -height),
		Vector2(width * 0.58, -height),
		Vector2(width, 0.0),
		Vector2(width * 0.58, height),
		Vector2(-width * 0.58, height)
	])
	shadow.color = Color(0.0470588, 0.0627451, 0.0745098, 0.52)
	return shadow

func _make_act_i_standee_reflection(standee_id: String, image: Image, visual_scale: float) -> Sprite2D:
	var reflection := Sprite2D.new()
	reflection.name = "%sWetFloorReflection" % standee_id.to_pascal_case()
	var reflection_image := image.duplicate()
	reflection_image.flip_y()
	reflection.texture = ImageTexture.create_from_image(reflection_image)
	reflection.centered = false
	reflection.scale = Vector2(visual_scale * 0.88, visual_scale * 0.18)
	reflection.modulate = Color(0.164706, 0.227451, 0.25098, 0.18)
	return reflection

func _make_act_i_standee_integration_rim(standee_id: String, image: Image, visual_scale: float, offset: Vector2) -> Sprite2D:
	var rim := Sprite2D.new()
	rim.name = "%sCharacterIntegrationRim" % standee_id.to_pascal_case()
	var rim_image := Image.create(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	rim_image.fill(Color.TRANSPARENT)
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.08:
				rim_image.set_pixel(x, y, ACT_I_CHARACTER_INTEGRATION_RIM_COLOR)
	rim.texture = ImageTexture.create_from_image(rim_image)
	rim.centered = false
	rim.scale = Vector2(visual_scale, visual_scale)
	rim.modulate = Color(1, 1, 1, 0.68 if offset.y < 0.0 else 0.52)
	return rim

func _add_act_i_character_occluders() -> void:
	if not ACT_I_CHARACTER_OCCLUDERS_BY_ROOM.has(room_code):
		return
	var props := get_node_or_null("Props")
	if props == null:
		props = self
	var container := props.get_node_or_null("ActICharacterOccluders")
	if container:
		container.queue_free()
	container = Node2D.new()
	container.name = "ActICharacterOccluders"
	container.z_index = 8
	props.add_child(container)
	for occluder in ACT_I_CHARACTER_OCCLUDERS_BY_ROOM[room_code]:
		_add_act_i_character_occluder(container, occluder)

func _add_act_i_character_occluder(container: Node, occluder: Dictionary) -> void:
	var occluder_id := String(occluder.get("id", ""))
	var path := String(occluder.get("path", ""))
	if occluder_id.is_empty() or path.is_empty():
		return
	if not FileAccess.file_exists(path):
		push_warning("Missing Act I character occluder: %s" % path)
		return
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_warning("Could not load Act I character occluder %s: %s" % [path, error_string(err)])
		return
	var texture := ImageTexture.create_from_image(image)
	var crop_top_ratio := clampf(float(occluder.get("crop_top_ratio", 0.5)), 0.1, 0.9)
	var crop_y := int(round(float(image.get_height()) * crop_top_ratio))
	var sprite := Sprite2D.new()
	sprite.name = "%sCharacterOccluder" % occluder_id.to_pascal_case()
	sprite.texture = texture
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, crop_y, image.get_width(), image.get_height() - crop_y)
	var position: Vector2 = occluder.get("position", Vector2.ZERO)
	sprite.position = position + Vector2(0, crop_y)
	sprite.z_index = int(occluder.get("z", 8))
	container.add_child(sprite)

func _add_act_i_setpieces() -> void:
	if not ACT_I_SETPIECES_BY_ROOM.has(room_code):
		return
	var props := get_node_or_null("Props")
	if props == null:
		props = self
	var container := props.get_node_or_null("ActISetpieces")
	if container:
		container.queue_free()
	container = Node2D.new()
	container.name = "ActISetpieces"
	props.add_child(container)
	for setpiece in ACT_I_SETPIECES_BY_ROOM[room_code]:
		_add_act_i_setpiece(container, setpiece)

func _add_act_i_atmosphere() -> void:
	if not ACT_I_ATMOSPHERE_BY_ROOM.has(room_code):
		return
	var props := get_node_or_null("Props")
	if props == null:
		props = self
	var container := props.get_node_or_null("ActIAtmosphere")
	if container:
		container.queue_free()
	container = Node2D.new()
	container.name = "ActIAtmosphere"
	props.add_child(container)
	for setpiece in ACT_I_ATMOSPHERE_BY_ROOM[room_code]:
		_add_act_i_setpiece(container, setpiece)

func _add_act_i_setpiece(container: Node, setpiece: Dictionary) -> void:
	var setpiece_id := String(setpiece.get("id", ""))
	if setpiece_id.is_empty():
		return
	var player := Sprite2D.new()
	player.set_script(SECTIONAL_SETPIECE_PLAYER)
	player.name = "%sSetpiece" % setpiece_id.to_pascal_case()
	player.position = setpiece.get("position", Vector2.ZERO)
	player.z_index = int(setpiece.get("z", 0))
	container.add_child(player)
	player.call("configure", setpiece.get("states", {}), String(setpiece.get("default_state", "")))

func _add_act_i_interaction_pulse_layer() -> void:
	var props := get_node_or_null("Props")
	if props == null:
		props = self
	var existing := props.get_node_or_null("ActIInteractionPulses")
	if existing:
		existing.queue_free()
	var container := Node2D.new()
	container.name = "ActIInteractionPulses"
	container.z_index = 9
	container.visible = false
	props.add_child(container)

func _add_act_i_hover_focus_layer() -> void:
	var props := get_node_or_null("Props")
	if props == null:
		props = self
	var existing := props.get_node_or_null("ActIHoverFocus")
	if existing:
		existing.queue_free()
	_hover_focus_layer = Node2D.new()
	_hover_focus_layer.name = "ActIHoverFocus"
	_hover_focus_layer.z_index = 12
	_hover_focus_layer.visible = false
	props.add_child(_hover_focus_layer)

func _play_act_i_interaction_pulse(interaction_key: String) -> bool:
	if not ACT_I_INTERACTION_PULSES.has(room_code):
		return false
	var room_pulses: Dictionary = ACT_I_INTERACTION_PULSES[room_code]
	if not room_pulses.has(interaction_key):
		return false
	var props := get_node_or_null("Props")
	if props == null:
		return false
	var container := props.get_node_or_null("ActIInteractionPulses")
	if container == null:
		_add_act_i_interaction_pulse_layer()
		container = props.get_node_or_null("ActIInteractionPulses")
	if container == null:
		return false
	for child in container.get_children():
		child.queue_free()
	var config: Dictionary = room_pulses[interaction_key]
	var effect := String(config.get("effect", "ripple"))
	var position: Vector2 = config.get("position", Vector2.ZERO)
	var radius := float(config.get("radius", 90.0))
	var color: Color = config.get("color", Color(0.894118, 0.862745, 0.784314, 0.55))
	var pulse := Polygon2D.new()
	pulse.name = "%sWetPulse" % interaction_key.to_pascal_case()
	pulse.position = position
	pulse.color = color
	pulse.polygon = _make_act_i_pulse_polygon(radius)
	pulse.z_index = 9
	container.add_child(pulse)
	_add_act_i_wet_effect_marks(container, interaction_key, effect, position, radius, color)
	container.visible = true
	var tween := create_tween()
	tween.tween_property(pulse, "scale", Vector2(1.22, 0.72), 0.22)
	tween.parallel().tween_property(pulse, "modulate:a", 0.0, 0.55)
	for child in container.get_children():
		if child != pulse and child is CanvasItem:
			tween.parallel().tween_property(child, "modulate:a", 0.0, 0.55)
	tween.tween_callback(container.hide)
	return true

func _add_act_i_wet_effect_marks(container: Node2D, interaction_key: String, effect: String, position: Vector2, radius: float, color: Color) -> void:
	match effect:
		"rope":
			for index in 3:
				var streak := Line2D.new()
				streak.name = "%sRopeWetStreak%d" % [interaction_key.to_pascal_case(), index + 1]
				streak.width = 5.0 - float(index)
				streak.default_color = Color(0.894118, 0.862745, 0.784314, 0.52 - float(index) * 0.08)
				streak.z_index = 10
				var offset := Vector2(-36.0 + float(index) * 32.0, -18.0 + float(index) * 11.0)
				streak.points = PackedVector2Array([position + offset, position + offset + Vector2(34.0, 9.0)])
				container.add_child(streak)
		"ink":
			for index in 4:
				var run := Line2D.new()
				run.name = "%sInkRun%d" % [interaction_key.to_pascal_case(), index + 1]
				run.width = 4.0
				run.default_color = Color(0.788235, 0.541176, 0.235294, 0.62)
				run.z_index = 10
				var top := position + Vector2(-40.0 + float(index) * 26.0, -38.0)
				run.points = PackedVector2Array([top, top + Vector2(-5.0 + float(index % 2) * 8.0, 62.0 + float(index) * 9.0)])
				container.add_child(run)
		"smoke":
			for index in 3:
				var puff := Polygon2D.new()
				puff.name = "%sSmokePuff%d" % [interaction_key.to_pascal_case(), index + 1]
				puff.position = position + Vector2(-30.0 + float(index) * 32.0, -28.0 - float(index) * 20.0)
				puff.color = Color(0.494118, 0.607843, 0.305882, 0.34 - float(index) * 0.05)
				puff.polygon = _make_act_i_pulse_polygon(max(18.0, radius * (0.24 - float(index) * 0.025)))
				puff.z_index = 10
				container.add_child(puff)
		"drain":
			for index in 4:
				var flow := Line2D.new()
				flow.name = "%sDrainFlow%d" % [interaction_key.to_pascal_case(), index + 1]
				flow.width = 3.0
				flow.default_color = Color(0.894118, 0.862745, 0.784314, 0.44)
				flow.z_index = 10
				var start := position + Vector2(-90.0 + float(index) * 38.0, -18.0 + float(index % 2) * 16.0)
				flow.points = PackedVector2Array([start, position + Vector2(-12.0 + float(index) * 6.0, 4.0)])
				container.add_child(flow)
		_:
			var shine := Polygon2D.new()
			shine.name = "%sWetShine" % interaction_key.to_pascal_case()
			shine.position = position
			shine.color = color
			shine.polygon = _make_act_i_pulse_polygon(radius * 0.42)
			shine.z_index = 10
			container.add_child(shine)

func _make_act_i_pulse_polygon(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 16:
		var angle := (TAU * float(index)) / 16.0
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius * 0.38))
	return points

func _play_act_i_setpiece(setpiece_id: String, state_name: String) -> bool:
	var props := get_node_or_null("Props/ActISetpieces")
	if props == null:
		return false
	var node_name := "%sSetpiece" % setpiece_id.to_pascal_case()
	var player := props.get_node_or_null(node_name)
	if player == null or not player.has_method("play_state"):
		return false
	return bool(player.call("play_state", state_name, true))

func _bind_hotspot_feedback(hotspot: Area2D, input_handler: Callable) -> void:
	var input_callable := input_handler.bind(hotspot)
	var entered_callable := _on_hotspot_mouse_entered.bind(hotspot)
	if not hotspot.input_event.is_connected(input_callable):
		hotspot.input_event.connect(input_callable)
	if not hotspot.mouse_entered.is_connected(entered_callable):
		hotspot.mouse_entered.connect(entered_callable)
	if not hotspot.mouse_exited.is_connected(_on_hotspot_mouse_exited):
		hotspot.mouse_exited.connect(_on_hotspot_mouse_exited)

func _on_hotspot_mouse_entered(hotspot: Area2D) -> void:
	var verb := "look"
	if _hud and "selected_verb" in _hud:
		verb = _hud.selected_verb
	_show_hover_focus(hotspot)
	_say("%s: %s" % [verb.capitalize(), _hover_label(hotspot)])

func _on_hotspot_mouse_exited() -> void:
	_hide_hover_focus()
	_refresh_status()

func _show_hover_focus(hotspot: Area2D) -> void:
	if hotspot == null:
		return
	if _hover_focus_layer == null or not is_instance_valid(_hover_focus_layer):
		_add_act_i_hover_focus_layer()
	if _hover_focus_layer == null:
		return
	if _hover_focus_tween:
		_hover_focus_tween.kill()
	for child in _hover_focus_layer.get_children():
		child.queue_free()
	var is_exit := hotspot.is_in_group("act_i_exit_hotspot")
	var radius := 42.0 if is_exit else 28.0
	var focus := Polygon2D.new()
	focus.name = "HoverFocusRing"
	focus.position = hotspot.position
	focus.color = Color(0.788235, 0.541176, 0.235294, 0.36 if is_exit else 0.48)
	focus.polygon = _make_hover_focus_polygon(radius)
	_hover_focus_layer.add_child(focus)
	var glint := Line2D.new()
	glint.name = "HoverFocusGlint"
	glint.position = hotspot.position
	glint.points = PackedVector2Array([Vector2(-radius * 0.42, 0.0), Vector2(radius * 0.42, 0.0)])
	glint.width = 2.0
	glint.default_color = Color(0.894118, 0.862745, 0.784314, 0.70)
	_hover_focus_layer.add_child(glint)
	_hover_focus_layer.visible = true
	_hover_focus_tween = create_tween()
	_hover_focus_tween.set_loops()
	_hover_focus_tween.tween_property(focus, "scale", Vector2(1.12, 0.82), 0.42)
	_hover_focus_tween.parallel().tween_property(focus, "modulate:a", 0.38, 0.42)
	_hover_focus_tween.tween_property(focus, "scale", Vector2(1.0, 1.0), 0.42)
	_hover_focus_tween.parallel().tween_property(focus, "modulate:a", 0.78, 0.42)

func _hide_hover_focus() -> void:
	if _hover_focus_tween:
		_hover_focus_tween.kill()
		_hover_focus_tween = null
	if _hover_focus_layer:
		_hover_focus_layer.visible = false
		for child in _hover_focus_layer.get_children():
			child.queue_free()

func _make_hover_focus_polygon(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 20:
		var angle := (TAU * float(index)) / 20.0
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius * 0.34))
	return points

func _on_exit_hotspot_input(_viewport: Node, event: InputEvent, _shape_idx: int, hotspot: Area2D) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	var verb := "look"
	if _hud:
		verb = _hud.selected_verb

	_play_corvin_verb_action(verb)
	if hotspot.has_method("handle_room_verb"):
		var result: Dictionary = hotspot.handle_room_verb(verb)
		_apply_interaction_result(result)

func _on_interaction_hotspot_input(_viewport: Node, event: InputEvent, _shape_idx: int, hotspot: Area2D) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	var verb := "look"
	if _hud:
		verb = _hud.selected_verb

	_play_corvin_verb_action(verb)
	if hotspot.has_method("handle_room_verb"):
		var result: Dictionary = hotspot.handle_room_verb(verb)
		_apply_interaction_result(result)

func _on_room_transition_finished() -> void:
	if Engine.is_editor_hint():
		return
	_play_corvin_runtime_animation("idle_current_side")
	_refresh_status()

func _refresh_status() -> void:
	if room_code.is_empty() and room_title.is_empty():
		return
	if ACT_I_ROOM_STATUS_LINES.has(room_code):
		_say(String(ACT_I_ROOM_STATUS_LINES[room_code]))
	elif not room_title.is_empty():
		_say(room_title)

func _say(message: String) -> void:
	if message.is_empty():
		return
	if _hud and _hud.has_method("set_status"):
		_hud.set_status(message)
	else:
		print(message)

func _hover_label(hotspot: Area2D) -> String:
	if hotspot.has_method("get_hover_label"):
		return String(hotspot.call("get_hover_label"))
	return _format_node_label(hotspot.name)

func _apply_interaction_result(result: Dictionary) -> void:
	var narrative := _narrative()
	var interaction_key := String(result.get("interaction_key", ""))
	var verb := String(result.get("verb", ""))
	if room_code == "R03" and interaction_key == "market_crowd" and (verb == "talk" or verb == "use"):
		_play_act_i_setpiece("salt_market_crowd", "turn_to_corvin")
	if verb == "wet":
		_play_act_i_interaction_pulse(interaction_key)
	if narrative:
		result = _resolve_alternate_result(result, narrative)
		for required_flag in result.get("requires_flags", []):
			if not narrative.has_act_i_flag(String(required_flag)):
				_play_ink_knot(String(result.get("blocked_ink_knot", "")))
				_say(String(result.get("blocked_text", "That is not ready yet.")))
				return
		for required_item in result.get("requires_items", []):
			if not narrative.has_item(String(required_item)):
				_play_ink_knot(String(result.get("blocked_ink_knot", "")))
				_say(String(result.get("blocked_text", "Corvin is missing the right bad idea.")))
				return
		var duel_opponent := String(result.get("duel_opponent", ""))
		if not duel_opponent.is_empty():
			_start_duel(duel_opponent, result)
			return
		_play_ink_knot(_resolve_ink_knot(result, narrative))
		for item_id in result.get("items_add", []):
			narrative.add_item(String(item_id))
		for flag_id in result.get("flags_set", []):
			if narrative.has_method("apply_act_i_flag_reward"):
				narrative.apply_act_i_flag_reward(String(flag_id))
			else:
				narrative.set_act_i_flag(String(flag_id), true)
		for confession_id in result.get("confessions_discover", []):
			narrative.discover_confession(String(confession_id))
		for confession_id in result.get("confessions_spend", []):
			narrative.spend_confession(String(confession_id))

	_say(String(result.get("message", "")))
	var target := String(result.get("target_room", ""))
	if not target.is_empty():
		var transition_animation := String(result.get("transition_animation", "walk_side_right"))
		if transition_animation.is_empty():
			transition_animation = "walk_side_right"
		_play_corvin_runtime_animation(transition_animation)
		if narrative and narrative.has_method("consume_float_warmth_room_step"):
			narrative.consume_float_warmth_room_step()
		R.goto_room(target, false, true)
	_refresh_narrative_hud()

func _play_corvin_runtime_animation(animation_name: String) -> bool:
	var characters := get_node_or_null("/root/C")
	if characters == null:
		return false
	var corvin: Node = characters.get("Corvin")
	if corvin == null or not corvin.has_method("play_runtime_animation"):
		return false
	return bool(corvin.call("play_runtime_animation", animation_name))

func _play_corvin_verb_action(verb: String) -> bool:
	match verb:
		"talk":
			return _play_corvin_runtime_animation("talk_current_side")
		"use":
			return _play_corvin_runtime_animation("use_current_side")
		"wet":
			return _play_corvin_runtime_animation("wet_current_side")
		_:
			return false

func _start_duel(opponent_id: String, result: Dictionary) -> void:
	var narrative := _narrative()
	if not narrative:
		_say("The Litany is unavailable.")
		return
	if _duel_panel and is_instance_valid(_duel_panel):
		_duel_panel.queue_free()
	var DuelPanel := load("res://game/ui/duel_panel.gd")
	_duel_panel = DuelPanel.new()
	add_child(_duel_panel)
	_pending_duel_result = result.duplicate(true)
	_duel_panel.duel_won.connect(_on_duel_won)
	_duel_panel.duel_lost.connect(_on_duel_lost)
	_duel_panel.start_duel(opponent_id, narrative, result.get("duel_pool", []))
	_play_ink_knot("%s_duel_start" % opponent_id)
	_say("The Registrar opens the Litany.")

func _on_duel_won(_opponent_id: String) -> void:
	var result := _pending_duel_result.duplicate(true)
	result["duel_opponent"] = ""
	result["duel_pool"] = []
	_pending_duel_result.clear()
	_play_ink_knot("%s_duel_win" % _opponent_id)
	_apply_interaction_result(result)

func _on_duel_lost(_opponent_id: String) -> void:
	_pending_duel_result.clear()
	_play_ink_knot("%s_duel_loss" % _opponent_id)
	_say("The Registrar closes the book. Salt wins the room.")

func _play_ink_knot(knot_name: String) -> void:
	var bridge := get_node_or_null("/root/InkBridge")
	if bridge and bridge.has_method("play_knot"):
		var lines: Array[Dictionary] = bridge.play_knot(knot_name)
		if _hud and _hud.has_method("set_dialogue_lines"):
			_hud.set_dialogue_lines(lines)

func _resolve_ink_knot(result: Dictionary, narrative: Node) -> String:
	var knot_name := String(result.get("ink_knot", ""))
	if knot_name == "juno_hot_pool_soak" and narrative and narrative.has_act_i_flag("FL_float_warmth_expired"):
		return "juno_warmth_expired"
	return knot_name

func _resolve_alternate_result(result: Dictionary, narrative: Node) -> Dictionary:
	var alternate_flags: Array = result.get("alternate_requires_flags", [])
	if alternate_flags.is_empty():
		return result
	for flag_id in alternate_flags:
		if not narrative.has_act_i_flag(String(flag_id)):
			return result
	var resolved := result.duplicate(true)
	var alternate_message_text := String(resolved.get("alternate_message", ""))
	if not alternate_message_text.is_empty():
		resolved["message"] = alternate_message_text
	var alternate_knot := String(resolved.get("alternate_ink_knot", ""))
	if not alternate_knot.is_empty():
		resolved["ink_knot"] = alternate_knot
	var alternate_flags_set: Array = resolved.get("alternate_flags_set", [])
	if not alternate_flags_set.is_empty():
		resolved["flags_set"] = alternate_flags_set
		resolved["items_add"] = []
		resolved["confessions_discover"] = []
		resolved["confessions_spend"] = []
	return resolved

func _refresh_narrative_hud() -> void:
	var narrative := _narrative()
	if not narrative or not _hud:
		return
	if _hud.has_method("set_journal_entries"):
		_hud.set_journal_entries(narrative.get_journal_entries())
	if _hud.has_method("set_objective_summary") and narrative.has_method("get_act_i_objective_summary"):
		_hud.set_objective_summary(narrative.get_act_i_objective_summary())
	if _hud.has_method("set_confession_summary"):
		_hud.set_confession_summary(narrative.get_confession_summary())
	if _hud.has_method("set_inventory_items"):
		_hud.set_inventory_items(narrative.acquired_items)

func _narrative() -> Node:
	return get_node_or_null("/root/N")

func _format_node_label(value: String) -> String:
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
		return "Hotspot"
	return normalized.capitalize()
