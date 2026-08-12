extends CanvasLayer

signal verb_changed(verb: String)

const VERBS := ["walk", "look", "use", "talk", "wet"]

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
	for verb in VERBS:
		_verb_buttons[verb].pressed.connect(set_selected_verb.bind(verb))
	set_selected_verb(selected_verb)
	set_status("Pick a verb, then click a greybox hotspot.")
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
