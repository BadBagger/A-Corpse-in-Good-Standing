# THE LITANY — Full Confession Library
### *A Corpse in Good Standing* · Confession Duel content spec
62 entries · Codex handoff · companion to `AGENTS_corpse_in_good_standing.md`

---

## 0. SPEC CORRECTION

The original brief contained a contradiction: gate G3 asked for "≥8 per category, ≥4 BETRAYAL" while §6.3 stated Corvin holds "exactly four BETRAYAL confessions in the whole game." Both can't be true as thresholds.

**Resolved:** BETRAYAL is a deliberate exception. Exactly 4, never more — its rarity is what makes the endgame null-play work. All other categories carry 11–12.

**G3 is hereby restated:** `≥11 each in GREED, LUST, PRIDE, CRUELTY, COWARDICE; exactly 4 in BETRAYAL; ≥60 total.` Codex should update the gate table rather than treat this as a soft note.

Current library: **62** — GREED 12 · LUST 12 · PRIDE 12 · CRUELTY 11 · COWARDICE 11 · BETRAYAL 4.

---

## 1. HOW TO READ AN ENTRY

```
id · CATEGORY · weight · act available · acquisition
> The confession line — what Corvin says to counter.
— The elaboration — the "say the rest" beat that lands the hit.
```

**Weights:** 1–7 for the five common categories. BETRAYAL is fixed at 8 and cannot be outweighed.

**Trump order:** GREED → LUST → PRIDE → CRUELTY → COWARDICE → BETRAYAL. A counter must match or trump the attack's category **and** strictly exceed its weight. Equal weight fails.

**Acquisition types:**
- `OVERHEARD` — picked up eavesdropping around Mordida. Free. Mostly light.
- `EXCAVATED` — Corvin recovering his own buried past. Puzzle-gated. Mid-weight.
- `COMMITTED` — Act II onward. The player must actually do the awful thing to earn the card. Heavy.

That last category is the design's spine: **restocking your deck means becoming worse.** Codex must not let a COMMITTED confession be acquired passively.

---

## 2. GREED
*Trump index 0. Counters only GREED. The cheap stuff — spend it freely, it won't save you later.*

**cf_greed_drink** · GREED · 1 · Act I · OVERHEARD
> "I've never bought a drink I could talk someone into buying."
— "I have a face people want to be generous at. I've never corrected it."

**cf_greed_scales** · GREED · 2 · Act I · OVERHEARD
> "I keep a second set of scales."
— "The honest ones are on the wall where you can see them. That's what they're for."

**cf_greed_plate** · GREED · 2 · Act I · OVERHEARD
> "I've taken change out of a collection plate."
— "Not coins. Notes. Coins make a sound."

**cf_greed_widows** · GREED · 3 · Act I · OVERHEARD
> "I charge widows double."
— "They cry less when it's expensive. Makes them feel like they've done something."

**cf_greed_wills** · GREED · 3 · Act I · EXCAVATED
> "I've read every will I ever witnessed. Twice, if there was property."
— "You learn a family faster from a will than from a wedding."

**cf_greed_boots** · GREED · 4 · Act I · EXCAVATED
> "I took a dead man's boots before I reported the body."
— "He'd been in the water two days. I waited for the tide to bring the second one."

**cf_greed_writeoff** · GREED · 4 · Act II · EXCAVATED
> "I've never given anything away I couldn't write off."
— "There's a column for charity. That's the only place it's ever appeared."

**cf_greed_candles** · GREED · 5 · Act II · COMMITTED
> "I charged the Church for candles I stole from the Church."
— "Teodor thanked me for the discount."

**cf_greed_berth** · GREED · 5 · Act II · EXCAVATED
> "I sold the same berth twice in one morning and stood on the quay to watch them work it out."
— "One of them lost a thumb. I'd already been paid by both, so I stayed for the end."

**cf_greed_ring** · GREED · 6 · Act II · EXCAVATED
> "I let a boy pay me with his mother's ring."
— "I knew whose it was. I knew she was still alive. I asked if she'd want him to have it, and he said yes, and I took it anyway."

**cf_greed_policy** · GREED · 7 · Act III · COMMITTED
> "I told a woman her husband's policy had lapsed."
— "It hadn't. I bought it off her at eleven percent and cashed it the same week. She sends me a card at midwinter."

**cf_greed_grave** · GREED · 7 · Act III · COMMITTED
> "I sold my own plot. The one next to my father."
— "I needed the money for something. I can't remember what. That's the part that's started to bother me."

---

## 3. LUST
*Trump index 1. Counters GREED and LUST. Where the game's appetite lives — most of these are about wanting, not having.*

**cf_lust_arguments** · LUST · 2 · Act I · OVERHEARD
> "I've kissed people to end arguments I was losing."
— "It works. That's the ugly part. It works almost every time."

**cf_lust_advice** · LUST · 3 · Act I · EXCAVATED
> "I've undressed every woman who's ever asked me for legal advice."
— "Not with my hands. That would at least have been honest."

**cf_lust_tar** · LUST · 3 · Act I · EXCAVATED
> "There's a smell — tar and orange peel — that stops me dead in the street."
— "I stand there like an idiot until it's gone. Twelve years. I still do it. I did it yesterday and I don't have a nose anymore."

**cf_lust_float** · LUST · 4 · Act I · OVERHEARD
> "I go to the Float and pay for conversation."
— "And I let them think it's the other thing, because the other thing is less embarrassing to want."

**cf_lust_schedule** · LUST · 5 · Act I · EXCAVATED
> "I learned her husband's schedule before I learned her name."
— "I told myself it was diligence."

**cf_lust_timing** · LUST · 5 · Act II · EXCAVATED
> "I wanted her before she was free to want me back."
— "And I made sure she knew it. At the worst possible moment. On purpose, so she'd have to carry it too."

**cf_lust_marriages** · LUST · 6 · Act II · EXCAVATED
> "I've notarized four marriages I was actively trying to ruin."
— "I have very good handwriting. Nobody looks at a man with good handwriting and thinks about what he wants."

**cf_lust_waiting** · LUST · 6 · Act II · EXCAVATED
> "I told her I'd wait."
— "I didn't wait. That's not the confession. The confession is that I never told her when I stopped, so she was still being faithful to something that wasn't there."

**cf_lust_burn** · LUST · 4 · Act II · EXCAVATED
> "I memorized the burn on her arm before I ever asked how she got it."
— "I still haven't asked. I like the version I made up."

**cf_lust_mireille** · LUST · 5 · Act III · COMMITTED
> "I sat with a dying woman and part of me was just glad to be looked at."
— "She was on day eight. She was forgetting her own name mid-sentence. And I was thinking about how she said mine."

**cf_lust_hands** · LUST · 6 · Act III · EXCAVATED
> "I can't feel anything anymore and I still reach for people."
— "I put my hand on Teodor's shoulder last week for no reason at all. Just to check. There was nothing there. I did it again the next day."

**cf_lust_still** · LUST · 7 · Act III · EXCAVATED
> "I still want her. Knowing what she signed."
— "That's the part I can't get out from under. Not that she did it. That it didn't change anything."

---

## 4. PRIDE
*Trump index 2. Counters GREED, LUST, PRIDE. Corvin's most abundant sin and his least self-aware.*

**cf_pride_voice** · PRIDE · 2 · Act I · OVERHEARD
> "I'm dead and I'm still doing the voice."
— "The one I use for clients. Lower. Slower. You've been hearing it this whole time."

**cf_pride_hated** · PRIDE · 2 · Act I · OVERHEARD
> "I'd rather be hated accurately than liked by mistake."
— "I've arranged my entire life around that and I've never once examined it."

**cf_pride_dontknow** · PRIDE · 3 · Act I · OVERHEARD
> "I've never once said 'I don't know' to a paying client."
— "I've said a great many other things instead. Some of them were even true."

**cf_pride_list** · PRIDE · 3 · Act I · EXCAVATED
> "I keep a list of everyone who's ever been wrong about me."
— "It's alphabetical. It's four pages. I update it."

**cf_pride_twice** · PRIDE · 3 · Act I · EXCAVATED
> "I've been the smartest man in a room exactly twice."
— "And I've never let anyone forget either occasion, including the people who weren't there."

**cf_pride_counselor** · PRIDE · 5 · Act I · EXCAVATED
> "I let people call me 'counselor.'"
— "I've never passed a bar. I've never sat one. I've never been in a room where one was being sat."

**cf_pride_handwriting** · PRIDE · 4 · Act II · EXCAVATED
> "When they struck my name off the roll, the part that hurt was the handwriting."
— "They didn't even do it neatly. Four thousand names in that book and mine's the one they scratched."

**cf_pride_famine** · PRIDE · 5 · Act II · EXCAVATED
> "I turned down honest work because the title was beneath me."
— "Twice. During the 'thirty-nine famine. I ate. Other people made other arrangements."

**cf_pride_eulogy** · PRIDE · 5 · Act II · EXCAVATED
> "I've been practicing my own eulogy for years."
— "I got to hear it. It was nothing like mine. It was four sentences and one of them was about the weather."

**cf_pride_lastwords** · PRIDE · 6 · Act II · EXCAVATED
> "I rewrote a man's last words."
— "His were clumsy. He said something about a dog. I gave the family something they could put on a stone."

**cf_pride_grammar** · PRIDE · 4 · Act I · OVERHEARD
> "I corrected a dying man's grammar."
— "He had about nine minutes left and I spent one of them on 'whom.'"

**cf_pride_kestrel** · PRIDE · 7 · Act II · EXCAVATED
> "I let Tomas take the blame for the Kestrel papers."
— "Not to save myself. He could afford to look stupid and I couldn't. That was the whole calculation. That was all of it."

---

## 5. CRUELTY
*Trump index 3. Counters everything below it. This is where Corvin stops being charming.*

**cf_cruel_sermon** · CRUELTY · 2 · Act I · OVERHEARD
> "I told Teodor his sermon was good."
— "It wasn't. I wanted to see how long he'd ride it. He's still riding it."

**cf_cruel_funeral** · CRUELTY · 3 · Act I · OVERHEARD
> "I laughed at a funeral, and I wasn't nervous."
— "It was just funny. It's still funny. I'd tell you but you'd have known him."

**cf_cruel_soupline** · CRUELTY · 4 · Act I · EXCAVATED
> "I gave a beggar directions to a soup line."
— "It closed in 'thirty-eight. I knew that. I wanted him to walk somewhere else and I didn't want to say so."

**cf_cruel_sentences** · CRUELTY · 4 · Act I · EXCAVATED
> "I've never hit anyone."
— "I've never had to. I'm very good with sentences. I've done more damage sitting down than most men manage standing up."

**cf_cruel_receipts** · CRUELTY · 5 · Act II · EXCAVATED
> "I keep people's worst moments the way other men keep receipts."
— "Filed. Dated. I know exactly where every one of them is and I can produce it inside a minute."

**cf_cruel_names** · CRUELTY · 5 · Act II · EXCAVATED
> "I've made three people cry on purpose."
— "I remember all their names. Fondly. That's the confession — not the crying, the fondly."

**cf_cruel_child** · CRUELTY · 6 · Act II · COMMITTED
> "I told a child the truth about his father."
— "Not to help him. I was tired and he was standing between me and a door."

**cf_cruel_adelie** · CRUELTY · 6 · Act II · COMMITTED
> "I let Adelie tell me about her husband for a full hour."
— "I already knew he'd sold her. I let her get all the way to the end of the good version first."

**cf_cruel_mother** · CRUELTY · 6 · Act III · EXCAVATED
> "I was relieved when my mother stopped writing."
— "I'd been leaving the letters sealed for two years. When they stopped I felt lighter, and then I felt nothing, and the nothing lasted longer."

**cf_cruel_diagnosis** · CRUELTY · 7 · Act III · COMMITTED
> "I read a man's diagnosis aloud in a crowded room."
— "To win a point about confidentiality. I won the point."

**cf_cruel_forgiven** · CRUELTY · 7 · Act III · EXCAVATED
> "I've never forgiven anyone."
— "I've only ever waited people out. There's a difference and I've been trading on it my whole life."

---

## 6. COWARDICE
*Trump index 4. Counters everything but BETRAYAL. The heaviest common category and the one that hurts him most to say.*

**cf_cow_drink** · COWARDICE · 1 · Act I · OVERHEARD
> "I say 'we should get a drink' to people I'm hoping never to see again."
— "I've said it to you. Twice."

**cf_cow_apologize** · COWARDICE · 2 · Act I · OVERHEARD
> "I've apologized to end conversations. Never to mean it."
— "It's the fastest word in the language. Nobody checks it."

**cf_cow_leftroom** · COWARDICE · 3 · Act I · OVERHEARD
> "I've left a room rather than say a true thing in it."
— "I have a bad knee that flares up at exactly the right moment. It's a very obedient knee."

**cf_cow_bigger** · COWARDICE · 3 · Act I · EXCAVATED
> "I've agreed with men I despise because they were bigger."
— "Every time. Without exception. I've never once found out what would happen if I didn't."

**cf_cow_passive** · COWARDICE · 4 · Act I · EXCAVATED
> "I write in the passive voice."
— "So nobody can find the hand that did it. *Errors were made. The cargo was cleared.* Twenty years of sentences with nobody in them."

**cf_cow_father** · COWARDICE · 5 · Act II · EXCAVATED
> "I've been dead nine days and I haven't gone to see my father's grave."
— "It's four streets. I've walked past the gate twice. I have six days left and I'm going to spend them not doing it."

**cf_cow_questions** · COWARDICE · 5 · Act II · EXCAVATED
> "I've never asked her a question I didn't already know the answer to."
— "In case. Twelve years of conversation and I've never once been surprised on purpose."

**cf_cow_fire** · COWARDICE · 6 · Act II · EXCAVATED
> "I ran from a fire and told myself I was going for help."
— "I went home. I made tea. I read for an hour. I remember what I read."

**cf_cow_why** · COWARDICE · 6 · Act III · EXCAVATED
> "When she told me what she'd signed, I didn't ask why."
— "I still haven't. And it isn't dignity. I'm afraid the reason's a good one, and then I'd have nothing left to be angry about."

**cf_cow_hanged** · COWARDICE · 7 · Act III · EXCAVATED
> "A man hanged for a signature I forged."
— "I attended. I stood at the back. I've told myself for six years that going was the decent thing, and standing at the back is the reason I know it wasn't."

**cf_cow_didntfight** · COWARDICE · 7 · Act III · EXCAVATED
> "When they put me under, I didn't fight."
— "Everyone assumes I did. It's the one part nobody's asked about. There was a hand on the back of my neck and I just — went. Like I'd been waiting to be told."

---

## 7. BETRAYAL
*Trump index 5. Counters anything. Weight 8, fixed, unbeatable. **Exactly four exist.** Every one is a puzzle reward, never an incidental pickup.*

**cf_bt_manifest** · BETRAYAL · 8 · Act I · EXCAVATED
> "I read it. Twice."
— "The Kestrel manifest. Eleven people in that hold, listed as freight. I read it twice — I wanted to be certain of the number before I took the money."

**cf_bt_tomas** · BETRAYAL · 8 · Act II · EXCAVATED
> "I gave them Tomas's name."
— "He's the third bollard past the customs house. People tie boats to him. He's still glad to see me. That's the worst of it — he's still glad to see me and he doesn't know why he shouldn't be."

**cf_bt_harbor** · BETRAYAL · 8 · Act II · COMMITTED
> "I signed her out of her own harbor."
— "Sabine gave me one document to witness and told me not to read it. So I read it, and I understood it, and I notarized it anyway, and that signature is why Kane can walk into her office whenever he likes."

**cf_bt_again** · BETRAYAL · 8 · Act III · EXCAVATED
> "I'd do all of it again."
— "Every part. The manifest, Tomas, the harbor. If it put her hand back on my wrist for one second — I'd do all of it again, and I'd be quicker about it the second time."

> **Design note.** The fourth confession is the trap and the point. Every other BETRAYAL is remorse. This one is Corvin admitting his remorse is fake — that given the same choices he'd repeat them for a woman's hand on his wrist. It's the last thing he owns, and spending it is what empties him out for the Kane duel. Codex: `cf_bt_again` must be the final BETRAYAL acquirable, and the null-play gate checks all four `spent == true`.

---

## 8. IMPLEMENTATION

**Schema** (`/data/confessions.json`):
```json
{
  "id": "cf_bt_manifest",
  "text": "I read it. Twice.",
  "elaboration": "The Kestrel manifest. Eleven people in that hold...",
  "category": "BETRAYAL",
  "weight": 8,
  "act_available": 1,
  "acquisition": "EXCAVATED",
  "source_node": "room_registry_ledger",
  "spent": false
}
```

**Resolution:**
```
valid = counter.weight > attack.weight
     && TRUMP.indexOf(counter.category) >= TRUMP.indexOf(attack.category)
```
Strictly greater on weight. The equal-weight failure is load-bearing, not an off-by-one.

**Rules Codex must enforce:**
- `spent` is global and permanent. A failed play still spends the card.
- A confession spoken by an *opponent* as an attack is locked out of the player's defense pool for the rest of the game.
- COMMITTED confessions require their source action to have actually occurred. Never grant one from dialogue alone.
- Elaboration text is mandatory on every successful counter. A counter without its elaboration does half damage — that's the fiction of willing confession, and it must be mechanical.

**Additional gate:**

| # | Gate | Threshold |
|---|---|---|
| G13 | Every attack line in `/duels/opponents/*.json` has ≥2 valid counters available at its earliest possible encounter | 100%, automated solver |
| G14 | Category distribution | GREED/LUST/PRIDE ≥11, CRUELTY/COWARDICE ≥11, BETRAYAL == 4 exactly |
| G15 | No confession is acquirable before its `act_available` | 100%, static check |
| G16 | `cf_bt_again` is unreachable until the other three BETRAYAL entries are spent | unit test, positive + negative |
