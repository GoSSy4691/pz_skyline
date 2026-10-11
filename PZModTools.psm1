Set-StrictMode -Version Latest

function ConvertTo-ModKey {
    param([Parameter(Mandatory)][string]$Id)
    # Match legacy exports to modern IDs, but retain mod.info's actual ID for output.
    return (($Id.Trim() -replace '^[\\/]+', '') -replace '^\d+[\\/]', '')
}

function ConvertTo-BuildVersion {
    param([Parameter(Mandatory)][string]$Value)
    if ($Value -notmatch '^\d+(\.\d+){0,3}$') {
        throw "Invalid build version '$Value'. Use a number such as 42.21.0."
    }
    $parts = @($Value.Split('.'))
    while ($parts.Count -lt 4) { $parts += '0' }
    return [version]($parts -join '.')
}

function Read-PZModInfo {
    param([Parameter(Mandatory)][string[]]$Paths)
    $values = @{}
    foreach ($path in $Paths) {
        $layer = @{}
        foreach ($line in [IO.File]::ReadAllLines($path)) {
            if ($line -match '^\s*([^=#]+?)\s*=\s*(.*?)\s*$') {
                $key = $Matches[1].Trim().ToLowerInvariant()
                $value = $Matches[2].Trim()
                if ($layer.ContainsKey($key) -and $key -in @('require','loadmodafter','loadmodbefore','incompatible','loadafter','loadbefore','incompatiblemods')) {
                    $layer[$key] += ',' + $value
                } else { $layer[$key] = $value }
            }
        }
        foreach ($key in $layer.Keys) { $values[$key] = $layer[$key] }
    }
    return $values
}

function Split-PZModIds {
    param([AllowNull()][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return }
    foreach ($part in ($Value -split '[,;]')) {
        if (-not [string]::IsNullOrWhiteSpace($part)) { ConvertTo-ModKey $part }
    }
}

function Get-B42ModMetadata {
    param(
        [Parameter(Mandatory)][string]$ItemDirectory,
        [Parameter(Mandatory)][string]$WorkshopId,
        [Parameter(Mandatory)][version]$BuildVersion,
        [string]$ModDirectory
    )
    $modsRoot = Join-Path $ItemDirectory 'mods'
    if (-not (Test-Path -LiteralPath $modsRoot -PathType Container)) {
        $modsRoot = Join-Path $ItemDirectory 'Contents/mods'
    }
    if (-not (Test-Path -LiteralPath $modsRoot -PathType Container)) { return }
    $folders = if ($ModDirectory) { @(Get-Item -LiteralPath $ModDirectory -ErrorAction Stop) } else { @(Get-ChildItem -LiteralPath $modsRoot -Directory | Sort-Object Name) }
    foreach ($folder in $folders) {
        $hasVersionFolders = $false
        $candidates = @(
            foreach ($child in (Get-ChildItem -LiteralPath $folder.FullName -Directory)) {
                if ($child.Name -match '^42(\.\d+){0,3}$') {
                    $hasVersionFolders = $true
                    $version = ConvertTo-BuildVersion $child.Name
                    # The game's version-folder selector compares major/minor; native
                    # versionMin/versionMax checks below retain full version precision.
                    if ($version.Major -eq $BuildVersion.Major -and $version.Minor -le $BuildVersion.Minor) {
                        [pscustomobject]@{ Directory = $child.FullName; Version = $version }
                    }
                }
            }
        )
        $selected = $candidates | Sort-Object Version -Descending | Select-Object -First 1
        if ($hasVersionFolders -and $null -eq $selected) { continue }
        $commonInfo = Join-Path $folder.FullName 'common/mod.info'
        $paths = @()
        $commonValues = @{}
        $versionInfo = $null
        if (Test-Path -LiteralPath $commonInfo -PathType Leaf) { $paths += $commonInfo }
        if ($paths.Count -gt 0) { $commonValues = Read-PZModInfo @($commonInfo) }
        if ($null -ne $selected) {
            $versionInfo = Join-Path $selected.Directory 'mod.info'
            if (Test-Path -LiteralPath $versionInfo -PathType Leaf) { $paths += $versionInfo }
        }
        # A B41 root mod.info must never stand in for an unavailable B42 variant.
        if ($paths.Count -eq 0) { continue }
        # Game metadata comes from the chosen version file, with common only as a fallback.
        # Common sorter directives are handled separately below.
        $values = $commonValues
        if ($versionInfo -and (Test-Path -LiteralPath $versionInfo -PathType Leaf)) { $values = Read-PZModInfo @($versionInfo) }
        if (-not $values.ContainsKey('id') -or [string]::IsNullOrWhiteSpace($values['id'])) {
            throw "Missing id= in $($paths -join ', ')."
        }
        $minBuild = $null
        $maxBuild = $null
        foreach ($key in @('versionmin','minversion')) {
            if ($values.ContainsKey($key) -and $values[$key]) { $minBuild = ConvertTo-BuildVersion $values[$key] }
        }
        foreach ($key in @('versionmax','maxversion')) {
            if ($values.ContainsKey($key) -and $values[$key]) { $maxBuild = ConvertTo-BuildVersion $values[$key] }
        }
        [pscustomobject]@{
            Id = $values['id']; Key = ConvertTo-ModKey $values['id']
            WorkshopId = $WorkshopId; Folder = $folder.FullName; InfoPaths = $paths
            Requires = @(Split-PZModIds $values['require'])
            # The included Mod Load Order Sorter also uses these common/mod.info keys.
            LoadAfter = @(@(Split-PZModIds $values['loadmodafter']) + @(Split-PZModIds $commonValues['loadafter']) | Select-Object -Unique)
            LoadBefore = @(@(Split-PZModIds $values['loadmodbefore']) + @(Split-PZModIds $commonValues['loadbefore']) | Select-Object -Unique)
            Incompatible = @(@(Split-PZModIds $values['incompatible']) + @(Split-PZModIds $commonValues['incompatiblemods']) | Select-Object -Unique)
            MinBuild = $minBuild; MaxBuild = $maxBuild
        }
    }
}

function Test-PZClientModProviders {
    param(
        [Parameter(Mandatory)][object[]]$SelectedMetadata,
        [string[]]$WorkshopContentRoots = @(),
        [Parameter(Mandatory)][string]$ClientDataDirectory,
        [Parameter(Mandatory)][version]$BuildVersion
    )
    $selected = @{}
    $selectedWorkshopIds = @{}
    foreach ($metadata in $SelectedMetadata) {
        $selected[(ConvertTo-ModKey $metadata.Id)] = $metadata
        $selectedWorkshopIds[[string]$metadata.WorkshopId] = $true
    }
    $warnings = [Collections.Generic.List[string]]::new()
    $conflicts = [Collections.Generic.List[string]]::new()
    $candidates = [Collections.Generic.List[object]]::new()
    $roots = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $localMods = [IO.Path]::GetFullPath((Join-Path $ClientDataDirectory 'mods'))
    function Add-ProviderScanWarning {
        param([string]$Path, [string]$Reason)
        $message = "Duplicate-provider scan could not check '$Path': $Reason Coverage of this location is incomplete."
        $warnings.Add($message)
        Write-Warning $message
    }
    foreach ($root in $WorkshopContentRoots) {
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
        $root = [IO.Path]::GetFullPath($root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        if (-not $roots.Add($root)) { continue }
        try {
            foreach ($item in @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction Stop | Where-Object { $_.Name -match '^\d+$' })) {
                $candidates.Add([pscustomobject]@{ Kind='Workshop'; ItemDirectory=$item.FullName; WorkshopId=$item.Name })
            }
        } catch { Add-ProviderScanWarning $root $_.Exception.Message }
    }
    if (Test-Path -LiteralPath $localMods -PathType Container) {
        $candidates.Add([pscustomobject]@{ Kind='Local'; ItemDirectory=[IO.Path]::GetFullPath($ClientDataDirectory); WorkshopId='local' })
    }
    $seenFolders = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($candidate in $candidates) {
        $modsRoot = Join-Path $candidate.ItemDirectory 'mods'
        if (-not (Test-Path -LiteralPath $modsRoot -PathType Container)) { $modsRoot = Join-Path $candidate.ItemDirectory 'Contents/mods' }
        if (-not (Test-Path -LiteralPath $modsRoot -PathType Container)) { continue }
        try { $folders = @(Get-ChildItem -LiteralPath $modsRoot -Directory -ErrorAction Stop) }
        catch { Add-ProviderScanWarning $modsRoot $_.Exception.Message; continue }
        foreach ($folder in $folders) {
            if (-not $seenFolders.Add([IO.Path]::GetFullPath($folder.FullName))) { continue }
            try {
                $metadata = @(Get-B42ModMetadata -ItemDirectory $candidate.ItemDirectory -WorkshopId $candidate.WorkshopId -BuildVersion $BuildVersion -ModDirectory $folder.FullName)
            } catch { Add-ProviderScanWarning $folder.FullName $_.Exception.Message; continue }
            foreach ($provider in $metadata) {
                if (($null -ne $provider.MinBuild -and $BuildVersion -lt $provider.MinBuild) -or ($null -ne $provider.MaxBuild -and $BuildVersion -gt $provider.MaxBuild)) { continue }
                $key = ConvertTo-ModKey $provider.Id
                if (-not $selected.ContainsKey($key)) { continue }
                $expected = $selected[$key]
                if ([IO.Path]::GetFullPath($provider.Folder) -eq [IO.Path]::GetFullPath($expected.Folder)) { continue }
                $keep = "Keep selected Workshop item $($expected.WorkshopId) at '$($expected.Folder)'."
                if ($candidate.Kind -eq 'Local') {
                    $conflicts.Add("'$($provider.Id)' also exists as a local mod at '$($provider.Folder)'. Move that local folder outside '$localMods' and rerun. $keep")
                } elseif ($candidate.WorkshopId -eq [string]$expected.WorkshopId) {
                    $conflicts.Add("'$($provider.Id)' also exists in another installed copy of Workshop item $($candidate.WorkshopId) at '$($candidate.ItemDirectory)'. Remove or move that extra copy and rerun. $keep")
                } elseif ($selectedWorkshopIds.ContainsKey([string]$candidate.WorkshopId)) {
                    $conflicts.Add("'$($provider.Id)' also exists in selected Workshop item $($candidate.WorkshopId) at '$($provider.Folder)'. Ask the server owner to select a single provider before rerunning. $keep")
                } else {
                    $conflicts.Add("'$($provider.Id)' also exists in Workshop item $($candidate.WorkshopId) at '$($candidate.ItemDirectory)'. Unsubscribe from that conflicting item, remove any remaining installation folder there, and rerun. $keep")
                }
            }
        }
    }
    if ($conflicts.Count -gt 0) { throw ("Conflicting installed copies of selected client mods were found. The client preset was not changed.`n" + ($conflicts -join "`n")) }
    return [pscustomobject]@{
        WorkshopContentRoots=@($roots | Sort-Object); LocalModsDirectory=$localMods
        CoverageComplete=($warnings.Count -eq 0); Warnings=$warnings.ToArray()
        Scope='Applicable B42 providers in the selected Workshop content roots and the client local mods folder. Other Steam libraries and custom mod locations are not scanned.'
    }
}

function Get-PZLoadOrder {
    param([Parameter(Mandatory)][object[]]$Records)
    $byKey = @{}
    $aliasKeys = @{}
    $edges = @{}
    $degree = @{}
    foreach ($record in $Records) {
        $key = $record.Metadata.Key
        if ($byKey.ContainsKey($key)) { throw "Duplicate active mod ID '$key'. Select only one Workshop source." }
        $byKey[$key] = $record
        $edges[$key] = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $degree[$key] = 0
        foreach ($alias in @($record.Entry.ModId) + @($record.Entry.Aliases) + @($record.Metadata.Id)) {
            $aliasKeys[(ConvertTo-ModKey $alias)] = $key
        }
    }
    foreach ($record in $Records) {
        $key = $record.Metadata.Key
        $required = @($record.Entry.Requires) + @($record.Metadata.Requires)
        foreach ($id in $required) {
            $normalized = ConvertTo-ModKey $id
            if (-not $aliasKeys.ContainsKey($normalized)) { throw "'$key' requires missing mod '$id'." }
        }
        foreach ($id in $required + @($record.Entry.LoadAfter) + @($record.Metadata.LoadAfter)) {
            $normalized = ConvertTo-ModKey $id
            if ($aliasKeys.ContainsKey($normalized)) {
                $before = $aliasKeys[$normalized]
                if ($before -ne $key -and $edges[$before].Add($key)) { $degree[$key]++ }
            }
        }
        foreach ($id in @($record.Metadata.LoadBefore)) {
            $normalized = ConvertTo-ModKey $id
            if ($aliasKeys.ContainsKey($normalized)) {
                $after = $aliasKeys[$normalized]
                if ($after -ne $key -and $edges[$key].Add($after)) { $degree[$after]++ }
            }
        }
        foreach ($id in @($record.Metadata.Incompatible)) {
            $normalized = ConvertTo-ModKey $id
            if ($aliasKeys.ContainsKey($normalized) -and $aliasKeys[$normalized] -ne $key) {
                throw "'$key' declares incompatible=$id in its downloaded mod.info."
            }
        }
    }
    $result = [Collections.Generic.List[object]]::new()
    while ($result.Count -lt $Records.Count) {
        $ready = @($Records | Where-Object { $degree[$_.Metadata.Key] -eq 0 } |
            Sort-Object @{ Expression = { $_.Entry.Priority } }, @{ Expression = { $_.Index } })
        if ($ready.Count -eq 0) {
            $remaining = @($Records | Where-Object { $degree[$_.Metadata.Key] -ge 0 } | ForEach-Object { $_.Metadata.Key })
            throw "Load-order cycle involving: $($remaining -join ', '). Check require/loadModAfter/loadModBefore rules."
        }
        # Pick one ready entry at a time to preserve priority when a dependency becomes ready.
        $next = $ready[0]
        $result.Add($next)
        $degree[$next.Metadata.Key] = -1
        foreach ($after in $edges[$next.Metadata.Key]) { $degree[$after]-- }
    }
    return $result.ToArray()
}

function Set-PZServerModSettings {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ModsLine,
        [Parameter(Mandatory)][string]$WorkshopLine,
        [hashtable]$AdditionalSettings = @{}
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Server INI does not exist: $Path" }
    $text = [IO.File]::ReadAllText($Path)
    $newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $settings = @{ Mods = $ModsLine; WorkshopItems = $WorkshopLine }
    foreach ($key in $AdditionalSettings.Keys) {
        if ($key -notmatch '^[A-Za-z][A-Za-z0-9_]*$' -or $key -in @('Mods','WorkshopItems') -or [string]$AdditionalSettings[$key] -match '[\r\n]') {
            throw "Invalid additional server setting: $key"
        }
        $settings[$key] = "$key=$($AdditionalSettings[$key])"
    }
    $seen = @{}
    $lines = [Collections.Generic.List[string]]::new()
    foreach ($line in ($text -split '\r?\n')) {
        if ($line -match '^\s*([A-Za-z][A-Za-z0-9_]*)\s*=' -and $settings.ContainsKey($Matches[1])) {
            $key = $Matches[1]
            if (-not $seen.ContainsKey($key)) { $lines.Add($settings[$key]); $seen[$key] = $true }
        } else { $lines.Add($line) }
    }
    foreach ($key in @('Mods','WorkshopItems') + @($AdditionalSettings.Keys | Sort-Object)) {
        if (-not $seen.ContainsKey($key)) { $lines.Add($settings[$key]) }
    }
    $backup = "$Path.backup-$([DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fffffff'))"
    $temporary = "$Path.tmp-$([guid]::NewGuid().ToString('N'))"
    try {
        [IO.File]::WriteAllText($temporary, ($lines -join $newline), [Text.UTF8Encoding]::new($false))
        # The same-volume replacement also preserves the original as a backup.
        [IO.File]::Replace($temporary, [IO.Path]::GetFullPath($Path), [IO.Path]::GetFullPath($backup))
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary }
    }
    return $backup
}

function Get-PZSetupActions {
    param([object]$Catalog, [string[]]$ActiveIds, [ValidateSet('Client','Server')][string]$Mode)
    if (-not $Catalog.PSObject.Properties['SetupActions']) { return }
    $active = @{}
    foreach ($id in $ActiveIds) { $active[(ConvertTo-ModKey $id)] = $true }
    foreach ($action in $Catalog.SetupActions) {
        if ($action.Audience -notin @($Mode, 'Both')) { continue }
        if (@($action.ModIds).Count -eq 0 -or @($action.ModIds | Where-Object { $active.ContainsKey((ConvertTo-ModKey $_)) }).Count -gt 0) {
            $action
        }
    }
}

function Get-PZRequiredServerSettings {
    param([object]$Catalog, [string[]]$ActiveIds)
    $result = @{}
    if ($Catalog.PSObject.Properties['ServerSettings']) {
        $active = @{}
        foreach ($id in $ActiveIds) { $active[(ConvertTo-ModKey $id)] = $true }
        foreach ($rule in $Catalog.ServerSettings) {
            if (@($rule.ModIds).Count -eq 0 -or @($rule.ModIds | Where-Object { $active.ContainsKey((ConvertTo-ModKey $_)) }).Count -gt 0) {
                foreach ($property in $rule.Settings.PSObject.Properties) {
                    $value = [string]$property.Value
                    if ($result.ContainsKey($property.Name) -and $result[$property.Name] -ne $value) {
                        throw "Selected mods require conflicting values for server setting $($property.Name)."
                    }
                    $result[$property.Name] = $value
                }
            }
        }
    }
    return $result
}

function Export-PZClientSetup {
    param([string]$ProjectDirectory, [string]$CatalogPath, [string]$ServerProfile, [string]$OutputDirectory)
    $files = @('Start-PZModSetup.cmd','Start-PZModSetup.ps1','Download-PZMods.ps1','PZModTools.psm1','SteamWorkshopClient.cs')
    foreach ($file in $files) {
        if (-not (Test-Path -LiteralPath (Join-Path $ProjectDirectory $file) -PathType Leaf)) {
            throw "Cannot prepare the player setup: missing $file. Keep all project files together."
        }
    }
    Read-PZServerProfile $ServerProfile | Out-Null
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $package = Join-Path $OutputDirectory 'player-setup.zip'
    $temporary = Join-Path $OutputDirectory ('player-setup-' + [guid]::NewGuid().ToString('N'))
    $temporaryZip = "$temporary.zip"
    $backupZip = "$temporary.previous.zip"
    try {
        New-Item -ItemType Directory -Path $temporary | Out-Null
        foreach ($file in $files) { Copy-Item -LiteralPath (Join-Path $ProjectDirectory $file) -Destination (Join-Path $temporary $file) }
        Copy-Item -LiteralPath $CatalogPath -Destination (Join-Path $temporary 'mods.catalog.json')
        Copy-Item -LiteralPath $ServerProfile -Destination (Join-Path $temporary 'server-profile.json')
        $instructions = @('PROJECT ZOMBOID PLAYER SETUP', '', '1. Extract all files from this ZIP into a folder.', '2. Open Steam and install the same game build as the server. Close the game.', '3. Double-click Start-PZModSetup.cmd, choose Player, then Download/update.', '4. Enter the game build. Setup automatically uses the repository mod list in mods.catalog.json.', '5. After setup, launch the game. Check texture mods in the main menu and restart if requested.', '6. Join the server using the address/password supplied by the owner.', '', 'The menu retains your existing Steam subscriptions and backs up your default mod profile.', 'Use the same repository catalog revision as the server.', 'The included server-profile.json is a record of the server scan; setup does not import it.', 'Metadata checks do not prove runtime compatibility.')
        [IO.File]::WriteAllLines((Join-Path $temporary 'READ-ME.txt'), $instructions, [Text.UTF8Encoding]::new($false))
        Compress-Archive -Path (Join-Path $temporary '*') -DestinationPath $temporaryZip
        if (Test-Path -LiteralPath $package -PathType Leaf) { [IO.File]::Replace($temporaryZip, [IO.Path]::GetFullPath($package), [IO.Path]::GetFullPath($backupZip)) }
        else { [IO.File]::Move($temporaryZip, [IO.Path]::GetFullPath($package)) }
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
        if (Test-Path -LiteralPath $temporaryZip) { Remove-Item -LiteralPath $temporaryZip }
        if (Test-Path -LiteralPath $backupZip) { Remove-Item -LiteralPath $backupZip }
    }
    return $package
}

function Select-PZSetupMode {
    param([string]$Mode)
    if ($Mode) { return $Mode }
    while ($true) {
        $answer = Read-Host 'Are you setting up a server or a client? [S]erver / [C]lient'
        switch -Regex ($answer.Trim()) {
            '^(s|server|1)$' { return 'Server' }
            '^(c|client|2)$' { return 'Client' }
            default { Write-Host 'Enter S for server or C for client.' }
        }
    }
}

function Read-PZServerProfile {
    param([Parameter(Mandatory)][string]$Path)
    $profile = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($profile.SchemaVersion -ne 1 -or $profile.AppId -ne '108600' -or $profile.ValidatedFromDownloads -ne $true) {
        throw 'Use a validated server-profile.json generated by a successful server run, not a preview.'
    }
    if ((ConvertTo-BuildVersion $profile.BuildVersion).Major -ne 42) { throw 'The server profile must use Build 42.' }
    if (@($profile.Mods).Count -eq 0) { throw 'The server profile contains no mods.' }
    $seen = @{}
    foreach ($mod in $profile.Mods) {
        if ($mod.WorkshopId -notmatch '^\d+$' -or [string]::IsNullOrWhiteSpace($mod.ModId) -or $mod.ModId -match '[;\r\n,]') {
            throw 'The server profile contains an invalid mod or Workshop ID.'
        }
        $key = ConvertTo-ModKey $mod.ModId
        if ($seen.ContainsKey($key)) { throw "Duplicate server profile mod ID: $($mod.ModId)" }
        $seen[$key] = $true
    }
    return $profile
}

function Get-PZSteamGameDirectory {
    param([string]$GameDirectory)
    if ($GameDirectory) {
        if (-not (Test-Path -LiteralPath $GameDirectory -PathType Container)) { throw "Game directory not found: $GameDirectory" }
        return [IO.Path]::GetFullPath($GameDirectory)
    }
    $steamRoots = @()
    foreach ($registry in @('HKCU:\Software\Valve\Steam','HKLM:\SOFTWARE\WOW6432Node\Valve\Steam')) {
        $settings = Get-ItemProperty -LiteralPath $registry -ErrorAction SilentlyContinue
        if ($null -eq $settings) { continue }
        foreach ($property in @('SteamPath','InstallPath')) {
            if ($settings.PSObject.Properties[$property]) { $steamRoots += $settings.$property }
        }
    }
    $libraries = @($steamRoots)
    foreach ($steamRoot in $steamRoots) {
        $vdf = Join-Path $steamRoot 'steamapps/libraryfolders.vdf'
        if (-not (Test-Path -LiteralPath $vdf -PathType Leaf)) { continue }
        foreach ($match in [regex]::Matches([IO.File]::ReadAllText($vdf), '"path"\s*"([^"]+)"')) {
            $libraries += $match.Groups[1].Value.Replace('\\','\')
        }
    }
    foreach ($library in @($libraries | Select-Object -Unique)) {
        $manifest = Join-Path $library 'steamapps/appmanifest_108600.acf'
        if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { continue }
        if ([IO.File]::ReadAllText($manifest) -match '"installdir"\s*"([^"]+)"') {
            $directory = Join-Path (Join-Path $library 'steamapps/common') $Matches[1]
            if (Test-Path -LiteralPath $directory -PathType Container) { return [IO.Path]::GetFullPath($directory) }
        }
    }
    throw 'Project Zomboid was not found in Steam libraries. Install it first or pass -GameDirectory "D:\SteamLibrary\steamapps\common\ProjectZomboid".'
}

function Invoke-PZClientWorkshopDownloads {
    param(
        [Parameter(Mandatory)][string[]]$Ids,
        [string]$GameDirectory,
        [int]$Retries = 3,
        [int]$TimeoutSeconds = 1200,
        # Injection is used by offline tests; normal callers always use the installed game's Steam API.
        [scriptblock]$SessionFactory
    )
    $session = $null
    $oldAppId = $env:SteamAppId
    $oldGameId = $env:SteamGameId
    try {
        if (-not $SessionFactory) {
            if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT -or -not [Environment]::Is64BitProcess) {
                throw 'Client downloads require Windows and 64-bit PowerShell. Use -PlanOnly or -SkipDownload for offline checks.'
            }
            if (Get-Process -Name ProjectZomboid64,ProjectZomboid32 -ErrorAction SilentlyContinue) { throw 'Close Project Zomboid before setting up client mods.' }
            $GameDirectory = Get-PZSteamGameDirectory $GameDirectory
            $dlls = @(Get-ChildItem -LiteralPath $GameDirectory -Filter steam_api64.dll -File -Recurse | Sort-Object @{ Expression = { $_.FullName.Length } })
            if ($dlls.Count -eq 0) { throw "steam_api64.dll not found under $GameDirectory. Verify the game installation in Steam." }
            if (-not ('PZModTools.SteamWorkshopClient' -as [type])) {
                Add-Type -Path (Join-Path $PSScriptRoot 'SteamWorkshopClient.cs')
            }
            $env:SteamAppId = '108600'
            $env:SteamGameId = '108600'
            $session = [PZModTools.SteamWorkshopClient]::new($dlls[0].FullName)
        } else { $session = & $SessionFactory }
        $directories = @{}
        Write-Host "Subscribing to $($Ids.Count) Workshop items in the signed-in Steam client's account..."
        $position = 0
        foreach ($id in $Ids) {
            $position++
            $numericId = [uint64]$id
            $clock = [Diagnostics.Stopwatch]::StartNew()
            $subscribed = $false
            for ($subscriptionAttempt = 1; $subscriptionAttempt -le $Retries; $subscriptionAttempt++) {
                # Complete this subscription before submitting the next item's request.
                $session.SubscribeItem($numericId)
                $clock.Restart()
                while ($true) {
                    $session.Pump()
                    $subscriptionResult = $session.GetSubscriptionResult($numericId)
                    if ($subscriptionResult -gt 1) { break }
                    if (-not $session.SubscriptionPending($numericId) -and ($session.GetItemState($numericId) -band 1) -ne 0) {
                        $subscribed = $true
                        break
                    }
                    if ($clock.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
                        throw "Steam subscription timed out for Workshop $id. Keep Steam online and signed in, then rerun setup. No client profile was installed."
                    }
                    Write-Progress -Activity 'Installing client Workshop mods through Steam' -Status "Subscribing $position/$($Ids.Count): $id" -PercentComplete (100 * ($position - 1) / $Ids.Count)
                    Start-Sleep -Milliseconds 200
                }
                if ($subscribed) { break }
                $reason = if ($subscriptionResult -eq 3) { 'Steam has no network connection.' } else { "Steam returned EResult=$subscriptionResult." }
                # Fail, NoConnection, Busy, Timeout, ServiceUnavailable, RateLimitExceeded.
                if ($subscriptionResult -notin @(2,3,10,16,20,84) -or $subscriptionAttempt -eq $Retries) {
                    throw "Steam subscription failed for Workshop $id. $reason Check Steam and the Workshop item, then rerun setup. No client profile was installed."
                }
                Write-Warning "Workshop $id subscription failed (Steam EResult=$subscriptionResult), attempt $subscriptionAttempt/$Retries. $reason Retrying..."
                Start-Sleep -Seconds ([Math]::Min(2 * $subscriptionAttempt, 10))
            }
            $installed = $false
            for ($attempt = 1; $attempt -le $Retries; $attempt++) {
                $session.Pump()
                $state = $session.GetItemState($numericId)
                $requestedDownload = $false
                # Installed=4; NeedsUpdate=8, Downloading=16, DownloadPending=32.
                if ($attempt -gt 1 -or ($state -band 4) -eq 0 -or ($state -band 56) -ne 0) {
                    if (-not $session.DownloadItem($numericId)) { throw "Steam rejected download for Workshop $id." }
                    $requestedDownload = $true
                }
                $clock.Restart()
                while ($true) {
                    $session.Pump()
                    $result = $session.GetDownloadResult($numericId)
                    if ($requestedDownload -and $result -gt 1) {
                        Write-Warning "Workshop $id download failed (Steam EResult=$result), attempt $attempt/$Retries."
                        break
                    }
                    $state = $session.GetItemState($numericId)
                    if (($state -band 5) -eq 5 -and ($state -band 56) -eq 0 -and (-not $requestedDownload -or $result -eq 1)) {
                        $directory = $session.GetInstallFolder($numericId)
                        if ($directory -and (Test-Path -LiteralPath $directory -PathType Container)) {
                            $infoFiles = @(Get-ChildItem -LiteralPath $directory -Filter mod.info -File -Recurse)
                            if ($infoFiles.Count -gt 0) {
                                $directories[[string]$id] = $directory
                                $installed = $true
                                break
                            }
                        }
                    }
                    Write-Progress -Activity 'Installing client Workshop mods through Steam' -Status "$position/$($Ids.Count): $id" -PercentComplete (100 * ($position - 1) / $Ids.Count)
                    if ($clock.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
                        Write-Warning "Workshop $id download timed out, attempt $attempt/$Retries."
                        break
                    }
                    Start-Sleep -Milliseconds 200
                }
                if ($installed) { Write-Host "Client Workshop $position/$($Ids.Count) ready: $id"; break }
            }
            if (-not $installed) { throw "Client Workshop download failed for $id. No client profile was installed." }
        }
        return $directories
    } finally {
        Write-Progress -Activity 'Installing client Workshop mods through Steam' -Completed
        try { if ($null -ne $session) { $session.Dispose() } } finally {
            $env:SteamAppId = $oldAppId
            $env:SteamGameId = $oldGameId
        }
    }
}

function Set-PZClientProfile {
    param([Parameter(Mandatory)][string]$Source, [Parameter(Mandatory)][string]$ClientDataDirectory)
    $modsDirectory = Join-Path $ClientDataDirectory 'mods'
    New-Item -ItemType Directory -Path $modsDirectory -Force | Out-Null
    $destination = [IO.Path]::GetFullPath((Join-Path $modsDirectory 'default.txt'))
    if ([IO.Path]::GetFullPath($Source) -eq $destination) { throw 'Client profile source and destination must be different files.' }
    $temporary = "$destination.tmp-$([guid]::NewGuid().ToString('N'))"
    $backup = $null
    try {
        [IO.File]::WriteAllText($temporary, [IO.File]::ReadAllText($Source), [Text.UTF8Encoding]::new($false))
        if (Test-Path -LiteralPath $destination -PathType Leaf) {
            $backup = "$destination.backup-$([DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fffffff'))"
            [IO.File]::Replace($temporary, $destination, $backup)
        } else { [IO.File]::Move($temporary, $destination) }
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary }
    }
    return [pscustomobject]@{ Path = $destination; Backup = $backup }
}

Export-ModuleMember -Function ConvertTo-ModKey, ConvertTo-BuildVersion, Read-PZModInfo, Split-PZModIds, Get-B42ModMetadata, Test-PZClientModProviders, Get-PZLoadOrder, Set-PZServerModSettings, Get-PZSetupActions, Get-PZRequiredServerSettings, Export-PZClientSetup, Select-PZSetupMode, Read-PZServerProfile, Get-PZSteamGameDirectory, Invoke-PZClientWorkshopDownloads, Set-PZClientProfile
