$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\corvin_animation_manifest.json"
$statusCsvPath = Join-Path $root "docs\art\corvin_animation_asset_status.csv"
$jsonPath = Join-Path $root "docs\art\corvin_side_priority_work_order.json"
$csvPath = Join-Path $root "docs\art\corvin_side_priority_work_order.csv"
$mdPath = Join-Path $root "docs\art\corvin_side_priority_work_order.md"

foreach ($path in @($manifestPath, $statusCsvPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Corvin side-priority input: $path"
    }
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$statusRows = @(Import-Csv -LiteralPath $statusCsvPath)
$actI = @($manifest.variants | Where-Object { $_.id -eq "act_i_clean" })[0]
if ($null -eq $actI) {
    throw "Corvin side-priority work order requires act_i_clean variant."
}

$sideDirections = @("side_right", "side_left")
$animationPriority = [ordered]@{
    idle = 0
    walk = 1
    talk = 2
    use = 3
    wet = 4
}

$sideSheetSpecs = [ordered]@{
    talk = [ordered]@{
        production_order = 1
        purpose = "Loopable side-view body-language layer for full-VO dialogue while portraits carry facial emotion."
        blender_action = "Corvin_act_i_clean_talk_side"
        source_basis = "Use the canonical Act I clean Blender source and current side idle registration."
        motion_intent = "Small dead-notary conversational motion: chin dip, one shoulder settling low, minimal coat sway, no broad acting."
        frame_beats = @(
            "01 neutral side idle registration frame",
            "02 chin drops and near shoulder sinks one pixel-row equivalent",
            "03 mouth/upper torso emphasis frame while coat hem lags",
            "04 return through neutral with drip held visible",
            "05 opposite micro-settle at shoulder and hand",
            "06 seamless return to frame 01"
        )
        mirror_policy = "Render side_right first, derive side_left by deterministic mirror only if silhouette, coat hang, and drip side remain readable."
        acceptance_checks = @(
            "6 frames at 12 fps, loop true",
            "first and last frame register cleanly for looping",
            "feet remain planted and do not slide",
            "head/shoulder motion reads at 512px sheet cell scale",
            "drip remains visible but does not crawl across the silhouette"
        )
    }
    use = [ordered]@{
        production_order = 2
        purpose = "Generic side-view item interaction for Act I hotspots before bespoke puzzle poses exist."
        blender_action = "Corvin_act_i_clean_use_side"
        source_basis = "Use current side idle as frame 01 and preserve side walk scale."
        motion_intent = "One restrained reach from the damp coat: hand leaves pocket, touches/indicates object, recoils slightly."
        frame_beats = @(
            "01 neutral side idle registration frame",
            "02 elbow lifts under heavy wet sleeve",
            "03 hand reaches forward, wrong shoulder stays low",
            "04 contact/indicate pose with coat hem delayed",
            "05 hand withdraws, sleeve leads",
            "06 torso settles back",
            "07 coat/drip follow-through",
            "08 neutral hold for handoff back to idle"
        )
        mirror_policy = "Render side_right first; mirror side_left only after contact hand remains readable and no prop-specific lighting is baked into the sheet."
        acceptance_checks = @(
            "8 frames at 12 fps, loop false",
            "frame 01 and frame 08 align with idle-side registration",
            "contact frame is the brightest/readable motion pose",
            "no frame moves feet outside the side idle footprint",
            "usable as a generic hotspot response without implying a specific item"
        )
    }
    wet = [ordered]@{
        production_order = 3
        purpose = "Signature wet-verb side-view action showing Corvin weaponizing the fact that he is permanently dripping."
        blender_action = "Corvin_act_i_clean_wet_side"
        source_basis = "Custom required; do not derive from Meshy biped canned motion."
        motion_intent = "Corvin leans and squeezes/drips brine from sleeve or coat hem onto the target, dryly practical rather than magical."
        frame_beats = @(
            "01 neutral side idle registration frame",
            "02 weight shifts forward without foot slide",
            "03 elbow/coat hem lifts to expose drip source",
            "04 brine drop/splash silhouette reaches target zone",
            "05 held drip frame for readability",
            "06 arm lowers and coat follows",
            "07 shoulders settle into wrong-shouldered stance",
            "08 neutral hold for handoff back to idle"
        )
        mirror_policy = "Render both directions or mirror only after confirming the drip arc reads on the correct interaction side in Godot."
        acceptance_checks = @(
            "8 frames at 12 fps, loop false",
            "wet action starts and ends on idle registration",
            "drip/splash is visible without arterial red or off-palette effects",
            "motion reads as physical brine, not magic",
            "does not obscure hotspot feedback or Litany UI"
        )
    }
}

$rows = New-Object System.Collections.Generic.List[object]
foreach ($animation in @($actI.animations | Sort-Object { $animationPriority[[string]$_.id] })) {
    foreach ($directionSpec in @($animation.directions | Where-Object { $_.direction -in $sideDirections })) {
        foreach ($asset in @(
            @{ Kind = "sheet_export"; Path = [string]$directionSpec.sheet_path },
            @{ Kind = "godot_import"; Path = [string]$directionSpec.godot_resource }
        )) {
            $statusRow = @($statusRows | Where-Object {
                $_.variant -eq "act_i_clean" -and
                $_.animation -eq [string]$animation.id -and
                $_.direction -eq [string]$directionSpec.direction -and
                $_.asset_kind -eq $asset.Kind
            })[0]
            if ($null -eq $statusRow) {
                throw "Missing Corvin status row for act_i_clean/$($animation.id)/$($directionSpec.direction)/$($asset.Kind)."
            }

            $priority = if ($animation.id -in @("idle", "walk") -and $statusRow.status -eq "present") {
                "P0_polish_runtime_candidate"
            } else {
                "P1_next_side_sheet"
            }
            $nextAction = if ($priority -eq "P0_polish_runtime_candidate") {
                "Polish timing, foot contact, registration, and drip readability without replacing the accepted runtime bridge."
            } elseif ($asset.Kind -eq "sheet_export") {
                "Render deterministic Blender ink sheet from the canonical Act I clean source."
            } else {
                "Import the matching sheet into Godot after the sheet export exists."
            }

            $rows.Add([pscustomobject]@{
                priority = $priority
                variant = "act_i_clean"
                animation = [string]$animation.id
                direction = [string]$directionSpec.direction
                asset_kind = $asset.Kind
                frames = [int]$animation.frames
                fps = [int]$animation.fps
                loop = [bool]$animation.loop
                status = [string]$statusRow.status
                relative_path = [string]$asset.Path
                next_action = $nextAction
            })
        }
    }
}

$presentCount = @($rows | Where-Object { $_.status -eq "present" }).Count
$pendingCount = @($rows | Where-Object { $_.status -eq "pending" }).Count
$runtimePresent = @($rows | Where-Object { $_.priority -eq "P0_polish_runtime_candidate" -and $_.status -eq "present" }).Count
$nextPending = @($rows | Where-Object { $_.priority -eq "P1_next_side_sheet" -and $_.status -eq "pending" }).Count
$rowArray = @($rows.ToArray())

$payload = [ordered]@{
    generated_from = "docs/art/corvin_animation_manifest.json and docs/art/corvin_animation_asset_status.csv"
    purpose = "Narrow Corvin Act I side-view production work order for the adventure-game camera before front/back and decay variants."
    status = "side_runtime_present_next_sheets_pending"
    rule_locks = @(
        "Side-on adventure-game staging is the Act I production priority.",
        "Do not use diffusion-per-frame character sheets for production animation.",
        "Do not treat present side idle/walk candidates as final polish-approved animation.",
        "Do not start Act II or Act III decay sheets before Act I side talk/use/wet are planned and reviewed."
    )
    side_sheet_specs = $sideSheetSpecs
    counts = [ordered]@{
        total = $rows.Count
        present = $presentCount
        pending = $pendingCount
        runtime_present = $runtimePresent
        next_pending = $nextPending
    }
    work_order = $rowArray
}

$payload | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
$rowArray | ConvertTo-Csv -NoTypeInformation | Set-Content -LiteralPath $csvPath -Encoding UTF8

$lines = @(
    "# Corvin Side Priority Work Order",
    "",
    'Generated by `tools/Export-CorvinSidePriorityWorkOrder.ps1`.',
    "",
    "Purpose: turn the full Corvin production animation contract into the next side-view queue the Act I adventure-game camera actually needs.",
    "",
    "Status: side_runtime_present_next_sheets_pending",
    "Total side-view rows: $($rows.Count)",
    "Present: $presentCount",
    "Pending: $pendingCount",
    "Runtime-present polish rows: $runtimePresent",
    "Next pending side-sheet rows: $nextPending",
    "",
    "Current playable side locomotion:",
    '- `idle_side_right`, `idle_side_left`, `walk_side_right`, and `walk_side_left` have sheet exports and Godot imports.',
    "- These are runtime candidates. They remain subject to timing, registration, foot-contact, and drip-readability polish.",
    "",
    "Next production side sheets:",
    '- `talk_side_right` and `talk_side_left` for body-language during full-VO dialogue.',
    '- `use_side_right` and `use_side_left` for generic Act I item interactions.',
    '- `wet_side_right` and `wet_side_left` for Corvin''s permanent wet verb.',
    "",
    "Side sheet specs:",
    ""
)

foreach ($entry in $sideSheetSpecs.GetEnumerator()) {
    $spec = $entry.Value
    $lines += "### $($entry.Key)"
    $lines += "- Production order: $($spec.production_order)"
    $lines += "- Purpose: $($spec.purpose)"
    $lines += "- Blender action: ``$($spec.blender_action)``"
    $lines += "- Source basis: $($spec.source_basis)"
    $lines += "- Motion intent: $($spec.motion_intent)"
    $lines += "- Mirror policy: $($spec.mirror_policy)"
    $lines += "- Frame beats:"
    foreach ($beat in @($spec.frame_beats)) {
        $lines += "  - $beat"
    }
    $lines += "- Acceptance checks:"
    foreach ($check in @($spec.acceptance_checks)) {
        $lines += "  - $check"
    }
    $lines += ""
}

$lines += @(
    "",
    "Rule locks:",
    "- Side-on adventure-game staging is the Act I production priority.",
    "- Do not use diffusion-per-frame character sheets for production animation.",
    "- Do not treat present side idle/walk candidates as final polish-approved animation.",
    "- Do not start Act II or Act III decay sheets before Act I side talk/use/wet are planned and reviewed.",
    "",
    "| Priority | Animation | Direction | Asset | Frames | FPS | Loop | Status | Path |",
    "|---|---|---|---|---:|---:|---|---|---|"
)

foreach ($row in $rows) {
    $lines += "| $($row.priority) | $($row.animation) | $($row.direction) | $($row.asset_kind) | $($row.frames) | $($row.fps) | $($row.loop) | $($row.status) | ``$($row.relative_path)`` |"
}

Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

Write-Host "Exported Corvin side-priority work order JSON -> $jsonPath"
Write-Host "Exported Corvin side-priority work order CSV -> $csvPath"
Write-Host "Exported Corvin side-priority work order report -> $mdPath"
Write-Host "Corvin side-priority work order: total=$($rows.Count), present=$presentCount, pending=$pendingCount, runtime=$runtimePresent, next=$nextPending"
