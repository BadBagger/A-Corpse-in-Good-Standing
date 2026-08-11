# A CORPSE IN GOOD STANDING
# FULL SCRIPT — BUILD DOCUMENT

Act I: complete and playable. Acts II–III: scene spec with key dialogue written.
Companion to `AGENTS_corpse_in_good_standing.md` and `LITANY_confession_library.md`.

---

## 0. SCOPE STATEMENT

A complete shooting script for a game this size is 40–60k words. This document delivers:

- **Act I:** every room, hotspot, item, puzzle chain, and line of dialogue. Buildable as-is.
- **Acts II–III:** every room, puzzle, item, and flag specified; major scenes written in full; incidental hotspot dialogue marked `[TO WRITE]` with a line count.

Act I is the standalone demo. Build it, ship it to playtest, and do not write Act II dialogue until Act I has been in front of strangers.

**Act I word count as written:** ~9,400. **Estimated remaining:** ~34,000.

---

## 1. FORMAT KEY

```
R##_name        Room
HS_name         Hotspot
IT_name         Inventory item
FL_name         Boolean flag
DL_name         Dialogue node (Ink knot)
cf_name         Confession (see LITANY doc)
```

Verb coin: **LOOK · USE · TALK**. Every hotspot needs all three (fallbacks count — gate G6).

---

## 2. ACT I ITEM MASTER

| ID | Item | Source | Used for |
|---|---|---|---|
| `IT_boots` | Dead man's boots | R03 market, grabbed during panic | Cosmetic; removes barefoot sprite |
| `IT_coroner_tag` | Coroner's tag, "VALE, C. — THURS" | R08 fish hall | Establishes day count; unlocks `cf_cow_didntfight` |
| `IT_knuckle_salt` | Scraped salt crystal | R02, USE hand on rope cleat | Trade to Bone Chandler |
| `IT_watch` | Prosper's pocket watch | R06 chandler, traded | Give to Prosper → Rite 3 |
| `IT_forgiveness` | Signed debt forgiveness | R07 almshouse | Rite 3 complete |
| `IT_ledger_page` | Torn registry page | R05 registry, requires distraction | Unlocks `cf_bt_manifest` |
| `IT_regulator` | Clockwork bilge regulator | R10 the Float, traded | Fake pulse → Rite 1 |
| `IT_chit` | Church confession chit | R09, from Teodor | Access to confession stall |
| `IT_rate_card` | Church price list | R09, earned by covering stall | Trade to Juno for regulator |
| `IT_flask` | Empty flask | R02 quay | Carries hot water; Act II red herring |
| `IT_name_writ` | Restored name on the roll | R05, duel victory | Rite 2 complete |

**Permanent verb — `WET`:** Corvin drips constantly. `USE CORVIN on [hotspot]` wets it. Three real solutions in Act I use this. Codex: implement as a global interaction, not per-room.

---

## 3. ACT I FLAGS

```
FL_knows_dead          set R02, after Tomas pulse beat
FL_knows_daycount      set R08, coroner tag read
FL_rite_name           Rite 2 complete
FL_rite_debt           Rite 3 complete
FL_rite_heartbeat      Rite 1 complete
FL_teodor_owes         set R09, stall covered
FL_juno_met            set R10
FL_manifest_known      set R05, ledger page read — gates cf_bt_manifest
FL_prosper_reset       daily, Prosper forgets Corvin
```

Act I exit requires all three `FL_rite_*`. Rites are **fully non-linear** — any order, any interleaving.

---

# ACT I

---

## R01 — THE MUDFLATS

*Grey dawn. Silt. A body face-down.*

**OPENING — plays on load, uninterruptible:**

**CORVIN (V.O.):** The tide comes in twice a day at Mordida. Once with the fish. Once with everybody else.

*He coughs. Sits up. Looks at his hands.*

**CORVIN:** Huh. *(stands)* That's a Tuesday.

*Pats coat. Pockets. Watch pocket.*

**CORVIN:** No boots. No purse. No — right. Well. Somebody had a lovely morning.

### Hotspots

**HS_silt**
- LOOK: "Mordida mud. Half of it's mud."
- USE: "I've been in it. I'm not going back in it."
- TALK: "We've said everything we're going to say to each other."

**HS_own_hands**
- LOOK: "Grey at the nails. That's new. Everything else looks like mine, which is somehow worse."
- USE: → tutorial for USE CORVIN. "There's nothing to do with them yet."
- TALK: "Not yet. Give it six days."

**HS_harbor_view**
- LOOK: "The ribs. Whole town's built through a dead thing's chest and nobody finds that remarkable but me."
- USE: "It's a view. You can't use a view."
- TALK: "I've talked at that harbor my whole life and it's never once answered."

**HS_coat**
- LOOK: "Wool. Was expensive. Is now a sponge with buttons."
- USE: → wrings it out. Puddle forms. Puddle persists. First `WET` demonstration.
- TALK: "It's a coat, and I'm not that far gone. Yet."

**Exit:** boardwalk north → R02.

---

## R02 — THE OLD QUAY

*Rotting boardwalk. Four mooring posts, grey, vaguely person-shaped. The fourth talks.*

### Hotspots

**HS_bollard_1 / 2 / 3**
- LOOK: "Grey. Person-shaped if you're not careful about it."
- USE: "I'd rather not."
- TALK: "…Nothing. They're past it."
- *(TALK on all three in sequence sets an optional flag; Tomas comments on it later.)*

**HS_tomas** → `DL_tomas_main`

**HS_rope_cleat**
- LOOK: "Iron cleat. Salt-eaten. Sharp edge on it."
- USE with hands → **acquires `IT_knuckle_salt`.** *(See scene below.)*
- TALK: "It's a cleat."

**HS_flask**
- LOOK: "Somebody's flask. Empty, obviously. This is a working quay."
- USE: → takes `IT_flask`.

---

### DL_tomas_main — SCENE

**BOLLARD:** Corvin?

*Corvin keeps walking. Stops. Comes back.*

**BOLLARD:** Corvin Vale.

**CORVIN:** …Tomas?

**BOLLARD:** Oh, thank Christ. I've been trying to get someone's attention for two years and everyone just ties a rope to me.

**CORVIN:** Tomas, you're a bollard.

**BOLLARD:** I'm aware.

**CORVIN:** You're a *bollard*, Tomas.

**BOLLARD:** Yes, and you're standing in mud with no shoes on, so let's both take a moment before we start ranking each other.

*Corvin crouches to eye level. There are eyes. Sort of.*

**CORVIN:** How long?

**BOLLARD:** Two years, give or take. Ran out of days and the salt got the rest. It's not so bad. You'd be amazed what people say in front of a mooring post.

**CORVIN:** Ran out of days.

**BOLLARD:** *(carefully)* Corvin. When did you get out of the water?

**CORVIN:** I didn't get *in* the water.

**BOLLARD:** That's not what I asked.

**CORVIN:** *(beat)* This morning.

**BOLLARD:** Right. — Put your hand on your chest.

**CORVIN:** Tomas—

**BOLLARD:** Put your hand on your chest, Corvin.

*He does. Waits. Moves it slightly. Waits. Takes it away and looks at it like it's the hand's fault.*

**CORVIN:** That's — no, that's a technique thing, you have to—

**BOLLARD:** Corvin.

**CORVIN:** I've never been good at finding it, even when—

**BOLLARD:** *Corvin.*

*Water slapping pilings.*

**CORVIN:** How long do I get?

**BOLLARD:** Nine days from when you went under. How many have you lost?

**CORVIN:** I don't know.

**BOLLARD:** Then find out. That's the first thing. Everything else is second.

**→ SET `FL_knows_dead`. Unlocks the whole map.**

---

### DL_tomas_topics — persistent, revisitable

**[What's the end like?]**
> **BOLLARD:** You want the honest answer or the one that helps?
> **CORVIN:** Honest.
> **BOLLARD:** The memory goes first. Oldest to newest, like lamps going out down a street. You lose your mother, then your childhood, then the last twenty years, and the last thing left is whatever happened five minutes ago, and then you're standing very still and someone's tying a rope to you.
> **CORVIN:** …And the one that helps?
> **BOLLARD:** It's quick at the end.
> **CORVIN:** Is that true?
> **BOLLARD:** No.

**[Who put me in?]**
> **BOLLARD:** Nobody drowns in Mordida harbor by accident. It's four feet deep at the quay and you could swim before you could read.
> **CORVIN:** I know.
> **BOLLARD:** Then go find out who, while you've still got the equipment to be angry with.

**[How do I get back on the roll?]** *(hint for Rite 2)*
> **BOLLARD:** The Registry. Old woman runs it, no name, just the job. She won't do it as a favour — she's never done anything as a favour in her life. You'll have to duel her for it.
> **CORVIN:** With what?
> **BOLLARD:** With what you've done. Same as everyone.

**[I need someone to forgive me a debt.]** *(hint for Rite 3)*
> **BOLLARD:** Nobody on this island will forgive you anything. You're a notary. — Unless. Half-Coin Prosper's in the almshouse with the rot. He meets everyone fresh every morning.
> **CORVIN:** He'd still have to have a reason.
> **BOLLARD:** So give him one before noon.

**[I need to pass for living.]** *(hint for Rite 1)*
> **BOLLARD:** Warmth and a pulse. That's all anyone checks, because that's all there is. Warmth you can borrow. A pulse you'll have to build.

**[Tell me something about myself.]** → **grants `cf_pride_list`, `cf_cow_leftroom`, `cf_greed_widows`**
> **BOLLARD:** You keep a list of everyone who's ever been wrong about you.
> **CORVIN:** That's private.
> **BOLLARD:** It's alphabetical, Corvin. You showed it to me. Twice.

**[Nothing. Just checking you're still here.]**
> **BOLLARD:** Where would I go.

**[Optional, if all three other bollards TALKed]**
> **BOLLARD:** You've been talking to the others.
> **CORVIN:** They're not talkers.
> **BOLLARD:** They were. Petra on the end used to sing. — Don't do that again.

---

### SCENE — Acquiring `IT_knuckle_salt`

*USE hands on HS_rope_cleat.*

**CORVIN:** There's a crust forming at the knuckles. Has been since I got up.

*He drags his hand across the cleat edge. It makes a sound like sugar.*

**CORVIN:** No pain. That's the part I'd like on record — no pain at all.

*A crystal comes loose. He holds it up. It catches the light.*

**CORVIN:** Somebody will want this. Somebody on this island wants everything.

**→ `IT_knuckle_salt`. Grants `cf_lust_hands`.**

*(Repeatable twice more; third attempt:)*

**CORVIN:** No. There's a limit and I've found it, and I'd rather find it here than somewhere it matters.

---

## R03 — SALT MARKET

*Crowded. Whale-oil lamps. Fishmongers, a boot stall, the Church confession stall with a queue.*

**Entry sequence** — plays once, on first arrival after `FL_knows_dead`:

**BOOT SELLER:** Morning. Size?
**CORVIN:** Eleven. And credit.
**BOOT SELLER:** Credit's for people I know.
**CORVIN:** You know me. Vale. I did your brother's transfer papers.
*(The seller looks up. Looks properly. His face does something complicated.)*
**BOOT SELLER:** …Vale.
**CORVIN:** There we are.
**BOOT SELLER:** Vale's dead.
**CORVIN:** Well. That's the sort of thing people say.
**BOOT SELLER:** No — *no* — they pulled you out Thursday. I *saw* it. They laid you on the ice at the fish hall, everyone came through, I *stood in the line*—
**CORVIN:** Right, and I appreciate—
**BOOT SELLER:** — I brought my *daughter*—
**CORVIN:** That seems like a choice.

*He backs into his own table. Boots everywhere. A woman in the confession queue turns, sees Corvin, and screams. The street stops.*

**CORVIN:** *(to nobody)* Thursday.

*Arithmetic on his fingers. Doesn't take long.*

**CORVIN:** Six days.

*He picks up boots off the ground, unhurried, and walks out through a crowd that parts without anyone deciding to.*

**→ `IT_boots`. Barefoot sprite retires. Market becomes navigable.**

### Hotspots

**HS_boot_stall** *(seller now refuses to look at him)*
- LOOK: "He's rearranging boots that don't need it. He'll be at that all day."
- USE: "I've taken enough from him."
- TALK: **SELLER:** "I've got nothing for you." / **CORVIN:** "I know." / **SELLER:** "…She's alright, by the way. The girl. She thought it was interesting." / **CORVIN:** "Kids are better at this than we are."

**HS_fishmonger** → grants `cf_greed_scales`, `cf_cow_drink` via eavesdrop
- LOOK: "Two sets of scales under that table. The honest ones are on the wall where you can see them."
- USE: "I'm not buying fish. I can't taste anything and it seems like a waste."
- TALK: **MONGER:** "You're dripping on the cod." / **CORVIN:** "It's a marinade."

**HS_confession_queue**
- LOOK: "Eleven people waiting to ask a dead man a question. Eight of them are here about money."
- USE: → "I'm on the wrong side of that counter."
- TALK: → grants `cf_cruel_funeral`, `cf_pride_voice` via overheard queue chatter

**HS_church_sign**
- LOOK: "**THE DROWNED CANNOT LIE — ONE SHILLING.** They got a signwriter in. It's good work."
- USE: → `WET` the sign, ink runs. **CORVIN:** "Petty. Necessary. Both."
- TALK: "I've argued with better-informed signs."

**HS_lamp**
- LOOK: "Whale oil. Warm light. Everything warm on this island is something dead being useful."
- USE: → holds hands near it. **CORVIN:** "Nothing. Not cold, not warm. Just — reported."

**Exits:** R05 registry · R06 chandler · R08 fish hall · R09 church · R07 almshouse · quay south → R02

---

## R05 — THE HARBOR REGISTRY

*Dark. Floor-to-ceiling ledgers. THE REGISTRAR, seventy, at a desk.*

### PUZZLE — Rite 2, A Name Restored

**Chain:**
1. TALK Registrar → she refuses. Corvin has no standing; the dead aren't citizens.
2. She offers the only route: a Confession Duel, publicly, per Church rule.
3. **Duel requires ≥6 unspent confessions.** If fewer, she declines and says so plainly.
4. `IT_ledger_page` is optional but strongly incentivized — reading it unlocks `cf_bt_manifest`, the only BETRAYAL available in Act I.
5. Win the duel → `IT_name_writ`, `FL_rite_name`.

**Sub-puzzle — obtaining `IT_ledger_page`:**
- The Kestrel ledger is on the high shelf, behind the desk. She never leaves it.
- `WET` the desk lamp → it guts and smokes → she rises to tend it → shelf is clear for one interaction.
- Take page. **She knows.** She says nothing until the duel, where she uses it against him. This is deliberate: the player thinks they got away with it.

### Hotspots

**HS_ledgers**
- LOOK: "Four thousand names in those books and every one of them struck out by the same hand."
- USE: "They're not mine to open. That's stopped me before. It's not stopping me today."
- TALK: "I've talked to books. It's been a long week."

**HS_roll_book** *(the open roll, his name struck)*
- LOOK: "There. **VALE, CORVIN** — and a line through it. Not even a neat line. She was in a hurry, or she wasn't paying attention, and I don't know which is worse." → grants `cf_pride_handwriting`
- USE: "Not with her sitting there."

**HS_lamp** → the `WET` solution
- LOOK: "Oil lamp. Low wick. She likes the dark; it makes people talk faster."
- USE: → *Corvin shakes his sleeve over it. It gutters, smokes, and the Registrar gets up.* **CORVIN:** "Terribly sorry. I'm damp."

**HS_registrar** → `DL_registrar`

---

### DL_registrar — SCENE

**REGISTRAR:** You're the Vale boy.

**CORVIN:** I'm thirty-six.

**REGISTRAR:** You're three days old. — Struck you out myself on Friday. Nice clean hand.

**CORVIN:** It wasn't, actually.

**REGISTRAR:** *(the first flicker of interest)* No. It wasn't. — What do you want?

**CORVIN:** My name back.

**REGISTRAR:** Can't. You're not a person. The roll's for people, and a person has a pulse, and you have a coat and an attitude.

**CORVIN:** Then I'll take the other route.

**REGISTRAR:** *(long look)* You want to duel me. For your name.

**CORVIN:** Church rule. You can't refuse a returned man a duel.

**REGISTRAR:** No, I can't. *(stands, gathering her skirts)* I've been doing this forty years, Mr. Vale. Do you know what that means?

**CORVIN:** That you're very good at it.

**REGISTRAR:** That I'm *bored* of it. — Come on, then. The hall's cold and you won't notice, which is the only advantage you've got.

**→ Launches Confession Duel: opponent `op_registrar`, 8 attack lines, tutorial UI overlay on first two rounds.**

**On victory:**
> **REGISTRAR:** *(writing)* There. **Vale, Corvin.** Back in.
> **CORVIN:** No lecture?
> **REGISTRAR:** You said the Kestrel out loud, in a hall, in front of forty people and a man selling pastries. There's nothing I could add.
> *(She blots the ink.)*
> **REGISTRAR:** That was a stupid thing to do and it was the only clever thing anyone's done in this room in a decade. Get out.

**On loss:**
> **REGISTRAR:** No.
> **CORVIN:** Best of—
> **REGISTRAR:** No. — And Mr. Vale? What you told me in there, I'll be selling by supper. That's the job. You knew it was the job when you walked in.
>
> **→ SET `FL_registrar_sold_manifest`. Consequences fire in Act II R12 and Act III Kane scene.**

---

## R06 — THE BONE CHANDLER

*A shop of things carved from calcified returned. Buttons, needles, chess sets. The CHANDLER, cheerful.*

### PUZZLE — obtaining `IT_watch` (Rite 3, step 1)

Prosper's pocket watch is behind the counter as collateral. Chandler won't sell it for money. He wants **fresh salt from a returned man who's still walking** — nobody will give him that, for obvious reasons.

`IT_knuckle_salt` → `IT_watch`.

### Hotspots

**HS_wares**
- LOOK: "Buttons. Needles. A chess set. All of it was somebody."
- USE: "I'd rather not handle the neighbours."
- TALK: "…No. Not today."

**HS_chess_set**
- LOOK: "White pieces are older stock — they go pale after twenty years. The black ones are recent." → grants `cf_cruel_receipts`

**HS_counter_watch**
- LOOK: "A pocket watch under glass. Half-Coin's, or it was. Chain's worn through on the left, which means he was right-handed and anxious."
- USE *(before trade)*: "It's under glass and he's watching me. Both of those are problems."

**HS_chandler** → `DL_chandler`

---

### DL_chandler — SCENE

**CHANDLER:** *(delighted)* Oh, you're *new*.

**CORVIN:** I'm not for sale.

**CHANDLER:** Everyone says that, and then day nine comes and someone ties a rope to them, and the rope wears a groove, and the groove is where I start. — What can I do for you?

**CORVIN:** The watch. Under the glass.

**CHANDLER:** Prosper's. Not for sale, I'm afraid. It's collateral. Man owes me eleven shillings and the rot's taken his memory of owing it, so I keep the watch and we're both content.

**CORVIN:** I'll trade.

**CHANDLER:** With *what?* You've got a wet coat and somebody else's boots.

*(Corvin sets the salt crystal on the counter. The Chandler goes very still.)*

**CHANDLER:** …That's fresh.

**CORVIN:** Off the knuckle. This morning.

**CHANDLER:** Off a *walking* man. — Do you know what that is? Nobody brings me that. They bring me their uncle after he's set, they bring me buttons, they bring me — nobody brings me this because to bring me this you have to take it off yourself and everyone finds that upsetting.

**CORVIN:** I didn't feel it.

**CHANDLER:** *(quietly, real)* No. That's rather the point, isn't it.

*He takes the crystal. Puts the watch on the counter. Doesn't look at Corvin.*

**CHANDLER:** Come back when there's more. — I'd rather you didn't. But come back.

**→ `IT_watch`. Grants `cf_cruel_names`.**

---

## R07 — THE ALMSHOUSE

*A long room of cots. HALF-COIN PROSPER by the window, late-stage salt rot, cheerful and blank.*

### PUZZLE — Rite 3, A Debt Forgiven

Prosper re-meets everyone fresh each morning. He won't forgive a stranger's debt — no reason to. So Corvin must become someone Prosper owes.

`IT_watch` → gratitude → favour → forgiveness → **and Corvin cannot lie about whose debt it is.**

### Hotspots

**HS_cots**
- LOOK: "Twelve cots. Nine occupied. Three of them are past talking and nobody's moved them yet."
- USE: "Leave them be."

**HS_window**
- LOOK: "Faces the water, which strikes me as cruel until you realise nobody in here remembers what it means." → grants `cf_cow_father`

**HS_prosper** → `DL_prosper`

---

### DL_prosper — SCENE

*(First visit, before watch:)*

**PROSPER:** Morning! Have we met?

**CORVIN:** Several times.

**PROSPER:** *(pleased)* Marvellous. How did it go?

**CORVIN:** Badly, mostly. I owed you money.

**PROSPER:** Did you pay it?

**CORVIN:** No.

**PROSPER:** *(entirely unbothered)* Well, there we are. Sit down, you look terrible.

*(With `IT_watch`:)*

**CORVIN:** I've got something of yours.

*(He sets the watch in Prosper's hand. Prosper's whole face changes — not recognition. Something under it.)*

**PROSPER:** …Oh.

**CORVIN:** You know it?

**PROSPER:** No. *(turning it over)* No, I don't know it at all. But my hand does. Look — *(thumbs the catch, one-handed, perfectly)* — I've done that ten thousand times and I couldn't tell you once.

**CORVIN:** It was at the Chandler's. Collateral.

**PROSPER:** And you got it back for me.

**CORVIN:** Yes.

**PROSPER:** Why?

**CORVIN:** *(beat — he can't lie)* Because I need a favour and this was the shortest route to it.

**PROSPER:** *(laughs, genuine)* Oh, that's *lovely*. Nobody's been honest with me in months — they all think I won't notice, and they're right, but I *notice that*. — Go on. What's the favour?

**CORVIN:** I need a debt forgiven. In writing. Signed.

**PROSPER:** Is that all? Whose?

*(Long beat. Corvin's mouth opens. Nothing comes out but the truth.)*

**CORVIN:** Mine. Eleven shillings, sixteen years, and I've been avoiding you in the street since before you got sick.

*(Silence. Prosper looks at him for a long moment — and something almost surfaces. Almost.)*

**PROSPER:** …Corvin.

**CORVIN:** Yes.

**PROSPER:** *(the flicker goes out)* I'm sorry — who?

*(He takes the paper. Writes. Signs it. Hands it over.)*

**PROSPER:** There. Whoever you are, you don't owe me anything.
**PROSPER:** We'll pretend I didn't hear the rest.

**→ `IT_forgiveness`, `FL_rite_debt`. Grants `cf_bt_tomas`… no — grants `cf_greed_ring`.**

**Optional revisit, next act:** Prosper remembers nothing. The watch is on the sill. He offers Corvin tea and asks if they've met.

---

## R08 — THE FISH HALL

*Cold room. Ice tables. This is where his body was laid out for viewing.*

### Hotspots

**HS_ice_table**
- LOOK: "That's the table. There's still a shape in the ice where I was, and it's smaller than I'd have guessed."
- USE: → he lies down in it. **CORVIN:** "…Fits. Well. That answers a question I didn't ask." → grants `cf_pride_eulogy`

**HS_tag_box**
- LOOK: "Coroner's tags in a tin. Alphabetical, which I appreciate more than I'd like to."
- USE: → **`IT_coroner_tag`.** *"VALE, C. — THURS. RECOVERED, QUAY. NO MARKS."*
  > **CORVIN:** "No marks. — I want that on record too. Nobody hit me. Nobody had to."
  > **→ SET `FL_knows_daycount`. Grants `cf_cow_didntfight`.**

**HS_visitor_book**
- LOOK: "They kept a book. Forty-one names came through to look at me." → grants `cf_pride_twice`
- USE: → he reads it. **CORVIN:** "Sabine's not in it." *(beat)* "She wouldn't sign a thing like that. She'd just come."

**HS_drain**
- LOOK: "It all goes back to the harbour eventually. Efficient island."
- USE: `WET` → "It's a drain. I'd be adding to it."

---

## R09 — THE CHURCH OF THE DROWNED

*Confession stall out front, hall behind. BROTHER TEODOR, young, sweating, drowning on land.*

### PUZZLE — obtaining `IT_rate_card` (Rite 1, step 1)

Teodor has oversold confession slots he can't fill — he sold eleven and has one returned man on the books, who has since set. He needs a returned man in the booth **today** or he's finished.

Corvin sits the stall for an hour → `FL_teodor_owes` + `IT_rate_card`.

**Inside the booth, three petitioners.** Each asks one question. Corvin cannot lie. Player picks a *framing*, not a falsehood — the comedy engine of the whole game.

### Hotspots

**HS_stall**
- LOOK: "**THE DROWNED CANNOT LIE — ONE SHILLING.** Queue's eleven deep. He's in trouble."
**HS_poor_box**
- LOOK: "Poor box. Someone's had the lock off and put it back badly." → grants `cf_greed_plate`
**HS_teodor** → `DL_teodor`

---

### DL_teodor — SCENE

**TEODOR:** We're closed. We're — I'm sorry, we're closed.

**CORVIN:** Your queue disagrees.

**TEODOR:** My queue is a *misunderstanding*.

**CORVIN:** You sold slots you can't fill.

**TEODOR:** *(too fast)* That is a very serious accusation and I would like to know who—

**CORVIN:** Nobody. You've got eleven people out there and one returned on your books, and I passed him on the quay this morning and he's a bollard now.

*(Teodor sits down on the step. Puts his head in his hands.)*

**TEODOR:** He was fine on Tuesday.

**CORVIN:** They're always fine on Tuesday.

**TEODOR:** They'll take the stall off me. It's not even the money, it's — my father got me this posting, he wrote *letters*—

**CORVIN:** Brother. Look at me.

**TEODOR:** *(does)* …Oh.

**CORVIN:** Oh.

**TEODOR:** *(standing so fast he nearly falls)* You'd — you would *sit*? For me?

**CORVIN:** For an hour. And in exchange you give me the rate card. What the Church charges, by question type, with the margins.

**TEODOR:** That's — I could be *defrocked* for—

**CORVIN:** Teodor.

**TEODOR:** *(already fetching it)* Yes. Right. Yes.

**→ Launches booth sequence.**

---

### DL_booth — THREE PETITIONERS

**PETITIONER 1 — a woman, forties, holding a hat.**
> **WOMAN:** Did my husband love me?
> *(Corvin cannot lie. Three options — all true:)*
> - **[He never told me.]** — true, useless, kind. She leaves calm.
> - **[I don't know. I never met him.]** — true, blunt. She leaves angry. **+`cf_cruel_sentences`**
> - **[Men who love their wives don't come to me to write things down.]** — true, cruel, and correct. She leaves destroyed. **+`cf_cruel_diagnosis` flagged for Act III**

**PETITIONER 2 — a boy of nineteen.**
> **BOY:** Is it true you can't lie?
> **CORVIN:** Yes.
> **BOY:** Say something you'd never say.
> **CORVIN:** *(player picks any unspent confession from the Litany — it is SPENT permanently, for nothing)*
> **BOY:** *(after)* …Why did you tell me that?
> **CORVIN:** Because you asked and I'm made this way now.
> **BOY:** That's horrible.
> **CORVIN:** Shilling, please.

> **Design note:** this is the tutorial for permanent spend. The player will hate it. Good — they'll never treat a confession casually again.

**PETITIONER 3 — Kane. He does not pay.**
> **KANE:** Comfortable in there?
> **CORVIN:** It's a box.
> **KANE:** It's a *booth*, Mr. Vale, and the difference is that a booth has a queue. — I'll have my question now.
> **CORVIN:** You haven't paid.
> **KANE:** No. — How many days have you got left?
> **CORVIN:** *(cannot lie)* Six.
> **KANE:** *(rising)* Thank you. That's all I came for. I like to know when a man's going to be reasonable, and it's never on day six.
> *(He goes. The queue lets him through without being asked.)*

**→ `IT_rate_card`, `FL_teodor_owes`. First Kane appearance.**

---

## R10 — THE GREY FLOAT

*Juno Ash's bathhouse barge, moored where the harbour runs warm off the tannery outflow. Steam. Lamplight. Amber — the only unsafe place lit warm.*

**Staging note (per §2.3):** silhouette, steam, backlight. The staff have names, opinions, and grievances about tips. Nobody here is scenery.

### PUZZLE — Rite 1, A Borrowed Heartbeat

The roll-clerk's living-status check tests two things: **warmth** and **pulse**.

- **Pulse:** `IT_regulator`, the clockwork bilge governor off the Float's pump. Juno trades it for `IT_rate_card` — she ran the island's information trade for thirty years before the Church industrialised it and wants to know exactly what they're charging.
- **Warmth:** one hour in the Float's hot pool raises his body temperature for roughly sixty minutes. Free, once Juno likes him.
- **Timing:** the interview must be attempted **immediately** after the soak. Wander three rooms and it fails, with a Juno line acknowledging it.

### Hotspots

**HS_pool**
- LOOK: "Hot. I can see it's hot. Steam coming off it like a kettle and I've got no opinion about it whatsoever."
- USE *(before Juno's permission)*: "Not without asking. She'd know."
- USE *(after)*: → soak sequence, starts the 60-minute warmth window.

**HS_pump**
- LOOK: "Bilge pump. Clockwork governor on it — nice piece, better than the barge deserves."
- USE: "That's hers, and she's the only person on this island who's been straight with me."

**HS_staff_corner**
- LOOK: "Three of them off shift, arguing about a tip. One's winning."
- TALK: → grants `cf_lust_float`, `cf_cow_apologize`

**HS_juno** → `DL_juno`

---

### DL_juno — SCENE

**JUNO:** *(without turning)* You're dripping on my deck, and my deck is already wet, so I want you to understand that I noticed anyway.

**CORVIN:** Juno.

**JUNO:** Corvin Vale. *(turns)* Well. You look exactly the same, which is the rudest thing you've ever done to me.

**CORVIN:** People keep screaming.

**JUNO:** People are *tourists*. — Sit. Don't sit there, that's Adela's. Sit there.

*(He sits.)*

**JUNO:** Everybody comes here to feel something, sugar. You're just the first one honest about not being able to.

**CORVIN:** I need your pump governor.

**JUNO:** *(flat)* No.

**CORVIN:** Juno—

**JUNO:** That pump is the only reason this barge is a barge and not a wreck with opinions. — What in God's name do you want a governor for?

**CORVIN:** I need something in my chest that ticks for an hour.

*(Beat. She laughs — one hard bark.)*

**JUNO:** …Oh, that's *good*. That's the best thing I've heard this month. — What's it worth?

**CORVIN:** *(sets down the rate card)* What the Church charges. By question type. With the margins.

*(She doesn't touch it. Looks at it a long time.)*

**JUNO:** Thirty years I ran that trade. Thirty. And they came in with a *building* and a *tariff*, and now there's a queue in the market and a boy in a collar taking a shilling a question.

**CORVIN:** Sixteen percent on grief. It's in there.

**JUNO:** *(taking it)* Sixteen. — Governor's on the pump. Take it, mind the spring, and Corvin—

**CORVIN:** Mm.

**JUNO:** The pool's free. You'll want an hour in it before you go anywhere they check.

**CORVIN:** How did you—

**JUNO:** Sugar, I've been putting warmth into cold men for forty years. It's the whole business.

**→ `IT_regulator`, `FL_juno_met`. Grants `cf_lust_float` if not already held.**

---

## R11 — THE HARBORMASTER'S OFFICE — RITE 1 CHECK

*Anteroom. A CLERK with a checklist. Beyond him, Sabine's door.*

**Requires:** `IT_regulator` equipped + soak active (<60 min) → otherwise auto-fail with a specific, non-punishing message.

> **CLERK:** Name.
> **CORVIN:** Vale.
> **CLERK:** *(checks roll — requires `FL_rite_name`)* …You're on. Right hand.
> *(Takes his wrist. Waits. The regulator ticks under the coat, four inches off and slightly too regular.)*
> **CLERK:** *(frowning)* That's fast.
> **CORVIN:** I'm nervous. She has that effect.
> **CLERK:** *(feels his hand — warm from the pool)* …Fine. Go through.

**→ `FL_rite_heartbeat`. All three Rites complete → Sabine's office.**

**Fail state (no soak):**
> **CLERK:** You're *cold*.
> **CORVIN:** It's a cold morning.
> **CLERK:** It's *August*. — Out.
> *(No penalty. Repeatable. Juno comments if you return: "You wandered off, didn't you. You had one job and it was to walk in a straight line.")*

---

## R12 — SABINE'S OFFICE — ACT I FINALE

*(Full scene as scripted in `script_prologue_act1.md`, Scene 5 — reproduced here for build completeness.)*

**SABINE:** You're dripping on the Persian.
**CORVIN:** It's brine. It's antiquing. You'll thank me in a decade.
**SABINE:** You always did know how to make an entrance.
**CORVIN:** I drowned, Sabine.
**SABINE:** Yes. It was very dramatic. I cried for almost a full minute.
**CORVIN:** A minute.
**SABINE:** It was a busy week.

*She writes another line. Sets down the pen. Looks at him for the first time.*

**SABINE:** You're on the roll again. I saw.
**CORVIN:** I had to out-confess a seventy-year-old woman in front of a paying audience.
**SABINE:** How was it?
**CORVIN:** Humiliating and extremely well attended.
**SABINE:** What did you give her?
**CORVIN:** *(beat)* The Kestrel.

*That lands. She sits back.*

**SABINE:** Out loud.
**CORVIN:** Out loud, in a hall, to about forty people and a man selling pastries.
**SABINE:** Corvin—
**CORVIN:** It's fine. It's actually — it's the only clever thing I've done since Tuesday. Nobody can hold it over me now. You can't blackmail a man with a thing he shouted.
**SABINE:** That's not why you did it.
**CORVIN:** No.
**SABINE:** Why did you do it?
**CORVIN:** Because I wanted one person on this island to know the worst of it and still be standing there afterwards. *(beat)* She was. She wrote my name back in. Didn't say anything about it.

*Silence. She gets up. Crosses to him. Water pooling on her floor and she walks straight through it.*

**SABINE:** Hold still.
**CORVIN:** What—
**SABINE:** Hold *still*.

*She takes his wrist. Two fingers to the inside of it. Four seconds. Nothing. She doesn't take her hand away.*

**CORVIN:** *(quietly)* That's not how you check.
**SABINE:** I know how to check.

*Two more seconds. She lets go. Returns to the desk. Picks up the pen.*

**SABINE:** Get out of my office, Corvin.
**CORVIN:** Right.

*At the door—*

**SABINE:** Six days.
**CORVIN:** Five.

**END OF ACT I.**

---
---

# ACT II — "THE FERRYMAN'S CUT"

**Premise:** Corvin's drowning wasn't murder-for-hire. It was a *transaction*, with paperwork. He follows the paper.

**Structure:** four new rooms, three returning. One long puzzle chain rather than parallel rites — Act II is a single tightening thread.

## Rooms

| ID | Room | Function |
|---|---|---|
| `R13_kane_parlour` | Kane's parlour | The offer. Written below. |
| `R14_float_lower` | Below decks, the Float | Mireille. Written below. |
| `R15_customs` | Customs house | The ledger that shouldn't exist |
| `R16_kestrel_wreck` | The Kestrel, low tide | `cf_bt_tomas` excavation |

## Item spec

| ID | Item | Source | Used for |
|---|---|---|---|
| `IT_cut_paper` | The transaction record | R15, requires `IT_regulator` returned | Reveals Sabine's signature |
| `IT_mireille_book` | Mireille's memory book | R14 | Optional; Act III memory tutorial |
| `IT_kane_seal` | Kane's wax seal | R13, stolen | Forges access to R15 |
| `IT_tide_table` | Tide table | R15 | Times the Kestrel window |
| `IT_tomas_papers` | The Kestrel crew list | R16 | Unlocks `cf_bt_tomas` |

## Puzzle chain

1. Kane's parlour — the offer. Refuse it. Palm `IT_kane_seal` during the handshake he insists on.
2. Seal forges a customs writ → R15.
3. Customs ledger names a broker, not a killer. `IT_cut_paper` — **and the counter-signature is Sabine's.**
4. `IT_tide_table` opens the Kestrel wreck for one window.
5. The wreck holds the crew list. Corvin gave them Tomas's name. → `cf_bt_tomas`
6. Return to Sabine. **Act break.**

## DL_kane_offer — WRITTEN

**KANE:** Sit down, Mr. Vale. You've got six days and you're spending them standing up in other men's rooms.
**CORVIN:** I'll stand.
**KANE:** Of course you will. *(pause)* Nine days. You'll spend six of them being clever and three of them being frightened. I'm offering you the alternative, and you're going to insult me instead, because you think that's the same thing as having a choice.
**CORVIN:** It's adjacent.
**KANE:** It's cheaper. *(warmly)* I read your manifest, by the way. The Kestrel. Eleven in the hold.
**CORVIN:** *(nothing)*
**KANE:** I'm not threatening you with it. Everyone threatens you with it — that's why it stopped working. I'm telling you I read it and I'd like you to work for me anyway. *(beat)* You've spent your whole life waiting for someone to know the worst thing and stay in the room. Here I am. Sitting down.

*(If `FL_registrar_sold_manifest`:)*
**KANE:** Though I paid rather less for it than I expected. Your Registrar sells cheap. She was fond of you, I think — that's usually what makes them cheap.

*(He extends a hand. Corvin has to take it to leave. `IT_kane_seal` palmed on contact.)*
**KANE:** Six days, Mr. Vale. I'll ask again on four, and you'll be politer.

## DL_mireille — WRITTEN

*Below decks. MIREILLE DAX, day eight, beautiful, unravelling, covering it with charm she is very good at.*

**MIREILLE:** Don't look at me like that.
**CORVIN:** Like what?
**MIREILLE:** Like a waiting room. — I'm not tragic, I'm just *early*.

**CORVIN:** How much is left?
**MIREILLE:** Of the memory? *(considers)* I've got my mother. I've lost the house she was in. I've got a song and I don't know who taught it to me, and I've got — *(stops)* — sorry. What was I saying?
**CORVIN:** Your mother.
**MIREILLE:** Did I say her name?
**CORVIN:** No.
**MIREILLE:** *(quietly)* Good. I'd like to keep it.

*(She has a book. Everything she is, written down, in three different hands as her handwriting degrades.)*

**MIREILLE:** Write in it for me. — Not about me. Just today. What the light was doing. Whether I was funny.
**CORVIN:** You were funny.
**MIREILLE:** Put that. Put it *first*.

**→ Optional chain. Completing it grants `cf_lust_mireille` and unlocks the Act III memory-decay UI early, so the player understands the mechanic before it happens to them.**

## DL_sabine_reveal — WRITTEN, ACT BREAK

**CORVIN:** *(sets `IT_cut_paper` on her desk)*
**SABINE:** *(doesn't look at it)* I know what it is.
**CORVIN:** Say it out loud.
**SABINE:** I signed for your death. Fourth of last month. Kane's broker, my counter-signature, eleven shillings' stamp duty which I paid myself because I wasn't going to have that on the office account.
**CORVIN:** *Why.*
**SABINE:** Because the alternative on the table was worse and I took the one I thought you'd forgive.
**CORVIN:** What was the alternative?
**SABINE:** *(beat)* No.
**CORVIN:** Sabine—
**SABINE:** No. You get the fact. You don't get the reason. The reason is mine and it cost me more than it cost you.
**CORVIN:** I *drowned*.
**SABINE:** Yes. And you came back. *(finally looking up)* I want you to sit with that for a moment before you decide which of us lost more.

*(He goes. She does not stop him. She does not apologise. She never apologises.)*

**END OF ACT II.**

`[TO WRITE: ~60 hotspot lines across R13–R16. ~40 duel attack lines for op_broker, op_customs_officer, op_juno, op_mireille.]`

---

# ACT III — "LOW WATER"

**Premise:** Day seven. The memory goes. Kane moves on the port.

**Systems change:** on each chapter tick, one solved journal entry and one inventory description degrade (spec §7.3 — text only, never functional).

## Rooms

| ID | Room | Function |
|---|---|---|
| `R17_registry_night` | Registry, after hours | The Registrar's last scene |
| `R18_church_burning` | The Church | Teodor dies |
| `R19_kane_hall` | The Confession Hall | Final duel |
| `R20_quay_end` | The Old Quay | All three endings |

## Puzzle chain

1. Kane calls the port debt. Sabine has four hours.
2. Corvin's remaining play is his own Litany — he must spend BETRAYAL 1–3 publicly to strip Kane's leverage over other people.
3. Teodor does the right thing for free, and it kills him. *(This must hurt. Do not undercut it with a joke.)*
4. `cf_bt_again` excavates — Corvin admits his remorse is fake.
5. All four BETRAYAL spent → **null play unlocks** → Kane duel.

## DL_kane_duel — THE ENDING OF THE MECHANIC

*Kane's pool is unbeatable by weight. Two centuries of sins, every one outranking Corvin's. The player will cycle the Litany looking for an answer and find nothing.*

**KANE:** You gave away the manifest. You gave away your friend. You gave away her harbour. *(gently)* What's left, Mr. Vale?

*(Litany opens. Every card greyed. One slot at the bottom, newly lit:)*

> **[ Nothing. There's nothing left. ]**

**CORVIN:** Nothing. There's nothing left.

**KANE:** *(the first time he has not been warm)* …That's not a confession.

**CORVIN:** No. It's an inventory.

*(Kane has nothing to buy, nothing to threaten, and nothing to offer. He was only ever a recruiter, and there's no one left in the room to recruit.)*

## Endings

**SALT** — Corvin refuses release. Calcifies on the quay. Becomes a bollard outside Sabine's window. Final line is hers, and she says it to a mooring post, every morning, for years.

**RELEASE** — requires every debt between them settled in Act III. Sabine forgives him everything and is owed nothing. He gets to die properly. The best ending and the quietest.

**TIDE** — requires ≥4 cruelty flags. Corvin takes Kane's chair. The offer gets made to someone new, warmly, by a man who is very good at it now.

`[TO WRITE: ~80 hotspot lines across R17–R20. Kane's 12 attack lines. Three ending scenes in full, ~1,200 words each.]`

---

# APPENDIX A — ACT I PUZZLE DEPENDENCY GRAPH

```
R01 → R02 ──┬─→ [FL_knows_dead] ─→ map unlock
            └─→ IT_knuckle_salt ─→ R06 ─→ IT_watch ─→ R07 ─→ IT_forgiveness ─→ [RITE 3]

R03 ─→ IT_boots
     ├─→ R08 ─→ IT_coroner_tag ─→ [FL_knows_daycount]
     ├─→ R05 ─→ WET lamp ─→ IT_ledger_page ─→ cf_bt_manifest ─┐
     │                                                          ├─→ DUEL ─→ [RITE 2]
     │         confessions ≥6 ────────────────────────────────┘
     └─→ R09 ─→ booth ─→ IT_rate_card ─→ R10 ─→ IT_regulator ─┐
                                              └─→ pool soak ───┴─→ R11 ─→ [RITE 1]

[RITE 1] + [RITE 2] + [RITE 3] ─→ R12 ─→ END ACT I
```

**Acyclic. No dead ends. No item is required before it is obtainable.** Verify against gate G1/G2.

---

# APPENDIX B — ACT I CONFESSION ACQUISITION

| Confession | Room | Method |
|---|---|---|
| `cf_pride_list`, `cf_cow_leftroom`, `cf_greed_widows` | R02 | Tomas, [Tell me something about myself] |
| `cf_lust_hands` | R02 | Scraping knuckle salt |
| `cf_greed_scales`, `cf_cow_drink` | R03 | Fishmonger eavesdrop |
| `cf_cruel_funeral`, `cf_pride_voice` | R03 | Confession queue eavesdrop |
| `cf_pride_handwriting` | R05 | LOOK roll book |
| `cf_bt_manifest` | R05 | `IT_ledger_page` |
| `cf_cruel_receipts` | R06 | LOOK chess set |
| `cf_cruel_names` | R06 | Chandler trade |
| `cf_cow_father` | R07 | LOOK almshouse window |
| `cf_greed_ring` | R07 | Prosper scene |
| `cf_pride_eulogy` | R08 | USE ice table |
| `cf_pride_twice` | R08 | LOOK visitor book |
| `cf_cow_didntfight` | R08 | `IT_coroner_tag` |
| `cf_greed_plate` | R09 | LOOK poor box |
| `cf_cruel_sentences` *or* `cf_cruel_diagnosis` | R09 | Booth, petitioner 1 branch |
| `cf_lust_float`, `cf_cow_apologize` | R10 | Staff corner |

**Total available in Act I: 18.** Duel entry requires 6. Petitioner 2 burns 1 for nothing. Comfortable margin, deliberate — the squeeze starts in Act II.
