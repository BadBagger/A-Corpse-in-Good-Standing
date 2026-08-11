@tool
extends "res://addons/popochiu/engine/interfaces/i_inventory.gd"

const PIIHarborMud := preload("res://game/inventory_items/harbor_mud/inventory_item_harbor_mud.gd")
const PIIBorrowedBoots := preload("res://game/inventory_items/borrowed_boots/inventory_item_borrowed_boots.gd")

var HarborMud: PIIHarborMud : get = get_HarborMud
var BorrowedBoots: PIIBorrowedBoots : get = get_BorrowedBoots

func get_HarborMud() -> PIIHarborMud: return get_item_instance("HarborMud")

func get_BorrowedBoots() -> PIIBorrowedBoots: return get_item_instance("BorrowedBoots")

