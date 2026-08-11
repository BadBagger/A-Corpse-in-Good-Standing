$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root "data\confessions.json"

if (-not (Test-Path -LiteralPath $path)) {
    throw "Missing confession data: $path"
}

$confessions = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
$categories = @("GREED", "LUST", "PRIDE", "CRUELTY", "COWARDICE", "BETRAYAL")
$ids = @{}

foreach ($confession in $confessions) {
    if ($ids.ContainsKey($confession.id)) {
        throw "Duplicate confession id: $($confession.id)"
    }
    $ids[$confession.id] = $true

    if ($categories -cnotcontains $confession.category) {
        throw "Invalid category for $($confession.id): $($confession.category)"
    }
    if ([string]::IsNullOrWhiteSpace($confession.text)) {
        throw "Missing text for $($confession.id)"
    }
    if ([string]::IsNullOrWhiteSpace($confession.elaboration)) {
        throw "Missing elaboration for $($confession.id)"
    }
    if ($confession.category -eq "BETRAYAL") {
        if ([int]$confession.weight -ne 8) {
            throw "BETRAYAL confession must have weight 8: $($confession.id)"
        }
    } elseif ([int]$confession.weight -lt 1 -or [int]$confession.weight -gt 7) {
        throw "Common confession weight out of range for $($confession.id): $($confession.weight)"
    }
    if ([int]$confession.act_available -lt 1 -or [int]$confession.act_available -gt 3) {
        throw "Invalid act_available for $($confession.id): $($confession.act_available)"
    }
    if (@("OVERHEARD", "EXCAVATED", "COMMITTED") -cnotcontains $confession.acquisition) {
        throw "Invalid acquisition for $($confession.id): $($confession.acquisition)"
    }
}

$counts = @{}
foreach ($category in $categories) {
    $counts[$category] = @($confessions | Where-Object { $_.category -eq $category }).Count
}

if (@($confessions).Count -lt 60) {
    throw "G14 fail: expected >=60 confessions, found $(@($confessions).Count)"
}
foreach ($category in @("GREED", "LUST", "PRIDE", "CRUELTY", "COWARDICE")) {
    if ($counts[$category] -lt 11) {
        throw "G14 fail: expected >=11 $category confessions, found $($counts[$category])"
    }
}
if ($counts["BETRAYAL"] -ne 4) {
    throw "G14 fail: expected exactly 4 BETRAYAL confessions, found $($counts["BETRAYAL"])"
}

$again = $confessions | Where-Object { $_.id -eq "cf_bt_again" } | Select-Object -First 1
if ($null -eq $again) {
    throw "G16 prep fail: missing cf_bt_again"
}
if ([int]$again.act_available -ne 3) {
    throw "G16 prep fail: cf_bt_again must be Act III"
}

$summary = ($categories | ForEach-Object { "$_=$($counts[$_])" }) -join ", "
Write-Host "Confession validation passed: total=$(@($confessions).Count), $summary"
