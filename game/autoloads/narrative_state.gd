extends Node

signal changed

const SAVE_PATH := "user://narrative_state.json"
const FLOAT_WARMTH_ROOM_STEPS := 3

const JOURNAL_CATALOG := {
	"j_returned_nine_days": {
		"title": "Nine Days",
		"text": "The returned get nine days before the salt finishes them."
	},
	"j_somebody_drowned_corvin": {
		"title": "Drowned",
		"text": "Corvin did not slip. Somebody put him under."
	},
	"j_corvin_died_thursday": {
		"title": "Thursday",
		"text": "Corvin died on Thursday. The week after that is missing."
	}
}

var current_day := 3
var journal: Dictionary = {}
var discovered_confessions: Array[String] = []
var spent_confessions: Array[String] = []
var opponent_spoken_confessions: Array[String] = []
var acquired_items: Array[String] = []
var act_i_flags: Dictionary = {}
var float_warmth_room_steps_remaining := 0

func _ready() -> void:
	load_state()

func add_journal(id: String) -> bool:
	if not JOURNAL_CATALOG.has(id) or journal.has(id):
		return false
	var entry: Dictionary = JOURNAL_CATALOG[id].duplicate(true)
	entry["id"] = id
	entry["degraded"] = false
	journal[id] = entry
	save_state()
	changed.emit()
	return true

func degrade_journal(id: String) -> bool:
	if not journal.has(id):
		return false
	var entry: Dictionary = journal[id]
	if entry.get("degraded", false):
		return false
	entry["degraded"] = true
	entry["text"] = "Something I knew. Something the salt has started rubbing out."
	journal[id] = entry
	save_state()
	changed.emit()
	return true

func discover_confession(id: String) -> bool:
	if id in spent_confessions or id in opponent_spoken_confessions or id in discovered_confessions:
		return false
	discovered_confessions.append(id)
	discovered_confessions.sort()
	save_state()
	changed.emit()
	return true

func spend_confession(id: String) -> bool:
	if id in spent_confessions:
		return false
	if id in discovered_confessions:
		discovered_confessions.erase(id)
	spent_confessions.append(id)
	spent_confessions.sort()
	save_state()
	changed.emit()
	return true

func lock_opponent_spoken_confession(id: String) -> bool:
	if id in opponent_spoken_confessions:
		return false
	if id in discovered_confessions:
		discovered_confessions.erase(id)
	opponent_spoken_confessions.append(id)
	opponent_spoken_confessions.sort()
	save_state()
	changed.emit()
	return true

func add_item(id: String) -> bool:
	if id in acquired_items:
		return false
	acquired_items.append(id)
	acquired_items.sort()
	save_state()
	changed.emit()
	return true

func has_item(id: String) -> bool:
	return id in acquired_items

func set_act_i_flag(id: String, value := true) -> bool:
	if bool(act_i_flags.get(id, false)) == value:
		return false
	act_i_flags[id] = value
	save_state()
	changed.emit()
	return true

func apply_act_i_flag_reward(id: String) -> bool:
	if id == "FL_float_warmth_active":
		return begin_float_warmth()
	return set_act_i_flag(id, true)

func has_act_i_flag(id: String) -> bool:
	return bool(act_i_flags.get(id, false))

func begin_float_warmth(steps := FLOAT_WARMTH_ROOM_STEPS) -> bool:
	float_warmth_room_steps_remaining = max(steps, 0)
	act_i_flags["FL_float_warmth_active"] = float_warmth_room_steps_remaining > 0
	act_i_flags["FL_float_warmth_expired"] = false
	save_state()
	changed.emit()
	return true

func consume_float_warmth_room_step() -> bool:
	if not has_act_i_flag("FL_float_warmth_active"):
		return false
	if float_warmth_room_steps_remaining <= 0:
		set_act_i_flag("FL_float_warmth_active", false)
		return true
	float_warmth_room_steps_remaining -= 1
	if float_warmth_room_steps_remaining <= 0:
		act_i_flags["FL_float_warmth_active"] = false
		act_i_flags["FL_float_warmth_expired"] = true
		save_state()
		changed.emit()
		return true
	save_state()
	changed.emit()
	return false

func are_act_i_rites_complete() -> bool:
	return has_act_i_flag("FL_rite_name") and has_act_i_flag("FL_rite_debt") and has_act_i_flag("FL_rite_heartbeat")

func apply_ink_tag(tag: String) -> bool:
	if tag.begins_with("journal:add:"):
		return add_journal(tag.substr("journal:add:".length()))
	if tag.begins_with("journal:degrade:"):
		return degrade_journal(tag.substr("journal:degrade:".length()))
	if tag.begins_with("confession:discover:"):
		return discover_confession(tag.substr("confession:discover:".length()))
	if tag.begins_with("confession:spent:"):
		return spend_confession(tag.substr("confession:spent:".length()))
	if tag.begins_with("confession:opponent_spoken:"):
		return lock_opponent_spoken_confession(tag.substr("confession:opponent_spoken:".length()))
	if tag.begins_with("item:add:"):
		return add_item(tag.substr("item:add:".length()))
	return false

func get_journal_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for id in journal.keys():
		entries.append(journal[id])
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"]))
	return entries

func get_confession_summary() -> String:
	return "Litany: %d known, %d spent, %d locked" % [
		discovered_confessions.size(),
		spent_confessions.size(),
		opponent_spoken_confessions.size()
	]

func to_snapshot() -> Dictionary:
	return {
		"current_day": current_day,
		"journal": journal.duplicate(true),
		"discovered_confessions": discovered_confessions.duplicate(),
		"spent_confessions": spent_confessions.duplicate(),
		"opponent_spoken_confessions": opponent_spoken_confessions.duplicate(),
		"acquired_items": acquired_items.duplicate(),
		"act_i_flags": act_i_flags.duplicate(true),
		"float_warmth_room_steps_remaining": float_warmth_room_steps_remaining
	}

func apply_snapshot(snapshot: Dictionary, write_to_disk := true) -> void:
	current_day = int(snapshot.get("current_day", current_day))
	journal = snapshot.get("journal", {}).duplicate(true)
	discovered_confessions.assign(snapshot.get("discovered_confessions", []))
	spent_confessions.assign(snapshot.get("spent_confessions", []))
	opponent_spoken_confessions.assign(snapshot.get("opponent_spoken_confessions", []))
	acquired_items.assign(snapshot.get("acquired_items", []))
	act_i_flags = snapshot.get("act_i_flags", {}).duplicate(true)
	float_warmth_room_steps_remaining = int(snapshot.get("float_warmth_room_steps_remaining", 0))
	if write_to_disk:
		save_state()
	changed.emit()

func clear_runtime_state(write_to_disk := true) -> void:
	current_day = 3
	journal.clear()
	discovered_confessions.clear()
	spent_confessions.clear()
	opponent_spoken_confessions.clear()
	acquired_items.clear()
	act_i_flags.clear()
	float_warmth_room_steps_remaining = 0
	if write_to_disk:
		save_state()
	changed.emit()

func save_state() -> void:
	var payload := to_snapshot()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload, "\t"))

func load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	apply_snapshot(parsed, false)
