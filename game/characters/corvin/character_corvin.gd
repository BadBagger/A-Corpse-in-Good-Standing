@tool
extends PopochiuCharacter

const Data := preload("character_corvin_state.gd")

var state: Data = Data.new()
var _last_side_direction := "side_right"

func play_runtime_animation(animation_name: String) -> bool:
	if animation_name == "idle_current_side":
		animation_name = "idle_%s" % _last_side_direction
	var runtime_sprite := get_node_or_null("RuntimeSprite")
	if runtime_sprite == null or not runtime_sprite.has_method("play_animation"):
		return false
	var played := bool(runtime_sprite.call("play_animation", animation_name))
	if played:
		_remember_side_direction(animation_name)
	return played

func play_idle_side_right() -> bool:
	return play_runtime_animation("idle_side_right")

func play_idle_side_left() -> bool:
	return play_runtime_animation("idle_side_left")

func play_walk_side_right() -> bool:
	return play_runtime_animation("walk_side_right")

func play_walk_side_left() -> bool:
	return play_runtime_animation("walk_side_left")

func play_idle_current_side() -> bool:
	return play_runtime_animation("idle_current_side")

func active_side_direction_for_test() -> String:
	return _last_side_direction

func _remember_side_direction(animation_name: String) -> void:
	if animation_name.ends_with("_side_left"):
		_last_side_direction = "side_left"
	elif animation_name.ends_with("_side_right"):
		_last_side_direction = "side_right"

func _on_room_set() -> void:
	if get_parent() and get_parent().get_parent() and get_parent().get_parent().has_node("Markers/PlayerStart"):
		position = get_parent().get_parent().get_node("Markers/PlayerStart").position

func _on_click() -> void:
	PopochiuUtils.e.command_fallback()

func _on_right_click() -> void:
	await PopochiuUtils.g.show_system_text("Corvin Vale: dead, damp, and still somehow overdressed.")
