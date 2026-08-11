$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$confessionPath = Join-Path $root "data\confessions.json"
$opponentsDir = Join-Path $root "duels\opponents"

if (-not (Test-Path -LiteralPath $confessionPath)) {
    throw "Missing confession data: $confessionPath"
}
if (-not (Test-Path -LiteralPath $opponentsDir)) {
    throw "Missing opponents directory: $opponentsDir"
}

$confessions = Get-Content -LiteralPath $confessionPath -Raw -Encoding UTF8 | ConvertFrom-Json
$confessionsById = @{}
foreach ($confession in $confessions) {
    $confessionsById[[string]$confession.id] = $confession
}

$trump = @{
    "GREED" = 0
    "LUST" = 1
    "PRIDE" = 2
    "CRUELTY" = 3
    "COWARDICE" = 4
    "BETRAYAL" = 5
}

$starterPool = @(
    "cf_greed_boots",
    "cf_pride_list",
    "cf_lust_float",
    "cf_lust_schedule",
    "cf_pride_grammar",
    "cf_pride_counselor",
    "cf_cruel_soupline",
    "cf_cruel_sentences",
    "cf_cow_leftroom",
    "cf_cow_bigger",
    "cf_cow_passive",
    "cf_bt_manifest"
)

$registrarScriptedWin = @(
    "cf_cruel_sentences",
    "cf_greed_boots",
    "cf_pride_list",
    "cf_cow_bigger",
    "cf_cow_passive",
    "cf_lust_schedule",
    "cf_pride_counselor",
    "cf_bt_manifest"
)

foreach ($id in $starterPool) {
    if (-not $confessionsById.ContainsKey($id)) {
        throw "Starter pool references missing confession: $id"
    }
}

$opponentCount = 0
$attackCount = 0
foreach ($file in Get-ChildItem -LiteralPath $opponentsDir -Filter "*.json" -File) {
    $opponent = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    $opponentCount++
    if ([string]::IsNullOrWhiteSpace($opponent.id)) {
        throw "$($file.Name) missing id"
    }
    if ([string]::IsNullOrWhiteSpace($opponent.name)) {
        throw "$($file.Name) missing name"
    }
    if (@($opponent.attacks).Count -lt 8) {
        throw "$($opponent.id) must have at least 8 attacks"
    }

    foreach ($attack in $opponent.attacks) {
        $attackCount++
        if ([string]::IsNullOrWhiteSpace($attack.id)) {
            throw "$($opponent.id) has attack without id"
        }
        if ([string]::IsNullOrWhiteSpace($attack.text)) {
            throw "$($opponent.id)/$($attack.id) missing text"
        }
        if (-not $trump.ContainsKey([string]$attack.category)) {
            throw "$($opponent.id)/$($attack.id) invalid category: $($attack.category)"
        }
        if ($null -ne $attack.locks_confession_id -and -not [string]::IsNullOrWhiteSpace($attack.locks_confession_id)) {
            if (-not $confessionsById.ContainsKey([string]$attack.locks_confession_id)) {
                throw "$($opponent.id)/$($attack.id) locks missing confession $($attack.locks_confession_id)"
            }
        }

        if ($opponent.id -eq "registrar") {
            $valid = @()
            foreach ($confessionId in $starterPool) {
                if ($confessionId -eq [string]$attack.locks_confession_id) {
                    continue
                }
                $confession = $confessionsById[$confessionId]
                if ([int]$confession.weight -gt [int]$attack.weight -and $trump[[string]$confession.category] -ge $trump[[string]$attack.category]) {
                    $valid += $confessionId
                }
            }
            if ($valid.Count -lt 2) {
                throw "G13 fail: registrar/$($attack.id) has only $($valid.Count) valid starter counters: $($valid -join ', ')"
            }
        }
    }

    if ($opponent.id -eq "registrar") {
        if (@($opponent.attacks).Count -ne $registrarScriptedWin.Count) {
            throw "Registrar scripted path mismatch: attacks=$(@($opponent.attacks).Count), scripted counters=$($registrarScriptedWin.Count)"
        }

        $spent = @{}
        $locked = @{}
        for ($index = 0; $index -lt $registrarScriptedWin.Count; $index++) {
            $attack = $opponent.attacks[$index]
            if ($null -ne $attack.locks_confession_id -and -not [string]::IsNullOrWhiteSpace($attack.locks_confession_id)) {
                $locked[[string]$attack.locks_confession_id] = $true
            }

            $valid = @()
            foreach ($confessionId in $starterPool) {
                if ($spent.ContainsKey($confessionId) -or $locked.ContainsKey($confessionId)) {
                    continue
                }
                $confession = $confessionsById[$confessionId]
                if ([int]$confession.weight -gt [int]$attack.weight -and $trump[[string]$confession.category] -ge $trump[[string]$attack.category]) {
                    $valid += $confessionId
                }
            }

            $scriptedCounter = $registrarScriptedWin[$index]
            if ($valid.Count -lt 2) {
                throw "G13 fail: registrar scripted round $($index + 1)/$($attack.id) has only $($valid.Count) valid choices before selection: $($valid -join ', ')"
            }
            if ($valid -notcontains $scriptedCounter) {
                throw "Registrar scripted counter invalid at round $($index + 1)/$($attack.id): $scriptedCounter. Valid: $($valid -join ', ')"
            }

            $spent[$scriptedCounter] = $true
        }
    }
}

Write-Host "Duel content validation passed: opponents=$opponentCount, attacks=$attackCount"
