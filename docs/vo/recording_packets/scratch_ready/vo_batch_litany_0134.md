# VO Recording Packet - vo_batch_litany_0134

Queue status: scratch_ready
Shipping status: scratch_only_not_shipping_audio
Batch type: litany_category_run
Act: Act 3
Speaker: CORVIN
Scratch voice: Callum / N2lVS1w4EtoT3dr4eOWO
Cast status: scratch_cast
Location: confessions
Knot: 
Category: CRUELTY
Line count: 6
Word count: 75

Generation rule: Generate as a category run; keep each confession immediately followed by its elaboration.
Notes: Litany text is generated from data/confessions.json only.

Rule locks:
- Generate this as one batch in source order, not as disconnected one-line fragments.
- Use this packet for scratch timing only; it is not shipping audio approval.
- Respect the listed audio paths exactly.
- Keep the accepted Litany/Registrar duel format.

## Target Lines

| Line ID | Source | Audio path | Text |
|---|---|---|---|
| vo_confession_cf_cruel_diagnosis | data/confessions.json#cf_cruel_diagnosis | vo/confessions/cf_cruel_diagnosis.mp3 | I read a man's diagnosis aloud in a crowded room. |
| vo_confession_cf_cruel_diagnosis_elaboration | data/confessions.json#cf_cruel_diagnosis | vo/confessions/cf_cruel_diagnosis_elaboration.mp3 | To win a point about confidentiality. I won the point. |
| vo_confession_cf_cruel_forgiven | data/confessions.json#cf_cruel_forgiven | vo/confessions/cf_cruel_forgiven.mp3 | I've never forgiven anyone. |
| vo_confession_cf_cruel_forgiven_elaboration | data/confessions.json#cf_cruel_forgiven | vo/confessions/cf_cruel_forgiven_elaboration.mp3 | I've only ever waited people out. There's a difference and I've been trading on it my whole life. |
| vo_confession_cf_cruel_mother | data/confessions.json#cf_cruel_mother | vo/confessions/cf_cruel_mother.mp3 | I was relieved when my mother stopped writing. |
| vo_confession_cf_cruel_mother_elaboration | data/confessions.json#cf_cruel_mother | vo/confessions/cf_cruel_mother_elaboration.mp3 | I'd been leaving the letters sealed for two years. When they stopped I felt lighter, and then I felt nothing, and the nothing lasted longer. |

## Context Lines

| Line ID | Speaker | Text |
|---|---|---|
| vo_confession_cf_cruel_diagnosis | CORVIN | I read a man's diagnosis aloud in a crowded room. |
| vo_confession_cf_cruel_diagnosis_elaboration | CORVIN | To win a point about confidentiality. I won the point. |
| vo_confession_cf_cruel_forgiven | CORVIN | I've never forgiven anyone. |
| vo_confession_cf_cruel_forgiven_elaboration | CORVIN | I've only ever waited people out. There's a difference and I've been trading on it my whole life. |
| vo_confession_cf_cruel_mother | CORVIN | I was relieved when my mother stopped writing. |
| vo_confession_cf_cruel_mother_elaboration | CORVIN | I'd been leaving the letters sealed for two years. When they stopped I felt lighter, and then I felt nothing, and the nothing lasted longer. |
