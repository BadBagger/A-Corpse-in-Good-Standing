@tool
extends "res://addons/popochiu/engine/interfaces/i_room.gd"

const PRMudflats := preload("res://game/rooms/mudflats/room_mudflats.gd")
const PRActIGreybox := preload("res://game/rooms/act_i_greybox_room.gd")

var Mudflats: PRMudflats : get = get_Mudflats
var OldQuay: PRActIGreybox : get = get_OldQuay
var SaltMarket: PRActIGreybox : get = get_SaltMarket
var HarborRegistry: PRActIGreybox : get = get_HarborRegistry
var BoneChandler: PRActIGreybox : get = get_BoneChandler
var Almshouse: PRActIGreybox : get = get_Almshouse
var FishHall: PRActIGreybox : get = get_FishHall
var ChurchOfTheDrowned: PRActIGreybox : get = get_ChurchOfTheDrowned
var GreyFloat: PRActIGreybox : get = get_GreyFloat
var HarbormasterOffice: PRActIGreybox : get = get_HarbormasterOffice
var SabineOffice: PRActIGreybox : get = get_SabineOffice

func get_Mudflats() -> PRMudflats: return get_runtime_room("Mudflats")
func get_OldQuay() -> PRActIGreybox: return get_runtime_room("OldQuay")
func get_SaltMarket() -> PRActIGreybox: return get_runtime_room("SaltMarket")
func get_HarborRegistry() -> PRActIGreybox: return get_runtime_room("HarborRegistry")
func get_BoneChandler() -> PRActIGreybox: return get_runtime_room("BoneChandler")
func get_Almshouse() -> PRActIGreybox: return get_runtime_room("Almshouse")
func get_FishHall() -> PRActIGreybox: return get_runtime_room("FishHall")
func get_ChurchOfTheDrowned() -> PRActIGreybox: return get_runtime_room("ChurchOfTheDrowned")
func get_GreyFloat() -> PRActIGreybox: return get_runtime_room("GreyFloat")
func get_HarbormasterOffice() -> PRActIGreybox: return get_runtime_room("HarbormasterOffice")
func get_SabineOffice() -> PRActIGreybox: return get_runtime_room("SabineOffice")
