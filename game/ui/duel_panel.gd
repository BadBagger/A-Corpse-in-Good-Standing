extends CanvasLayer

signal duel_won(opponent_id: String)
signal duel_lost(opponent_id: String)

const CATEGORIES := ["GREED", "LUST", "PRIDE", "CRUELTY", "COWARDICE", "BETRAYAL"]
const CONFESSIONS_PATH := "res://data/confessions.json"
const OPPONENT_PATH_TEMPLATE := "res://duels/opponents/%s.json"
const DAMAGE_REQUIRED := 2
const MAX_SALT := 3
const DUEL_RULE_HINT := "Rule: counter weight must be higher, and sin must match or trump. Spoken cards are spent."
const PALETTE := {
	"bone": Color("#E4DCC8"),
	"wet_black": Color("#0C1013"),
	"harbor_slate": Color("#2A3A40"),
	"absinthe": Color("#7D9B4E"),
	"amber": Color("#C98A3C"),
}

var opponent_id := ""
var opponent: Dictionary = {}
var narrative: Node
var base_pool: Array[String] = []
var confessions_by_id: Dictionary = {}
var attack_index := 0
var current_attack_damage := 0
var salt := 0
var begun_attacks: Dictionary = {}
var last_message := ""

var _root_panel: Panel
var _title: Label
var _subtitle: Label
var _round_label: Label
var _salt_label: Label
var _attack_meta: Label
var _attack: Label
var _status: Label
var _option_hint: Label
var _options: VBoxContainer
var _close_button: Button
var _first_option_button: Button

func _ready() -> void:
	_build_ui()
	visible = false

func start_duel(id: String, narrative_state: Node, pool: Array[String]) -> void:
	opponent_id = id
	narrative = narrative_state
	base_pool.assign(pool)
	confessions_by_id = _load_confessions()
	opponent = _load_opponent(id)
	attack_index = 0
	current_attack_damage = 0
	salt = 0
	begun_attacks.clear()
	last_message = ""
	visible = true
	_render()

func play_confession(confession_id: String) -> Dictionary:
	if opponent.is_empty():
		return {"accepted": false, "won": false, "lost": false, "message": "No duel is active."}
	if attack_index >= _attacks().size():
		return {"accepted": false, "won": true, "lost": false, "message": "Duel already won."}

	var attack := _begin_current_attack()
	if not confessions_by_id.has(confession_id):
		last_message = "Confession is not defined."
		_render()
		return {"accepted": false, "won": false, "lost": false, "message": last_message}
	if not _available_confession_ids().has(confession_id):
		last_message = "Confession is not available."
		_render()
		return {"accepted": false, "won": false, "lost": false, "message": last_message}

	var confession: Dictionary = confessions_by_id[confession_id]
	narrative.spend_confession(confession_id)
	var accepted := _is_valid_counter(attack, confession)
	var damage := 0
	if accepted:
		damage = 1 if String(confession.get("elaboration", "")).strip_edges().is_empty() else 2
		current_attack_damage += damage
		last_message = "Accepted: %s" % String(confession.get("elaboration", ""))
		if current_attack_damage >= DAMAGE_REQUIRED:
			attack_index += 1
			current_attack_damage = 0
	else:
		salt += 1
		last_message = "Rejected: %s Salt %d/%d." % [_rejection_reason(attack, confession), salt, MAX_SALT]

	var won := attack_index >= _attacks().size()
	var lost := salt >= MAX_SALT
	_render()
	if won:
		visible = false
		duel_won.emit(opponent_id)
	elif lost:
		duel_lost.emit(opponent_id)

	return {
		"accepted": accepted,
		"damage": damage,
		"salt": salt,
		"won": won,
		"lost": lost,
		"message": last_message
	}

func get_available_confession_ids() -> Array[String]:
	return _available_confession_ids()

func get_current_attack() -> Dictionary:
	if attack_index >= _attacks().size():
		return {}
	return _begin_current_attack()

func get_ui_snapshot() -> Dictionary:
	var option_texts: Array[String] = []
	for child in _options.get_children():
		if child is Button:
			option_texts.append(String(child.text))
	return {
		"visible": visible,
		"title": _title.text if _title else "",
		"subtitle": _subtitle.text if _subtitle else "",
		"round": _round_label.text if _round_label else "",
		"salt": _salt_label.text if _salt_label else "",
		"attack_meta": _attack_meta.text if _attack_meta else "",
		"attack": _attack.text if _attack else "",
		"status": _status.text if _status else "",
		"option_hint": _option_hint.text if _option_hint else "",
		"option_count": option_texts.size(),
		"option_texts": option_texts,
		"close_text": _close_button.text if _close_button else "",
	}

func _begin_current_attack() -> Dictionary:
	var attack: Dictionary = _attacks()[attack_index]
	if not begun_attacks.has(attack_index):
		begun_attacks[attack_index] = true
		var lock_id := String(attack.get("locks_confession_id", ""))
		if not lock_id.is_empty():
			narrative.lock_opponent_spoken_confession(lock_id)
	return attack

func _available_confession_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in base_pool:
		if confessions_by_id.has(id) and not narrative.spent_confessions.has(id) and not narrative.opponent_spoken_confessions.has(id):
			ids.append(id)
	for id in narrative.discovered_confessions:
		if confessions_by_id.has(id) and not ids.has(id) and not narrative.spent_confessions.has(id) and not narrative.opponent_spoken_confessions.has(id):
			ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ca: Dictionary = confessions_by_id[a]
		var cb: Dictionary = confessions_by_id[b]
		var cat_a := CATEGORIES.find(String(ca.get("category", "")))
		var cat_b := CATEGORIES.find(String(cb.get("category", "")))
		if cat_a != cat_b:
			return cat_a < cat_b
		var weight_a := int(ca.get("weight", 0))
		var weight_b := int(cb.get("weight", 0))
		if weight_a != weight_b:
			return weight_a < weight_b
		return a < b
	)
	return ids

func _is_valid_counter(attack: Dictionary, confession: Dictionary) -> bool:
	return int(confession.get("weight", 0)) > int(attack.get("weight", 0)) \
		and CATEGORIES.find(String(confession.get("category", ""))) >= CATEGORIES.find(String(attack.get("category", "")))

func _rejection_reason(attack: Dictionary, confession: Dictionary) -> String:
	var reasons: Array[String] = []
	if int(confession.get("weight", 0)) <= int(attack.get("weight", 0)):
		reasons.append("weight is not higher than the accusation")
	if CATEGORIES.find(String(confession.get("category", ""))) < CATEGORIES.find(String(attack.get("category", ""))):
		reasons.append("sin category does not match or trump")
	if reasons.is_empty():
		return "the salt refuses it."
	return "%s." % "; ".join(reasons)

func _attacks() -> Array:
	return opponent.get("attacks", [])

func _load_confessions() -> Dictionary:
	var file := FileAccess.open(CONFESSIONS_PATH, FileAccess.READ)
	if not file:
		push_error("Could not load confessions: %s" % CONFESSIONS_PATH)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	var by_id := {}
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Confession data must be an array.")
		return by_id
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY:
			by_id[String(item.get("id", ""))] = item
	return by_id

func _load_opponent(id: String) -> Dictionary:
	var path := OPPONENT_PATH_TEMPLATE % id
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Could not load opponent: %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Opponent data must be a dictionary: %s" % path)
		return {}
	return parsed

func _build_ui() -> void:
	_root_panel = Panel.new()
	_root_panel.name = "DuelPanel"
	_root_panel.set_anchors_preset(Control.PRESET_CENTER)
	_root_panel.custom_minimum_size = Vector2(980.0, 620.0)
	_root_panel.offset_left = -490.0
	_root_panel.offset_top = -310.0
	_root_panel.offset_right = 490.0
	_root_panel.offset_bottom = 310.0
	add_child(_root_panel)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 24.0
	layout.offset_top = 18.0
	layout.offset_right = -24.0
	layout.offset_bottom = -18.0
	layout.add_theme_constant_override("separation", 12)
	_root_panel.add_child(layout)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 18)
	layout.add_child(header)

	var title_stack := VBoxContainer.new()
	title_stack.name = "TitleStack"
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_stack)

	_title = Label.new()
	_title.name = "Title"
	_title.add_theme_color_override("font_color", PALETTE.bone)
	_title.add_theme_font_size_override("font_size", 26)
	title_stack.add_child(_title)

	_subtitle = Label.new()
	_subtitle.name = "Subtitle"
	_subtitle.add_theme_color_override("font_color", PALETTE.amber)
	_subtitle.add_theme_font_size_override("font_size", 14)
	title_stack.add_child(_subtitle)

	var state_stack := VBoxContainer.new()
	state_stack.name = "StateStack"
	state_stack.custom_minimum_size = Vector2(190.0, 0.0)
	header.add_child(state_stack)

	_round_label = Label.new()
	_round_label.name = "Round"
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_round_label.add_theme_color_override("font_color", PALETTE.bone)
	state_stack.add_child(_round_label)

	_salt_label = Label.new()
	_salt_label.name = "Salt"
	_salt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_salt_label.add_theme_color_override("font_color", PALETTE.absinthe)
	state_stack.add_child(_salt_label)

	_attack_meta = Label.new()
	_attack_meta.name = "AttackMeta"
	_attack_meta.add_theme_color_override("font_color", PALETTE.amber)
	_attack_meta.add_theme_font_size_override("font_size", 13)
	layout.add_child(_attack_meta)

	_attack = Label.new()
	_attack.name = "Attack"
	_attack.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_attack.custom_minimum_size = Vector2(0.0, 88.0)
	_attack.add_theme_color_override("font_color", PALETTE.bone)
	_attack.add_theme_font_size_override("font_size", 20)
	layout.add_child(_attack)

	_status = Label.new()
	_status.name = "Status"
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(0.0, 64.0)
	_status.add_theme_color_override("font_color", PALETTE.absinthe)
	layout.add_child(_status)

	_option_hint = Label.new()
	_option_hint.name = "OptionHint"
	_option_hint.text = DUEL_RULE_HINT
	_option_hint.add_theme_color_override("font_color", PALETTE.amber)
	_option_hint.add_theme_font_size_override("font_size", 13)
	layout.add_child(_option_hint)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	_options = VBoxContainer.new()
	_options.name = "Options"
	_options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_options.add_theme_constant_override("separation", 8)
	scroll.add_child(_options)

	_close_button = Button.new()
	_close_button.text = "Leave duel"
	_close_button.tooltip_text = "Close the greybox duel panel without resolving it."
	_close_button.pressed.connect(func() -> void: visible = false)
	layout.add_child(_close_button)

func _render() -> void:
	if not is_inside_tree():
		return
	if opponent.is_empty():
		return

	_title.text = "Confession Duel: %s" % String(opponent.get("name", opponent_id))
	_subtitle.text = "The Drowned respect only what is volunteered."
	_round_label.text = "Accusation %d/%d" % [min(attack_index + 1, _attacks().size()), _attacks().size()]
	_salt_label.text = "Salt %d/%d" % [salt, MAX_SALT]
	var attack := {}
	if attack_index >= _attacks().size():
		_attack_meta.text = "Resolved"
		_attack.text = "The salt has heard enough."
	else:
		attack = _begin_current_attack()
		_attack_meta.text = "%s accusation - %s %d" % [
			String(opponent.get("name", "Opponent")).to_upper(),
			String(attack.get("category", "")),
			int(attack.get("weight", 0)),
		]
		_attack.text = "\"%s\"" % String(attack.get("text", ""))

	_status.tooltip_text = "%s Salt is taken on failed counters. At %d Salt, the duel is lost." % [
		DUEL_RULE_HINT,
		MAX_SALT
	]
	if attack_index >= _attacks().size():
		_option_hint.text = DUEL_RULE_HINT
	else:
		_option_hint.text = "%s Current accusation: %s %d." % [
			DUEL_RULE_HINT,
			String(attack.get("category", "")),
			int(attack.get("weight", 0))
		]

	_status.text = "%s\nSalt %d/%d. %s" % [
		last_message if not last_message.is_empty() else "Pick a confession from the Litany.",
		salt,
		MAX_SALT,
		DUEL_RULE_HINT
	]

	_first_option_button = null
	for child in _options.get_children():
		_options.remove_child(child)
		child.free()

	for confession_id in _available_confession_ids():
		var confession: Dictionary = confessions_by_id[confession_id]
		var button := Button.new()
		button.name = confession_id
		button.custom_minimum_size = Vector2(0.0, 54.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s  W%d  %s" % [
			String(confession.get("category", "")),
			int(confession.get("weight", 0)),
			String(confession.get("text", ""))
		]
		button.tooltip_text = "%s confession. Weight %d. This will be spent whether it works or fails." % [
			String(confession.get("category", "")),
			int(confession.get("weight", 0))
		]
		button.pressed.connect(play_confession.bind(confession_id))
		_options.add_child(button)
		if _first_option_button == null:
			_first_option_button = button

	if _first_option_button != null and visible:
		_first_option_button.grab_focus.call_deferred()
