$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$templateScript = Join-Path $PSScriptRoot "Validate-VoMinorSpeakerDecisionTemplate.ps1"
$importScript = Join-Path $PSScriptRoot "Import-VoMinorSpeakerDecisions.ps1"
$validateBatchesScript = Join-Path $PSScriptRoot "Validate-VoRecordingBatches.ps1"
$validateQueueScript = Join-Path $PSScriptRoot "Validate-VoRecordingQueue.ps1"
$validatePacketsScript = Join-Path $PSScriptRoot "Validate-VoRecordingPackets.ps1"
$validateAudioStatusScript = Join-Path $PSScriptRoot "Validate-VoAudioAssetStatus.ps1"
$validateCommercialReadinessScript = Join-Path $PSScriptRoot "Validate-VoCommercialReadiness.ps1"
$templateCsv = Join-Path $root "docs\vo\vo_minor_speaker_decisions_template.csv"
$decisionJson = Join-Path $root "docs\vo\vo_minor_speaker_decisions.json"
$importReport = Join-Path $root "docs\vo\vo_minor_speaker_decision_import_report.md"
$testCsv = Join-Path $root "docs\vo\vo_minor_speaker_decisions_test.csv"
$badCsv = Join-Path $root "docs\vo\vo_minor_speaker_decisions_bad_test.csv"

foreach ($path in @($templateScript, $importScript, $validateBatchesScript, $validateQueueScript, $validatePacketsScript, $validateAudioStatusScript, $validateCommercialReadinessScript)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing VO minor speaker decision test dependency: $path"
    }
}

$hadDecisionJson = Test-Path -LiteralPath $decisionJson
$originalDecisionJson = if ($hadDecisionJson) { Get-Content -LiteralPath $decisionJson -Raw } else { "" }
$hadImportReport = Test-Path -LiteralPath $importReport
$originalImportReport = if ($hadImportReport) { Get-Content -LiteralPath $importReport -Raw } else { "" }

try {

& powershell -NoProfile -ExecutionPolicy Bypass -File $templateScript
if ($LASTEXITCODE -ne 0) {
    throw "VO minor speaker template validation failed before import test."
}
if (-not (Test-Path -LiteralPath $templateCsv)) {
    throw "Missing generated VO minor speaker template CSV: $templateCsv"
}

$rows = @(Import-Csv -LiteralPath $templateCsv)
if ($rows.Count -lt 8) {
    throw "Expected at least 8 minor speaker rows for import test, got $($rows.Count)."
}

foreach ($row in $rows) {
    if ($row.speaker -eq "BOOT_SELLER") {
        $row.decision = "cast"
        $row.cast_as = "Boot Seller"
        $row.scratch_voice = "Will"
        $row.scratch_voice_id = "bIHbv24MWmeRgasZH58o"
        $row.notes = "Rough temp only; re-audition before shipping."
    } elseif ($row.speaker -eq "MONGER") {
        $row.decision = "consolidate"
        $row.consolidate_into = "BOOT_SELLER"
        $row.notes = "Small market role can share Boot Seller texture for scratch timing."
    } elseif ($row.speaker -eq "MAN") {
        $row.decision = "cut_or_rewrite"
        $row.notes = "Replace generic crowd man with room-specific named speaker before final VO."
    } else {
        $row.decision = "pending"
    }
}

$rows | Export-Csv -LiteralPath $testCsv -NoTypeInformation -Encoding UTF8

& powershell -NoProfile -ExecutionPolicy Bypass -File $importScript -InputCsv "docs\vo\vo_minor_speaker_decisions_test.csv" -DryRun
if ($LASTEXITCODE -ne 0) {
    throw "VO minor speaker decision dry-run import failed."
}

$badRows = @(Import-Csv -LiteralPath $templateCsv)
foreach ($row in $badRows) {
    if ($row.speaker -eq "BOOT_SELLER") {
        $row.decision = "cast"
        $row.cast_as = "Boot Seller"
        $row.scratch_voice = ""
        $row.scratch_voice_id = ""
    }
}
$badRows | Export-Csv -LiteralPath $badCsv -NoTypeInformation -Encoding UTF8

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$badOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $importScript -InputCsv "docs\vo\vo_minor_speaker_decisions_bad_test.csv" -DryRun 2>&1
$badExit = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference
if ($badExit -eq 0) {
    throw "Bad VO minor speaker decision import unexpectedly passed."
}
if (($badOutput -join "`n") -notmatch "marked cast must include scratch_voice") {
    throw "Bad VO minor speaker decision import failed for the wrong reason: $($badOutput -join ' ')"
}

$badRows = @(Import-Csv -LiteralPath $templateCsv)
foreach ($row in $badRows) {
    if ($row.speaker -eq "BOOT_SELLER") {
        $row.decision = "cast"
        $row.cast_as = "Boot Seller"
        $row.scratch_voice = "Will"
        $row.scratch_voice_id = "bIHbv24MWmeRgasZH58o"
        $row.notes = ""
    }
}
$badRows | Export-Csv -LiteralPath $badCsv -NoTypeInformation -Encoding UTF8

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$badOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $importScript -InputCsv "docs\vo\vo_minor_speaker_decisions_bad_test.csv" -DryRun 2>&1
$badExit = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference
if ($badExit -eq 0) {
    throw "VO minor speaker decision import should reject non-pending rows without rationale notes."
}
if (($badOutput -join "`n") -notmatch "must include notes explaining") {
    throw "VO minor speaker decision import notes negative control failed for the wrong reason: $($badOutput -join ' ')"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $importScript -InputCsv "docs\vo\vo_minor_speaker_decisions_test.csv" -Apply
if ($LASTEXITCODE -ne 0) {
    throw "VO minor speaker decision apply import failed."
}
if (-not (Test-Path -LiteralPath $decisionJson)) {
    throw "VO minor speaker decision apply did not write durable decision JSON."
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $validateBatchesScript
if ($LASTEXITCODE -ne 0) {
    throw "VO recording batch validation failed after applied minor-speaker decisions."
}
$batchManifest = Get-Content -LiteralPath (Join-Path $root "docs\vo\vo_recording_batches.json") -Raw | ConvertFrom-Json
$bootBatches = @($batchManifest.batches | Where-Object { $_.speaker -eq "BOOT_SELLER" })
$mongerBatches = @($batchManifest.batches | Where-Object { $_.speaker -eq "MONGER" })
$manBatches = @($batchManifest.batches | Where-Object { $_.speaker -eq "MAN" })
if (@($bootBatches | Where-Object { $_.cast_status -ne "scratch_cast" -or $_.scratch_voice -ne "Will" }).Count -gt 0) {
    throw "Applied BOOT_SELLER cast decision was not honored by regenerated VO batches."
}
if (@($mongerBatches | Where-Object { $_.cast_status -ne "scratch_cast" -or $_.scratch_voice -ne "Will" }).Count -gt 0) {
    throw "Applied MONGER consolidation decision was not honored by regenerated VO batches."
}
if (@($manBatches | Where-Object { $_.cast_status -ne "blocked_cut_or_rewrite" }).Count -gt 0) {
    throw "Applied MAN cut/rewrite decision was not honored by regenerated VO batches."
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $validateQueueScript
if ($LASTEXITCODE -ne 0) {
    throw "VO recording queue validation failed after applied minor-speaker decisions."
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $validatePacketsScript
if ($LASTEXITCODE -ne 0) {
    throw "VO recording packet validation failed after applied minor-speaker decisions."
}
& powershell -NoProfile -ExecutionPolicy Bypass -File $validateAudioStatusScript
if ($LASTEXITCODE -ne 0) {
    throw "VO audio asset status validation failed after applied minor-speaker decisions."
}
& powershell -NoProfile -ExecutionPolicy Bypass -File $validateCommercialReadinessScript
if ($LASTEXITCODE -ne 0) {
    throw "VO commercial readiness validation failed after applied minor-speaker decisions."
}
$packetIndex = Get-Content -LiteralPath (Join-Path $root "docs\vo\vo_recording_packets_index.json") -Raw | ConvertFrom-Json
$packetRows = @($packetIndex.packets)
$audioStatus = Get-Content -LiteralPath (Join-Path $root "docs\vo\vo_audio_asset_status.json") -Raw | ConvertFrom-Json
$commercialReadiness = Get-Content -LiteralPath (Join-Path $root "docs\vo\vo_commercial_readiness.json") -Raw | ConvertFrom-Json
if (@($packetRows | Where-Object { $_.speaker -eq "BOOT_SELLER" }).Count -eq 0) {
    throw "Applied BOOT_SELLER cast decision did not produce scratch-ready recording packets."
}
if (@($packetRows | Where-Object { $_.speaker -eq "MONGER" }).Count -eq 0) {
    throw "Applied MONGER consolidation decision did not produce scratch-ready recording packets."
}
if (@($packetRows | Where-Object { $_.speaker -eq "MAN" }).Count -ne 0) {
    throw "Applied MAN cut/rewrite decision incorrectly produced scratch-ready recording packets."
}
if ([int]$audioStatus.cut_rewrite_blocked_expected_count -le 0) {
    throw "Applied MAN cut/rewrite decision did not create blocked cut/rewrite audio expectations."
}
if (@($audioStatus.lines | Where-Object { $_.speaker -eq "MAN" -and $_.recording_queue_status -ne "blocked_cut_or_rewrite" }).Count -ne 0) {
    throw "Applied MAN cut/rewrite audio rows were not marked blocked_cut_or_rewrite."
}
if ([int]$commercialReadiness.cut_rewrite_blocked_speaker_count -le 0) {
    throw "Applied MAN cut/rewrite decision did not surface in VO commercial readiness."
}
if ([int]$commercialReadiness.needs_cast_decision_count + [int]$commercialReadiness.cut_rewrite_blocked_speaker_count -ne [int]$commercialReadiness.minor_speaker_work_blocked_count) {
    throw "VO commercial readiness minor-speaker work blocker count is inconsistent after applied decisions."
}

Remove-Item -LiteralPath $testCsv -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $badCsv -Force -ErrorAction SilentlyContinue

}
finally {
    if ($hadDecisionJson) {
        Set-Content -LiteralPath $decisionJson -Value $originalDecisionJson -Encoding UTF8
    } else {
        Remove-Item -LiteralPath $decisionJson -Force -ErrorAction SilentlyContinue
    }
    if ($hadImportReport) {
        Set-Content -LiteralPath $importReport -Value $originalImportReport -Encoding UTF8
    } else {
        Remove-Item -LiteralPath $importReport -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $testCsv -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $badCsv -Force -ErrorAction SilentlyContinue
    & powershell -NoProfile -ExecutionPolicy Bypass -File $validateBatchesScript
    if ($LASTEXITCODE -ne 0) {
        throw "VO recording batch validation failed while restoring after minor-speaker decision test."
    }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $validateQueueScript
    if ($LASTEXITCODE -ne 0) {
        throw "VO recording queue validation failed while restoring after minor-speaker decision test."
    }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $validatePacketsScript
    if ($LASTEXITCODE -ne 0) {
        throw "VO recording packet validation failed while restoring after minor-speaker decision test."
    }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $validateAudioStatusScript
    if ($LASTEXITCODE -ne 0) {
        throw "VO audio asset status validation failed while restoring after minor-speaker decision test."
    }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $validateCommercialReadinessScript
    if ($LASTEXITCODE -ne 0) {
        throw "VO commercial readiness validation failed while restoring after minor-speaker decision test."
    }
}

Write-Host "VO minor speaker decision import test passed: dry-run/apply writes durable decisions, regeneration honors batches/queues/packets/audio/commercial readiness, blocked cut/rewrite batches stay unpacketed, and incomplete cast rows fail."
