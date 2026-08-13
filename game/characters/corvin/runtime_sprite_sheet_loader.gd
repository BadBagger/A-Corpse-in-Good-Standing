@tool
extends Sprite2D

const FRAME_SIZE := Vector2i(256, 512)
const FPS := 12.0
const VISUAL_SCALE := 0.72
const DEFAULT_ANIMATION := "idle_side_right"
const READABILITY_SHADOW_COLOR := Color(0.0470588, 0.0627451, 0.0745098, 0.44)
const READABILITY_SHADOW_OFFSET := Vector2(10, 14)
const ANIMATIONS := {
	"idle_side_right": {
		"path": "res://game/characters/corvin/sprites/act_i_clean/idle_side_right.png",
		"frames": 12,
	},
	"idle_side_left": {
		"path": "res://game/characters/corvin/sprites/act_i_clean/idle_side_left.png",
		"frames": 12,
	},
	"walk_side_right": {
		"path": "res://game/characters/corvin/sprites/act_i_clean/walk_side_right.png",
		"frames": 8,
	},
	"walk_side_left": {
		"path": "res://game/characters/corvin/sprites/act_i_clean/walk_side_left.png",
		"frames": 8,
	},
	"talk_side_right": {
		"path": "res://game/characters/corvin/sprites/act_i_clean/talk_side_right.png",
		"frames": 6,
	},
	"talk_side_left": {
		"path": "res://game/characters/corvin/sprites/act_i_clean/talk_side_left.png",
		"frames": 6,
	},
	"use_side_right": {
		"path": "res://game/characters/corvin/sprites/act_i_clean/use_side_right.png",
		"frames": 8,
	},
	"use_side_left": {
		"path": "res://game/characters/corvin/sprites/act_i_clean/use_side_left.png",
		"frames": 8,
	},
	"wet_side_right": {
		"path": "res://game/characters/corvin/sprites/act_i_clean/wet_side_right.png",
		"frames": 8,
	},
	"wet_side_left": {
		"path": "res://game/characters/corvin/sprites/act_i_clean/wet_side_left.png",
		"frames": 8,
	},
}

@export var fallback_node_path: NodePath = ^"../Sprite2D"
@export var salt_node_path: NodePath = ^"../SaltKnuckles"
@export var drip_node_path: NodePath = ^"../Drip"

var _sheet: Image
var _active_animation := DEFAULT_ANIMATION
var _frame_count := 0
var _current_frame := 0
var _accumulator := 0.0
var _readability_shadow: Sprite2D

func _ready() -> void:
	_ensure_readability_shadow()
	_load_sheet()


func _process(delta: float) -> void:
	if _sheet == null:
		return

	_accumulator += delta
	var frame_time := 1.0 / FPS
	while _accumulator >= frame_time:
		_accumulator -= frame_time
		_set_frame((_current_frame + 1) % _frame_count)


func _load_first_frame() -> void:
	_load_sheet()


func _load_sheet() -> void:
	_load_animation(DEFAULT_ANIMATION)


func play_animation(animation_name: String) -> bool:
	if animation_name == _active_animation and _sheet != null:
		return true
	return _load_animation(animation_name)


func is_animation_available(animation_name: String) -> bool:
	return ANIMATIONS.has(animation_name)


func is_animation_planned(animation_name: String) -> bool:
	return false


func active_animation_for_test() -> String:
	return _active_animation


func frame_count_for_test() -> int:
	return _frame_count


func _load_animation(animation_name: String) -> bool:
	if not ANIMATIONS.has(animation_name):
		_show_fallback()
		return false

	var animation: Dictionary = ANIMATIONS[animation_name]
	var sprite_sheet_path := String(animation["path"])
	var frame_count := int(animation["frames"])
	var image := Image.new()
	var err := image.load(sprite_sheet_path)
	if err != OK:
		_show_fallback()
		return false

	if image.get_width() < FRAME_SIZE.x * frame_count or image.get_height() < FRAME_SIZE.y:
		_show_fallback()
		return false

	_sheet = image
	_active_animation = animation_name
	_frame_count = frame_count
	_current_frame = 0
	_accumulator = 0.0
	centered = true
	offset = Vector2(0, -188)
	scale = Vector2(VISUAL_SCALE, VISUAL_SCALE)
	visible = true
	_update_readability_shadow()
	_hide_fallback()
	_set_frame(0)
	return true


func _set_frame(frame_index: int) -> void:
	if _sheet == null:
		return

	_current_frame = clampi(frame_index, 0, _frame_count - 1)
	var frame_origin := Vector2i(_current_frame * FRAME_SIZE.x, 0)
	var frame := _sheet.get_region(Rect2i(frame_origin, FRAME_SIZE))
	var frame_texture := ImageTexture.create_from_image(frame)
	texture = frame_texture
	if _readability_shadow:
		_readability_shadow.texture = frame_texture


func advance_for_test(delta: float) -> int:
	_process(delta)
	return _current_frame


func current_frame_for_test() -> int:
	return _current_frame


func _hide_fallback() -> void:
	for path in [fallback_node_path, salt_node_path, drip_node_path]:
		var node := get_node_or_null(path)
		if node is CanvasItem:
			node.visible = false


func _show_fallback() -> void:
	_sheet = null
	_frame_count = 0
	visible = false
	if _readability_shadow:
		_readability_shadow.visible = false
	for path in [fallback_node_path, salt_node_path, drip_node_path]:
		var node := get_node_or_null(path)
		if node is CanvasItem:
			node.visible = true


func _ensure_readability_shadow() -> void:
	if _readability_shadow:
		return
	_readability_shadow = Sprite2D.new()
	_readability_shadow.name = "RuntimeReadabilityShadow"
	_readability_shadow.centered = true
	_readability_shadow.modulate = READABILITY_SHADOW_COLOR
	_readability_shadow.z_index = z_index - 1
	_readability_shadow.show_behind_parent = true
	_readability_shadow.visible = false
	add_child(_readability_shadow)


func _update_readability_shadow() -> void:
	_ensure_readability_shadow()
	_readability_shadow.offset = offset + READABILITY_SHADOW_OFFSET
	_readability_shadow.scale = Vector2.ONE
	_readability_shadow.visible = visible
