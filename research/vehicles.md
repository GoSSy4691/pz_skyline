# New vehicle mod research

Target: Project Zomboid42.21.0 multiplayer. Checked2026-10-11. All131 requested vehicle IDs have Workshop mappings; two legacy optional IDs need downloaded metadata confirmation. This research is not a runtime compatibility certificate.

## Current issues and conservative exclusions

- `83amgeneralM923extra`: Legacy optional texture ID is absent from the current author Mod ID list; keep disabled until downloaded Build42.21 metadata verifies it. [Author Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=2811383142)
- `92amgeneralM998extra`: Legacy optional texture ID is absent from the current author Mod ID list; keep disabled until downloaded Build42.21 metadata verifies it. [Author Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=2642541073)
- `close-the-trunk`: Original author description only declares multiplayer support for Build41; Build42 multiplayer item loss reports exist. Hold back pending a Build42.21 dedicated-server test. [Author Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=3262467691)
- `NepEngineColor`: Author says this is now a vanilla Build42 feature, so it is redundant. [Author Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=2975204120)
- `NepBatteryColor`: Author says this is now a vanilla Build42 feature, so it is redundant. [Author Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=2973053380)
- `NepHighBeams`: Author states Build42.13 testing was singleplayer only; hold this optional lighting change back until Build42.21 multiplayer is tested. [Author Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=3438126404)
- `OffroadGoBrrr`: Author labels this Build41 and deprecated; Build42 implements the intended off-road behavior in the base game. [Author Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=3309119521)
- `KI5minifixes`: Current author acknowledged invalid KI5CamperJack recipe input and an update pending after KI5 updates; hold this optional patch back until the current Build42.21 package is tested. [Author Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=3740300378)
- `WorkingSeatbelt`: Author acknowledged a recent game update broke the mod and suggested disabling the chime or mod; a Build42.21 bug report is open. Hold back pending an author update/test. [Author Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=3055029361)
- `CrashedCarsMod`: Author labels this abandoned and says Build42 multiplayer support needs help. Build42 also requires a fresh save. [Author Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=1539281445)

## Order and dependencies

- Place `damnlib` and `YAPZLib` before their dependents. KI5 has tested the current library with the compatible vehicle set in singleplayer and multiplayer42.20+; this does not verify unrelated mods. [damnlib](https://steamcommunity.com/sharedfiles/filedetails/?id=3171167894)
- Place vehicle base modules before their optional variants/spawn modules. The submitted order has `76chevyKseriesExpanded` before its base and needs correction.
- Put `VSUIKI5`, `SpecLoot`, and optional `KI5minifixes` after all KI5 vehicles, including Campers and Trailers. These are explicit author requirements. [Seat UI](https://steamcommunity.com/sharedfiles/filedetails/?id=3501302358), [Specific Loot](https://steamcommunity.com/sharedfiles/filedetails/?id=3457132019), [Mini-fixes](https://steamcommunity.com/sharedfiles/filedetails/?id=3740300378)
- Put `VMZNEW` after vehicle additions to restrict military vehicles to military zones. It needs `YAPZLib`; existing saves apply spawn changes only in unexplored areas. [Vehicle Military Zones](https://steamcommunity.com/sharedfiles/filedetails/?id=3436499337)
- Put retained `VehicleRepairOverhaul` and `VehicleSalvageOverhaulB42` after the added vehicle definitions/patches. [Author instructions](https://steamcommunity.com/sharedfiles/filedetails/?id=2757712197)

## Other setup considerations

- `PushVehicle` currently explicitly targets42.21+ multiplayer. [Author page](https://steamcommunity.com/sharedfiles/filedetails/?id=3780639614)
- `VVR` replaces vanilla cars at spawn and warns that adding it to an existing save replaces their loot. Keep vanilla vehicle spawning enabled. Its `YAPZLib` requirement is already in the new list. [Author page](https://steamcommunity.com/sharedfiles/filedetails/?id=3423424077)
- Current `NepHighBeams` uses Lua and does not require manual Java installation. It is held back because the author only documents singleplayer testing. [Author page](https://steamcommunity.com/sharedfiles/filedetails/?id=3438126404)
- `YouDriveISleep` needs sleep allowed in server settings to provide useful passenger sleeping. [Author page](https://steamcommunity.com/sharedfiles/filedetails/?id=2830570280)
- Selected M49A2C/M50A3 tanker cargo functionality has an optional Build42.20 multiplayer addon, `AMGeneralTankerFunctionality`3790021065. It adds fuel/water transfers (Rubber Hose required), but is outside the requested294 and is not a declared hard vehicle dependency. It has not been automatically added. [Author addon page](https://steamcommunity.com/sharedfiles/filedetails/?id=3790021065)
- Public Steam HTML contains generic hidden/incompatible banner text even for visible supported items. Valve API reports public visibility/result1 and banned0 for these mapped packages; the generic banner was not used to classify them.

## Workshop mapping coverage

| Mod ID | Workshop ID | Default multiplayer profile |
| --- | --- | --- |
| `04vwTouran` | [3478633453](https://steamcommunity.com/sharedfiles/filedetails/?id=3478633453) | Enabled; requires runtime test |
| `49powerWagon` | [2900580391](https://steamcommunity.com/sharedfiles/filedetails/?id=2900580391) | Enabled; requires runtime test |
| `59meteor` | [2772575623](https://steamcommunity.com/sharedfiles/filedetails/?id=2772575623) | Enabled; requires runtime test |
| `ECTO1` | [2772575623](https://steamcommunity.com/sharedfiles/filedetails/?id=2772575623) | Enabled; requires runtime test |
| `62daimlerFerret` | [3787530735](https://steamcommunity.com/sharedfiles/filedetails/?id=3787530735) | Enabled; requires runtime test |
| `63beetle` | [3005903549](https://steamcommunity.com/sharedfiles/filedetails/?id=3005903549) | Enabled; requires runtime test |
| `63Type2Van` | [3041122351](https://steamcommunity.com/sharedfiles/filedetails/?id=3041122351) | Enabled; requires runtime test |
| `65banshee` | [3566868353](https://steamcommunity.com/sharedfiles/filedetails/?id=3566868353) | Enabled; requires runtime test |
| `66pontiacLeMans` | [3447272250](https://steamcommunity.com/sharedfiles/filedetails/?id=3447272250) | Enabled; requires runtime test |
| `67commando` | [2478247379](https://steamcommunity.com/sharedfiles/filedetails/?id=2478247379) | Enabled; requires runtime test |
| `67gt500` | [3026723485](https://steamcommunity.com/sharedfiles/filedetails/?id=3026723485) | Enabled; requires runtime test |
| `68firebird` | [3258343790](https://steamcommunity.com/sharedfiles/filedetails/?id=3258343790) | Enabled; requires runtime test |
| `69charger` | [3631989559](https://steamcommunity.com/sharedfiles/filedetails/?id=3631989559) | Enabled; requires runtime test |
| `69fordMustang` | [3756938756](https://steamcommunity.com/sharedfiles/filedetails/?id=3756938756) | Enabled; requires runtime test |
| `69camaro` | [2991201484](https://steamcommunity.com/sharedfiles/filedetails/?id=2991201484) | Enabled; requires runtime test |
| `69fordMustangExtra` | [3756938756](https://steamcommunity.com/sharedfiles/filedetails/?id=3756938756) | Enabled; requires runtime test |
| `69mini` | [2937786633](https://steamcommunity.com/sharedfiles/filedetails/?id=2937786633) | Enabled; requires runtime test |
| `69mini_ItalianJob` | [2937786633](https://steamcommunity.com/sharedfiles/filedetails/?id=2937786633) | Enabled; requires runtime test |
| `69mini_MrBean` | [2937786633](https://steamcommunity.com/sharedfiles/filedetails/?id=2937786633) | Enabled; requires runtime test |
| `69mini_PitbullSpecial` | [2937786633](https://steamcommunity.com/sharedfiles/filedetails/?id=2937786633) | Enabled; requires runtime test |
| `70chevelle` | [3766571591](https://steamcommunity.com/sharedfiles/filedetails/?id=3766571591) | Enabled; requires runtime test |
| `70dodge` | [2873290424](https://steamcommunity.com/sharedfiles/filedetails/?id=2873290424) | Enabled; requires runtime test |
| `70fordEscort` | [3670063857](https://steamcommunity.com/sharedfiles/filedetails/?id=3670063857) | Enabled; requires runtime test |
| `70barracuda` | [2913633066](https://steamcommunity.com/sharedfiles/filedetails/?id=2913633066) | Enabled; requires runtime test |
| `70roadRunner` | [3642935062](https://steamcommunity.com/sharedfiles/filedetails/?id=3642935062) | Enabled; requires runtime test |
| `73fordFalcon` | [3490370700](https://steamcommunity.com/sharedfiles/filedetails/?id=3490370700) | Enabled; requires runtime test |
| `73fordFalconPS` | [3490370700](https://steamcommunity.com/sharedfiles/filedetails/?id=3490370700) | Enabled; requires runtime test |
| `73nissanGTR` | [3743371090](https://steamcommunity.com/sharedfiles/filedetails/?id=3743371090) | Enabled; requires runtime test |
| `75grandPrix` | [3213391371](https://steamcommunity.com/sharedfiles/filedetails/?id=3213391371) | Enabled; requires runtime test |
| `76chevyKseriesExpanded` | [3161951724](https://steamcommunity.com/sharedfiles/filedetails/?id=3161951724) | Enabled; requires runtime test |
| `76chevyKseries` | [3161951724](https://steamcommunity.com/sharedfiles/filedetails/?id=3161951724) | Enabled; requires runtime test |
| `77firebird` | [3346905070](https://steamcommunity.com/sharedfiles/filedetails/?id=3346905070) | Enabled; requires runtime test |
| `76chryslerNewYorker` | [3730833846](https://steamcommunity.com/sharedfiles/filedetails/?id=3730833846) | Enabled; requires runtime test |
| `78amgeneralM35A2` | [2799152995](https://steamcommunity.com/sharedfiles/filedetails/?id=2799152995) | Enabled; requires runtime test |
| `78amgeneralM35A2extra` | [2799152995](https://steamcommunity.com/sharedfiles/filedetails/?id=2799152995) | Enabled; requires runtime test |
| `78amgeneralM49A2C` | [2799152995](https://steamcommunity.com/sharedfiles/filedetails/?id=2799152995) | Enabled; requires runtime test |
| `78amgeneralM50A3` | [2799152995](https://steamcommunity.com/sharedfiles/filedetails/?id=2799152995) | Enabled; requires runtime test |
| `78amgeneralM62` | [2799152995](https://steamcommunity.com/sharedfiles/filedetails/?id=2799152995) | Enabled; requires runtime test |
| `79camaro` | [3703948448](https://steamcommunity.com/sharedfiles/filedetails/?id=3703948448) | Enabled; requires runtime test |
| `80manKat1` | [3248388837](https://steamcommunity.com/sharedfiles/filedetails/?id=3248388837) | Enabled; requires runtime test |
| `81deloreanDMC12` | [3253385114](https://steamcommunity.com/sharedfiles/filedetails/?id=3253385114) | Enabled; requires runtime test |
| `81deloreanDMC12BTTF` | [3253385114](https://steamcommunity.com/sharedfiles/filedetails/?id=3253385114) | Enabled; requires runtime test |
| `82jeepJ10` | [2886832257](https://steamcommunity.com/sharedfiles/filedetails/?id=2886832257) | Enabled; requires runtime test |
| `82jeepJ10t` | [2886832257](https://steamcommunity.com/sharedfiles/filedetails/?id=2886832257) | Enabled; requires runtime test |
| `82oshkoshM911` | [2618213077](https://steamcommunity.com/sharedfiles/filedetails/?id=2618213077) | Enabled; requires runtime test |
| `82firebird` | [3320947974](https://steamcommunity.com/sharedfiles/filedetails/?id=3320947974) | Enabled; requires runtime test |
| `82firebirdKITT` | [3320947974](https://steamcommunity.com/sharedfiles/filedetails/?id=3320947974) | Enabled; requires runtime test |
| `82porsche911` | [3379334330](https://steamcommunity.com/sharedfiles/filedetails/?id=3379334330) | Enabled; requires runtime test |
| `83amgeneralM923` | [2811383142](https://steamcommunity.com/sharedfiles/filedetails/?id=2811383142) | Enabled; requires runtime test |
| `83amgeneralM923extra` | [2811383142](https://steamcommunity.com/sharedfiles/filedetails/?id=2811383142) | Held back |
| `83gmcGseriesVans` | [3799732653](https://steamcommunity.com/sharedfiles/filedetails/?id=3799732653) | Enabled; requires runtime test |
| `83gmcVanduraATeam` | [3799732653](https://steamcommunity.com/sharedfiles/filedetails/?id=3799732653) | Enabled; requires runtime test |
| `84buickElectra` | [3596903773](https://steamcommunity.com/sharedfiles/filedetails/?id=3596903773) | Enabled; requires runtime test |
| `84cadillacDeVille` | [3592777775](https://steamcommunity.com/sharedfiles/filedetails/?id=3592777775) | Enabled; requires runtime test |
| `84gageV300` | [3171184800](https://steamcommunity.com/sharedfiles/filedetails/?id=3171184800) | Enabled; requires runtime test |
| `84corvette` | [3684254299](https://steamcommunity.com/sharedfiles/filedetails/?id=3684254299) | Enabled; requires runtime test |
| `84merc` | [2805630347](https://steamcommunity.com/sharedfiles/filedetails/?id=2805630347) | Enabled; requires runtime test |
| `84jeepXJ` | [3409287192](https://steamcommunity.com/sharedfiles/filedetails/?id=3409287192) | Enabled; requires runtime test |
| `84oldsmobile98` | [3601417745](https://steamcommunity.com/sharedfiles/filedetails/?id=3601417745) | Enabled; requires runtime test |
| `85buickLeSabre` | [3418252689](https://steamcommunity.com/sharedfiles/filedetails/?id=3418252689) | Enabled; requires runtime test |
| `85chevyCaprice` | [3413704851](https://steamcommunity.com/sharedfiles/filedetails/?id=3413704851) | Enabled; requires runtime test |
| `85chevyStepVan` | [3614034284](https://steamcommunity.com/sharedfiles/filedetails/?id=3614034284) | Enabled; requires runtime test |
| `85chevyStepVanexpanded` | [3614034284](https://steamcommunity.com/sharedfiles/filedetails/?id=3614034284) | Enabled; requires runtime test |
| `85oldsmobileDelta88` | [3418253716](https://steamcommunity.com/sharedfiles/filedetails/?id=3418253716) | Enabled; requires runtime test |
| `85pontiacParisienne` | [3413706334](https://steamcommunity.com/sharedfiles/filedetails/?id=3413706334) | Enabled; requires runtime test |
| `86chevyCUCV` | [3428008364](https://steamcommunity.com/sharedfiles/filedetails/?id=3428008364) | Enabled; requires runtime test |
| `86fordE150` | [2870394916](https://steamcommunity.com/sharedfiles/filedetails/?id=2870394916) | Enabled; requires runtime test |
| `86fordE150expanded` | [2870394916](https://steamcommunity.com/sharedfiles/filedetails/?id=2870394916) | Enabled; requires runtime test |
| `86fordE150dnd` | [2870394916](https://steamcommunity.com/sharedfiles/filedetails/?id=2870394916) | Enabled; requires runtime test |
| `86fordE150mm` | [2870394916](https://steamcommunity.com/sharedfiles/filedetails/?id=2870394916) | Enabled; requires runtime test |
| `86fordE150pd` | [2870394916](https://steamcommunity.com/sharedfiles/filedetails/?id=2870394916) | Enabled; requires runtime test |
| `86oshkoshP19A` | [2566953935](https://steamcommunity.com/sharedfiles/filedetails/?id=2566953935) | Enabled; requires runtime test |
| `87buickRegal` | [3226885926](https://steamcommunity.com/sharedfiles/filedetails/?id=3226885926) | Enabled; requires runtime test |
| `87chevySuburban` | [3196180339](https://steamcommunity.com/sharedfiles/filedetails/?id=3196180339) | Enabled; requires runtime test |
| `87fordB700` | [3110911330](https://steamcommunity.com/sharedfiles/filedetails/?id=3110911330) | Enabled; requires runtime test |
| `87toyotaCorolla` | [3779315249](https://steamcommunity.com/sharedfiles/filedetails/?id=3779315249) | Enabled; requires runtime test |
| `87toyotaMR2` | [3052360250](https://steamcommunity.com/sharedfiles/filedetails/?id=3052360250) | Enabled; requires runtime test |
| `88chevyS10` | [2886832936](https://steamcommunity.com/sharedfiles/filedetails/?id=2886832936) | Enabled; requires runtime test |
| `88toyotaHilux` | [3435796523](https://steamcommunity.com/sharedfiles/filedetails/?id=3435796523) | Enabled; requires runtime test |
| `89dodgeCaravan` | [3034636011](https://steamcommunity.com/sharedfiles/filedetails/?id=3034636011) | Enabled; requires runtime test |
| `89fordBronco` | [2886833398](https://steamcommunity.com/sharedfiles/filedetails/?id=2886833398) | Enabled; requires runtime test |
| `89trooper` | [2932549988](https://steamcommunity.com/sharedfiles/filedetails/?id=2932549988) | Enabled; requires runtime test |
| `89defender` | [3570973322](https://steamcommunity.com/sharedfiles/filedetails/?id=3570973322) | Enabled; requires runtime test |
| `89volvo200` | [3292659291](https://steamcommunity.com/sharedfiles/filedetails/?id=3292659291) | Enabled; requires runtime test |
| `90bmwE30` | [3110913021](https://steamcommunity.com/sharedfiles/filedetails/?id=3110913021) | Enabled; requires runtime test |
| `90fordF350ambulance` | [2952802178](https://steamcommunity.com/sharedfiles/filedetails/?id=2952802178) | Enabled; requires runtime test |
| `90pierceArrow` | [2942793445](https://steamcommunity.com/sharedfiles/filedetails/?id=2942793445) | Enabled; requires runtime test |
| `91fordLTD` | [3366300557](https://steamcommunity.com/sharedfiles/filedetails/?id=3366300557) | Enabled; requires runtime test |
| `91fordRanger` | [3539691958](https://steamcommunity.com/sharedfiles/filedetails/?id=3539691958) | Enabled; requires runtime test |
| `91geoMetro` | [3008795514](https://steamcommunity.com/sharedfiles/filedetails/?id=3008795514) | Enabled; requires runtime test |
| `91lexusLS400` | [3770890864](https://steamcommunity.com/sharedfiles/filedetails/?id=3770890864) | Enabled; requires runtime test |
| `91nissan240sx` | [3504401781](https://steamcommunity.com/sharedfiles/filedetails/?id=3504401781) | Enabled; requires runtime test |
| `91range` | [2409333430](https://steamcommunity.com/sharedfiles/filedetails/?id=2409333430) | Enabled; requires runtime test |
| `92amgeneralM998` | [2642541073](https://steamcommunity.com/sharedfiles/filedetails/?id=2642541073) | Enabled; requires runtime test |
| `92amgeneralM998extra` | [2642541073](https://steamcommunity.com/sharedfiles/filedetails/?id=2642541073) | Held back |
| `92fordCVPI` | [2962175696](https://steamcommunity.com/sharedfiles/filedetails/?id=2962175696) | Enabled; requires runtime test |
| `92jeepYJ` | [3287727378](https://steamcommunity.com/sharedfiles/filedetails/?id=3287727378) | Enabled; requires runtime test |
| `92jeepYJJP18` | [3287727378](https://steamcommunity.com/sharedfiles/filedetails/?id=3287727378) | Enabled; requires runtime test |
| `92nissanGTR` | [2846036306](https://steamcommunity.com/sharedfiles/filedetails/?id=2846036306) | Enabled; requires runtime test |
| `92vwGolfMk2` | [3812024929](https://steamcommunity.com/sharedfiles/filedetails/?id=3812024929) | Enabled; requires runtime test |
| `93chevySuburban` | [3152529790](https://steamcommunity.com/sharedfiles/filedetails/?id=3152529790) | Enabled; requires runtime test |
| `93chevySuburbanExpanded` | [3152529790](https://steamcommunity.com/sharedfiles/filedetails/?id=3152529790) | Enabled; requires runtime test |
| `93fordElgin` | [2969343830](https://steamcommunity.com/sharedfiles/filedetails/?id=2969343830) | Enabled; requires runtime test |
| `93fordF350` | [3073430075](https://steamcommunity.com/sharedfiles/filedetails/?id=3073430075) | Enabled; requires runtime test |
| `93mustangSSP` | [3001592312](https://steamcommunity.com/sharedfiles/filedetails/?id=3001592312) | Enabled; requires runtime test |
| `93fordTaurus` | [3088951320](https://steamcommunity.com/sharedfiles/filedetails/?id=3088951320) | Enabled; requires runtime test |
| `93townCar` | [2932547723](https://steamcommunity.com/sharedfiles/filedetails/?id=2932547723) | Enabled; requires runtime test |
| `95impreza` | [3647735736](https://steamcommunity.com/sharedfiles/filedetails/?id=3647735736) | Enabled; requires runtime test |
| `96lancerEVO` | [3647736504](https://steamcommunity.com/sharedfiles/filedetails/?id=3647736504) | Enabled; requires runtime test |
| `96saturnSseries` | [3679880253](https://steamcommunity.com/sharedfiles/filedetails/?id=3679880253) | Enabled; requires runtime test |
| `98stagea` | [3315443103](https://steamcommunity.com/sharedfiles/filedetails/?id=3315443103) | Enabled; requires runtime test |
| `97bushmaster` | [2897390033](https://steamcommunity.com/sharedfiles/filedetails/?id=2897390033) | Enabled; requires runtime test |
| `99fordCVPI` | [2971246021](https://steamcommunity.com/sharedfiles/filedetails/?id=2971246021) | Enabled; requires runtime test |
| `close-the-trunk` | [3262467691](https://steamcommunity.com/sharedfiles/filedetails/?id=3262467691) | Held back |
| `isoContainers` | [2625625421](https://steamcommunity.com/sharedfiles/filedetails/?id=2625625421) | Enabled; requires runtime test |
| `KI5campers` | [3670064951](https://steamcommunity.com/sharedfiles/filedetails/?id=3670064951) | Enabled; requires runtime test |
| `NepEngineColor` | [2975204120](https://steamcommunity.com/sharedfiles/filedetails/?id=2975204120) | Held back |
| `NepBatteryColor` | [2973053380](https://steamcommunity.com/sharedfiles/filedetails/?id=2973053380) | Held back |
| `NepHighBeams` | [3438126404](https://steamcommunity.com/sharedfiles/filedetails/?id=3438126404) | Held back |
| `OffroadGoBrrr` | [3309119521](https://steamcommunity.com/sharedfiles/filedetails/?id=3309119521) | Held back |
| `PushVehicle` | [3780639614](https://steamcommunity.com/sharedfiles/filedetails/?id=3780639614) | Enabled; requires runtime test |
| `YAPZLib` | [3624971238](https://steamcommunity.com/sharedfiles/filedetails/?id=3624971238) | Enabled; requires runtime test |
| `VMZNEW` | [3436499337](https://steamcommunity.com/sharedfiles/filedetails/?id=3436499337) | Enabled; requires runtime test |
| `VVR` | [3423424077](https://steamcommunity.com/sharedfiles/filedetails/?id=3423424077) | Enabled; requires runtime test |
| `SpecLoot` | [3457132019](https://steamcommunity.com/sharedfiles/filedetails/?id=3457132019) | Enabled; requires runtime test |
| `KI5minifixes` | [3740300378](https://steamcommunity.com/sharedfiles/filedetails/?id=3740300378) | Held back |
| `KI5trailers` | [3330403100](https://steamcommunity.com/sharedfiles/filedetails/?id=3330403100) | Enabled; requires runtime test |
| `VSUIKI5` | [3501302358](https://steamcommunity.com/sharedfiles/filedetails/?id=3501302358) | Enabled; requires runtime test |
| `WorkingSeatbelt` | [3055029361](https://steamcommunity.com/sharedfiles/filedetails/?id=3055029361) | Held back |
| `YouDriveISleep` | [2830570280](https://steamcommunity.com/sharedfiles/filedetails/?id=2830570280) | Enabled; requires runtime test |
| `CrashedCarsMod` | [1539281445](https://steamcommunity.com/sharedfiles/filedetails/?id=1539281445) | Held back |
