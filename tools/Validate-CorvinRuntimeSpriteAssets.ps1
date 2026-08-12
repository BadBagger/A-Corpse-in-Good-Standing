$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "Resolve-Godot.ps1")
$godot = Get-CorpseGodotPath -Kind Console
$statusPath = Join-Path $root "docs\art\corvin_runtime_sprite_assets_status.json"
$reportPath = Join-Path $root "docs\art\corvin_runtime_sprite_assets_status.md"

$spritePaths = @(
    (Join-Path $root "game\characters\corvin\sprites\act_i_clean\idle_side_right.png"),
    (Join-Path $root "game\characters\corvin\sprites\act_i_clean\idle_side_left.png"),
    (Join-Path $root "game\characters\corvin\sprites\act_i_clean\walk_side_right.png"),
    (Join-Path $root "game\characters\corvin\sprites\act_i_clean\walk_side_left.png"),
    (Join-Path $root "game\characters\corvin\sprites\act_i_clean\talk_side_right.png"),
    (Join-Path $root "game\characters\corvin\sprites\act_i_clean\talk_side_left.png"),
    (Join-Path $root "game\characters\corvin\sprites\act_i_clean\use_side_right.png"),
    (Join-Path $root "game\characters\corvin\sprites\act_i_clean\use_side_left.png"),
    (Join-Path $root "game\characters\corvin\sprites\act_i_clean\wet_side_right.png"),
    (Join-Path $root "game\characters\corvin\sprites\act_i_clean\wet_side_left.png")
)
foreach ($spritePath in $spritePaths) {
    if (-not (Test-Path -LiteralPath $spritePath)) {
        throw "Missing Corvin runtime sprite sheet: $spritePath"
    }
}

Push-Location $root
try {
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & $godot --headless --path $root --script "res://tools/godot_validate_corvin_sprite_assets.gd" 2>&1
    $exit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    $output | Write-Host

    $unexpectedErrors = @(
        $output |
            Where-Object { $_ -match "^(SCRIPT ERROR|ERROR):" } |
            Where-Object { $_ -notmatch "RID allocations .* were leaked at exit\.$" } |
            Where-Object { $_ -notmatch "resources still in use at exit" }
    )
    if ($unexpectedErrors.Count -gt 0) {
        throw "Corvin runtime sprite validation produced errors: $($unexpectedErrors -join ' | ')"
    }
    if ($exit -ne 0) {
        throw "Corvin runtime sprite validation failed with exit code $exit"
    }

    $passLine = @($output | Where-Object { $_ -match "Corvin sprite asset validation passed:" })[0]
    if ($null -eq $passLine) {
        throw "Corvin runtime sprite validation did not produce the expected pass line."
    }

    $status = [ordered]@{
        generated_from = "tools/Validate-CorvinRuntimeSpriteAssets.ps1"
        status = "audited"
        godot_path = $godot
        sprite_resources = @(
            [ordered]@{
                resource = "res://game/characters/corvin/sprites/act_i_clean/idle_side_right.png"
                role = "runtime_default"
                width = 3072
                height = 512
                frames = 12
            },
            [ordered]@{
                resource = "res://game/characters/corvin/sprites/act_i_clean/idle_side_left.png"
                role = "mirrored_navigation_idle"
                width = 3072
                height = 512
                frames = 12
            },
            [ordered]@{
                resource = "res://game/characters/corvin/sprites/act_i_clean/walk_side_right.png"
                role = "load_validated_next_animation"
                width = 2048
                height = 512
                frames = 8
            },
            [ordered]@{
                resource = "res://game/characters/corvin/sprites/act_i_clean/walk_side_left.png"
                role = "mirrored_navigation_walk"
                width = 2048
                height = 512
                frames = 8
            },
            [ordered]@{
                resource = "res://game/characters/corvin/sprites/act_i_clean/talk_side_right.png"
                role = "runtime_side_dialogue"
                width = 1536
                height = 512
                frames = 6
            },
            [ordered]@{
                resource = "res://game/characters/corvin/sprites/act_i_clean/talk_side_left.png"
                role = "runtime_side_dialogue"
                width = 1536
                height = 512
                frames = 6
            },
            [ordered]@{
                resource = "res://game/characters/corvin/sprites/act_i_clean/use_side_right.png"
                role = "runtime_side_item_use"
                width = 2048
                height = 512
                frames = 8
            },
            [ordered]@{
                resource = "res://game/characters/corvin/sprites/act_i_clean/use_side_left.png"
                role = "runtime_side_item_use"
                width = 2048
                height = 512
                frames = 8
            },
            [ordered]@{
                resource = "res://game/characters/corvin/sprites/act_i_clean/wet_side_right.png"
                role = "runtime_side_wet_verb"
                width = 2048
                height = 512
                frames = 8
            },
            [ordered]@{
                resource = "res://game/characters/corvin/sprites/act_i_clean/wet_side_left.png"
                role = "runtime_side_wet_verb"
                width = 2048
                height = 512
                frames = 8
            }
        )
        registered_sprite_actions = @(
            "talk_side_right",
            "talk_side_left",
            "use_side_right",
            "use_side_left",
            "wet_side_right",
            "wet_side_left"
        )
        runtime_sprite = "side_right_side_left_idle_walk_talk_use_wet_switchable"
        character_animation_bridge = "side_right_side_left_idle_walk_talk_use_wet_switchable_with_current_side_actions"
        walk_state_switching = "implemented_loader_api"
        current_side_idle = "implemented_character_bridge_alias"
        current_side_actions = "implemented_character_bridge_aliases"
        known_shutdown_warnings = "Popochiu UID fallback and Godot headless RID/resource cleanup warnings"
        pass_line = [string]$passLine
    }
    $status | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $statusPath -Encoding UTF8

    $reportLines = @(
        "# Corvin Runtime Sprite Assets Status",
        "",
        'Generated by `tools/Validate-CorvinRuntimeSpriteAssets.ps1`.',
        "",
        "Status: audited.",
        'Runtime default sprite resource: `res://game/characters/corvin/sprites/act_i_clean/idle_side_right.png`.',
        "Runtime default dimensions: 3072x512.",
        "Runtime default frames: 12.",
        'Left idle sprite resource: `res://game/characters/corvin/sprites/act_i_clean/idle_side_left.png`.',
        "Left idle dimensions: 3072x512.",
        "Left idle frames: 12.",
        'Walk sprite resource: `res://game/characters/corvin/sprites/act_i_clean/walk_side_right.png`.',
        "Walk dimensions: 2048x512.",
        "Walk frames: 8.",
        'Left walk sprite resource: `res://game/characters/corvin/sprites/act_i_clean/walk_side_left.png`.',
        "Left walk dimensions: 2048x512.",
        "Left walk frames: 8.",
        'Talk sprite resources: `res://game/characters/corvin/sprites/act_i_clean/talk_side_right.png`, `res://game/characters/corvin/sprites/act_i_clean/talk_side_left.png`.',
        "Talk dimensions: 1536x512.",
        "Talk frames: 6.",
        'Use sprite resources: `res://game/characters/corvin/sprites/act_i_clean/use_side_right.png`, `res://game/characters/corvin/sprites/act_i_clean/use_side_left.png`.',
        "Use dimensions: 2048x512.",
        "Use frames: 8.",
        'Wet sprite resources: `res://game/characters/corvin/sprites/act_i_clean/wet_side_right.png`, `res://game/characters/corvin/sprites/act_i_clean/wet_side_left.png`.',
        "Wet dimensions: 2048x512.",
        "Wet frames: 8.",
        "Registered side action resources: talk_side_right, talk_side_left, use_side_right, use_side_left, wet_side_right, wet_side_left.",
        "RuntimeSprite: side_right_side_left_idle_walk_talk_use_wet_switchable.",
        "Character animation bridge: side_right_side_left_idle_walk_talk_use_wet_switchable_with_current_side_actions.",
        "Walk state switching: implemented_loader_api.",
        "Current-side idle: implemented_character_bridge_alias.",
        "Current-side actions: implemented_character_bridge_aliases.",
        "Known shutdown warnings: Popochiu UID fallback and Godot headless RID/resource cleanup warnings.",
        "",
        "Pass line:",
        '```text',
        [string]$passLine,
        '```'
    )
    Set-Content -LiteralPath $reportPath -Value $reportLines -Encoding UTF8
}
finally {
    Pop-Location
}
