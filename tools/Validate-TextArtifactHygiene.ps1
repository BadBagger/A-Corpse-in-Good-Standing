$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$textFiles = @()
$textExtensions = @(
    ".md",
    ".csv",
    ".json",
    ".html",
    ".ink",
    ".cs",
    ".csproj",
    ".sln",
    ".gd",
    ".tscn",
    ".tres",
    ".ps1",
    ".svg",
    ".godot",
    ".gitignore",
    ".gitattributes"
)

foreach ($folder in @("docs", "ink", "data", "duels", "narrative", "tests", "prototype", "game", "tools")) {
    $path = Join-Path $root $folder
    if (Test-Path -LiteralPath $path) {
        $textFiles += Get-ChildItem -LiteralPath $path -Recurse -File |
            Where-Object {
                $_.FullName -notmatch "\\bin\\" -and
                $_.FullName -notmatch "\\obj\\" -and
                $_.FullName -notmatch "\\.godot\\" -and
                $_.FullName -notmatch "\\.git\\" -and
                $textExtensions -contains $_.Extension.ToLowerInvariant()
            }
    }
}

foreach ($fileName in @("README.md", "AGENTS.md", "project.godot", ".gitignore", ".gitattributes")) {
    $path = Join-Path $root $fileName
    if (Test-Path -LiteralPath $path) {
        $textFiles += Get-Item -LiteralPath $path
    }
}

$textFiles = @($textFiles | Sort-Object FullName -Unique)
$badFiles = @()
foreach ($file in $textFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    if ($text -match "[\x00-\x08\x0B\x0C\x0E-\x1F]") {
        $badFiles += $file.FullName.Substring($root.Length + 1)
    }
}

if ($badFiles.Count -gt 0) {
    throw "Illegal control characters found in text artifacts: $($badFiles -join ', ')"
}

Write-Host "Text artifact hygiene passed: $($textFiles.Count) files checked, 0 illegal control-character files."
