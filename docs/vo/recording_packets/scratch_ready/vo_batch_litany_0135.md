# VO Recording Packet - vo_batch_litany_0135

Queue status: scratch_ready
Shipping status: scratch_only_not_shipping_audio
Batch type: litany_category_run
Act: Act 3
Speaker: CORVIN
Scratch voice: Callum / N2lVS1w4EtoT3dr4eOWO
Cast status: scratch_cast
Location: confessions
Knot: 
Category: GREED
Line count: 4
Word count: 61

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
| vo_confession_cf_greed_grave | data/confessions.json#cf_greed_grave | vo/confessions/cf_greed_grave.mp3 | I sold my own plot. The one next to my father. |
| vo_confession_cf_greed_grave_elaboration | data/confessions.json#cf_greed_grave | vo/confessions/cf_greed_grave_elaboration.mp3 | I needed the money for something. I can't remember what. That's the part that's started to bother me. |
| vo_confession_cf_greed_policy | data/confessions.json#cf_greed_policy | vo/confessions/cf_greed_policy.mp3 | I told a woman her husband's policy had lapsed. |
| vo_confession_cf_greed_policy_elaboration | data/confessions.json#cf_greed_policy | vo/confessions/cf_greed_policy_elaboration.mp3 | It hadn't. I bought it off her at eleven percent and cashed it the same week. She sends me a card at midwinter. |

## Context Lines

| Line ID | Speaker | Text |
|---|---|---|
| vo_confession_cf_greed_grave | CORVIN | I sold my own plot. The one next to my father. |
| vo_confession_cf_greed_grave_elaboration | CORVIN | I needed the money for something. I can't remember what. That's the part that's started to bother me. |
| vo_confession_cf_greed_policy | CORVIN | I told a woman her husband's policy had lapsed. |
| vo_confession_cf_greed_policy_elaboration | CORVIN | It hadn't. I bought it off her at eleven percent and cashed it the same week. She sends me a card at midwinter. |
