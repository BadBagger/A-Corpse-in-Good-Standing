extends Sprite2D

@export_file("*.png") var prop_path := ""

func _ready() -> void:
	if prop_path.is_empty():
		push_error("PropImageLoader has no prop_path on %s." % get_path())
		return

	var image := Image.new()
	var err := image.load(prop_path)
	if err != OK:
		push_error("Could not load room prop %s: %s" % [prop_path, error_string(err)])
		return

	texture = ImageTexture.create_from_image(image)
