$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$graphPath = Join-Path $root "docs\act_ii_puzzle_dependency_graph.json"
$confessionsPath = Join-Path $root "data\confessions.json"

if (-not (Test-Path -LiteralPath $graphPath)) {
    throw "Act II puzzle dependency graph is missing: $graphPath"
}
if (-not (Test-Path -LiteralPath $confessionsPath)) {
    throw "Confession library is missing: $confessionsPath"
}

$graph = Get-Content -LiteralPath $graphPath -Raw -Encoding UTF8 | ConvertFrom-Json
$confessions = Get-Content -LiteralPath $confessionsPath -Raw -Encoding UTF8 | ConvertFrom-Json

if ($graph.act -ne "II") {
    throw "Act II graph must declare act II."
}
if ($graph.status -ne "planning_only_blocked_until_act_i_human_review") {
    throw "Act II graph must remain planning-only until Act I human review is complete."
}
if ($graph.build_order_guard.realtime_countdown -ne $false -or $graph.build_order_guard.narrative_clock_only -ne $true) {
    throw "Act II graph must preserve narrative-clock-only timing and no realtime countdown."
}
if ($graph.build_order_guard.act_i_human_review_required_before_greybox -ne $true) {
    throw "Act II graph must keep Act I human review as the greybox production guard."
}
if ($graph.build_order_guard.act_ii_final_dialogue_locked -ne $true -or $graph.build_order_guard.act_ii_final_art_locked -ne $true) {
    throw "Act II graph must keep final dialogue and final art locked at planning stage."
}

if (-not $graph.nodes -or -not $graph.edges -or -not $graph.rooms) {
    throw "Act II graph must contain rooms, nodes, and edges."
}

$nodeIds = @($graph.nodes | ForEach-Object { [string]$_.id })
$uniqueNodeIds = @($nodeIds | Sort-Object -Unique)
if ($nodeIds.Count -ne $uniqueNodeIds.Count) {
    $duplicates = $nodeIds | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name }
    throw "Act II graph has duplicate node ids: $($duplicates -join ', ')"
}

$nodeSet = @{}
foreach ($id in $nodeIds) {
    if ([string]::IsNullOrWhiteSpace($id)) {
        throw "Act II graph contains a blank node id."
    }
    $nodeSet[$id] = $true
}

$roomIds = @($graph.rooms | ForEach-Object { [string]$_.id })
$roomSet = @{}
foreach ($roomId in $roomIds) {
    if ([string]::IsNullOrWhiteSpace($roomId)) {
        throw "Act II graph contains a blank room id."
    }
    $roomSet[$roomId] = $true
}

$requiredRooms = @(
    "R13_kane_parlour",
    "R14_float_lower",
    "R15_customs",
    "R16_kestrel_wreck",
    "R12_sabine_office_return"
)
foreach ($requiredRoom in $requiredRooms) {
    if (-not $roomSet.ContainsKey($requiredRoom)) {
        throw "Act II graph is missing required room: $requiredRoom"
    }
}

foreach ($node in $graph.nodes) {
    $room = [string]$node.room
    if (-not [string]::IsNullOrWhiteSpace($room) -and -not $roomSet.ContainsKey($room) -and $room -notmatch "^[A-Za-z]+[A-Za-z0-9]*$") {
        throw "Act II node references unknown room id: $($node.id) -> $room"
    }
}

foreach ($edge in $graph.edges) {
    $from = [string]$edge.from
    $to = [string]$edge.to
    if (-not $nodeSet.ContainsKey($from)) {
        throw "Act II graph edge references missing from node: $from -> $to"
    }
    if (-not $nodeSet.ContainsKey($to)) {
        throw "Act II graph edge references missing to node: $from -> $to"
    }
    if ($from -eq $to) {
        throw "Act II graph contains a self-cycle: $from"
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
$incomingCounts = @{}
foreach ($id in $nodeIds) {
    $incomingCounts[$id] = $incoming[$id].Count
    if ($incoming[$id].Count -eq 0) {
        $ready.Enqueue($id)
    }
}

$visited = New-Object System.Collections.Generic.List[string]
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
    throw "Act II graph is cyclic or disconnected from topological walk: $($unvisited -join ', ')"
}

$requiredNodes = @(
    "start",
    "FL_act_i_human_review_pending",
    "FL_act_ii_started",
    "FL_kane_offer_refused",
    "IT_kane_seal",
    "IT_forged_customs_writ",
    "FL_customs_access",
    "FL_regulator_returned",
    "IT_cut_paper",
    "IT_tide_table",
    "FL_sabine_signature_seen",
    "FL_float_lower_access",
    "IT_mireille_book",
    "FL_memory_decay_tutorial_seen",
    "FL_kestrel_window_open",
    "IT_tomas_papers",
    "cf_bt_tomas",
    "cf_bt_harbor",
    "FL_sabine_signed_revealed",
    "FL_act_ii_complete"
)
foreach ($required in $requiredNodes) {
    if (-not $nodeSet.ContainsKey($required)) {
        throw "Act II graph is missing required node: $required"
    }
}

$actComplete = [string]$graph.act_complete_node
if ($actComplete -ne "FL_act_ii_complete" -or -not $nodeSet.ContainsKey($actComplete)) {
    throw "Act II graph act_complete_node must be FL_act_ii_complete."
}

$actCompleteParents = @($incoming[$actComplete] | Sort-Object -Unique)
if ($actCompleteParents.Count -ne 1 -or $actCompleteParents[0] -ne "FL_sabine_signed_revealed") {
    throw "Act II completion must be gated only by Sabine reveal. Actual parents: $($actCompleteParents -join ', ')"
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

foreach ($spineNode in @($graph.required_spine_nodes | ForEach-Object { [string]$_ })) {
    if (-not $nodeSet.ContainsKey($spineNode)) {
        throw "Act II required_spine_nodes references missing node: $spineNode"
    }
    if (-not (Test-Reachable -From "start" -To $spineNode)) {
        throw "Act II required spine node is unreachable from start: $spineNode"
    }
    if (-not (Test-Reachable -From $spineNode -To $actComplete)) {
        throw "Act II required spine node cannot reach completion: $spineNode"
    }
}

$forbiddenTokens = @($graph.explicitly_forbidden_until_act_iii | ForEach-Object { [string]$_ })
foreach ($forbidden in $forbiddenTokens) {
    if ($forbidden -eq "cf_bt_again" -and $nodeSet.ContainsKey($forbidden)) {
        throw "Act II graph must not include cf_bt_again; it is the final Act III betrayal."
    }
}

$confessionById = @{}
foreach ($confession in $confessions) {
    $confessionById[[string]$confession.id] = $confession
}

$unlockRows = @($graph.confession_unlocks)
foreach ($unlock in $unlockRows) {
    $id = [string]$unlock.id
    if (-not $nodeSet.ContainsKey($id)) {
        throw "Act II confession unlock references missing graph node: $id"
    }
    if (-not $confessionById.ContainsKey($id)) {
        throw "Act II confession unlock is missing from data/confessions.json: $id"
    }
    $confession = $confessionById[$id]
    if ([int]$confession.act_available -gt 2) {
        throw "Act II graph unlocks an Act III confession too early: $id"
    }
    if ([int]$confession.act_available -gt [int]$unlock.act_available_max) {
        throw "Act II graph unlock max contradicts confession act_available for $id."
    }
    if ([string]$confession.acquisition -eq "COMMITTED" -and $unlock.requires_committed_action -ne $true) {
        throw "COMMITTED confession is not guarded as a committed action: $id"
    }
    if ([string]$confession.acquisition -ne "COMMITTED" -and $unlock.requires_committed_action -eq $true) {
        throw "Non-COMMITTED confession is incorrectly flagged as committed action: $id"
    }
    $sourceNode = [string]$unlock.source_node
    if (-not $nodeSet.ContainsKey($sourceNode)) {
        throw "Act II confession unlock source node is missing: $id -> $sourceNode"
    }
    if (-not (Test-Reachable -From $sourceNode -To $id) -and $sourceNode -ne $id) {
        throw "Act II confession unlock source cannot reach confession node: $sourceNode -> $id"
    }
}

$committedConfessionNodes = @(
    $graph.nodes |
        Where-Object {
            $nodeId = [string]$_.id
            $_.type -eq "confession" -and
                $confessionById.ContainsKey($nodeId) -and
                [string]$confessionById[$nodeId].acquisition -eq "COMMITTED"
        }
)
foreach ($node in $committedConfessionNodes) {
    if ($node.requires_committed_action -ne $true) {
        throw "COMMITTED confession graph node must set requires_committed_action=true: $($node.id)"
    }
    $parents = @($incoming[[string]$node.id] | Sort-Object -Unique)
    $committedParent = $false
    foreach ($parent in $parents) {
        $parentNode = $graph.nodes | Where-Object { $_.id -eq $parent } | Select-Object -First 1
        if ($parentNode.type -eq "committed_action") {
            $committedParent = $true
        }
        $edgeKind = @($graph.edges | Where-Object { $_.from -eq $parent -and $_.to -eq $node.id } | ForEach-Object { [string]$_.kind })
        if ($edgeKind -contains "committed_action") {
            $committedParent = $true
        }
    }
    if (-not $committedParent) {
        throw "COMMITTED confession must be reached through a committed_action parent or edge: $($node.id)"
    }
}

$floatRoom = $graph.rooms | Where-Object { $_.id -eq "R14_float_lower" } | Select-Object -First 1
$floatTags = @($floatRoom.content_tags | ForEach-Object { [string]$_ })
foreach ($requiredTag in @("hard_r_non_explicit", "adult_labor_agency", "no_cold_girl")) {
    if ($requiredTag -notin $floatTags) {
        throw "R14_float_lower is missing required content tag: $requiredTag"
    }
}
foreach ($forbiddenTag in @("explicit_sex", "cold_girl", "sexualized_violence")) {
    if ($forbiddenTag -in $floatTags) {
        throw "R14_float_lower contains forbidden content tag: $forbiddenTag"
    }
}

$allSerialized = Get-Content -LiteralPath $graphPath -Raw -Encoding UTF8
foreach ($forbiddenText in @("real-time countdown", "realtime timer", "cf_bt_again")) {
    if ($forbiddenText -eq "cf_bt_again") {
        $matches = [regex]::Matches($allSerialized, [regex]::Escape($forbiddenText))
        if ($matches.Count -gt 1) {
            throw "Act II graph may only mention cf_bt_again in the forbidden-until-Act-III list."
        }
    }
}

Write-Host "Act II planning graph validation passed: rooms=$($roomIds.Count), nodes=$($nodeIds.Count), edges=$($graph.edges.Count), confession_unlocks=$($unlockRows.Count)"
