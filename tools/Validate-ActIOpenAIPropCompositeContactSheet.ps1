$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_openai_prop_composite_contact_sheet.json"
$reportPath = Join-Path $root "docs\art\act_i_openai_prop_composite_contact_sheet.md"
$imagePath = Join-Path $root "docs\art\review\act_i_openai_prop_composite_contact_sheet.png"

foreach ($path in @($jsonPath, $reportPath, $imagePath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I prop contact-sheet validation input: $path"
    }
}

$payload = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$report = Get-Content -LiteralPath $reportPath -Raw

$requiredRooms = @(
    "mudflats",
    "old_quay",
    "salt_market",
    "harbor_registry",
    "bone_chandler",
    "almshouse",
    "fish_hall",
    "church_of_the_drowned",
    "grey_float",
    "harbormaster_office",
    "sabine_office"
)

if ($payload.status -ne "exported") {
    throw "Act I prop contact sheet has unexpected status: $($payload.status)"
}

$rooms = @($payload.rooms)
if ($rooms.Count -ne $requiredRooms.Count -or [int]$payload.room_count -ne $requiredRooms.Count) {
    throw "Act I prop contact sheet expected $($requiredRooms.Count) rooms, got $($rooms.Count)."
}

foreach ($roomId in $requiredRooms) {
    $row = @($rooms | Where-Object { $_.room_id -eq $roomId })[0]
    if ($null -eq $row) {
        throw "Act I prop contact sheet missing room: $roomId"
    }
    $compositeRelative = [string]$row.composite
    if ($compositeRelative -match "\\") {
        throw "Act I prop contact sheet composite path must use forward slashes: $compositeRelative"
    }
    $compositeAbsolute = Join-Path $root ($compositeRelative -replace "/", "\")
    if (-not (Test-Path -LiteralPath $compositeAbsolute)) {
        throw "Act I prop contact sheet references missing composite: $compositeRelative"
    }

    $roomDir = Join-Path $root ("game\rooms\$roomId")
    $propsDir = Join-Path $roomDir "props"
    if (-not (Test-Path -LiteralPath $propsDir)) {
        throw "Act I room $roomId is missing runtime props directory."
    }
    $propCount = @(Get-ChildItem -LiteralPath $propsDir -File -Filter "*.png").Count
    if ($propCount -lt 3) {
        throw "Act I room $roomId must have at least 3 runtime foreground props, got $propCount."
    }
}

Add-Type -AssemblyName System.Drawing
$bitmap = [System.Drawing.Bitmap]::new($imagePath)
try {
    if ($bitmap.Width -lt 900 -or $bitmap.Height -lt 1500) {
        throw "Act I prop contact sheet is too small: $($bitmap.Width)x$($bitmap.Height)"
    }
    $nonBlackSamples = 0
    $sampleCount = 0
    $stepX = [Math]::Max(1, [int]($bitmap.Width / 80))
    $stepY = [Math]::Max(1, [int]($bitmap.Height / 80))
    for ($y = 0; $y -lt $bitmap.Height; $y += $stepY) {
        for ($x = 0; $x -lt $bitmap.Width; $x += $stepX) {
            $sampleCount += 1
            $pixel = $bitmap.GetPixel($x, $y)
            if (($pixel.R + $pixel.G + $pixel.B) -gt 70) {
                $nonBlackSamples += 1
            }
        }
    }
    if (($nonBlackSamples / [double]$sampleCount) -lt 0.20) {
        throw "Act I prop contact sheet appears visually blank."
    }
}
finally {
    $bitmap.Dispose()
}

foreach ($requiredText in @(
    "Act I OpenAI Prop Composite Contact Sheet",
    "runtime-room composite",
    "Act I background rooms only",
    "hard-R, no explicit anatomy, no gore, no bodies, no child figures"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Act I prop contact-sheet report missing required text: $requiredText"
    }
}

Write-Host "Act I OpenAI prop composite contact sheet validation passed: rooms=$($rooms.Count)."
