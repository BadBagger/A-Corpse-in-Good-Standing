INCLUDE confessions.ink

VAR current_day = 3
VAR learned_returned_rule = false
VAR recovered_boots = false
VAR reached_salt_market = false

-> mudflats_wake

=== mudflats_wake ===
# speaker:CORVIN
The tide comes in twice a day at Mordida. Once with the fish. Once with everybody else.
# speaker:CORVIN
Huh.
# speaker:CORVIN
That's a Tuesday.
-> old_quay_tomas

=== mudflats_silt ===
# location:mudflats
# speaker:CORVIN
Mordida mud.
# speaker:CORVIN
Half of it's mud. The other half is evidence with poor boundaries.
# speaker:CORVIN
I've been in it. I'm not going back in it.
-> END

=== mudflats_hands ===
# location:mudflats
# speaker:CORVIN
Grey at the nails.
# speaker:CORVIN
That's new.
# speaker:CORVIN
Everything else looks like mine, which is somehow worse.
# speaker:CORVIN
Not yet. Give it six days.
-> END

=== mudflats_harbor_view ===
# location:mudflats
# speaker:CORVIN
The ribs.
# speaker:CORVIN
Whole town's built through a dead thing's chest and nobody finds that remarkable but me.
# speaker:CORVIN
I've talked at that harbor my whole life and it's never once answered.
-> END

=== mudflats_coat_wet ===
# location:mudflats
# speaker:CORVIN
Wool.
# speaker:CORVIN
Was expensive.
# speaker:CORVIN
Is now a sponge with buttons.
# speaker:NARRATION
He wrings one sleeve. A puddle forms and stays formed.
# speaker:CORVIN
It's a coat, and I'm not that far gone. Yet.
-> END

=== old_quay_tomas ===
# location:old_quay
# speaker:TOMAS
Corvin?
# speaker:NARRATION
Corvin keeps walking. Stops. Comes back.
# speaker:TOMAS
Corvin Vale.
# speaker:CORVIN
...Tomas?
# speaker:TOMAS
Oh, thank Christ. I've been trying to get someone's attention for two years and everyone just ties a rope to me.
# speaker:CORVIN
Tomas, you're a bollard.
# speaker:TOMAS
I'm aware.
# speaker:CORVIN
You're a bollard, Tomas.
# speaker:TOMAS
Yes, and you're standing in mud with no shoes on, so let's both take a moment before we start ranking each other.
# speaker:NARRATION
Corvin crouches to eye level. There are eyes. Sort of.
# speaker:CORVIN
How long?
# speaker:TOMAS
Two years, give or take. Ran out of days and the salt got the rest.
# speaker:TOMAS
It's not so bad. You'd be amazed what people say in front of a mooring post.
# speaker:CORVIN
Ran out of days.
# speaker:TOMAS
Corvin. When did you get out of the water?
# speaker:CORVIN
I didn't get in the water.
# speaker:TOMAS
That's not what I asked.
# speaker:CORVIN
This morning.
# speaker:TOMAS
Right. Put your hand on your chest.
# speaker:CORVIN
Tomas-
# speaker:TOMAS
Put your hand on your chest, Corvin.
# speaker:NARRATION
He does. Waits. Moves it slightly. Waits. Takes it away and looks at it like it's the hand's fault.
# speaker:CORVIN
That's - no, that's a technique thing, you have to-
# speaker:TOMAS
Corvin.
# speaker:CORVIN
I've never been good at finding it, even when-
# speaker:TOMAS
Corvin.
# speaker:NARRATION
Water slaps the pilings.
# speaker:CORVIN
How long do I get?
# speaker:TOMAS
Nine days from when you went under. How many have you lost?
# journal:add:j_returned_nine_days
~ learned_returned_rule = true
# confession:discover:cf_cow_leftroom
# speaker:CORVIN
I don't know.
# speaker:TOMAS
Then find out. That's the first thing. Everything else is second.
-> old_quay_equipment

=== old_quay_equipment ===
# speaker:TOMAS
Somebody put you in there.
# speaker:CORVIN
I know.
# journal:add:j_somebody_drowned_corvin
# confession:discover:cf_pride_voice
# speaker:TOMAS
Then go find out who, while you've still got the equipment to be angry with.
-> salt_market_arrival

=== old_quay_tomas_topics ===
# location:old_quay
# speaker:TOMAS
You want the honest answer or the one that helps?
# speaker:CORVIN
Honest.
# speaker:TOMAS
The memory goes first. Oldest to newest, like lamps going out down a street.
# speaker:TOMAS
You lose your mother, then your childhood, then the last twenty years, and the last thing left is whatever happened five minutes ago.
# speaker:TOMAS
Then you're standing very still and someone's tying a rope to you.
# speaker:CORVIN
And the one that helps?
# speaker:TOMAS
It's quick at the end.
# speaker:CORVIN
Is that true?
# speaker:TOMAS
No.
# speaker:TOMAS
Nobody drowns in Mordida harbor by accident. It's four feet deep at the quay and you could swim before you could read.
# speaker:CORVIN
I know.
# speaker:TOMAS
Then go find out who, while you've still got the equipment to be angry with.
# speaker:CORVIN
How do I get back on the roll?
# speaker:TOMAS
The Registry. Old woman runs it, no name, just the job.
# speaker:TOMAS
She won't do it as a favour. She's never done anything as a favour in her life. You'll have to duel her for it.
# speaker:CORVIN
With what?
# speaker:TOMAS
With what you've done. Same as everyone.
# speaker:CORVIN
I need someone to forgive me a debt.
# speaker:TOMAS
Nobody on this island will forgive you anything. You're a notary.
# speaker:TOMAS
Unless. Half-Coin Prosper's in the almshouse with the rot. He meets everyone fresh every morning.
# speaker:CORVIN
He'd still have to have a reason.
# speaker:TOMAS
So give him one before noon.
# speaker:CORVIN
I need to pass for living.
# speaker:TOMAS
Warmth and a pulse. That's all anyone checks, because that's all there is.
# speaker:CORVIN
Warmth I can borrow.
# speaker:TOMAS
A pulse you'll have to build.
# speaker:CORVIN
Tell me something about myself.
# speaker:TOMAS
You keep a list of everyone who's ever been wrong about you.
# speaker:CORVIN
That's private.
# speaker:TOMAS
It's alphabetical, Corvin. You showed it to me. Twice.
# speaker:CORVIN
Nothing. Just checking you're still here.
# speaker:TOMAS
Where would I go.
-> END

=== old_quay_silent_bollards ===
# location:old_quay
# speaker:CORVIN
Grey. Person-shaped if you're not careful about it.
# speaker:CORVIN
Nothing.
# speaker:TOMAS
They're past it.
# speaker:CORVIN
Past talking?
# speaker:TOMAS
Past wanting to.
-> END

=== old_quay_bollard_petra ===
# location:old_quay
# speaker:CORVIN
Petra.
# speaker:TOMAS
On the end. Used to sing.
# speaker:CORVIN
Her mouth's gone.
# speaker:TOMAS
No. Just closed for good.
-> END

=== old_quay_bollard_ledger ===
# location:old_quay
# speaker:CORVIN
There's a rope groove across this one's throat.
# speaker:TOMAS
Collar, then rope. The island likes a promotion ladder.
# speaker:CORVIN
Did you know him?
# speaker:TOMAS
Everyone knew him while he owed money. Then fewer people made the effort.
-> END

=== old_quay_bollard_bride ===
# location:old_quay
# speaker:CORVIN
Still wearing a ring.
# speaker:TOMAS
She set on day nine waiting for a husband who'd already sailed.
# speaker:CORVIN
That's awful.
# speaker:TOMAS
That's port work.
-> END

=== old_quay_bollards_all_seen ===
# location:old_quay
# speaker:TOMAS
You've done the rounds.
# speaker:CORVIN
I said three names to three dead people and got nothing back.
# speaker:TOMAS
You got practice.
# speaker:CORVIN
For what?
# speaker:TOMAS
For Mordida. Most conversations here are with people who stopped listening before you arrived.
-> END

=== old_quay_flask ===
# location:old_quay
# speaker:CORVIN
Somebody's flask.
# speaker:TOMAS
Empty, obviously. This is a working quay.
# speaker:CORVIN
I'll take it.
# speaker:TOMAS
For courage?
# speaker:CORVIN
For evidence. Courage leaks.
-> END

=== old_quay_rope_cleat ===
# location:old_quay
# speaker:CORVIN
Sharp edge.
# speaker:TOMAS
You're not about to do something clever with your own knuckles.
# speaker:CORVIN
No.
# speaker:TOMAS
Corvin.
# speaker:CORVIN
I'm about to do something useful with my own knuckles. Different sin.
-> END

=== salt_market_arrival ===
# location:salt_market
~ reached_salt_market = true
# item:add:BorrowedBoots
# speaker:BOOT_SELLER
Vale's dead.
# speaker:CORVIN
Well. That's the sort of thing people say.
# journal:add:j_corvin_died_thursday
# confession:discover:cf_greed_boots
# speaker:CORVIN
Thursday.
# speaker:CORVIN
Six days.
-> END

=== salt_market_public_recognition ===
# location:salt_market
# speaker:BOOT_SELLER
Morning. Size?
# speaker:CORVIN
Eleven. And credit.
# speaker:BOOT_SELLER
Credit's for people I know.
# speaker:CORVIN
You know me. Vale. I did your brother's transfer papers.
# speaker:NARRATION
The seller looks up. Looks properly. His face does something complicated.
# speaker:BOOT_SELLER
...Vale.
# speaker:CORVIN
There we are.
# speaker:BOOT_SELLER
Vale's dead.
# speaker:CORVIN
Well. That's the sort of thing people say.
# speaker:BOOT_SELLER
No. No, they pulled you out Thursday. I saw it. They laid you on the ice at the fish hall.
# speaker:CORVIN
Right, and I appreciate the attendance.
# speaker:BOOT_SELLER
I brought my daughter.
# speaker:CORVIN
That seems like a choice.
# speaker:NARRATION
He backs into his own table. Boots go everywhere.
# speaker:WOMAN
Oh God.
# speaker:CORVIN
Look. Nobody needs to-
# speaker:WOMAN
He's walking.
# speaker:NARRATION
The street stops.
# speaker:CORVIN
Thursday.
# speaker:NARRATION
Arithmetic on his fingers. It doesn't take long.
# speaker:CORVIN
Six days.
# speaker:CORVIN
Six days to find out who held me under.
# speaker:NARRATION
He picks up boots off the ground, unhurried, and walks out through a crowd that parts without anyone deciding to.
-> END

=== salt_market_boot_stall_after ===
# location:salt_market
# speaker:CORVIN
He's rearranging boots that don't need it.
# speaker:CORVIN
He'll be at that all day.
# speaker:BOOT_SELLER
I've got nothing for you.
# speaker:CORVIN
I know.
# speaker:BOOT_SELLER
She's alright, by the way. The girl.
# speaker:BOOT_SELLER
She thought it was interesting.
# speaker:CORVIN
Kids are better at this than we are.
# speaker:BOOT_SELLER
Don't make it sound kind.
# speaker:CORVIN
I won't.
-> END

=== salt_market_fishmonger ===
# location:salt_market
# speaker:CORVIN
Two sets of scales under that table.
# speaker:CORVIN
The honest ones are on the wall where you can see them.
# speaker:MONGER
You're dripping on the cod.
# speaker:CORVIN
It's a marinade.
# speaker:MONGER
That's not a selling point.
# speaker:CORVIN
Neither is the cod.
# speaker:MONGER
It was selling fine before you came back from the harbor.
# speaker:CORVIN
Most things were.
-> END

=== salt_market_lamp ===
# location:salt_market
# speaker:CORVIN
Whale oil.
# speaker:CORVIN
Warm light.
# speaker:CORVIN
Everything warm on this island is something dead being useful.
# speaker:CORVIN
Nothing.
# speaker:CORVIN
Not cold, not warm.
# speaker:CORVIN
Just reported.
-> END

=== registrar_duel_start ===
# location:harbor_registry
# speaker:REGISTRAR
You're the Vale boy.
# speaker:CORVIN
I'm thirty-six.
# speaker:REGISTRAR
You're three days old.
# speaker:REGISTRAR
Struck you out myself on Friday. Nice clean hand.
# speaker:CORVIN
It wasn't, actually.
# speaker:REGISTRAR
No. It wasn't.
# speaker:REGISTRAR
What do you want?
# speaker:CORVIN
My name back on the roll.
# speaker:REGISTRAR
Can't. You're not a person.
# speaker:REGISTRAR
The roll's for people, and a person has a pulse, and you have a coat and an attitude.
# speaker:CORVIN
Then let me stand here and embarrass us both.
# speaker:REGISTRAR
You want to duel me. For your name.
# speaker:CORVIN
Church rule. You can't refuse a returned man a duel.
# speaker:REGISTRAR
No, I can't.
# speaker:REGISTRAR
I've been doing this forty years, Mr. Vale. Do you know what that means?
# speaker:CORVIN
You're very good with ink?
# speaker:REGISTRAR
That I'm bored of it.
# speaker:REGISTRAR
Come on, then. The hall's cold and you won't notice, which is the only advantage you've got.
-> END

=== registrar_duel_win ===
# location:harbor_registry
# speaker:REGISTRAR
...Say the rest.
# speaker:CORVIN
I read it twice. I wanted to be sure of the number before I took the money.
# speaker:REGISTRAR
There. Vale, Corvin. Back in.
# speaker:REGISTRAR
You said the Kestrel out loud, in a hall, in front of forty people and a man selling pastries.
# speaker:REGISTRAR
There's nothing I could add.
# speaker:CORVIN
That sounds almost kind.
# speaker:REGISTRAR
No.
# speaker:REGISTRAR
And Mr. Vale? What you told me in there, I'll be selling by supper.
# speaker:REGISTRAR
That's the job. You knew it was the job when you walked in.
# speaker:CORVIN
Yes.
# speaker:REGISTRAR
Good. I prefer a man to recognize the knife before he rents it.
-> END

=== registrar_duel_loss ===
# location:harbor_registry
# speaker:REGISTRAR
Enough. The salt has more patience than I do.
# speaker:CORVIN
That's not the first time I've lost to paperwork.
-> END

=== registry_ledgers ===
# location:harbor_registry
# speaker:CORVIN
Four thousand names.
# speaker:CORVIN
Every one struck out by the same hand.
# speaker:REGISTRAR
Not the same hand. The same office.
# speaker:CORVIN
That's worse.
# speaker:REGISTRAR
That's why offices survive.
# speaker:CORVIN
People don't. But the ledgers look well.
# speaker:REGISTRAR
Paper has the decency not to beg.
-> END

=== registry_roll_book ===
# location:harbor_registry
# speaker:CORVIN
There. VALE, CORVIN.
# speaker:NARRATION
The line through it has bitten into the paper, not just crossed it.
# speaker:CORVIN
And a line through it. Not even a neat one.
# speaker:REGISTRAR
I was busy.
# speaker:CORVIN
I've been dead three days and somehow this is the wound that stings.
# speaker:REGISTRAR
Names are vanity until someone takes yours away.
# speaker:CORVIN
That's almost comforting.
# speaker:REGISTRAR
Then I phrased it poorly.
-> END

=== registry_lamp_smoked ===
# location:harbor_registry
# speaker:CORVIN
Terribly sorry.
# speaker:REGISTRAR
You drowned on my rug and now you're drowning my lamp.
# speaker:CORVIN
I contain multitudes. Mostly water.
# speaker:REGISTRAR
Don't move.
# speaker:CORVIN
Wouldn't dream of it.
# speaker:REGISTRAR
You dream professionally, Mr. Vale. Stay professionally still.
-> END

=== registry_ledger_blocked ===
# location:harbor_registry
# speaker:CORVIN
The Kestrel ledger is behind her desk.
# speaker:REGISTRAR
And I am in front of my desk.
# speaker:CORVIN
You're very good at furniture.
-> END

=== registry_ledger_page ===
# location:harbor_registry
# speaker:CORVIN
Kestrel. Hold listed as freight.
# speaker:CORVIN
Eleven names buried in a number column.
# speaker:NARRATION
The Registrar sees the torn corner. She does not rise.
# speaker:REGISTRAR
Put that back.
# speaker:CORVIN
Can't. I'm making it worse honestly.
# speaker:REGISTRAR
Good. Then say it properly when the room is listening.
# speaker:NARRATION
She files the moment somewhere quiet and reachable.
# speaker:CORVIN
You knew it was there.
# speaker:REGISTRAR
I know where every body is, Mr. Vale. The living just file them creatively.
-> END

=== registry_registrar_needs_manifest ===
# location:harbor_registry
# speaker:REGISTRAR
You can duel me when you know what you're here to say.
# speaker:CORVIN
I know my name.
# speaker:REGISTRAR
So does the book. The book crossed it out anyway.
-> END

=== salt_market_confession_queue ===
# location:salt_market
# speaker:WOMAN
He laughed at the funeral.
# speaker:NARRATION
Eleven people wait to ask a dead man a question. Eight of them look like money.
# speaker:NARRATION
A boy in a collar takes shillings under a sign that promises truth by the minute.
# speaker:MAN
People laugh when they're nervous.
# speaker:WOMAN
He wasn't nervous. He asked if the coffin came with a receipt.
# speaker:CORVIN
That's not even a good line.
# speaker:WOMAN
It was at the time.
-> END

=== salt_market_church_sign_wet ===
# location:salt_market
# speaker:CORVIN
Petty.
# speaker:CORVIN
Necessary.
# speaker:CORVIN
Both.
# speaker:WOMAN
Is he allowed to do that?
# speaker:MAN
He's dead. I don't know who fines him.
-> END

=== fish_hall_ice_table ===
# location:fish_hall
# speaker:CORVIN
That's the table.
# speaker:CORVIN
There's still a shape in the ice.
# speaker:CORVIN
Smaller than I'd have guessed.
# speaker:CORVIN
The fish got burlap. I got a sheet.
# speaker:CORVIN
Very formal. Very dead.
# speaker:CORVIN
Fits.
# speaker:CORVIN
Well. That answers a question I didn't ask.
# speaker:CORVIN
I always thought I'd take up more room.
-> END

=== fish_hall_coroner_tag ===
# location:fish_hall
# speaker:CORVIN
VALE, C. THURS. RECOVERED, QUAY. NO MARKS.
# speaker:CORVIN
They got the day right.
# speaker:CORVIN
They got the place wrong, unless the quay learned to hold a man's head under.
# speaker:CORVIN
No marks.
# speaker:CORVIN
I want that on record too.
# speaker:CORVIN
Nobody hit me. Nobody had to.
# speaker:CORVIN
That's the part nobody writes down.
-> END

=== fish_hall_visitor_book ===
# location:fish_hall
# speaker:CORVIN
Forty-one names.
# speaker:CORVIN
People came through to look at me and signed for the privilege.
# speaker:CORVIN
Good turnout. Terrible host.
# speaker:CORVIN
Two clients, three creditors, and a woman who once told me I had merciful eyes.
# speaker:CORVIN
I made a note to correct her, which is apparently my idea of mercy.
# speaker:CORVIN
Sabine's not in it.
# speaker:CORVIN
She wouldn't sign a thing like that.
# speaker:CORVIN
She'd just come.
-> END

=== fish_hall_drain ===
# location:fish_hall
# speaker:CORVIN
It all goes back to the harbor eventually.
# speaker:CORVIN
Ice water. Fish blood. Whatever was left of me.
# speaker:CORVIN
Efficient island.
# speaker:CORVIN
No romance about it at all.
# speaker:CORVIN
Just gravity, brine, and somewhere lower to be.
-> END

=== chandler_wares ===
# location:bone_chandler
# speaker:CORVIN
Buttons. Needles. A chess set.
# speaker:CORVIN
All of it was somebody.
# speaker:CHANDLER
Still is, if you ask the right buyer.
# speaker:CORVIN
I'd rather not handle the neighbours.
-> END

=== chandler_chess_set ===
# location:bone_chandler
# speaker:CORVIN
White pieces are older stock.
# speaker:CORVIN
They go pale after twenty years.
# speaker:CORVIN
The black ones are recent.
# speaker:CHANDLER
People prefer a matched set until they learn what matching costs.
# speaker:CORVIN
I have rarely liked a sentence less.
-> END

=== chandler_needs_salt ===
# location:bone_chandler
# speaker:CORVIN
Prosper's watch.
# speaker:CORVIN
Under glass, chain worn through on the left.
# speaker:CHANDLER
Right-handed and anxious. You do look at things.
# speaker:CORVIN
I need it.
# speaker:CHANDLER
Not for sale, I'm afraid.
# speaker:CORVIN
Everything's for sale. That's why you put it behind glass.
# speaker:CHANDLER
Fresh salt from a walking returned man. Bring me that and we'll discuss glass.
# speaker:CORVIN
And until then?
# speaker:CHANDLER
Until then the glass and I are both watching you.
-> END

=== chandler_watch_trade ===
# location:bone_chandler
# speaker:CHANDLER
Oh, you're new.
# speaker:CORVIN
I'm not for sale.
# speaker:CHANDLER
Everyone says that, and then day nine comes and someone ties a rope to them.
# speaker:CHANDLER
The rope wears a groove, and the groove is where I start.
# speaker:CORVIN
The watch. Under the glass.
# speaker:CHANDLER
Prosper's. Collateral. Man owes me eleven shillings and the rot's taken his memory of owing it.
# speaker:CORVIN
I'll trade.
# speaker:CHANDLER
With what? You've got a wet coat and somebody else's boots.
# speaker:CORVIN
Fresh enough?
# speaker:CHANDLER
...That's fresh.
# speaker:CORVIN
Off the knuckle. This morning.
# speaker:CHANDLER
Off a walking man.
# speaker:CHANDLER
Nobody brings me that. They bring me their uncle after he's set. They bring me buttons. Nobody brings me this.
# speaker:CORVIN
I didn't feel it.
# speaker:CHANDLER
No. That's rather the point, isn't it.
# speaker:CHANDLER
Take the watch. Stop touching my counter.
# speaker:CHANDLER
Come back when there's more.
# speaker:CHANDLER
I'd rather you didn't. But come back.
-> END

=== prosper_before_watch ===
# location:almshouse
# speaker:PROSPER
Morning! Have we met?
# speaker:CORVIN
Several times.
# speaker:PROSPER
Marvellous. How did it go?
# speaker:CORVIN
Badly, mostly. I owed you money.
# speaker:PROSPER
Did you pay it?
# speaker:CORVIN
No.
# speaker:PROSPER
Well, there we are.
# speaker:PROSPER
That makes us almost acquainted. Sit down, you look terrible.
# speaker:CORVIN
You don't remember me.
# speaker:PROSPER
No, but I can tell I was probably right to be fond of you.
# speaker:CORVIN
That's generous.
# speaker:PROSPER
It's cheap. I get to spend it fresh every morning.
-> END

=== prosper_forgiveness ===
# location:almshouse
# speaker:CORVIN
I've got something of yours.
# speaker:PROSPER
...Oh.
# speaker:CORVIN
You know it?
# speaker:PROSPER
No. I don't know it at all. But my hand does.
# speaker:PROSPER
Look. I've done that ten thousand times and I couldn't tell you once.
# speaker:CORVIN
It was at the Chandler's. Collateral.
# speaker:PROSPER
And you got it back for me.
# speaker:CORVIN
Yes.
# speaker:PROSPER
Why?
# speaker:CORVIN
Because I need a favour and this was the shortest route to it.
# speaker:PROSPER
Oh, that's lovely. Nobody's been honest with me in months.
# speaker:PROSPER
They all think I won't notice, and they're right, but I notice that.
# speaker:PROSPER
Go on. What's the favour?
# speaker:CORVIN
I need a debt forgiven. In writing. Signed.
# speaker:PROSPER
Is that all?
# speaker:PROSPER
Whose?
# speaker:CORVIN
...
# speaker:CORVIN
Mine. Eleven shillings, sixteen years, and I've been avoiding you in the street since before you got sick.
# speaker:PROSPER
...Corvin.
# speaker:CORVIN
Yes.
# speaker:PROSPER
I'm sorry — who?
# speaker:PROSPER
There. Whoever you are, you don't owe me anything. We'll pretend I didn't hear the rest.
-> END

=== almshouse_cots ===
# location:almshouse
# speaker:CORVIN
Twelve cots.
# speaker:CORVIN
Nine occupied.
# speaker:CORVIN
Three of them are past talking and nobody's moved them yet.
# speaker:CORVIN
The sheets are folded back from their feet so the salt doesn't glue them down.
# speaker:PROSPER
That's kind. Some people move you before you're done being somewhere.
-> END

=== almshouse_window ===
# location:almshouse
# speaker:CORVIN
The window faces the water.
# speaker:CORVIN
That seems cruel until you realize nobody here remembers what it means.
# speaker:CORVIN
Every bed gets a stripe of harbor light. Equal shares of a bad idea.
# speaker:PROSPER
Pretty, though.
# speaker:CORVIN
Yes. That's usually how cruelty gets inside.
-> END

=== juno_needs_rate_card ===
# location:grey_float
# speaker:JUNO
That pump is the only reason this barge is a barge and not a wreck with opinions.
# speaker:CORVIN
I need something in my chest that ticks for an hour.
# speaker:JUNO
Then bring me something worth breaking a pump over.
-> END

=== float_juno_table ===
# location:grey_float
# speaker:JUNO
You're dripping on my deck, and my deck is already wet, so I want you to understand that I noticed anyway.
# speaker:CORVIN
Juno.
# speaker:JUNO
Corvin Vale. Well. You look exactly the same, which is the rudest thing you've ever done to me.
# speaker:CORVIN
People keep screaming.
# speaker:JUNO
People are tourists. Sit. Don't sit there, that's Adela's. Sit there.
# speaker:JUNO
Everybody comes here to feel something, sugar. You're just the first one honest about not being able to.
# speaker:CORVIN
I need your pump governor.
# speaker:JUNO
No.
# speaker:CORVIN
Juno.
# speaker:JUNO
That pump is the only reason this barge is a barge and not a wreck with opinions.
# speaker:CORVIN
I need something in my chest that ticks for an hour.
# speaker:JUNO
Oh, that's good. What's it worth?
# speaker:CORVIN
What do you want?
# speaker:JUNO
The Church's rate card. By question type. With the margins.
-> END

=== juno_regulator_trade ===
# location:grey_float
# speaker:JUNO
Thirty years I ran that trade. Thirty.
# speaker:JUNO
And they came in with a building and a tariff, and now there's a queue in the market and a boy in a collar taking a shilling a question.
# speaker:CORVIN
Sixteen percent on grief. It's in there.
# speaker:JUNO
Sixteen.
# speaker:CORVIN
I brought the Church rate card.
# speaker:NARRATION
Juno does not touch it. She looks at it a long time.
# speaker:JUNO
Governor's on the pump. Take it, mind the spring. And Corvin — the pool's free.
# speaker:CORVIN
How did you—
# speaker:JUNO
Sugar, I've been putting warmth into cold men for forty years. It's the whole business.
-> END

=== juno_pool_before_permission ===
# location:grey_float
# speaker:CORVIN
The pool's warm.
# speaker:JUNO
The pool's mine.
# speaker:CORVIN
That's a distinction with steam on it.
# speaker:JUNO
Bring me the Church's rate card, sugar. Then we'll discuss your temperature.
-> END

=== juno_hot_pool_soak ===
# location:grey_float
# speaker:JUNO
Ten minutes.
# speaker:NARRATION
The amber screen slides shut. Steam turns the room into voices and shoulders.
# speaker:CORVIN
I need an hour.
# speaker:JUNO
You get ten minutes of heat and fifty minutes of lying posture.
# speaker:CORVIN
I can't lie.
# speaker:JUNO
Then stand very confidently.
# speaker:NARRATION
His skin takes the warmth before he does. That feels worse than cold.
# speaker:CORVIN
Nothing.
# speaker:JUNO
Warmth or feeling?
# speaker:CORVIN
Yes.
# speaker:JUNO
Then move while your skin still remembers.
-> END

=== juno_warmth_expired ===
# location:grey_float
# speaker:JUNO
You wandered off, didn't you.
# speaker:CORVIN
I took a scenic route through civic incompetence.
# speaker:JUNO
You had one job and it was to walk in a straight line.
# speaker:CORVIN
In fairness, I was briefly alive enough to make bad choices.
# speaker:JUNO
Back in the pool, sugar. Try not to make tourism out of it.
-> END

=== float_staff_corner ===
# location:grey_float
# speaker:ADELA
He said sorry and left two buttons.
# speaker:MARIN
Two good buttons?
# speaker:ADELA
One good button and one apology.
# speaker:MARIN
So no.
# speaker:CORVIN
That's a harsh exchange rate.
# speaker:ADELA
Sorry is the cheapest word men carry.
# speaker:MARIN
Men come here to feel forgiven and leave us the small change.
# speaker:ADELA
Forgiven costs extra.
# speaker:CORVIN
Does it work?
# speaker:ADELA
For them? Usually.
# speaker:MARIN
For us? Never before breakfast.
# speaker:CORVIN
I'll stop apologizing, then.
# speaker:ADELA
Don't flatter yourself. We charge for silence too.
# confession:discover:cf_lust_float
-> END

=== float_steam_screen ===
# location:grey_float
# speaker:CORVIN
Steam, backlight, silhouettes.
# speaker:CORVIN
The Float sells privacy by making everybody an outline.
# speaker:JUNO
Eyes front, Corvin.
# speaker:CORVIN
My eyes are front.
# speaker:JUNO
Your imagination isn't.
# speaker:CORVIN
That survived the drowning. Very inconvenient.
# speaker:JUNO
So did manners, if you ever owned any.
# speaker:CORVIN
It's only heat and shadow.
# speaker:JUNO
That's what privacy is, sugar. Heat, shadow, and people agreeing not to name what they saw.
# speaker:CORVIN
I can't feel the heat.
# speaker:JUNO
Then respect the shadow.
-> END

=== heartbeat_check_fail ===
# location:harbormaster_office
# speaker:CLERK
You're cold.
# speaker:CORVIN
It's a cold morning.
# speaker:CLERK
It's August. Out.
# speaker:CORVIN
I have circulation issues.
# speaker:CLERK
You have absence issues. Out twice.
-> END

=== harbormaster_checklist_desk ===
# location:harbormaster_office
# speaker:CORVIN
Three boxes beside my name.
# speaker:CORVIN
Name. Debt. Heartbeat.
# speaker:CLERK
All three. In ink. No pencil for the dead.
# speaker:CORVIN
That's the warmest thing anyone's said to me in an office.
# speaker:CLERK
I can scratch it out if you prefer.
-> END

=== harbormaster_sabine_door ===
# location:harbormaster_office
# speaker:CORVIN
SABINE CROIX, HARBORMASTER.
# speaker:NARRATION
Black letters on frosted glass. Her office is one room away and still somehow uphill.
# speaker:CORVIN
I've crossed oceans with less weather in them.
# speaker:CLERK
Door opens when the list says it opens.
-> END

=== heartbeat_check_pass ===
# location:harbormaster_office
# speaker:CLERK
Name.
# speaker:CORVIN
Vale.
# speaker:CLERK
You're on. Right hand.
# speaker:CORVIN
Is this medical or civic?
# speaker:CLERK
On Mordida, those are the same stamp.
# speaker:CLERK
Hold still.
# speaker:NARRATION
He takes Corvin's wrist and waits.
# speaker:CORVIN
I'm a monument to stillness.
# speaker:NARRATION
The regulator ticks under the coat, four inches off and slightly too regular.
# speaker:CLERK
Your pulse is four inches left of your wrist.
# speaker:CORVIN
Old injury.
# speaker:CLERK
That's fast.
# speaker:CORVIN
I'm nervous. She has that effect.
# speaker:NARRATION
The clerk feels Corvin's hand.
# speaker:CLERK
Your hand's warm.
# speaker:CORVIN
I had an emotional morning.
# speaker:CLERK
Fine. Go through.
-> END

=== teodor_rate_card_booth ===
# location:church_of_the_drowned
# speaker:TEODOR
We're closed. We're... I'm sorry, we're closed.
# speaker:CORVIN
Your queue disagrees.
# speaker:TEODOR
My queue is a misunderstanding.
# speaker:CORVIN
You sold slots you can't fill.
# speaker:TEODOR
That is a very serious accusation and I would like to know who...
# speaker:CORVIN
Nobody. You've got eleven people out there and one returned on your books, and I passed him on the quay this morning and he's a bollard now.
# speaker:NARRATION
Teodor sits down on the step. Puts his head in his hands.
# speaker:TEODOR
He was fine on Tuesday.
# speaker:CORVIN
They're always fine on Tuesday.
# speaker:TEODOR
They'll take the stall off me.
# speaker:TEODOR
It's not even the money. My father got me this posting. He wrote letters.
# speaker:CORVIN
Brother. Look at me.
# speaker:TEODOR
Oh.
# speaker:CORVIN
Oh.
# speaker:TEODOR
You would sit? For me?
# speaker:CORVIN
For an hour. And in exchange you give me the rate card. What the Church charges, by question type, with the margins.
# speaker:TEODOR
That's... I could be defrocked for...
# speaker:CORVIN
Teodor.
# speaker:TEODOR
Yes. Right. Yes.
# speaker:WOMAN
Did my husband love me?
# speaker:CORVIN
He never told me.
# speaker:WOMAN
That's kinder than I paid for.
# speaker:CORVIN
Most things are.
# speaker:BOY
Is it true you can't lie?
# speaker:CORVIN
Yes.
# speaker:BOY
Say something you'd never say.
# speaker:CORVIN
I have spent twenty years making sentences where nobody did anything to anyone.
# speaker:BOY
Why did you tell me that?
# speaker:CORVIN
Because you asked and I'm made this way now.
# speaker:BOY
That's worse.
# speaker:CORVIN
Shilling, please.
# speaker:KANE
Comfortable in there?
# speaker:CORVIN
It's a box.
# speaker:KANE
It's a booth, Mr. Vale, and the difference is that a booth has a queue.
# speaker:KANE
I'll have my question now.
# speaker:CORVIN
You haven't paid.
# speaker:KANE
No. How many days have you got left?
# speaker:CORVIN
Six.
# speaker:KANE
Thank you. That's all I came for.
# speaker:KANE
I like to know when a man's going to be reasonable, and it's never on day six.
# speaker:NARRATION
He goes. The queue lets him through without being asked.
-> END

=== church_poor_box ===
# location:church_of_the_drowned
# speaker:CORVIN
Poor box.
# speaker:NARRATION
The lock sits crooked, scraped bright around the screws.
# speaker:CORVIN
Someone had the lock off and put it back badly.
# speaker:NARRATION
Coins remain in the bottom. The folded notes are gone.
# speaker:TEODOR
We had a locksmith.
# speaker:CORVIN
You had a thief with a screwdriver and confidence.
# speaker:TEODOR
Please don't say that near the vestry.
-> END

=== church_stall_sign ===
# location:church_of_the_drowned
# speaker:CORVIN
THE DROWNED CANNOT LIE. ONE SHILLING.
# speaker:NARRATION
The queue is eleven deep. Teodor is sweating through doctrine.
# speaker:CORVIN
That's not theology. That's inventory pressure.
# speaker:TEODOR
Please don't call it that where the queue can hear.
-> END

=== church_confession_booth ===
# location:church_of_the_drowned
# speaker:CORVIN
A green-lit box with a queue.
# speaker:CORVIN
The Church found a way to make truth billable by the minute.
# speaker:TEODOR
It's not a box. It's a booth.
# speaker:CORVIN
The difference being?
# speaker:TEODOR
Rates, mostly.
# speaker:CORVIN
That's doctrine I can believe in.
# speaker:TEODOR
Take this chit. If anyone asks, you were scheduled, expected, and absolutely not a miracle I found leaking on the floor.
# speaker:CORVIN
That's almost a lie.
# speaker:TEODOR
That's administration.
-> END

=== teodor_needs_chit ===
# location:church_of_the_drowned
# speaker:TEODOR
I can't put you in the stall without a chit.
# speaker:CORVIN
I am visibly dead and damp.
# speaker:TEODOR
Yes, but the Church prefers miracles in triplicate.
-> END

=== sabine_act_i_audience ===
# location:sabine_office
# speaker:SABINE
You're dripping on the Persian.
# speaker:CORVIN
It's brine. It's antiquing. You'll thank me in a decade.
# speaker:SABINE
You always did know how to make an entrance.
# speaker:CORVIN
I drowned, Sabine.
# speaker:SABINE
Yes. It was very dramatic. I cried for almost a full minute.
# speaker:CORVIN
A minute.
# speaker:SABINE
It was a busy week.
# speaker:NARRATION
She writes another line, sets down the pen, and looks at him for the first time.
# speaker:SABINE
You're on the roll again. I saw.
# speaker:CORVIN
I had to out-confess a seventy-year-old woman in front of a paying audience.
# speaker:SABINE
How was it?
# speaker:CORVIN
Humiliating and extremely well attended.
# speaker:SABINE
What did you give her?
# speaker:CORVIN
The Kestrel.
# speaker:SABINE
Out loud.
# speaker:CORVIN
Out loud, in a hall, to about forty people and a man selling pastries.
# speaker:SABINE
Corvin.
# speaker:CORVIN
It's fine. It's actually the only clever thing I've done since Tuesday. Nobody can hold it over me now.
# speaker:CORVIN
You can't blackmail a man with a thing he shouted.
# speaker:SABINE
That's not why you did it.
# speaker:CORVIN
No.
# speaker:SABINE
Why did you do it?
# speaker:CORVIN
Because I wanted one person on this island to know the worst of it and still be standing there afterwards.
# speaker:CORVIN
She was.
# speaker:CORVIN
She wrote my name back in. Didn't say anything about it.
# speaker:NARRATION
Water pools on Sabine's floor. She crosses through it like it isn't there.
# speaker:SABINE
Hold still.
# speaker:CORVIN
What?
# speaker:SABINE
Hold still.
# speaker:NARRATION
Two fingers to the inside of his wrist. Four seconds. Nothing. Her hand stays.
# speaker:CORVIN
That's not how you check.
# speaker:SABINE
I know how to check.
# speaker:CORVIN
There isn't anything there.
# speaker:SABINE
I noticed.
# speaker:CORVIN
Sabine.
# speaker:SABINE
Don't make me say a thing badly when I'm doing it correctly.
# speaker:SABINE
Get out of my office, Corvin.
# speaker:CORVIN
Right.
# speaker:SABINE
Six days.
# speaker:CORVIN
Five.
-> END
