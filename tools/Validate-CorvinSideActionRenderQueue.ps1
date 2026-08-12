$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-CorvinSideActionRenderQueue.ps1"
$jsonPath = Join-Path $root "docs\art\corvin_side_action_render_queue.json"
$mdPath = Join-Path $root "docs\art\corvin_side_action_render_queue.md"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing Corvin side action render queue exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Corvin side action render queue export failed."
}

foreach ($path in @($jsonPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Corvin side action render queue artifact: $path"
    }
}

$queue = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$report = Get-Content -LiteralPath $mdPath -Raw
$rows = @($queue.rows)

if ($queue.status -notin @("pending_deterministic_blender_renders", "partial_pending_review", "render_outputs_present_pending_audit")) {
    throw "Corvin side action render queue has unexpected status: $($queue.status)"
}
if ($rows.Count -ne 6 -or [int]$queue.total_rows -ne 6) {
    throw "Corvin side action render queue expected 6 rows, got $($rows.Count)."
}
if ([int]$queue.cell_width -ne 256 -or [int]$queue.cell_height -ne 512) {
    throw "Corvin side action render queue cell dimensions changed unexpectedly."
}

$expected = @{
    talk = @{ frames = 6; loop = $true; width = 1536 }
    use = @{ frames = 8; loop = $false; width = 2048 }
    wet = @{ frames = 8; loop = $false; width = 2048 }
}

foreach ($animation in @("talk", "use", "wet")) {
    foreach ($direction in @("side_right", "side_left")) {
        $row = @($rows | Where-Object { $_.animation -eq $animation -and $_.direction -eq $direction })[0]
        if ($null -eq $row) {
            throw "Corvin side action render queue missing $animation $direction row."
        }
        if ($row.variant -ne "act_i_clean" -or $row.priority -ne "P1_next_side_sheet") {
            throw "Corvin side action render queue row $animation $direction has wrong variant or priority."
        }
        if ([int]$row.frames -ne [int]$expected[$animation].frames -or [bool]$row.loop -ne [bool]$expected[$animation].loop) {
            throw "Corvin side action render queue row $animation $direction has wrong frames or loop flag."
        }
        if ([int]$row.expected_sheet_width -ne [int]$expected[$animation].width -or [int]$row.expected_sheet_height -ne 512) {
            throw "Corvin side action render queue row $animation $direction has wrong expected sheet dimensions."
        }
        foreach ($target in @($row.sheet_export, $row.godot_import, $row.render_source, $row.shader_source)) {
            if ([string]::IsNullOrWhiteSpace([string]$target) -or [string]$target -match "\\") {
                throw "Corvin side action render queue path must be repo-relative with forward slashes: $target"
            }
        }
        if ($row.sheet_export -notmatch "/$($animation)_$direction\.png$" -or $row.godot_import -notmatch "/$($animation)_$direction\.png$") {
            throw "Corvin side action render queue row $animation $direction has mismatched target paths."
        }
        if ([bool]$row.godot_present -and -not [bool]$row.sheet_present) {
            throw "Corvin side action render queue row $animation $direction has Godot import without sheet export."
        }
        if (@($row.acceptance_checks).Count -lt 5) {
            throw "Corvin side action render queue row $animation $direction lost acceptance checks."
        }
    }
}

$pendingRows = @($rows | Where-Object { $_.status -eq "pending_render" })
if ([int]$queue.pending_render_count -ne $pendingRows.Count) {
    throw "Corvin side action render queue pending count mismatch."
}
if ($pendingRows.Count -eq 6 -and $queue.status -ne "pending_deterministic_blender_renders") {
    throw "Corvin side action render queue should report pending_deterministic_blender_renders while all six rows are pending."
}

foreach ($requiredText in @(
    "Corvin Side Action Render Queue",
    "Do not create placeholder PNGs",
    "Only deterministic Blender renders",
    "Godot imports must be byte-for-byte copied",
    "No arterial red may appear in wet brine frames",
    "talk",
    "use",
    "wet"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin side action render queue report missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @("System.Object[]", "@{", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Corvin side action render queue report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Corvin side action render queue report must stay ASCII-only."
}

Write-Host "Corvin side action render queue validation passed: rows=$($rows.Count), pending=$($queue.pending_render_count), status=$($queue.status)."
