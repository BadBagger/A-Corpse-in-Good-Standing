extends CanvasLayer

signal verb_changed(verb: String)

const VERBS := ["walk", "look", "use", "talk", "wet"]
const HUD_SKIN_BASE := "res://game/ui/skins/act_i/%s.png"
const PORTRAIT_BASE := "res://game/portraits/act_i/%s.png"
const PALETTE := {
	"bone": Color("#E4DCC8"),
	"wet_black": Color("#0C1013"),
	"harbor_slate": Color("#2A3A40"),
	"absinthe": Color("#7D9B4E"),
	"amber": Color("#C98A3C"),
}
const VERB_ICONS := {
	"walk": ">>",
	"look": "O",
	"use": "+",
	"talk": "\"",
	"wet": "~",
}
const SPEAKER_PORTRAITS := {
	"corvin": "corvin_neutral",
	"tomas": "tomas_wry",
	"bollard-of-tomas": "tomas_wry",
	"registrar": "registrar_bored",
	"prosper": "prosper_forgetful_kind",
	"half-coin prosper": "prosper_forgetful_kind",
	"juno": "juno_warm_danger",
	"sabine": "sabine_controlled",
}

var selected_verb := "look"
var inventory_items: Array[String] = []
var _speaker_portrait: TextureRect
var _speaker_plate: TextureRect

@onready var _verb_buttons := {
	"walk": %WalkButton,
	"look": %LookButton,
	"use": %UseButton,
	"talk": %TalkButton,
	"wet": %WetButton,
}
@onready var _status: Label = %Status
@onready var _objective: Label = %Objective
@onready var _inventory: Label = %Inventory
@onready var _journal: Label = %Journal
@onready var _litany: Label = %Litany
@onready var _dialogue: Label = %Dialogue

func _ready() -> void:
	_apply_noir_skin()
	for verb in VERBS:
		_verb_buttons[verb].pressed.connect(set_selected_verb.bind(verb))
	set_selected_verb(selected_verb)
	set_status("Choose a verb, then test Mordida's patience.")
	set_objective_summary("Objective: Reach the Salt Market and find out who recognizes Corvin.")
	_refresh_inventory()
	set_journal_entries([])
	set_confession_summary("Litany: 0 known, 0 spent, 0 locked")
	set_dialogue_lines([])

func set_selected_verb(verb: String) -> void:
	if verb not in VERBS:
		return
	selected_verb = verb
	for key in _verb_buttons:
		_verb_buttons[key].button_pressed = key == verb
	set_status("Verb: %s" % verb.capitalize())
	verb_changed.emit(verb)

func add_inventory_item(item_name: String) -> void:
	if item_name in inventory_items:
		return
	inventory_items.append(item_name)
	_refresh_inventory()

func set_inventory_items(items: Array[String]) -> void:
	inventory_items.assign(items)
	_refresh_inventory()

func has_inventory_item(item_name: String) -> bool:
	return item_name in inventory_items

func set_status(message: String) -> void:
	_status.text = message

func set_objective_summary(summary: String) -> void:
	_objective.text = summary

func set_journal_entries(entries: Array[Dictionary]) -> void:
	if entries.is_empty():
		_journal.text = "Journal: empty"
		return
	var lines: Array[String] = ["Journal:"]
	for entry in entries:
		var mark := "~" if entry.get("degraded", false) else "-"
		lines.append("%s %s: %s" % [mark, entry.get("title", "Untitled"), entry.get("text", "")])
	_journal.text = "\n".join(lines)

func set_confession_summary(summary: String) -> void:
	_litany.text = summary

func set_dialogue_lines(lines: Array[Dictionary]) -> void:
	if lines.is_empty():
		_dialogue.text = "Dialogue: idle"
		_set_speaker_portrait("")
		return
	var rendered: Array[String] = []
	var active_speaker := ""
	for line in lines:
		var speaker := String(line.get("speaker", "")).capitalize()
		var text := String(line.get("text", ""))
		if active_speaker.is_empty() and not speaker.is_empty():
			active_speaker = speaker
		rendered.append("%s: %s" % [speaker, text] if not speaker.is_empty() else text)
	_dialogue.text = "\n".join(rendered)
	_set_speaker_portrait(active_speaker)

func _refresh_inventory() -> void:
	_inventory.text = "Inventory: " + (", ".join(inventory_items) if not inventory_items.is_empty() else "empty")

func _apply_noir_skin() -> void:
	_add_texture_backdrop(%Status, "status_strip.png", Vector2(8, 30), Vector2(0.325, 0.50), -1, Rect2i(0, 0, 430, 112))
	_add_texture_backdrop(%Dialogue, "dialogue_panel.png", Vector2(-122, -18), Vector2(1.15, 0.56), -1)
	_add_dialogue_portrait_frame(%Dialogue)
	_add_texture_backdrop(%Inventory, "bottom_inventory_panel.png", Vector2(-14, -86), Vector2(0.63, 0.34), -1)
	_add_texture_backdrop(%Litany, "small_icon_frame.png", Vector2(-74, -30), Vector2(0.34, 0.34), -1)
	_style_panel(%WalkButton.get_parent().get_parent().get_parent(), Color(PALETTE.wet_black, 0.62))
	_style_panel(%Inventory.get_parent().get_parent(), Color(PALETTE.wet_black, 0.58))
	_style_panel(%Status.get_parent().get_parent(), Color(PALETTE.wet_black, 0.36))
	_style_panel(%Objective.get_parent().get_parent(), Color(PALETTE.wet_black, 0.48))
	_style_panel(%Dialogue.get_parent().get_parent(), Color(PALETTE.wet_black, 0.42))
	_style_panel(%Journal.get_parent().get_parent(), Color(PALETTE.wet_black, 0.50))
	_style_panel(%Litany.get_parent().get_parent(), Color(PALETTE.wet_black, 0.48))
	for verb in VERBS:
		_style_verb_button(_verb_buttons[verb], verb)
		_add_button_texture_backdrop(_verb_buttons[verb], "verb_button_plate.png")
	for label in [_status, _objective, _inventory, _journal, _litany, _dialogue]:
		_style_label(label)

func _add_texture_backdrop(anchor: Control, file_name: String, offset: Vector2, scale: Vector2, z: int, source_rect: Rect2i = Rect2i()) -> void:
	var texture := _load_hud_texture(file_name)
	if texture == null:
		return
	var parent := anchor.get_parent()
	if parent == null:
		return
	var rect := TextureRect.new()
	rect.name = file_name.get_basename().to_pascal_case()
	rect.texture = texture
	if source_rect.size.x > 0 and source_rect.size.y > 0:
		rect.region_enabled = true
		rect.region_rect = source_rect
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = z
	rect.position = offset
	rect.custom_minimum_size = Vector2(texture.get_width() * scale.x, texture.get_height() * scale.y)
	rect.size = rect.custom_minimum_size
	parent.add_child(rect)
	parent.move_child(rect, 0)

func _add_dialogue_portrait_frame(anchor: Control) -> void:
	var parent := anchor.get_parent()
	if parent == null:
		return
	_speaker_plate = TextureRect.new()
	_speaker_plate.name = "DialogueSpeakerPortraitPlate"
	_speaker_plate.texture = _load_hud_texture("small_icon_frame.png")
	_speaker_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_speaker_plate.stretch_mode = TextureRect.STRETCH_SCALE
	_speaker_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker_plate.z_index = 1
	_speaker_plate.position = Vector2(-104, -36)
	_speaker_plate.size = Vector2(96, 96)
	parent.add_child(_speaker_plate)
	_speaker_portrait = TextureRect.new()
	_speaker_portrait.name = "DialogueSpeakerPortrait"
	_speaker_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_speaker_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_speaker_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker_portrait.z_index = 2
	_speaker_portrait.position = Vector2(-93, -25)
	_speaker_portrait.size = Vector2(74, 74)
	parent.add_child(_speaker_portrait)
	_set_speaker_portrait("")

func _style_panel(node: Node, color: Color) -> void:
	if not node is PanelContainer:
		return
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = Color(PALETTE.amber, 0.48)
	box.set_border_width_all(1)
	box.corner_radius_top_left = 2
	box.corner_radius_top_right = 2
	box.corner_radius_bottom_left = 2
	box.corner_radius_bottom_right = 2
	node.add_theme_stylebox_override("panel", box)

func _style_verb_button(button: Button, verb: String) -> void:
	button.text = "%s  %s" % [VERB_ICONS.get(verb, "?"), verb.to_upper()]
	button.custom_minimum_size = Vector2(124, 36)
	button.add_theme_color_override("font_color", PALETTE.bone)
	button.add_theme_color_override("font_pressed_color", PALETTE.wet_black)
	button.add_theme_color_override("font_hover_color", PALETTE.amber)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_stylebox_override("normal", _button_style(Color(PALETTE.harbor_slate, 0.82), Color(PALETTE.amber, 0.45)))
	button.add_theme_stylebox_override("hover", _button_style(Color(PALETTE.harbor_slate, 0.95), Color(PALETTE.amber, 0.85)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(PALETTE.amber, 0.90), Color(PALETTE.bone, 0.9)))
	button.add_theme_stylebox_override("focus", _button_style(Color(PALETTE.harbor_slate, 0.95), Color(PALETTE.bone, 0.95)))

func _add_button_texture_backdrop(button: Button, file_name: String) -> void:
	var texture := _load_hud_texture(file_name)
	if texture == null:
		return
	var rect := TextureRect.new()
	rect.name = "%sBackdrop" % file_name.get_basename().to_pascal_case()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = -1
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.offset_left = 0
	rect.offset_top = 0
	rect.offset_right = 0
	rect.offset_bottom = 0
	button.add_child(rect)
	button.move_child(rect, 0)

func _hud_skin_path(file_name: String) -> String:
	return HUD_SKIN_BASE % file_name.trim_suffix(".png")

func _load_hud_texture(file_name: String) -> Texture2D:
	var path := _hud_skin_path(file_name)
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)

func _set_speaker_portrait(speaker: String) -> void:
	if _speaker_portrait == null:
		return
	var key := speaker.to_lower()
	var portrait_id := String(SPEAKER_PORTRAITS.get(key, "corvin_neutral"))
	var path := PORTRAIT_BASE % portrait_id
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		_speaker_portrait.texture = null
		return
	_speaker_portrait.texture = ImageTexture.create_from_image(image)

func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.corner_radius_top_left = 2
	box.corner_radius_top_right = 2
	box.corner_radius_bottom_left = 2
	box.corner_radius_bottom_right = 2
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box

func _style_label(label: Label) -> void:
	label.add_theme_color_override("font_color", PALETTE.bone)
	label.add_theme_color_override("font_shadow_color", PALETTE.wet_black)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
