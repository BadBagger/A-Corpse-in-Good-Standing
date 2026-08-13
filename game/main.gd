extends Node2D

func _ready() -> void:
	print("A Corpse in Good Standing: Act I loaded")
	if Engine.has_singleton("R"):
		R.goto_room("Mudflats", false, false)
