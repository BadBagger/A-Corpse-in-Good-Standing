extends CanvasLayer

signal verb_changed(verb: String)

const VERBS := ["walk", "look", "use", "talk", "wet"]
const HUD_SKIN_BASE := "res://game/ui/skins/act_i/%s.png"
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

var selected_verb := "look"
var inventory_items: Array[String] = []

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
		return
	var rendered: Array[String] = []
	for line in lines:
		var speaker := String(line.get("speaker", "")).capitalize()
		var text := String(line.get("text", ""))
		rendered.append("%s: %s" % [speaker, text] if not speaker.is_empty() else text)
	_dialogue.text = "\n".join(rendered)

func _refresh_inventory() -> void:
	_inventory.text = "Inventory: " + (", ".join(inventory_items) if not inventory_items.is_empty() else "empty")

func _apply_noir_skin() -> void:
	_add_texture_backdrop(%Status, "status_strip.png", Vector2(8, 30), Vector2(0.325, 0.50), -1, Rect2i(0, 0, 430, 112))
	_add_texture_backdrop(%Dialogue, "dialogue_panel.png", Vector2(-128, -8), Vector2(1.15, 0.56), -1)
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
