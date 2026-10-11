# Launcher audit, 11 October 2026

Target: Windows users, Project Zomboid multiplayer, exact Build 42.21.0. This is source inspection; Windows Steam/SteamCMD downloads and live dedicated gameplay were not exercised on the macOS development machine.

Double-clicking `Start-PZModSetup.cmd` opens the role/action menus. The wrapper invokes the bundled script with an absolute path, Windows PowerShell 5.1, STA for the file picker, and a process-local execution-policy bypass. It selects Sysnative if a 32-bit shell needs the 64-bit host. Keep all scripts together and extract the ZIP before launching.

Players must already have Steam installed, running and signed in, the same game version as the server, and the game closed while changing the preset. Client downloads use Steam's client API. The default preset is backed up and replaced after metadata validation. Other subscriptions remain installed; they are not unsubscribed. Existing saves retain their own settings. Joining the server still happens in the game.

Owners must have the correct server game installed and stopped, select its existing INI or choose generated settings only, authenticate when SteamCMD asks, and restart the server afterwards. Generated settings only requires applying `server-mods.ini` manually. This tool does not install/start the server, change the Steam game version, configure network reachability, or choose sandbox options.

Distribute the generated `player-setup.zip` with the exact checked `server-profile.json`. Without that profile, players only match the default catalog selection; a customized server can differ. The shared profile requires downloaded IDs and active order to match.

The checks protect against missing B42 variants, declared build bounds, dependencies, duplicate active IDs, declared conflicts, and load-order cycles. Reports say runtime-tested=false. They cannot prove every Lua action, animation, synchronization path, balance combination, or performance condition. A fresh dedicated test world, two clients, reconnects and log review remain necessary.

Possible additional game steps identified by primary author sources:

- SPNCC and retextures need matching texture size and main-menu activation before joining; restart after retexture changes. Vanilla faces use 256; HD details need matching 512 body textures. [Author instructions](https://steamcommunity.com/sharedfiles/filedetails/?id=3414634809).
- DG_MIVehicles should not be added to an existing world because existing vehicle openings change. Set probabilities in sandbox options and test on a fresh world. [Author instructions](https://steamcommunity.com/sharedfiles/filedetails/?id=3162566044).
- Mini Health Panel's one-time update notice can be blocked by NeatUI. If affected, temporarily disable the UI mod, dismiss it once, restore the preset and restart. [Author troubleshooting](https://steamcommunity.com/sharedfiles/filedetails/?id=2866258937).

Implementation findings shared with root:

- Use active Workshop items plus required dependencies for the default download list; separate disabled/replaced sources can leave duplicate ModIds installed. Shared-profile downloads already use active items.
- Read custom common/mod.info rules separately from version game metadata. The sorter author names custom `loadAfter`, `loadBefore`, `incompatibleMods`, `loadFirst`, `loadLast`, and native version `loadModAfter`, `loadModBefore`, `incompatible`. Category first/last cannot safely be treated as global without category support. [Sorter author](https://steamcommunity.com/workshop/filedetails/discussion/3423660713/592888629473368243/).
- The guide author's direct loader inspection says version mod.info wins wholesale, with common metadata only as fallback. A common id, requirement or build bound must not be inherited when version metadata exists. Common sorter extensions can still be read separately. [Loader inspection](https://steamcommunity.com/sharedfiles/filedetails/?id=3776551449).
- Target-build input validates mod metadata; it does not inspect/change the installed game's Steam branch.
- Current CleanUI 42.21 author uses plain `Mods=NeatUI_Framework;CleanUI`; other B42 authors use leading backslashes. The official-forum loadAfter reproduction is not official proof that Mods= requires backslashes. [CleanUI author](https://steamcommunity.com/sharedfiles/filedetails/?id=3437629766), [forum reproduction](https://theindiestone.com/forums/topic/97781-title-manual-mod-load-order-mods-line-not-respected-in-dedicated-mp-servers-loadafter-required-as-a-workaround-build-4220/).
- Keep LuaChecksum enabled; old per-mod workarounds do not justify disabling it globally.

Final retained-pack recommendations are in `retained-audit.json`: the verified B42 BarricadedWorld continuation can transparently replace its older source; original EasyLaundry is held back pending downloaded proof and testing. UsefulBarrelsMP, ReactiveSE, PFHDTrueCargo and OverTheShoulder have author-declared incomplete or untested multiplayer paths. DynamicVehicleSnow is redundant with the author's recommended ImmersiveSnow, not a confirmed hard conflict.

## Final implementation follow-up

The downloader now selects active items plus required dependencies, uses native version metadata with common fallback, reads common `loadAfter`/`loadBefore`/`incompatibleMods`, prevents held-back requested mods from dependency auto-enablement, applies required sleep INI settings, and automatically exports a complete player ZIP after a chosen INI update succeeds. Category/global `loadFirst`/`loadLast` are explicitly outside its model.

Players migrating from original Barricaded World 2696986935 must remove that old edition before using continuation 3529472651; both expose the same ModId. Client setup checks other applicable B42 providers in its selected Workshop roots and local client mods folder before writing the preset. It retains unrelated subscriptions, reports the duplicate's ID/path, and changes no subscriptions/files during scanning. Inaccessible or malformed unrelated metadata produces an incomplete-coverage warning. Other Steam libraries and custom mod locations remain outside this scan.

106 offline checks passed on the macOS PowerShell runtime. They include client duplicate detection, preset preservation after failures, INI backups/required settings, profile and player-ZIP refresh on repeated runs, shared-profile matching, native callback structure sizes, and fake download retry behavior. This does not change the Windows/Steam/runtime testing limits above. The consolidated selection and acceptance steps are in [COMPATIBILITY.md](../COMPATIBILITY.md).
