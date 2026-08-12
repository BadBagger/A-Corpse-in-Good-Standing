# Act I Greybox Automated Playtest Report

- Generated: `2026-08-12 01:41:21`
- Runner: `tools/godot_record_act_i_greybox_playtest.gd`
- Scope: critical path from no Act I Rites complete through Sabine's office.


## Route

### Mudflats tutorial: `Mudflats/Silt` `look`
- Result: observed
- Player text: `Mordida mud establishes the opening ground texture.`
- Ink `mudflats_silt`:
  - `CORVIN`: `Mordida mud.`
  - `CORVIN`: `Half of it's mud. The other half is evidence with poor boundaries.`
  - `CORVIN`: `I've been in it. I'm not going back in it.`

### Mudflats tutorial: `Mudflats/OwnHands` `look`
- Result: observed
- Player text: `Corvin checks the grey at his nails and the body that still looks like his.`
- Ink `mudflats_hands`:
  - `CORVIN`: `Grey at the nails.`
  - `CORVIN`: `That's new.`
  - `CORVIN`: `Everything else looks like mine, which is somehow worse.`
  - `CORVIN`: `Not yet. Give it six days.`

### Mudflats tutorial: `Mudflats/HarborView` `look`
- Result: observed
- Player text: `The town's leviathan ribs read as the first background composition anchor.`
- Ink `mudflats_harbor_view`:
  - `CORVIN`: `The ribs.`
  - `CORVIN`: `Whole town's built through a dead thing's chest and nobody finds that remarkable but me.`
  - `CORVIN`: `I've talked at that harbor my whole life and it's never once answered.`

### Mudflats wet tutorial: `Mudflats/Coat` `use`
- Result: observed
- Player text: `Corvin wrings out the coat and creates the first persistent puddle read.`
- Ink `mudflats_coat_wet`:
  - `CORVIN`: `Wool.`
  - `CORVIN`: `Was expensive.`
  - `CORVIN`: `Is now a sponge with buttons.`
  - `NARRATION`: `He wrings one sleeve. A puddle forms and stays formed.`
  - `CORVIN`: `It's a coat, and I'm not that far gone. Yet.`

### Mudflats Tomas introduction: `Mudflats/BollardOfTomas` `talk`
- Result: observed
- Player text: `Tomas gives Corvin the first returned-rule scene before the Act I hint hub takes over.`
- Ink `old_quay_tomas`:
  - `TOMAS`: `Corvin?`
  - `NARRATION`: `Corvin keeps walking. Stops. Comes back.`
  - `TOMAS`: `Corvin Vale.`
  - `CORVIN`: `...Tomas?`
  - `TOMAS`: `Oh, thank Christ. I've been trying to get someone's attention for two years and everyone just ties a rope to me.`
  - `CORVIN`: `Tomas, you're a bollard.`
  - `TOMAS`: `I'm aware.`
  - `CORVIN`: `You're a bollard, Tomas.`
  - `TOMAS`: `Yes, and you're standing in mud with no shoes on, so let's both take a moment before we start ranking each other.`
  - `NARRATION`: `Corvin crouches to eye level. There are eyes. Sort of.`
  - `CORVIN`: `How long?`
  - `TOMAS`: `Two years, give or take. Ran out of days and the salt got the rest.`
  - `TOMAS`: `It's not so bad. You'd be amazed what people say in front of a mooring post.`
  - `CORVIN`: `Ran out of days.`
  - `TOMAS`: `Corvin. When did you get out of the water?`
  - `CORVIN`: `I didn't get in the water.`
  - `TOMAS`: `That's not what I asked.`
  - `CORVIN`: `This morning.`
  - `TOMAS`: `Right. Put your hand on your chest.`
  - `CORVIN`: `Tomas-`
  - `TOMAS`: `Put your hand on your chest, Corvin.`
  - `NARRATION`: `He does. Waits. Moves it slightly. Waits. Takes it away and looks at it like it's the hand's fault.`
  - `CORVIN`: `That's - no, that's a technique thing, you have to-`
  - `TOMAS`: `Corvin.`
  - `CORVIN`: `I've never been good at finding it, even when-`
  - `TOMAS`: `Corvin.`
  - `NARRATION`: `Water slaps the pilings.`
  - `CORVIN`: `How long do I get?`
  - `TOMAS`: `Nine days from when you went under. How many have you lost?`
  - `CORVIN`: `I don't know.`
  - `TOMAS`: `Then find out. That's the first thing. Everything else is second.`

### Mudflats exit pressure: `Mudflats/SaltMarketExit` `walk`
- Result: observed
- Player text: `Tomas points Corvin toward the market while the drowning question becomes actionable.`
- Ink `old_quay_equipment`:
  - `TOMAS`: `Somebody put you in there.`
  - `CORVIN`: `I know.`
  - `TOMAS`: `Then go find out who, while you've still got the equipment to be angry with.`

### Gate check: `HarbormasterOffice/ToSabine` `walk`
- Result: blocked
- Player text: `The clerk blocks Sabine's door. Three Rites, all complete, or no audience.`

### Act I blocked aftermath: `SaltMarket/BootStall` `talk`
- Result: blocked
- Player text: `The boot stall is only a stall until the market realizes Corvin is dead.`

### Old Quay hint hub: `OldQuay/Tomas` `talk`
- Result: applied
- Player text: `Tomas gives the useful version: warmth, pulse, Prosper, Registry. It is almost kind.`
- Ink `old_quay_tomas_topics`:
  - `TOMAS`: `You want the honest answer or the one that helps?`
  - `CORVIN`: `Honest.`
  - `TOMAS`: `The memory goes first. Oldest to newest, like lamps going out down a street.`
  - `TOMAS`: `You lose your mother, then your childhood, then the last twenty years, and the last thing left is whatever happened five minutes ago.`
  - `TOMAS`: `Then you're standing very still and someone's tying a rope to you.`
  - `CORVIN`: `And the one that helps?`
  - `TOMAS`: `It's quick at the end.`
  - `CORVIN`: `Is that true?`
  - `TOMAS`: `No.`
  - `TOMAS`: `Nobody drowns in Mordida harbor by accident. It's four feet deep at the quay and you could swim before you could read.`
  - `CORVIN`: `I know.`
  - `TOMAS`: `Then go find out who, while you've still got the equipment to be angry with.`
  - `CORVIN`: `How do I get back on the roll?`
  - `TOMAS`: `The Registry. Old woman runs it, no name, just the job.`
  - `TOMAS`: `She won't do it as a favour. She's never done anything as a favour in her life. You'll have to duel her for it.`
  - `CORVIN`: `With what?`
  - `TOMAS`: `With what you've done. Same as everyone.`
  - `CORVIN`: `I need someone to forgive me a debt.`
  - `TOMAS`: `Nobody on this island will forgive you anything. You're a notary.`
  - `TOMAS`: `Unless. Half-Coin Prosper's in the almshouse with the rot. He meets everyone fresh every morning.`
  - `CORVIN`: `He'd still have to have a reason.`
  - `TOMAS`: `So give him one before noon.`
  - `CORVIN`: `I need to pass for living.`
  - `TOMAS`: `Warmth and a pulse. That's all anyone checks, because that's all there is.`
  - `CORVIN`: `Warmth I can borrow.`
  - `TOMAS`: `A pulse you'll have to build.`
  - `CORVIN`: `Tell me something about myself.`
  - `TOMAS`: `You keep a list of everyone who's ever been wrong about you.`
  - `CORVIN`: `That's private.`
  - `TOMAS`: `It's alphabetical, Corvin. You showed it to me. Twice.`
  - `CORVIN`: `Nothing. Just checking you're still here.`
  - `TOMAS`: `Where would I go.`
- Flags set: `FL_tomas_topics_seen`
- Confessions discovered: `cf_pride_list`, `cf_cow_leftroom`, `cf_greed_widows`

### Old Quay foreshadowing: `OldQuay/SilentBollards` `talk`
- Result: applied
- Player text: `Corvin talks to the silent bollards. Tomas tells him they are past wanting to answer.`
- Ink `old_quay_silent_bollards`:
  - `CORVIN`: `Grey. Person-shaped if you're not careful about it.`
  - `CORVIN`: `Nothing.`
  - `TOMAS`: `They're past it.`
  - `CORVIN`: `Past talking?`
  - `TOMAS`: `Past wanting to.`
- Flags set: `FL_silent_bollards_seen`

### Old Quay bollard row: `OldQuay/BollardPetra` `talk`
- Result: applied
- Player text: `Corvin says Petra's name. The harbor answers for her, badly.`
- Ink `old_quay_bollard_petra`:
  - `CORVIN`: `Petra.`
  - `TOMAS`: `On the end. Used to sing.`
  - `CORVIN`: `Her mouth's gone.`
  - `TOMAS`: `No. Just closed for good.`
- Flags set: `FL_bollard_petra_seen`

### Old Quay bollard row: `OldQuay/BollardLedger` `talk`
- Result: applied
- Player text: `Corvin tries hello. Nothing comes back but gulls and bad timing.`
- Ink `old_quay_bollard_ledger`:
  - `CORVIN`: `There's a rope groove across this one's throat.`
  - `TOMAS`: `Collar, then rope. The island likes a promotion ladder.`
  - `CORVIN`: `Did you know him?`
  - `TOMAS`: `Everyone knew him while he owed money. Then fewer people made the effort.`
- Flags set: `FL_bollard_ledger_seen`

### Old Quay bollard row: `OldQuay/BollardBride` `talk`
- Result: applied
- Player text: `Corvin apologizes to the bollard and immediately dislikes himself for choosing the easy audience.`
- Ink `old_quay_bollard_bride`:
  - `CORVIN`: `Still wearing a ring.`
  - `TOMAS`: `She set on day nine waiting for a husband who'd already sailed.`
  - `CORVIN`: `That's awful.`
  - `TOMAS`: `That's port work.`
- Flags set: `FL_bollard_bride_seen`

### Old Quay Tomas follow-up: `OldQuay/Tomas` `talk`
- Result: applied
- Player text: `Tomas notices Corvin has made the whole silent row personal. Mordida does that to a man if he lets it.`
- Ink `old_quay_bollards_all_seen`:
  - `TOMAS`: `You've done the rounds.`
  - `CORVIN`: `I said three names to three dead people and got nothing back.`
  - `TOMAS`: `You got practice.`
  - `CORVIN`: `For what?`
  - `TOMAS`: `For Mordida. Most conversations here are with people who stopped listening before you arrived.`
- Flags set: `FL_bollard_row_reported`

### Old Quay inventory: `OldQuay/Flask` `use`
- Result: applied
- Player text: `Corvin takes the empty flask. It is evidence until proven otherwise.`
- Ink `old_quay_flask`:
  - `CORVIN`: `Somebody's flask.`
  - `TOMAS`: `Empty, obviously. This is a working quay.`
  - `CORVIN`: `I'll take it.`
  - `TOMAS`: `For courage?`
  - `CORVIN`: `For evidence. Courage leaks.`
- Items added: `IT_flask`
- Flags set: `FL_flask_taken`

### Act I public turn: `SaltMarket/MarketCrowd` `use`
- Result: applied
- Player text: `The boot seller says Vale is dead. The queue screams. Corvin counts six days and takes the fallen boots.`
- Ink `salt_market_public_recognition`:
  - `BOOT_SELLER`: `Morning. Size?`
  - `CORVIN`: `Eleven. And credit.`
  - `BOOT_SELLER`: `Credit's for people I know.`
  - `CORVIN`: `You know me. Vale. I did your brother's transfer papers.`
  - `NARRATION`: `The seller looks up. Looks properly. His face does something complicated.`
  - `BOOT_SELLER`: `...Vale.`
  - `CORVIN`: `There we are.`
  - `BOOT_SELLER`: `Vale's dead.`
  - `CORVIN`: `Well. That's the sort of thing people say.`
  - `BOOT_SELLER`: `No. No, they pulled you out Thursday. I saw it. They laid you on the ice at the fish hall.`
  - `CORVIN`: `Right, and I appreciate the attendance.`
  - `BOOT_SELLER`: `I brought my daughter.`
  - `CORVIN`: `That seems like a choice.`
  - `NARRATION`: `He backs into his own table. Boots go everywhere.`
  - `WOMAN`: `Oh God.`
  - `CORVIN`: `Look. Nobody needs to-`
  - `WOMAN`: `He's walking.`
  - `NARRATION`: `The street stops.`
  - `CORVIN`: `Thursday.`
  - `NARRATION`: `Arithmetic on his fingers. It doesn't take long.`
  - `CORVIN`: `Six days.`
  - `CORVIN`: `Six days to find out who held me under.`
  - `NARRATION`: `He picks up boots off the ground, unhurried, and walks out through a crowd that parts without anyone deciding to.`
- Items added: `BorrowedBoots`
- Flags set: `FL_market_recognized`, `FL_market_day_hint`
- Confessions discovered: `cf_pride_voice`

### Act I boot-stall aftermath: `SaltMarket/BootStall` `talk`
- Result: applied
- Player text: `The seller will not look at Corvin, except when he cannot help it.`
- Ink `salt_market_boot_stall_after`:
  - `CORVIN`: `He's rearranging boots that don't need it.`
  - `CORVIN`: `He'll be at that all day.`
  - `BOOT_SELLER`: `I've got nothing for you.`
  - `CORVIN`: `I know.`
  - `BOOT_SELLER`: `She's alright, by the way. The girl.`
  - `BOOT_SELLER`: `She thought it was interesting.`
  - `CORVIN`: `Kids are better at this than we are.`
  - `BOOT_SELLER`: `Don't make it sound kind.`
  - `CORVIN`: `I won't.`
- Flags set: `FL_boot_stall_after_seen`

### Act I eavesdrop: `SaltMarket/Fishmonger` `talk`
- Result: applied
- Player text: `The fishmonger complains about Corvin dripping on the cod. Corvin calls it a marinade.`
- Ink `salt_market_fishmonger`:
  - `CORVIN`: `Two sets of scales under that table.`
  - `CORVIN`: `The honest ones are on the wall where you can see them.`
  - `MONGER`: `You're dripping on the cod.`
  - `CORVIN`: `It's a marinade.`
  - `MONGER`: `That's not a selling point.`
  - `CORVIN`: `Neither is the cod.`
  - `MONGER`: `It was selling fine before you came back from the harbor.`
  - `CORVIN`: `Most things were.`
- Flags set: `FL_fishmonger_seen`
- Confessions discovered: `cf_greed_scales`, `cf_cow_drink`

### Act I eavesdrop: `SaltMarket/ConfessionQueue` `talk`
- Result: applied
- Player text: `The queue trades grief, interest rates, and one funeral story nobody should be enjoying.`
- Ink `salt_market_confession_queue`:
  - `WOMAN`: `He laughed at the funeral.`
  - `NARRATION`: `Eleven people wait to ask a dead man a question. Eight of them look like money.`
  - `NARRATION`: `A boy in a collar takes shillings under a sign that promises truth by the minute.`
  - `MAN`: `People laugh when they're nervous.`
  - `WOMAN`: `He wasn't nervous. He asked if the coffin came with a receipt.`
  - `CORVIN`: `That's not even a good line.`
  - `WOMAN`: `It was at the time.`
- Confessions discovered: `cf_cruel_funeral`
- Confession pickup blocked by global state: `cf_pride_voice`

### Act I market texture: `SaltMarket/WhaleOilLamp` `use`
- Result: applied
- Player text: `Corvin holds his hands near the lamp. Nothing. Not cold, not warm. Just reported.`
- Ink `salt_market_lamp`:
  - `CORVIN`: `Whale oil.`
  - `CORVIN`: `Warm light.`
  - `CORVIN`: `Everything warm on this island is something dead being useful.`
  - `CORVIN`: `Nothing.`
  - `CORVIN`: `Not cold, not warm.`
  - `CORVIN`: `Just reported.`
- Flags set: `FL_market_lamp_checked`

### Act I wet verb: `SaltMarket/ChurchSign` `wet`
- Result: applied
- Player text: `Corvin lets his sleeve drip over the tariff. The ink runs just enough to make doctrine expensive to read.`
- Ink `salt_market_church_sign_wet`:
  - `CORVIN`: `Petty.`
  - `CORVIN`: `Necessary.`
  - `CORVIN`: `Both.`
  - `WOMAN`: `Is he allowed to do that?`
  - `MAN`: `He's dead. I don't know who fines him.`
- Flags set: `FL_church_sign_wet`

### Day-count proof: `FishHall/IceTable` `use`
- Result: applied
- Player text: `Corvin lies down in the shape he left. It fits. That answers a question he did not ask.`
- Ink `fish_hall_ice_table`:
  - `CORVIN`: `That's the table.`
  - `CORVIN`: `There's still a shape in the ice.`
  - `CORVIN`: `Smaller than I'd have guessed.`
  - `CORVIN`: `The fish got burlap. I got a sheet.`
  - `CORVIN`: `Very formal. Very dead.`
  - `CORVIN`: `Fits.`
  - `CORVIN`: `Well. That answers a question I didn't ask.`
  - `CORVIN`: `I always thought I'd take up more room.`
- Flags set: `FL_body_fit_confirmed`

### Day-count proof: `FishHall/CoronerTag` `use`
- Result: applied
- Player text: `Corvin pockets the tag. No marks. Nobody hit him. Nobody had to.`
- Ink `fish_hall_coroner_tag`:
  - `CORVIN`: `VALE, C. THURS. RECOVERED, QUAY. NO MARKS.`
  - `CORVIN`: `They got the day right.`
  - `CORVIN`: `They got the place wrong, unless the quay learned to hold a man's head under.`
  - `CORVIN`: `No marks.`
  - `CORVIN`: `I want that on record too.`
  - `CORVIN`: `Nobody hit me. Nobody had to.`
  - `CORVIN`: `That's the part nobody writes down.`
- Items added: `IT_coroner_tag`
- Flags set: `FL_day_count_proven`, `FL_knows_daycount`

### Day-count proof: `FishHall/VisitorBook` `use`
- Result: applied
- Player text: `Corvin reads the names. Sabine is not in it. She would not sign a thing like that.`
- Ink `fish_hall_visitor_book`:
  - `CORVIN`: `Forty-one names.`
  - `CORVIN`: `People came through to look at me and signed for the privilege.`
  - `CORVIN`: `Good turnout. Terrible host.`
  - `CORVIN`: `Two clients, three creditors, and a woman who once told me I had merciful eyes.`
  - `CORVIN`: `I made a note to correct her, which is apparently my idea of mercy.`
  - `CORVIN`: `Sabine's not in it.`
  - `CORVIN`: `She wouldn't sign a thing like that.`
  - `CORVIN`: `She'd just come.`
- Flags set: `FL_sabine_absent_from_book`
- Confessions discovered: `cf_pride_twice`

### Fish Hall wet return: `FishHall/Drain` `wet`
- Result: applied
- Player text: `Corvin lets his coat drip into the drain. The island accepts the return without a receipt.`
- Ink `fish_hall_drain`:
  - `CORVIN`: `It all goes back to the harbor eventually.`
  - `CORVIN`: `Ice water. Fish blood. Whatever was left of me.`
  - `CORVIN`: `Efficient island.`
  - `CORVIN`: `No romance about it at all.`
  - `CORVIN`: `Just gravity, brine, and somewhere lower to be.`
- Flags set: `FL_fish_hall_drain_seen`

### Church support: `ChurchOfTheDrowned/PoorBox` `use`
- Result: applied
- Player text: `Corvin finds the bad hinge, the missing notes, and the Church's talent for losing small money.`
- Ink `church_poor_box`:
  - `CORVIN`: `Poor box.`
  - `NARRATION`: `The lock sits crooked, scraped bright around the screws.`
  - `CORVIN`: `Someone had the lock off and put it back badly.`
  - `NARRATION`: `Coins remain in the bottom. The folded notes are gone.`
  - `TEODOR`: `We had a locksmith.`
  - `CORVIN`: `You had a thief with a screwdriver and confidence.`
  - `TEODOR`: `Please don't say that near the vestry.`
- Confessions discovered: `cf_greed_plate`

### Church stall sign: `ChurchOfTheDrowned/ChurchStallSign` `use`
- Result: applied
- Player text: `Corvin reads the tariff and the queue. The Church has turned truth into inventory.`
- Ink `church_stall_sign`:
  - `CORVIN`: `THE DROWNED CANNOT LIE. ONE SHILLING.`
  - `NARRATION`: `The queue is eleven deep. Teodor is sweating through doctrine.`
  - `CORVIN`: `That's not theology. That's inventory pressure.`
  - `TEODOR`: `Please don't call it that where the queue can hear.`
- Flags set: `FL_church_stall_sign_seen`

### Church blocked booth access: `ChurchOfTheDrowned/RateCard` `use`
- Result: blocked
- Player text: `Teodor needs Corvin properly booked into the confession booth before he can hand over Church accounts.`
- Ink `teodor_needs_chit`:
  - `TEODOR`: `I can't put you in the stall without a chit.`
  - `CORVIN`: `I am visibly dead and damp.`
  - `TEODOR`: `Yes, but the Church prefers miracles in triplicate.`

### Church booth access: `ChurchOfTheDrowned/ConfessionBooth` `use`
- Result: applied
- Player text: `Teodor issues Corvin a confession chit with the relief of a man stamping his own reprieve.`
- Ink `church_confession_booth`:
  - `CORVIN`: `A green-lit box with a queue.`
  - `CORVIN`: `The Church found a way to make truth billable by the minute.`
  - `TEODOR`: `It's not a box. It's a booth.`
  - `CORVIN`: `The difference being?`
  - `TEODOR`: `Rates, mostly.`
  - `CORVIN`: `That's doctrine I can believe in.`
  - `TEODOR`: `Take this chit. If anyone asks, you were scheduled, expected, and absolutely not a miracle I found leaking on the floor.`
  - `CORVIN`: `That's almost a lie.`
  - `TEODOR`: `That's administration.`
- Items added: `IT_chit`
- Flags set: `FL_church_booth_seen`, `FL_chit_acquired`

### Rite 3 blocked watch: `BoneChandler/ProsperWatch` `use`
- Result: blocked
- Player text: `The Chandler wants fresh salt from a returned man. Corvin has not scraped any loose yet.`
- Ink `chandler_needs_salt`:
  - `CORVIN`: `Prosper's watch.`
  - `CORVIN`: `Under glass, chain worn through on the left.`
  - `CHANDLER`: `Right-handed and anxious. You do look at things.`
  - `CORVIN`: `I need it.`
  - `CHANDLER`: `Not for sale, I'm afraid.`
  - `CORVIN`: `Everything's for sale. That's why you put it behind glass.`
  - `CHANDLER`: `Fresh salt from a walking returned man. Bring me that and we'll discuss glass.`
  - `CORVIN`: `And until then?`
  - `CHANDLER`: `Until then the glass and I are both watching you.`

### Rite 3 wet verb: `OldQuay/RopeCleat` `wet`
- Result: applied
- Player text: `Corvin presses his wet knuckles to the cleat and scrapes loose fresh salt.`
- Ink `old_quay_rope_cleat`:
  - `CORVIN`: `Sharp edge.`
  - `TOMAS`: `You're not about to do something clever with your own knuckles.`
  - `CORVIN`: `No.`
  - `TOMAS`: `Corvin.`
  - `CORVIN`: `I'm about to do something useful with my own knuckles. Different sin.`
- Items added: `IT_knuckle_salt`
- Flags set: `FL_salt_scraped`

### Rite 3 blocked setup: `Almshouse/HalfCoinProsper` `use`
- Result: blocked
- Player text: `Prosper owes a favor only after the watch is returned.`
- Ink `prosper_before_watch`:
  - `PROSPER`: `Morning! Have we met?`
  - `CORVIN`: `Several times.`
  - `PROSPER`: `Marvellous. How did it go?`
  - `CORVIN`: `Badly, mostly. I owed you money.`
  - `PROSPER`: `Did you pay it?`
  - `CORVIN`: `No.`
  - `PROSPER`: `Well, there we are.`
  - `PROSPER`: `That makes us almost acquainted. Sit down, you look terrible.`
  - `CORVIN`: `You don't remember me.`
  - `PROSPER`: `No, but I can tell I was probably right to be fond of you.`
  - `CORVIN`: `That's generous.`
  - `PROSPER`: `It's cheap. I get to spend it fresh every morning.`

### Rite 3 room texture: `BoneChandler/Wares` `use`
- Result: applied
- Player text: `Corvin would rather not handle the neighbours.`
- Ink `chandler_wares`:
  - `CORVIN`: `Buttons. Needles. A chess set.`
  - `CORVIN`: `All of it was somebody.`
  - `CHANDLER`: `Still is, if you ask the right buyer.`
  - `CORVIN`: `I'd rather not handle the neighbours.`
- Flags set: `FL_chandler_wares_seen`

### Rite 3 room texture: `BoneChandler/ChessSet` `use`
- Result: applied
- Player text: `Corvin leaves the kings alone. They have enough dead men in politics.`
- Ink `chandler_chess_set`:
  - `CORVIN`: `White pieces are older stock.`
  - `CORVIN`: `They go pale after twenty years.`
  - `CORVIN`: `The black ones are recent.`
  - `CHANDLER`: `People prefer a matched set until they learn what matching costs.`
  - `CORVIN`: `I have rarely liked a sentence less.`
- Flags set: `FL_chandler_chess_seen`

### Rite 3 setup: `BoneChandler/ProsperWatch` `use`
- Result: applied
- Player text: `The Chandler accepts fresh salt from a walking returned man and hands over the watch.`
- Ink `chandler_watch_trade`:
  - `CHANDLER`: `Oh, you're new.`
  - `CORVIN`: `I'm not for sale.`
  - `CHANDLER`: `Everyone says that, and then day nine comes and someone ties a rope to them.`
  - `CHANDLER`: `The rope wears a groove, and the groove is where I start.`
  - `CORVIN`: `The watch. Under the glass.`
  - `CHANDLER`: `Prosper's. Collateral. Man owes me eleven shillings and the rot's taken his memory of owing it.`
  - `CORVIN`: `I'll trade.`
  - `CHANDLER`: `With what? You've got a wet coat and somebody else's boots.`
  - `CORVIN`: `Fresh enough?`
  - `CHANDLER`: `...That's fresh.`
  - `CORVIN`: `Off the knuckle. This morning.`
  - `CHANDLER`: `Off a walking man.`
  - `CHANDLER`: `Nobody brings me that. They bring me their uncle after he's set. They bring me buttons. Nobody brings me this.`
  - `CORVIN`: `I didn't feel it.`
  - `CHANDLER`: `No. That's rather the point, isn't it.`
  - `CHANDLER`: `Take the watch. Stop touching my counter.`
  - `CHANDLER`: `Come back when there's more.`
  - `CHANDLER`: `I'd rather you didn't. But come back.`
- Items added: `IT_watch`
- Flags set: `FL_watch_recovered`

### Rite 3 room texture: `Almshouse/Cots` `use`
- Result: applied
- Player text: `Corvin leaves them be.`
- Ink `almshouse_cots`:
  - `CORVIN`: `Twelve cots.`
  - `CORVIN`: `Nine occupied.`
  - `CORVIN`: `Three of them are past talking and nobody's moved them yet.`
  - `CORVIN`: `The sheets are folded back from their feet so the salt doesn't glue them down.`
  - `PROSPER`: `That's kind. Some people move you before you're done being somewhere.`
- Flags set: `FL_almshouse_cots_seen`

### Rite 3 room texture: `Almshouse/Window` `use`
- Result: applied
- Player text: `Corvin wipes salt from the sill. It comes back in the grain.`
- Ink `almshouse_window`:
  - `CORVIN`: `The window faces the water.`
  - `CORVIN`: `That seems cruel until you realize nobody here remembers what it means.`
  - `CORVIN`: `Every bed gets a stripe of harbor light. Equal shares of a bad idea.`
  - `PROSPER`: `Pretty, though.`
  - `CORVIN`: `Yes. That's usually how cruelty gets inside.`
- Flags set: `FL_almshouse_window_seen`

### Rite 3 complete: `Almshouse/HalfCoinProsper` `use`
- Result: applied
- Player text: `Corvin returns the watch. Prosper writes the forgiveness before the old anger can find the room.`
- Ink `prosper_forgiveness`:
  - `CORVIN`: `I've got something of yours.`
  - `PROSPER`: `...Oh.`
  - `CORVIN`: `You know it?`
  - `PROSPER`: `No. I don't know it at all. But my hand does.`
  - `PROSPER`: `Look. I've done that ten thousand times and I couldn't tell you once.`
  - `CORVIN`: `It was at the Chandler's. Collateral.`
  - `PROSPER`: `And you got it back for me.`
  - `CORVIN`: `Yes.`
  - `PROSPER`: `Why?`
  - `CORVIN`: `Because I need a favour and this was the shortest route to it.`
  - `PROSPER`: `Oh, that's lovely. Nobody's been honest with me in months.`
  - `PROSPER`: `They all think I won't notice, and they're right, but I notice that.`
  - `PROSPER`: `Go on. What's the favour?`
  - `CORVIN`: `I need a debt forgiven. In writing. Signed.`
  - `PROSPER`: `Is that all?`
  - `PROSPER`: `Whose?`
  - `CORVIN`: `...`
  - `CORVIN`: `Mine. Eleven shillings, sixteen years, and I've been avoiding you in the street since before you got sick.`
  - `PROSPER`: `...Corvin.`
  - `CORVIN`: `Yes.`
  - `PROSPER`: `I'm sorry — who?`
  - `PROSPER`: `There. Whoever you are, you don't owe me anything. We'll pretend I didn't hear the rest.`
- Items added: `IT_forgiveness`
- Flags set: `FL_rite_debt`

### Rite 2 blocked setup: `HarborRegistry/KestrelLedger` `use`
- Result: blocked
- Player text: `The Kestrel ledger is behind the Registrar's desk. She has not moved.`
- Ink `registry_ledger_blocked`:
  - `CORVIN`: `The Kestrel ledger is behind her desk.`
  - `REGISTRAR`: `And I am in front of my desk.`
  - `CORVIN`: `You're very good at furniture.`

### Rite 2 blocked setup: `HarborRegistry/Registrar` `talk`
- Result: blocked
- Player text: `The Registrar will duel him, but not while the Kestrel page is still safely above her desk.`
- Ink `registry_registrar_needs_manifest`:
  - `REGISTRAR`: `You can duel me when you know what you're here to say.`
  - `CORVIN`: `I know my name.`
  - `REGISTRAR`: `So does the book. The book crossed it out anyway.`

### Rite 2 setup: `HarborRegistry/Ledgers` `use`
- Result: applied
- Player text: `Corvin reads the wall of absences. The office has been eating people longer than he has.`
- Ink `registry_ledgers`:
  - `CORVIN`: `Four thousand names.`
  - `CORVIN`: `Every one struck out by the same hand.`
  - `REGISTRAR`: `Not the same hand. The same office.`
  - `CORVIN`: `That's worse.`
  - `REGISTRAR`: `That's why offices survive.`
  - `CORVIN`: `People don't. But the ledgers look well.`
  - `REGISTRAR`: `Paper has the decency not to beg.`
- Flags set: `FL_registry_ledgers_seen`

### Rite 2 setup: `HarborRegistry/RollBook` `use`
- Result: applied
- Player text: `Corvin reads the scratch again. The insult is administrative and personal.`
- Ink `registry_roll_book`:
  - `CORVIN`: `There. VALE, CORVIN.`
  - `NARRATION`: `The line through it has bitten into the paper, not just crossed it.`
  - `CORVIN`: `And a line through it. Not even a neat one.`
  - `REGISTRAR`: `I was busy.`
  - `CORVIN`: `I've been dead three days and somehow this is the wound that stings.`
  - `REGISTRAR`: `Names are vanity until someone takes yours away.`
  - `CORVIN`: `That's almost comforting.`
  - `REGISTRAR`: `Then I phrased it poorly.`

### Rite 2 wet verb: `HarborRegistry/DeskLamp` `wet`
- Result: applied
- Player text: `Corvin shakes his sleeve over the lamp. It gutters, smokes, and the Registrar rises to tend it.`
- Ink `registry_lamp_smoked`:
  - `CORVIN`: `Terribly sorry.`
  - `REGISTRAR`: `You drowned on my rug and now you're drowning my lamp.`
  - `CORVIN`: `I contain multitudes. Mostly water.`
  - `REGISTRAR`: `Don't move.`
  - `CORVIN`: `Wouldn't dream of it.`
  - `REGISTRAR`: `You dream professionally, Mr. Vale. Stay professionally still.`
- Flags set: `FL_registry_lamp_smoked`

### Rite 2 setup: `HarborRegistry/KestrelLedger` `use`
- Result: applied
- Player text: `Corvin tears out the Kestrel page. The Registrar knows. She saves it for the duel.`
- Ink `registry_ledger_page`:
  - `CORVIN`: `Kestrel. Hold listed as freight.`
  - `CORVIN`: `Eleven names buried in a number column.`
  - `NARRATION`: `The Registrar sees the torn corner. She does not rise.`
  - `REGISTRAR`: `Put that back.`
  - `CORVIN`: `Can't. I'm making it worse honestly.`
  - `REGISTRAR`: `Good. Then say it properly when the room is listening.`
  - `NARRATION`: `She files the moment somewhere quiet and reachable.`
  - `CORVIN`: `You knew it was there.`
  - `REGISTRAR`: `I know where every body is, Mr. Vale. The living just file them creatively.`
- Items added: `IT_ledger_page`
- Flags set: `FL_manifest_known`
- Confessions discovered: `cf_bt_manifest`

### Rite 2 complete: `HarborRegistry/Registrar` `talk`
- Result: duel opened
- Player text: `The Registrar opens the book. The Litany answers or it doesn't.`
- Ink `registrar_duel_start`:
  - `REGISTRAR`: `You're the Vale boy.`
  - `CORVIN`: `I'm thirty-six.`
  - `REGISTRAR`: `You're three days old.`
  - `REGISTRAR`: `Struck you out myself on Friday. Nice clean hand.`
  - `CORVIN`: `It wasn't, actually.`
  - `REGISTRAR`: `No. It wasn't.`
  - `REGISTRAR`: `What do you want?`
  - `CORVIN`: `My name back on the roll.`
  - `REGISTRAR`: `Can't. You're not a person.`
  - `REGISTRAR`: `The roll's for people, and a person has a pulse, and you have a coat and an attitude.`
  - `CORVIN`: `Then let me stand here and embarrass us both.`
  - `REGISTRAR`: `You want to duel me. For your name.`
  - `CORVIN`: `Church rule. You can't refuse a returned man a duel.`
  - `REGISTRAR`: `No, I can't.`
  - `REGISTRAR`: `I've been doing this forty years, Mr. Vale. Do you know what that means?`
  - `CORVIN`: `You're very good with ink?`
  - `REGISTRAR`: `That I'm bored of it.`
  - `REGISTRAR`: `Come on, then. The hall's cold and you won't notice, which is the only advantage you've got.`
- Duel UI: `Confession Duel: The Registrar`, `Accusation 1/8`, `Salt 0/3`, options `19`
- Round `reg_manifest`: attack `You signed a manifest you never read. Eleven people in that hold.` -> counter `cf_cruel_sentences` -> accepted `true`, salt `0`
- Round `reg_collection_plate`: attack `You took from a collection plate and called it liquidity.` -> counter `cf_greed_boots` -> accepted `true`, salt `0`
- Round `reg_clients_voice`: attack `You lower your voice for clients so theft sounds like counsel.` -> counter `cf_pride_list` -> accepted `true`, salt `0`
- Round `reg_soup_line`: attack `You sent a hungry man to a closed soup line.` -> counter `cf_cow_bigger` -> accepted `true`, salt `0`
- Round `reg_left_room`: attack `You leave rooms before truth can catch up.` -> counter `cf_cow_passive` -> accepted `true`, salt `0`
- Round `reg_float`: attack `You pay at the Float and pretend conversation is not what you bought.` -> counter `cf_lust_schedule` -> accepted `true`, salt `0`
- Round `reg_counselor`: attack `You let people call you counselor because fraud sounds better in a clean collar.` -> counter `cf_pride_counselor` -> accepted `true`, salt `0`
- Round `reg_kestrel_number`: attack `You knew the Kestrel number before you took the money.` -> counter `cf_bt_manifest` -> accepted `true`, salt `0`
- Ink `registrar_duel_win`:
  - `REGISTRAR`: `...Say the rest.`
  - `CORVIN`: `I read it twice. I wanted to be sure of the number before I took the money.`
  - `REGISTRAR`: `There. Vale, Corvin. Back in.`
  - `REGISTRAR`: `You said the Kestrel out loud, in a hall, in front of forty people and a man selling pastries.`
  - `REGISTRAR`: `There's nothing I could add.`
  - `CORVIN`: `That sounds almost kind.`
  - `REGISTRAR`: `No.`
  - `REGISTRAR`: `And Mr. Vale? What you told me in there, I'll be selling by supper.`
  - `REGISTRAR`: `That's the job. You knew it was the job when you walked in.`
  - `CORVIN`: `Yes.`
  - `REGISTRAR`: `Good. I prefer a man to recognize the knife before he rents it.`
- Items added: `IT_name_writ`
- Flags set: `FL_rite_name`, `FL_registrar_sold_manifest`

### Rite 1 blocked regulator: `GreyFloat/BilgeRegulator` `use`
- Result: blocked
- Player text: `Juno wants the Church rate card before she lets the regulator leave the Float.`
- Ink `juno_needs_rate_card`:
  - `JUNO`: `That pump is the only reason this barge is a barge and not a wreck with opinions.`
  - `CORVIN`: `I need something in my chest that ticks for an hour.`
  - `JUNO`: `Then bring me something worth breaking a pump over.`

### Rite 1 setup: `ChurchOfTheDrowned/RateCard` `use`
- Result: applied
- Player text: `Corvin sits the stall for an hour. The Church gets its returned man, Teodor keeps his posting, and the rate card changes hands.`
- Ink `teodor_rate_card_booth`:
  - `TEODOR`: `We're closed. We're... I'm sorry, we're closed.`
  - `CORVIN`: `Your queue disagrees.`
  - `TEODOR`: `My queue is a misunderstanding.`
  - `CORVIN`: `You sold slots you can't fill.`
  - `TEODOR`: `That is a very serious accusation and I would like to know who...`
  - `CORVIN`: `Nobody. You've got eleven people out there and one returned on your books, and I passed him on the quay this morning and he's a bollard now.`
  - `NARRATION`: `Teodor sits down on the step. Puts his head in his hands.`
  - `TEODOR`: `He was fine on Tuesday.`
  - `CORVIN`: `They're always fine on Tuesday.`
  - `TEODOR`: `They'll take the stall off me.`
  - `TEODOR`: `It's not even the money. My father got me this posting. He wrote letters.`
  - `CORVIN`: `Brother. Look at me.`
  - `TEODOR`: `Oh.`
  - `CORVIN`: `Oh.`
  - `TEODOR`: `You would sit? For me?`
  - `CORVIN`: `For an hour. And in exchange you give me the rate card. What the Church charges, by question type, with the margins.`
  - `TEODOR`: `That's... I could be defrocked for...`
  - `CORVIN`: `Teodor.`
  - `TEODOR`: `Yes. Right. Yes.`
  - `WOMAN`: `Did my husband love me?`
  - `CORVIN`: `He never told me.`
  - `WOMAN`: `That's kinder than I paid for.`
  - `CORVIN`: `Most things are.`
  - `BOY`: `Is it true you can't lie?`
  - `CORVIN`: `Yes.`
  - `BOY`: `Say something you'd never say.`
  - `CORVIN`: `I have spent twenty years making sentences where nobody did anything to anyone.`
  - `BOY`: `Why did you tell me that?`
  - `CORVIN`: `Because you asked and I'm made this way now.`
  - `BOY`: `That's worse.`
  - `CORVIN`: `Shilling, please.`
  - `KANE`: `Comfortable in there?`
  - `CORVIN`: `It's a box.`
  - `KANE`: `It's a booth, Mr. Vale, and the difference is that a booth has a queue.`
  - `KANE`: `I'll have my question now.`
  - `CORVIN`: `You haven't paid.`
  - `KANE`: `No. How many days have you got left?`
  - `CORVIN`: `Six.`
  - `KANE`: `Thank you. That's all I came for.`
  - `KANE`: `I like to know when a man's going to be reasonable, and it's never on day six.`
  - `NARRATION`: `He goes. The queue lets him through without being asked.`
- Items added: `IT_rate_card`
- Flags set: `FL_teodor_owes`, `FL_rate_card`, `FL_kane_seen`
- Confession pickup blocked by global state: `cf_cruel_sentences`

### Rite 1 blocked warmth: `GreyFloat/HotPool` `use`
- Result: blocked
- Player text: `Juno has not offered the pool yet, and the Float remembers unpaid manners.`
- Ink `juno_pool_before_permission`:
  - `CORVIN`: `The pool's warm.`
  - `JUNO`: `The pool's mine.`
  - `CORVIN`: `That's a distinction with steam on it.`
  - `JUNO`: `Bring me the Church's rate card, sugar. Then we'll discuss your temperature.`

### Rite 1 Juno negotiation: `GreyFloat/JunoTable` `use`
- Result: applied
- Player text: `Juno prices Corvin's trouble and names the Church rate card as the cost of her pump governor.`
- Ink `float_juno_table`:
  - `JUNO`: `You're dripping on my deck, and my deck is already wet, so I want you to understand that I noticed anyway.`
  - `CORVIN`: `Juno.`
  - `JUNO`: `Corvin Vale. Well. You look exactly the same, which is the rudest thing you've ever done to me.`
  - `CORVIN`: `People keep screaming.`
  - `JUNO`: `People are tourists. Sit. Don't sit there, that's Adela's. Sit there.`
  - `JUNO`: `Everybody comes here to feel something, sugar. You're just the first one honest about not being able to.`
  - `CORVIN`: `I need your pump governor.`
  - `JUNO`: `No.`
  - `CORVIN`: `Juno.`
  - `JUNO`: `That pump is the only reason this barge is a barge and not a wreck with opinions.`
  - `CORVIN`: `I need something in my chest that ticks for an hour.`
  - `JUNO`: `Oh, that's good. What's it worth?`
  - `CORVIN`: `What do you want?`
  - `JUNO`: `The Church's rate card. By question type. With the margins.`
- Flags set: `FL_float_juno_table_seen`

### Rite 1 blocked warmth: `GreyFloat/HotPool` `use`
- Result: blocked
- Player text: `Juno has not offered the pool yet, and the Float remembers unpaid manners.`
- Ink `juno_pool_before_permission`:
  - `CORVIN`: `The pool's warm.`
  - `JUNO`: `The pool's mine.`
  - `CORVIN`: `That's a distinction with steam on it.`
  - `JUNO`: `Bring me the Church's rate card, sugar. Then we'll discuss your temperature.`

### Rite 1 setup: `GreyFloat/BilgeRegulator` `use`
- Result: applied
- Player text: `Juno trades the regulator for the Church rate card and a look she pretends is not pity.`
- Ink `juno_regulator_trade`:
  - `JUNO`: `Thirty years I ran that trade. Thirty.`
  - `JUNO`: `And they came in with a building and a tariff, and now there's a queue in the market and a boy in a collar taking a shilling a question.`
  - `CORVIN`: `Sixteen percent on grief. It's in there.`
  - `JUNO`: `Sixteen.`
  - `CORVIN`: `I brought the Church rate card.`
  - `NARRATION`: `Juno does not touch it. She looks at it a long time.`
  - `JUNO`: `Governor's on the pump. Take it, mind the spring. And Corvin — the pool's free.`
  - `CORVIN`: `How did you—`
  - `JUNO`: `Sugar, I've been putting warmth into cold men for forty years. It's the whole business.`
- Items added: `IT_regulator`
- Flags set: `FL_juno_met`, `FL_regulator_acquired`

### Rite 1 eavesdrop: `GreyFloat/StaffCorner` `talk`
- Result: applied
- Player text: `The staff corner settles nothing, but it gives Corvin two things he can use later: shame and phrasing.`
- Ink `float_staff_corner`:
  - `ADELA`: `He said sorry and left two buttons.`
  - `MARIN`: `Two good buttons?`
  - `ADELA`: `One good button and one apology.`
  - `MARIN`: `So no.`
  - `CORVIN`: `That's a harsh exchange rate.`
  - `ADELA`: `Sorry is the cheapest word men carry.`
  - `MARIN`: `Men come here to feel forgiven and leave us the small change.`
  - `ADELA`: `Forgiven costs extra.`
  - `CORVIN`: `Does it work?`
  - `ADELA`: `For them? Usually.`
  - `MARIN`: `For us? Never before breakfast.`
  - `CORVIN`: `I'll stop apologizing, then.`
  - `ADELA`: `Don't flatter yourself. We charge for silence too.`
- Confessions discovered: `cf_cow_apologize`
- Confession pickup blocked by global state: `cf_lust_float`

### Rite 1 room texture: `GreyFloat/SteamScreen` `use`
- Result: applied
- Player text: `Corvin lets the steam hide him and discovers it cannot make him warm.`
- Ink `float_steam_screen`:
  - `CORVIN`: `Steam, backlight, silhouettes.`
  - `CORVIN`: `The Float sells privacy by making everybody an outline.`
  - `JUNO`: `Eyes front, Corvin.`
  - `CORVIN`: `My eyes are front.`
  - `JUNO`: `Your imagination isn't.`
  - `CORVIN`: `That survived the drowning. Very inconvenient.`
  - `JUNO`: `So did manners, if you ever owned any.`
  - `CORVIN`: `It's only heat and shadow.`
  - `JUNO`: `That's what privacy is, sugar. Heat, shadow, and people agreeing not to name what they saw.`
  - `CORVIN`: `I can't feel the heat.`
  - `JUNO`: `Then respect the shadow.`
- Flags set: `FL_float_steam_seen`

### Rite 1 anteroom texture: `HarbormasterOffice/ChecklistDesk` `use`
- Result: applied
- Player text: `Corvin reads the boxes again: name, debt, heartbeat. Bureaucracy loves a trilogy.`
- Ink `harbormaster_checklist_desk`:
  - `CORVIN`: `Three boxes beside my name.`
  - `CORVIN`: `Name. Debt. Heartbeat.`
  - `CLERK`: `All three. In ink. No pencil for the dead.`
  - `CORVIN`: `That's the warmest thing anyone's said to me in an office.`
  - `CLERK`: `I can scratch it out if you prefer.`
- Flags set: `FL_harbormaster_checklist_seen`

### Rite 1 anteroom texture: `HarbormasterOffice/SabineDoor` `use`
- Result: applied
- Player text: `The handle does not move. The clerk's pen does, which is worse.`
- Ink `harbormaster_sabine_door`:
  - `CORVIN`: `SABINE CROIX, HARBORMASTER.`
  - `NARRATION`: `Black letters on frosted glass. Her office is one room away and still somehow uphill.`
  - `CORVIN`: `I've crossed oceans with less weather in them.`
  - `CLERK`: `Door opens when the list says it opens.`
- Flags set: `FL_harbormaster_sabine_door_seen`

### Rite 1 blocked warmth: `HarbormasterOffice/ChecklistClerk` `use`
- Result: blocked
- Player text: `Corvin needs both the regulator's false pulse and the Float's borrowed warmth before the clerk can be fooled.`
- Ink `heartbeat_check_fail`:
  - `CLERK`: `You're cold.`
  - `CORVIN`: `It's a cold morning.`
  - `CLERK`: `It's August. Out.`
  - `CORVIN`: `I have circulation issues.`
  - `CLERK`: `You have absence issues. Out twice.`

### Rite 1 warmth: `GreyFloat/HotPool` `use`
- Result: applied
- Player text: `Corvin stands in the hot pool until his skin can pass for living. It feels like information, not comfort.`
- Ink `juno_hot_pool_soak`:
  - `JUNO`: `Ten minutes.`
  - `NARRATION`: `The amber screen slides shut. Steam turns the room into voices and shoulders.`
  - `CORVIN`: `I need an hour.`
  - `JUNO`: `You get ten minutes of heat and fifty minutes of lying posture.`
  - `CORVIN`: `I can't lie.`
  - `JUNO`: `Then stand very confidently.`
  - `NARRATION`: `His skin takes the warmth before he does. That feels worse than cold.`
  - `CORVIN`: `Nothing.`
  - `JUNO`: `Warmth or feeling?`
  - `CORVIN`: `Yes.`
  - `JUNO`: `Then move while your skin still remembers.`
- Flags set: `FL_float_warmth_active`

### Rite 1 expired warmth: `HarbormasterOffice/ChecklistClerk` `use`
- Result: blocked
- Player text: `Corvin needs both the regulator's false pulse and the Float's borrowed warmth before the clerk can be fooled.`
- Ink `heartbeat_check_fail`:
  - `CLERK`: `You're cold.`
  - `CORVIN`: `It's a cold morning.`
  - `CLERK`: `It's August. Out.`
  - `CORVIN`: `I have circulation issues.`
  - `CLERK`: `You have absence issues. Out twice.`

### Rite 1 re-soak: `GreyFloat/HotPool` `use`
- Result: applied
- Player text: `Corvin stands in the hot pool until his skin can pass for living. It feels like information, not comfort.`
- Ink `juno_warmth_expired`:
  - `JUNO`: `You wandered off, didn't you.`
  - `CORVIN`: `I took a scenic route through civic incompetence.`
  - `JUNO`: `You had one job and it was to walk in a straight line.`
  - `CORVIN`: `In fairness, I was briefly alive enough to make bad choices.`
  - `JUNO`: `Back in the pool, sugar. Try not to make tourism out of it.`
- Flags set: `FL_float_warmth_active`

### Rite 1 complete: `HarbormasterOffice/ChecklistClerk` `use`
- Result: applied
- Player text: `The regulator knocks inside Corvin's coat and the pool heat lingers in his hand. The clerk marks heartbeat complete.`
- Ink `heartbeat_check_pass`:
  - `CLERK`: `Name.`
  - `CORVIN`: `Vale.`
  - `CLERK`: `You're on. Right hand.`
  - `CORVIN`: `Is this medical or civic?`
  - `CLERK`: `On Mordida, those are the same stamp.`
  - `CLERK`: `Hold still.`
  - `NARRATION`: `He takes Corvin's wrist and waits.`
  - `CORVIN`: `I'm a monument to stillness.`
  - `NARRATION`: `The regulator ticks under the coat, four inches off and slightly too regular.`
  - `CLERK`: `Your pulse is four inches left of your wrist.`
  - `CORVIN`: `Old injury.`
  - `CLERK`: `That's fast.`
  - `CORVIN`: `I'm nervous. She has that effect.`
  - `NARRATION`: `The clerk feels Corvin's hand.`
  - `CLERK`: `Your hand's warm.`
  - `CORVIN`: `I had an emotional morning.`
  - `CLERK`: `Fine. Go through.`
- Flags set: `FL_rite_heartbeat`

### Act I gate: `HarbormasterOffice/ToSabine` `walk`
- Result: applied
- Player text: `Corvin heads for Sabine.`
- Target room: `SabineOffice`
- Transition animation: `walk_side_right`

### Act I close: `SabineOffice/SabineDesk` `talk`
- Result: applied
- Player text: `Sabine lets Corvin decide what her explanation is worth. She does not apologize.`
- Ink `sabine_act_i_audience`:
  - `SABINE`: `You're dripping on the Persian.`
  - `CORVIN`: `It's brine. It's antiquing. You'll thank me in a decade.`
  - `SABINE`: `You always did know how to make an entrance.`
  - `CORVIN`: `I drowned, Sabine.`
  - `SABINE`: `Yes. It was very dramatic. I cried for almost a full minute.`
  - `CORVIN`: `A minute.`
  - `SABINE`: `It was a busy week.`
  - `NARRATION`: `She writes another line, sets down the pen, and looks at him for the first time.`
  - `SABINE`: `You're on the roll again. I saw.`
  - `CORVIN`: `I had to out-confess a seventy-year-old woman in front of a paying audience.`
  - `SABINE`: `How was it?`
  - `CORVIN`: `Humiliating and extremely well attended.`
  - `SABINE`: `What did you give her?`
  - `CORVIN`: `The Kestrel.`
  - `SABINE`: `Out loud.`
  - `CORVIN`: `Out loud, in a hall, to about forty people and a man selling pastries.`
  - `SABINE`: `Corvin.`
  - `CORVIN`: `It's fine. It's actually the only clever thing I've done since Tuesday. Nobody can hold it over me now.`
  - `CORVIN`: `You can't blackmail a man with a thing he shouted.`
  - `SABINE`: `That's not why you did it.`
  - `CORVIN`: `No.`
  - `SABINE`: `Why did you do it?`
  - `CORVIN`: `Because I wanted one person on this island to know the worst of it and still be standing there afterwards.`
  - `CORVIN`: `She was.`
  - `CORVIN`: `She wrote my name back in. Didn't say anything about it.`
  - `NARRATION`: `Water pools on Sabine's floor. She crosses through it like it isn't there.`
  - `SABINE`: `Hold still.`
  - `CORVIN`: `What?`
  - `SABINE`: `Hold still.`
  - `NARRATION`: `Two fingers to the inside of his wrist. Four seconds. Nothing. Her hand stays.`
  - `CORVIN`: `That's not how you check.`
  - `SABINE`: `I know how to check.`
  - `CORVIN`: `There isn't anything there.`
  - `SABINE`: `I noticed.`
  - `CORVIN`: `Sabine.`
  - `SABINE`: `Don't make me say a thing badly when I'm doing it correctly.`
  - `SABINE`: `Get out of my office, Corvin.`
  - `CORVIN`: `Right.`
  - `SABINE`: `Six days.`
  - `CORVIN`: `Five.`
- Flags set: `FL_act_i_complete`


## Final State

- Items: `BorrowedBoots`, `IT_chit`, `IT_coroner_tag`, `IT_flask`, `IT_forgiveness`, `IT_knuckle_salt`, `IT_ledger_page`, `IT_name_writ`, `IT_rate_card`, `IT_regulator`, `IT_watch`
- Act I flags: `FL_tomas_topics_seen`, `FL_silent_bollards_seen`, `FL_bollard_petra_seen`, `FL_bollard_ledger_seen`, `FL_bollard_bride_seen`, `FL_bollard_row_reported`, `FL_flask_taken`, `FL_market_recognized`, `FL_market_day_hint`, `FL_boot_stall_after_seen`, `FL_fishmonger_seen`, `FL_market_lamp_checked`, `FL_church_sign_wet`, `FL_body_fit_confirmed`, `FL_day_count_proven`, `FL_knows_daycount`, `FL_sabine_absent_from_book`, `FL_fish_hall_drain_seen`, `FL_church_stall_sign_seen`, `FL_church_booth_seen`, `FL_chit_acquired`, `FL_salt_scraped`, `FL_chandler_wares_seen`, `FL_chandler_chess_seen`, `FL_watch_recovered`, `FL_almshouse_cots_seen`, `FL_almshouse_window_seen`, `FL_rite_debt`, `FL_registry_ledgers_seen`, `FL_registry_lamp_smoked`, `FL_manifest_known`, `FL_rite_name`, `FL_registrar_sold_manifest`, `FL_teodor_owes`, `FL_rate_card`, `FL_kane_seen`, `FL_float_juno_table_seen`, `FL_juno_met`, `FL_regulator_acquired`, `FL_float_steam_seen`, `FL_harbormaster_checklist_seen`, `FL_harbormaster_sabine_door_seen`, `FL_float_warmth_active`, `FL_float_warmth_expired`, `FL_rite_heartbeat`, `FL_act_i_complete`
- Spent confessions: `cf_bt_manifest`, `cf_cow_bigger`, `cf_cow_passive`, `cf_cruel_sentences`, `cf_greed_boots`, `cf_lust_schedule`, `cf_pride_counselor`, `cf_pride_list`
- Locked opponent-spoken confessions: `cf_cow_leftroom`, `cf_cruel_soupline`, `cf_greed_plate`, `cf_lust_float`, `cf_pride_voice`
- Discovered confessions: `cf_cow_apologize`, `cf_cow_drink`, `cf_cruel_funeral`, `cf_greed_scales`, `cf_greed_widows`, `cf_pride_twice`
- Rites complete: `true`

## Automated Notes

- This is a deterministic greybox recorder, not a human fun/readability verdict.
- It confirms the critical Act I route is playable and captures the current beats for review.
- Generated Act I room exits now record direction-aware transition animations (`walk_side_left` or `walk_side_right`), and arrivals settle Corvin into `idle_current_side` so he does not snap to the wrong facing after a transition.
- Known simplification: several authored Act I script beats are represented by first-pass greybox interactions rather than full scene-level dialogue.
- Mudflats now captures the four authored tutorial/environment hotspots: silt, own hands, harbor view, and coat/wet demonstration, plus the Tomas returned-rule introduction and exit-pressure beat before Act I opens into the market.
- Old Quay now captures Tomas as the Act I hint hub, the Appendix B source for `cf_pride_list`, `cf_cow_leftroom`, and `cf_greed_widows`, the three individual silent bollards as a quay composition row, Tomas's conditional all-three-bollards follow-up, and the Act I item-master flask pickup.
- Salt Market is now verified as the Act I hub for Old Quay, Registry, Bone Chandler, Almshouse, Fish Hall, and the Church; the room graph gate proves all registered rooms are reachable from Mudflats through actual exits.
- The Salt Market public-recognition beat now establishes `FL_market_recognized`, `FL_market_day_hint`, `BorrowedBoots`, and `cf_pride_voice` before the Rites, and captures the seller's face-change, scattered boots, frozen street, and crowd-parting staging that makes the market navigable.
- The Salt Market boot-stall aftermath now stays blocked until the public-recognition beat, then captures the scattered-boots prop cluster, seller avoidance, and daughter line as an art-planning interaction.
- The Salt Market fishmonger beat now captures the two-scales prop read and cod/drip exchange, sets `FL_fishmonger_seen`, and moves `cf_cow_drink` onto the fishmonger pickup alongside `cf_greed_scales` per the Act I script.
- The Salt Market confession queue now stages the eleven-person paid-truth line before adding the Act I-safe `cf_cruel_funeral` pickup ahead of the Registrar duel.
- The Salt Market whale-oil lamp now captures the amber warmth/no-temperature body read before the Rites.
- The global `wet` verb is now exercised on the Church sign, Fish Hall drain, Old Quay rope cleat, and Registry desk lamp during the automated route.
- The Fish Hall proof now captures the expanded body-table size read, wrong-place tag read, visitor-book pride beat, and drain return line while establishing `FL_body_fit_confirmed`, `FL_knows_daycount`, `FL_sabine_absent_from_book`, `FL_fish_hall_drain_seen`, `IT_coroner_tag`, and `cf_pride_twice`; `cf_pride_eulogy` and `cf_cow_didntfight` stay deferred because the Litany marks them Act II/III.
- The Church poor-box beat now discovers `cf_greed_plate` before the Registrar can lock that sin as opponent-spoken, with the crooked-lock and missing-notes read staged in Ink.
- The Church stall sign now captures the one-shilling paid-truth read as a non-progress Ink beat, separate from Teodor's gated rate-card exchange.
- The Church confession booth now captures the green-lit paid-truth staging, awards `IT_chit`, and gates Teodor's rate-card stall before booth access; the rate-card booth carries Teodor's posting panic, the three fixed petitioner beats, `FL_kane_seen`, and Kane's day-six pressure without adding the deferred confession-choice/spend sequence.
- The Debt Forgiven path now captures Bone Chandler wares/chess-set and Almshouse cots/window room texture, including the chess-set aging read and Almshouse salt-sheet/harbor-light art anchors without awarding `cf_cruel_receipts` or `cf_cow_father` early; the watch trade includes the authored fresh-salt-from-a-walking-returned beat and Prosper's forgiveness scene includes the hand-memory/truth-lock beats.
- The Bone Chandler watch gate now records the blocked under-glass/watch-chain read before `IT_knuckle_salt`, proving the watch cannot be acquired before Corvin scrapes fresh salt.
- The Almshouse before-watch Prosper scene now carries the fresh-every-morning memory-rot beat; Bone Chandler chess-set, Chandler trade, Almshouse window, Prosper forgiveness, and Registry roll-book remain art/emotional anchors and still do not grant the Act II `cf_cruel_receipts`, `cf_cruel_names`, `cf_cow_father`, `cf_greed_ring`, or `cf_pride_handwriting` confessions.
- Borrowed Heartbeat now requires both `IT_regulator` and `FL_float_warmth_active`; the report captures the blocked pump-governor setup before the Church rate card, blocked warmth before Juno permission, blocked warmth before the hot-pool soak, the amber-screen/steam privacy staging during the soak, warmth expiry across three room transitions, the authored Juno return line before the re-soak, and the Harbormaster wrist check as staged physical action.
- The Harbormaster anteroom now carries checklist-desk and Sabine-door art anchors before the fake-pulse check: three boxes beside Corvin's name, frosted glass, and the one-room-away staging before Sabine.
- The Float staff corner now offers the Act I-safe `cf_lust_float` and `cf_cow_apologize` pickups through named staff tip-grievance chatter; in this Name-before-Heartbeat route `cf_lust_float` is already opponent-spoken by the Registrar and correctly blocked by global state, the bilge-regulator trade stays item/flag-only, and no confession-spend interaction is introduced.
- The Float pump governor now has a captured blocked setup before the Church rate card, proving the regulator is visible as the Rite 1 prop but cannot leave the barge early; the Juno table carries the authored first negotiation, and the trade captures Juno's long look at the Church rate card before she gives it up.
- The Registry ledgers beat now sets `FL_registry_ledgers_seen` before the roll book and ledger sub-puzzle, with expanded office/ledger texture; the roll book carries the scored-paper strike-through as an art anchor without granting `cf_pride_handwriting` early, and the Kestrel page pickup captures the Registrar filing the torn-corner moment for the duel.
- The Registrar route now earns `cf_bt_manifest` from `IT_ledger_page` before the accepted duel path spends it, then sets `FL_registrar_sold_manifest` as the Act II/III consequence hook for the Registrar selling the Kestrel confession.
- The Act I Sabine office close now captures the pen-down first-look beat, water pooling on the floor, Sabine crossing through it, and the extended wrist check while preserving the no-apology rule.
- Sabine's Act I close now captures the public Kestrel-confession aftermath, her writing Corvin back into standing without apologizing, the wrist/no-pulse beat, and the final Six/Five exchange.
- Next design review should compare this report against `docs/script/act_i_full_script_build_document.md` and decide which room beats need to be expanded before art.
