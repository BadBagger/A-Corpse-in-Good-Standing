$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$summaryPath = Join-Path $root "docs\art\ink_shader_spike_still_render_status.json"
$reportPath = Join-Path $root "docs\art\ink_shader_spike_still_render_status.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Render-InkShaderSpikeStills.ps1")

foreach ($path in @($summaryPath, $reportPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing ink shader spike still render artifact: $path"
    }
}

$summary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
if ($summary.status -notin @("pending", "audited")) {
    throw "Ink shader spike still render must be pending or audited after validation: $($summary.status)"
}
if ($summary.timeout_seconds -ne 120) {
    throw "Ink shader spike still render must use a 120 second timeout."
}
if ($summary.raw_output -ne "art/export/shader_spike/corvin_act_i_clean_side_raw.png") {
    throw "Ink shader spike still render has wrong raw output path."
}
if ($summary.ramp_output -ne "art/export/shader_spike/corvin_act_i_clean_side_ink_ramp.png") {
    throw "Ink shader spike still render has wrong ramp output path."
}

if ($summary.status -eq "audited") {
    if ($summary.raw_present -ne $true -or $summary.ramp_present -ne $true) {
        throw "Ink shader spike still render audited but required PNGs are missing."
    }
    if ([int]$summary.raw_width -ne 1920 -or [int]$summary.raw_height -ne 1080) {
        throw "Ink shader spike raw still must be 1920x1080."
    }
    if ([int]$summary.ramp_width -ne 1920 -or [int]$summary.ramp_height -ne 1080) {
        throw "Ink shader spike ramp still must be 1920x1080."
    }
}

$report = Get-Content -LiteralPath $reportPath -Raw
foreach ($requiredText in @("Ink Shader Spike Still Render Status", "R1/R2 still proof", "does not satisfy the R3/R4", "Raw output", "Ramp output")) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Ink shader spike still render report missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @('$(@{', "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Ink shader spike still render report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Ink shader spike still render report must stay ASCII-only."
}

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Test-InkShaderSpikeStillImages.ps1")

$imageAuditPath = Join-Path $root "docs\art\ink_shader_spike_still_image_audit.json"
$imageAuditReportPath = Join-Path $root "docs\art\ink_shader_spike_still_image_audit.md"
foreach ($path in @($imageAuditPath, $imageAuditReportPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing ink shader spike still image audit artifact: $path"
    }
}

$imageAudit = Get-Content -LiteralPath $imageAuditPath -Raw | ConvertFrom-Json
$imageAuditRows = @($imageAudit.rows)
if ($imageAuditRows.Count -ne 2) {
    throw "Ink shader spike still image audit must contain 2 rows."
}
if ([int]$imageAudit.sample_stride -ne 4) {
    throw "Ink shader spike still image audit must use a 4 pixel sample stride."
}
foreach ($row in $imageAuditRows) {
    if ($row.status -notin @("pending", "audited")) {
        throw "Ink shader spike still image audit has invalid status: $($row.status)"
    }
    if ($row.status -eq "audited" -and $row.pass -ne $true) {
        throw "Ink shader spike still image audit failed row: $($row.id)"
    }
}

$imageAuditReport = Get-Content -LiteralPath $imageAuditReportPath -Raw
foreach ($requiredText in @("Ink Shader Spike Still Image Audit", "nonblank visual content", "Palette proximity", "R1 raw side-profile", "R2 two-tone ink ramp")) {
    if ($imageAuditReport -notmatch [regex]::Escape($requiredText)) {
        throw "Ink shader spike still image audit report missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @('$(@{', "`t", "	ools/")) {
    if ($imageAuditReport.Contains($forbiddenText)) {
        throw "Ink shader spike still image audit report contains malformed Markdown: $forbiddenText"
    }
}
if ($imageAuditReport -match "[^\u0000-\u007F]") {
    throw "Ink shader spike still image audit report must stay ASCII-only."
}

Write-Host "Ink shader spike still render validation passed: status=$($summary.status), raw=$($summary.raw_present), ramp=$($summary.ramp_present)"
