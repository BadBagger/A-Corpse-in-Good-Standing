$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$placementPath = Join-Path $root "docs\art\act_i_background_source_placement.json"
$intakePath = Join-Path $root "docs\art\act_i_background_source_intake.json"
$dropzonesPath = Join-Path $root "docs\art\act_i_background_source_dropzones.json"
$jsonPath = Join-Path $root "docs\art\act_i_background_source_acquisition.json"
$csvPath = Join-Path $root "docs\art\act_i_background_source_acquisition.csv"
$mdPath = Join-Path $root "docs\art\act_i_background_source_acquisition.md"

foreach ($path in @($placementPath, $intakePath, $dropzonesPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I background source acquisition input: $path"
    }
}

$placement = Get-Content -LiteralPath $placementPath -Raw | ConvertFrom-Json
$intake = Get-Content -LiteralPath $intakePath -Raw | ConvertFrom-Json
$dropzones = Get-Content -LiteralPath $dropzonesPath -Raw | ConvertFrom-Json

$intakeById = @{}
foreach ($row in @($intake.rows)) {
    $intakeById[[string]$row.id] = $row
}

$dropzoneByDirectory = @{}
foreach ($zone in @($dropzones.dropzones)) {
    $dropzoneByDirectory[[string]$zone.directory_path] = $zone
}

function Get-SourceDirectory {
    param([Parameter(Mandatory=$true)][string]$SourcePath)
    return ($SourcePath -replace "/[^/]+$", "")
}

function Get-AcquisitionRule {
    param([Parameter(Mandatory=$true)][string]$Kind)

    switch ($Kind) {
        "meshy_source_model" {
            return [ordered]@{
                acquisition_phase = "generate_now"
                acquisition_lane = "A_meshy_helper_geometry"
                priority_order = 10
                blocking_rule = "can_acquire_before_human_review"
                handoff_check = "import into the room Blender blockout as helper geometry only"
            }
        }
        "generated_reference" {
            return [ordered]@{
                acquisition_phase = "generate_now"
                acquisition_lane = "B_reference_board"
                priority_order = 20
                blocking_rule = "can_acquire_before_human_review"
                handoff_check = "review as mood or texture reference only, never as a final room plate"
            }
        }
        "interactive_layer" {
            return [ordered]@{
                acquisition_phase = "hold_for_room_approval"
                acquisition_lane = "C_interactive_runtime_layer"
                priority_order = 30
                blocking_rule = "requires_human_room_review_before_source_psd"
                handoff_check = "export separate PNG and verify hotspot alignment in Godot"
            }
        }
        "navigation_silhouette" {
            return [ordered]@{
                acquisition_phase = "hold_for_room_approval"
                acquisition_lane = "D_navigation_readability_layer"
                priority_order = 40
                blocking_rule = "requires_human_room_review_before_source_psd"
                handoff_check = "preserve existing exit metadata and walk-band readability"
            }
        }
        default {
            throw "Unknown acquisition kind: $Kind"
        }
    }
}

$items = @()
foreach ($row in @($placement.rows)) {
    $id = [string]$row.id
    if (-not $intakeById.ContainsKey($id)) {
        throw "Acquisition checklist missing intake row: $id"
    }

    $sourceDirectory = Get-SourceDirectory ([string]$row.source_path)
    if (-not $dropzoneByDirectory.ContainsKey($sourceDirectory)) {
        throw "Acquisition checklist missing drop-zone row for $id at $sourceDirectory"
    }

    $rule = Get-AcquisitionRule ([string]$row.kind)
    $intakeRow = $intakeById[$id]
    $sourceExists = [bool]$intakeRow.source_exists
    $sourceStatus = if ($sourceExists) { "received_unreviewed" } elseif ($rule.acquisition_phase -eq "hold_for_room_approval") { "held_pending_room_review" } else { "ready_to_generate" }
    $batchId = "$($row.room_code)_$($rule.acquisition_lane)"

    $items += [ordered]@{
        id = $id
        batch_id = $batchId
        room_code = $row.room_code
        room_id = $row.room_id
        room_title = $row.room_title
        kind = $row.kind
        tool = $row.tool
        name = $row.name
        acquisition_phase = $rule.acquisition_phase
        acquisition_lane = $rule.acquisition_lane
        priority_order = $rule.priority_order
        blocking_rule = $rule.blocking_rule
        source_status = $sourceStatus
        content_status = $intakeRow.content_status
        source_path = $row.source_path
        source_directory = $sourceDirectory
        dropzone_readme = $dropzoneByDirectory[$sourceDirectory].readme_path
        runtime_path = $row.runtime_path
        placement_target = $row.placement_target
        runtime_policy = $row.runtime_policy
        review_gate = $row.review_gate
        handoff_check = $rule.handoff_check
    }
}

$items = @($items | Sort-Object @{ Expression = { [int](([string]$_["room_code"]) -replace "\D", "") } }, @{ Expression = { [int]$_["priority_order"] } }, @{ Expression = { [string]$_["name"] } })

$rooms = @()
foreach ($roomGroup in @($items | Group-Object { $_["room_id"] } | Sort-Object @{ Expression = { [int](($_.Group[0]["room_code"]) -replace "\D", "") } })) {
    $roomItems = @($roomGroup.Group)
    $first = $roomItems[0]
    $readyNow = @($roomItems | Where-Object { $_["source_status"] -eq "ready_to_generate" }).Count
    $held = @($roomItems | Where-Object { $_["source_status"] -eq "held_pending_room_review" }).Count
    $received = @($roomItems | Where-Object { $_["source_status"] -eq "received_unreviewed" }).Count
    $rooms += [ordered]@{
        room_code = $first.room_code
        room_id = $first.room_id
        room_title = $first.room_title
        total_items = $roomItems.Count
        ready_to_generate = $readyNow
        held_pending_room_review = $held
        received_unreviewed = $received
        lanes = @($roomItems | Group-Object { $_["acquisition_lane"] } | Sort-Object Name | ForEach-Object {
            [ordered]@{
                lane = $_.Name
                count = $_.Count
                source_statuses = @($_.Group | Group-Object { $_["source_status"] } | Sort-Object Name | ForEach-Object { "$($_.Name):$($_.Count)" })
            }
        })
    }
}

$phaseCounts = [ordered]@{}
foreach ($group in @($items | Group-Object { $_["acquisition_phase"] } | Sort-Object Name)) {
    $phaseCounts[$group.Name] = $group.Count
}

$statusCounts = [ordered]@{}
foreach ($group in @($items | Group-Object { $_["source_status"] } | Sort-Object Name)) {
    $statusCounts[$group.Name] = $group.Count
}

$payload = [ordered]@{
    generated_from = @(
        "docs/art/act_i_background_source_placement.json",
        "docs/art/act_i_background_source_intake.json",
        "docs/art/act_i_background_source_dropzones.json"
    )
    purpose = "Per-room acquisition checklist for Act I background source outputs."
    status = "ready_for_source_acquisition"
    guardrails = @(
        "Acquire Meshy helper GLBs and generated reference boards before room approval if useful.",
        "Hold interactive and navigation PSD source work until the room passes human art review.",
        "Do not batch-generate final backgrounds.",
        "Do not create placeholder binary outputs.",
        "A received source file remains unreviewed until intake, placement, and its handoff gate pass."
    )
    item_count = $items.Count
    room_count = $rooms.Count
    phase_counts = $phaseCounts
    status_counts = $statusCounts
    rooms = $rooms
    items = $items
}

$payload | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$csvRows = @()
foreach ($item in $items) {
    $csvRows += [pscustomobject]$item
}
$csvRows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$lines = @(
    "# Act I Background Source Acquisition Checklist",
    "",
    'Generated by `tools/Export-ActIBackgroundSourceAcquisition.ps1` from placement, intake, and drop-zone data.',
    "",
    "Status: $($payload.status). This is source acquisition planning, not final art approval.",
    "",
    "Guardrails:",
    "- Acquire Meshy helper GLBs and generated reference boards before room approval if useful.",
    "- Hold interactive and navigation PSD source work until the room passes human art review.",
    "- Do not batch-generate final backgrounds.",
    "- Do not create placeholder binary outputs.",
    "- A received source file remains unreviewed until intake, placement, and its handoff gate pass.",
    "",
    "Counts:",
    "- Rooms: $($payload.room_count)",
    "- Items: $($payload.item_count)"
)

foreach ($key in @($phaseCounts.Keys)) {
    $lines += "- ${key}: $($phaseCounts[$key])"
}
foreach ($key in @($statusCounts.Keys)) {
    $lines += "- ${key}: $($statusCounts[$key])"
}

$lines += ""

foreach ($room in $rooms) {
    $lines += "## $($room.room_code) - $($room.room_title)"
    $lines += ""
    $lines += "- Total: $($room.total_items)"
    $lines += "- Ready to generate: $($room.ready_to_generate)"
    $lines += "- Held pending room review: $($room.held_pending_room_review)"
    $lines += "- Received unreviewed: $($room.received_unreviewed)"
    $lines += ""
    $lines += "| Lane | Count | Statuses |"
    $lines += "|---|---:|---|"
    foreach ($lane in @($room.lanes)) {
        $lines += "| $($lane.lane) | $($lane.count) | $($lane.source_statuses -join ', ') |"
    }
    $lines += ""
    $lines += "| ID | Tool | Status | Source | Handoff Check |"
    $lines += "|---|---|---|---|---|"
    foreach ($item in @($items | Where-Object { $_["room_id"] -eq $room.room_id })) {
        $lines += "| $($item.id) | $($item.tool) | $($item.source_status) | ``$($item.source_path)`` | $($item.handoff_check) |"
    }
    $lines += ""
}

Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

Write-Host "Exported Act I background source acquisition JSON -> $jsonPath"
Write-Host "Exported Act I background source acquisition CSV -> $csvPath"
Write-Host "Exported Act I background source acquisition report -> $mdPath"
