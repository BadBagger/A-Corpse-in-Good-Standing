extends Sprite2D

var _states: Dictionary = {}
var _active_state := ""
var _sheet: Image
var _frame_size := Vector2i.ZERO
var _frame_count := 0
var _fps := 8.0
var _loop := true
var _return_state := ""
var _current_frame := 0
var _accumulator := 0.0

func configure(states: Dictionary, default_state: String) -> bool:
	_states = states
	return play_state(default_state, true)

func play_state(state_name: String, restart := false) -> bool:
	if not _states.has(state_name):
		return false
	if state_name == _active_state and not restart:
		return true

	var state: Dictionary = _states[state_name]
	var image := Image.new()
	var err := image.load(String(state.get("path", "")))
	if err != OK:
		push_warning("Could not load sectional setpiece sheet %s: %s" % [state.get("path", ""), error_string(err)])
		return false

	_frame_count = int(state.get("frames", 1))
	if _frame_count <= 0:
		return false
	_frame_size = Vector2i(int(state.get("width", image.get_width() / _frame_count)), int(state.get("height", image.get_height())))
	if image.get_width() < _frame_size.x * _frame_count or image.get_height() < _frame_size.y:
		push_warning("Sectional setpiece sheet has invalid dimensions: %s" % state.get("path", ""))
		return false

	_sheet = image
	_active_state = state_name
	_fps = float(state.get("fps", 8.0))
	_loop = bool(state.get("loop", true))
	_return_state = String(state.get("return_state", ""))
	_current_frame = 0
	_accumulator = 0.0
	centered = false
	visible = true
	_set_frame(0)
	return true

func active_state_for_test() -> String:
	return _active_state

func frame_count_for_test() -> int:
	return _frame_count

func _process(delta: float) -> void:
	if _sheet == null or _frame_count <= 1 or _fps <= 0.0:
		return
	_accumulator += delta
	var frame_time := 1.0 / _fps
	while _accumulator >= frame_time:
		_accumulator -= frame_time
		_advance_frame()

func _advance_frame() -> void:
	var next_frame := _current_frame + 1
	if next_frame >= _frame_count:
		if _loop:
			next_frame = 0
		elif not _return_state.is_empty():
			play_state(_return_state, true)
			return
		else:
			next_frame = _frame_count - 1
	_set_frame(next_frame)

func _set_frame(frame_index: int) -> void:
	if _sheet == null:
		return
	_current_frame = clampi(frame_index, 0, _frame_count - 1)
	var origin := Vector2i(_current_frame * _frame_size.x, 0)
	texture = ImageTexture.create_from_image(_sheet.get_region(Rect2i(origin, _frame_size)))
