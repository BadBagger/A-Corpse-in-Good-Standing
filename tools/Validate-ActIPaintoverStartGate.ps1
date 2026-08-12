$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-ActIPaintoverStartGate.ps1"
$jsonPath = Join-Path $root "docs\art\act_i_paintover_start_gate.json"
$mdPath = Join-Path $root "docs\art\act_i_paintover_start_gate.md"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing Act I paintover start gate exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Act I paintover start gate export failed."
}

foreach ($path in @($jsonPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing generated Act I paintover start gate artifact: $path"
    }
}

$gate = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rooms = @($gate.rooms)
if ($rooms.Count -ne 11) {
    throw "Act I paintover start gate expected 11 rooms, got $($rooms.Count)."
}

$readyRooms = @($rooms | Where-Object { [bool]$_.ready_for_paintover })
$blockedRooms = @($rooms | Where-Object { -not [bool]$_.ready_for_paintover })
if ([int]$gate.ready_count -ne $readyRooms.Count) {
    throw "Act I paintover start gate ready_count mismatch: json=$($gate.ready_count), actual=$($readyRooms.Count)."
}
if ([int]$gate.blocked_count -ne $blockedRooms.Count) {
    throw "Act I paintover start gate blocked_count mismatch: json=$($gate.blocked_count), actual=$($blockedRooms.Count)."
}
if ($gate.status -eq "ready" -and $blockedRooms.Count -ne 0) {
    throw "Act I paintover start gate cannot be ready while blocked rooms remain."
}
if ($gate.status -eq "blocked_pending_human_review" -and $blockedRooms.Count -eq 0) {
    throw "Act I paintover start gate should be ready when no blocked rooms remain."
}
if ($gate.status -notin @("ready", "blocked_pending_human_review")) {
    throw "Act I paintover start gate has invalid status: $($gate.status)."
}

foreach ($room in $rooms) {
    $blockers = @($room.blockers)
    if ([bool]$room.ready_for_paintover) {
        if ($blockers.Count -ne 0) {
            throw "Room $($room.room_id) is ready_for_paintover but still has blockers: $($blockers -join ', ')"
        }
        if ($room.review_status -ne "approved" -or -not [bool]$room.approved_for_paintover) {
            throw "Room $($room.room_id) is ready_for_paintover without approved review state."
        }
        if ([string]::IsNullOrWhiteSpace([string]$room.reviewer) -or [string]::IsNullOrWhiteSpace([string]$room.reviewed_at) -or [string]::IsNullOrWhiteSpace([string]$room.decision_note)) {
            throw "Room $($room.room_id) is ready_for_paintover without reviewer metadata."
        }
        if ([string]::IsNullOrWhiteSpace([string]$room.build_commit)) {
            throw "Room $($room.room_id) is ready_for_paintover without build_commit."
        }
        if ([string]$room.look_target_reviewed -ne "yes") {
            throw "Room $($room.room_id) is ready_for_paintover without look_target_reviewed=yes."
        }
        if ([string]$room.build_commit -notmatch '^(unknown|[0-9a-f]{7,40})$') {
            throw "Room $($room.room_id) has invalid build_commit: $($room.build_commit)"
        }
    } else {
        if ($blockers.Count -eq 0) {
            throw "Room $($room.room_id) is blocked but has no blocker list."
        }
    }
    if ($room.target_paintover_status -notin @("pending", "present")) {
        throw "Room $($room.room_id) has invalid final PSD target status: $($room.target_paintover_status)."
    }
}

$report = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Act I Paintover Start Gate",
    "Status: $($gate.status)",
    "Ready rooms: $($gate.ready_count)",
    "Blocked rooms: $($gate.blocked_count)",
    "Build",
    "Reviewer",
    "Reviewed At",
    "Look Target",
    "expected to remain blocked until human Act I art/readability review signs off"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Act I paintover start gate report missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @("System.Object[]", "@{", "ï»¿", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Act I paintover start gate report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Act I paintover start gate report must stay ASCII-only."
}

Write-Host "Act I paintover start gate validation passed: status=$($gate.status), ready=$($gate.ready_count), blocked=$($gate.blocked_count)."
