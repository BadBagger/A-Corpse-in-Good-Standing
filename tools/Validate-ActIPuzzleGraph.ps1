$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$graphPath = Join-Path $root "docs\act_i_puzzle_dependency_graph.json"

if (-not (Test-Path -LiteralPath $graphPath)) {
    throw "Act I puzzle dependency graph is missing: $graphPath"
}

$graph = Get-Content -LiteralPath $graphPath -Raw -Encoding UTF8 | ConvertFrom-Json

if (-not $graph.nodes -or -not $graph.edges) {
    throw "Act I puzzle dependency graph must contain nodes and edges."
}

$nodeIds = @($graph.nodes | ForEach-Object { [string]$_.id })
$uniqueNodeIds = @($nodeIds | Sort-Object -Unique)
if ($nodeIds.Count -ne $uniqueNodeIds.Count) {
    $duplicates = $nodeIds | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name }
    throw "Act I puzzle dependency graph has duplicate node ids: $($duplicates -join ', ')"
}

$nodeSet = @{}
foreach ($id in $nodeIds) {
    if ([string]::IsNullOrWhiteSpace($id)) {
        throw "Act I puzzle dependency graph contains a blank node id."
    }
    $nodeSet[$id] = $true
}

foreach ($edge in $graph.edges) {
    $from = [string]$edge.from
    $to = [string]$edge.to
    if (-not $nodeSet.ContainsKey($from)) {
        throw "Act I puzzle dependency graph edge references missing from node: $from -> $to"
    }
    if (-not $nodeSet.ContainsKey($to)) {
        throw "Act I puzzle dependency graph edge references missing to node: $from -> $to"
    }
    if ($from -eq $to) {
        throw "Act I puzzle dependency graph contains a self-cycle: $from"
    }
}

$incoming = @{}
$outgoing = @{}
foreach ($id in $nodeIds) {
    $incoming[$id] = New-Object System.Collections.Generic.List[string]
    $outgoing[$id] = New-Object System.Collections.Generic.List[string]
}

foreach ($edge in $graph.edges) {
    $from = [string]$edge.from
    $to = [string]$edge.to
    $outgoing[$from].Add($to)
    $incoming[$to].Add($from)
}

$ready = New-Object System.Collections.Generic.Queue[string]
foreach ($id in $nodeIds) {
    if ($incoming[$id].Count -eq 0) {
        $ready.Enqueue($id)
    }
}

$visited = New-Object System.Collections.Generic.List[string]
$incomingCounts = @{}
foreach ($id in $nodeIds) {
    $incomingCounts[$id] = $incoming[$id].Count
}

while ($ready.Count -gt 0) {
    $id = $ready.Dequeue()
    $visited.Add($id)
    foreach ($next in $outgoing[$id]) {
        $incomingCounts[$next] -= 1
        if ($incomingCounts[$next] -eq 0) {
            $ready.Enqueue($next)
        }
    }
}

if ($visited.Count -ne $nodeIds.Count) {
    $unvisited = $nodeIds | Where-Object { $_ -notin $visited }
    throw "Act I puzzle dependency graph is cyclic or disconnected from topological walk: $($unvisited -join ', ')"
}

$requiredNodes = @(
    "start",
    "map_open",
    "IT_knuckle_salt",
    "IT_watch",
    "IT_forgiveness",
    "FL_rite_debt",
    "FL_registry_lamp_smoked",
    "IT_ledger_page",
    "cf_bt_manifest",
    "FL_rite_name",
    "IT_chit",
    "IT_rate_card",
    "IT_regulator",
    "FL_float_warmth_active",
    "FL_rite_heartbeat",
    "FL_act_i_complete"
)

foreach ($required in $requiredNodes) {
    if (-not $nodeSet.ContainsKey($required)) {
        throw "Act I puzzle dependency graph is missing required node: $required"
    }
}

$riteNodes = @($graph.required_rite_nodes | ForEach-Object { [string]$_ })
if ($riteNodes.Count -ne 3) {
    throw "Act I puzzle dependency graph must declare exactly three required Rite nodes."
}
foreach ($rite in $riteNodes) {
    if (-not $nodeSet.ContainsKey($rite)) {
        throw "Act I puzzle dependency graph required Rite node is missing: $rite"
    }
}

$actComplete = [string]$graph.act_complete_node
if (-not $nodeSet.ContainsKey($actComplete)) {
    throw "Act I puzzle dependency graph act_complete_node is missing: $actComplete"
}

$actCompleteParents = @($incoming[$actComplete] | Sort-Object -Unique)
foreach ($rite in $riteNodes) {
    if ($rite -notin $actCompleteParents) {
        throw "Act I completion is not gated by required Rite node: $rite"
    }
}
if ($actCompleteParents.Count -ne $riteNodes.Count) {
    throw "Act I completion has unexpected direct prerequisites: $($actCompleteParents -join ', ')"
}

function Test-Reachable {
    param(
        [Parameter(Mandatory=$true)][string]$From,
        [Parameter(Mandatory=$true)][string]$To
    )

    $seen = @{}
    $queue = New-Object System.Collections.Generic.Queue[string]
    $queue.Enqueue($From)
    $seen[$From] = $true
    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        foreach ($next in $outgoing[$current]) {
            if ($next -eq $To) {
                return $true
            }
            if (-not $seen.ContainsKey($next)) {
                $seen[$next] = $true
                $queue.Enqueue($next)
            }
        }
    }
    return $false
}

foreach ($fromRite in $riteNodes) {
    foreach ($toRite in $riteNodes) {
        if ($fromRite -eq $toRite) {
            continue
        }
        if (Test-Reachable -From $fromRite -To $toRite) {
            throw "Act I Rite dependency graph is not non-linear: $fromRite reaches $toRite"
        }
    }
}

Write-Host "Act I puzzle dependency graph validation passed: nodes=$($nodeIds.Count), edges=$($graph.edges.Count), rites=$($riteNodes -join ', ')"
