# Mod list changes — 11 October 2026

Historical comparison against the original 114-mod list, preserved in `history/requested-mods-original.txt`. The supplied new `default.txt` and `ModFolders.cfg` exports are preserved under `inputs/`. The downloader was subsequently updated to the new list; see `COMPATIBILITY.md` for its current selection.

## Enabled mod comparison

| Change | Count |
| --- | ---: |
| Previous requested mod IDs | 114 |
| New enabled mod IDs | 294 |
| Added | 183 |
| Removed | 3 |
| Retained | 111 |
| Duplicate IDs in new list | 0 |

Counts refer to mod IDs, including submods, rather than unique Steam Workshop items. Workshop mappings were researched later in the compatibility review; this comparison records only the changes between supplied lists.

## Removed mods

| Mod ID | Previous position |
| --- | ---: |
| `JustHideDebugMenu` | 46 |
| `TacHoldFork` | 88 |
| `TacHold Complete` | 89 |

`HideDebugMenu` is newly added while `JustHideDebugMenu` was removed. Their names suggest a replacement, but these files alone do not establish that they are the same mod or a rename.

## Order changes

All 111 retained IDs keep exactly the same relative order. All 183 new IDs are appended after `P4AddictedToWeight`: positions 112–294, starting with `SWMG` and ending with `Improved_Blood_Ffects`. Removing the three old IDs shifts some position numbers but does not reorder the retained mods.

This describes the supplied order. Dependency order and multiplayer compatibility for the additions have not been validated.

## Folder information

The supplied `ModFolders.cfg` defines 11 top-level folders and 295 unique membership entries. Every one of the 294 enabled IDs is assigned to a folder. `PZ_Optimization` is assigned to `Optimisation` but is absent from the new enabled list.

The previous repository copy of `ModFolders.cfg` was removed earlier, so a comparison of old and new folder assignments is unavailable. The categories below come from the supplied new file.

| Folder | New additions | Total enabled in new list |
| --- | ---: | ---: |
| Framework | 4 | 7 |
| Optimisation | 0 | 1 |
| UI | 10 | 42 |
| Map | 1 | 3 |
| Weapon | 6 | 10 |
| Vehicles | 131 | 141 |
| Food | 0 | 3 |
| Clothing | 7 | 14 |
| Realistic | 17 | 64 |
| Fixes | 0 | 2 |
| Character | 7 | 7 |

The new `default.txt` has `VERSION = 1` and an empty `maps` section.

## Effect on the existing downloader

At the time this comparison was created, the downloader still used the original 114 entries. It has since been updated to all 294 requested entries, with conservative multiplayer exclusions described in `COMPATIBILITY.md`.

The supplied list retains `Buttstroke` and `SPNCCDetailsHD`, both disabled in the earlier recommended profile. The updated profile re-enables Buttstroke now that Tactical Hold was removed, and keeps HD details disabled for the chosen vanilla 256 texture preset.

## All 183 additions

IDs are listed below in their new relative order within each folder. Positions refer to the enabled list in the supplied `default.txt`.

### Framework — 4 added

- `SWMG` (position 112)
- `HBVCEFb42` (position 115)
- `damnlib` (position 119)
- `UnifiedCarryWeightFramework` (position 246)

### UI — 10 added

- `ContainerCapacityIndicator` (position 233)
- `GenRange` (position 237)
- `HideDebugMenu` (position 238)
- `MinimalHotbar` (position 242)
- `MoodleFramework` (position 243)
- `MutiesContextMenuIcons` (position 248)
- `MutiesContextMenuIconsStorage42` (position 249)
- `MutiesContextMenuIconsExpanded42` (position 250)
- `MutiesContextMenuIconsRedrawn42` (position 251)
- `Briefing` (position 288)

### Map — 1 added

- `MapLegendUI` (position 241)

### Weapon — 6 added

- `GunsOfMarz` (position 113)
- `HBAmmoCraft` (position 114)
- `HBTacReload` (position 116)
- `MarzVanillaGuns` (position 117)
- `LowConditionGuns` (position 240)
- `ReloadAllMagazines` (position 258)

### Vehicles — 131 added

- `04vwTouran` (position 118)
- `49powerWagon` (position 120)
- `59meteor` (position 121)
- `ECTO1` (position 122)
- `62daimlerFerret` (position 123)
- `63beetle` (position 124)
- `63Type2Van` (position 125)
- `65banshee` (position 126)
- `66pontiacLeMans` (position 127)
- `67commando` (position 128)
- `67gt500` (position 129)
- `68firebird` (position 130)
- `69charger` (position 131)
- `69fordMustang` (position 132)
- `69camaro` (position 133)
- `69fordMustangExtra` (position 134)
- `69mini` (position 135)
- `69mini_ItalianJob` (position 136)
- `69mini_MrBean` (position 137)
- `69mini_PitbullSpecial` (position 138)
- `70chevelle` (position 139)
- `70dodge` (position 140)
- `70fordEscort` (position 141)
- `70barracuda` (position 142)
- `70roadRunner` (position 143)
- `73fordFalcon` (position 144)
- `73fordFalconPS` (position 145)
- `73nissanGTR` (position 146)
- `75grandPrix` (position 147)
- `76chevyKseriesExpanded` (position 148)
- `76chevyKseries` (position 149)
- `77firebird` (position 150)
- `76chryslerNewYorker` (position 151)
- `78amgeneralM35A2` (position 152)
- `78amgeneralM35A2extra` (position 153)
- `78amgeneralM49A2C` (position 154)
- `78amgeneralM50A3` (position 155)
- `78amgeneralM62` (position 156)
- `79camaro` (position 157)
- `80manKat1` (position 158)
- `81deloreanDMC12` (position 159)
- `81deloreanDMC12BTTF` (position 160)
- `82jeepJ10` (position 161)
- `82jeepJ10t` (position 162)
- `82oshkoshM911` (position 163)
- `82firebird` (position 164)
- `82firebirdKITT` (position 165)
- `82porsche911` (position 166)
- `83amgeneralM923` (position 167)
- `83amgeneralM923extra` (position 168)
- `83gmcGseriesVans` (position 169)
- `83gmcVanduraATeam` (position 170)
- `84buickElectra` (position 171)
- `84cadillacDeVille` (position 172)
- `84gageV300` (position 173)
- `84corvette` (position 174)
- `84merc` (position 175)
- `84jeepXJ` (position 176)
- `84oldsmobile98` (position 177)
- `85buickLeSabre` (position 178)
- `85chevyCaprice` (position 179)
- `85chevyStepVan` (position 180)
- `85chevyStepVanexpanded` (position 181)
- `85oldsmobileDelta88` (position 182)
- `85pontiacParisienne` (position 183)
- `86chevyCUCV` (position 184)
- `86fordE150` (position 185)
- `86fordE150expanded` (position 186)
- `86fordE150dnd` (position 187)
- `86fordE150mm` (position 188)
- `86fordE150pd` (position 189)
- `86oshkoshP19A` (position 190)
- `87buickRegal` (position 191)
- `87chevySuburban` (position 192)
- `87fordB700` (position 193)
- `87toyotaCorolla` (position 194)
- `87toyotaMR2` (position 195)
- `88chevyS10` (position 196)
- `88toyotaHilux` (position 197)
- `89dodgeCaravan` (position 198)
- `89fordBronco` (position 199)
- `89trooper` (position 200)
- `89defender` (position 201)
- `89volvo200` (position 202)
- `90bmwE30` (position 203)
- `90fordF350ambulance` (position 204)
- `90pierceArrow` (position 205)
- `91fordLTD` (position 206)
- `91fordRanger` (position 207)
- `91geoMetro` (position 208)
- `91lexusLS400` (position 209)
- `91nissan240sx` (position 210)
- `91range` (position 211)
- `92amgeneralM998` (position 212)
- `92amgeneralM998extra` (position 213)
- `92fordCVPI` (position 214)
- `92jeepYJ` (position 215)
- `92jeepYJJP18` (position 216)
- `92nissanGTR` (position 217)
- `92vwGolfMk2` (position 218)
- `93chevySuburban` (position 219)
- `93chevySuburbanExpanded` (position 220)
- `93fordElgin` (position 221)
- `93fordF350` (position 222)
- `93mustangSSP` (position 223)
- `93fordTaurus` (position 224)
- `93townCar` (position 225)
- `95impreza` (position 226)
- `96lancerEVO` (position 227)
- `96saturnSseries` (position 228)
- `98stagea` (position 229)
- `97bushmaster` (position 230)
- `99fordCVPI` (position 231)
- `close-the-trunk` (position 232)
- `isoContainers` (position 234)
- `KI5campers` (position 239)
- `NepEngineColor` (position 252)
- `NepBatteryColor` (position 253)
- `NepHighBeams` (position 254)
- `OffroadGoBrrr` (position 255)
- `PushVehicle` (position 256)
- `YAPZLib` (position 262)
- `VMZNEW` (position 263)
- `VVR` (position 264)
- `SpecLoot` (position 265)
- `KI5minifixes` (position 266)
- `KI5trailers` (position 271)
- `VSUIKI5` (position 281)
- `WorkingSeatbelt` (position 282)
- `YouDriveISleep` (position 283)
- `CrashedCarsMod` (position 293)

### Clothing — 7 added

- `TombBody` (position 274)
- `TombBodyCompat` (position 275)
- `TombBodyCompatBootsExp` (position 276)
- `SM4BootsExpandedB42` (position 277)
- `TombBodyCompatBootsExpVanilla` (position 278)
- `SM4BootsExpandedB42VanillaONLY` (position 279)
- `VanillaGearExpanded` (position 280)

### Realistic — 17 added

- `AatheomEMVFSM` (position 235)
- `FWOBenchPressTreadmill` (position 236)
- `1299328280/ToadTraitsDynamic` (position 244)
- `1299328280/ToadTraits` (position 245)
- `CP_MoreTraits` (position 247)
- `RainingZombies` (position 257)
- `J93RunningBloodPools` (position 259)
- `SmokingSoundsOverhaul` (position 260)
- `SomewhatWater` (position 261)
- `TrueSleep` (position 272)
- `TrueSmoking` (position 273)
- `ZombiesTargetAnimals` (position 284)
- `ADRENALINE_MOD` (position 285)
- `ZombieDismembermentB42` (position 286)
- `KAMER_RepairWall` (position 289)
- `KAMER_WallHealth` (position 290)
- `Improved_Blood_Ffects` (position 294)

### Character — 7 added

- `SPNCCFaces` (position 267)
- `SPNRetextureCustom` (position 268)
- `SPNRetextureZombieUnderwear` (position 269)
- `SpnHairAPI` (position 270)
- `YakiHRB42` (position 287)
- `SpnHair` (position 291)
- `FH` (position 292)
