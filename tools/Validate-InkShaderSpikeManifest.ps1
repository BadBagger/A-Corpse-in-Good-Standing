$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\ink_shader_spike_manifest.json"
$briefPath = Join-Path $root "docs\art\ink_shader_spike_brief.md"
$statusCsvPath = Join-Path $root "docs\art\ink_shader_spike_status.csv"
$statusReportPath = Join-Path $root "docs\art\ink_shader_spike_status.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-InkShaderSpikeManifest.ps1")

foreach ($path in @($manifestPath, $briefPath, $statusCsvPath, $statusReportPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing ink shader spike artifact: $path"
    }
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.duel_format_locked -ne $true) {
    throw "Ink shader spike manifest must preserve the duel-format lock."
}
if ($manifest.no_diffusion_per_frame -ne $true) {
    throw "Ink shader spike manifest must forbid diffusion-per-frame production art."
}
if ($manifest.render_contract.fps -ne 12) {
    throw "Ink shader spike render contract must be 12 fps."
}
if ($manifest.render_contract.sequence_frames -lt 24) {
    throw "Ink shader spike render contract must use at least 24 frames."
}
if ($manifest.render_contract.stress_motion -ne "yaw_turn") {
    throw "Ink shader spike must stress hatching with a yaw turn."
}
if ($manifest.render_contract.hatching_space -ne "object_or_world_anchored") {
    throw "Ink shader spike must require object/world-anchored hatching."
}
if ($manifest.render_contract.forbidden_hatching_space -ne "screen_space_only") {
    throw "Ink shader spike must identify screen-space-only hatching as forbidden for production."
}
if ($manifest.render_contract.first_to_last_drift_required -ne $true) {
    throw "Ink shader spike must require a first-to-last drift check."
}
if ([double]$manifest.render_contract.first_to_last_drift_threshold_percent -ne 9.0) {
    throw "Ink shader spike first-to-last drift threshold must remain the provisional 9 percent calibration target."
}
if ([double]$manifest.render_contract.pairwise_delta_threshold_percent -ne 6.0) {
    throw "Ink shader spike pairwise threshold must remain the provisional 6 percent calibration target."
}

$paletteHex = @($manifest.palette | ForEach-Object { $_.hex })
foreach ($requiredHex in @("#E4DCC8", "#0C1013", "#2A3A40", "#7D9B4E", "#C98A3C", "#8E1B22")) {
    if ($requiredHex -notin $paletteHex) {
        throw "Ink shader spike palette missing locked color: $requiredHex"
    }
}

$tests = @($manifest.tests)
if ($tests.Count -ne 7) {
    throw "Ink shader spike test count mismatch: expected 7, got $($tests.Count)"
}
foreach ($requiredGate in @("R1", "R2", "R3", "R4", "R5", "R6", "R7")) {
    if ($requiredGate -notin @($tests | ForEach-Object { $_.gate })) {
        throw "Ink shader spike missing gate: $requiredGate"
    }
}

$objectSequence = @($tests | Where-Object { $_.id -eq "r3_object_anchored_hatching_sequence" })[0]
if ($null -eq $objectSequence -or $objectSequence.frame_count -lt 24 -or $objectSequence.motion -ne "yaw_turn") {
    throw "Ink shader spike object-anchored sequence must be a 24-frame yaw turn."
}
$badControl = @($tests | Where-Object { $_.id -eq "r4_screen_space_bad_control" })[0]
if ($null -eq $badControl -or $badControl.frame_count -lt 24 -or $badControl.motion -ne "yaw_turn") {
    throw "Ink shader spike bad control must be a 24-frame screen-space yaw turn."
}
$pairwise = @($tests | Where-Object { $_.id -eq "r5_pairwise_hatching_delta" })[0]
if ($null -eq $pairwise -or [double]$pairwise.provisional_threshold_percent -ne 6.0) {
    throw "Ink shader spike pairwise delta report must carry the provisional 6 percent threshold."
}
$drift = @($tests | Where-Object { $_.id -eq "r6_first_last_hatching_drift" })[0]
if ($null -eq $drift -or $drift.frame_count -lt 24) {
    throw "Ink shader spike first-to-last drift report must cover the 24-frame sequence."
}

foreach ($test in $tests) {
    foreach ($pathProperty in @("source_path", "output_path")) {
        $value = [string]$test.$pathProperty
        if ([string]::IsNullOrWhiteSpace($value) -or $value -match "\\") {
            throw "Ink shader spike test $($test.id) has invalid $pathProperty path: $value"
        }
    }
}

$statusRows = @(Import-Csv -LiteralPath $statusCsvPath)
if ($statusRows.Count -ne 7) {
    throw "Ink shader spike status row count mismatch: expected 7, got $($statusRows.Count)"
}
foreach ($row in $statusRows) {
    if ($row.status -notin @("present", "pending")) {
        throw "Ink shader spike status has invalid status: $($row.status)"
    }
    if ([string]::IsNullOrWhiteSpace($row.output_path) -or $row.output_path -match "\\") {
        throw "Ink shader spike status has invalid output path: $($row.output_path)"
    }
}

$brief = Get-Content -LiteralPath $briefPath -Raw
$statusReport = Get-Content -LiteralPath $statusReportPath -Raw
foreach ($requiredText in @("Ink Shader Spike Brief", "Duel lock", "24-frame yaw turn", "object-anchored hatching", "known-bad control", "6 percent")) {
    if ($brief -notmatch [regex]::Escape($requiredText)) {
        throw "Ink shader spike brief missing required text: $requiredText"
    }
}
foreach ($requiredText in @("Ink Shader Spike Status", "shader proof tracker", "7 total shader proof slots")) {
    if ($statusReport -notmatch [regex]::Escape($requiredText)) {
        throw "Ink shader spike status report missing required text: $requiredText"
    }
}
foreach ($text in @($brief, $statusReport)) {
    foreach ($forbiddenText in @('$(@{', "`t", "	ools/")) {
        if ($text.Contains($forbiddenText)) {
            throw "Ink shader spike generated report contains malformed Markdown: $forbiddenText"
        }
    }
    if ($text -match "[^\u0000-\u007F]") {
        throw "Ink shader spike generated reports must stay ASCII-only."
    }
}

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Test-InkShaderSpikeMetrics.ps1")

$metricsPath = Join-Path $root "docs\art\ink_shader_spike_metrics_status.json"
$metricsReportPath = Join-Path $root "docs\art\ink_shader_spike_metrics_status.md"
foreach ($path in @($metricsPath, $metricsReportPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing ink shader spike metrics artifact: $path"
    }
}

$metrics = Get-Content -LiteralPath $metricsPath -Raw | ConvertFrom-Json
if ($metrics.status -notin @("pending", "audited")) {
    throw "Ink shader spike metrics status must be pending or audited after validation: $($metrics.status)"
}
if ($metrics.required_frame_count -lt 24) {
    throw "Ink shader spike metrics must require at least 24 frames."
}
if ([double]$metrics.pairwise_threshold_percent -ne 6.0) {
    throw "Ink shader spike metrics must use the provisional 6 percent pairwise threshold."
}
if ([double]$metrics.first_to_last_drift_threshold_percent -ne 9.0) {
    throw "Ink shader spike metrics must use the provisional 9 percent drift threshold."
}

$metricsReport = Get-Content -LiteralPath $metricsReportPath -Raw
foreach ($requiredText in @("Ink Shader Spike Metrics Status", "24-frame yaw-turn renders", "Pairwise threshold", "First-to-last drift threshold")) {
    if ($metricsReport -notmatch [regex]::Escape($requiredText)) {
        throw "Ink shader spike metrics report missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @('$(@{', "`t", "	ools/")) {
    if ($metricsReport.Contains($forbiddenText)) {
        throw "Ink shader spike metrics report contains malformed Markdown: $forbiddenText"
    }
}
if ($metricsReport -match "[^\u0000-\u007F]") {
    throw "Ink shader spike metrics report must stay ASCII-only."
}

Write-Host "Ink shader spike manifest validation passed: tests=$($tests.Count), statusRows=$($statusRows.Count), pending=$(@($statusRows | Where-Object { $_.status -eq 'pending' }).Count)"
