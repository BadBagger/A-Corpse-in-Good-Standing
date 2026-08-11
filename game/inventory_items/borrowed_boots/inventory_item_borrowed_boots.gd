@tool
extends PopochiuInventoryItem

const Data := preload("inventory_item_borrowed_boots_state.gd")

var state: Data = Data.new()

func _on_click() -> void:
	set_active()

func _on_right_click() -> void:
	await PopochiuUtils.g.show_system_text("Boots acquired on credit, panic, and a loose definition of ownership.")

