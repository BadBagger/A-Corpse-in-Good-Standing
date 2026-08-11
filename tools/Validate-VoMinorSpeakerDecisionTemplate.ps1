$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-VoMinorSpeakerDecisionTemplate.ps1"
$batchManifestPath = Join-Path $root "docs\vo\vo_recording_batches.json"
$csvPath = Join-Path $root "docs\vo\vo_minor_speaker_decisions_template.csv"
$mdPath = Join-Path $root "docs\vo\vo_minor_speaker_decisions_template.md"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing VO minor speaker decision template exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "VO minor speaker decision template export failed."
}

foreach ($path in @($batchManifestPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing VO minor speaker decision template input/artifact: $path"
    }
}

$manifest = Get-Content -LiteralPath $batchManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$batches = @($manifest.batches | ForEach-Object { $_ })
$uncastBatches = @($batches | Where-Object { $_.cast_status -eq "needs_cast_decision" })
$rows = @(Import-Csv -LiteralPath $csvPath)
$report = Get-Content -LiteralPath $mdPath -Raw

$expectedSpeakers = @(
    $uncastBatches |
        Select-Object -ExpandProperty speaker -Unique |
        Sort-Object
)

if ($expectedSpeakers.Count -eq 0) {
    throw "Expected at least one uncast speaker for this stage."
}
if ($rows.Count -ne $expectedSpeakers.Count) {
    throw "Minor speaker decision template expected $($expectedSpeakers.Count) rows, got $($rows.Count)."
}

$seen = @{}
foreach ($row in $rows) {
    $speaker = [string]$row.speaker
    if ([string]::IsNullOrWhiteSpace($speaker)) {
        throw "Minor speaker decision template contains a row without speaker."
    }
    if ($seen.ContainsKey($speaker)) {
        throw "Minor speaker decision template contains duplicate speaker: $speaker"
    }
    $seen[$speaker] = $true
    if ($speaker -notin $expectedSpeakers) {
        throw "Minor speaker decision template has unexpected speaker: $speaker"
    }
    if ($row.decision -ne "pending") {
        throw "Minor speaker decision template should start pending for $speaker, got $($row.decision)."
    }

    $speakerBatches = @($uncastBatches | Where-Object { $_.speaker -eq $speaker })
    $batchCount = $speakerBatches.Count
    $lineCount = ($speakerBatches | Measure-Object -Property line_count -Sum).Sum
    $wordCount = ($speakerBatches | Measure-Object -Property word_count -Sum).Sum
    if ([int]$row.batch_count -ne [int]$batchCount) {
        throw "Batch count mismatch for $speaker."
    }
    if ([int]$row.line_count -ne [int]$lineCount) {
        throw "Line count mismatch for $speaker."
    }
    if ([int]$row.word_count -ne [int]$wordCount) {
        throw "Word count mismatch for $speaker."
    }
    foreach ($batchId in ([string]$row.batch_ids).Split(";", [System.StringSplitOptions]::RemoveEmptyEntries)) {
        if ($batchId -notin @($speakerBatches | Select-Object -ExpandProperty batch_id)) {
            throw "Speaker $speaker references unexpected batch id: $batchId"
        }
    }
}

foreach ($speaker in $expectedSpeakers) {
    if (-not $seen.ContainsKey($speaker)) {
        throw "Minor speaker decision template missing speaker: $speaker"
    }
}

foreach ($requiredText in @(
    "VO Minor Speaker Decision Template",
    "make minor-speaker casting and consolidation decisions explicit",
    "Allowed decisions:",
    "pending",
    "cast",
    "consolidate",
    "cut_or_rewrite",
    "Every non-pending decision requires notes explaining the casting, consolidation, or script-change rationale.",
    "Do not assign narrator/audiobook voices to minor character parts by default.",
    "Do not start scratch generation for batches whose speaker remains pending."
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "VO minor speaker decision template missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @("System.Object[]", "@{", "ÃƒÂ¯Ã‚Â»Ã‚Â¿", "`t")) {
    if ($report.Contains($forbiddenText)) {
        throw "VO minor speaker decision template contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[\x00-\x08\x0B\x0C\x0E-\x1F]") {
    throw "VO minor speaker decision template contains illegal control characters."
}

Write-Host "VO minor speaker decision template validation passed: speakers=$($rows.Count), uncastBatches=$($uncastBatches.Count)."
