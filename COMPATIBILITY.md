# Compatibility review: Project Zomboid 42.21.0 multiplayer

Reviewed **2026-10-11** for the exact server build you specified. The supplied list has **294 unique requested IDs**, mapped to **249 Workshop items**. The recommended profile selects **260 IDs / 224 Workshop items** and excludes **34 IDs**.

**This pack has not passed a live server/gameplay test.** Author documentation, public metadata and automated tool checks establish a proposed selection and dependency order. They cannot establish error-free operation of all 260 mods together. Some authors document only older B42 versions, hosted multiplayer, or incomplete features.

## What changed

All 294 supplied IDs are preserved in [requested-mods.txt](requested-mods.txt) and [mods.catalog.json](mods.catalog.json). The raw exports are retained under [inputs](inputs/default.txt); they are reference data because their selection enables incompatible variants.

The new list adds 183 IDs and removes JustHideDebugMenu, TacHoldFork and TacHold Complete from the original 114. The obsolete TacHold exclusion was removed, enabling Buttstroke again. See the historical [list comparison](mod-list-changes-2026-10-11.md).

There is one documented Workshop edition change: BarricadedWorld now maps to **3529472651**, the maintained B42 continuation. The author publishes the same BarricadedWorld ID in [B42 metadata](https://raw.githubusercontent.com/Terrahop/zomboid-barricadedworld/main/mod/42/mod.info). The former ID **2696986935** remains recorded as OriginalWorkshopId. This is not a claim that the original was B41-only. [Continuation author](https://steamcommunity.com/sharedfiles/filedetails/?id=3529472651).

Players migrating from the old pack must unsubscribe from the old edition and ensure its installed copy is gone. Both editions expose the same ID; default.txt cannot select between them. Client setup checks installed duplicate providers in the Workshop roots it uses and the selected local Zomboid/mods directory before applying the preset. Unrelated subscriptions can remain. Other Steam libraries/custom game cache locations outside those scanned roots are not certified.

## Why the full list cannot be enabled together

| Combination | Decision and evidence |
| --- | --- |
| GunsOfMarz + MarzVanillaGuns | Select GunsOfMarz. The weapons author excludes Vanilla Weapons Plus from the GoM combination. [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3722134990) |
| GenRange + BetterGeneratorInfo | Keep BetterGeneratorInfo. Its author excludes competing generator range/fuel display replacements. [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3576056135) |
| Full Boots Expanded + VanillaONLY | Select the full shoe mod and its matching Tomb patch; exclude the vanilla-only shoe and patch alternatives. [Boots author](https://steamcommunity.com/sharedfiles/filedetails/?id=2850935956), [Tomb compatibility author](https://steamcommunity.com/sharedfiles/filedetails/?id=3431734923) |
| TombBody + SPNRetextureCustom | Exclude player retexture customization, which the Spongie author declares incompatible with the selected Tomb body. [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3340255334) |
| Vanilla 256 body textures + SPNCCDetailsHD | Use SPNCCFaces and standard details. HD details require matching 512 body textures, which TombBody's model-only module does not provide. [Spongie author](https://steamcommunity.com/sharedfiles/filedetails/?id=3414634809), [Tomb author](https://steamcommunity.com/sharedfiles/filedetails/?id=3429790870) |

The optional zombie underwear retexture is also held back: its author acknowledged erroneous Tomb incompatibility declarations, but the installed package has not been inspected. The tool respects current metadata; it never edits a mod's incompatibility rules to force it on.

The default body selection uses vanilla textures with Tomb's model-only module and the appropriate clothing patches. Extra Tomb/Spongie human retexture modules and HD details are not enabled automatically. Players must enable the matching body/customization mods in the main menu and restart as requested. [Spongie setup instructions](https://steamcommunity.com/sharedfiles/filedetails/?id=3414634809).

## All 34 held-back requested IDs

Exclusion does not always mean a confirmed conflict. Reasons below distinguish mutually exclusive variants, discontinued features, known author issues, insufficient multiplayer evidence and inferred redundancy. A held-back mod remains mapped and cannot be silently re-enabled during dependency expansion. Its Workshop item may still be downloaded when it also contains a selected module.

| Requested ID | Reason | Primary source |
| --- | --- | --- |
| `2925034918/EasyLaundry` | Requested original has no verified current 42.21 multiplayer support. A separate 42.20 fix exists, but its exact 42.21 server behavior has not been verified; retain the original mapping for opt-in testing. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=2925034918) |
| `UsefulBarrelsMP` | Author explicitly states multiplayer is not fully implemented or tested; excluded from the conservative server profile. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3436537035) |
| `ReactiveSE` | Author says physical scene generation is single-player only and dedicated multiplayer testing is pending. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3656190498) |
| `SPNCCDetailsHD` | Requires matching 512x512 body textures. Default requested TombBody is a model replacement, while the chosen vanilla-face preset uses 256 textures. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3414634809) |
| `DynamicVehicleSnow` | Redundant snow visual provider: its author recommends ImmersiveSnow. This is a conservative overlap recommendation, not an author-declared hard incompatibility. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3781818628) |
| `PFHDTrueCargo` | Author states server behavior is not yet tested; dedicated thrown-car spill is untested. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3806955469) |
| `OverTheShoulder` | Author only tested a hosted server with one player; animation synchronization to other players and dedicated multiplayer remain untested. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3808805481) |
| `MarzVanillaGuns` | Guns of Marz author explicitly forbids using Vanilla Weapons Plus alongside GunsOfMarz; keep GunsOfMarz for this profile. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3773834525) |
| `83amgeneralM923extra` | Legacy optional texture ID is absent from the current author Mod ID list; keep disabled until downloaded Build42.21 metadata verifies it. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=2811383142) |
| `92amgeneralM998extra` | Legacy optional texture ID is absent from the current author Mod ID list; keep disabled until downloaded Build42.21 metadata verifies it. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=2642541073) |
| `close-the-trunk` | Original author description only declares multiplayer support for Build41; Build42 multiplayer item loss reports exist. Hold back pending a Build42.21 dedicated-server test. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3262467691) |
| `GenRange` | Conflicts with selected BetterGeneratorInfo: both replace the generator information/range display; BetterGeneratorInfo author explicitly excludes other generator range/fuel mods. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=2972289937) |
| `1299328280/ToadTraitsDynamic` | Legacy More Traits is no longer maintained and its author lists an unresolved multiplayer Martial Artist death-sync issue; the older ComputerPers override has not been verified against the current legacy version. Hold this family out of the conservative MP profile until tested. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=1299328280) |
| `1299328280/ToadTraits` | Legacy More Traits is no longer maintained and its author lists an unresolved multiplayer Martial Artist death-sync issue; the older ComputerPers override has not been verified against the current legacy version. Hold this family out of the conservative MP profile until tested. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=1299328280) |
| `CP_MoreTraits` | Legacy More Traits is no longer maintained and its author lists an unresolved multiplayer Martial Artist death-sync issue; the older ComputerPers override has not been verified against the current legacy version. Hold this family out of the conservative MP profile until tested. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3587315482) |
| `MutiesContextMenuIcons` | Author explicitly says the original icon mod has not been tested on Build42 stable. Held out of the conservative profile rather than asserting compatibility. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3101668503) |
| `MutiesContextMenuIconsStorage42` | Author archived this B42 icon extension and directs users to a newer mod. Old magazine-menu hooks overlap firearm-menu mods; hold these archived modules out of the conservative MP profile. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3422112160) |
| `MutiesContextMenuIconsExpanded42` | Author archived this B42 icon extension and directs users to a newer mod. Old magazine-menu hooks overlap firearm-menu mods; hold these archived modules out of the conservative MP profile. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3422112160) |
| `MutiesContextMenuIconsRedrawn42` | Author archived this B42 icon extension and directs users to a newer mod. Old magazine-menu hooks overlap firearm-menu mods; hold these archived modules out of the conservative MP profile. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3422112160) |
| `NepEngineColor` | Author says this is now a vanilla Build42 feature, so it is redundant. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=2975204120) |
| `NepBatteryColor` | Author says this is now a vanilla Build42 feature, so it is redundant. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=2973053380) |
| `NepHighBeams` | Author states Build42.13 testing was singleplayer only; hold this optional lighting change back until Build42.21 multiplayer is tested. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3438126404) |
| `OffroadGoBrrr` | Author labels this Build41 and deprecated; Build42 implements the intended off-road behavior in the base game. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3309119521) |
| `RainingZombies` | Author recommends singleplayer only: local physics can cause multiplayer desync and MP has not been tested. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3763651059) |
| `KI5minifixes` | Current author acknowledged invalid KI5CamperJack recipe input and an update pending after KI5 updates; hold this optional patch back until the current Build42.21 package is tested. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3740300378) |
| `SPNRetextureCustom` | Player retexture customisation is incompatible with the selected Tomb body and the submitted list supplies no required compatible human Spongie texture variant. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3340255334) |
| `SPNRetextureZombieUnderwear` | The author acknowledged erroneous Tomb incompatibility exclusions in zombie texture variants, but current downloaded mod.info has not been verified. Hold this optional zombie variant until metadata and Tomb visuals can be checked; never rewrite exclusions automatically. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3340255334) |
| `TombBodyCompatBootsExpVanilla` | Alternative patch for the vanilla-only Boots variant; this profile selects full Boots Expanded and its matching full compatibility patch. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3431734923) |
| `SM4BootsExpandedB42VanillaONLY` | Alternative to full Boots Expanded. Enable one shoe variant; full SM4BootsExpandedB42 is selected for this profile. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=2850935956) |
| `WorkingSeatbelt` | Author acknowledged a recent game update broke the mod and suggested disabling the chime or mod; a Build42.21 bug report is open. Hold back pending an author update/test. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3055029361) |
| `ZombiesTargetAnimals` | Author describes MP support as ALPHA and several feeding/herd features remain singleplayer-only; exclude from conservative MP profile pending multi-client animal tests. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3774007514) |
| `ADRENALINE_MOD` | Discontinued; author says panic is disabled or bugged in B42 multiplayer and the mod currently does nothing there. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=2807001835) |
| `ZombieDismembermentB42` | Author labels multiplayer experimental and explicitly says no live multiplayer or dedicated-server gameplay session has been tested. Persistence after area unload/restart is also unverified. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3811483602) |
| `CrashedCarsMod` | Author labels this abandoned and says Build42 multiplayer support needs help. Build42 also requires a fresh save. | [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=1539281445) |

DynamicVehicleSnow versus ImmersiveSnow is an **inferred redundancy**, not an author-confirmed hard incompatibility. The selected ImmersiveSnow supplies overlapping vanilla-vehicle snow visuals.

## Load order

The full proposed order is [preview/load-order.preview.txt](preview/load-order.preview.txt). It is recomputed after real downloads; the preview has not inspected current installed packages.

| Rule | Applied order |
| --- | --- |
| Texture/depth fixes | ETO_B first; bath depth map very early and before TakeABathAndShowerNew |
| Shared libraries | Required frameworks/libraries before their consumers |
| Error reporting | ChuckleberryFinnAlertSystem before errorMagnifier |
| Weapons | HBVCEFb42 → SWMG → GunsOfMarz |
| KI5 vehicles | Required libraries → vehicle bases → matching expansions |
| Vehicle adjustments | Vehicles → specialized loot/storage patches → VehicleRepairOverhaul → VehicleSalvageOverhaulB42 |
| Body/clothing | Clothing and body modules → matching compatibility patches; boots before their footwear patch |
| Weather/lighting | Project Seasons and winter modules before their final sun override |
| Hotbar | CleanHotBar late; MinimalHotbar after CleanHotBar/CleanUI/ItemCondition |

The error-reporting edge was corrected using the authors' native files: [errorMagnifier requires the alert system](https://raw.githubusercontent.com/Chuckleberry-Finn/errorMagnifier/main/Contents/mods/errorMagnifier/42.20/mod.info), while the [alert-system file has no reverse native requirement](https://raw.githubusercontent.com/Chuckleberry-Finn/moddingAlertSystem/main/Contents/mods/chuckleberryModdingAlertSystem/42.0/mod.info). Steam Workshop mutual installation links must not be treated as two opposing load-order edges.

The [weapons author specifies Hot Brass → Gunworks → GoM](https://steamcommunity.com/sharedfiles/filedetails/?id=3722134990), and [MinimalHotbar requests loading after CleanHotBar](https://steamcommunity.com/sharedfiles/filedetails/?id=3688576740). Vehicle author-specific constraints and every new vehicle mapping are recorded in [research/vehicles.md](research/vehicles.md).

Real downloads are checked for available B42 IDs/aliases, requirements, version bounds, multiple providers, declared incompatibilities and cycles. The scanner models version folder selection by major/minor and uses the chosen native mod.info as a whole, with common metadata as fallback. It additionally reads common loadAfter/loadBefore/incompatibleMods sorter fields. It does not model category/global loadFirst/loadLast. The native loader analysis used for these details covers 42.20, not an inspection of your exact 42.21.0 executable. [Loader research](https://steamcommunity.com/sharedfiles/filedetails/?id=3776551449), [sorter author instructions](https://steamcommunity.com/workshop/filedetails/discussion/3423660713/592888629473368243/).

Workshop required-item sidebars may list optional companion variants. For example SpnHair's [author metadata requires FH](https://raw.githubusercontent.com/LazySpongie/SpongieHair/main/Contents/mods/Spongie%20Hair/42.0/mod.info); Hairstyle Unlocker only [orders itself after the optional Improved Hair Menu](https://raw.githubusercontent.com/LazySpongie/SpongieHairAPI/main/Contents/mods/Spongie%20Hairstyle%20Unlocker/42.18/mod.info). A verified mapping for that optional menu is available in Dependencies but is not downloaded/enabled by default.

No additional mandatory external library was verified in the focused gap checks. That finding is not exhaustive: four of the 43 new non-vehicle item sidebars were inaccessible, and fresh downloaded metadata remains essential. Mapped native dependencies can be downloaded automatically; unknown or ambiguous dependencies stop setup with an actionable ID. [Dependency audit](research/extra-nonvehicle-dependencies.json).

## Selected mods still needing specific checks

These remain in the proposed profile with limitations. Their selection is not a certification of dedicated-server compatibility.

| Selected mod/combination | Remaining limitation or test |
| --- | --- |
| ShelterHold_Beehive / Neat_Crafting_AddonXP | Published support ends at 42.20.4 / 42.20.x. Check actual version bounds and crafting/beehive behavior on 42.21.0. [Beehive author](https://steamcommunity.com/sharedfiles/filedetails/?id=3596827035), [XP addon author](https://steamcommunity.com/sharedfiles/filedetails/?id=3540503606) |
| VB_CommonSense | Author labels multiplayer a work in progress. Test overlapping bandage, belt-light and magazine actions with this pack. [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3750253491) |
| VanillaOutfitsExpanded + Open Jackets + Tomb | New outfit textures do not have full opened/rolled-jacket support; female body clipping is documented. [Outfits author](https://steamcommunity.com/sharedfiles/filedetails/?id=3783094058) |
| EURY_CONTAINERS + CleanUI | Authors support the pair, but nested containers in world loot have multiplayer networking limitations. Test inventory and world-container behavior separately. [Containers author](https://steamcommunity.com/sharedfiles/filedetails/?id=3586216562), [CleanUI author](https://steamcommunity.com/sharedfiles/filedetails/?id=3437629766) |
| FittedBarricades | Multiplayer was tested by the author; dedicated-server use was not. Test barricading from two clients. [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3795414660) |
| ImmersiveSnow | Author lists vehicle snow flickering at some angles. [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3810071828) |
| ImmersiveCarsDecay + TimeDecreasesCarConditionB42 | Both may reduce initial vehicle condition. This is an inferred balance overlap; tune sandbox settings and inspect newly spawned vehicles. [Decay author](https://steamcommunity.com/sharedfiles/filedetails/?id=3495105059), [time-condition author](https://steamcommunity.com/sharedfiles/filedetails/?id=3448375286) |
| RealisticDash + amclub | Dashboard author lists a soft incompatibility while riding Motorclub bikes. Test bikes as well as cars. [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3635591071) |
| SM4BootsExpandedB42 | Author labels B42 beta with a 42.15 quickfix. Check shoes and the selected body patch on this exact build. [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=2850935956) |
| HBAmmoCraft + GunsOfMarz | Author's ammo-crafting coverage does not include every GoM ammunition type. Missing recipes may be a feature limitation. [Crafting author](https://steamcommunity.com/sharedfiles/filedetails/?id=3610677934) |
| TrueSmoking + MoodleFramework | Framework 2.7 changed its old consumer API. Test moodles, partial cigarettes, reconnect and two clients. The optional legacy bridge is not silently added. [Framework author](https://steamcommunity.com/sharedfiles/filedetails/?id=3396446795), [smoking author](https://steamcommunity.com/sharedfiles/filedetails/?id=3423984426) |
| MiniHealthPanel + NeatUI | A one-time update notice can be hard to dismiss. Temporarily disable UI mods, dismiss once, restore preset and restart if affected. [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=2866258937) |
| P4HasBeenRead / ItIsOfInterestToMe | Map-read status may not persist after reconnect; notes can differ between clients. [Read-marker author](https://steamcommunity.com/sharedfiles/filedetails/?id=2544353492), [notes author](https://steamcommunity.com/sharedfiles/filedetails/?id=3796373365) |
| TrueWeight | Partial item matching can affect other mods' items. Check weapon, food and container weights. [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3768669395) |

Other interactions remain untested. Passing metadata checks cannot detect every Lua overwrite, animation mismatch, save migration, networking error or cumulative balance/performance effect.

## What is required beyond the CMD?

The launcher handles role selection, downloads, metadata ordering, server INI backups/updates, required sleep settings, matching client preset installation and an automatic player ZIP. Normal users do not need PowerShell commands or manual mod-list editing.

| Who | Required action |
| --- | --- |
| Server owner | Install/configure a 42.21.0 server once and stop it before setup. Choose its existing INI in the menu for automatic application. Generate-settings-only requires copying the generated lines manually. |
| Server owner | Supply Steam authentication/Steam Guard if anonymous Workshop downloads fail. The tool does not install the server game or open router/firewall ports. |
| Server owner | Restart into a fresh **test** world and verify with two clients before using the main world. Share output/player-setup.zip after successful metadata checks and runtime validation. |
| Players | Install the same game build, run Steam signed in and close the game during setup. Extract all files from the owner's ZIP, run the CMD, launch/restart and join. |
| Migrating players | Remove duplicate obsolete editions reported by setup, especially original Barricaded World. Other subscriptions can remain. |
| Everyone | Check body/hair/clothing enablement in the main menu and fully restart after changes. Handle MiniHealthPanel's one-time notice if affected. |

TrueSleep requires SleepAllowed=true and SleepNeeded=true in multiplayer; both are automatically applied with a selected server INI. YouDriveISleep also needs sleeping allowed. [TrueSleep author](https://steamcommunity.com/sharedfiles/filedetails/?id=3781533687), [passenger-sleep author](https://steamcommunity.com/sharedfiles/filedetails/?id=2830570280).

Use a fresh world for DG_MIVehicles: the author warns existing vehicle doors, hoods and trunks will open when it is added. Keep vanilla vehicle spawning enabled for VVR, whose author warns existing vanilla vehicle loot can be replaced. These are game/world choices the downloader cannot repair. [DG author](https://steamcommunity.com/sharedfiles/filedetails/?id=3162566044), [VVR author](https://steamcommunity.com/sharedfiles/filedetails/?id=3423424077).

ModFolders.cfg is optional UI organization. It does not determine load order and needs no manual installation for this setup.

## Runtime acceptance before the main world

1. Verify server and both clients report **42.21.0**, use the same current player ZIP and have matching Workshop revisions.
2. Start a fresh world. Check server startup logs for missing IDs, recipes, scripts, models and Lua exceptions. Both clients must join, see each other and reconnect without checksum/mod errors.
3. With both players, test equipped clothing/body/hair, opened jackets and shoes; weapon equip, automatic fire, reload, sling, inspection and ammo crafting; healing/bandages and belt lighting.
4. Test inventory/world nested containers, arranging items, generator information, water barrels, food/cooking/preservation, bathing, beehives and crafting XP.
5. Test KI5 cars, expanded bases, campers, trailers, bikes, vehicle loot, repairs, salvage, seats/sleep and snow visuals. Check newly generated vehicle condition under your sandbox settings.
6. Test traits/weight, smoking moodles, fitness, sleep/wake, weather/season transitions and bandit behavior. Save, stop/restart the server and reconnect; check persistence and logs.
7. If a failure appears, keep logs and the precise action/IDs involved. Reproduce with a smaller selection on a separate test world. Fix or exclude the offending feature on the server, export a fresh ZIP and repeat the affected test.

Do not treat the absence of a visible red error counter as proof. Vanilla build defects and intended feature limitations can also affect gameplay.

## Evidence and verification limits

- [Vehicles](research/vehicles.md): all 131 added vehicle IDs mapped; author dependencies, addon ordering, unsupported/redundant items and fresh-world constraints.
- [Other new mods](research/nonvehicles.md): 52 added non-vehicle IDs, alternative modules, conflicts, optional companions and multiplayer warnings.
- [Retained mods](research/retained-audit.json): focused current constraints for the 111 retained requested entries.
- [Dependency follow-up](research/extra-dependencies.json) and [new-item sidebar follow-up](research/extra-nonvehicle-dependencies.json): native requirement checks and explicit coverage gaps.
- [Launcher audit](research/launcher-audit.md): installation prerequisites and what cannot be automated here.
- [Offline verification](tests/Verify-PZMods.ps1): synthetic Steam/download fixtures, selection/order, backups, failure paths, exported selection records and menu flows using the repository catalog.

Real Windows double-click dialogs, Steam authentication/native DLL downloads, dedicated-server startup, two-client synchronization and gameplay were **not run** on the macOS development machine. Reports explicitly retain RuntimeTested=false. The checked-in preview has ValidatedFromDownloads=false.

Workshop authors can change files and compatibility after this review. The player profile fixes selected IDs/order/Workshop mappings, not an immutable Workshop revision. Refresh and retest after meaningful game/mod updates.
