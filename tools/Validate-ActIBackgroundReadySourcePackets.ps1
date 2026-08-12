$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_background_ready_source_packets.json"
$csvPath = Join-Path $root "docs\art\act_i_background_ready_source_packets.csv"
$mdPath = Join-Path $root "docs\art\act_i_background_ready_source_packets.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-ActIBackgroundReadySourcePackets.ps1")

foreach ($path in @($jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I ready-source packet artifact: $path"
    }
}

$payload = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$brief = Get-Content -LiteralPath $mdPath -Raw
$packets = @($payload.packets)

if ($payload.ready_item_count -ne 43) {
    throw "Act I ready-source packets expected 43 remaining ready Meshy items, got $($payload.ready_item_count)."
}
if ($payload.held_item_count -ne 87) {
    throw "Act I ready-source packets expected 87 non-ready items excluded, got $($payload.held_item_count)."
}
if ($payload.packet_count -ne 11 -or $packets.Count -ne 11 -or $rows.Count -ne 11) {
    throw "Act I ready-source packets expected 11 remaining Meshy room packets, got payload=$($payload.packet_count), json=$($packets.Count), csv=$($rows.Count)."
}

$allIds = @()
foreach ($packet in $packets) {
    $packetPath = Join-Path $root (([string]$packet.packet_path) -replace "/", "\")
    if (-not (Test-Path -LiteralPath $packetPath -PathType Leaf)) {
        throw "Missing Act I ready-source packet file: $($packet.packet_path)"
    }
    if ([string]$packet.tool -ne "Meshy") {
        throw "Remaining ready-source packets must only use Meshy after generated references are received, got $($packet.tool) in $($packet.packet_id)."
    }
    if ([string]$packet.packet_path -match "\\") {
        throw "Ready-source packet path must use forward slashes: $($packet.packet_path)"
    }

    $packetText = Get-Content -LiteralPath $packetPath -Raw
    foreach ($required in @(
        "This packet includes ready-to-generate source assets only.",
        "Do not generate final background plates from this packet.",
        "Do not include interactive or navigation PSD work in this packet.",
        "Save outputs exactly to the listed source paths.",
        "Run source intake again after files are saved."
    )) {
        if ($packetText -notmatch [regex]::Escape($required)) {
            throw "Ready-source packet $($packet.packet_id) missing guardrail: $required"
        }
    }
    if ($packetText -match "held_pending_room_review" -or $packetText -match "\.psd") {
        throw "Ready-source packet $($packet.packet_id) must not include held PSD work."
    }
    foreach ($id in @($packet.item_ids)) {
        $allIds += [string]$id
        if ($packetText -notmatch [regex]::Escape([string]$id)) {
            throw "Ready-source packet $($packet.packet_id) missing item id $id."
        }
    }
}

$duplicates = @($allIds | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
if ($duplicates.Count -gt 0) {
    throw "Ready-source packets contain duplicate item ids: $($duplicates -join ', ')"
}
if ($allIds.Count -ne 43) {
    throw "Ready-source packet item id count expected 43, got $($allIds.Count)."
}

foreach ($required in @(
    "Act I Background Ready Source Packets",
    "Packets include ready-to-generate source assets only.",
    "Packets exclude interactive and navigation PSD work.",
    "Packets must not be used to generate final background plates.",
    "Outputs must be saved exactly to the listed source paths.",
    "Run source intake again after files are saved."
)) {
    if ($brief -notmatch [regex]::Escape($required)) {
        throw "Ready-source packet index missing guardrail: $required"
    }
}

if ($brief -match "[^\u0000-\u007F]") {
    throw "Act I ready-source packet index must stay ASCII-only."
}

Write-Host "Act I ready-source packet validation passed: packets=$($payload.packet_count), readyMeshy=$($payload.ready_item_count), excluded=$($payload.held_item_count), ids=$($allIds.Count)."
