$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "docs\art"
$jsonPath = Join-Path $outDir "act_ii_background_source_worklist.json"
$csvPath = Join-Path $outDir "act_ii_background_source_worklist.csv"
$mdPath = Join-Path $outDir "act_ii_background_source_worklist.md"

function New-SourceItem {
    param(
        [Parameter(Mandatory=$true)][string]$RoomCode,
        [Parameter(Mandatory=$true)][string]$RoomId,
        [Parameter(Mandatory=$true)][string]$RoomTitle,
        [Parameter(Mandatory=$true)][string]$Kind,
        [Parameter(Mandatory=$true)][string]$Name,
        [string[]]$CriticalRoles = @()
    )

    $slug = ($Name.ToLowerInvariant() -replace "[^a-z0-9]+", "_" -replace "^_|_$", "")
    $prefix = "$RoomId`_$Kind`_$slug"

    $route = switch ($Kind) {
        "meshy_source_model" { "source_model_helper_only" }
        "generated_reference" { "reference_board_only" }
        "interactive_layer" { "separate_runtime_sprite_or_hotspot_layer" }
        "navigation_silhouette" { "painted_readability_plus_godot_hotspot" }
        default { throw "Unknown Act II source kind: $Kind" }
    }

    $sourcePath = switch ($Kind) {
        "meshy_source_model" { "art/src/backgrounds/act_ii/source_models/$RoomId/$slug.glb" }
        "generated_reference" { "docs/art/reference/act_ii/$RoomId/$slug.png" }
        "interactive_layer" { "art/src/backgrounds/act_ii/interactive_layers/$RoomId/$slug.psd" }
        "navigation_silhouette" { "art/src/backgrounds/act_ii/navigation_silhouettes/$RoomId/$slug.psd" }
    }

    $runtimePath = switch ($Kind) {
        "interactive_layer" { "game/rooms/$RoomId/props/$slug.png" }
        "navigation_silhouette" { "game/rooms/$RoomId/background/${RoomId}_bg.png" }
        default { "" }
    }

    [pscustomobject]@{
        id = $prefix
        room_code = $RoomCode
        room_id = $RoomId
        room_title = $RoomTitle
        kind = $Kind
        name = $Name
        route = $route
        status = "pending"
        purpose = switch ($Kind) {
            "meshy_source_model" { "Create or collect reusable 3D helper geometry for Blender blockout and paintover reference; never import directly as final room art." }
            "generated_reference" { "Generate or collect mood/material reference only; never import as a final room plate." }
            "interactive_layer" { "Keep as a separate runtime prop or hotspot layer because logic, visibility, or inventory state can change it." }
            "navigation_silhouette" { "Paint readable exits and depth cues while keeping Godot hotspot metadata authoritative." }
        }
        source_path = $sourcePath
        runtime_path = $runtimePath
        critical_roles = $CriticalRoles
    }
}

$rooms = @(
    [pscustomobject]@{
        code = "R13"
        id = "kane_parlour"
        title = "Kane's Parlour"
        meshy = @("coral calcified chair", "wax seal desk", "ledger lectern", "half-flooded floorboards")
        generated = @("calcified black coral material", "green wrong-light reference", "noir office smoke wash")
        interactive = @("Kane's wax seal", "exit door handle", "offer chair")
        navigation = @("door back to port")
        tags = @("occult_noir", "non_explicit")
    },
    [pscustomobject]@{
        code = "R14"
        id = "float_lower"
        title = "Below Decks, The Grey Float"
        meshy = @("steam partition screens", "low bath railings", "Mireille day-eight couch", "warm pipe lattice")
        generated = @("hard-R non-explicit steam silhouettes", "amber unsafe warmth reference", "water condensation wash", "dignified labor staging")
        interactive = @("Mireille memory book", "privacy curtain", "lamp valve")
        navigation = @("stairs to upper Float", "screened private alcove")
        tags = @("hard_r_non_explicit", "adult_labor_agency", "steam_silhouette", "no_cold_girl")
    },
    [pscustomobject]@{
        code = "R15"
        id = "customs_house"
        title = "Customs House"
        meshy = @("customs counter cage", "impossible ledger cabinet", "stamp press", "tide table rack")
        generated = @("wet paper texture", "absinthe ledger glow", "bureaucratic clutter silhouettes")
        interactive = @("cut paper transaction record", "tide table", "forged customs writ slot", "harbor assignment document")
        navigation = @("door to harbor", "stairs to archive shelf")
        tags = @("paper_trail", "no_final_art")
    },
    [pscustomobject]@{
        code = "R16"
        id = "kestrel_wreck"
        title = "The Kestrel at Low Tide"
        meshy = @("broken hull ribs", "tilted cargo hold", "exposed keel beam", "crew-list strongbox")
        generated = @("low tide mud sheen", "bone-white surf foam", "non-explicit wreck body-horror texture")
        interactive = @("Tomas papers strongbox", "crew list", "low tide marker")
        navigation = @("return path to quay", "crawlway into hold")
        tags = @("low_tide", "body_horror_non_explicit")
    },
    [pscustomobject]@{
        code = "R12"
        id = "sabine_office_return"
        title = "Sabine's Office, Return"
        meshy = @("Sabine desk document staging", "window rain bars", "harbor map wall")
        generated = @("cold office after-argument lighting", "wet footprints on Persian rug")
        interactive = @("cut paper on desk", "Sabine ledger drawer")
        navigation = @("door Corvin walks out through")
        tags = @("act_break", "no_apology")
    }
)

$items = New-Object System.Collections.Generic.List[object]
foreach ($room in $rooms) {
    foreach ($name in $room.meshy) {
        $items.Add((New-SourceItem -RoomCode $room.code -RoomId $room.id -RoomTitle $room.title -Kind "meshy_source_model" -Name $name -CriticalRoles @("perspective", "silhouette")))
    }
    foreach ($name in $room.generated) {
        $items.Add((New-SourceItem -RoomCode $room.code -RoomId $room.id -RoomTitle $room.title -Kind "generated_reference" -Name $name -CriticalRoles @("tone", "material")))
    }
    foreach ($name in $room.interactive) {
        $items.Add((New-SourceItem -RoomCode $room.code -RoomId $room.id -RoomTitle $room.title -Kind "interactive_layer" -Name $name -CriticalRoles @("hotspot", "state")))
    }
    foreach ($name in $room.navigation) {
        $items.Add((New-SourceItem -RoomCode $room.code -RoomId $room.id -RoomTitle $room.title -Kind "navigation_silhouette" -Name $name -CriticalRoles @("exit_readability")))
    }
}

$kindCounts = [ordered]@{}
foreach ($group in @($items | Group-Object kind | Sort-Object Name)) {
    $kindCounts[$group.Name] = $group.Count
}

$worklist = [ordered]@{
    generated_from = "docs/act_ii_puzzle_dependency_graph.json"
    purpose = "Concrete Act II background source-art worklist for Meshy helper models, generated references, interactive prop layers, and navigation silhouettes."
    status = "planning_only_pending_act_i_human_review"
    rules = @(
        "Meshy source models are helper assets only and must be brought through Blender/paintover.",
        "Generated references are concept/reference only and must not be imported as final room plates.",
        "Interactive layers must remain separate from baked backgrounds when logic touches them.",
        "Navigation silhouettes are readability tasks; Godot hotspot metadata remains authoritative.",
        "No Act II final art export is accepted before Act I human review.",
        "No final background export is accepted without G9/G10 palette audit.",
        "The Float remains hard-R non-explicit: no explicit sex, no sexualized violence, and no Cold Girl staging."
    )
    room_count = $rooms.Count
    item_count = $items.Count
    room_tags = [ordered]@{}
    kind_counts = $kindCounts
    items = @($items | Sort-Object room_code, kind, name)
}
foreach ($room in $rooms) {
    $worklist.room_tags[$room.id] = $room.tags
}

$worklist | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
$items | Sort-Object room_code, kind, name | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Act II Background Source Worklist")
$lines.Add("")
$lines.Add('Generated by `tools/Export-ActIIBackgroundSourceWorklist.ps1` from `docs/act_ii_puzzle_dependency_graph.json`.')
$lines.Add("")
$lines.Add("Status: planning-only source assets. This is a worklist, not proof that final art exists.")
$lines.Add("")
$lines.Add("Rules:")
foreach ($rule in $worklist.rules) {
    $lines.Add("- $rule")
}
$lines.Add("")
$lines.Add("Counts:")
$lines.Add("- Rooms: $($worklist.room_count)")
$lines.Add("- Items: $($worklist.item_count)")
foreach ($key in $worklist.kind_counts.Keys) {
    $lines.Add("- ${key}: $($worklist.kind_counts[$key])")
}

foreach ($room in @($rooms | Sort-Object code)) {
    $tagText = $room.tags -join '`, `'
    $lines.Add("")
    $lines.Add("## $($room.code) - $($room.title)")
    $lines.Add("")
    $lines.Add(('Tags: `{0}`' -f $tagText))
    $lines.Add("")
    $lines.Add("| ID | Kind | Name | Route | Source | Runtime |")
    $lines.Add("|---|---|---|---|---|---|")
    foreach ($item in @($items | Where-Object { $_.room_id -eq $room.id } | Sort-Object kind, name)) {
        $runtime = if ([string]::IsNullOrWhiteSpace([string]$item.runtime_path)) { "-" } else { $item.runtime_path }
        $lines.Add(('| {0} | {1} | {2} | {3} | `{4}` | `{5}` |' -f $item.id, $item.kind, $item.name, $item.route, $item.source_path, $runtime))
    }
}

$lines | Set-Content -LiteralPath $mdPath -Encoding UTF8

Write-Host "Exported Act II background source worklist JSON -> $jsonPath"
Write-Host "Exported Act II background source worklist CSV -> $csvPath"
Write-Host "Exported Act II background source worklist report -> $mdPath"
