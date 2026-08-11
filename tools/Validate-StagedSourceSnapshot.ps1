$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$reportPath = Join-Path $root "docs\checkpoints\staged_source_snapshot.md"

Push-Location $root
try {
    $stagedFiles = @(git diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to inspect staged files."
    }
    if ($stagedFiles.Count -eq 0) {
        throw "No files are staged for the source snapshot."
    }

    $forbiddenPatterns = @(
        "(^|/)bin/",
        "(^|/)obj/",
        "^\.godot/",
        "\.blend1$",
        "\.blend2$",
        "\.tmp$",
        "\.bak$",
        "\.log$"
    )

    $forbidden = @()
    foreach ($file in $stagedFiles) {
        $normalized = $file -replace "\\", "/"
        foreach ($pattern in $forbiddenPatterns) {
            if ($normalized -match $pattern) {
                $forbidden += $normalized
                break
            }
        }
    }
    if ($forbidden.Count -gt 0) {
        throw "Forbidden files staged: $($forbidden -join ', ')"
    }

    $requiredFiles = @(
        ".gitattributes",
        ".gitignore",
        "AGENTS.md",
        "README.md",
        "CorpseInGoodStanding.sln",
        "project.godot",
        "tools/Run-RepoReadinessGates.ps1",
        "tools/Run-Step5ReadinessGates.ps1",
        "docs/checkpoints/step_5_act_i_art_pass_readiness.md",
        "docs/checkpoints/source_control_readiness.md"
    )

    $missingRequired = @()
    foreach ($required in $requiredFiles) {
        if ($stagedFiles -notcontains $required) {
            $missingRequired += $required
        }
    }
    if ($missingRequired.Count -gt 0) {
        throw "Required snapshot files are not staged: $($missingRequired -join ', ')"
    }

    $lfsVersion = (& git lfs version 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace([string]$lfsVersion)) {
        throw "Git LFS is required but unavailable."
    }

    $lfsExtensions = @(".blend", ".glb", ".gltf", ".fbx", ".psd", ".png", ".jpg", ".jpeg", ".webp", ".tif", ".tiff", ".exr", ".hdr", ".wav", ".ogg", ".mp3", ".flac", ".zip", ".7z", ".rar", ".exe")
    $lfsCoveredStaged = @($stagedFiles | Where-Object { $lfsExtensions -contains [System.IO.Path]::GetExtension($_).ToLowerInvariant() })
    $branchLine = [string]((git status --short --branch | Select-Object -First 1))
    $unstagedFiles = @(git diff --name-only)
    $topLevelCounts = @{}
    foreach ($file in $stagedFiles) {
        $normalized = $file -replace "\\", "/"
        $topLevel = if ($normalized -match "/") { $normalized.Split("/")[0] } else { "<root>" }
        if (-not $topLevelCounts.ContainsKey($topLevel)) {
            $topLevelCounts[$topLevel] = 0
        }
        $topLevelCounts[$topLevel] += 1
    }
    $identityName = [string](git config --get user.name)
    $identityEmail = [string](git config --get user.email)
    $remotes = @(git remote -v)

    $commitBlockers = @()
    if ([string]::IsNullOrWhiteSpace($identityName) -or [string]::IsNullOrWhiteSpace($identityEmail)) {
        $commitBlockers += "missing local git user.name/user.email"
    }
    if ($remotes.Count -eq 0) {
        $commitBlockers += "no git remote configured"
    }

    $tick = [char]96
    $fence = "$tick$tick$tick"
    $lines = @(
        "# Staged Source Snapshot",
        "",
        "Status: pass",
        "",
        "Staged files: $($stagedFiles.Count)",
        "Git LFS: $lfsVersion",
        "LFS-covered staged paths by extension: $($lfsCoveredStaged.Count)",
        "Unstaged files before report write: $($unstagedFiles.Count)",
        "",
        "## Forbidden Files",
        "",
        "- No $($tick)bin/$tick, $($tick)obj/$tick, $($tick).godot/$tick, $($tick).blend1$tick, temp, backup, or log files are staged.",
        "",
        "## Required Files",
        ""
    )
    foreach ($required in $requiredFiles) {
        $lines += "- $tick$required$tick"
    }

    $lines += @(
        "",
        "## Staged Top-Level Coverage",
        ""
    )
    foreach ($key in @($topLevelCounts.Keys | Sort-Object)) {
        $lines += ("- " + $tick + $key + $tick + ": " + $topLevelCounts[$key])
    }

    $lines += @(
        "",
        "## Commit/Remote State",
        "",
        "Branch: $branchLine",
        ""
    )

    if ($commitBlockers.Count -eq 0) {
        $lines += "Commit blockers: none"
    } else {
        $lines += "Commit blockers:"
        foreach ($blocker in $commitBlockers) {
            $lines += "- $blocker"
        }
    }

    [System.IO.File]::WriteAllText($reportPath, (($lines -join "`n") + "`n"), [System.Text.Encoding]::ASCII)
    Write-Host "Staged source snapshot passed: $reportPath"
}
finally {
    Pop-Location
}
