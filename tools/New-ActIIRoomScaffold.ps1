$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Value
    )
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Value, $encoding)
}

function Format-GodotString {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) {
        return '""'
    }
    $escaped = $Value -replace '\\', '\\' -replace '"', '\"' -replace "`r?`n", '\n'
    return '"' + $escaped + '"'
}

function Format-GodotStringArray {
    param([string[]]$Items)
    if (-not $Items -or $Items.Count -eq 0) {
        return "Array[String]([])"
    }
    $quoted = $Items | ForEach-Object { Format-GodotString $_ }
    return "Array[String]([" + ($quoted -join ", ") + "])"
}

$rooms = @(
    @{
        Id="kane_parlour"; Script="KaneParlour"; Code="R13"; Title="Kane's Parlour"; Notes="Act II opening. Refuse Kane, steal the seal, begin the paper trail."; Background="Color(0.0470588, 0.0627451, 0.0745098, 1)"
        Exits=@(@{ Name="ToFloat"; Target="FloatLower"; Label="The Grey Float"; X=220; Y=740 }, @{ Name="ToCustoms"; Target="CustomsHouse"; Label="Customs House"; X=1680; Y=730; RequiresItems=@("IT_forged_customs_writ"); Blocked="The Customs House needs an official-looking lie first." })
        Interactions=@(
            @{ Name="Kane"; Key="kane"; Label="Ossuary Kane"; X=790; Y=660; Look="Kane is immaculate from the waist up and reef from the waist down."; Use="Kane offers Corvin six days without the fear. Corvin refuses, because apparently he has principles now."; Talk="Kane gives the reasonable offer. That is the dangerous part."; Walk="Corvin stops at the edge of Kane's green light."; FlagsSet=@("FL_act_ii_started","FL_kane_offer_refused","FL_kane_offer_heard"); InkKnot="act_ii_kane_offer" },
            @{ Name="WaxSeal"; Key="wax_seal"; Label="Kane's wax seal"; X=1040; Y=720; Look="Kane's seal waits on the desk like a small official sin."; Use="Corvin palms the seal during the handshake Kane insists on."; Talk="Corvin asks the seal if it has standards. It has a crest instead."; Walk="Corvin stands close enough to steal something useful."; RequiresFlags=@("FL_kane_offer_refused"); Blocked="Kane has not offered his hand yet."; ItemsAdd=@("IT_kane_seal"); FlagsSet=@("FL_kane_seal_stolen"); InkKnot="act_ii_kane_seal" },
            @{ Name="ForgeWrit"; Key="forge_writ"; Label="blank customs writ"; X=1220; Y=700; Look="Blank paper. Official paper. The difference is wax and confidence."; Use="Corvin presses Kane's seal into the writ. It becomes legal enough for Mordida."; Talk="Corvin tells the paper to behave like authority. It has been waiting for that."; Walk="Corvin stands over the desk and makes fraud look clerical."; RequiresItems=@("IT_kane_seal"); Blocked="The paper needs Kane's seal before it can lie convincingly."; ItemsAdd=@("IT_forged_customs_writ"); FlagsSet=@("FL_customs_writ_forged"); InkKnot="act_ii_forge_writ" }
        )
    },
    @{
        Id="float_lower"; Script="FloatLower"; Code="R14"; Title="Below Decks, The Grey Float"; Notes="Mireille memory-book chain. Hard-R non-explicit staging only."; Background="Color(0.164706, 0.227451, 0.25098, 1)"
        Exits=@(@{ Name="ToKane"; Target="KaneParlour"; Label="Kane's Parlour"; X=180; Y=740 }, @{ Name="ToCustoms"; Target="CustomsHouse"; Label="Customs House"; X=1700; Y=720; RequiresItems=@("IT_forged_customs_writ"); Blocked="Customs still wants paper with the right wrong seal." })
        Interactions=@(
            @{ Name="Mireille"; Key="mireille"; Label="Mireille Dax"; X=740; Y=680; Look="Mireille is on day eight and still winning the room by pretending she is not leaving it."; Use="Corvin writes today down for her: the light, the joke, the part where she was funny first."; Talk="Mireille says she is not tragic, just early."; Walk="Corvin stands where the steam gives grief manners."; FlagsSet=@("FL_mireille_today_recorded","FL_memory_decay_tutorial_seen"); ItemsAdd=@("IT_mireille_book"); InkKnot="act_ii_mireille_book" },
            @{ Name="SteamScreens"; Key="steam_screens"; Label="steam screens"; X=1180; Y=650; Look="Steam, amber light, silhouettes, privacy. The Float sells boundaries by the minute."; Use="Corvin lets the steam hide him. It cannot make him warm."; Talk="The screens keep counsel better than most clients."; Walk="Corvin passes the screens without making anyone into scenery."; FlagsSet=@("FL_float_lower_access"); InkKnot="act_ii_float_screens" },
            @{ Name="LampValve"; Key="lamp_valve"; Label="lamp valve"; X=1450; Y=700; Look="A brass valve feeds amber light through the lower deck."; Use="Corvin lowers the flame. The room becomes kinder and less honest."; Talk="Corvin asks the valve for discretion. It gives him atmosphere."; Walk="Corvin stands where amber pretends to be safety."; FlagsSet=@("FL_float_lamp_dimmed"); InkKnot="act_ii_float_lamp" }
        )
    },
    @{
        Id="customs_house"; Script="CustomsHouse"; Code="R15"; Title="Customs House"; Notes="The impossible ledger, cut paper, tide table, and optional harbor betrayal."; Background="Color(0.894118, 0.862745, 0.784314, 1)"
        Exits=@(@{ Name="ToKane"; Target="KaneParlour"; Label="Kane's Parlour"; X=180; Y=740 }, @{ Name="ToKestrel"; Target="KestrelWreck"; Label="Kestrel Wreck"; X=1700; Y=730; RequiresItems=@("IT_tide_table"); Blocked="The wreck only opens at low tide. The table knows when." }, @{ Name="ToSabine"; Target="SabineOfficeReturn"; Label="Sabine's Office"; X=960; Y=620; RequiresFlags=@("FL_sabine_reveal_ready"); Blocked="Corvin has the signature. He still needs the Tomas papers before this hurts properly." })
        Interactions=@(
            @{ Name="LedgerCabinet"; Key="ledger_cabinet"; Label="impossible ledger"; X=720; Y=670; Look="The ledger should not exist. Naturally, Customs gave it a cabinet."; Use="The writ opens the cabinet. The transaction names a broker, not a killer, and Sabine's hand is on the counter-signature."; Talk="Corvin asks the ledger who sold him. The ledger answers in fees."; Walk="Corvin stands where paper learns to drown people."; RequiresItems=@("IT_forged_customs_writ"); Blocked="The cabinet wants authority. Kane's stolen seal should do."; ItemsAdd=@("IT_cut_paper"); FlagsSet=@("FL_customs_access","FL_sabine_signature_seen","FL_harbor_assignment_offer_seen"); InkKnot="act_ii_cut_paper"; BlockedInkKnot="act_ii_customs_locked" },
            @{ Name="TideTable"; Key="tide_table"; Label="tide table"; X=1120; Y=680; Look="Tides, tariffs, and one low-water window by the Kestrel."; Use="Corvin takes the tide table. The wreck has an appointment with the mud."; Talk="Corvin asks the table for mercy. It offers timing."; Walk="Corvin stands under dates that do not care who is dead."; RequiresItems=@("IT_cut_paper"); Blocked="The tide table matters after the transaction points at the Kestrel."; ItemsAdd=@("IT_tide_table"); FlagsSet=@("FL_kestrel_window_known"); InkKnot="act_ii_tide_table" },
            @{ Name="HarborAssignment"; Key="harbor_assignment"; Label="harbor assignment"; X=1390; Y=705; Look="A document that would sign Sabine out of her own harbor."; Use="Corvin notarizes the harbor assignment anyway. The ink takes too well."; Talk="Corvin tells the paper it is only paper. The paper knows better."; Walk="Corvin stands over the kind of choice that becomes a confession."; RequiresFlags=@("FL_harbor_assignment_offer_seen"); Blocked="The assignment is not visible until the impossible ledger is open."; FlagsSet=@("FL_harbor_assignment_signed"); ConfessionsDiscover=@("cf_bt_harbor"); InkKnot="act_ii_harbor_assignment" }
        )
    },
    @{
        Id="kestrel_wreck"; Script="KestrelWreck"; Code="R16"; Title="The Kestrel at Low Tide"; Notes="Low-water wreck. Tomas papers and Act II betrayal excavation."; Background="Color(0.0470588, 0.0627451, 0.0745098, 1)"
        Exits=@(@{ Name="ToCustoms"; Target="CustomsHouse"; Label="Customs House"; X=180; Y=740 })
        Interactions=@(
            @{ Name="HullRibs"; Key="hull_ribs"; Label="broken hull ribs"; X=580; Y=710; Look="The Kestrel's ribs show at low tide. Mordida likes a theme."; Use="Corvin puts a hand on the hull and gets salt under the nails."; Talk="The hull has already given its statement. Nobody liked it."; Walk="Corvin steps through mud that remembers cargo."; FlagsSet=@("FL_kestrel_window_open"); InkKnot="act_ii_kestrel_hull" },
            @{ Name="Strongbox"; Key="strongbox"; Label="crew-list strongbox"; X=980; Y=700; Look="A strongbox under the tilted hold. The lock has drowned better than Corvin."; Use="Corvin opens the strongbox with the tide table's timing and a notary's old nerve. Tomas's name is there."; Talk="Corvin asks the box to be empty. It refuses."; Walk="Corvin stands above the hold and tries not to count eleven."; RequiresItems=@("IT_tide_table"); Blocked="The strongbox is reachable only when the tide gives the Kestrel back."; ItemsAdd=@("IT_tomas_papers"); FlagsSet=@("FL_tomas_papers_found"); ConfessionsDiscover=@("cf_bt_tomas","cf_pride_kestrel"); InkKnot="act_ii_tomas_papers"; BlockedInkKnot="act_ii_kestrel_tide_blocked" },
            @{ Name="CargoHold"; Key="cargo_hold"; Label="cargo hold"; X=1350; Y=740; Look="The hold is too small for eleven people and exactly large enough for paperwork."; Use="Corvin reads the shape of the hold and does not improve as a person."; Talk="The hold says nothing. That is how it survived the manifest."; Walk="Corvin stands where freight used to breathe."; RequiresItems=@("IT_tomas_papers"); Blocked="The hold is only accusation until the papers put names to it."; FlagsSet=@("FL_sabine_reveal_ready"); InkKnot="act_ii_cargo_hold" }
        )
    },
    @{
        Id="sabine_office_return"; Script="SabineOfficeReturn"; Code="R12B"; Title="Sabine's Office, Return"; Notes="Act II reveal. Sabine signed for Corvin's death and gives fact, not reason."; Background="Color(0.164706, 0.227451, 0.25098, 1)"
        Exits=@(@{ Name="ToCustoms"; Target="CustomsHouse"; Label="Customs House"; X=180; Y=740 })
        Interactions=@(
            @{ Name="SabineDesk"; Key="sabine_desk_return"; Label="Sabine's desk"; X=870; Y=680; Look="Sabine's desk is dry again. Corvin fixes that by existing near it."; Use="Corvin sets the cut paper on the desk. Sabine does not look down. She already knows what it is."; Talk="Sabine says she signed for his death. She gives him the fact and keeps the reason."; Walk="Corvin crosses the Persian and leaves a tide line."; RequiresItems=@("IT_cut_paper","IT_tomas_papers"); Blocked="Corvin needs both the cut paper and the Tomas papers before he can force this conversation."; FlagsSet=@("FL_sabine_signed_revealed","FL_act_ii_complete"); InkKnot="act_ii_sabine_reveal"; BlockedInkKnot="act_ii_sabine_not_ready" },
            @{ Name="DoorOut"; Key="door_out"; Label="door out"; X=1500; Y=710; Look="The door Corvin will use because staying would require a better man."; Use="Corvin leaves before either of them can make the room smaller."; Talk="The door does not apologize either."; Walk="Corvin walks out. Act II knows where to cut."; RequiresFlags=@("FL_act_ii_complete"); Blocked="The argument has not landed yet."; FlagsSet=@("FL_act_ii_walkout"); InkKnot="act_ii_walkout" }
        )
    }
)

$roomScriptPath = "res://game/rooms/act_i_greybox_room.gd"
$exitScriptPath = "res://game/rooms/act_i_exit_hotspot.gd"
$interactionScriptPath = "res://game/rooms/act_i_interaction_hotspot.gd"
$hudPath = "res://game/ui/prologue_hud.tscn"

foreach ($room in $rooms) {
    $dir = Join-Path $root "game\rooms\$($room.Id)"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $scenePath = Join-Path $dir "room_$($room.Id).tscn"
    $dataPath = Join-Path $dir "room_$($room.Id).tres"
    $statePath = Join-Path $dir "room_$($room.Id)_state.gd"

    $subResources = New-Object System.Collections.Generic.List[string]
    $exitNodes = New-Object System.Collections.Generic.List[string]
    $interactionNodes = New-Object System.Collections.Generic.List[string]
    $shapeIndex = 1

    foreach ($exit in $room.Exits) {
        $shapeId = "RectangleShape2D_exit_$shapeIndex"
        $subResources.Add("[sub_resource type=`"RectangleShape2D`" id=`"$shapeId`"]`nsize = Vector2(240, 180)`n")
        $exitNodes.Add(@"

[node name="$($exit.Name)" type="Area2D" parent="Hotspots"]
position = Vector2($($exit.X), $($exit.Y))
script = ExtResource("3_exit")
script_name = $(Format-GodotString $exit.Name)
description = $(Format-GodotString $exit.Label)
target_room = $(Format-GodotString $exit.Target)
requires_flags = $(Format-GodotStringArray $exit.RequiresFlags)
requires_items = $(Format-GodotStringArray $exit.RequiresItems)
blocked_text = $(Format-GodotString $exit.Blocked)
look_text = $(Format-GodotString "$($exit.Label). The way through is visible. That does not make it innocent.")
use_text = $(Format-GodotString "Corvin considers using the exit as evidence. It declines.")
talk_text = $(Format-GodotString "Corvin tells the exit to wait. It does.")
walk_text = $(Format-GodotString "Corvin heads for $($exit.Label).")

[node name="Shape" type="CollisionShape2D" parent="Hotspots/$($exit.Name)"]
shape = SubResource("$shapeId")

[node name="Label" type="Label" parent="Hotspots/$($exit.Name)"]
offset_left = -96.0
offset_top = -118.0
offset_right = 156.0
offset_bottom = -82.0
theme_override_colors/font_color = Color(0.894118, 0.862745, 0.784314, 1)
text = $(Format-GodotString $exit.Label)
"@)
        $shapeIndex += 1
    }

    foreach ($interaction in $room.Interactions) {
        $shapeId = "RectangleShape2D_interaction_$shapeIndex"
        $subResources.Add("[sub_resource type=`"RectangleShape2D`" id=`"$shapeId`"]`nsize = Vector2(280, 160)`n")
        $interactionNodes.Add(@"

[node name="$($interaction.Name)" type="Area2D" parent="Hotspots"]
position = Vector2($($interaction.X), $($interaction.Y))
script = ExtResource("4_interaction")
script_name = $(Format-GodotString $interaction.Name)
description = $(Format-GodotString $interaction.Label)
interaction_key = $(Format-GodotString $interaction.Key)
requires_items = $(Format-GodotStringArray $interaction.RequiresItems)
requires_flags = $(Format-GodotStringArray $interaction.RequiresFlags)
items_add = $(Format-GodotStringArray $interaction.ItemsAdd)
flags_set = $(Format-GodotStringArray $interaction.FlagsSet)
confessions_discover = $(Format-GodotStringArray $interaction.ConfessionsDiscover)
confessions_spend = $(Format-GodotStringArray $interaction.ConfessionsSpend)
wet_items_add = Array[String]([])
wet_flags_set = Array[String]([])
wet_confessions_discover = Array[String]([])
wet_confessions_spend = Array[String]([])
wet_ink_knot = ""
duel_opponent = ""
duel_pool = Array[String]([])
ink_knot = $(Format-GodotString $interaction.InkKnot)
blocked_ink_knot = $(Format-GodotString $interaction.BlockedInkKnot)
alternate_requires_flags = Array[String]([])
alternate_message = ""
alternate_flags_set = Array[String]([])
alternate_ink_knot = ""
blocked_text = $(Format-GodotString $interaction.Blocked)
look_text = $(Format-GodotString $interaction.Look)
use_text = $(Format-GodotString $interaction.Use)
talk_text = $(Format-GodotString $interaction.Talk)
walk_text = $(Format-GodotString $interaction.Walk)
wet_text = $(Format-GodotString "Corvin drips on it. Mordida makes a note and charges nobody.")

[node name="Shape" type="CollisionShape2D" parent="Hotspots/$($interaction.Name)"]
shape = SubResource("$shapeId")

[node name="Label" type="Label" parent="Hotspots/$($interaction.Name)"]
offset_left = -110.0
offset_top = -104.0
offset_right = 190.0
offset_bottom = -66.0
theme_override_colors/font_color = Color(0.788235, 0.541176, 0.235294, 1)
text = $(Format-GodotString $interaction.Label)
"@)
        $shapeIndex += 1
    }

    $scene = @"
[gd_scene load_steps=$($room.Exits.Count + $room.Interactions.Count + 7) format=3]

[ext_resource type="Script" path="$roomScriptPath" id="1_room"]
[ext_resource type="PackedScene" path="$hudPath" id="2_hud"]
[ext_resource type="Script" path="$exitScriptPath" id="3_exit"]
[ext_resource type="Script" path="$interactionScriptPath" id="4_interaction"]

[sub_resource type="Gradient" id="Gradient_bg"]
offsets = PackedFloat32Array(0, 0.58, 1)
colors = PackedColorArray(0.0470588, 0.0627451, 0.0745098, 1, 0.164706, 0.227451, 0.25098, 1, 0.494118, 0.607843, 0.305882, 1)

[sub_resource type="GradientTexture2D" id="GradientTexture2D_bg"]
gradient = SubResource("Gradient_bg")
width = 1920
height = 1080
fill_from = Vector2(0.5, 0)
fill_to = Vector2(0.5, 1)

$($subResources -join "`n")
[node name="Room$($room.Script)" type="Node2D"]
script = ExtResource("1_room")
script_name = $(Format-GodotString $room.Script)
has_player = true
width = 1920
height = 1080
room_code = $(Format-GodotString $room.Code)
room_title = $(Format-GodotString $room.Title)
room_notes = $(Format-GodotString $room.Notes)

[node name="Background" type="Sprite2D" parent="."]
texture = SubResource("GradientTexture2D_bg")
centered = false

[node name="Floor" type="Polygon2D" parent="."]
color = Color(0.164706, 0.227451, 0.25098, 0.65)
polygon = PackedVector2Array(0, 700, 1920, 620, 1920, 1080, 0, 1080)

[node name="TitleLabel" type="Label" parent="."]
offset_left = 48.0
offset_top = 44.0
offset_right = 1120.0
offset_bottom = 96.0
theme_override_colors/font_color = Color(0.894118, 0.862745, 0.784314, 1)
text = $(Format-GodotString "$($room.Code) / $($room.Title)")

[node name="NotesLabel" type="Label" parent="."]
offset_left = 48.0
offset_top = 100.0
offset_right = 1320.0
offset_bottom = 176.0
theme_override_colors/font_color = Color(0.788235, 0.541176, 0.235294, 1)
text = $(Format-GodotString $room.Notes)

[node name="WalkableAreas" type="Node2D" parent="."]

[node name="WalkableMain" type="Polygon2D" parent="WalkableAreas"]
color = Color(0.494118, 0.607843, 0.305882, 0.35)
polygon = PackedVector2Array(160, 810, 1720, 760, 1810, 1025, 120, 1030)

[node name="Props" type="Node2D" parent="."]

[node name="Hotspots" type="Node2D" parent="."]
$($exitNodes -join "`n")
$($interactionNodes -join "`n")

[node name="Regions" type="Node2D" parent="."]

[node name="Markers" type="Node2D" parent="."]

[node name="PlayerStart" type="Marker2D" parent="Markers"]
position = Vector2(960, 790)

[node name="Characters" type="Node2D" parent="."]

[node name="PrologueHud" parent="." instance=ExtResource("2_hud")]
"@

    Write-Utf8NoBom -Path $scenePath -Value $scene

    $data = @"
[gd_resource type="Resource" script_class="PopochiuRoomData" load_steps=2 format=3]

[ext_resource type="Script" path="res://addons/popochiu/engine/objects/room/popochiu_room_data.gd" id="1_data"]

[resource]
script = ExtResource("1_data")
script_name = $(Format-GodotString $room.Script)
scene = "res://game/rooms/$($room.Id)/room_$($room.Id).tscn"
"@
    Write-Utf8NoBom -Path $dataPath -Value $data

    $state = @"
@tool
extends PopochiuRoomData

var visited_for_act_ii := false
"@
    Write-Utf8NoBom -Path $statePath -Value $state
}

Write-Host "Generated $($rooms.Count) Act II greybox room scaffolds."
