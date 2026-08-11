$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$Value
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Value, $encoding)
}

function Format-GodotStringArray {
    param([string[]]$Items)
    if (-not $Items -or $Items.Count -eq 0) {
        return "Array[String]([])"
    }
    $quoted = $Items | ForEach-Object { '"' + ($_ -replace '"', '\"') + '"' }
    return "Array[String]([" + ($quoted -join ", ") + "])"
}

$rooms = @(
    @{ Id="old_quay"; Script="OldQuay"; Code="R02"; Title="The Old Quay"; Notes="Rotting boardwalk, bollards, rope cleat, flask. Tomas unlocks the Act I map."; Exits=@(@{ Name="ToMudflats"; Target="Mudflats"; Label="Mudflats"; X=180; Y=760 }, @{ Name="ToSaltMarket"; Target="SaltMarket"; Label="Salt Market"; X=1700; Y=700 }); Interactions=@(
        @{ Name="Tomas"; Key="tomas"; Label="Bollard Tomas"; X=470; Y=720; Look="Tomas is the fourth bollard, and the only one with opinions still above water."; Use="Corvin refuses to untie anything from Tomas without a better understanding of maritime law."; Talk="Tomas gives the useful version: warmth, pulse, Prosper, Registry. It is almost kind."; Walk="Corvin crouches to eye level with a mooring post and somehow comes out less dignified."; FlagsSet=@("FL_tomas_topics_seen"); ConfessionsDiscover=@("cf_pride_list","cf_cow_leftroom","cf_greed_widows"); InkKnot="old_quay_tomas_topics"; AlternateRequiresFlags=@("FL_bollard_petra_seen","FL_bollard_ledger_seen","FL_bollard_bride_seen"); AlternateMessage="Tomas notices Corvin has made the whole silent row personal. Mordida does that to a man if he lets it."; AlternateFlagsSet=@("FL_bollard_row_reported"); AlternateInkKnot="old_quay_bollards_all_seen" },
        @{ Name="BollardPetra"; Key="bollard_petra"; Label="Bollard Petra"; X=690; Y=700; Look="Petra, if Tomas is right. Salt has sealed her mouth in a line that used to sing."; Use="Corvin keeps his hands off the salt. There are boundaries even here."; Talk="Corvin says Petra's name. The harbor answers for her, badly."; Walk="Corvin stands by the end bollard and lets the rope creak do the talking."; FlagsSet=@("FL_bollard_petra_seen"); InkKnot="old_quay_bollard_petra" },
        @{ Name="BollardLedger"; Key="bollard_ledger"; Label="Ledger bollard"; X=870; Y=705; Look="This one calcified with a rope groove where a collar should have been."; Use="Corvin has no business testing whether a dead neck still remembers pressure."; Talk="Corvin tries hello. Nothing comes back but gulls and bad timing."; Walk="Corvin gives the mooring rope a wide berth. It has practice making people useful."; FlagsSet=@("FL_bollard_ledger_seen"); InkKnot="old_quay_bollard_ledger" },
        @{ Name="BollardBride"; Key="bollard_bride"; Label="Bride bollard"; X=1050; Y=715; Look="A ring has gone white on one swollen finger. Someone tied boats to a marriage."; Use="Corvin decides not to pry at the ring. That might be growth."; Talk="Corvin apologizes to the bollard and immediately dislikes himself for choosing the easy audience."; Walk="Corvin stands where the quay turns people into hardware and calls it infrastructure."; FlagsSet=@("FL_bollard_bride_seen"); InkKnot="old_quay_bollard_bride" },
        @{ Name="SilentBollards"; Key="silent_bollards"; Label="Silent bollards"; X=910; Y=710; Look="Grey. Person-shaped if you're not careful about it."; Use="Corvin decides not to test whether they still bruise."; Talk="Corvin talks to the silent bollards. Tomas tells him they are past wanting to answer."; Walk="Corvin stands among the town's future hardware and counts too many faces."; FlagsSet=@("FL_silent_bollards_seen"); InkKnot="old_quay_silent_bollards" },
        @{ Name="Flask"; Key="flask"; Label="Empty flask"; X=1180; Y=760; Look="Somebody's flask. Empty, obviously. This is a working quay."; Use="Corvin takes the empty flask. It is evidence until proven otherwise."; Talk="Corvin asks the flask for courage. The flask has been out of courage for hours."; Walk="Corvin steps around the flask, then thinks better of leaving useful trash behind."; ItemsAdd=@("IT_flask"); FlagsSet=@("FL_flask_taken"); InkKnot="old_quay_flask" },
        @{ Name="RopeCleat"; Key="rope_cleat"; Label="Rope cleat"; X=720; Y=800; Look="A rope cleat crusted with salt from men who kept walking."; Use="Corvin scrapes fresh salt from his own knuckles against the cleat."; Talk="Corvin asks the cleat for mercy. It remains professionally maritime."; Walk="Corvin stands close enough to regret having feet."; Wet="Corvin presses his wet knuckles to the cleat and scrapes loose fresh salt."; ItemsAdd=@("IT_knuckle_salt"); FlagsSet=@("FL_salt_scraped"); WetItemsAdd=@("IT_knuckle_salt"); WetFlagsSet=@("FL_salt_scraped"); InkKnot="old_quay_rope_cleat"; WetInkKnot="old_quay_rope_cleat" }
    ) },
    @{ Id="salt_market"; Script="SaltMarket"; Code="R03"; Title="Salt Market"; Notes="First public scream, boots, panic, market hub."; Exits=@(@{ Name="ToOldQuay"; Target="OldQuay"; Label="Old Quay"; X=180; Y=740 }, @{ Name="ToRegistry"; Target="HarborRegistry"; Label="Registry"; X=520; Y=650 }, @{ Name="ToChandler"; Target="BoneChandler"; Label="Bone Chandler"; X=820; Y=655 }, @{ Name="ToAlmshouse"; Target="Almshouse"; Label="Almshouse"; X=1120; Y=655 }, @{ Name="ToFishHall"; Target="FishHall"; Label="Fish Hall"; X=1390; Y=655 }, @{ Name="ToChurch"; Target="ChurchOfTheDrowned"; Label="Church"; X=1660; Y=650 }); Interactions=@(
        @{ Name="MarketCrowd"; Key="market_crowd"; Label="Crowd"; X=960; Y=760; Look="Everyone has noticed Corvin is dead except the people pretending not to."; Use="The boot seller says Vale is dead. The queue screams. Corvin counts six days and takes the fallen boots."; Talk="The market screams once, then starts pricing him."; Walk="Corvin gives the crowd room. They take several more."; ItemsAdd=@("BorrowedBoots"); FlagsSet=@("FL_market_recognized","FL_market_day_hint"); ConfessionsDiscover=@("cf_pride_voice"); InkKnot="salt_market_public_recognition" },
        @{ Name="BootStall"; Key="boot_stall"; Label="Boot stall"; X=300; Y=720; Look="He's rearranging boots that don't need it. He'll be at that all day."; Use="Corvin leaves the table standing, which is more than the table did for itself."; Talk="The seller will not look at Corvin, except when he cannot help it."; Walk="Corvin steps around the fallen boots. Ownership is already complicated enough."; Wet="The stall has suffered enough water for one morning."; RequiresItems=@("BorrowedBoots"); RequiresFlags=@("FL_market_recognized"); FlagsSet=@("FL_boot_stall_after_seen"); Blocked="The boot stall is only a stall until the market realizes Corvin is dead."; InkKnot="salt_market_boot_stall_after" },
        @{ Name="Fishmonger"; Key="fishmonger"; Label="Fishmonger"; X=520; Y=720; Look="Two sets of scales under that table. The honest ones are on the wall where you can see them."; Use="Corvin is not buying fish. He can't taste anything and it seems like a waste."; Talk="The fishmonger complains about Corvin dripping on the cod. Corvin calls it a marinade."; Walk="Corvin moves past the scales before arithmetic gets involved."; FlagsSet=@("FL_fishmonger_seen"); ConfessionsDiscover=@("cf_greed_scales","cf_cow_drink"); InkKnot="salt_market_fishmonger" },
        @{ Name="ConfessionQueue"; Key="confession_queue"; Label="Confession queue"; X=1180; Y=720; Look="Eleven people waiting to ask a dead man a question. Eight of them are here about money."; Use="Corvin is on the wrong side of that counter, which is new and not an improvement."; Talk="The queue trades grief, interest rates, and one funeral story nobody should be enjoying."; Walk="Corvin stands close enough to hear what people call closure when it costs a shilling."; ConfessionsDiscover=@("cf_cruel_funeral","cf_pride_voice"); InkKnot="salt_market_confession_queue" },
        @{ Name="ChurchSign"; Key="church_sign"; Label="Church sign"; X=1380; Y=540; Look="THE DROWNED CANNOT LIE - ONE SHILLING. They got a signwriter in. It's good work."; Use="Corvin considers using Church doctrine, but the warranty expired at drowning."; Talk="Corvin argues with the sign. The sign has better funding."; Walk="Corvin stands under the Church tariff and tries not to become a product."; Wet="Corvin lets his sleeve drip over the tariff. The ink runs just enough to make doctrine expensive to read."; WetFlagsSet=@("FL_church_sign_wet"); WetInkKnot="salt_market_church_sign_wet" },
        @{ Name="WhaleOilLamp"; Key="whale_oil_lamp"; Label="Whale-oil lamp"; X=1520; Y=620; Look="Whale oil. Warm light. Everything warm on this island is something dead being useful."; Use="Corvin holds his hands near the lamp. Nothing. Not cold, not warm. Just reported."; Talk="Corvin asks the lamp if usefulness counts as a second life. It keeps burning."; Walk="Corvin stands in amber light and learns it has no jurisdiction over him."; FlagsSet=@("FL_market_lamp_checked"); InkKnot="salt_market_lamp" }
    ) },
    @{ Id="harbor_registry"; Script="HarborRegistry"; Code="R05"; Title="Harbor Registry"; Notes="Rite 2: Name Restored. Registrar duel and ledger page."; Exits=@(@{ Name="ToSaltMarket"; Target="SaltMarket"; Label="Salt Market"; X=180; Y=740 }); Interactions=@(
        @{ Name="Ledgers"; Key="ledgers"; Label="Ledgers"; X=420; Y=660; Look="Four thousand names in those books and every one of them struck out by the same hand."; Use="Corvin reads the wall of absences. The office has been eating people longer than he has."; Talk="Corvin talks to the ledgers. They have heard worse and filed it."; Walk="Corvin stands under four thousand official absences."; FlagsSet=@("FL_registry_ledgers_seen"); InkKnot="registry_ledgers" },
        @{ Name="RollBook"; Key="roll_book"; Label="Open roll"; X=640; Y=700; Look="There. VALE, CORVIN - and a line through it. Not even a neat line."; Use="Corvin reads the scratch again. The insult is administrative and personal."; Talk="Corvin asks the roll to improve its handwriting. It declines."; Walk="Corvin stands over his own absence."; InkKnot="registry_roll_book" },
        @{ Name="DeskLamp"; Key="desk_lamp"; Label="Desk lamp"; X=890; Y=650; Look="Oil lamp. Low wick. She likes the dark; it makes people talk faster."; Use="Corvin needs a distraction, not a lamp-owning hobby."; Talk="Corvin apologizes to the lamp. The lamp smokes like it accepts."; Walk="Corvin steps close enough to drip with intent."; Wet="Corvin shakes his sleeve over the lamp. It gutters, smokes, and the Registrar rises to tend it."; WetFlagsSet=@("FL_registry_lamp_smoked"); WetInkKnot="registry_lamp_smoked" },
        @{ Name="KestrelLedger"; Key="kestrel_ledger"; Label="Kestrel ledger"; X=1220; Y=610; Look="High shelf, black binding, one torn corner. The kind of book that survives by ruining everyone else."; Use="Corvin tears out the Kestrel page. The Registrar knows. She saves it for the duel."; Talk="The ledger says nothing. That's how ledgers get away with murder."; Walk="Corvin crosses behind the desk while the lamp performs innocence."; RequiresFlags=@("FL_registry_lamp_smoked"); Blocked="The Kestrel ledger is behind the Registrar's desk. She has not moved."; ItemsAdd=@("IT_ledger_page"); FlagsSet=@("FL_manifest_known"); ConfessionsDiscover=@("cf_bt_manifest"); InkKnot="registry_ledger_page"; BlockedInkKnot="registry_ledger_blocked" },
        @{ Name="Registrar"; Key="registrar"; Label="Registrar"; X=980; Y=690; Look="The Registrar has struck four thousand names off the roll and remembers every one."; Use="The Registrar opens the book. The Litany answers or it doesn't."; Talk="The Registrar opens the book. The Litany answers or it doesn't."; Walk="Corvin approaches the desk. The desk considers legal action."; RequiresFlags=@("FL_manifest_known"); Blocked="The Registrar will duel him, but not while the Kestrel page is still safely above her desk."; ItemsAdd=@("IT_name_writ"); FlagsSet=@("FL_rite_name","FL_registrar_sold_manifest"); DuelOpponent="registrar"; DuelPool=@("cf_greed_boots","cf_pride_list","cf_lust_float","cf_lust_schedule","cf_pride_grammar","cf_pride_counselor","cf_cruel_soupline","cf_cruel_sentences","cf_cow_leftroom","cf_cow_bigger","cf_cow_passive"); BlockedInkKnot="registry_registrar_needs_manifest" }
    ) },
    @{ Id="bone_chandler"; Script="BoneChandler"; Code="R06"; Title="The Bone Chandler"; Notes="Trade salt crystal for Prosper watch."; Exits=@(@{ Name="ToSaltMarket"; Target="SaltMarket"; Label="Salt Market"; X=180; Y=740 }, @{ Name="ToAlmshouse"; Target="Almshouse"; Label="Almshouse"; X=1700; Y=730 }); Interactions=@(
        @{ Name="Wares"; Key="wares"; Label="Wares"; X=560; Y=700; Look="Buttons. Needles. A chess set. All of it was somebody."; Use="Corvin would rather not handle the neighbours."; Talk="Corvin almost says something to the shelves. No. Not today."; Walk="Corvin stands where craftsmanship becomes a legal problem."; FlagsSet=@("FL_chandler_wares_seen"); InkKnot="chandler_wares" },
        @{ Name="ChessSet"; Key="chess_set"; Label="Chess set"; X=790; Y=680; Look="White pieces are older stock. The black ones are recent."; Use="Corvin leaves the kings alone. They have enough dead men in politics."; Talk="Corvin asks the knight if it knew it would end up moving like that. The knight keeps its counsel."; Walk="Corvin gives the board enough distance to stay metaphorical."; FlagsSet=@("FL_chandler_chess_seen"); InkKnot="chandler_chess_set" },
        @{ Name="ProsperWatch"; Key="prosper_watch"; Label="Prosper's watch"; X=1010; Y=700; Look="Prosper's pocket watch hangs behind the counter as collateral."; Use="The Chandler accepts fresh salt from a walking returned man and hands over the watch."; Talk="The watch ticks with the confidence of something nobody drowned."; Walk="Corvin leans over the counter. The Chandler moves the expensive bones."; RequiresItems=@("IT_knuckle_salt"); Blocked="The Chandler wants fresh salt from a returned man. Corvin has not scraped any loose yet."; ItemsAdd=@("IT_watch"); FlagsSet=@("FL_watch_recovered"); InkKnot="chandler_watch_trade"; BlockedInkKnot="chandler_needs_salt" }
    ) },
    @{ Id="almshouse"; Script="Almshouse"; Code="R07"; Title="The Almshouse"; Notes="Rite 3: Debt Forgiven. Prosper forgets and signs."; Exits=@(@{ Name="ToBoneChandler"; Target="BoneChandler"; Label="Bone Chandler"; X=180; Y=740 }, @{ Name="ToSaltMarket"; Target="SaltMarket"; Label="Salt Market"; X=1700; Y=730 }); Interactions=@(
        @{ Name="Cots"; Key="cots"; Label="Cots"; X=560; Y=720; Look="Twelve cots. Nine occupied. Three of them are past talking and nobody has moved them yet."; Use="Corvin leaves them be."; Talk="Corvin keeps his voice down. Some rooms deserve that much."; Walk="Corvin walks the aisle between bad luck and worse care."; FlagsSet=@("FL_almshouse_cots_seen"); InkKnot="almshouse_cots" },
        @{ Name="Window"; Key="window"; Label="Window"; X=780; Y=650; Look="The window faces the water, which seems cruel until nobody here remembers what it means."; Use="Corvin wipes salt from the sill. It comes back in the grain."; Talk="Corvin asks the harbor to look elsewhere for once."; Walk="Corvin stands in the light and gives it very little to work with."; FlagsSet=@("FL_almshouse_window_seen"); InkKnot="almshouse_window" },
        @{ Name="HalfCoinProsper"; Key="prosper"; Label="Half-Coin Prosper"; X=980; Y=700; Look="Prosper smiles like he has just met Corvin, because he has."; Use="Corvin returns the watch. Prosper writes the forgiveness before the old anger can find the room."; Talk="Prosper asks who the forgiveness is for. Corvin says his own name. Prosper signs anyway."; Walk="Corvin crosses to Prosper carefully. Memory rot makes witnesses of strangers."; RequiresItems=@("IT_watch"); Blocked="Prosper owes a favor only after the watch is returned."; ItemsAdd=@("IT_forgiveness"); FlagsSet=@("FL_rite_debt"); InkKnot="prosper_forgiveness"; BlockedInkKnot="prosper_before_watch" }
    ) },
    @{ Id="fish_hall"; Script="FishHall"; Code="R08"; Title="The Fish Hall"; Notes="Coroner tag and day-count proof."; Exits=@(@{ Name="ToSaltMarket"; Target="SaltMarket"; Label="Salt Market"; X=180; Y=740 }); Interactions=@(
        @{ Name="IceTable"; Key="ice_table"; Label="Ice table"; X=610; Y=720; Look="That's the table. There's still a shape in the ice where Corvin was, and it's smaller than he'd have guessed."; Use="Corvin lies down in the shape he left. It fits. That answers a question he did not ask."; Talk="Corvin asks the ice how he looked. The ice is diplomatic."; Walk="Corvin stands beside the table and tries not to improve the outline."; FlagsSet=@("FL_body_fit_confirmed"); InkKnot="fish_hall_ice_table" },
        @{ Name="CoronerTag"; Key="coroner_tag"; Label="Coroner tag"; X=960; Y=710; Look="VALE, C. - THURS. RECOVERED, QUAY. NO MARKS."; Use="Corvin pockets the tag. No marks. Nobody hit him. Nobody had to."; Talk="The tag declines cross-examination."; Walk="Corvin stands where the fish smell almost covers the harbor."; ItemsAdd=@("IT_coroner_tag"); FlagsSet=@("FL_day_count_proven","FL_knows_daycount"); InkKnot="fish_hall_coroner_tag" },
        @{ Name="VisitorBook"; Key="visitor_book"; Label="Visitor book"; X=1260; Y=690; Look="They kept a book. Forty-one names came through to look at him."; Use="Corvin reads the names. Sabine is not in it. She would not sign a thing like that."; Talk="Corvin thanks the book for attendance figures. It has no sense of occasion."; Walk="Corvin keeps enough distance to pretend the names are statistics."; FlagsSet=@("FL_sabine_absent_from_book"); ConfessionsDiscover=@("cf_pride_twice"); InkKnot="fish_hall_visitor_book" },
        @{ Name="Drain"; Key="drain"; Label="Drain"; X=1500; Y=780; Look="It all goes back to the harbor eventually. Efficient island."; Use="It's a drain. Corvin would be adding to it, which feels redundant without being helpful."; Talk="Corvin negotiates with the drain. The drain has seniority."; Walk="Corvin gives the drain the professional respect due any working hole."; Wet="Corvin lets his coat drip into the drain. The island accepts the return without a receipt."; WetFlagsSet=@("FL_fish_hall_drain_seen"); WetInkKnot="fish_hall_drain" }
    ) },
    @{ Id="church_of_the_drowned"; Script="ChurchOfTheDrowned"; Code="R09"; Title="Church of the Drowned"; Notes="Teodor, confession chit, rate card, confession stall."; Exits=@(@{ Name="ToSaltMarket"; Target="SaltMarket"; Label="Salt Market"; X=180; Y=740 }, @{ Name="ToGreyFloat"; Target="GreyFloat"; Label="Grey Float"; X=1700; Y=730 }); Interactions=@(
        @{ Name="PoorBox"; Key="poor_box"; Label="Poor box"; X=620; Y=720; Look="Poor box. Someone had the lock off and put it back badly."; Use="Corvin finds the bad hinge, the missing notes, and the Church's talent for losing small money."; Talk="Corvin asks the poor box for an audit. It pleads poverty."; Walk="Corvin stands where charity becomes accounting."; ConfessionsDiscover=@("cf_greed_plate"); InkKnot="church_poor_box" },
        @{ Name="ConfessionBooth"; Key="confession_booth"; Label="Confession booth"; X=780; Y=650; Look="A green-lit box with a queue. The Church found a way to make truth billable by the minute."; Use="Teodor issues Corvin a confession chit with the relief of a man stamping his own reprieve."; Talk="Corvin asks the booth if it feels shame. It has excellent margins instead."; Walk="Corvin stands by the booth and watches grief become scheduling."; ItemsAdd=@("IT_chit"); FlagsSet=@("FL_church_booth_seen","FL_chit_acquired"); InkKnot="church_confession_booth" },
        @{ Name="ChurchStallSign"; Key="church_stall_sign"; Label="Church stall sign"; X=1100; Y=585; Look="THE DROWNED CANNOT LIE - ONE SHILLING. The queue is eleven deep and Teodor is sweating through doctrine."; Use="Corvin reads the tariff and the queue. The Church has turned truth into inventory."; Talk="Corvin asks the sign if shame costs extra. The sign has no small print, which is how they get you."; Walk="Corvin stands under the green tariff light and tries not to become merchandise."; FlagsSet=@("FL_church_stall_sign_seen"); InkKnot="church_stall_sign" },
        @{ Name="RateCard"; Key="rate_card"; Label="Teodor's stall"; X=940; Y=700; Look="THE DROWNED CANNOT LIE - ONE SHILLING. The queue is eleven deep and Teodor is sweating through doctrine."; Use="Corvin sits the stall for an hour. The Church gets its returned man, Teodor keeps his posting, and the rate card changes hands."; Talk="Teodor explains the discount badly, then realizes Corvin is the discount."; Walk="Corvin steps under the green light and tries not to count the donations."; RequiresItems=@("IT_chit"); Blocked="Teodor needs Corvin properly booked into the confession booth before he can hand over Church accounts."; ItemsAdd=@("IT_rate_card"); FlagsSet=@("FL_teodor_owes","FL_rate_card","FL_kane_seen"); ConfessionsDiscover=@("cf_cruel_sentences"); InkKnot="teodor_rate_card_booth"; BlockedInkKnot="teodor_needs_chit" }
    ) },
    @{ Id="grey_float"; Script="GreyFloat"; Code="R10"; Title="The Grey Float"; Notes="Rite 1: Borrowed Heartbeat. Juno, warmth, and regulator."; Exits=@(@{ Name="ToChurch"; Target="ChurchOfTheDrowned"; Label="Church"; X=180; Y=740 }, @{ Name="ToHarbormaster"; Target="HarbormasterOffice"; Label="Harbormaster"; X=1700; Y=730 }); Interactions=@(
        @{ Name="JunoTable"; Key="juno_table"; Label="Juno's table"; X=450; Y=675; Look="A bolted table, three ledgers, six rings, and one chair nobody borrows."; Use="Juno prices Corvin's trouble and names the Church rate card as the cost of her pump governor."; Talk="Juno looks up from her ledgers just long enough to make grief sound like arithmetic."; Walk="Corvin stops at the edge of Juno's amber light. The chair does not invite him."; FlagsSet=@("FL_float_juno_table_seen"); InkKnot="float_juno_table" },
        @{ Name="SteamScreen"; Key="steam_screen"; Label="Steam screen"; X=1450; Y=650; Look="Steam, backlight, silhouettes. The Float sells privacy by making everyone an outline."; Use="Corvin lets the steam hide him and discovers it cannot make him warm."; Talk="Corvin says excuse me to a curtain of vapor. The vapor has better boundaries than most clients."; Walk="Corvin stands where the amber turns bodies into shapes and shapes into rumors."; FlagsSet=@("FL_float_steam_seen"); InkKnot="float_steam_screen" },
        @{ Name="BilgeRegulator"; Key="bilge_regulator"; Label="Bilge regulator"; X=900; Y=700; Look="A clockwork bilge regulator ticks like a heart that negotiated better terms."; Use="Juno trades the regulator for the Church rate card and a look she pretends is not pity."; Talk="Juno says everybody comes here to feel something. Corvin has to settle for timing."; Walk="The Float rocks gently. Corvin, less gently."; RequiresItems=@("IT_rate_card"); Blocked="Juno wants the Church rate card before she lets the regulator leave the Float."; ItemsAdd=@("IT_regulator"); FlagsSet=@("FL_juno_met","FL_regulator_acquired"); InkKnot="juno_regulator_trade"; BlockedInkKnot="juno_needs_rate_card" },
        @{ Name="StaffCorner"; Key="staff_corner"; Label="Staff corner"; X=620; Y=710; Look="Three of them off shift, arguing about a tip. One is winning by refusing to care."; Use="Corvin considers helping and immediately improves the room by not doing that."; Talk="The staff corner settles nothing, but it gives Corvin two things he can use later: shame and phrasing."; Walk="Corvin stands where the steam makes everybody a silhouette with an opinion."; ConfessionsDiscover=@("cf_lust_float","cf_cow_apologize"); InkKnot="float_staff_corner" },
        @{ Name="HotPool"; Key="hot_pool"; Label="Hot pool"; X=1220; Y=720; Look="The pool steams amber. The only unsafe place on Mordida lit like a hearth."; Use="Corvin stands in the hot pool until his skin can pass for living. It feels like information, not comfort."; Talk="Corvin asks the pool for warmth. The pool is the first thing all day to answer honestly."; Walk="Corvin stands by the pool and remembers temperature as a rumor."; RequiresFlags=@("FL_juno_met"); Blocked="Juno has not offered the pool yet, and the Float remembers unpaid manners."; FlagsSet=@("FL_float_warmth_active"); InkKnot="juno_hot_pool_soak"; BlockedInkKnot="juno_pool_before_permission" }
    ) },
    @{ Id="harbormaster_office"; Script="HarbormasterOffice"; Code="R11"; Title="Harbormaster's Office"; Notes="Rite 1 check and Act I gate check."; Exits=@(@{ Name="ToGreyFloat"; Target="GreyFloat"; Label="Grey Float"; X=180; Y=740 }, @{ Name="ToSabine"; Target="SabineOffice"; Label="Sabine"; X=1700; Y=730; RequiresFlags=@("FL_rite_name","FL_rite_debt","FL_rite_heartbeat"); Blocked="The clerk blocks Sabine's door. Three Rites, all complete, or no audience." }); Interactions=@(
        @{ Name="ChecklistDesk"; Key="checklist_desk"; Label="Checklist desk"; X=740; Y=690; Look="A narrow desk, a blotter, and a checklist with three boxes beside Corvin's name."; Use="Corvin reads the boxes again: name, debt, heartbeat. Bureaucracy loves a trilogy."; Talk="Corvin asks the desk for mercy. The desk has a stamp instead."; Walk="Corvin stands where the office reduces a dead man to three empty squares."; FlagsSet=@("FL_harbormaster_checklist_seen"); InkKnot="harbormaster_checklist_desk" },
        @{ Name="SabineDoor"; Key="sabine_door"; Label="Sabine's door"; X=1500; Y=665; Look="Frosted glass. SABINE CROIX, HARBORMASTER, painted in black. The paint looks newer than the mercy."; Use="The handle does not move. The clerk's pen does, which is worse."; Talk="Corvin says her name under his breath. The door keeps it."; Walk="Corvin stops one room away from the woman who signed him dead."; FlagsSet=@("FL_harbormaster_sabine_door_seen"); InkKnot="harbormaster_sabine_door" },
        @{ Name="ChecklistClerk"; Key="checklist_clerk"; Label="Checklist clerk"; X=960; Y=700; Look="The clerk has a checklist and the cruel serenity of a man with one job."; Use="The regulator knocks inside Corvin's coat and the pool heat lingers in his hand. The clerk marks heartbeat complete."; Talk="The clerk listens for a pulse. The machine lies more persuasively than Corvin can."; Walk="Corvin stands before the desk and drips on process."; RequiresItems=@("IT_regulator"); RequiresFlags=@("FL_float_warmth_active"); Blocked="Corvin needs both the regulator's false pulse and the Float's borrowed warmth before the clerk can be fooled."; FlagsSet=@("FL_rite_heartbeat"); InkKnot="heartbeat_check_pass"; BlockedInkKnot="heartbeat_check_fail" }
    ) },
    @{ Id="sabine_office"; Script="SabineOffice"; Code="R12"; Title="Sabine's Office"; Notes="Act I finale: audience with Sabine after all three Rites."; Exits=@(@{ Name="ToHarbormaster"; Target="HarbormasterOffice"; Label="Harbormaster"; X=180; Y=740 }); Interactions=@(@{ Name="SabineDesk"; Key="sabine_desk"; Label="Sabine's desk"; X=960; Y=690; Look="Sabine's desk is dry, organized, and already winning the argument."; Use="Sabine checks Corvin's wrist. No pulse. Her hand stays there anyway."; Talk="Sabine lets Corvin decide what her explanation is worth. She does not apologize."; Walk="Corvin crosses the carpet and ruins it."; RequiresFlags=@("FL_rite_name","FL_rite_debt","FL_rite_heartbeat"); Blocked="Sabine does not receive the dead without standing. Finish the three Rites first."; FlagsSet=@("FL_act_i_complete"); InkKnot="sabine_act_i_audience" }) }
)

$roomScriptPath = "res://game/rooms/act_i_greybox_room.gd"
$exitScriptPath = "res://game/rooms/act_i_exit_hotspot.gd"
$interactionScriptPath = "res://game/rooms/act_i_interaction_hotspot.gd"
$hudPath = "res://game/ui/prologue_hud.tscn"

foreach ($room in $rooms) {
    $dir = Join-Path $root "game\rooms\$($room.Id)"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $scenePath = Join-Path $dir "room_$($room.Id).tscn"
    $dataPath = Join-Path $dir "room_$($room.Id).tres"
    $statePath = Join-Path $dir "room_$($room.Id)_state.gd"

    $exitResources = @()
    $exitNodes = @()
    $shapeIndex = 1
    foreach ($exit in $room.Exits) {
        $shapeId = "RectangleShape2D_exit_$shapeIndex"
        $exitResources += "[sub_resource type=`"RectangleShape2D`" id=`"$shapeId`"]`nsize = Vector2(240, 180)`n"
        $exitNodes += @"

[node name="$($exit.Name)" type="Area2D" parent="Hotspots"]
position = Vector2($($exit.X), $($exit.Y))
script = ExtResource("3_exit")
script_name = "$($exit.Name)"
description = "$($exit.Label)"
target_room = "$($exit.Target)"
requires_flags = $(Format-GodotStringArray $exit.RequiresFlags)
blocked_text = "$($exit.Blocked)"
look_text = "$($exit.Label). The map gets less merciful in that direction."
use_text = "Corvin considers using the way out as evidence. It declines."
talk_text = "Corvin tells the exit to wait. It does."
walk_text = "Corvin heads for $($exit.Label)."

[node name="Shape" type="CollisionShape2D" parent="Hotspots/$($exit.Name)"]
shape = SubResource("$shapeId")

[node name="Label" type="Label" parent="Hotspots/$($exit.Name)"]
offset_left = -86.0
offset_top = -118.0
offset_right = 126.0
offset_bottom = -82.0
theme_override_colors/font_color = Color(0.894118, 0.862745, 0.784314, 1)
text = "$($exit.Label)"
"@
        $shapeIndex += 1
    }

    $interactionNodes = @()
    foreach ($interaction in $room.Interactions) {
        $shapeId = "RectangleShape2D_interaction_$shapeIndex"
        $exitResources += "[sub_resource type=`"RectangleShape2D`" id=`"$shapeId`"]`nsize = Vector2(260, 150)`n"
        $interactionNodes += @"

[node name="$($interaction.Name)" type="Area2D" parent="Hotspots"]
position = Vector2($($interaction.X), $($interaction.Y))
script = ExtResource("4_interaction")
script_name = "$($interaction.Name)"
description = "$($interaction.Label)"
interaction_key = "$($interaction.Key)"
requires_items = $(Format-GodotStringArray $interaction.RequiresItems)
requires_flags = $(Format-GodotStringArray $interaction.RequiresFlags)
items_add = $(Format-GodotStringArray $interaction.ItemsAdd)
flags_set = $(Format-GodotStringArray $interaction.FlagsSet)
confessions_discover = $(Format-GodotStringArray $interaction.ConfessionsDiscover)
confessions_spend = $(Format-GodotStringArray $interaction.ConfessionsSpend)
wet_items_add = $(Format-GodotStringArray $interaction.WetItemsAdd)
wet_flags_set = $(Format-GodotStringArray $interaction.WetFlagsSet)
wet_confessions_discover = $(Format-GodotStringArray $interaction.WetConfessionsDiscover)
wet_confessions_spend = $(Format-GodotStringArray $interaction.WetConfessionsSpend)
wet_ink_knot = "$($interaction.WetInkKnot)"
duel_opponent = "$($interaction.DuelOpponent)"
duel_pool = $(Format-GodotStringArray $interaction.DuelPool)
ink_knot = "$($interaction.InkKnot)"
blocked_ink_knot = "$($interaction.BlockedInkKnot)"
alternate_requires_flags = $(Format-GodotStringArray $interaction.AlternateRequiresFlags)
alternate_message = "$($interaction.AlternateMessage)"
alternate_flags_set = $(Format-GodotStringArray $interaction.AlternateFlagsSet)
alternate_ink_knot = "$($interaction.AlternateInkKnot)"
blocked_text = "$($interaction.Blocked)"
look_text = "$($interaction.Look)"
use_text = "$($interaction.Use)"
talk_text = "$($interaction.Talk)"
walk_text = "$($interaction.Walk)"
wet_text = "$($interaction.Wet)"

[node name="Shape" type="CollisionShape2D" parent="Hotspots/$($interaction.Name)"]
shape = SubResource("$shapeId")

[node name="Label" type="Label" parent="Hotspots/$($interaction.Name)"]
offset_left = -96.0
offset_top = -102.0
offset_right = 156.0
offset_bottom = -66.0
theme_override_colors/font_color = Color(0.788235, 0.541176, 0.235294, 1)
text = "$($interaction.Label)"
"@
        $shapeIndex += 1
    }

    $scene = @"
[gd_scene load_steps=$($room.Exits.Count + $room.Interactions.Count + 8) format=3]

[ext_resource type="Script" path="$roomScriptPath" id="1_room"]
[ext_resource type="PackedScene" path="$hudPath" id="2_hud"]
[ext_resource type="Script" path="$exitScriptPath" id="3_exit"]
[ext_resource type="Script" path="$interactionScriptPath" id="4_interaction"]

[sub_resource type="Gradient" id="Gradient_bg"]
offsets = PackedFloat32Array(0, 0.58, 1)
colors = PackedColorArray(0.0470588, 0.0627451, 0.0745098, 1, 0.164706, 0.227451, 0.25098, 1, 0.894118, 0.862745, 0.784314, 1)

[sub_resource type="GradientTexture2D" id="GradientTexture2D_bg"]
gradient = SubResource("Gradient_bg")
width = 1920
height = 1080
fill_from = Vector2(0.5, 0)
fill_to = Vector2(0.5, 1)

$($exitResources -join "`n")
[node name="Room$($room.Script)" type="Node2D"]
script = ExtResource("1_room")
script_name = "$($room.Script)"
has_player = true
width = 1920
height = 1080
room_code = "$($room.Code)"
room_title = "$($room.Title)"
room_notes = "$($room.Notes)"

[node name="Background" type="Sprite2D" parent="."]
texture = SubResource("GradientTexture2D_bg")
centered = false

[node name="Floor" type="Polygon2D" parent="."]
color = Color(0.164706, 0.227451, 0.25098, 1)
polygon = PackedVector2Array(0, 700, 1920, 620, 1920, 1080, 0, 1080)

[node name="TitleLabel" type="Label" parent="."]
offset_left = 48.0
offset_top = 44.0
offset_right = 980.0
offset_bottom = 96.0
theme_override_colors/font_color = Color(0.894118, 0.862745, 0.784314, 1)
text = "$($room.Code) / $($room.Title)"

[node name="NotesLabel" type="Label" parent="."]
offset_left = 48.0
offset_top = 100.0
offset_right = 1180.0
offset_bottom = 176.0
theme_override_colors/font_color = Color(0.788235, 0.541176, 0.235294, 1)
text = "$($room.Notes)"

[node name="WalkableAreas" type="Node2D" parent="."]

[node name="WalkableMain" type="Polygon2D" parent="WalkableAreas"]
color = Color(0.494118, 0.607843, 0.305882, 0.35)
polygon = PackedVector2Array(160, 810, 1720, 760, 1810, 1025, 120, 1030)

[node name="Props" type="Node2D" parent="."]

[node name="Hotspots" type="Node2D" parent="."]
$($exitNodes -join "`n")
$($interactionNodes -join "`n")

[node name="Regions" type="Node2D" parent="."]

[node name="Markers" type="Node2D" parent="."]

[node name="PlayerStart" type="Marker2D" parent="Markers"]
position = Vector2(960, 790)

[node name="Characters" type="Node2D" parent="."]

[node name="PrologueHud" parent="." instance=ExtResource("2_hud")]
"@

    Write-Utf8NoBom -Path $scenePath -Value $scene

    $data = @"
[gd_resource type="Resource" script_class="PopochiuRoomData" load_steps=2 format=3]

[ext_resource type="Script" path="res://addons/popochiu/engine/objects/room/popochiu_room_data.gd" id="1_data"]

[resource]
script = ExtResource("1_data")
script_name = "$($room.Script)"
scene = "res://game/rooms/$($room.Id)/room_$($room.Id).tscn"
"@
    Write-Utf8NoBom -Path $dataPath -Value $data

    $state = @"
@tool
extends PopochiuRoomData

var visited_for_act_i := false
"@
    Write-Utf8NoBom -Path $statePath -Value $state
}

Write-Host "Generated $($rooms.Count) Act I greybox room scaffolds."
