extends Sprite2D

@export_file("*.png") var background_path := ""

func _ready() -> void:
	if background_path.is_empty():
		push_error("BackgroundImageLoader has no background_path on %s." % get_path())
		return

	var image := Image.new()
	var err := image.load(background_path)
	if err != OK:
		push_error("Could not load room background %s: %s" % [background_path, error_string(err)])
		return

	texture = ImageTexture.create_from_image(image)
