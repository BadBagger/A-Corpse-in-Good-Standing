@tool
extends "res://addons/popochiu/engine/interfaces/i_character.gd"

const PCCorvin := preload("res://game/characters/corvin/character_corvin.gd")

var Corvin: PCCorvin : get = get_Corvin

func get_Corvin() -> PCCorvin: return get_runtime_character("Corvin")
