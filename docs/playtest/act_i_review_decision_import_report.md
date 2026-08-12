# Act I Review Decision Import Report

Mode: apply
Input CSV: `docs\playtest\results\act_i_review_decision_import_test.csv`
Rows: 11
Approved: 1
Revise before art: 1
Stop and redesign: 0
Pending review: 9

Rule locks:
- Accepted Litany/Registrar duel format remains locked.
- Grey Float remains hard-R: steam, silhouette, privacy, and agency only.
- Non-pending decisions require build_commit from the generated human-review notes.
- Non-pending decisions require reviewer, reviewed_at, and decision_note.
- Non-pending decisions require look_target_reviewed=yes for the Act I look target reference.
- Non-pending decisions require corvin_action_scaffold_reviewed=yes for the Corvin side-action Blender handoff.
- Harbor Registry non-pending decisions require an explicit duel_format note from the reviewer.

| Room | Previous | Incoming | Build | Reviewer | Fix Note |
|---|---|---|---|---|---|
| R01 Mudflats | pending_review | pending_review | 3c710597fce7 |  | False |
| R02 The Old Quay | pending_review | pending_review | 3c710597fce7 |  | False |
| R03 Salt Market | pending_review | pending_review | 3c710597fce7 |  | False |
| R05 Harbor Registry | approved | approved | 3c710597fce7 | Automated test | True |
| R06 The Bone Chandler | pending_review | pending_review | 3c710597fce7 |  | False |
| R07 The Almshouse | pending_review | pending_review | 3c710597fce7 |  | False |
| R08 The Fish Hall | pending_review | pending_review | 3c710597fce7 |  | False |
| R09 Church of the Drowned | pending_review | pending_review | 3c710597fce7 |  | False |
| R10 The Grey Float | revise_before_art | revise_before_art | 3c710597fce7 | Automated test | True |
| R11 Harbormaster's Office | pending_review | pending_review | 3c710597fce7 |  | False |
| R12 Sabine's Office | pending_review | pending_review | 3c710597fce7 |  | False |
