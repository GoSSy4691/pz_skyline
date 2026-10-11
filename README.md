# Project Zomboid 42.21.0 mod setup

**On Windows, extract the project folder and double-click `Start-PZModSetup.cmd`.** Choose **Player** or **Server owner**, then **Download/update**. The menu guides you through locations, Steam sign-in, the selected mods, and any remaining game steps. No PowerShell commands are needed for normal setup.

The supplied new list contains **294 requested mod IDs**. The default multiplayer profile selects **260** and holds back **34** with visible reasons. It downloads **224 unique Workshop items** for that selection; all requested IDs map to 249 items. Incompatible variants, abandoned mods, uncertain multiplayer features, and redundant additions are retained in the catalog for review. They are not downloaded unless their Workshop package also supplies a selected mod. See [COMPATIBILITY.md](COMPATIBILITY.md) for every exclusion and the remaining limitations.

This is a setup and metadata validation tool. It has **not** been tested by running your Windows server or joining it. A source review and a dependency order cannot establish error-free gameplay for this entire pack.

## Server owner: normal setup

1. Install your Project Zomboid **42.21.0** server and create its settings once through the game or server. Stop the server.
2. Double-click `Start-PZModSetup.cmd` and choose **Server owner → Download/update**. Accept `42.21.0` as the target build.
3. Choose the server installation folder containing `steamapps`, or a separate download folder. Sign in when SteamCMD prompts; use an account owning Project Zomboid if anonymous access is denied.
4. Select the server's existing INI. The tool backs it up and applies `Mods=`, `WorkshopItems=`, and required sleep settings. Choosing **Generate settings only** instead means you must apply the generated lines yourself.
5. Restart your server with a **fresh test world**, join with two players, and complete the checks in [COMPATIBILITY.md](COMPATIBILITY.md). Once satisfied, share `output\player-setup.zip` with players.

The player ZIP is prepared automatically after metadata checks and any selected INI update succeed. It includes the launcher, scripts, native Steam bridge source, matching catalog, exact ordered `server-profile.json`, and instructions. You do not need to assemble those files manually. Files from a failed run must not be distributed; check `output\run-status.json`.

SteamCMD is installed automatically from [Valve's installer](https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip) when needed. SteamCMD asks for the password and Steam Guard code itself. Passwords are not stored in this project. This tool downloads mods; it does not install/start the server game or configure your network.

## Player: normal setup

1. Install Steam and Project Zomboid **42.21.0**, matching the server. Open Steam and sign in. Close the game.
2. Extract **all** files from the owner's `player-setup.zip` into a folder.
3. Double-click `Start-PZModSetup.cmd`, choose **Player → Download/update**, and use the included server profile when offered.
4. After setup, launch Project Zomboid. The matching main-menu mod profile is already installed. Verify its body/hair/clothing mods are enabled; fully exit and restart if the game asks, then join the server.

Client mode subscribes/downloads using the running Steam app and the game's installed `steam_api64.dll`, through [Valve's Workshop API](https://partner.steamgames.com/doc/api/ISteamUGC). No Steam SDK DLL is bundled. The launcher selects 64-bit Windows PowerShell and uses a process-only execution-policy override; administrator privileges are not normally required.

Existing subscriptions and downloaded mods are kept. After validation, only the chosen server mods are written to `%USERPROFILE%\Zomboid\mods\default.txt`, with an existing profile backed up beside it. Existing single-player saves retain their own settings. Joining a multiplayer server also uses the server's mod selection.

An old or manually installed copy can provide the **same mod ID** as a selected edition. Disablement in `default.txt` cannot distinguish such copies. In particular, users of the original pack must unsubscribe from old **Barricaded World 2696986935** and remove its remaining copy before using the selected continuation **3529472651**. Setup reports duplicates it finds before installing the client preset; it does not unsubscribe or delete mods for you.

The shared profile checks exact enabled IDs, Workshop mappings, build, and load order. It does not pin Workshop revisions or change the installed game version. After a Workshop update, update/restart the server and give players a fresh ZIP as needed.

## What is required beyond clicking the CMD?

No manual script editing is needed for the default selection when downloads and metadata checks succeed. You still need the correct game/server installed, matching builds, Steam authentication when prompted, a stopped game/server during setup, and a restart/join afterwards.

Some game-specific steps remain:

- **Fresh world:** the author of [DG_MIVehicles](https://steamcommunity.com/sharedfiles/filedetails/?id=3162566044) warns against enabling it on an existing world. [VVR](https://steamcommunity.com/sharedfiles/filedetails/?id=3423424077) can replace existing vanilla vehicle loot and needs vanilla vehicle spawning enabled.
- **Model initialization:** [Tomb's body](https://steamcommunity.com/sharedfiles/filedetails/?id=3429790870) and [Spongie's customization](https://steamcommunity.com/sharedfiles/filedetails/?id=3414634809) need main-menu enablement and a full restart after changes. Client setup installs the preset before you launch the game.
- **One-time notice:** if [Mini Health Panel's](https://steamcommunity.com/sharedfiles/filedetails/?id=2866258937) update notice cannot close with NeatUI, temporarily disable the UI mods, close the notice once, then restore the server preset and restart.
- **Old editions:** if setup reports two installed copies providing the same ID, remove the obsolete edition it identifies and rerun. This includes old Barricaded World for players migrating from the original pack.
- **Gameplay validation:** test the actual server and two clients before using the pack on the main world. Published support does not cover every combination of Lua scripts, models, networking, or sandbox choices.

TrueSleep's required `SleepAllowed=true` and `SleepNeeded=true` are handled automatically when you select an INI. [The author requires both in multiplayer](https://steamcommunity.com/sharedfiles/filedetails/?id=3781533687). Optional sandbox balance choices remain in the game's server settings. Checksum verification is retained.

## Selection and ordering

`requested-mods.txt` preserves all 294 IDs in supplied order; `inputs\default.txt` and `inputs\ModFolders.cfg` preserve the supplied exports as reference data. The input export enables conflicting variants and is **not** the recommended client preset. The 114-entry original is preserved in `history\requested-mods-original.txt`; its comparison remains in `mod-list-changes-2026-10-11.md`.

`mods.catalog.json` maps requested IDs to author Workshop sources and researched constraints. The default selection omits known conflicts and higher-risk optional features without replacing them with unrequested alternatives. **BarricadedWorld is the one transparent edition change:** the catalog uses the maintained Build 42 continuation, Workshop **3529472651**, whose author source confirms the same `BarricadedWorld` ID. Its former item, 2696986935, is recorded as `OriginalWorkshopId`. [Maintained author's page](https://steamcommunity.com/sharedfiles/filedetails/?id=3529472651), [author's B42 metadata](https://raw.githubusercontent.com/Terrahop/zomboid-barricadedworld/main/mod/42/mod.info).

Order is recomputed from current downloaded metadata and catalog edges. It puts required libraries before their dependents; Hot Brass before Gunworks before Guns of Marz; vehicle bases before expansions, loot and repair patches; and body compatibility patches below the clothing they affect. Clean HotBar is late, with MinimalHotbar after it as its author requests. Texture/depth fixes and weather overrides have explicit priorities/edges.

For each Workshop item the scanner selects the highest applicable numeric Build 42 directory by major/minor build, then checks full native version bounds. It rejects B41-only and future-only variants. Native `mod.info` fields come from the chosen version file, with common metadata as fallback. The scanner also reads the sorter's common `loadAfter`, `loadBefore`, and `incompatibleMods` fields. Category/global `loadFirst` and `loadLast` directives are not modeled; the game's sorter can still alter its own profile. Missing required IDs, duplicate providers, declared incompatibilities, build bounds, and cycles stop setup before the client preset or selected INI is changed. This models published B42 loader behavior; the exact 42.21.0 game loader has not been inspected here.

Held-back requested mods cannot be re-enabled silently by dependency expansion. Separately listed supported libraries in `Dependencies` can be enabled when required. A newly discovered mapped dependency is downloaded automatically; an unmapped/ambiguous dependency stops setup with its ID rather than inventing a Workshop mapping.

A folder's name/membership does not set load order. `ModFolders.cfg` is optional UI organization; no manual copy is needed for mods to load.

## Results and menu actions

| File | Purpose |
| --- | --- |
| `output\server-mods.ini` | Ordered Mods/WorkshopItems and required server option lines |
| `output\load-order.txt` | Final IDs in dependency order |
| `output\default.txt` | Matching client main-menu preset |
| `output\server-profile.json` | Exact metadata-checked selection/order to share |
| `output\player-setup.zip` | Complete player installer folder to distribute |
| `output\validation.json` | Actual IDs, metadata paths, exclusions, next steps, validation scope |
| `output\run-status.json` | Latest run outcome, applied INI flag, client install flag, ZIP path |
| `output\download-plan.csv` | Requested mappings and initial selection/download decisions |
| `output\logs\` | SteamCMD output and per-batch command files |

Client results normally go into `output\client\`. **Preview** uses `output\preview\server\` or `output\preview\client\`, makes no Steam/account/configuration changes, and writes filenames ending in `.preview`. **Use existing downloads** checks an existing Workshop `content\108600` directory and applies the same validation. An existing cache never hides a failed download/update.

`run-status.json` must say `validated` after a real successful scan; client mode must also say `ClientProfileInstalled: true`. `validated` means metadata and selection checks passed. Reports explicitly say **`RuntimeTested: false`**. Old files can remain after a failed run, so always check the latest status.

## Advanced commands

Normal users can stay in the menu. Advanced Windows PowerShell examples:

```powershell
# Server setup and automatic INI update
.\Download-PZMods.ps1 -Mode Server -BuildVersion 42.21.0 `
  -SteamUser YOUR_STEAM_LOGIN -SteamCmdDirectory "C:\PZServer" `
  -ServerIni "$env:USERPROFILE\Zomboid\Server\servertest.ini"

# Exact player setup from the owner's profile
.\Download-PZMods.ps1 -Mode Client -ServerProfile .\server-profile.json

# Preview without Steam or live configuration changes
.\Download-PZMods.ps1 -Mode Server -PlanOnly
```

For an unusual Steam location use `-GameDirectory "D:\SteamLibrary\steamapps\common\ProjectZomboid"`. For a custom PZ cache directory use `-ClientDataDirectory "D:\Zomboid"`. `-SkipDownload -WorkshopContentPath "D:\SteamLibrary\steamapps\workshop\content\108600"` checks existing downloads.

Server owners may use `-ExcludeMod ID`, or review the catalog to choose an alternative combination. `-Profile AllRequested` requests the full list and will reject its known conflicting combinations. Loading order cannot repair them. Client mode rejects local exclusions and AllRequested so clients do not diverge from the server profile.

`-AdditionalWorkshopId ID` can supply a newly identified dependency for a server scan. Only required submods are enabled automatically. Add a researched permanent mapping to the catalog before sharing a new player ZIP. With an exact client profile, additional Workshop IDs are rejected; dependencies must be selected on the server first.

## Offline verification

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Verify-PZMods.ps1
```

Checks cover the complete new catalog, selected order/variants, B42 folder selection and metadata fallback, common sorter fields, aliases, dependencies, conflicts/cycles/bounds, server backups and required settings, player ZIP contents and repeated replacement, shared profiles, installed Workshop/local duplicates, incomplete scan coverage, client retries/timeouts/stale caches, and menu previews/cancellation/error recovery. Fake Steam sessions and a fake SteamCMD process exercise download behavior without account changes.

The development machine is macOS. Real Windows double-click/file pickers, Steam DLL initialization/authentication/downloads, dedicated startup, two-client synchronization, and gameplay have not been run here. The checked-in `preview\` files are proposed order/mappings, not evidence of runtime success.
