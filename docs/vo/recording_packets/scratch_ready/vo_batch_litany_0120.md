# VO Recording Packet - vo_batch_litany_0120

Queue status: scratch_ready
Shipping status: scratch_only_not_shipping_audio
Batch type: litany_category_run
Act: Act 1
Speaker: CORVIN
Scratch voice: Callum / N2lVS1w4EtoT3dr4eOWO
Cast status: scratch_cast
Location: confessions
Knot: 
Category: BETRAYAL
Line count: 2
Word count: 32

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
| vo_confession_cf_bt_manifest | data/confessions.json#cf_bt_manifest | vo/confessions/cf_bt_manifest.mp3 | I read it. Twice. |
| vo_confession_cf_bt_manifest_elaboration | data/confessions.json#cf_bt_manifest | vo/confessions/cf_bt_manifest_elaboration.mp3 | The Kestrel manifest. Eleven people in that hold, listed as freight. I read it twice — I wanted to be certain of the number before I took the money. |

## Context Lines

| Line ID | Speaker | Text |
|---|---|---|
| vo_confession_cf_bt_manifest | CORVIN | I read it. Twice. |
| vo_confession_cf_bt_manifest_elaboration | CORVIN | The Kestrel manifest. Eleven people in that hold, listed as freight. I read it twice — I wanted to be certain of the number before I took the money. |
