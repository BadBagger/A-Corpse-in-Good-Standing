$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$worklistPath = Join-Path $root "docs\art\act_i_background_source_worklist.json"
$jsonPath = Join-Path $root "docs\art\act_i_background_source_prompts.json"
$csvPath = Join-Path $root "docs\art\act_i_background_source_prompts.csv"
$mdPath = Join-Path $root "docs\art\act_i_background_source_prompts.md"

if (-not (Test-Path -LiteralPath $worklistPath)) {
    throw "Missing Act I background source worklist: $worklistPath"
}

$worklist = Get-Content -LiteralPath $worklistPath -Raw | ConvertFrom-Json

function Get-PromptForItem {
    param([Parameter(Mandatory=$true)]$Item)

    $palette = "limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved"
    $room = "$($Item.room_title) on Isla Mordida"

    switch ($Item.kind) {
        "meshy_source_model" {
            return [ordered]@{
                tool = "Meshy"
                prompt = "Create a single reusable 3D source prop for ${room}: $($Item.name). Fixed-camera point-and-click adventure source asset, stylized 1740s occult harbor noir, strong silhouette, simple readable geometry, usable as Blender blockout/paintover reference, neutral grey material groups, no scene floor, no full room, no characters, no text labels. $palette."
                negative_prompt = "whole room, complete environment, final background, camera blur, unreadable tiny detail, modern objects, extra characters, explicit sexual content, arterial red, photoreal gore"
                output_contract = "Download as GLB to $($Item.source_path). Import into Blender only as helper geometry; final room art still comes from greybox plus paintover."
            }
        }
        "generated_reference" {
            return [ordered]@{
                tool = "imagegen"
                prompt = "Reference image only for ${room}: $($Item.name). Produce a mood/texture/silhouette reference board for an ink-and-wash noir point-and-click background. Keep it non-final and non-layout-authoritative. Emphasize material, edge breakup, lighting feel, and palette-safe dressing ideas. $palette."
                negative_prompt = "finished game background, full room plate, new hotspot layout, text UI, readable signage that must become canon, explicit sexual content, arterial red, photorealism"
                output_contract = "Save reference image to $($Item.source_path). Use only as paintover reference; do not import directly as a final background plate."
            }
        }
        "interactive_layer" {
            return [ordered]@{
                tool = "paintover"
                prompt = "Paint a separate interactive layer for ${room}: $($Item.name), centered near $($Item.position). It must read at 1920x1080, align to the existing hotspot, and remain separable from the baked background because roles [$(@($Item.critical_roles) -join ', ')] touch game logic. Transparent background, clean silhouette, palette-audited, no coordinate drift. $palette."
                negative_prompt = "merged into background only, moved hotspot center, decorative ambiguity, extra interactable-looking clutter, explicit sexual content, arterial red without approval"
                output_contract = "Source stays at $($Item.source_path); runtime export target is $($Item.runtime_path). Keep Godot hotspot metadata authoritative."
            }
        }
        "navigation_silhouette" {
            return [ordered]@{
                tool = "paintover"
                prompt = "Paint navigation readability for $room exit: $($Item.name), near $($Item.position). Preserve existing Godot exit metadata and make the destination silhouette legible without adding a separate puzzle object. Integrate into the room paintover and keep walk-band readability intact. $palette."
                negative_prompt = "new route, moved exit, blocked walk band, clickable-looking non-exit clutter, full generated background, explicit sexual content"
                output_contract = "Paintover source note at $($Item.source_path); final visibility is in $($Item.runtime_path). Regenerate hotspot map if coordinates change."
            }
        }
        default {
            throw "Unknown background source worklist kind for prompts: $($Item.kind)"
        }
    }
}

$prompts = @()
foreach ($item in @($worklist.items)) {
    $prompt = Get-PromptForItem $item
    $prompts += [ordered]@{
        id = $item.id
        room_code = $item.room_code
        room_id = $item.room_id
        room_title = $item.room_title
        kind = $item.kind
        name = $item.name
        status = "pending"
        tool = $prompt.tool
        prompt = $prompt.prompt
        negative_prompt = $prompt.negative_prompt
        output_contract = $prompt.output_contract
        source_path = $item.source_path
        runtime_path = $item.runtime_path
    }
}

$toolCounts = [ordered]@{}
foreach ($group in @($prompts | Group-Object { $_["tool"] } | Sort-Object Name)) {
    $toolCounts[$group.Name] = $group.Count
}

$payload = [ordered]@{
    generated_from = "docs/art/act_i_background_source_worklist.json"
    purpose = "Prompt packets for Act I background source tasks, constrained by the locked background element pipeline."
    status = "pending_generation"
    guardrails = @(
        "Meshy prompts create isolated helper GLB props only, never whole room plates.",
        "imagegen prompts create reference boards only, never final background imports.",
        "interactive layer prompts preserve existing hotspot centers and runtime separation.",
        "navigation prompts preserve Godot exit metadata.",
        "Every prompt repeats palette and content-compliance constraints."
    )
    prompt_count = $prompts.Count
    tool_counts = $toolCounts
    prompts = $prompts
}

$payload | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$csvRows = @()
foreach ($prompt in $prompts) {
    $csvRows += [pscustomobject]@{
        id = $prompt.id
        room_code = $prompt.room_code
        room_id = $prompt.room_id
        kind = $prompt.kind
        name = $prompt.name
        tool = $prompt.tool
        status = $prompt.status
        source_path = $prompt.source_path
        runtime_path = $prompt.runtime_path
        prompt = $prompt.prompt
        negative_prompt = $prompt.negative_prompt
        output_contract = $prompt.output_contract
    }
}
$csvRows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$fence = ([string][char]96) * 3
$fenceText = "$($fence)text"

$lines = @(
    "# Act I Background Source Prompts",
    "",
    'Generated by `tools/Export-ActIBackgroundSourcePrompts.ps1` from `docs/art/act_i_background_source_worklist.json`.',
    "",
    "Status: pending generation. These prompts do not approve final art.",
    "",
    "Guardrails:",
    "- Meshy prompts create isolated helper GLB props only, never whole room plates.",
    "- imagegen prompts create reference boards only, never final background imports.",
    "- Interactive layer prompts preserve existing hotspot centers and runtime separation.",
    "- Navigation prompts preserve Godot exit metadata.",
    "- Every prompt repeats palette and content-compliance constraints.",
    "",
    "Counts:",
    "- Prompts: $($payload.prompt_count)"
)

foreach ($key in @($toolCounts.Keys)) {
    $lines += "- ${key}: $($toolCounts[$key])"
}

$lines += ""

foreach ($roomGroup in @($prompts | Group-Object { $_["room_id"] } | Sort-Object @{ Expression = { [int](($_.Group[0]["room_code"]) -replace "\D", "") } })) {
    $roomPrompts = @($roomGroup.Group)
    $first = $roomPrompts[0]
    $lines += "## $($first.room_code) - $($first.room_title)"
    $lines += ""
    foreach ($prompt in @($roomPrompts | Sort-Object { $_["tool"] }, { $_["kind"] }, { $_["name"] })) {
        $lines += "### $($prompt.id)"
        $lines += ""
        $lines += "- Tool: $($prompt.tool)"
        $lines += "- Kind: $($prompt.kind)"
        $lines += "- Source: ``$($prompt.source_path)``"
        if (-not [string]::IsNullOrWhiteSpace([string]$prompt.runtime_path)) {
            $lines += "- Runtime: ``$($prompt.runtime_path)``"
        }
        $lines += ""
        $lines += "Prompt:"
        $lines += ""
        $lines += $fenceText
        $lines += $prompt.prompt
        $lines += $fence
        $lines += ""
        $lines += "Negative prompt:"
        $lines += ""
        $lines += $fenceText
        $lines += $prompt.negative_prompt
        $lines += $fence
        $lines += ""
        $lines += "Output contract: $($prompt.output_contract)"
        $lines += ""
    }
}

Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

Write-Host "Exported Act I background source prompts JSON -> $jsonPath"
Write-Host "Exported Act I background source prompts CSV -> $csvPath"
Write-Host "Exported Act I background source prompts report -> $mdPath"
