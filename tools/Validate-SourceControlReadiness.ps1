$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$gitIgnorePath = Join-Path $root ".gitignore"
$gitAttributesPath = Join-Path $root ".gitattributes"
$reportPath = Join-Path $root "docs\checkpoints\source_control_readiness.md"

foreach ($path in @($gitIgnorePath, $gitAttributesPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing source-control file: $path"
    }
}

$gitIgnore = Get-Content -LiteralPath $gitIgnorePath -Raw
$gitAttributes = Get-Content -LiteralPath $gitAttributesPath -Raw
$gitLfsVersion = (& git lfs version 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace([string]$gitLfsVersion)) {
    throw "Git LFS is required for this repo but git lfs version did not return successfully."
}

$requiredIgnores = @(
    "bin/",
    "obj/",
    ".godot/",
    ".import/",
    "*.tmp",
    "*.bak",
    "*.blend1",
    "*.log",
    "_incoming_*/"
)

$requiredLfsPatterns = @(
    "*.blend",
    "*.glb",
    "*.gltf",
    "*.fbx",
    "*.psd",
    "*.png",
    "*.jpg",
    "*.jpeg",
    "*.webp",
    "*.tif",
    "*.tiff",
    "*.exr",
    "*.hdr",
    "*.wav",
    "*.ogg",
    "*.mp3",
    "*.flac",
    "*.zip",
    "*.7z",
    "*.rar",
    "*.exe"
)

$missingIgnores = @()
foreach ($pattern in $requiredIgnores) {
    if ($gitIgnore -notmatch [regex]::Escape($pattern)) {
        $missingIgnores += $pattern
    }
}

$missingLfs = @()
foreach ($pattern in $requiredLfsPatterns) {
    $expected = "$pattern filter=lfs diff=lfs merge=lfs -text"
    if ($gitAttributes -notmatch [regex]::Escape($expected)) {
        $missingLfs += $expected
    }
}

if ($missingIgnores.Count -gt 0) {
    throw "Missing .gitignore entries: $($missingIgnores -join ', ')"
}
if ($missingLfs.Count -gt 0) {
    throw "Missing .gitattributes LFS entries: $($missingLfs -join ', ')"
}

$oversizedFiles = @(
    Get-ChildItem -LiteralPath $root -Recurse -File |
        Where-Object {
            $_.FullName -notmatch "\\.git\\" -and
            $_.FullName -notmatch "\\.godot\\" -and
            $_.FullName -notmatch "\\bin\\" -and
            $_.FullName -notmatch "\\obj\\" -and
            $_.Length -gt 50MB
        } |
        Sort-Object Length -Descending
)

$oversizedRows = @()
foreach ($file in $oversizedFiles) {
    $relative = $file.FullName.Substring($root.Length + 1).Replace("\", "/")
    $extension = "*$($file.Extension.ToLowerInvariant())"
    $status = if ($relative -like "*.blend1") { "ignored_backup" } elseif ($requiredLfsPatterns -contains $extension) { "covered_by_lfs" } else { "uncovered" }
    $oversizedRows += [pscustomobject]@{
        path = $relative
        bytes = $file.Length
        status = $status
    }
}

$uncovered = @($oversizedRows | Where-Object { $_.status -ne "covered_by_lfs" -and $_.path -notlike "*.blend1" })
if ($uncovered.Count -gt 0) {
    throw "Found oversized files without LFS coverage: $(@($uncovered | ForEach-Object { $_.path }) -join ', ')"
}

$lines = @(
    "# Source Control Readiness",
    "",
    "Status: pass",
    "",
    "This gate protects the new repo from committing local Godot caches, build output, Blender backups, or large production binaries without Git LFS coverage.",
    "",
    "Git LFS: $gitLfsVersion",
    "",
    "## Ignore Coverage",
    ""
)
foreach ($pattern in $requiredIgnores) {
    $lines += ("- " + [char]96 + $pattern + [char]96)
}

$lines += @(
    "",
    "## Git LFS Coverage",
    ""
)
foreach ($pattern in $requiredLfsPatterns) {
    $lines += ("- " + [char]96 + $pattern + [char]96)
}

$lines += @(
    "",
    "## Oversized Files Checked",
    ""
)
if ($oversizedRows.Count -eq 0) {
    $lines += "- None over 50 MB outside ignored build/cache folders."
} else {
    foreach ($row in $oversizedRows) {
        $mb = [math]::Round($row.bytes / 1MB, 2)
        $lines += ("- " + [char]96 + $row.path + [char]96 + " - $mb MB - $($row.status)")
    }
}

$lines += @(
    "",
    "Notes:",
    ("- " + [char]96 + ".blend1" + [char]96 + " files are Blender backups and should stay ignored, not source-tracked."),
    ("- " + [char]96 + "tools/ink/inklecate.exe" + [char]96 + " is a binary tool and is covered by LFS if committed."),
    "- Source art and exported runtime art are intentionally kept in the repo, but large binary formats must route through LFS."
)

[System.IO.File]::WriteAllText($reportPath, (($lines -join "`n") + "`n"), [System.Text.Encoding]::ASCII)
Write-Host "Source-control readiness passed: $reportPath"
