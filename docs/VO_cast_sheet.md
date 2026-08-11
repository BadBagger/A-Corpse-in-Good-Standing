# VO CAST SHEET — SCRATCH TRACK
### *A Corpse in Good Standing*
ElevenLabs configuration. **Scratch/temp only — see §5 before considering shipping any of this.**

---

## 1. LOCKED CAST

| Character | Voice | ID | Notes |
|---|---|---|---|
| **Corvin Vale** | Callum | `N2lVS1w4EtoT3dr4eOWO` | Rough, characterful, mid-range. Anchor voice — all other casting is judged against him. |
| **Tomas (bollard)** | Roger | `CwhRBWXzGAHq8TQ4Fs17` | Casual, confident, clearly separable from Callum. |
| **Sabine Croix** | Charlotte | `XB0fDUnXU5powFXDhCwa` | Low, character texture. Controlled without going cold. |
| **Ossuary Kane** | Thomas | `GBv7mTt0atIp3Br8iCZE` | Calm, meditative. Never plays menace — which is the entire point of the character. |
| **Mireille Dax** | Lily | `pFZP5JQG7iQjIQuC4Bku` | Soft, musical. Charm covering active memory loss — recovers *brighter*, never sadder. |
| **Juno Ash** | Domi | `AZnzlk1XvdvUeBnXmlld` | Strong, hard-edged. Hospitable and bitter without contradiction. |
| **Brother Teodor** | Eric | `cjVigY5qzO86Huf0OWal` | Boyish — the one role where that's the brief. Rejected as Tomas for exactly this quality. |
| **The Registrar** | Alice | `Xb7hH8MSUJpSbSDYk0k2` | Clipped, administrative. Forty years of striking out names. |
| **Bone Chandler** | Will | `bIHbv24MWmeRgasZH58o` | Cheerful about horrifying things. Genuine exactly once. |
| **Half-Coin Prosper** | Bill | `pqHfZKP75CvOlQylNhV4` | Warm, blank, delighted. Never sad — the tragedy is in the writing. |

**Unconfirmed:** Teodor, Registrar, Chandler, and Prosper were cast on single takes rather than slates. Re-audition if any read wrong in context.

**Cast complete — 11 of 11.**

**Backup:** River `SAz9YHcvj6GT2YYXdXww` — close second for Sabine, neutral and unhurried. Hold in reserve rather than discard; useful if Charlotte's texture causes problems in longer scenes.

**Corvin is the anchor.** He appears in every scene in the game. Never recast him to fit someone else; recast the other role.

---

## 2. REJECTED — AND WHY

Keeping this so the same ground isn't re-covered.

| Voice | ID | Tried as | Rejected because |
|---|---|---|---|
| Daniel | `onwK4e9ZLuTAKqWW03F9` | Corvin | Narrator voice. Broadcast-polished, read like a newsreader. |
| George | `JBFqnCBsd6RMkjVDRZzb` | Tomas | Narrator voice. Same problem. |
| Chris | `iP95p4xoKVk53GoZ742B` | Corvin | Beaten by Callum. |
| Will | `bIHbv24MWmeRgasZH58o` | Corvin | Beaten by Callum. |
| Liam | `TX3LPaxmHKxFdv7VOQHJ` | Corvin | Too young/light. |
| Eric | `cjVigY5qzO86Huf0OWal` | Tomas | Close second, but boyish. **Later cast as Teodor.** |
| Bill | `pqHfZKP75CvOlQylNhV4` | Tomas | Good in isolation, too close to Callum's texture in shared scenes. |
| Charlie | `IKne3meq5aSn9XLyUdCD` | Tomas | Beaten by Roger. |
| Alice | `Xb7hH8MSUJpSbSDYk0k2` | Sabine | Beaten by Charlotte. |
| Matilda | `XrExE9yKIg1WjnnlVkGX` | Sabine | Too warm — softened the wrist beat. |
| Bill | `pqHfZKP75CvOlQylNhV4` | Kane | Close, but beaten by Thomas. |
| Brian | `nPczCjzI2devNBz1zQrb` | Kane | Beaten by Thomas. |
| George | `JBFqnCBsd6RMkjVDRZzb` | Kane (re-test) | Narrator polish didn't rescue him even on formal dialogue. |
| Michael | `flq6f7yk4E4fJM5XTYuZ` | Kane | Beaten by Thomas. |
| Fin | `D38z5RcWu1voky8WS1ja` | Kane | Read as sailor rather than aristocrat. |
| Matilda | `XrExE9yKIg1WjnnlVkGX` | Mireille (re-test) | Beaten by Lily. |
| Aria | `9BWtsMINqrJLrRacOk9x` | Mireille | Beaten by Lily. |
| Grace | `oWAxZDx7w5VEj9dCyTzz` | Juno | Beaten by Domi — too soft for thirty years of grievance. |

**Two rules learned:**
1. **Avoid narrator/audiobook voices entirely.** They're built for neutral delivery and cannot do character work. This was the single biggest early mistake.
2. **Avoid boyish timbre for any character over forty.** Rules out most of the "friendly conversational" shelf for Tomas, Juno, Kane, the Registrar, and Prosper.
3. **Cast antagonists from the calm/meditative shelf, not the gruff/character shelf.** Given villain lines, models add menace by default. Picking a voice built for gentleness counteracts that at the source, which works far better than fighting it with tags.

---

## 3. GENERATION SETTINGS

```
model_id:      eleven_v3          ← required; v2 was flat and listless
output_format: mp3_44100_128
```

**Do not generate with `eleven_multilingual_v2`.** Side-by-side, v2 produced the "robotic" reads. v3 with inline tags is the only configuration that worked.

### Tag vocabulary that produced usable takes

```
[dry]              [flat]            [unbothered]
[wry]              [quiet]           [small]
[empty]            [barely there]    [trailing off]
[too fast, deflecting]               [weary, amused]
[patient]          [careful, gentle] [firm, kind]
[softly]           [almost a whisper]
```

**Tag every line individually.** Untagged lines revert to neutral and flatten the whole take.

### Method note — matters more than the voice pick

Early takes failed partly because lines were fed as **disconnected fragments** with the other character's dialogue stripped out. TTS has no conversational momentum to ride and resets to neutral on every line.

For any multi-line scene: feed the full run of one character's lines **in scene order**, with per-line emotional tags reflecting where that line sits in the scene's arc. Do not generate line-by-line in isolation.

---

## 4. CASTING COMPLETE

All eleven speaking roles cast. **Bill was auditioned three times** (Tomas, Kane, Prosper) before landing — worth noting that a voice rejected for one role is often right for another, so keep the rejected list rather than discarding it.

**Both hard roles passed.** Sabine ("controlled but not cold") and Kane ("warm, never menacing") sit in the registers where TTS usually collapses, and were the two most likely to prove the VO route unworkable. Both cast cleanly. No further evidence against the route is expected from casting — the open questions are now licensing and audience reception, not capability. See §5.

---

## 5. STATUS — SCRATCH ONLY

This cast is a **temp track** for timing, pacing, and testing whether lines land. It is not a shipping decision.

**Before any of this goes in a build:**

- **AI voice in a commercial indie game currently draws real backlash.** Same pattern as AI art on the Twitch pack. This is a live controversy, not a hypothetical.
- ElevenLabs stock library voices carry **licensing terms that vary by tier and by use case.** Commercial game distribution is not the same as personal use. Verify before shipping, not after.
- The three options from the VO test script still stand: full VO, partial VO (Corvin only, ~300 lines), or text-only. **Monkey Island 1 shipped with no voice at all.**

**Recommended:** use this scratch track through Act I development for timing and pacing, then decide. Do not let "the temp track sounds fine" become the shipping decision by default — that's how temp tracks get shipped.

---

## 7. OPEN BLOCKERS — NOT VO

Captured here so they don't get lost. None of these moved while casting happened.

1. **Duel prototype "is it fun with 12 confessions" checkpoint** — unmet. Gates the remaining 50 confessions and everything downstream. This is build step 1 and the highest-value next action.
2. **`game/gui/gui.tscn` missing** — Popochiu GUI variant never instantiated. Small fix, but blocks calling the scaffold checkpoint green.
3. **Ink-wash shader spike** — specced with calibrated gates (R5 24-frame yaw turn, good/bad controls), never run.
4. **Pixel art vs 3D-toon hybrid** — undecided. If pixel wins, the shader spike is void and the salt-decay slider becomes 3× the character budget instead of a parameter. **Decide before running the spike, not after.**

---

## 8. FILE NAMING

Bind audio to script IDs so lines can be traced back to source:

```
vo/{room_id}/{dialogue_node}_{line_index}_{character}.mp3

vo/R02_old_quay/DL_tomas_main_004_corvin.mp3
vo/R02_old_quay/DL_tomas_main_005_tomas.mp3
```

Hotspot lines:
```
vo/{room_id}/{hotspot_id}_{verb}_{variant}.mp3
vo/R05_registry/HS_roll_book_look_01.mp3
```

Confession lines key off the confession ID directly:
```
vo/confessions/{confession_id}.mp3
vo/confessions/{confession_id}_elaboration.mp3

vo/confessions/cf_bt_manifest.mp3
vo/confessions/cf_bt_manifest_elaboration.mp3
```

**Note the volume implication:** 62 confessions × 2 files = 124 Corvin lines for the duel system alone, before a single room hotspot. Worth knowing before committing to full VO.
