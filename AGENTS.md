# A CORPSE IN GOOD STANDING
### *Nine Days on Isla Mordida*
**Story bible + build brief — Codex handoff**
Genre: point-and-click adventure (Monkey Island structural DNA, noir/occult tone)
Target: Godot 4.6.3 .NET · Popochiu 2.1.1 · Ink · GUT

---

## 0. BLOCKING INPUTS — ANSWER BEFORE WRITING CODE

Codex must not begin implementation until Kyle answers these. Report them back as a checklist, do not guess.

1. **Is this a new repo or a branch of `C:\dev\mha`?** This project must NOT share a repo or publishing identity with *Lost & Underfound*. Confirm target path.
2. **VO or text-only?** This is a dialogue-heavy noir. Full VO is the single largest cost line in the project. If text-only, Rhubarb/viseme work is out of scope entirely.
3. **Confession Duel content budget.** Minimum viable pool is 60 unique confessions across 12 opponents (§6.4). Confirm Kyle is writing these or confirm they are generated-then-edited.
4. **Storefront target.** Steam vs itch.io changes the content ceiling (§2.3). Steam adult tagging has real revenue and regional-visibility consequences. Confirm before art direction locks.

---

## 1. LOGLINE

Three days ago, Corvin Vale drowned in the harbor of Isla Mordida. This morning the tide gave him back. He has nine days before the salt finishes the job, one suit that will never be dry again, and a fairly strong suspicion that the woman he still loves is the one who held him under.

---

## 2. TONE & CONTENT

### 2.1 The register
Monkey Island's *structure* — absurd puzzle logic, a charming failure of a protagonist, a formidable love interest who outclasses him, a supernatural rival, three escalating trials, a signature verbal-combat minigame — run through hard-boiled noir instead of swashbuckling comedy.

The jokes stay. The jokes are what make the darkness land. Corvin is funny the way people are funny at funerals: because the alternative is screaming.

**Voice rules for all dialogue:**
- Short lines. Trade fast. Nobody delivers a paragraph unless they're lying.
- Every line does two jobs: character + information, or character + joke. Lines that do one job get cut.
- Corvin never wins an exchange with the woman he loves. Not once. That's the running gag and the emotional thesis.
- No fantasy-novel diction. Nobody says "verily." Everyone says "the rent."

### 2.2 What "adult" means here
The sexuality is **appetite-driven, not decoration.** Corvin is a dead man. His body is cooling by the day, and the first thing the returned lose is touch — temperature, texture, pressure. So the wanting is the point. He is a man who can still remember what skin felt like and can no longer feel it, walking through a port city built on vice. Every sensual beat in this script is about *loss of sensation*, not titillation for its own sake.

That makes it good writing instead of filler. It also means the heat lands harder, because it's starved.

### 2.3 The content line — HARD RULE FOR CODEX
Write to **hard R, not X.**

| Allowed | Not allowed |
|---|---|
| Charged, explicit *dialogue*; frank adult banter; propositions | Written descriptions of sex acts |
| Nudity in silhouette, backlight, water distortion, or partial frame | Explicit rendered anatomy in sprites or CGs |
| Fade-to-black scene transitions; morning-after staging | On-screen depicted intercourse |
| Sex work depicted as labor with dignity and agency | Sexualized violence as spectacle |
| Drug use, addiction, murder, body horror, on-screen death | Anything involving a character under 18 — no ambiguity, no exceptions |

Rationale, not prudery: this register plays better in comedy-adventure than explicitness does (arousal and puzzle-solving compete for the same attention), it keeps the art budget sane, and it keeps the store page out of Steam's adult-only ghetto where discovery collapses. If Kyle overrides this, he overrides it explicitly — Codex does not drift the line on its own.

---

## 3. WORLD

**Isla Mordida** — "the bitten island." A free port, 1740s-adjacent, no flag, no law, three churches and forty bars. The town is built into and around the ribcage of a beached leviathan; the bones are load-bearing. Whale-oil lamps, absinthe, tobacco, debt.

**The Tide's Rule.** The bay does not keep its dead. Anything drowned in Mordida harbor washes back at the next high tide — walking, talking, remembering. Nobody knows why. Everyone has an opinion, and every opinion costs money.

**The Returned** get nine days. Over those nine days:
- Day 1–3: pass for living, if you stay out of good light
- Day 4–6: no heartbeat, no warmth, no taste; salt starts crusting at the joints
- Day 7–9: memories begin going out like lamps, oldest first
- Day 9: you calcify where you stand. The town uses the leftovers as bollards. There are a lot of bollards.

**The Church of the Drowned** monetized this. A returned man cannot lie — the salt in his throat won't let him — so the Church runs **Confession Halls** where the living pay to ask the dead questions. It's the island's intelligence economy. Secrets are currency. Everyone on this island is holding something they'd drown to keep.

**The one loophole (the game's spine):** a returned soul can be *released* — cut loose from the nine-day clock — but only by a person who owes them nothing and forgives them everything. Which on Isla Mordida is functionally nobody.

---

## 4. STRUCTURE

Classic three-trial spine. Four acts. **The nine days are a narrative clock, not a real-time timer** — no wall-clock pressure, no fail state from slow play. Days advance only on act beats. Codex must not implement a live countdown; it punishes exploration and breaks adventure-game pacing.

### PROLOGUE — "Wet"
Corvin wakes on the mudflats, day 3, missing his boots and his memory of the last week. Tutorial. He learns what he is from a bollard that used to be a man he knew. Establishes verb coin, inventory, and the fact that this game will be funny about horrible things.
**Ends when:** he reaches the Salt Market and someone recognizes him and screams.

### ACT I — "Three Rites"
To get an audience with Sabine Croix, who runs the port, Corvin must prove he's a *citizen in good standing* — and the dead don't have standing. Three Rites, in any order (MI's three-trials structure, fully non-linear):

1. **A Borrowed Heartbeat** — pass as living for one hour. Requires a stolen mechanism, a live accomplice, and a very cold night.
2. **A Name Restored** — Corvin's name was struck from the harbor roll the day he died. Getting it back means beating the Registrar in a Confession Duel.
3. **A Debt Forgiven** — someone must forgive Corvin one debt in writing. Everyone he's ever met refuses. The solution is a man who has forgotten who Corvin is.

**Ends when:** Corvin walks into Sabine's office, dripping.

### ACT II — "The Ferryman's Cut"
Corvin learns his drowning wasn't murder-for-hire — it was a *transaction*. Someone sold his death. He tracks the paper. The trail goes through the bathhouse, the opium float, and a ledger that shouldn't exist.
**Reveal at act break:** Sabine signed it. She signed it to save his life — the alternative on the table was worse, and she took the option she thought he'd forgive her for. He does not forgive her. Act ends with him walking out.

### ACT III — "Low Water"
Day 7. Memories going. Corvin starts losing puzzle knowledge — the game literalizes this: solved-puzzle notes vanish from his journal, inventory item descriptions degrade to "something metal, I think it mattered." Ossuary Kane makes his move on the port.
**Ends with:** the Confession Duel against Kane, in which the winning move is not a better secret. It's Corvin telling the truth about himself with no leverage attached. Kane can't survive a man with nothing left to protect.

### ENDINGS — three, all earned by Act I–III choices
- **SALT** — Corvin refuses release, calcifies, becomes a bollard outside Sabine's window. The last line is hers.
- **RELEASE** — Sabine forgives him everything and is owed nothing, because he spent Act III quietly settling every debt between them. He gets to die properly. Bittersweet, and the best one.
- **TIDE** — Corvin takes Kane's offer and becomes the next Ferryman. Cyclical, bleak, sets up a sequel. Locked behind cruelty choices.

---

## 5. CAST

### CORVIN VALE — protagonist
**Was:** a ship's notary. Sold signatures. The man you paid to make a thing legal that shouldn't have been.
**Is:** dead, damp, and funnier about it than anyone finds appropriate.
**Look:** mid-thirties, tall, wrong-shouldered — one hangs lower since the drowning. Wool coat permanently dark with water; it never dries and it drips on everything, which is a running visual gag and a puzzle mechanic (he can wet things). Grey at the temples that wasn't there last week. Salt crystals forming at the knuckles, worse each act — **his sprite degrades visibly across the game.** Barefoot for the whole prologue.
**Voice:** self-deprecating, quick, allergic to sincerity until it costs him. He deflects with a joke exactly once too often, and the game notices.
> *"I've been called a lot of things. 'Deceased' is new, and frankly it's the most accurate anyone's ever been about me."*

### SABINE CROIX — harbormaster, love interest, the person who signed for his death
**Look:** forties. Built like someone who did the hard version of the job before she got the office. Black hair pinned with a marlinspike — practical, not decorative, and she's used it. Men's coat, no shirt collar, ink on her fingers. A burn scar across the inside of one forearm she never explains and Corvin never asks about, because he already knows.
**Character:** competent to the point of cruelty. Runs Isla Mordida's harbor because she's the only person who can. Genuinely loves Corvin and genuinely sold him, and refuses to pretend those are contradictory. **She never apologizes.** Not once, not in any ending. She explains, and lets him decide.
**Function:** she wins every verbal exchange. This is a structural rule, not a preference.
> SABINE: *"You're dripping on the Persian."*
> CORVIN: *"It's brine. It's antiquing. You'll thank me."*
> SABINE: *"You always did know how to make an entrance."*
> CORVIN: *"I drowned, Sabine."*
> SABINE: *"Yes. It was very dramatic. I cried for almost a full minute."*

**Signature staging beat (Act I close):** she presses two fingers to the inside of his wrist to check for a pulse. There isn't one. She leaves her hand there anyway, considerably longer than the check requires. Neither of them says anything. That's the whole romance in one gesture — write the rest of it to that standard.

### OSSUARY KANE — the Ferryman (antagonist)
The island's oldest returned. Beat the nine days two centuries ago by taking the deal, and has been collecting the drowned ever since. Calcified from the ribs down — he walks on legs of grey coral and he *sounds* like it. Immaculately dressed above the waist. Rots downward.
Wants: Sabine's port, Sabine's ledger, and Sabine. Not in that order, and he'd say so.
**Not a monster — a recruiter.** Every scene, he offers Corvin something reasonable. The horror is how good the offers are.
> *"Nine days. You'll spend six of them being clever and three of them being frightened. I'm offering you the alternative, and you're going to insult me instead, because you think that's the same as having a choice."*

### JUNO ASH — proprietor, the Grey Float
Runs the bathhouse-and-opium-barge moored where the harbor's warmest. Late fifties, wide, gold rings on every finger including the thumbs, a voice like a door on a bad hinge. Ran the island's information trade for thirty years before the Church industrialized it and put her out of the business she invented. Bitter, hospitable, and the only person on Mordida who treats Corvin exactly the same dead as alive.
**The Float is the game's "adult" set-piece location** and is written per §2.3: steam, silhouette, staff with names and opinions and grievances about tips. Nobody there is a prop.
> *"Everybody comes here to feel something, sugar. You're just the first one honest about not being able to."*

### MIREILLE DAX — the mirror
A returned courtesan on day eight when Corvin meets her. Beautiful, unraveling, forgetting her own name mid-sentence and covering it with charm — a technique she is very, very good at. She's what Corvin has coming in six days.
Her side quest — helping her write down everything she is before it goes — is the game's optional emotional gut-punch and the tutorial for Act III's memory-loss mechanic.
> *"Don't look at me like that. I'm not tragic, I'm just *early*."*

### BROTHER TEODOR — Church of the Drowned
Young, sweating, in over his head. Sincere faith, catastrophic finances. Sells confession slots he doesn't have. Comic relief who becomes, in Act III, the only person who does the right thing for free. Kill him at the end of Act III. It should hurt.

### THE REGISTRAR — Act I duel opponent
Nameless by profession, an old woman who has struck four thousand names off the roll and remembers every one. Duel tutorial boss.

### SUPPORTING (portrait + 8–15 lines each)
Bollard-of-Tomas (a talking mooring post, Corvin's dead best friend, does the exposition and most of the puns) · The Cold Girl (child ghost — **non-sexualized, full stop, appears in no scene at the Float**) · Half-Coin Prosper (fence) · The Bone Chandler · Mad Adelie (Kane's calcified ex-wife, still furious).

---

## 6. SIGNATURE MECHANIC — THE CONFESSION DUEL

This is the game's insult-swordfight. It is the most important system in the build. Ship it first, prototype it in isolation.

### 6.1 Fiction
The returned cannot lie. The Church weaponized this into a formal contest: two parties trade secrets, and the crowd — or the salt — judges. **An attack is a true thing about you that your opponent dug up. A defense is a worse true thing that you volunteer yourself.** The Drowned respect only *willing* confession; a secret dragged out of you is worth nothing, a secret you hand over freely outranks it.

So winning means being more honest than your opponent can stomach. The mechanic *is* the theme.

### 6.2 Rules
- Opponent plays an attack line from their pool.
- Player selects a confession from inventory (the "Litany").
- Correct counter = confession whose **weight** exceeds the attack's **weight** and whose **sin category** matches or trumps it (§6.3).
- Wrong counter: player takes Salt. Three Salt = duel lost.
- **A confession, once spoken anywhere in the game, is permanently spent.** Global, not per-duel.
- Therefore the player must continuously *acquire new sins* — by eavesdropping, by digging up his own forgotten past, and in Act II by actually doing bad things. The collection loop is Monkey Island's insult-gathering with real moral cost.

### 6.3 Six sin categories, trump order
`GREED → LUST → PRIDE → CRUELTY → COWARDICE → BETRAYAL`
Each trumps the one before it. BETRAYAL trumps nothing — it is the highest weight and the rarest. Corvin holds exactly four BETRAYAL confessions in the whole game, and the final one is the Kane duel's win condition.

### 6.4 Content budget — HARD MINIMUMS
- ≥ 60 unique player confessions, evenly distributed: ≥ 8 per category, ≥ 4 at BETRAYAL
- 12 duel opponents
- ≥ 8 attack lines per opponent (96 total minimum)
- Every attack must have ≥ 2 valid counters in the pool at the point it can first be encountered

### 6.5 Sample exchange (Registrar, Act I)
> REGISTRAR: *"You signed a manifest you never read. Eleven people in that hold."*
> CORVIN: *"I read it."* — **(BETRAYAL, weight 8)** ✔
>
> REGISTRAR: *"...Say the rest."*
> CORVIN: *"I read it twice. I wanted to be sure of the number before I took the money."*

### 6.6 The Kane duel — special case
Kane's pool is unbeatable by weight; he has two centuries of sins and every one outranks Corvin's. **The win condition is a null play**: an empty Litany slot labeled *"Nothing. There's nothing left."* It is only unlockable if the player spent all four BETRAYAL confessions before this scene. Codex: this must be a hard prerequisite gate, not a soft hint.

---

## 7. PUZZLE DESIGN

### 7.1 Standing rules
- **Corvin's wetness is a verb.** He drips permanently. Wet the ledger, wet the fuse, wet the priest's collar so the ink runs. It's his one supernatural advantage and it's stupid, which is correct.
- **Corvin has no pulse.** Weight plates, doctors' examinations, and one very good lock all key off this.
- **Corvin cannot lie, ever, in dialogue.** So puzzles are solved by finding true things that are misleading. This is the best comedy engine in the design — use it constantly.
- No moon-logic. If a solution wouldn't survive Kyle explaining it out loud to a stranger, cut it.

### 7.2 Worked example — "A Debt Forgiven" (Act I)
Nobody will forgive Corvin a debt, because everyone hates him and his debts are the only leverage they have. Solution chain:
1. Learn from Bollard-of-Tomas that Half-Coin Prosper has late-stage salt-memory rot and re-meets everyone fresh each morning.
2. Prosper won't forgive a debt to a *stranger* — no reason to.
3. So Corvin must become someone Prosper owes. Steal Prosper's own lost pocket-watch from the Bone Chandler (who's holding it as collateral), return it.
4. Prosper, grateful, offers a favor. Corvin asks for the forgiveness. Prosper writes it — then asks who he's writing it for.
5. Corvin, unable to lie, has to say his own name. Prosper's face changes. He signs it anyway. *"...We'll pretend I didn't hear that."*
6. **Optional beat:** revisit Prosper next act. He remembers nothing. The kindness happened; it just doesn't persist. That's the game.

### 7.3 Act III memory decay — spec
On each Act III chapter tick, mark one *already-solved* journal entry and one inventory description as degraded. **Degrade text only — never remove a functional item or block a solved path.** A player must never be softlocked by the memory system. This is atmosphere and dread, not a difficulty mechanic.

---

## 8. ART DIRECTION

### 8.1 Style
Ink-and-wash noir. Heavy black, wet highlights, hard silhouette reads. Think woodcut sea charts that got rained on. High-contrast staging so the puzzle-relevant object is always the brightest thing in frame — Monkey Island's readability discipline, LeChuck's-Revenge-era, under a much darker palette.

### 8.2 Palette — locked
| Role | Hex |
|---|---|
| Bone / paper white | `#E4DCC8` |
| Wet black | `#0C1013` |
| Harbor slate | `#2A3A40` |
| Absinthe green (Church, opium, unnatural light) | `#7D9B4E` |
| Whale-oil amber (warmth, living people, safety) | `#C98A3C` |
| Arterial red — **used ≤ 5 times in the entire game** | `#8E1B22` |

Rule: **amber = alive, green = wrong.** The Float is the only location lit amber that isn't safe. That's deliberate.

### 8.3 Pipeline — reuse the validated path
Meshy 3D → Blender toon render → 2D sprite sheets. Same pipeline as *Lost & Underfound*, different shader stack: replace flat toon ramp with a two-tone ink ramp plus a screen-space hatching pass. Keeps the character work deterministic and repo-native instead of diffusion-per-frame.

- Backgrounds: 1920×1080 native, hand-painted over Blender greybox blockouts
- Characters: rendered at 2× target, 4-direction, 12 fps ink-on-twos
- **Corvin needs 3 sprite variants** (Act I clean / Act II salting / Act III crusted). Budget for this early; it's not a late polish task.
- Portraits for dialogue: 720×720, hard-inked, one per emotional state (5 states for mains, 2 for supporting)

### 8.4 Audio
Solo cello, prepared piano, harbor field recordings (rope strain, hull groan, gulls). No percussion anywhere except Kane's scenes, where it's a slow calcified knocking. Silence is a real instrument here — the Float is the only location with continuous music, which is why it feels like a trap.

---

## 9. TECHNICAL DELIVERABLES

**Build order — do not deviate:**
1. Confession Duel prototype, isolated scene, 1 opponent, 12 confessions, no art. Prove the loop is fun before anything else. **Stop here and report.**
2. Popochiu room scaffold + verb coin + inventory, prologue only, greybox art.
3. Ink integration + journal + spent-confession global state persistence.
4. Act I, three Rites, playable end to end, greybox.
5. Art pass on Act I only. **Stop and report.** Do not art-pass Acts II–III before Act I ships to playtest.

**Repo layout:**
```
/ink            all narrative, one .ink per act + confessions.ink
/duels          Confession Duel system (C#) + opponent JSON
/rooms          Popochiu rooms
/art/src        Blender scenes, .blend, source
/art/export     rendered sheets (git-lfs)
/tests          GUT
/docs           this file, puzzle dependency graph
```

**Single source of truth:** `confessions.json` holds every confession (id, text, category, weight, act_available, spent_flag). Ink references by id only. Never duplicate confession text into Ink files.

---

## 10. QA GATES — NUMERIC, HARD PASS/FAIL

| # | Gate | Threshold |
|---|---|---|
| G1 | Puzzle dependency graph is acyclic and fully solvable from a cold start | automated solver, 100% pass |
| G2 | Zero softlocks — every reachable state can reach an ending | exhaustive state walk, 0 dead ends |
| G3 | Confession pool size | ≥ 60 unique, ≥ 8 per category, ≥ 4 BETRAYAL |
| G4 | Duel coverage — every opponent attack has valid counters available at first encounter | ≥ 2 counters, 100% of attacks |
| G5 | Ink compiles clean | 0 errors, 0 warnings, 0 unreachable knots |
| G6 | Every hotspot has look + use + talk responses (fallbacks count) | 100%, no default "I can't do that" strings in shipped rooms |
| G7 | Act III memory decay never removes a functional item or blocks a path | automated: post-decay solvability check each tick, 100% pass |
| G8 | Kane duel null-play gate fires only with all 4 BETRAYAL confessions spent | unit test, both positive and negative case |
| G9 | Palette conformance — no shipped background uses a colour outside §8.2 ±5% | automated pixel audit, ≥ 98% of pixels in-gamut |
| G10 | Arterial red `#8E1B22` appears in ≤ 5 distinct scenes | automated scene scan, hard fail at 6 |
| G11 | Content compliance — no asset or line violates §2.3 right column | manual review checklist, signed off per act |
| G12 | Frame time, 1080p, mid-tier GPU | ≥ 60 fps sustained, 0 frames > 33ms during dialogue |

---

## 11. DO / DO-NOT FOR CODEX

**DO**
- Prototype the Confession Duel before writing a single room.
- Keep all narrative in Ink, all confession data in JSON, all logic in C#. No dialogue strings hardcoded in scenes.
- Timeout-wrap every Godot and Blender invocation. 120s ceiling, non-blocking.
- Report a mismatch rather than adjusting a threshold to make a gate pass.
- Stop at the two named checkpoints (§9 steps 1 and 5) and wait for review.

**DO NOT**
- Do not implement a real-time nine-day countdown. Narrative clock only.
- Do not let the Act III memory system remove functional items.
- Do not soften §2.3 in either direction without an explicit written override from Kyle.
- Do not write a scene where Corvin wins an argument with Sabine.
- Do not introduce a new engine, framework, or asset tool. Godot + Popochiu + Ink + Blender is the stack. Tool changes require evidence of a blocking failure in the current stack, not preference.
- Do not put the Cold Girl in any Grey Float scene, or in any scene with sexual content, ever.

**REPORT-BACK FORMAT (every checkpoint)**
```
CHECKPOINT: <name>
GATES: <G# pass/fail, actual value vs threshold>
BLOCKERS: <numbered, with what input is needed and from whom>
DEVIATIONS: <anything built differently from this brief, and why>
NEXT: <single next action, not a plan>
```

---

## 12. RISKS — FLAGGED HONESTLY

1. **This cannot ship under Good4Bagger or anywhere near *Lost & Underfound*.** One is a Humongous-style kids' adventure, one is an adult noir about a drowned man. Separate publishing identity, separate storefront presence, separate marketing. Decide the pseudonym now, not at launch, because the two will otherwise cross-contaminate in every algorithm that touches them.

2. **The Confession Duel is the whole game, and it might not be fun.** 60+ confessions is a large writing investment in a mechanic that hasn't been proven. That's why it's build step 1 in isolation. If the prototype isn't fun with 12 confessions, it will not become fun with 60 — kill or redesign it there, before the art budget commits.

3. **Word count is the real scope monster.** Dialogue-heavy noir + 96 duel attack lines + 60 confessions + full hotspot coverage is plausibly 40–60k words. For a solo dev that's the dominant cost, well above art. Scope Act I to ship standalone as a demo.

4. **Steam adult tagging is a one-way door.** It affects regional visibility, wishlist velocity, and some payment rails. §2.3's hard-R line is partly a craft decision and substantially a distribution one. Confirm before art locks, because silhouette-vs-explicit changes every character sheet.

5. **Three Corvin sprite variants across three acts triples the protagonist's animation cost.** It's the best visual idea in the design and it's also the thing most likely to get cut at month four. Either budget it now or design the decay as a shader/overlay pass on one base sprite.
