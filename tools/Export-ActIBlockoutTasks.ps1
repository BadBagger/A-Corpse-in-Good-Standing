$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$jsonPath = Join-Path $root "docs\art\act_i_blockout_tasks.json"
$briefPath = Join-Path $root "docs\art\act_i_blockout_tasks.md"

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Missing Act I background manifest: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$rooms = @($manifest.rooms)
if ($rooms.Count -eq 0) {
    throw "Act I background manifest has no rooms."
}

$closeDistance = 90

function Get-RoleTask {
    param(
        [Parameter(Mandatory=$true)]
        $Hotspot
    )

    $roles = @($Hotspot.critical_roles)
    $tasks = @()

    if ("duel" -in $roles) {
        $tasks += "Frame this as a formal duel position while preserving the existing Litany UI flow; do not add a second confession-spend interface."
    }
    if ("wet_verb" -in $roles) {
        $tasks += "Make the wet interaction target visually reachable from Corvin's side-on staging and readable before final paint."
    }
    if ("confession_source" -in $roles) {
        $tasks += "Stage this as an overheard or discovered truth source without making it look like a separate duel interface."
    }
    if ("item_reward" -in $roles) {
        $tasks += "Reserve a clear pickup silhouette and hand-height access path."
    }
    if ("blocked_feedback" -in $roles) {
        $tasks += "Leave space for a readable blocked-state reaction or staging beat."
    }
    if ("conditional_followup" -in $roles) {
        $tasks += "Keep the actor/prop readable for a later revisited interaction state."
    }
    if ("custom_navigation" -in $roles) {
        $tasks += "Signal this as a navigation pull even though it is implemented as a scripted hotspot."
    }
    if ($tasks.Count -eq 0) {
        $tasks += "Keep as room texture unless later script polish makes it progression-critical."
    }

    return @($tasks)
}

$roomTasks = @()
foreach ($room in $rooms) {
    $hotspots = @($room.hotspots)
    $layoutPoints = @()
    foreach ($hotspot in $hotspots) {
        $layoutPoints += [pscustomobject]@{
            name = $hotspot.name
            x = [double]$hotspot.x
            y = [double]$hotspot.y
        }
    }
    foreach ($exit in @($room.exits)) {
        $layoutPoints += [pscustomobject]@{
            name = $exit.name
            x = [double]$exit.x
            y = [double]$exit.y
        }
    }

    $closePairs = @()
    for ($i = 0; $i -lt $layoutPoints.Count; $i++) {
        for ($j = $i + 1; $j -lt $layoutPoints.Count; $j++) {
            $a = $layoutPoints[$i]
            $b = $layoutPoints[$j]
            $dx = [double]$a.x - [double]$b.x
            $dy = [double]$a.y - [double]$b.y
            $distance = [math]::Sqrt(($dx * $dx) + ($dy * $dy))
            if ($distance -lt $closeDistance) {
                $closePairs += [ordered]@{
                    a = $a.name
                    b = $b.name
                    distance_px = [math]::Round($distance, 1)
                }
            }
        }
    }

    $criticalHotspots = @()
    foreach ($hotspot in $hotspots) {
        $roles = @($hotspot.critical_roles)
        if ($roles.Count -eq 0) {
            continue
        }
        $criticalHotspots += [ordered]@{
            name = $hotspot.name
            label = $hotspot.label
            x = [int]$hotspot.x
            y = [int]$hotspot.y
            roles = $roles
            tasks = @(Get-RoleTask $hotspot)
        }
    }

    $navigationTasks = @()
    foreach ($exit in @($room.exits)) {
        $navigationTasks += ("Exit ``{0}`` to ``{1}`` must read as a walkable transition around {2}, {3}." -f $exit.label, $exit.target_room, $exit.x, $exit.y)
    }
    foreach ($navHotspot in @($hotspots | Where-Object { "custom_navigation" -in @($_.critical_roles) })) {
        $navigationTasks += ("Scripted navigation hotspot ``{0}`` must read as a walkable transition around {1}, {2}." -f $navHotspot.label, $navHotspot.x, $navHotspot.y)
    }
    if ($navigationTasks.Count -eq 0) {
        $navigationTasks += "No outgoing navigation required for this room in the Act I greybox contract."
    }

    $roomTasks += [ordered]@{
        room_id = $room.room_id
        room_code = $room.room_code
        title = $room.title
        source_blend = $room.source_blend
        camera = [ordered]@{
            resolution = "$($room.stage.width)x$($room.stage.height)"
            framing = "fixed side-on orthographic adventure-game room"
            walk_band = "y $($room.walk_band.y_min)-$($room.walk_band.y_max)"
        }
        navigation_tasks = $navigationTasks
        critical_hotspots = $criticalHotspots
        close_pair_review = $closePairs
        export_target = $room.export_png
    }
}

$output = [ordered]@{
    generated_from = "docs/art/act_i_background_manifest.json"
    close_pair_threshold_px = $closeDistance
    rooms = $roomTasks
}

$output | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$briefLines = @(
    "# Act I Blender Blockout Tasks",
    "",
    'Generated by `tools/Export-ActIBlockoutTasks.ps1` from `docs/art/act_i_background_manifest.json`.',
    "",
    "These tasks are for greybox/blockout proof, not final paint. A blockout should prove camera framing, navigation, silhouette priority, and hotspot readability before any final background is painted.",
    "",
    "Duel lock: Registrar art may frame the duel, but the accepted Confession Duel format and Litany UI stay unchanged.",
    "",
    "Close-pair threshold: ${closeDistance}px.",
    ""
)

foreach ($room in $roomTasks) {
    $briefLines += "## $($room.room_code) - $($room.title)"
    $briefLines += ""
    $briefLines += "- Source blend: ``$($room.source_blend)``"
    $briefLines += "- Export target: ``$($room.export_target)``"
    $briefLines += "- Camera: $($room.camera.resolution), $($room.camera.framing), walk band $($room.camera.walk_band)"
    $briefLines += ""
    $briefLines += "Navigation:"
    foreach ($task in @($room.navigation_tasks)) {
        $briefLines += "- $task"
    }
    $briefLines += ""
    $briefLines += "Critical hotspots:"
    if (@($room.critical_hotspots).Count -eq 0) {
        $briefLines += "- None beyond room texture and exits."
    } else {
        foreach ($hotspot in @($room.critical_hotspots)) {
            $roleText = @($hotspot.roles) -join ", "
            $briefLines += "- $($hotspot.label) ($($hotspot.x), $($hotspot.y)) - $roleText"
            foreach ($task in @($hotspot.tasks)) {
                $briefLines += "  - $task"
            }
        }
    }
    $briefLines += ""
    $briefLines += "Close-pair review:"
    if (@($room.close_pair_review).Count -eq 0) {
        $briefLines += "- None under ${closeDistance}px."
    } else {
        foreach ($pair in @($room.close_pair_review)) {
            $briefLines += "- $($pair.a) / $($pair.b): $($pair.distance_px)px. Separate with silhouette, lighting, spacing, or a local interaction cluster."
        }
    }
    $briefLines += ""
}

Set-Content -LiteralPath $briefPath -Value $briefLines -Encoding UTF8

Write-Host "Exported Act I blockout task JSON -> $jsonPath"
Write-Host "Exported Act I blockout task brief -> $briefPath"
