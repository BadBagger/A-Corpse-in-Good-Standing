# Act I Background Production Brief

Generated from `docs/art/act_i_hotspot_map.csv` by `tools/Export-ActIBackgroundManifest.ps1`.

Native background size: 1920x1080.
Default walk band: y 650-800.

Use this as the handoff list for Blender greyboxes, paintovers, and final Godot background imports. The Registrar duel remains a UI/system beat; art can frame the Registry for it, but must not change the accepted duel format.

## R01 - Mudflats

- Source blend: `art/src/backgrounds/act_i/mudflats.blend`
- Paintover source: `art/src/backgrounds/act_i/mudflats.psd`
- Export PNG: `art/export/backgrounds/act_i/mudflats_bg.png`
- Godot import target: `game/rooms/mudflats/background/mudflats_bg.png`
- Exits: scripted hotspot: road to the Salt Market

| Hotspot | Type | Position | Critical Roles | Ink / Duel |
|---|---|---:|---|---|
| harbor view | hotspot | 1180, 620 | scene_texture | - |
| road to the Salt Market | hotspot | 1765, 665 | custom_navigation | - |
| Bollard-of-Tomas | hotspot | 390, 702 | scene_texture | - |
| Corvin's hands | hotspot | 660, 760 | scene_texture | - |
| coat | hotspot | 735, 760 | scene_texture | - |
| missing boots | hotspot | 965, 910 | scene_texture | - |
| silt | hotspot | 500, 930 | scene_texture | - |

## R02 - The Old Quay

- Source blend: `art/src/backgrounds/act_i/old_quay.blend`
- Paintover source: `art/src/backgrounds/act_i/old_quay.psd`
- Export PNG: `art/export/backgrounds/act_i/old_quay_blockout_bg.png`
- Godot import target: `game/rooms/old_quay/background/old_quay_blockout_bg.png`
- Exits: Salt Market -> SaltMarket; Mudflats -> Mudflats

| Hotspot | Type | Position | Critical Roles | Ink / Duel |
|---|---|---:|---|---|
| Bollard Petra | hotspot | 690, 700 | scene_texture | old_quay_bollard_petra |
| Ledger bollard | hotspot | 870, 705 | scene_texture | old_quay_bollard_ledger |
| Silent bollards | hotspot | 910, 710 | scene_texture | old_quay_silent_bollards |
| Bride bollard | hotspot | 1050, 715 | scene_texture | old_quay_bollard_bride |
| Bollard Tomas | hotspot | 470, 720 | conditional_followup, confession_source | old_quay_tomas_topics, old_quay_bollards_all_seen |
| Empty flask | hotspot | 1180, 760 | item_reward | old_quay_flask |
| Rope cleat | hotspot | 720, 800 | wet_verb, item_reward | old_quay_rope_cleat, old_quay_rope_cleat |

## R03 - Salt Market

- Source blend: `art/src/backgrounds/act_i/salt_market.blend`
- Paintover source: `art/src/backgrounds/act_i/salt_market.psd`
- Export PNG: `art/export/backgrounds/act_i/salt_market_bg.png`
- Godot import target: `game/rooms/salt_market/background/salt_market_bg.png`
- Exits: Registry -> HarborRegistry; Church -> ChurchOfTheDrowned; Bone Chandler -> BoneChandler; Almshouse -> Almshouse; Fish Hall -> FishHall; Old Quay -> OldQuay

| Hotspot | Type | Position | Critical Roles | Ink / Duel |
|---|---|---:|---|---|
| Church sign | hotspot | 1380, 540 | wet_verb | salt_market_church_sign_wet |
| Whale-oil lamp | hotspot | 1520, 620 | scene_texture | salt_market_lamp |
| Boot stall | hotspot | 300, 720 | gated | salt_market_boot_stall_after |
| Fishmonger | hotspot | 520, 720 | confession_source | salt_market_fishmonger |
| Confession queue | hotspot | 1180, 720 | confession_source | salt_market_confession_queue |
| Crowd | hotspot | 960, 760 | confession_source, item_reward | salt_market_public_recognition |

## R05 - Harbor Registry

- Source blend: `art/src/backgrounds/act_i/harbor_registry.blend`
- Paintover source: `art/src/backgrounds/act_i/harbor_registry.psd`
- Export PNG: `art/export/backgrounds/act_i/harbor_registry_bg.png`
- Godot import target: `game/rooms/harbor_registry/background/harbor_registry_bg.png`
- Exits: Salt Market -> SaltMarket

| Hotspot | Type | Position | Critical Roles | Ink / Duel |
|---|---|---:|---|---|
| Kestrel ledger | hotspot | 1220, 610 | blocked_feedback, confession_source, item_reward, gated | registry_ledger_page, registry_ledger_blocked |
| Desk lamp | hotspot | 890, 650 | wet_verb | registry_lamp_smoked |
| Ledgers | hotspot | 420, 660 | scene_texture | registry_ledgers |
| Registrar | duel | 980, 690 | duel, blocked_feedback, item_reward, gated | registry_registrar_needs_manifest, registrar |
| Open roll | hotspot | 640, 700 | scene_texture | registry_roll_book |

## R06 - The Bone Chandler

- Source blend: `art/src/backgrounds/act_i/bone_chandler.blend`
- Paintover source: `art/src/backgrounds/act_i/bone_chandler.psd`
- Export PNG: `art/export/backgrounds/act_i/bone_chandler_bg.png`
- Godot import target: `game/rooms/bone_chandler/background/bone_chandler_bg.png`
- Exits: Almshouse -> Almshouse; Salt Market -> SaltMarket

| Hotspot | Type | Position | Critical Roles | Ink / Duel |
|---|---|---:|---|---|
| Chess set | hotspot | 790, 680 | scene_texture | chandler_chess_set |
| Wares | hotspot | 560, 700 | scene_texture | chandler_wares |
| Prosper's watch | hotspot | 1010, 700 | blocked_feedback, item_reward, gated | chandler_watch_trade, chandler_needs_salt |

## R07 - The Almshouse

- Source blend: `art/src/backgrounds/act_i/almshouse.blend`
- Paintover source: `art/src/backgrounds/act_i/almshouse.psd`
- Export PNG: `art/export/backgrounds/act_i/almshouse_bg.png`
- Godot import target: `game/rooms/almshouse/background/almshouse_bg.png`
- Exits: Salt Market -> SaltMarket; Bone Chandler -> BoneChandler

| Hotspot | Type | Position | Critical Roles | Ink / Duel |
|---|---|---:|---|---|
| Window | hotspot | 780, 650 | scene_texture | almshouse_window |
| Half-Coin Prosper | hotspot | 980, 700 | blocked_feedback, item_reward, gated | prosper_forgiveness, prosper_before_watch |
| Cots | hotspot | 560, 720 | scene_texture | almshouse_cots |

## R08 - The Fish Hall

- Source blend: `art/src/backgrounds/act_i/fish_hall.blend`
- Paintover source: `art/src/backgrounds/act_i/fish_hall.psd`
- Export PNG: `art/export/backgrounds/act_i/fish_hall_bg.png`
- Godot import target: `game/rooms/fish_hall/background/fish_hall_bg.png`
- Exits: Salt Market -> SaltMarket

| Hotspot | Type | Position | Critical Roles | Ink / Duel |
|---|---|---:|---|---|
| Visitor book | hotspot | 1260, 690 | confession_source | fish_hall_visitor_book |
| Coroner tag | hotspot | 960, 710 | item_reward | fish_hall_coroner_tag |
| Ice table | hotspot | 610, 720 | scene_texture | fish_hall_ice_table |
| Drain | hotspot | 1500, 780 | wet_verb | fish_hall_drain |

## R09 - Church of the Drowned

- Source blend: `art/src/backgrounds/act_i/church_of_the_drowned.blend`
- Paintover source: `art/src/backgrounds/act_i/church_of_the_drowned.psd`
- Export PNG: `art/export/backgrounds/act_i/church_of_the_drowned_bg.png`
- Godot import target: `game/rooms/church_of_the_drowned/background/church_of_the_drowned_bg.png`
- Exits: Grey Float -> GreyFloat; Salt Market -> SaltMarket

| Hotspot | Type | Position | Critical Roles | Ink / Duel |
|---|---|---:|---|---|
| Church stall sign | hotspot | 1100, 585 | scene_texture | church_stall_sign |
| Confession booth | hotspot | 780, 650 | item_reward | church_confession_booth |
| Teodor's stall | hotspot | 940, 700 | blocked_feedback, confession_source, item_reward, gated | teodor_rate_card_booth, teodor_needs_chit |
| Poor box | hotspot | 620, 720 | confession_source | church_poor_box |

## R10 - The Grey Float

- Source blend: `art/src/backgrounds/act_i/grey_float.blend`
- Paintover source: `art/src/backgrounds/act_i/grey_float.psd`
- Export PNG: `art/export/backgrounds/act_i/grey_float_bg.png`
- Godot import target: `game/rooms/grey_float/background/grey_float_bg.png`
- Exits: Harbormaster -> HarbormasterOffice; Church -> ChurchOfTheDrowned

| Hotspot | Type | Position | Critical Roles | Ink / Duel |
|---|---|---:|---|---|
| Steam screen | hotspot | 1450, 650 | scene_texture | float_steam_screen |
| Juno's table | hotspot | 450, 675 | scene_texture | float_juno_table |
| Bilge regulator | hotspot | 900, 700 | blocked_feedback, item_reward, gated | juno_regulator_trade, juno_needs_rate_card |
| Staff corner | hotspot | 620, 710 | confession_source | float_staff_corner |
| Hot pool | hotspot | 1220, 720 | blocked_feedback, gated | juno_hot_pool_soak, juno_pool_before_permission |

## R11 - Harbormaster's Office

- Source blend: `art/src/backgrounds/act_i/harbormaster_office.blend`
- Paintover source: `art/src/backgrounds/act_i/harbormaster_office.psd`
- Export PNG: `art/export/backgrounds/act_i/harbormaster_office_bg.png`
- Godot import target: `game/rooms/harbormaster_office/background/harbormaster_office_bg.png`
- Exits: Sabine -> SabineOffice; Grey Float -> GreyFloat

| Hotspot | Type | Position | Critical Roles | Ink / Duel |
|---|---|---:|---|---|
| Sabine's door | hotspot | 1500, 665 | scene_texture | harbormaster_sabine_door |
| Checklist desk | hotspot | 740, 690 | scene_texture | harbormaster_checklist_desk |
| Checklist clerk | hotspot | 960, 700 | blocked_feedback, gated | heartbeat_check_pass, heartbeat_check_fail |

## R12 - Sabine's Office

- Source blend: `art/src/backgrounds/act_i/sabine_office.blend`
- Paintover source: `art/src/backgrounds/act_i/sabine_office.psd`
- Export PNG: `art/export/backgrounds/act_i/sabine_office_bg.png`
- Godot import target: `game/rooms/sabine_office/background/sabine_office_bg.png`
- Exits: Harbormaster -> HarbormasterOffice

| Hotspot | Type | Position | Critical Roles | Ink / Duel |
|---|---|---:|---|---|
| Sabine's desk | hotspot | 960, 690 | gated | sabine_act_i_audience |

