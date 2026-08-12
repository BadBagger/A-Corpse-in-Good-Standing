$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\corvin_side_priority_work_order.json"
$csvPath = Join-Path $root "docs\art\corvin_side_priority_work_order.csv"
$mdPath = Join-Path $root "docs\art\corvin_side_priority_work_order.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-CorvinSidePriorityWorkOrder.ps1")

foreach ($path in @($jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Corvin side-priority work order artifact: $path"
    }
}

$payload = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$report = Get-Content -LiteralPath $mdPath -Raw
$workOrder = @($payload.work_order)

if ($payload.status -ne "side_runtime_present_next_sheets_pending") {
    throw "Corvin side-priority work order has unexpected status: $($payload.status)"
}
if ($rows.Count -ne 20 -or $workOrder.Count -ne 20 -or $payload.counts.total -ne 20) {
    throw "Corvin side-priority work order expected 20 rows, got csv=$($rows.Count), json=$($workOrder.Count), total=$($payload.counts.total)."
}
if ($payload.counts.present -ne 8 -or $payload.counts.pending -ne 12) {
    throw "Corvin side-priority counts expected 8 present and 12 pending, got present=$($payload.counts.present), pending=$($payload.counts.pending)."
}
if ($payload.counts.runtime_present -ne 8 -or $payload.counts.next_pending -ne 12) {
    throw "Corvin side-priority expected 8 runtime-present rows and 12 next-pending rows, got runtime=$($payload.counts.runtime_present), next=$($payload.counts.next_pending)."
}

$allowedDirections = @("side_right", "side_left")
$allowedAnimations = @("idle", "walk", "talk", "use", "wet")
$allowedKinds = @("sheet_export", "godot_import")
foreach ($row in $rows) {
    if ($row.variant -ne "act_i_clean") {
        throw "Corvin side-priority work order must only target act_i_clean, got $($row.variant)."
    }
    if ($row.direction -notin $allowedDirections) {
        throw "Corvin side-priority work order contains non-side direction: $($row.direction)."
    }
    if ($row.animation -notin $allowedAnimations) {
        throw "Corvin side-priority work order contains unexpected animation: $($row.animation)."
    }
    if ($row.asset_kind -notin $allowedKinds) {
        throw "Corvin side-priority work order contains unexpected asset kind: $($row.asset_kind)."
    }
    if ($row.status -notin @("present", "pending")) {
        throw "Corvin side-priority work order contains unexpected status: $($row.status)."
    }
    if ([string]::IsNullOrWhiteSpace($row.relative_path) -or $row.relative_path -match "\\") {
        throw "Corvin side-priority work order path must be repo-relative with forward slashes: $($row.relative_path)"
    }
}

$presentRuntime = @($rows | Where-Object { $_.priority -eq "P0_polish_runtime_candidate" -and $_.status -eq "present" })
$pendingNext = @($rows | Where-Object { $_.priority -eq "P1_next_side_sheet" -and $_.status -eq "pending" })
if ($presentRuntime.Count -ne 8) {
    throw "Corvin side-priority work order expected 8 present runtime polish rows, got $($presentRuntime.Count)."
}
if ($pendingNext.Count -ne 12) {
    throw "Corvin side-priority work order expected 12 pending next side-sheet rows, got $($pendingNext.Count)."
}

foreach ($required in @(
    "idle_side_right",
    "idle_side_left",
    "walk_side_right",
    "walk_side_left",
    "talk_side_right",
    "talk_side_left",
    "use_side_right",
    "use_side_left",
    "wet_side_right",
    "wet_side_left"
)) {
    if ($report -notmatch [regex]::Escape($required)) {
        throw "Corvin side-priority report missing required animation direction: $required"
    }
}
foreach ($requiredText in @(
    "Corvin Side Priority Work Order",
    "Current playable side locomotion",
    "Next production side sheets",
    "full-VO dialogue",
    "permanent wet verb",
    "Do not use diffusion-per-frame character sheets"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin side-priority report missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @('$(@{', "System.Object[]", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Corvin side-priority report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Corvin side-priority report must stay ASCII-only."
}

Write-Host "Corvin side-priority work order validation passed: rows=$($rows.Count), present=$($payload.counts.present), pending=$($payload.counts.pending)."
