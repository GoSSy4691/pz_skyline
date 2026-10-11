#Requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $root 'PZModTools.psm1') -Force -DisableNameChecking
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('pz-mod-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporary | Out-Null
$utf8 = [Text.UTF8Encoding]::new($false)
$script:checks = 0
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:checks++
}
function Assert-Throws {
    param([scriptblock]$Action, [string]$Pattern)
    $caught = $false
    try { & $Action | Out-Null } catch {
        if ($_.Exception.Message -notmatch $Pattern) { throw }
        $caught = $true
    }
    Assert-True $caught "Expected an error matching '$Pattern'."
}
function Write-Fixture {
    param([string]$RelativePath, [string]$Text)
    $path = Join-Path $temporary $RelativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    [IO.File]::WriteAllText($path, $Text, $utf8)
    return $path
}
function New-Entry {
    param([string]$Id, [string]$Workshop = '111', [int]$Priority = 100, [bool]$Enabled = $true)
    return [pscustomobject]@{ ModId = $Id; WorkshopId = $Workshop; Aliases = @(); Requires = @(); LoadAfter = @(); Priority = $Priority; MultiplayerEnabled = $Enabled; DisabledReason = 'fixture'; Notes = ''; Source = "https://steamcommunity.com/sharedfiles/filedetails/?id=$Workshop" }
}
function New-Record {
    param([string]$Id, [int]$Priority = 100, [string[]]$Requires = @(), [string[]]$After = @(), [string[]]$Before = @(), [string[]]$Incompatible = @())
    return [pscustomobject]@{ Entry = (New-Entry $Id -Priority $Priority); Index = $Priority; Metadata = [pscustomobject]@{ Id = $Id; Key = $Id; Requires = $Requires; LoadAfter = $After; LoadBefore = $Before; Incompatible = $Incompatible } }
}
class FakeClientSession {
    [hashtable]$Directories
    [Collections.Generic.List[uint64]]$Subscribed = [Collections.Generic.List[uint64]]::new()
    [Collections.Generic.List[uint64]]$Downloads = [Collections.Generic.List[uint64]]::new()
    [bool]$AlwaysFail
    [bool]$Disposed
    [bool]$PendingForever
    [int]$DownloadResult
    [int]$PumpCount
    FakeClientSession([hashtable]$Directories) { $this.Directories = $Directories }
    [void]SubscribeItem([uint64]$Id) { $this.Subscribed.Add($Id) }
    [bool]SubscriptionPending([uint64]$Id) { return $this.PendingForever }
    [uint32]GetItemState([uint64]$Id) {
        if ($Id -eq 111 -or $this.DownloadResult -eq 1) { return 5 }
        # Leave a cached, installed folder after an error to ensure it never hides that error.
        if ($this.DownloadResult -gt 1) { return 5 }
        return 9
    }
    [bool]DownloadItem([uint64]$Id) {
        $this.Downloads.Add($Id)
        $this.DownloadResult = if ($this.AlwaysFail -or $this.Downloads.Count -eq 1) { 2 } else { 1 }
        return $true
    }
    [int]GetDownloadResult([uint64]$Id) { return $this.DownloadResult }
    [string]GetInstallFolder([uint64]$Id) { return $this.Directories[[string]$Id] }
    [void]Pump() { $this.PumpCount++ }
    [void]Dispose() { $this.Disposed = $true }
}
try {
    foreach ($file in @('Download-PZMods.ps1','Start-PZModSetup.ps1','PZModTools.psm1','tests/Verify-PZMods.ps1')) {
        $tokens = $null; $errors = $null
        [Management.Automation.Language.Parser]::ParseFile((Join-Path $root $file), [ref]$tokens, [ref]$errors) | Out-Null
        Assert-True ($errors.Count -eq 0) "PowerShell syntax: $file. $($errors -join '; ')"
    }
    Assert-True ((ConvertTo-ModKey '\2925034918/EasyLaundry') -eq 'EasyLaundry') 'Legacy Workshop-prefixed mod matching.'
    Assert-True ((ConvertTo-BuildVersion '42.21') -eq [version]'42.21.0.0') 'Build number normalization.'
    Assert-Throws { ConvertTo-BuildVersion '42.bad' } 'Invalid build'
    Assert-True ((Select-PZSetupMode 'Client') -eq 'Client' -and (Select-PZSetupMode 'Server') -eq 'Server') 'Explicit mode skips the setup prompt.'
    # Exercise the real prompt path without interactive input.
    $module = Get-Module PZModTools
    $prompted = & $module {
        function Read-Host { return 'c' }
        Select-PZSetupMode
    }
    Assert-True ($prompted -eq 'Client') 'The interactive setup prompt selects client mode.'
    Add-Type -Path (Join-Path $root 'SteamWorkshopClient.cs')
    Assert-True ([Runtime.InteropServices.Marshal]::SizeOf([type][PZModTools.SteamWorkshopClient+SubscriptionResult]) -eq 16 -and
        [Runtime.InteropServices.Marshal]::SizeOf([type][PZModTools.SteamWorkshopClient+DownloadResult]) -eq 24 -and
        [Runtime.InteropServices.Marshal]::SizeOf([type][PZModTools.SteamWorkshopClient+CallbackMessage]) -eq 24) 'The compiled native bridge matches the Windows x64 Steam callback ABI.'

    Write-Fixture 'versions/mods/Example/mod.info' "id=WrongB41`n" | Out-Null
    Write-Fixture 'versions/mods/Example/common/mod.info' "id=CommonId`nrequire=CommonDep`n" | Out-Null
    Write-Fixture 'versions/mods/Example/42/mod.info' "id=OldB42`n" | Out-Null
    Write-Fixture 'versions/mods/Example/42.20/mod.info' "id=ChosenB42`nrequire=Library,Implicit`nversionMin=42.20`nversionMax=42.21.0`n" | Out-Null
    Write-Fixture 'versions/mods/Example/42.22/mod.info' "id=FutureB42`n" | Out-Null
    Write-Fixture 'versions/mods/B41Only/mod.info' "id=B41Only`n" | Out-Null
    Write-Fixture 'versions/mods/FutureOnly/common/mod.info' "id=FutureOnly`n" | Out-Null
    Write-Fixture 'versions/mods/FutureOnly/42.22/mod.info' "id=FutureOnly`n" | Out-Null
    $metadata = @(Get-B42ModMetadata -ItemDirectory (Join-Path $temporary 'versions') -WorkshopId 111 -BuildVersion (ConvertTo-BuildVersion '42.21.0'))
    Assert-True ($metadata.Count -eq 1 -and $metadata[0].Id -eq 'ChosenB42') 'Select applicable B42 folder; reject B41 and future-only mods even when they contain common metadata.'
    Assert-True ($metadata[0].Requires.Count -eq 2 -and 'CommonDep' -notin $metadata[0].Requires) 'Version mod.info overrides common metadata.'
    Write-Fixture 'no-inheritance/mods/Example/common/mod.info' "id=OldId`nrequire=UnusedCommonDependency`nversionMax=42.20`n" | Out-Null
    Write-Fixture 'no-inheritance/mods/Example/42.21/mod.info' "id=CurrentId`n" | Out-Null
    $notInherited = @(Get-B42ModMetadata -ItemDirectory (Join-Path $temporary 'no-inheritance') -WorkshopId 115 -BuildVersion (ConvertTo-BuildVersion '42.21'))
    Assert-True ($notInherited[0].Id -eq 'CurrentId' -and $notInherited[0].Requires.Count -eq 0 -and $null -eq $notInherited[0].MaxBuild) 'Do not inherit omitted native requirements or version bounds from common when version metadata exists.'
    Write-Fixture 'patch-folder/mods/Example/42.21.9/mod.info' "id=SameMinorVersion`n" | Out-Null
    $sameMinor = @(Get-B42ModMetadata -ItemDirectory (Join-Path $temporary 'patch-folder') -WorkshopId 116 -BuildVersion (ConvertTo-BuildVersion '42.21.0'))
    Assert-True ($sameMinor.Count -eq 1 -and $sameMinor[0].Id -eq 'SameMinorVersion') 'Select version folders by the game major/minor key, independently of full native build bounds.'
    Assert-True ($metadata[0].MinBuild -eq [version]'42.20.0.0' -and $metadata[0].MaxBuild -eq [version]'42.21.0.0') 'Read official versionMin/versionMax fields.'
    $older = @(Get-B42ModMetadata -ItemDirectory (Join-Path $temporary 'versions') -WorkshopId 111 -BuildVersion (ConvertTo-BuildVersion '42.19.0'))
    Assert-True ($older[0].Id -eq 'OldB42') 'Choose earlier metadata on an earlier server build.'
    Write-Fixture 'common-only/mods/Example/common/mod.info' "id=CommonOnly`n" | Out-Null
    $common = @(Get-B42ModMetadata -ItemDirectory (Join-Path $temporary 'common-only') -WorkshopId 112 -BuildVersion (ConvertTo-BuildVersion '42.21'))
    Assert-True ($common.Count -eq 1 -and $common[0].Id -eq 'CommonOnly') 'Support a common-only B42 mod.'
    Write-Fixture 'sorter/mods/Sorted/common/mod.info' "id=Sorted`nloadAfter=\CommonFirst`nloadAfter=CommonSecond`nloadBefore=CommonLast`nincompatibleMods=CommonConflict`n" | Out-Null
    Write-Fixture 'sorter/mods/Sorted/42/mod.info' "id=Sorted`nloadModAfter=NativeFirst`nloadModBefore=\NativeLast`nincompatible=NativeConflict`n" | Out-Null
    $sorterMetadata = @(Get-B42ModMetadata -ItemDirectory (Join-Path $temporary 'sorter') -WorkshopId 114 -BuildVersion (ConvertTo-BuildVersion '42.21'))
    Assert-True (($sorterMetadata[0].LoadAfter -join ',') -eq 'NativeFirst,CommonFirst,CommonSecond' -and ($sorterMetadata[0].LoadBefore -join ',') -eq 'NativeLast,CommonLast' -and ($sorterMetadata[0].Incompatible -join ',') -eq 'NativeConflict,CommonConflict') 'Combine native B42 fields with common sorter rules, including repeated list fields.'

    $records = @((New-Record 'Addon' 1 -Requires Library), (New-Record 'Library' 100), (New-Record 'Patch' 2 -After Addon), (New-Record 'Early' 200 -Before Library))
    $order = @((Get-PZLoadOrder $records) | ForEach-Object { $_.Metadata.Id })
    Assert-True (($order -join ',') -eq 'Early,Library,Addon,Patch') 'Enforce require, loadModAfter and loadModBefore together.'
    Assert-Throws { Get-PZLoadOrder @((New-Record 'Addon' -Requires Missing)) } 'requires missing'
    Assert-Throws { Get-PZLoadOrder @((New-Record 'A' -After B),(New-Record 'B' -After A)) } 'cycle'
    Assert-Throws { Get-PZLoadOrder @((New-Record 'A' -Incompatible B),(New-Record 'B')) } 'incompatible'
    Assert-Throws { Get-PZLoadOrder @((New-Record 'A'),(New-Record 'A')) } 'Duplicate active'

    $iniOriginal = "# preserve`r`nPublicName=Test server`r`nMods=Old`r`nWorkshopItems=999`r`nMods=Duplicate`r`nMap=Muldraugh, KY`r`n"
    $ini = Write-Fixture 'server.ini' $iniOriginal
    $backup = Set-PZServerModSettings -Path $ini -ModsLine 'Mods=Library;Addon' -WorkshopLine 'WorkshopItems=111'
    $updated = [IO.File]::ReadAllText($ini)
    Assert-True ([IO.File]::ReadAllText($backup) -ceq $iniOriginal) 'Backup is byte-equivalent when read as text.'
    Assert-True ($updated.Contains('PublicName=Test server') -and $updated.Contains('Map=Muldraugh, KY')) 'Preserve unrelated server settings.'
    Assert-True (([regex]::Matches($updated,'(?m)^Mods=')).Count -eq 1 -and $updated.Contains('Mods=Library;Addon')) 'Replace duplicates with one Mods setting.'
    Assert-True ($updated.Contains("`r`n")) 'Preserve Windows INI line endings.'
    Assert-Throws { Set-PZServerModSettings -Path (Join-Path $temporary 'missing.ini') -ModsLine 'Mods=A' -WorkshopLine 'WorkshopItems=1' } 'does not exist'
    $sleepOriginal = "PublicName=Sleep server`r`nSleepAllowed=false`r`nSleepNeeded=false`r`nOtherOption=keep`r`n"
    $sleepIni = Write-Fixture 'sleep.ini' $sleepOriginal
    $sleepBackup = Set-PZServerModSettings -Path $sleepIni -ModsLine 'Mods=TrueSleep' -WorkshopLine 'WorkshopItems=3781533687' -AdditionalSettings @{ SleepAllowed='true'; SleepNeeded='true' }
    $sleepUpdated = [IO.File]::ReadAllText($sleepIni)
    Assert-True ($sleepUpdated.Contains('SleepAllowed=true') -and $sleepUpdated.Contains('SleepNeeded=true') -and $sleepUpdated.Contains('OtherOption=keep') -and [IO.File]::ReadAllText($sleepBackup) -ceq $sleepOriginal) 'Apply mod-required sleeping settings with a complete backup and preserve other server options.'
    Assert-Throws { Set-PZServerModSettings -Path $sleepIni -ModsLine 'Mods=A' -WorkshopLine 'WorkshopItems=1' -AdditionalSettings @{ SleepAllowed="true`nOtherOption=changed" } } 'Invalid additional'
    $settingsCatalog = [pscustomobject]@{
        ServerSettings=@([pscustomobject]@{ModIds=@('TrueSleep');Settings=[pscustomobject]@{SleepAllowed='true';SleepNeeded='true'}})
        SetupActions=@([pscustomobject]@{Audience='Client';ModIds=@('SPNCC');Text='Enable textures and restart'},[pscustomobject]@{Audience='Server';ModIds=@();Text='Test server'},[pscustomobject]@{Audience='Client';ModIds=@('NotSelected');Text='Should not appear'})
    }
    Assert-True ((Get-PZRequiredServerSettings -Catalog $settingsCatalog -ActiveIds @('TrueSleep')).Count -eq 2 -and (Get-PZRequiredServerSettings -Catalog $settingsCatalog -ActiveIds @('Other')).Count -eq 0) 'Apply required server settings only when the relevant mod is selected.'
    $clientActions = @(Get-PZSetupActions -Catalog $settingsCatalog -ActiveIds @('SPNCC') -Mode Client)
    Assert-True ($clientActions.Count -eq 1 -and $clientActions[0].Text -eq 'Enable textures and restart') 'Next steps match the selected mods and setup role.'

    $catalog = Get-Content -LiteralPath (Join-Path $root 'mods.catalog.json') -Raw | ConvertFrom-Json
    $requested = ((Get-Content -LiteralPath (Join-Path $root 'requested-mods.txt') -Raw).Trim() -split ':',2)[1] -split ';' | Where-Object { $_ }
    Assert-True ($catalog.Mods.Count -eq 294 -and ($requested -join ';') -ceq (($catalog.Mods | ForEach-Object { $_.ModId }) -join ';')) 'Catalog preserves all 294 new requested entries and their supplied order.'
    Assert-True (@($catalog.Mods.WorkshopId | Select-Object -Unique).Count -eq 249) 'Deduplicate the complete 294-entry Workshop mapping.'
    Assert-True (@($catalog.Mods | Where-Object { -not $_.MultiplayerEnabled -and -not $_.BlockAutoEnable }).Count -eq 0) 'Every held-back requested mod is protected from dependency auto-enablement.'
    & (Join-Path $root 'Download-PZMods.ps1') -Mode Server -BuildVersion 42.21.0 -PlanOnly -OutputDirectory (Join-Path $temporary 'preview')
    $preview = Get-Content -LiteralPath (Join-Path $temporary 'preview/validation.preview.json') -Raw | ConvertFrom-Json
    Assert-True (-not $preview.ValidatedFromDownloads -and -not $preview.RuntimeTested -and $preview.EnabledMods.Count -eq 260) 'Full catalog preview uses the 260-mod conservative MP selection without claiming live validation.'
    Assert-True ($preview.DownloadWorkshopIds.Count -eq 224 -and '1539281445' -notin $preview.DownloadWorkshopIds) 'Download only the selected 224 Workshop items; do not download the held-back abandoned car mod.'
    $fullOrder = @($preview.EnabledMods.ActualId)
    Assert-True ($fullOrder[0] -eq 'ETO_B' -and [array]::IndexOf($fullOrder,'ATakeABathAndShowerDepthMap') -lt 5 -and [array]::IndexOf($fullOrder,'ATakeABathAndShowerDepthMap') -lt [array]::IndexOf($fullOrder,'TakeABathAndShowerNew')) 'Place the author-requested texture and bath depth fixes at the top, allowing early error-reporting libraries.'
    Assert-True ([array]::IndexOf($fullOrder,'HBVCEFb42') -lt [array]::IndexOf($fullOrder,'SWMG') -and [array]::IndexOf($fullOrder,'SWMG') -lt [array]::IndexOf($fullOrder,'GunsOfMarz')) 'Hot Brass precedes Gunworks and Guns of Marz.'
    $alert = $catalog.Mods | Where-Object ModId -eq 'ChuckleberryFinnAlertSystem'
    $magnifier = $catalog.Mods | Where-Object ModId -eq 'errorMagnifier'
    Assert-True ($alert.Requires.Count -eq 0 -and 'ChuckleberryFinnAlertSystem' -in $magnifier.Requires -and [array]::IndexOf($fullOrder,'ChuckleberryFinnAlertSystem') -lt [array]::IndexOf($fullOrder,'errorMagnifier')) 'Follow the author-native errorMagnifier dependency without creating a reverse Workshop co-installation cycle.'
    Assert-True ([array]::IndexOf($fullOrder,'CleanHotBar') -lt [array]::IndexOf($fullOrder,'MinimalHotbar')) 'Apply the author-requested hotbar override after CleanHotBar.'
    Assert-True ([array]::IndexOf($fullOrder,'76chevyKseries') -lt [array]::IndexOf($fullOrder,'76chevyKseriesExpanded') -and [array]::IndexOf($fullOrder,'KI5campers') -lt [array]::IndexOf($fullOrder,'SpecLoot') -and [array]::IndexOf($fullOrder,'SpecLoot') -lt [array]::IndexOf($fullOrder,'VehicleRepairOverhaul')) 'Vehicle bases precede expansions, loot patches, and the repair overhaul.'
    Assert-True ([array]::IndexOf($fullOrder,'SM4BootsExpandedB42') -lt [array]::IndexOf($fullOrder,'TombBodyCompatBootsExp') -and 'SM4BootsExpandedB42VanillaONLY' -notin $fullOrder -and 'MarzVanillaGuns' -notin $fullOrder) 'Use one boots variant and one Marz weapons pack, with the matching body patch after boots.'
    Assert-True ($preview.RequiredServerSettings.SleepAllowed -eq 'true' -and $preview.RequiredServerSettings.SleepNeeded -eq 'true') 'The selected TrueSleep profile exports both required server settings.'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $temporary 'preview/server-mods.ini'))) 'Preview never writes a validated INI.'
    Assert-Throws { Read-PZServerProfile (Join-Path $temporary 'preview/server-profile.preview.json') } 'validated server-profile'
    & (Join-Path $root 'Download-PZMods.ps1') -Mode Server -BuildVersion 42.21.0 -PlanOnly -OutputDirectory (Join-Path $temporary 'preview')
    $previewRerunStatus = Get-Content -LiteralPath (Join-Path $temporary 'preview/run-status.json') -Raw | ConvertFrom-Json
    Assert-True ($previewRerunStatus.Status -eq 'preview' -and (Get-Content -LiteralPath (Join-Path $temporary 'preview/server-profile.preview.json') -Raw | ConvertFrom-Json).Mods.Count -eq 260) 'A successful preview rerun replaces an existing preview profile.'
    Assert-Throws { & (Join-Path $root 'Download-PZMods.ps1') -Mode Server -BuildVersion 42.21.0 -PlanOnly -Profile AllRequested -OutputDirectory (Join-Path $temporary 'conflicting-preview') } 'Incompatible selection'

    # End-to-end scan: renamed submod + dependency auto-enabling + implicit required submod.
    Write-Fixture 'content/111/mods/Main/42/mod.info' "id=Main`nrequire=Library,Implicit`n" | Out-Null
    Write-Fixture 'content/111/mods/Library/42/mod.info' "id=Library`n" | Out-Null
    Write-Fixture 'content/111/mods/Implicit/common/mod.info' "id=Implicit`n" | Out-Null
    Write-Fixture 'content/222/mods/Addon/42/mod.info' "id=RenamedAddon`nloadModAfter=Main`n" | Out-Null
    $main = New-Entry Main 111
    $library = New-Entry Library 111 -Enabled $false
    $library | Add-Member -NotePropertyName AllowDependencyAutoEnable -NotePropertyValue $true
    $addon = New-Entry OldAddon 222
    $addon.Aliases = @('RenamedAddon')
    $fixtureCatalog = @{
        SchemaVersion=1; AppId='108600'; VerifiedDate='2026-10-11'; Mods=@($main,$library,$addon); Conflicts=@()
        ServerSettings=@(@{ModIds=@('OldAddon');Settings=@{AliasFlag='true'}})
        SetupActions=@(@{Audience='Client';ModIds=@('OldAddon');Text='Alias-selected next step'})
    }
    $fixtureCatalogPath = Write-Fixture 'catalog.json' ($fixtureCatalog | ConvertTo-Json -Depth 8)
    $scanIni = Write-Fixture 'scan.ini' $iniOriginal
    $scanParameters = @{ Mode='Server'; CatalogPath=$fixtureCatalogPath; BuildVersion='42.21.0'; SkipDownload=$true; WorkshopContentPath=(Join-Path $temporary 'content'); OutputDirectory=(Join-Path $temporary 'scan'); ServerIni=$scanIni }
    & (Join-Path $root 'Download-PZMods.ps1') @scanParameters
    $scanReport = Get-Content -LiteralPath (Join-Path $temporary 'scan/validation.json') -Raw | ConvertFrom-Json
    $scanOrder = @($scanReport.EnabledMods.ActualId)
    Assert-True ($scanReport.ValidatedFromDownloads -and $scanOrder.Count -eq 4) 'Downloaded metadata scan enables required modules, including unlisted submods.'
    Assert-True ([array]::IndexOf($scanOrder,'Library') -lt [array]::IndexOf($scanOrder,'Main') -and [array]::IndexOf($scanOrder,'Implicit') -lt [array]::IndexOf($scanOrder,'Main')) 'Dependencies precede their dependent in generated output.'
    Assert-True ('RenamedAddon' -in $scanOrder -and 'OldAddon' -notin $scanOrder) 'Output uses actual downloaded submod IDs.'
    Assert-True ([IO.File]::ReadAllText($scanIni).Contains('WorkshopItems=111;222')) 'Server INI contains only unique enabled Workshop IDs.'

    # Shared server profile round trip into a client setup, using existing Workshop fixtures.
    $sharePath = Join-Path $temporary 'scan/server-profile.json'
    $shared = Read-PZServerProfile $sharePath
    Assert-True (($shared.Mods.ModId -join ';') -ceq ($scanOrder -join ';')) 'The server exports exact downloaded IDs and load order for clients.'
    $playerZip = Join-Path $temporary 'scan/player-setup.zip'
    $playerExtract = Join-Path $temporary 'player-package'
    Expand-Archive -LiteralPath $playerZip -DestinationPath $playerExtract
    $packedProfile = Read-PZServerProfile (Join-Path $playerExtract 'server-profile.json')
    Assert-True (($packedProfile.Mods.ModId -join ';') -ceq ($scanOrder -join ';') -and (Test-Path -LiteralPath (Join-Path $playerExtract 'Start-PZModSetup.cmd')) -and (Test-Path -LiteralPath (Join-Path $playerExtract 'SteamWorkshopClient.cs')) -and (Test-Path -LiteralPath (Join-Path $playerExtract 'mods.catalog.json'))) 'The player ZIP includes its double-click launcher, native bridge, exact catalog, and server profile.'
    $scanStatus = Get-Content -LiteralPath (Join-Path $temporary 'scan/run-status.json') -Raw | ConvertFrom-Json
    Assert-True ($scanStatus.ServerIniUpdated -and $scanStatus.ClientPackagePath -eq $playerZip -and -not $scanStatus.RuntimeTested -and -not $scanReport.RuntimeTested) 'Successful setup reports the applied INI and player ZIP without claiming a runtime test.'
    Assert-True ($scanReport.RequiredServerSettings.AliasFlag -eq 'true' -and @($shared.SetupActions).Count -eq 1 -and $shared.SetupActions[0].Text -eq 'Alias-selected next step') 'Rules keyed by the requested ID remain active after metadata resolves a renamed ID.'
    $protectedIni = Write-Fixture 'protected-ini/live.ini' $iniOriginal
    $protectedParameters = $scanParameters.Clone()
    $protectedParameters.ServerIni = $protectedIni
    $protectedParameters.OutputDirectory = Join-Path $temporary 'protected-share'
    & (Join-Path $root 'Download-PZMods.ps1') @protectedParameters
    $protectedProfile = Join-Path $protectedParameters.OutputDirectory 'server-profile.json'
    $protectedZip = Join-Path $protectedParameters.OutputDirectory 'player-setup.zip'
    $previousProfile = [IO.File]::ReadAllText($protectedProfile)
    $previousZipHash = (Get-FileHash -LiteralPath $protectedZip).Hash
    $mainOnlyCatalogPath = Write-Fixture 'main-only-catalog.json' (@{SchemaVersion=1;AppId='108600';VerifiedDate='2026-10-11';Mods=@($main);Conflicts=@()} | ConvertTo-Json -Depth 8)
    $protectedParameters.CatalogPath = $mainOnlyCatalogPath
    try {
        if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { (Get-Item -LiteralPath $protectedIni).IsReadOnly = $true }
        else { & chmod 'a-w' (Split-Path -Parent $protectedIni) }
        Assert-Throws { & (Join-Path $root 'Download-PZMods.ps1') @protectedParameters } '.'
    } finally {
        if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { (Get-Item -LiteralPath $protectedIni).IsReadOnly = $false }
        else { & chmod 'u+w' (Split-Path -Parent $protectedIni) }
    }
    Assert-True ([IO.File]::ReadAllText($protectedProfile) -ceq $previousProfile -and (Get-FileHash -LiteralPath $protectedZip).Hash -eq $previousZipHash) 'A failed server INI update cannot publish a new player profile or replace the previous player ZIP.'
    $rerunCatalog = $fixtureCatalog.Clone()
    $rerunCatalog.SetupActions = @(@{Audience='Client';ModIds=@('OldAddon');Text='Refreshed player instructions'})
    $rerunCatalogPath = Write-Fixture 'rerun-catalog.json' ($rerunCatalog | ConvertTo-Json -Depth 8)
    $rerunParameters = $scanParameters.Clone()
    $rerunParameters.CatalogPath = $rerunCatalogPath
    & (Join-Path $root 'Download-PZMods.ps1') @rerunParameters
    $rerunProfile = Read-PZServerProfile $sharePath
    $rerunStatus = Get-Content -LiteralPath (Join-Path $temporary 'scan/run-status.json') -Raw | ConvertFrom-Json
    Assert-True ($rerunStatus.Status -eq 'validated' -and $rerunStatus.ServerIniUpdated -and $rerunProfile.SetupActions[0].Text -eq 'Refreshed player instructions') 'A successful server rerun replaces its existing exported profile with the refreshed selection instructions.'
    $rerunExtract = Join-Path $temporary 'rerun-player-package'
    Expand-Archive -LiteralPath $playerZip -DestinationPath $rerunExtract
    $rerunPackedProfile = Read-PZServerProfile (Join-Path $rerunExtract 'server-profile.json')
    Assert-True ($rerunPackedProfile.SetupActions[0].Text -eq 'Refreshed player instructions' -and ($rerunPackedProfile.Mods.ModId -join ';') -ceq ($scanOrder -join ';')) 'A successful server rerun replaces its existing player ZIP with the refreshed exported profile.'
    Write-Fixture 'dependency-content/111/mods/Main/42/mod.info' "id=Main`nrequire=ExternalLibrary`n" | Out-Null
    Write-Fixture 'dependency-content/333/mods/ExternalLibrary/42/mod.info' "id=ExternalLibrary`n" | Out-Null
    $dependencyMain = New-Entry Main 111 -Priority 1
    $dependencyMain.Requires = @('ExternalLibrary')
    $externalLibrary = New-Entry ExternalLibrary 333 -Priority 100 -Enabled $false
    $dependencyCatalogPath = Write-Fixture 'dependency-catalog.json' (@{SchemaVersion=1;AppId='108600';VerifiedDate='2026-10-11';Mods=@($dependencyMain);Dependencies=@($externalLibrary);Conflicts=@();SetupActions=@();ServerSettings=@()} | ConvertTo-Json -Depth 8)
    & (Join-Path $root 'Download-PZMods.ps1') -Mode Server -CatalogPath $dependencyCatalogPath -PlanOnly -OutputDirectory (Join-Path $temporary 'dependency-preview')
    $dependencyPreview = Get-Content -LiteralPath (Join-Path $temporary 'dependency-preview/validation.preview.json') -Raw | ConvertFrom-Json
    Assert-True (($dependencyPreview.EnabledMods.ActualId -join ';') -eq 'ExternalLibrary;Main' -and '333' -in $dependencyPreview.DownloadWorkshopIds) 'A researched library outside the requested list is selected and ordered before downloading.'
    & (Join-Path $root 'Download-PZMods.ps1') -Mode Server -CatalogPath $dependencyCatalogPath -SkipDownload -WorkshopContentPath (Join-Path $temporary 'dependency-content') -OutputDirectory (Join-Path $temporary 'dependency-scan')
    $dependencyScan = Get-Content -LiteralPath (Join-Path $temporary 'dependency-scan/validation.json') -Raw | ConvertFrom-Json
    Assert-True (($dependencyScan.EnabledMods.ActualId -join ';') -eq 'ExternalLibrary;Main' -and $dependencyScan.ValidatedFromDownloads) 'Downloaded metadata confirms a dependency from the catalog library section.'
    Assert-Throws { & (Join-Path $root 'Download-PZMods.ps1') -Mode Server -CatalogPath $dependencyCatalogPath -PlanOnly -ExcludeMod ExternalLibrary -OutputDirectory (Join-Path $temporary 'dependency-scan') } 'explicitly excluded'
    $earlyFailure = Get-Content -LiteralPath (Join-Path $temporary 'dependency-scan/run-status.json') -Raw | ConvertFrom-Json
    Assert-True ($earlyFailure.Status -eq 'failed' -and -not $earlyFailure.ValidatedFromDownloads) 'An early catalog selection error invalidates the previous successful run status.'
    $holdbackCatalogPath = Write-Fixture 'heldback-catalog.json' (@{SchemaVersion=1;AppId='108600';VerifiedDate='2026-10-11';Mods=@($dependencyMain,$externalLibrary);Conflicts=@()} | ConvertTo-Json -Depth 8)
    Assert-Throws { & (Join-Path $root 'Download-PZMods.ps1') -Mode Server -CatalogPath $holdbackCatalogPath -PlanOnly -OutputDirectory (Join-Path $temporary 'heldback-preview') } 'held out of the multiplayer'
    $dependencyMain.Requires = @()
    $holdbackMetadataPath = Write-Fixture 'heldback-metadata-catalog.json' (@{SchemaVersion=1;AppId='108600';VerifiedDate='2026-10-11';Mods=@($dependencyMain,$externalLibrary);Conflicts=@()} | ConvertTo-Json -Depth 8)
    Assert-Throws { & (Join-Path $root 'Download-PZMods.ps1') -Mode Server -CatalogPath $holdbackMetadataPath -SkipDownload -WorkshopContentPath (Join-Path $temporary 'dependency-content') -OutputDirectory (Join-Path $temporary 'heldback-metadata') } 'held out of the multiplayer'
    $clientExisting = Write-Fixture 'client-data/mods/default.txt' "VERSION = 1,`nmods { mod = Old, }`n"
    $clientOriginal = [IO.File]::ReadAllText($clientExisting)
    $unrelatedWorkshop = Write-Fixture 'content/999/mods/Unrelated/42/mod.info' "id=UnrelatedWorkshop`n"
    $unrelatedLocal = Write-Fixture 'client-data/mods/Unrelated/42/mod.info' "id=UnrelatedLocal`n"
    Write-Fixture 'content/997/mods/InapplicableDuplicate/42/mod.info' "id=Main`nversionMin=42.22`n" | Out-Null
    Write-Fixture 'content/998/mods/Malformed/42/mod.info' "name=Unrelated malformed fixture`n" | Out-Null
    $clientParameters = @{ Mode='Client'; CatalogPath=$fixtureCatalogPath; ServerProfile=$sharePath; SkipDownload=$true; WorkshopContentPath=(Join-Path $temporary 'content'); OutputDirectory=(Join-Path $temporary 'client-output'); ClientDataDirectory=(Join-Path $temporary 'client-data') }
    $providerWarnings = @()
    & (Join-Path $root 'Download-PZMods.ps1') @clientParameters -WarningVariable providerWarnings
    $clientReport = Get-Content -LiteralPath (Join-Path $temporary 'client-output/validation.json') -Raw | ConvertFrom-Json
    Assert-True ($clientReport.Mode -eq 'Client' -and ($clientReport.EnabledMods.ActualId -join ';') -ceq ($scanOrder -join ';')) 'Client setup reproduces the server order, including renamed and implicit submods.'
    Assert-True ([IO.File]::ReadAllText($clientExisting) -ceq [IO.File]::ReadAllText((Join-Path $temporary 'client-output/default.txt'))) 'Client mode installs its checked profile in the client mods directory.'
    $clientBackups = @(Get-ChildItem -LiteralPath (Split-Path $clientExisting -Parent) -Filter 'default.txt.backup-*')
    Assert-True ($clientBackups.Count -eq 1 -and [IO.File]::ReadAllText($clientBackups[0].FullName) -ceq $clientOriginal) 'Existing client profile is backed up before replacement.'
    $clientStatus = Get-Content -LiteralPath (Join-Path $temporary 'client-output/run-status.json') -Raw | ConvertFrom-Json
    Assert-True ($clientStatus.Status -eq 'validated' -and $clientStatus.ClientProfileInstalled) 'Client status confirms installation only after validation.'
    Assert-True ((Test-Path -LiteralPath $unrelatedWorkshop) -and (Test-Path -LiteralPath $unrelatedLocal) -and $clientReport.ClientDuplicateProviderScan.WorkshopContentRoots.Count -eq 1) 'Unrelated installed Workshop/local mods and an out-of-range duplicate do not block or get removed during client setup.'
    Assert-True (-not $clientReport.ClientDuplicateProviderScan.CoverageComplete -and @($providerWarnings | Where-Object { [string]$_ -match 'Malformed.*Coverage.*incomplete' }).Count -eq 1 -and $clientReport.ClientDuplicateProviderScan.Warnings.Count -eq 1) 'Malformed unrelated metadata produces an explicit warning and incomplete scan coverage instead of a clean-coverage claim.'
    $profileBeforePreview = [IO.File]::ReadAllText($clientExisting)
    $duplicateWorkshop = Write-Fixture 'content/777/mods/OldProvider/42/mod.info' "id=Main`n"
    $duplicateParameters = $clientParameters.Clone()
    $duplicateParameters.OutputDirectory = Join-Path $temporary 'client-duplicate'
    Assert-Throws { & (Join-Path $root 'Download-PZMods.ps1') @duplicateParameters } 'Main.*Workshop item 777'
    $duplicateStatus = Get-Content -LiteralPath (Join-Path $duplicateParameters.OutputDirectory 'run-status.json') -Raw | ConvertFrom-Json
    Assert-True ([IO.File]::ReadAllText($clientExisting) -ceq $profileBeforePreview -and @(Get-ChildItem -LiteralPath (Split-Path $clientExisting -Parent) -Filter 'default.txt.backup-*').Count -eq 1 -and (Test-Path -LiteralPath $duplicateWorkshop) -and $duplicateStatus.Status -eq 'failed' -and -not $duplicateStatus.ClientProfileInstalled) 'An unselected second Workshop provider blocks preset overwrite, preserves its existing backup, and leaves both installed copies untouched.'
    Remove-Item -LiteralPath (Join-Path $temporary 'content/777') -Recurse -Force
    $duplicateLocal = Write-Fixture 'client-data/mods/LocalCopy/42/mod.info' "id=RenamedAddon`n"
    $duplicateParameters.OutputDirectory = Join-Path $temporary 'client-local-duplicate'
    Assert-Throws { & (Join-Path $root 'Download-PZMods.ps1') @duplicateParameters } 'RenamedAddon.*local mod'
    Assert-True ([IO.File]::ReadAllText($clientExisting) -ceq $profileBeforePreview -and (Test-Path -LiteralPath $duplicateLocal)) 'A local copy of an actual selected mod ID blocks preset overwrite without deleting the local copy.'
    Remove-Item -LiteralPath (Join-Path $temporary 'client-data/mods/LocalCopy') -Recurse -Force
    & (Join-Path $root 'Download-PZMods.ps1') -Mode Client -PlanOnly -CatalogPath $fixtureCatalogPath -ServerProfile $sharePath -ClientDataDirectory (Join-Path $temporary 'client-data') -OutputDirectory (Join-Path $temporary 'client-preview')
    Assert-True ([IO.File]::ReadAllText($clientExisting) -ceq $profileBeforePreview) 'Client preview never overwrites the installed profile.'
    Assert-Throws { & (Join-Path $root 'Download-PZMods.ps1') @clientParameters -BuildVersion 42.20.0 } 'differs from'
    Assert-Throws { & (Join-Path $root 'Download-PZMods.ps1') @clientParameters -ServerIni $scanIni } 'only available in Server'
    Assert-Throws { & (Join-Path $root 'Download-PZMods.ps1') @clientParameters -ExcludeMod Main } 'Client mode uses'
    $missingDependencyProfile = Write-Fixture 'incomplete-server-profile.json' (@{ SchemaVersion=1; AppId='108600'; ValidatedFromDownloads=$true; BuildVersion='42.21.0'; Mods=@(@{ModId='Main';WorkshopId='111'}) } | ConvertTo-Json -Depth 8)
    Assert-Throws { & (Join-Path $root 'Download-PZMods.ps1') -Mode Client -ServerProfile $missingDependencyProfile -CatalogPath $fixtureCatalogPath -SkipDownload -WorkshopContentPath (Join-Path $temporary 'content') -ClientDataDirectory (Join-Path $temporary 'client-data') -OutputDirectory (Join-Path $temporary 'client-mismatch') } 'differ from the server profile'
    Assert-True ([IO.File]::ReadAllText($clientExisting) -ceq $profileBeforePreview) 'Server profile mismatch leaves the client profile untouched.'

    # Exercise the interactive menu with queued answers and the actual offline backend.
    & {
        . (Join-Path $root 'Start-PZModSetup.ps1') -NoStart
        $wizardRoot = Join-Path $temporary 'wizard project'
        New-Item -ItemType Directory -Path $wizardRoot -Force | Out-Null
        foreach ($file in @('Start-PZModSetup.cmd','Start-PZModSetup.ps1','Download-PZMods.ps1','PZModTools.psm1','SteamWorkshopClient.cs')) {
            Copy-Item -LiteralPath (Join-Path $root $file) -Destination (Join-Path $wizardRoot $file)
        }
        Copy-Item -LiteralPath $fixtureCatalogPath -Destination (Join-Path $wizardRoot 'mods.catalog.json')
        Copy-Item -LiteralPath $sharePath -Destination (Join-Path $wizardRoot 'server-profile.json')
        $script:PZSetupRoot = $wizardRoot
        $answers = [Collections.Generic.Queue[string]]::new()
        $script:PZSetupInputReader = {
            param($Prompt)
            if ($answers.Count -eq 0) { throw "Unexpected menu prompt: $Prompt" }
            return $answers.Dequeue()
        }.GetNewClosure()
        foreach ($answer in @('2','3','bad-build','42.21.0','1','0')) { $answers.Enqueue($answer) }
        Start-PZSetupMenu
        $wizardPreview = Get-Content -LiteralPath (Join-Path $wizardRoot 'output/preview/server/run-status.json') -Raw | ConvertFrom-Json
        Assert-True ($answers.Count -eq 0 -and $wizardPreview.Status -eq 'preview' -and $wizardPreview.Mode -eq 'Server') 'The server menu validates a build entry and completes a preview through the real backend.'
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $wizardRoot 'output/server-mods.ini'))) 'The preview menu cannot create validated server settings.'

        foreach ($answer in @('1','3','1','1','0')) { $answers.Enqueue($answer) }
        Start-PZSetupMenu
        $wizardClient = Get-Content -LiteralPath (Join-Path $wizardRoot 'output/preview/client/validation.preview.json') -Raw | ConvertFrom-Json
        Assert-True ($answers.Count -eq 0 -and ($wizardClient.EnabledMods.ActualId -join ';') -ceq ($scanOrder -join ';') -and -not $wizardClient.ValidatedFromDownloads) 'The player menu finds the shared server profile and previews its exact mod order.'

        # The Existing action must scan the chosen content folder and apply only the selected INI.
        $wizardContent = Join-Path $wizardRoot 'steamcmd/steamapps/workshop/content/108600'
        New-Item -ItemType Directory -Path (Split-Path $wizardContent -Parent) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $temporary 'content') -Destination $wizardContent -Recurse
        function Select-PZSetupServerIni { return $scanIni }
        foreach ($answer in @('','1')) { $answers.Enqueue($answer) }
        $wizardExisting = Get-PZSetupParameters -Mode Server -Action Existing
        Assert-True ($answers.Count -eq 0 -and $wizardExisting.SkipDownload -and -not $wizardExisting.ContainsKey('PlanOnly') -and $wizardExisting.ServerIni -eq $scanIni -and $wizardExisting.WorkshopContentPath -eq $wizardContent) 'The existing-download menu passes the selected folder and INI without requesting downloads.'
        Invoke-PZSetupRun -Parameters $wizardExisting
        Assert-True ([IO.File]::ReadAllText($scanIni).Contains('WorkshopItems=111;222')) 'The menu dispatcher applies validated settings using the existing downloader.'

        $pathWithSpaces = Write-Fixture 'wizard project/a folder with spaces/server settings.ini' $iniOriginal
        foreach ($answer in @('2', ('"' + $pathWithSpaces + '"'))) { $answers.Enqueue($answer) }
        $pickedPath = Select-PZSetupPath -Label 'Fixture settings file' -Kind File
        Assert-True ($pickedPath -eq $pathWithSpaces -and $answers.Count -eq 0) 'Typed file paths can be quoted and contain spaces.'

        $script:PZSetupRoot = Join-Path $temporary 'cancelled-wizard'
        foreach ($answer in @('1','3','0','0')) { $answers.Enqueue($answer) }
        Start-PZSetupMenu
        Assert-True ($answers.Count -eq 0 -and -not (Test-Path -LiteralPath $script:PZSetupRoot)) 'Back exits a setup step without creating any files.'

        # Deliberately omit a catalog: the error should return to the menu, then allow Exit.
        $script:PZSetupRoot = Join-Path $temporary 'broken-wizard'
        foreach ($answer in @('1','3','2','','1','','0')) { $answers.Enqueue($answer) }
        Start-PZSetupMenu
        Assert-True ($answers.Count -eq 0 -and -not (Test-Path -LiteralPath $script:PZSetupRoot)) 'Setup errors stay visible and return to the menu instead of closing the window.'
        foreach ($answer in @('4','','0')) { $answers.Enqueue($answer) }
        Start-PZSetupMenu
        Assert-True ($answers.Count -eq 0) 'Help returns to the main menu and permits a clean exit.'
    }

    # Client Steam state machine: accept an up-to-date item; retry a failed update; reject stale cache.
    $fakeClient = [FakeClientSession]::new(@{ '111'=(Join-Path $temporary 'content/111'); '222'=(Join-Path $temporary 'content/222') })
    $savedAppId = $env:SteamAppId
    $savedGameId = $env:SteamGameId
    $clientPaths = Invoke-PZClientWorkshopDownloads -Ids @('111','222') -Retries 2 -TimeoutSeconds 1 -SessionFactory { $fakeClient }.GetNewClosure()
    Assert-True ($clientPaths.Count -eq 2 -and $fakeClient.Subscribed.Count -eq 2 -and $fakeClient.Downloads.Count -eq 2 -and @($fakeClient.Downloads | Where-Object { $_ -eq 111 }).Count -eq 0) 'Steam client retries a failed update while accepting an already up-to-date item.'
    Assert-True ($fakeClient.Disposed -and $fakeClient.PumpCount -gt 0 -and $env:SteamAppId -eq $savedAppId -and $env:SteamGameId -eq $savedGameId) 'Client session cleanup restores process environment after success.'
    $fakeFailure = [FakeClientSession]::new(@{ '222'=(Join-Path $temporary 'content/222') })
    $fakeFailure.AlwaysFail = $true
    Assert-Throws { Invoke-PZClientWorkshopDownloads -Ids @('222') -Retries 2 -TimeoutSeconds 1 -SessionFactory { $fakeFailure }.GetNewClosure() } 'Client Workshop download failed'
    Assert-True ($fakeFailure.Disposed -and $fakeFailure.Downloads.Count -eq 2) 'Failed client updates cannot use a clean-looking old cache or skip the retry.'
    $fakePending = [FakeClientSession]::new(@{})
    $fakePending.PendingForever = $true
    Assert-Throws { Invoke-PZClientWorkshopDownloads -Ids @('222') -TimeoutSeconds 1 -SessionFactory { $fakePending }.GetNewClosure() } 'subscription timed out'
    Assert-True ($fakePending.Disposed) 'Client subscription timeout cleans up the Steam session.'

    $beforeFailure = [IO.File]::ReadAllText($scanIni)
    Assert-Throws { & (Join-Path $root 'Download-PZMods.ps1') @scanParameters -ExcludeMod Library } 'explicitly excluded'
    Assert-True ([IO.File]::ReadAllText($scanIni) -ceq $beforeFailure) 'Validation failure leaves live server INI untouched.'
    $failedStatus = Get-Content -LiteralPath (Join-Path $temporary 'scan/run-status.json') -Raw | ConvertFrom-Json
    Assert-True ($failedStatus.Status -eq 'failed' -and -not $failedStatus.ValidatedFromDownloads) 'A failed rerun invalidates the latest-run status even if older output files remain.'
    Assert-Throws { & (Join-Path $root 'Download-PZMods.ps1') -Mode Server -PlanOnly -ServerIni $scanIni -OutputDirectory (Join-Path $temporary 'invalid-preview') } 'cannot modify'
    Write-Fixture 'content/111/mods/Main/42/mod.info' "id=Main`nversionMax=42.20.0`n" | Out-Null
    Assert-Throws { & (Join-Path $root 'Download-PZMods.ps1') @scanParameters } 'does not support build'
    Write-Fixture 'content/111/mods/Main/42/mod.info' "id=Main`nversionMin=42.22.0`n" | Out-Null
    Assert-Throws { & (Join-Path $root 'Download-PZMods.ps1') @scanParameters } 'does not support build'

    # Native-process checks use a Python fake SteamCMD on macOS/Linux, with no network.
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        Write-Fixture 'content/111/mods/Main/42/mod.info' "id=Main`nrequire=Library,Implicit`n" | Out-Null
        $fakeDirectory = Join-Path $temporary 'fake-steamcmd'
        $fake = Write-Fixture 'fake-steamcmd/steamcmd.exe' @'
#!/usr/bin/env python3
import os,sys,json,pathlib
args=sys.argv[1:]
if '+runscript' not in args: sys.exit(0)
root=pathlib.Path(__file__).parent
state=root/'calls.json'
calls=json.loads(state.read_text()) if state.exists() else []
script=pathlib.Path(args[args.index('+runscript')+1]).read_text()
ids=[line.split()[2] for line in script.splitlines() if line.startswith('workshop_download_item ')]
calls.append(ids); state.write_text(json.dumps(calls))
for wid in ids:
    if wid=='222' and (os.environ.get('PZ_TEST_ALWAYS_FAIL')=='1' or len(calls)==1):
        print('ERROR! Download item 222 failed (Failure).')
    else:
        print(f'Success. Downloaded item {wid} to "{root}/steamapps/workshop/content/108600/{wid}" (100 bytes)')
sys.exit(0)
'@
        & chmod '+x' $fake
        New-Item -ItemType Directory -Path (Join-Path $fakeDirectory 'steamapps/workshop/content') -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $temporary 'content') -Destination (Join-Path $fakeDirectory 'steamapps/workshop/content/108600') -Recurse
        $nativeParameters = @{ Mode='Server'; CatalogPath=$fixtureCatalogPath; BuildVersion='42.21.0'; SteamCmdDirectory=$fakeDirectory; OutputDirectory=(Join-Path $temporary 'native'); Retries=2; BatchSize=15 }
        & (Join-Path $root 'Download-PZMods.ps1') @nativeParameters
        $calls = Get-Content -LiteralPath (Join-Path $fakeDirectory 'calls.json') -Raw | ConvertFrom-Json
        Assert-True ($calls.Count -eq 2 -and $calls[0].Count -eq 2 -and $calls[1].Count -eq 1 -and $calls[1][0] -eq '222') 'Retry only failed downloads, even when SteamCMD returns zero.'
        Remove-Item -LiteralPath (Join-Path $fakeDirectory 'calls.json')
        $env:PZ_TEST_ALWAYS_FAIL = '1'
        $nativeParameters.OutputDirectory = Join-Path $temporary 'native-failure'
        $nativeParameters.ServerIni = $scanIni
        Assert-Throws { & (Join-Path $root 'Download-PZMods.ps1') @nativeParameters } 'Workshop download failed'
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $temporary 'native-failure/server-mods.ini')) -and [IO.File]::ReadAllText($scanIni) -ceq $beforeFailure) 'Cached files never hide a failed download or trigger an INI update.'
        Remove-Item Env:PZ_TEST_ALWAYS_FAIL
    }
    Write-Host "PASS: $script:checks checks. No real Steam downloads or live server files were used."
} finally {
    if (Test-Path Env:PZ_TEST_ALWAYS_FAIL) { Remove-Item Env:PZ_TEST_ALWAYS_FAIL }
    Remove-Item -LiteralPath $temporary -Recurse -Force
}
