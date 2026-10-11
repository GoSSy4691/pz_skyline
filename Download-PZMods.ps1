#Requires -Version 5.1
<#
.SYNOPSIS
Set up the supplied Build 42 mods for a server or a Steam client, with a checked load order.
.EXAMPLE
.\Download-PZMods.ps1 -Mode Server -BuildVersion 42.21.0 -SteamCmdDirectory C:\PZServer
.EXAMPLE
.\Download-PZMods.ps1 -Mode Client -ServerProfile .\server-profile.json
.EXAMPLE
.\Download-PZMods.ps1 -Mode Server -BuildVersion 42.21.0 -PlanOnly
#>
[CmdletBinding()]
param(
    [ValidateSet('Server','Client')][string]$Mode,
    [string]$BuildVersion = '42.21.0',
    [string]$SteamCmdDirectory = (Join-Path $PSScriptRoot 'steamcmd'),
    [ValidatePattern('^[A-Za-z0-9_@.-]+$')][string]$SteamUser = 'anonymous',
    [string]$WorkshopContentPath,
    [string]$CatalogPath = (Join-Path $PSScriptRoot 'mods.catalog.json'),
    [string]$OutputDirectory,
    [ValidateSet('Multiplayer','AllRequested')][string]$Profile = 'Multiplayer',
    [string[]]$ExcludeMod = @(),
    [ValidatePattern('^\d+$')][string[]]$AdditionalWorkshopId = @(),
    [ValidateRange(1,10)][int]$Retries = 3,
    [ValidateRange(1,50)][int]$BatchSize = 15,
    [switch]$PlanOnly,
    [switch]$SkipDownload,
    [string]$ServerIni,
    [string]$ServerProfile,
    [string]$GameDirectory,
    [string]$ClientDataDirectory = (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Zomboid'),
    [ValidateRange(1,86400)][int]$ClientTimeoutSeconds = 1200
)

if ($PSBoundParameters.Count -eq 0) {
    & (Join-Path $PSScriptRoot 'Start-PZModSetup.ps1')
    return
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$runStatus = $null
$statusPath = $null
Import-Module (Join-Path $PSScriptRoot 'PZModTools.psm1') -Force -DisableNameChecking
$Mode = Select-PZSetupMode $Mode
if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $PSScriptRoot 'output'
    if ($Mode -eq 'Client') { $OutputDirectory = Join-Path $OutputDirectory 'client' }
}
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$utf8 = [Text.UTF8Encoding]::new($false)
$statusPath = Join-Path $OutputDirectory 'run-status.json'
$runStatus = [ordered]@{ Status = 'running'; Mode = $Mode; BuildVersion = $BuildVersion; Profile = $Profile; ValidatedFromDownloads = $false; RuntimeTested = $false; ClientProfileInstalled = $false; ServerIniUpdated = $false; ClientPackagePath = ''; Message = '' }
[IO.File]::WriteAllText($statusPath, ($runStatus | ConvertTo-Json), $utf8)
trap {
    $failure = $_
    if ($null -ne $runStatus -and $statusPath) {
        $runStatus.Status = 'failed'
        $runStatus.Message = $failure.Exception.Message
        [IO.File]::WriteAllText($statusPath, ($runStatus | ConvertTo-Json), $utf8)
    }
    throw $failure
}
if ($Mode -eq 'Client' -and $ServerIni) { throw '-ServerIni is only available in Server mode.' }
if ($Mode -eq 'Server' -and $ServerProfile) { throw '-ServerProfile is only available in Client mode.' }
if ($Mode -eq 'Client' -and ($Profile -ne 'Multiplayer' -or $ExcludeMod.Count -gt 0)) {
    throw 'Client mode uses the multiplayer server mod selection. Change the server profile, rather than excluding required client mods.'
}
$serverSelection = $null
if ($ServerProfile) {
    if ($AdditionalWorkshopId.Count -gt 0) { throw 'With -ServerProfile, add new Workshop items on the server and export a fresh profile first.' }
    $serverSelection = Read-PZServerProfile $ServerProfile
    if ($PSBoundParameters.ContainsKey('BuildVersion') -and (ConvertTo-BuildVersion $BuildVersion) -ne (ConvertTo-BuildVersion $serverSelection.BuildVersion)) {
        throw 'The client -BuildVersion differs from the supplied server profile.'
    }
    $BuildVersion = $serverSelection.BuildVersion
    $runStatus.BuildVersion = $BuildVersion
}
$build = ConvertTo-BuildVersion $BuildVersion
if ($build.Major -ne 42) { throw 'This catalog is for Build 42 only.' }
if ($PlanOnly -and $ServerIni) { throw '-PlanOnly cannot modify a server INI. Use the validated download/scan mode.' }
if ($ServerIni -and -not (Test-Path -LiteralPath $ServerIni -PathType Leaf)) { throw "Server INI not found: $ServerIni" }
$catalog = Get-Content -LiteralPath $CatalogPath -Raw | ConvertFrom-Json
if ($catalog.SchemaVersion -ne 1 -or $catalog.AppId -ne '108600') { throw 'Unsupported catalog schema or game App ID.' }
$requestedEntries = @($catalog.Mods)
if ($requestedEntries.Count -eq 0) { throw 'The catalog contains no mods.' }
$dependencyEntries = @()
if ($catalog.PSObject.Properties['Dependencies']) { $dependencyEntries = @($catalog.Dependencies) }
$entries = @($requestedEntries) + @($dependencyEntries)
$requestedHoldbacks = @{}
foreach ($entry in $requestedEntries) {
    if (-not $entry.MultiplayerEnabled -and -not ($entry.PSObject.Properties['AllowDependencyAutoEnable'] -and $entry.AllowDependencyAutoEnable)) {
        $requestedHoldbacks[(ConvertTo-ModKey $entry.ModId)] = $true
    }
}
$entryById = @{}
foreach ($entry in $entries) {
    if ($entry.WorkshopId -notmatch '^\d+$') { throw "Invalid Workshop ID for $($entry.ModId)." }
    foreach ($key in @(@($entry.ModId) + @($entry.Aliases) | ForEach-Object { ConvertTo-ModKey $_ } | Select-Object -Unique)) {
        if ($entryById.ContainsKey($key)) { throw "Duplicate catalog mod/alias: $key" }
        $entryById[$key] = $entry
    }
}
$excludedKeys = @{}
foreach ($id in $ExcludeMod) {
    $key = ConvertTo-ModKey $id
    if (-not $entryById.ContainsKey($key)) { throw "Unknown -ExcludeMod ID: $id" }
    $excludedKeys[(ConvertTo-ModKey $entryById[$key].ModId)] = $true
}
$activeEntries = @($requestedEntries | Where-Object {
    ($Profile -eq 'AllRequested' -or $_.MultiplayerEnabled) -and
    -not $excludedKeys.ContainsKey((ConvertTo-ModKey $_.ModId))
})
if ($serverSelection) {
    $activeEntries = @()
    $previousId = $null
    foreach ($mod in $serverSelection.Mods) {
        $key = ConvertTo-ModKey $mod.ModId
        $known = $null
        if ($entryById.ContainsKey($key)) { $known = $entryById[$key] }
        if ($null -eq $known -and $mod.PSObject.Properties['RequestedId']) {
            $requestedKey = ConvertTo-ModKey $mod.RequestedId
            if ($entryById.ContainsKey($requestedKey)) { $known = $entryById[$requestedKey] }
        }
        if ($null -ne $known -and [string]$known.WorkshopId -ne [string]$mod.WorkshopId) {
            throw "Server profile Workshop mapping differs from the catalog for $($mod.ModId). Use the server's current catalog."
        }
        $entry = [pscustomobject]@{
            ModId = [string]$mod.ModId; WorkshopId = [string]$mod.WorkshopId
            Aliases = @(); Requires = @(); LoadAfter = @(); Priority = $activeEntries.Count
            MultiplayerEnabled = $true; DisabledReason = ''; Notes = 'Selected by the server profile.'
            Source = "https://steamcommunity.com/sharedfiles/filedetails/?id=$($mod.WorkshopId)"
        }
        if ($null -ne $known) {
            $entry.Aliases = @(@($known.ModId) + @($known.Aliases) | Where-Object { $_ -ne $entry.ModId } | Select-Object -Unique)
            $entry.Requires = @($known.Requires)
            $entry.LoadAfter = @($known.LoadAfter)
            if ($known.PSObject.Properties['MinBuild']) { $entry | Add-Member -NotePropertyName MinBuild -NotePropertyValue $known.MinBuild }
        }
        # Preserve the server's exact order, while still checking current dependency constraints.
        if ($previousId) { $entry.LoadAfter += $previousId }
        $activeEntries += $entry
        $previousId = $entry.ModId
    }
}
if ($activeEntries.Count -eq 0) { throw 'The chosen profile enables no mods.' }
# Resolve researched dependencies before downloads, including libraries outside the requested list.
if (-not $serverSelection) {
    $initialKeys = @{}
    foreach ($entry in $activeEntries) { $initialKeys[(ConvertTo-ModKey $entry.ModId)] = $true }
    for ($position = 0; $position -lt $activeEntries.Count; $position++) {
        foreach ($id in @($activeEntries[$position].Requires)) {
            $key = ConvertTo-ModKey $id
            if (-not $entryById.ContainsKey($key)) { throw "Catalog dependency '$id' has no Workshop mapping. Update the catalog before downloading." }
            $dependency = $entryById[$key]
            $dependencyKey = ConvertTo-ModKey $dependency.ModId
            if ($excludedKeys.ContainsKey($dependencyKey)) { throw "Required mod '$($dependency.ModId)' was explicitly excluded." }
            if ($Profile -eq 'Multiplayer' -and ($requestedHoldbacks.ContainsKey($dependencyKey) -or ($dependency.PSObject.Properties['BlockAutoEnable'] -and $dependency.BlockAutoEnable))) {
                throw "Required mod '$($dependency.ModId)' is held out of the multiplayer selection. $($dependency.DisabledReason) Review the dependent mod selection."
            }
            if (-not $initialKeys.ContainsKey($dependencyKey)) {
                $activeEntries += $dependency
                $initialKeys[$dependencyKey] = $true
            }
        }
    }
}
$initialActiveKeys = @{}
foreach ($entry in $activeEntries) {
    foreach ($id in @($entry.ModId) + @($entry.Aliases)) { $initialActiveKeys[(ConvertTo-ModKey $id)] = $true }
    if ($entry.PSObject.Properties['MinBuild'] -and $entry.MinBuild -and $build -lt (ConvertTo-BuildVersion $entry.MinBuild)) {
        throw "'$($entry.ModId)' does not support build $BuildVersion according to the catalog minimum $($entry.MinBuild)."
    }
}
foreach ($conflict in $catalog.Conflicts) {
    $present = @($conflict.ModIds | Where-Object { $initialActiveKeys.ContainsKey((ConvertTo-ModKey $_)) })
    if ($present.Count -eq $conflict.ModIds.Count) { throw "Incompatible selection: $($present -join ' + '). $($conflict.Reason) Source: $($conflict.Source)" }
}
$workshopIds = @(@($activeEntries | ForEach-Object { [string]$_.WorkshopId }) + $AdditionalWorkshopId | Select-Object -Unique)
if ($serverSelection) { $workshopIds = @($activeEntries | ForEach-Object { [string]$_.WorkshopId } | Select-Object -Unique) }
$downloadedWorkshopIds = [Collections.Generic.List[string]]::new()
foreach ($id in $workshopIds) { $downloadedWorkshopIds.Add($id) }
$runStatus.BuildVersion = $BuildVersion
Write-Host "$($requestedEntries.Count) requested mods; $($dependencyEntries.Count) additional dependency entries; $($workshopIds.Count) unique Workshop downloads; $($activeEntries.Count) initially enabled."
Write-Host "Setup mode: $Mode. Target game build: $BuildVersion."
if ($Mode -eq 'Client' -and -not $serverSelection) {
    Write-Host 'Using the catalog multiplayer selection. Supply -ServerProfile server-profile.json to match a specific server configuration.'
}
foreach ($entry in $entries | Where-Object { -not $serverSelection -and $_ -notin $activeEntries }) {
    $reason = if ($excludedKeys.ContainsKey((ConvertTo-ModKey $entry.ModId))) { 'Excluded by -ExcludeMod.' } else { $entry.DisabledReason }
    Write-Warning "Not enabled in this profile: $($entry.ModId). $reason"
}
$planEntries = if ($serverSelection) { $activeEntries } else { $entries }
$planEntries | Select-Object ModId, WorkshopId, @{ Name = 'EnabledInProfile'; Expression = { $_ -in $activeEntries } }, @{ Name = 'WorkshopSelected'; Expression = { [string]$_.WorkshopId -in $workshopIds } }, DisabledReason, Source |
    Export-Csv -LiteralPath (Join-Path $OutputDirectory 'download-plan.csv') -NoTypeInformation -Encoding UTF8

function Install-SteamCmd {
    $executable = Join-Path $SteamCmdDirectory 'steamcmd.exe'
    if (Test-Path -LiteralPath $executable -PathType Leaf) { return [IO.Path]::GetFullPath($executable) }
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        throw 'SteamCMD installation in this script targets Windows. Use -PlanOnly or -SkipDownload for offline checks on other systems.'
    }
    New-Item -ItemType Directory -Path $SteamCmdDirectory -Force | Out-Null
    $zip = Join-Path $SteamCmdDirectory 'steamcmd-installer.zip'
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Write-Host 'Downloading SteamCMD from Valve...'
    Invoke-WebRequest -UseBasicParsing -Uri 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip' -OutFile $zip
    Expand-Archive -LiteralPath $zip -DestinationPath $SteamCmdDirectory -Force
    Remove-Item -LiteralPath $zip
    if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) { throw 'SteamCMD installer did not contain steamcmd.exe.' }
    return [IO.Path]::GetFullPath($executable)
}

function Invoke-WorkshopDownloads {
    param([string]$Executable, [string[]]$Ids)
    $logDirectory = Join-Path $OutputDirectory 'logs'
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    # Keep passwords/Steam Guard input in SteamCMD itself, never in this script or its arguments.
    if ($SteamUser -ne 'anonymous') {
        Write-Host 'Log in directly in SteamCMD. Enter the password and Steam Guard code when it prompts.'
        & $Executable '+login' $SteamUser '+quit'
        if ($LASTEXITCODE -ne 0) { throw 'SteamCMD login failed.' }
    }
    $pending = @($Ids)
    for ($attempt = 1; $attempt -le $Retries -and $pending.Count -gt 0; $attempt++) {
        $failed = [Collections.Generic.List[string]]::new()
        for ($offset = 0; $offset -lt $pending.Count; $offset += $BatchSize) {
            $last = [Math]::Min($offset + $BatchSize - 1, $pending.Count - 1)
            $batch = @($pending[$offset..$last])
            $tag = "$([DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fffffff'))-$attempt-$offset"
            $runScript = Join-Path $logDirectory "$tag.steamcmd.txt"
            $commands = @('@ShutdownOnFailedCommand 0','@NoPromptForPassword 0')
            foreach ($id in $batch) { $commands += "workshop_download_item 108600 $id validate" }
            $commands += 'quit'
            [IO.File]::WriteAllLines($runScript, $commands, [Text.Encoding]::ASCII)
            $lines = [Collections.Generic.List[string]]::new()
            Write-Host "Download attempt $attempt/$Retries, items $($offset + 1)-$($last + 1) of $($pending.Count)."
            $oldPreference = $ErrorActionPreference
            try {
                $ErrorActionPreference = 'Continue'
                & $Executable '+login' $SteamUser '+runscript' $runScript 2>&1 | ForEach-Object {
                    $line = [string]$_
                    $lines.Add($line)
                    Write-Host $line
                }
                $exitCode = $LASTEXITCODE
            } finally { $ErrorActionPreference = $oldPreference }
            [IO.File]::WriteAllLines((Join-Path $logDirectory "$tag.log"), $lines.ToArray(), $utf8)
            $log = $lines -join "`n"
            foreach ($id in $batch) {
                $success = $log -match ("(?im)(?:Success\.\s*)?Downloaded item\s+" + [regex]::Escape($id) + '\s+to\s')
                $directory = Join-Path $WorkshopContentPath $id
                $infoFiles = @(if (Test-Path -LiteralPath $directory -PathType Container) {
                    Get-ChildItem -LiteralPath $directory -Filter mod.info -File -Recurse
                })
                if (-not $success -or $infoFiles.Count -eq 0 -or $exitCode -ne 0) { $failed.Add($id) }
            }
        }
        $pending = @($failed.ToArray())
        if ($pending.Count -gt 0) { Write-Warning "Not confirmed downloaded: $($pending -join ', ')." }
    }
    if ($pending.Count -gt 0) {
        throw "Workshop download failed for: $($pending -join ', '). See output/logs. If anonymous login was denied, rerun with -SteamUser YOUR_STEAM_LOGIN using an account that owns Project Zomboid. No validated configuration was written."
    }
}

$itemDirectories = @{}
if ($Mode -eq 'Client' -and -not $PlanOnly -and -not $SkipDownload) {
    if ($WorkshopContentPath) { throw 'Client downloads use Steam-reported installation paths. -WorkshopContentPath is only for -SkipDownload.' }
    $itemDirectories = Invoke-PZClientWorkshopDownloads -Ids $workshopIds -GameDirectory $GameDirectory -Retries $Retries -TimeoutSeconds $ClientTimeoutSeconds
} elseif (-not $PlanOnly -and -not $SkipDownload) {
    $SteamCmdDirectory = [IO.Path]::GetFullPath($SteamCmdDirectory)
    if (-not $WorkshopContentPath) { $WorkshopContentPath = Join-Path $SteamCmdDirectory 'steamapps/workshop/content/108600' }
    $expectedContent = [IO.Path]::GetFullPath((Join-Path $SteamCmdDirectory 'steamapps/workshop/content/108600'))
    if ([IO.Path]::GetFullPath($WorkshopContentPath) -ne $expectedContent) {
        throw '-WorkshopContentPath overrides are for -SkipDownload. SteamCMD downloads into its own steamapps/workshop/content/108600 folder.'
    }
    $executable = Install-SteamCmd
    Push-Location $SteamCmdDirectory
    try { Invoke-WorkshopDownloads -Executable $executable -Ids $workshopIds } finally { Pop-Location }
}
if ($Mode -eq 'Client' -and $SkipDownload -and -not $WorkshopContentPath) {
    throw 'Client -SkipDownload requires -WorkshopContentPath pointing to the existing Steam Workshop content/108600 directory.'
}
if (-not $WorkshopContentPath) { $WorkshopContentPath = Join-Path $SteamCmdDirectory 'steamapps/workshop/content/108600' }

$records = [Collections.Generic.List[object]]::new()
$selectedKeys = @{}
$metadataByWorkshop = @{}
$metadataByKey = @{}
function Add-WorkshopMetadata {
    param([string]$Id)
    if ($metadataByWorkshop.ContainsKey($Id)) { return }
    if ($Id -notin $downloadedWorkshopIds) {
        if (-not $SkipDownload) {
            Write-Host "Downloading newly required Workshop dependency: $Id"
            if ($Mode -eq 'Client') {
                $newDirectories = Invoke-PZClientWorkshopDownloads -Ids @($Id) -GameDirectory $GameDirectory -Retries $Retries -TimeoutSeconds $ClientTimeoutSeconds
                $itemDirectories[$Id] = $newDirectories[$Id]
            } else {
                Push-Location $SteamCmdDirectory
                try { Invoke-WorkshopDownloads -Executable $executable -Ids @($Id) } finally { Pop-Location }
            }
        }
        $downloadedWorkshopIds.Add($Id)
    }
    $itemDirectory = if ($itemDirectories.ContainsKey($Id)) { $itemDirectories[$Id] } else { Join-Path $WorkshopContentPath $Id }
    $metadata = @(Get-B42ModMetadata -ItemDirectory $itemDirectory -WorkshopId $Id -BuildVersion $build)
    $metadataByWorkshop[$Id] = $metadata
    foreach ($mod in $metadata) {
        if (-not $metadataByKey.ContainsKey($mod.Key)) { $metadataByKey[$mod.Key] = @() }
        $metadataByKey[$mod.Key] += $mod
    }
}
if (-not $PlanOnly) { foreach ($id in $workshopIds) { Add-WorkshopMetadata $id } }

function Add-ActiveEntry {
    param([object]$Entry)
    $entryKey = ConvertTo-ModKey $Entry.ModId
    if ($selectedKeys.ContainsKey($entryKey)) { return }
    if ($excludedKeys.ContainsKey($entryKey)) { throw "Required mod '$($Entry.ModId)' was explicitly excluded." }
    if (-not $serverSelection -and $Profile -eq 'Multiplayer' -and ($requestedHoldbacks.ContainsKey($entryKey) -or ($Entry.PSObject.Properties['BlockAutoEnable'] -and $Entry.BlockAutoEnable))) {
        throw "Required mod '$($Entry.ModId)' is held out of the multiplayer selection. $($Entry.DisabledReason) Review the dependent mod selection."
    }
    if ($PlanOnly) {
        $metadata = [pscustomobject]@{ Id = $Entry.ModId; Key = $entryKey; WorkshopId = $Entry.WorkshopId; Requires = @(); LoadAfter = @(); LoadBefore = @(); Incompatible = @(); InfoPaths = @(); MinBuild = $null; MaxBuild = $null }
    } else {
        Add-WorkshopMetadata ([string]$Entry.WorkshopId)
        $metadata = $null
        foreach ($id in @($Entry.ModId) + @($Entry.Aliases)) {
            $candidateKey = ConvertTo-ModKey $id
            $matchesForId = @($metadataByWorkshop[[string]$Entry.WorkshopId] | Where-Object { $_.Key -eq $candidateKey })
            if ($matchesForId.Count -gt 1) { throw "Multiple B42 folders provide '$id' in Workshop item $($Entry.WorkshopId)." }
            if ($matchesForId.Count -eq 1) { $metadata = $matchesForId[0]; break }
        }
        if ($null -eq $metadata) {
            throw "No usable B42 '$($Entry.ModId)' (or listed alias) in Workshop $($Entry.WorkshopId) for build $BuildVersion. Check the Workshop page, adjust mods.catalog.json or use -ExcludeMod '$($Entry.ModId)'. No validated configuration was written."
        }
    }
    $minimum = $metadata.MinBuild
    if ($Entry.PSObject.Properties['MinBuild'] -and $Entry.MinBuild) {
        $catalogMinimum = ConvertTo-BuildVersion $Entry.MinBuild
        if ($null -eq $minimum -or $catalogMinimum -gt $minimum) { $minimum = $catalogMinimum }
    }
    if (($null -ne $minimum -and $build -lt $minimum) -or ($null -ne $metadata.MaxBuild -and $build -gt $metadata.MaxBuild)) {
        throw "'$($Entry.ModId)' does not support build $BuildVersion according to its version bounds (min=$minimum, max=$($metadata.MaxBuild)). Choose a compatible release or exclude it; bounds are not bypassed."
    }
    $selectedKeys[$entryKey] = $true
    $records.Add([pscustomobject]@{ Entry = $Entry; Metadata = $metadata; Index = $records.Count })
    if ($metadata.Id -cne $Entry.ModId) { Write-Host "Resolved $($Entry.ModId) -> $($metadata.Id) from downloaded metadata." }
}
foreach ($entry in $activeEntries) { Add-ActiveEntry $entry }
for ($position = 0; $position -lt $records.Count; $position++) {
    $record = $records[$position]
    foreach ($id in @($record.Entry.Requires) + @($record.Metadata.Requires)) {
        $key = ConvertTo-ModKey $id
        $alreadyActive = @($records | Where-Object {
            $_.Metadata.Key -eq $key -or (ConvertTo-ModKey $_.Entry.ModId) -eq $key -or $key -in @($_.Entry.Aliases | ForEach-Object { ConvertTo-ModKey $_ })
        })
        if ($alreadyActive.Count -gt 0) { continue }
        if ($serverSelection) {
            throw "Downloaded requirements differ from the server profile: missing '$id'. Ask the server owner for a fresh profile; no client profile was installed."
        }
        if ($entryById.ContainsKey($key)) {
            Add-ActiveEntry $entryById[$key]
            Write-Host "Enabled required dependency: $id"
        } elseif ($metadataByKey.ContainsKey($key) -and $metadataByKey[$key].Count -eq 1) {
            $dependency = $metadataByKey[$key][0]
            $entry = [pscustomobject]@{ ModId = $dependency.Id; WorkshopId = $dependency.WorkshopId; Aliases = @(); Requires = @(); LoadAfter = @(); Priority = 20; Notes = 'Dependency discovered in downloaded mod.info.'; Source = "https://steamcommunity.com/sharedfiles/filedetails/?id=$($dependency.WorkshopId)" }
            Add-ActiveEntry $entry
            Write-Host "Enabled required submod: $id"
        } else {
            throw "'$($record.Metadata.Id)' requires missing or ambiguous '$id'. Download its B42 Workshop item with -AdditionalWorkshopId ID, or add an exact mapping to mods.catalog.json and rerun. No validated configuration was written."
        }
    }
}
$activeIds = @($records | ForEach-Object { $_.Entry.ModId })
$activeKeys = @{}
foreach ($record in $records) {
    foreach ($id in @($record.Entry.ModId) + @($record.Entry.Aliases) + @($record.Metadata.Id)) { $activeKeys[(ConvertTo-ModKey $id)] = $true }
}
foreach ($conflict in $catalog.Conflicts) {
    $present = @($conflict.ModIds | Where-Object { $activeKeys.ContainsKey((ConvertTo-ModKey $_)) })
    if ($present.Count -eq $conflict.ModIds.Count) { throw "Incompatible selection: $($present -join ' + '). $($conflict.Reason) Source: $($conflict.Source)" }
}
$ordered = @(Get-PZLoadOrder $records.ToArray())
$modIds = @($ordered | ForEach-Object { $_.Metadata.Id })
$enabledWorkshopIds = @($ordered | ForEach-Object { $_.Metadata.WorkshopId } | Select-Object -Unique)
if ($serverSelection -and ($modIds -join ';') -cne (($serverSelection.Mods | ForEach-Object { $_.ModId }) -join ';')) {
    throw 'Downloaded mods or requirements differ from the server profile. Ask the server owner for a fresh profile; no client profile was installed.'
}
$clientProviderScan = $null
if ($Mode -eq 'Client' -and -not $PlanOnly) {
    $clientWorkshopRoots = if ($SkipDownload) { @($WorkshopContentPath) } else { @($itemDirectories.Values | ForEach-Object { Split-Path -Parent $_ } | Select-Object -Unique) }
    $clientProviderScan = Test-PZClientModProviders -SelectedMetadata @($ordered | ForEach-Object { $_.Metadata }) -WorkshopContentRoots $clientWorkshopRoots -ClientDataDirectory $ClientDataDirectory -BuildVersion $build
}
$modsLine = 'Mods=' + ($modIds -join ';')
$workshopLine = 'WorkshopItems=' + ($enabledWorkshopIds -join ';')
$activeRuleIds = @($activeKeys.Keys)
$requiredServerSettings = Get-PZRequiredServerSettings -Catalog $catalog -ActiveIds $activeRuleIds
$setupActions = @(Get-PZSetupActions -Catalog $catalog -ActiveIds $activeRuleIds -Mode $Mode)
if ($serverSelection -and $serverSelection.PSObject.Properties['SetupActions']) {
    $setupActions = @($serverSelection.SetupActions)
}
$suffix = if ($PlanOnly) { '.preview' } else { '' }
$serverLines = @($modsLine, $workshopLine)
foreach ($key in @($requiredServerSettings.Keys | Sort-Object)) { $serverLines += "$key=$($requiredServerSettings[$key])" }
[IO.File]::WriteAllLines((Join-Path $OutputDirectory "server-mods$suffix.ini"), $serverLines, $utf8)
[IO.File]::WriteAllLines((Join-Path $OutputDirectory "load-order$suffix.txt"), $modIds, $utf8)
$defaultLines = @('VERSION = 1,','','mods','{')
$defaultLines += @($modIds | ForEach-Object { "    mod = $_," })
$defaultLines += @('}','','maps','{','}')
[IO.File]::WriteAllLines((Join-Path $OutputDirectory "default$suffix.txt"), $defaultLines, $utf8)
$report = [ordered]@{
    ValidatedFromDownloads = (-not $PlanOnly); RuntimeTested = $false; ValidationScope = 'Downloaded metadata and researched catalog constraints; no server/game runtime test.'
    Mode = $Mode; BuildVersion = $BuildVersion; Profile = $Profile; ServerProfile = $ServerProfile
    CatalogVerifiedDate = $catalog.VerifiedDate; DownloadWorkshopIds = @($downloadedWorkshopIds.ToArray())
    RequiredServerSettings = $requiredServerSettings; SetupActions = $setupActions; ClientDuplicateProviderScan = $clientProviderScan
    EnabledMods = @($ordered | ForEach-Object { [ordered]@{ RequestedId = $_.Entry.ModId; ActualId = $_.Metadata.Id; WorkshopId = $_.Metadata.WorkshopId; InfoPaths = $_.Metadata.InfoPaths; Notes = $_.Entry.Notes; Source = $_.Entry.Source } })
    DisabledMods = @($entries | Where-Object { -not $activeKeys.ContainsKey((ConvertTo-ModKey $_.ModId)) } | ForEach-Object {
        [ordered]@{ ModId = $_.ModId; DisabledReason = $(if ($excludedKeys.ContainsKey((ConvertTo-ModKey $_.ModId))) { 'Excluded by -ExcludeMod.' } else { $_.DisabledReason }); Source = $_.Source }
    })
}
[IO.File]::WriteAllText((Join-Path $OutputDirectory "validation$suffix.json"), ($report | ConvertTo-Json -Depth 8), $utf8)
if ($ServerIni) {
    $backup = Set-PZServerModSettings -Path $ServerIni -ModsLine $modsLine -WorkshopLine $workshopLine -AdditionalSettings $requiredServerSettings
    $runStatus.ServerIniUpdated = $true
    Write-Host "Updated $ServerIni. Original backup: $backup"
}
# Publish a player profile only after the selected server settings have been applied.
if ($Mode -eq 'Server') {
    $shareProfile = [ordered]@{
        SchemaVersion = 1; AppId = '108600'; ValidatedFromDownloads = (-not $PlanOnly); BuildVersion = $BuildVersion
        RuntimeTested = $false; SetupActions = @(Get-PZSetupActions -Catalog $catalog -ActiveIds $activeRuleIds -Mode Client)
        Mods = @($ordered | ForEach-Object { [ordered]@{ ModId = $_.Metadata.Id; RequestedId = $_.Entry.ModId; WorkshopId = $_.Metadata.WorkshopId } })
    }
    $profileDestination = Join-Path $OutputDirectory "server-profile$suffix.json"
    $profileTemporary = "$profileDestination.tmp-$([guid]::NewGuid().ToString('N'))"
    $profileBackup = "$profileDestination.previous-$([guid]::NewGuid().ToString('N'))"
    try {
        [IO.File]::WriteAllText($profileTemporary, ($shareProfile | ConvertTo-Json -Depth 8), $utf8)
        if (Test-Path -LiteralPath $profileDestination -PathType Leaf) { [IO.File]::Replace($profileTemporary, $profileDestination, $profileBackup) }
        else { [IO.File]::Move($profileTemporary, $profileDestination) }
    } finally {
        if (Test-Path -LiteralPath $profileTemporary) { Remove-Item -LiteralPath $profileTemporary }
        if (Test-Path -LiteralPath $profileBackup) { Remove-Item -LiteralPath $profileBackup }
    }
    if (-not $PlanOnly) {
        $runStatus.ClientPackagePath = Export-PZClientSetup -ProjectDirectory $PSScriptRoot -CatalogPath $CatalogPath -ServerProfile (Join-Path $OutputDirectory 'server-profile.json') -OutputDirectory $OutputDirectory
        Write-Host "Player setup ZIP prepared: $($runStatus.ClientPackagePath)"
    }
}
if ($Mode -eq 'Client' -and -not $PlanOnly) {
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT -and (Get-Process -Name ProjectZomboid64,ProjectZomboid32 -ErrorAction SilentlyContinue)) {
        throw 'Close Project Zomboid before installing the client profile, then rerun.'
    }
    $clientProfile = Set-PZClientProfile -Source (Join-Path $OutputDirectory 'default.txt') -ClientDataDirectory $ClientDataDirectory
    $runStatus.ClientProfileInstalled = $true
    Write-Host "Installed client mod profile: $($clientProfile.Path)"
    if ($clientProfile.Backup) { Write-Host "Previous client profile backup: $($clientProfile.Backup)" }
    Write-Host 'Start Project Zomboid through Steam, check the texture mods in the Mods menu, restart if requested, then join your server.'
    Write-Host 'Your game build and Workshop mod versions must match the server. The server controls which mods load when joining.'
}
if ($PlanOnly) {
    Write-Warning 'Preview only: downloaded mod.info files have not been checked. Do not apply the preview INI as a validated server configuration.'
} else {
    Write-Host "Metadata checks passed for $($modIds.Count) enabled mods in dependency order. Files: $OutputDirectory"
}
foreach ($action in $setupActions) { Write-Host "Required next step: $($action.Text)" -ForegroundColor Yellow }
if (-not $PlanOnly) { Write-Host 'Runtime compatibility still needs a test server startup, player join, and gameplay/log check.' }
$runStatus.Status = if ($PlanOnly) { 'preview' } else { 'validated' }
$runStatus.ValidatedFromDownloads = (-not $PlanOnly)
[IO.File]::WriteAllText($statusPath, ($runStatus | ConvertTo-Json), $utf8)
