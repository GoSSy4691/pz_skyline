# Build 42.21.0: newly requested non-vehicle mods

Checked 2026-10-11. The 52 new entries map to **43 original Workshop items**. Each item was read through Steam's public `ISteamRemoteStorage/GetPublishedFileDetails` API and returned success for Project Zomboid, app 108600. Mod IDs were also checked against their authors' descriptions. This establishes item identity and published requirements; it does **not** establish that the complete server pack has been tested in game.

`research/nonvehicles.json` contains all 52 mappings, source links, dependency/order edges, recommended omissions, and evidence status. `MultiplayerEnabled` is the recommended default selection, not an unconditional compatibility certificate. `RuntimeMultiplayerTested` is false for every entry.

## Problems that cannot be solved just by changing load order

- **GunsOfMarz and MarzVanillaGuns:** the Guns of Marz author explicitly says not to use Vanilla Weapons Plus alongside it. Keep GunsOfMarz and omit the competing pack. Author family order is **HBVCEFb42 → SWMG → GunsOfMarz**. Hot Brass is an optional integration; Gunworks is required. [Author's Guns of Marz page](https://steamcommunity.com/sharedfiles/filedetails/?id=3722134990).
- **GenRange and BetterGeneratorInfo:** BetterGeneratorInfo already contains the generator range display; its author states that other generator range/fuel information mods cannot run with it. Omit GenRange. [BetterGeneratorInfo author comments](https://steamcommunity.com/sharedfiles/filedetails/?id=3576056135&l=greek).
- **Both Boots Expanded variants and both Tomb footwear patches:** select the full Boots Expanded module and its matching full Tomb patch; omit the vanilla-only pair. These are alternative variants of the same clothing/shoe replacements. The Boots author also warns about other shoe replacements. The matching Tomb patches must load below affected clothing. [Boots Expanded](https://steamcommunity.com/sharedfiles/filedetails/?id=2850935956), [Tomb compatibility](https://steamcommunity.com/sharedfiles/filedetails/?id=3431734923).
- **SPNRetextureCustom with TombBody:** Spongie's player retexture explicitly excludes Tomb's body layout. The new list also has no human Spongie texture variant. Omit this player-texture addon. The author acknowledged accidental Tomb exclusions on zombie variants, but current downloaded exclusions are still unverified; omit SPNRetextureZombieUnderwear pending that check instead of rewriting mod metadata. [Spongie's retexture](https://steamcommunity.com/sharedfiles/filedetails/?id=3340255334).

## Body, face and texture choice

TombBody contains models **without textures** and can use vanilla textures. Keeping the requested vanilla SPNCCFaces therefore calls for vanilla 256 textures and omission of existing SPNCCDetailsHD. The optional TombBodyTex 512 texture and TombBodyCustom heads form a different valid choice, but require removing vanilla faces; they are not mandatory dependencies and are not silently added here. Models require main-menu enablement and a complete client restart. [Tomb author instructions](https://steamcommunity.com/sharedfiles/filedetails/?id=3429790870), [Spongie face/HD instructions](https://steamcommunity.com/sharedfiles/filedetails/?id=3414634809).

Spongie's published face-pack [mod.info source](https://github.com/LazySpongie/SpongieCharacterCustomisation/blob/main/Contents/mods/SpongieCharacterCustomisation%20-%20Vanilla%20Faces%20Pack/42.13/mod.info) explicitly excludes Tomb texture/head variants. That public source is an older 42.13 metadata branch and is supporting evidence, not a substitute for checking the currently downloaded 42.21 files.

## Unsupported or experimental multiplayer features

- **RainingZombies:** the author recommends singleplayer because its local physics may desynchronize multiplayer. [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3763651059).
- **ZombiesTargetAnimals:** multiplayer is explicitly alpha; some feeding and herd-defense features remain singleplayer-only. [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3774007514).
- **ZombieDismembermentB42:** specifically targets 42.21, but MP is experimental and the author states no live multiplayer/dedicated session has been tested. Persistent cuts after unload/restart remain unverified. [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=3811483602).
- **ADRENALINE_MOD:** discontinued; the author says its panic-driven mechanic currently does nothing in B42 multiplayer. [Author](https://steamcommunity.com/sharedfiles/filedetails/?id=2807001835).
- **More Traits base/dynamic and CP_MoreTraits:** the original is now unsupported legacy and lists a Martial Artist player-death synchronization problem. Dynamic is an addon, not an alternative to the base, and its dependency must precede it. ComputerPers is an older override that cannot establish current compatibility. Hold these three out of the conservative profile; no replacement trait system is automatically installed. [Original author](https://steamcommunity.com/sharedfiles/filedetails/?id=1299328280), [ComputerPers patch](https://steamcommunity.com/sharedfiles/filedetails/?id=3587315482).

These omissions are recommendations for this user's request to minimize errors. Alpha or legacy status alone is not proof that every feature always fails.

## Context menus and hotbar

The original Mutie icon mod explicitly remains untested on Build 42 stable. The three expansion modules are archived, and their author redirects users to a new item. Hold the four requested legacy icon modules out pending a game test. **Expanded and Redrawn are not mutually exclusive:** their author allows both; Storage is required, with order Storage → Expanded → Redrawn. Original Mutie is optional. [Original Mutie](https://steamcommunity.com/sharedfiles/filedetails/?id=3101668503), [Extension author's instructions](https://steamcommunity.com/sharedfiles/filedetails/?id=3422112160).

Load All Magazines replaces the magazine context-menu function. Guns of Marz explicitly integrates it; unrelated replacements still need testing. This also motivates caution around archived menu-hook addons. [Load All Magazines](https://steamcommunity.com/sharedfiles/filedetails/?id=2920899878).

**CleanHotBar and MinimalHotbar can coexist:** MinimalHotbar's author says to load it at the end for CleanHotBar compatibility. Load it after CleanHotBar and item-condition UI. [MinimalHotbar](https://steamcommunity.com/sharedfiles/filedetails/?id=3688576740).

## Already present dependencies and setup requirements

- TrueSmoking requires MoodleFramework and StarlitLibrary, both present. Use the original author item 3423984426; the different MP-fixed item 3803208661 reuses the same internal ID and must not be installed alongside the original. Existing NoLighterNeeded/SmokingSoundsOverhaul integrations are listed by the original. [True Smoking author](https://steamcommunity.com/sharedfiles/filedetails/?id=3423984426), [Smoking Sounds author](https://steamcommunity.com/sharedfiles/filedetails/?id=2857762294).
- MoodleFramework 2.7 changed its interface. The optional author bridge is for consumers that have not updated; its author warns that MP inconsistencies are possible. It is not automatically required for every mod. Validate TrueSmoking's moodles on the actual server. [Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3396446795), [Author's backward bridge](https://steamcommunity.com/sharedfiles/filedetails/?id=3789490511).
- SpnHair requires FH enabled on the server. Both are requested. Improved Hair Menu is recommended, not required; if installed, it must precede SpnHairAPI. [Spongie's Hair](https://steamcommunity.com/sharedfiles/filedetails/?id=2463184726), [Hairstyle Unlocker](https://steamcommunity.com/sharedfiles/filedetails/?id=3041733782).
- KAMER_RepairWall requires KAMER_WallHealth in multiplayer. Both are requested, and the author has updated the original items for 42.21. Respect downloaded version limits instead of altering them. [Repair Wall](https://steamcommunity.com/sharedfiles/filedetails/?id=3006882690), [Wall Health](https://steamcommunity.com/sharedfiles/filedetails/?id=3002666175).
- TrueSleep requires server `SleepAllowed=true` **and** `SleepNeeded=true`. The author's recommended `FastForwardMultiplier=5` is optional tuning, not a hard requirement. [True Sleep](https://steamcommunity.com/sharedfiles/filedetails/?id=3781533687).
- Hot Brass AmmoCraft does not yet claim recipes for every Guns of Marz ammo type. Do not promise that its crafting covers the entire gun pack or install an unrequested ammo mod as a presumed mandatory dependency. [Hot Brass author](https://steamcommunity.com/sharedfiles/filedetails/?id=3610677934).

No hard additional Workshop dependency missing from these 52 newly added entries subset was identified in published author requirements. Further requirements from current downloaded `mod.info` files must be resolved before profile creation; optional recommendations should not be confused with required items.

## Supported pairs and limits

Blood Pools' author explicitly supports RainCleansBlood and blood retextures; the requested Improved Blood Effects fits that category. Validate performance with large hordes. [Blood Pools](https://steamcommunity.com/sharedfiles/filedetails/?id=3784951301).

Workout and its treadmill/benchpress module can run together or separately; one is not a hard dependency of the other. [Workout author](https://steamcommunity.com/sharedfiles/filedetails/?id=2940354599).

Yaki's hair retexture explicitly supports FH. Its stated incompatible Yaki Hair Salon alternative is absent from the requested list. [Yaki author](https://steamcommunity.com/sharedfiles/filedetails/?id=2787539183).

The full pack still needs a temporary 42.21.0 multiplayer server, two real clients, gameplay checks, and server/client logs: joining/rejoining, firearms/reloads, trait creation, sleep/waking, body/clothing/hats, generators, crafting, animals, vehicle interactions, and saving/restart. Published support and a topological load order cannot prove every interaction among 294 mods.

## Required-items sidebar follow-up

The follow-up audit in `research/extra-nonvehicle-dependencies.json` read required-item sidebars for 39 of the 43 new Workshop items. Four pages were inaccessible or content-gated; their original descriptions remain API-verified, and their required-item sidebar status is explicitly unresolved. Retained TrueWeight and VanillaOutfitsExpanded also have no current required-item block. No additional mandatory dependency was identified.

SpnHair lists four Workshop recommendations, including the absent Improved Hair Menu. However, the author's [native 42.0 metadata](https://raw.githubusercontent.com/LazySpongie/SpongieHair/main/Contents/mods/Spongie%20Hair/42.0/mod.info) declares only FH as required, and [Hairstyle Unlocker's 42.18 metadata](https://raw.githubusercontent.com/LazySpongie/SpongieHairAPI/main/Contents/mods/Spongie%20Hairstyle%20Unlocker/42.18/mod.info) declares only an order edge after that optional menu. Its exact mapping is supplied as inactive support metadata, without inventing a hard requirement.

The [primary bytecode-inspection guide](https://steamcommunity.com/sharedfiles/filedetails/?id=3776551449&l=vietnamese) reports that native mod metadata uses the chosen version's entire `mod.info`, falling back to `common/mod.info` only when the former is absent. It also reports that version-folder matching compares major/minor and ignores patch numbers. That source explicitly verifies 42.20; it does not certify the exact 42.21 bytecode. Current author sources support the dependency/order keys, while an exact game-loader claim still needs local game-file inspection.
