$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$blockoutTasksPath = Join-Path $root "docs\art\act_i_blockout_tasks.json"
$assetStatusPath = Join-Path $root "docs\art\act_i_background_asset_status.csv"
$paletteAuditPath = Join-Path $root "docs\art\act_i_background_palette_audit.csv"
$jsonPath = Join-Path $root "docs\art\act_i_paintover_packet.json"
$briefPath = Join-Path $root "docs\art\act_i_paintover_packet.md"

foreach ($path in @($manifestPath, $blockoutTasksPath, $assetStatusPath, $paletteAuditPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I paintover packet input: $path"
    }
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$blockoutTasks = Get-Content -LiteralPath $blockoutTasksPath -Raw | ConvertFrom-Json
$assetRows = @(Import-Csv -LiteralPath $assetStatusPath)
$paletteRows = @(Import-Csv -LiteralPath $paletteAuditPath)

$palette = [ordered]@{
    bone_paper_white = "#E4DCC8"
    wet_black = "#0C1013"
    harbor_slate = "#2A3A40"
    absinthe_green = "#7D9B4E"
    whale_oil_amber = "#C98A3C"
    arterial_red = "#8E1B22"
    rule = "amber = alive; green = wrong; arterial red <= 5 scenes across the game"
}

function Get-RoomTone {
    param([Parameter(Mandatory=$true)] [string] $RoomId)

    switch ($RoomId) {
        "mudflats" { return "cold dawn mud, low slate horizon, bone ribs as distant readable shapes" }
        "old_quay" { return "wet black pilings, bone bollards, sparse amber lamps, harbor slate negative space" }
        "salt_market" { return "busy public hub, amber life pockets against slate street, boots and queue readable at a glance" }
        "harbor_registry" { return "paper-white ledgers, hard ink shadows, green wrong-light at the desk lamp once wet/smoked" }
        "bone_chandler" { return "bone-white wares in wet-black racks, dusty amber trade counter, no red accents" }
        "almshouse" { return "thin harbor light, salt sheets, low warmth, readable window/cots without softening the rot" }
        "fish_hall" { return "ice table and tag as brightest proof objects, cold slate, minimal amber" }
        "church_of_the_drowned" { return "absinthe-green institutional wrongness, bone paperwork, Church commerce staging" }
        "grey_float" { return "the only unsafe amber room; steam silhouettes and warm privacy without explicit depiction" }
        "harbormaster_office" { return "official amber restraint, frosted glass, checklist as the clearest prop" }
        "sabine_office" { return "controlled authority, wet-black floor reflection, Sabine's desk and wrist-check staging space" }
        default { return "locked palette noir staging; keep puzzle objects brightest in frame" }
    }
}

function Get-InteractionPriority {
    param($Room)

    $roles = @()
    foreach ($hotspot in @($Room.hotspots)) {
        foreach ($role in @($hotspot.critical_roles)) {
            if ($role -notin $roles) {
                $roles += $role
            }
        }
    }
    foreach ($exit in @($Room.exits)) {
        if ("navigation" -notin $roles) {
            $roles += "navigation"
        }
    }
    if ($roles.Count -eq 0) {
        $roles += "room_texture"
    }
    return @($roles)
}

$roomPackets = @()
foreach ($room in @($manifest.rooms)) {
    $taskRoom = @($blockoutTasks.rooms | Where-Object { $_.room_id -eq $room.room_id })[0]
    if ($null -eq $taskRoom) {
        throw "Missing blockout task room for paintover packet: $($room.room_id)"
    }

    $paintoverRow = @($assetRows | Where-Object { $_.room_id -eq $room.room_id -and $_.asset_kind -eq "paintover_source" })[0]
    $paletteRow = @($paletteRows | Where-Object { $_.room_id -eq $room.room_id })[0]
    if ($null -eq $paintoverRow) {
        throw "Missing paintover source row for room: $($room.room_id)"
    }
    if ($null -eq $paletteRow) {
        throw "Missing palette audit row for room: $($room.room_id)"
    }

    $criticalList = @()
    foreach ($hotspot in @($taskRoom.critical_hotspots)) {
        $criticalList += [ordered]@{
            name = $hotspot.name
            label = $hotspot.label
            position = "$($hotspot.x), $($hotspot.y)"
            roles = @($hotspot.roles)
            paintover_note = (@($hotspot.tasks) -join " ")
        }
    }

    $closePairNotes = @()
    foreach ($pair in @($taskRoom.close_pair_review)) {
        $closePairNotes += "$($pair.a) / $($pair.b) at $($pair.distance_px)px"
    }

    $roomPackets += [ordered]@{
        room_id = $room.room_id
        room_code = $room.room_code
        title = $room.title
        source_blend = $room.source_blend
        blockout_export = $room.export_png
        godot_background = $room.godot_background_resource
        paintover_source = $room.paintover_source
        paintover_status = $paintoverRow.status
        review_overlay = $room.review_overlay
        palette_audit = [ordered]@{
            status = $paletteRow.status
            in_gamut_percent = $paletteRow.in_gamut_percent
            arterial_red_pixels = $paletteRow.arterial_red_pixels
            pass = $paletteRow.pass
        }
        camera = [ordered]@{
            resolution = "$($room.stage.width)x$($room.stage.height)"
            walk_band = "y $($room.walk_band.y_min)-$($room.walk_band.y_max)"
            side_on = $true
        }
        tone = Get-RoomTone $room.room_id
        interaction_priorities = @(Get-InteractionPriority $room)
        navigation_notes = @($taskRoom.navigation_tasks)
        critical_hotspots = $criticalList
        close_pair_review = $closePairNotes
        paintover_rules = @(
            "Keep puzzle-relevant objects as the brightest readable shapes in frame.",
            "Do not move hotspot centers without updating the Godot scene and regenerating the hotspot map.",
            "Preserve the y 650-800 walk band as clear navigable ground.",
            "Use only the locked palette family; any exported PNG must pass G9/G10 before shipping.",
            "Do not add explicit sexual imagery; Grey Float stays hard-R through steam, silhouette, labor, and privacy staging."
        )
    }
}

$packet = [ordered]@{
    generated_from = @(
        "docs/art/act_i_background_manifest.json",
        "docs/art/act_i_blockout_tasks.json",
        "docs/art/act_i_background_asset_status.csv",
        "docs/art/act_i_background_palette_audit.csv"
    )
    purpose = "Per-room Act I final-paintover packet derived from validated greybox and art-readiness evidence."
    scope = "Act I only. This does not authorize Acts II-III art pass."
    palette = $palette
    rooms = $roomPackets
}

$packet | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = @(
    "# Act I Paintover Packet",
    "",
    'Generated by `tools/Export-ActIPaintoverPacket.ps1` from the validated Act I background manifest, blockout tasks, asset tracker, and palette audit.',
    "",
    "Scope: Act I only. This packet prepares the Step 5 art pass; it does not claim final paintovers are complete.",
    "",
    "Locked palette: bone/paper white `#E4DCC8`, wet black `#0C1013`, harbor slate `#2A3A40`, absinthe green `#7D9B4E`, whale-oil amber `#C98A3C`, arterial red `#8E1B22`.",
    "",
    "Rules:",
    "- Keep puzzle-relevant objects as the brightest readable shapes in frame.",
    "- Preserve hotspot coordinates unless the Godot room scene is updated and the hotspot map is regenerated.",
    "- Preserve the y 650-800 walk band as clear navigable ground.",
    "- Amber means alive; green means wrong. The Grey Float is the deliberate unsafe amber exception.",
    "- Hard-R line remains locked: steam, silhouette, privacy, and labor staging only; no explicit anatomy.",
    "- Registrar duel art must preserve the accepted Litany UI format; do not add a second confession-spend interface.",
    ""
)

foreach ($room in $roomPackets) {
    $lines += "## $($room.room_code) - $($room.title)"
    $lines += ""
    $lines += "- Blockout: ``$($room.blockout_export)``"
    $lines += "- Godot import: ``$($room.godot_background)``"
    $lines += "- Paintover source: ``$($room.paintover_source)`` ($($room.paintover_status))"
    $lines += "- Overlay: ``$($room.review_overlay)``"
    $lines += "- Palette audit: $($room.palette_audit.status), $($room.palette_audit.in_gamut_percent)% in gamut, arterial red pixels $($room.palette_audit.arterial_red_pixels), pass $($room.palette_audit.pass)"
    $lines += "- Camera: $($room.camera.resolution), fixed side-on, walk band $($room.camera.walk_band)"
    $lines += "- Tone: $($room.tone)"
    $lines += "- Interaction priorities: $((@($room.interaction_priorities) -join ', '))"
    $lines += ""
    $lines += "Navigation:"
    foreach ($note in @($room.navigation_notes)) {
        $lines += "- $note"
    }
    $lines += ""
    $lines += "Critical hotspots:"
    if (@($room.critical_hotspots).Count -eq 0) {
        $lines += "- None beyond room texture and navigation."
    } else {
        foreach ($hotspot in @($room.critical_hotspots)) {
            $lines += "- $($hotspot.label) at $($hotspot.position): $((@($hotspot.roles) -join ', ')). $($hotspot.paintover_note)"
        }
    }
    $lines += ""
    $lines += "Close-pair review:"
    if (@($room.close_pair_review).Count -eq 0) {
        $lines += "- None under the current review threshold."
    } else {
        foreach ($note in @($room.close_pair_review)) {
            $lines += "- $note. Separate through silhouette, value, local shadow, or prop spacing before final paint."
        }
    }
    $lines += ""
}

Set-Content -LiteralPath $briefPath -Value $lines -Encoding UTF8

Write-Host "Exported Act I paintover packet JSON -> $jsonPath"
Write-Host "Exported Act I paintover packet brief -> $briefPath"
