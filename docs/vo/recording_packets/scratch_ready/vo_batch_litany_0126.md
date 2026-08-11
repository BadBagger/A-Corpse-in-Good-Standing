# VO Recording Packet - vo_batch_litany_0126

Queue status: scratch_ready
Shipping status: scratch_only_not_shipping_audio
Batch type: litany_category_run
Act: Act 2
Speaker: CORVIN
Scratch voice: Callum / N2lVS1w4EtoT3dr4eOWO
Cast status: scratch_cast
Location: confessions
Knot: 
Category: BETRAYAL
Line count: 4
Word count: 92

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
| vo_confession_cf_bt_harbor | data/confessions.json#cf_bt_harbor | vo/confessions/cf_bt_harbor.mp3 | I signed her out of her own harbor. |
| vo_confession_cf_bt_harbor_elaboration | data/confessions.json#cf_bt_harbor | vo/confessions/cf_bt_harbor_elaboration.mp3 | Sabine gave me one document to witness and told me not to read it. So I read it, and I understood it, and I notarized it anyway, and that signature is why Kane can walk into her office whenever he likes. |
| vo_confession_cf_bt_tomas | data/confessions.json#cf_bt_tomas | vo/confessions/cf_bt_tomas.mp3 | I gave them Tomas's name. |
| vo_confession_cf_bt_tomas_elaboration | data/confessions.json#cf_bt_tomas | vo/confessions/cf_bt_tomas_elaboration.mp3 | He's the third bollard past the customs house. People tie boats to him. He's still glad to see me. That's the worst of it — he's still glad to see me and he doesn't know why he shouldn't be. |

## Context Lines

| Line ID | Speaker | Text |
|---|---|---|
| vo_confession_cf_bt_harbor | CORVIN | I signed her out of her own harbor. |
| vo_confession_cf_bt_harbor_elaboration | CORVIN | Sabine gave me one document to witness and told me not to read it. So I read it, and I understood it, and I notarized it anyway, and that signature is why Kane can walk into her office whenever he likes. |
| vo_confession_cf_bt_tomas | CORVIN | I gave them Tomas's name. |
| vo_confession_cf_bt_tomas_elaboration | CORVIN | He's the third bollard past the customs house. People tie boats to him. He's still glad to see me. That's the worst of it — he's still glad to see me and he doesn't know why he shouldn't be. |
