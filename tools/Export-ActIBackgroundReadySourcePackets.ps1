$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$acquisitionPath = Join-Path $root "docs\art\act_i_background_source_acquisition.json"
$promptsPath = Join-Path $root "docs\art\act_i_background_source_prompts.json"
$packetDirRelative = "docs/art/generation_packets/act_i_background_ready_sources"
$packetDir = Join-Path $root ($packetDirRelative -replace "/", "\")
$jsonPath = Join-Path $root "docs\art\act_i_background_ready_source_packets.json"
$csvPath = Join-Path $root "docs\art\act_i_background_ready_source_packets.csv"
$mdPath = Join-Path $root "docs\art\act_i_background_ready_source_packets.md"

foreach ($path in @($acquisitionPath, $promptsPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I ready-source packet input: $path"
    }
}

$acquisition = Get-Content -LiteralPath $acquisitionPath -Raw | ConvertFrom-Json
$prompts = Get-Content -LiteralPath $promptsPath -Raw | ConvertFrom-Json

$promptById = @{}
foreach ($prompt in @($prompts.prompts)) {
    $promptById[[string]$prompt.id] = $prompt
}

$readyItems = @($acquisition.items | Where-Object { $_.source_status -eq "ready_to_generate" })
$heldItems = @($acquisition.items | Where-Object { $_.source_status -ne "ready_to_generate" })

if (-not (Test-Path -LiteralPath $packetDir -PathType Container)) {
    New-Item -ItemType Directory -Path $packetDir -Force | Out-Null
}

$packets = @()
foreach ($group in @($readyItems | Group-Object { $_.batch_id } | Sort-Object @{ Expression = { [int](($_.Group[0].room_code) -replace "\D", "") } }, @{ Expression = { [int]$_.Group[0].priority_order } })) {
    $items = @($group.Group | Sort-Object name)
    $first = $items[0]
    $tool = [string]$first.tool
    $packetSlug = ([string]$group.Name).ToLowerInvariant()
    $packetPathRelative = "$packetDirRelative/$packetSlug.md"
    $packetPath = Join-Path $root ($packetPathRelative -replace "/", "\")

    $packetItems = @()
    foreach ($item in $items) {
        if (-not $promptById.ContainsKey([string]$item.id)) {
            throw "Ready-source packet missing prompt for item: $($item.id)"
        }
        $prompt = $promptById[[string]$item.id]
        $packetItems += [ordered]@{
            id = $item.id
            name = $item.name
            kind = $item.kind
            tool = $item.tool
            source_path = $item.source_path
            source_directory = $item.source_directory
            dropzone_readme = $item.dropzone_readme
            placement_target = $item.placement_target
            runtime_policy = $item.runtime_policy
            review_gate = $item.review_gate
            handoff_check = $item.handoff_check
            prompt = $prompt.prompt
            negative_prompt = $prompt.negative_prompt
            output_contract = $prompt.output_contract
        }
    }

    $lines = @(
        "# $($first.room_code) - $($first.room_title) - $tool Ready Source Packet",
        "",
        "Packet ID: $($group.Name)",
        "",
        "Guardrails:",
        "- This packet includes ready-to-generate source assets only.",
        "- Do not generate final background plates from this packet.",
        "- Do not include interactive or navigation PSD work in this packet.",
        "- Save outputs exactly to the listed source paths.",
        "- Run source intake again after files are saved.",
        "",
        "Counts:",
        "- Items: $($packetItems.Count)",
        "- Tool: $tool",
        "",
        "| ID | Source | Drop Zone | Review Gate |",
        "|---|---|---|---|"
    )

    foreach ($packetItem in $packetItems) {
        $lines += "| $($packetItem.id) | ``$($packetItem.source_path)`` | ``$($packetItem.dropzone_readme)`` | $($packetItem.review_gate) |"
    }

    $fence = ([string][char]96) * 3
    $lines += ""
    foreach ($packetItem in $packetItems) {
        $lines += "## $($packetItem.id)"
        $lines += ""
        $lines += "- Source: ``$($packetItem.source_path)``"
        $lines += "- Placement target: ``$($packetItem.placement_target)``"
        $lines += "- Runtime policy: $($packetItem.runtime_policy)"
        $lines += "- Handoff check: $($packetItem.handoff_check)"
        $lines += ""
        $lines += "Prompt:"
        $lines += ""
        $lines += "$($fence)text"
        $lines += $packetItem.prompt
        $lines += $fence
        $lines += ""
        $lines += "Negative prompt:"
        $lines += ""
        $lines += "$($fence)text"
        $lines += $packetItem.negative_prompt
        $lines += $fence
        $lines += ""
        $lines += "Output contract: $($packetItem.output_contract)"
        $lines += ""
    }

    Set-Content -LiteralPath $packetPath -Value $lines -Encoding UTF8

    $packets += [ordered]@{
        packet_id = $group.Name
        packet_path = $packetPathRelative
        room_code = $first.room_code
        room_id = $first.room_id
        room_title = $first.room_title
        tool = $tool
        acquisition_lane = $first.acquisition_lane
        item_count = $packetItems.Count
        source_paths = @($packetItems | ForEach-Object { $_.source_path })
        item_ids = @($packetItems | ForEach-Object { $_.id })
    }
}

$toolCounts = [ordered]@{}
foreach ($group in @($readyItems | Group-Object tool | Sort-Object Name)) {
    $toolCounts[$group.Name] = $group.Count
}

$payload = [ordered]@{
    generated_from = @(
        "docs/art/act_i_background_source_acquisition.json",
        "docs/art/act_i_background_source_prompts.json"
    )
    purpose = "Generation packets for Act I background source items that are safe to acquire before human room review."
    status = "ready_source_packets_generated"
    guardrails = @(
        "Packets include ready-to-generate source assets only.",
        "Packets exclude interactive and navigation PSD work.",
        "Packets must not be used to generate final background plates.",
        "Outputs must be saved exactly to the listed source paths.",
        "Run source intake again after files are saved."
    )
    ready_item_count = $readyItems.Count
    held_item_count = $heldItems.Count
    packet_count = $packets.Count
    tool_counts = $toolCounts
    packet_directory = $packetDirRelative
    packets = $packets
}

$payload | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$csvRows = @()
foreach ($packet in $packets) {
    $csvRows += [pscustomobject]@{
        packet_id = $packet.packet_id
        packet_path = $packet.packet_path
        room_code = $packet.room_code
        room_id = $packet.room_id
        room_title = $packet.room_title
        tool = $packet.tool
        acquisition_lane = $packet.acquisition_lane
        item_count = $packet.item_count
        item_ids = ($packet.item_ids -join ";")
        source_paths = ($packet.source_paths -join ";")
    }
}
$csvRows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$indexLines = @(
    "# Act I Background Ready Source Packets",
    "",
    'Generated by `tools/Export-ActIBackgroundReadySourcePackets.ps1` from acquisition and prompt data.',
    "",
    "Status: $($payload.status). These packets are for source generation, not final art approval.",
    "",
    "Guardrails:",
    "- Packets include ready-to-generate source assets only.",
    "- Packets exclude interactive and navigation PSD work.",
    "- Packets must not be used to generate final background plates.",
    "- Outputs must be saved exactly to the listed source paths.",
    "- Run source intake again after files are saved.",
    "",
    "Counts:",
    "- Ready items: $($payload.ready_item_count)",
    "- Held items excluded: $($payload.held_item_count)",
    "- Packets: $($payload.packet_count)"
)
foreach ($key in @($toolCounts.Keys)) {
    $indexLines += "- ${key}: $($toolCounts[$key])"
}
$indexLines += ""
$indexLines += "| Packet | Tool | Items | Path |"
$indexLines += "|---|---|---:|---|"
foreach ($packet in $packets) {
    $indexLines += "| $($packet.packet_id) | $($packet.tool) | $($packet.item_count) | ``$($packet.packet_path)`` |"
}

Set-Content -LiteralPath $mdPath -Value $indexLines -Encoding UTF8

Write-Host "Exported Act I ready-source packet JSON -> $jsonPath"
Write-Host "Exported Act I ready-source packet CSV -> $csvPath"
Write-Host "Exported Act I ready-source packet index -> $mdPath"
Write-Host "Exported Act I ready-source packet files -> $packetDir"
