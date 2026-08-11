# Act I Human Greybox Playtest

Purpose: decide what to cut, expand, or move before final Act I art and VO timing lock.

This is not a mechanics proof. The automated Step 4 route already proves reachability, Rite order permutations, duel legality, and Act I completion. This pass is for pacing, readability, and whether the player understands the fiction well enough to make intentional choices.

## Before The Run

Run the latest automated route once so the expected state is fresh:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Record-ActIGreyboxPlaytest.ps1
```

Or use the launcher to refresh the automated route, create timestamped notes, and open the playable Godot build:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Start-ActIHumanPlaytest.ps1 -RefreshAutomatedReport
```

Then start from a clean save.

## Player Instructions

Give the player only this setup:

```text
You are Corvin Vale. You have washed back from the harbor dead, wet, and missing the last week of memory. Reach Sabine's office by proving you have standing in the port.
```

Do not explain the three Rites, the wet verb, the Litany rules, or the expected route unless the test has already failed and you are marking a rescue.

## Pass Criteria

Mark each as `yes`, `mixed`, or `no`.

```text
1. The player understood they were dead before leaving the opening area.
2. The player understood days advance narratively, not in real time.
3. The player discovered or remembered wet as a reusable verb after Mudflats.
4. The Salt Market recognition beat clearly opened the Act I hub.
5. The player could identify the three Rites without external explanation.
6. Each Rite felt like a scene chain, not just a checklist.
7. The Registrar duel communicated category, weight, Salt, and spent-card stakes.
8. The accepted Registrar route stayed emotionally legible.
9. The Teodor booth felt like an authored scene, not a missing choice UI.
10. The Grey Float stayed hard-R rather than explicit or coy.
11. The Harbormaster pulse check read as physical staging, not inventory magic.
12. Sabine's Act I entrance landed as the act break.
13. The player wanted to continue into Act II.
14. No line, prop, or staging beat violated the hard-R content line.
15. No player confusion suggested adding a second confession-spend interface.
```

## Timing Targets

These are first-pass targets, not hard gates.

| Segment | Target |
|---|---:|
| Mudflats to Salt Market scream | 8-12 minutes |
| Finding all three Rites | 10-18 minutes |
| Name Restored branch | 12-20 minutes |
| Debt Forgiven branch | 10-18 minutes |
| Borrowed Heartbeat branch | 12-20 minutes |
| Sabine office close | 4-8 minutes |

## Rescue Marks

Write the exact moment if the tester needs help:

```text
Rescue 1:
  Room:
  Hotspot or UI:
  What they tried:
  What they missed:
  Was this wording, layout, verb, or logic?

Rescue 2:
  Room:
  Hotspot or UI:
  What they tried:
  What they missed:
  Was this wording, layout, verb, or logic?
```

## Notes To Capture

```text
Tester:
Date:
Build or commit:
Run length:
Finished Act I: yes / no

First place they stalled:

Most satisfying puzzle beat:

Most confusing puzzle beat:

Line that should be cut before VO:

Line that needs more room to breathe:

Prop that was too hard to read:

Did the wet verb feel useful or gimmicky?

Did the duel feel like confession or math?

Did any choice feel morally expensive?

Did any Act I script/source contradiction confuse review?

Keep / revise before art / stop and redesign:
```

## Decision Rule

Proceed toward final Act I art only if the final answer is `keep` or `revise before art`.

If the answer is `stop and redesign`, do not start paintovers or sprite-sheet production. Fix the failed scene chain or duel comprehension issue in greybox first.
