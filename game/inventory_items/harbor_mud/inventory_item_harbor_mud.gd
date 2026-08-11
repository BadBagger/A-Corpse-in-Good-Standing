@tool
extends PopochiuInventoryItem

const Data := preload("inventory_item_harbor_mud_state.gd")

var state: Data = Data.new()

func _on_click() -> void:
	set_active()

func _on_right_click() -> void:
	await PopochiuUtils.g.show_system_text("A useful amount of harbor mud. The island provides, badly.")

