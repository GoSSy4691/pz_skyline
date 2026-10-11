#Requires -Version 5.1
<#
.SYNOPSIS
An interactive setup menu for Project Zomboid server owners and players.
.DESCRIPTION
On Windows, double-click Start-PZModSetup.cmd. Advanced commands remain in Download-PZMods.ps1.
.PARAMETER NoStart
Load the menu functions without opening the menu, for offline verification.
#>
[CmdletBinding()]
param([switch]$NoStart)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:PZSetupRoot = $PSScriptRoot
$script:PZSetupQuietScreen = $NoStart.IsPresent
$script:PZSetupInputReader = { param($Prompt) Read-Host $Prompt }
Import-Module (Join-Path $PSScriptRoot 'PZModTools.psm1') -Force -DisableNameChecking

function Show-PZSetupScreen {
    param([string]$Title, [string]$Description, [switch]$KeepOutput)
    if (-not $KeepOutput -and -not $script:PZSetupQuietScreen) { Clear-Host }
    Write-Host ''
    Write-Host '  +------------------------------------------------------------+' -ForegroundColor DarkCyan
    Write-Host ('  |{0,-60}|' -f '  PROJECT ZOMBOID') -ForegroundColor Cyan
    Write-Host ('  |{0,-60}|' -f '  MOD SETUP  /  BUILD 42') -ForegroundColor White
    Write-Host '  +------------------------------------------------------------+' -ForegroundColor DarkCyan
    Write-Host ''
    Write-Host "  $Title" -ForegroundColor White
    if ($Description) { Write-Host "  $Description" -ForegroundColor Gray }
    Write-Host ''
}

function Read-PZSetupAnswer {
    param([string]$Prompt)
    $value = & $script:PZSetupInputReader $Prompt
    if ($null -eq $value) { throw [IO.EndOfStreamException]::new('Input was closed.') }
    return ([string]$value).Trim()
}

function Read-PZSetupChoice {
    param([Parameter(Mandatory)][string[]]$Items, [int]$Default = 1, [string]$BackLabel = 'Back')
    for ($index = 0; $index -lt $Items.Count; $index++) {
        $marker = if ($index + 1 -eq $Default) { '>' } else { ' ' }
        $color = if ($index + 1 -eq $Default) { 'Cyan' } else { 'White' }
        Write-Host ("  {0} [{1}] {2}" -f $marker, ($index + 1), $Items[$index]) -ForegroundColor $color
    }
    Write-Host "    [0] $BackLabel" -ForegroundColor DarkGray
    Write-Host ''
    while ($true) {
        $answer = Read-PZSetupAnswer "  Choose an option (Enter = $Default)"
        if (-not $answer) { return $Default }
        if ($answer -match '^(q|exit|back)$') { return 0 }
        if ($answer -match '^\d+$' -and $answer.Length -lt 3) {
            $number = [int]$answer
            if ($number -ge 0 -and $number -le $Items.Count) { return $number }
        }
        Write-Host "  Choose a number from 0 to $($Items.Count)." -ForegroundColor Yellow
    }
}

function Stop-PZSetupStep { throw [OperationCanceledException]::new('Back to menu.') }

function Read-PZSetupBuild {
    Write-Host '  Use the exact game version shown on your server/game main menu.' -ForegroundColor Gray
    while ($true) {
        $value = Read-PZSetupAnswer '  Game build [42.21.0] (Q = back)'
        if ($value -match '^(q|back)$') { Stop-PZSetupStep }
        if (-not $value) { $value = '42.21.0' }
        try {
            if ((ConvertTo-BuildVersion $value).Major -eq 42) { return $value }
        } catch { }
        Write-Host '  Enter a Build 42 version, for example 42.21.0.' -ForegroundColor Yellow
    }
}

function Select-PZSetupPath {
    param(
        [Parameter(Mandatory)][string]$Label,
        [ValidateSet('File','Directory')][string]$Kind = 'Directory',
        [string]$DefaultPath,
        [string]$Filter = 'All files (*.*)|*.*',
        [switch]$AllowNewDirectory
    )
    while ($true) {
        Write-Host ''
        Write-Host "  $Label" -ForegroundColor White
        $items = @("Browse for a $($Kind.ToLowerInvariant())", 'Type or paste a path')
        if ($DefaultPath) {
            Write-Host "  Suggested: $DefaultPath" -ForegroundColor Gray
            $items = @('Use the suggested location') + $items
        }
        $choice = Read-PZSetupChoice -Items $items
        if ($choice -eq 0) { Stop-PZSetupStep }
        $path = $null
        if ($DefaultPath -and $choice -eq 1) { $path = $DefaultPath }
        else {
            $browseChoice = if ($DefaultPath) { 2 } else { 1 }
            if ($choice -eq $browseChoice -and [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
                $dialog = $null
                try {
                    Add-Type -AssemblyName System.Windows.Forms
                    if ($Kind -eq 'File') {
                        $dialog = New-Object System.Windows.Forms.OpenFileDialog
                        $dialog.Title = $Label
                        $dialog.Filter = $Filter
                        $dialog.CheckFileExists = $true
                    } else {
                        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
                        $dialog.Description = $Label
                        $dialog.ShowNewFolderButton = $AllowNewDirectory.IsPresent
                        if ($DefaultPath -and (Test-Path -LiteralPath $DefaultPath -PathType Container)) { $dialog.SelectedPath = $DefaultPath }
                    }
                    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                        $path = if ($Kind -eq 'File') { $dialog.FileName } else { $dialog.SelectedPath }
                    } else { continue }
                } catch {
                    Write-Host '  File picker unavailable. Paste a path below instead.' -ForegroundColor Yellow
                    $path = Read-PZSetupAnswer '  Path (Q = back)'
                } finally { if ($null -ne $dialog) { $dialog.Dispose() } }
            } else { $path = Read-PZSetupAnswer '  Path (Q = back)' }
        }
        if ($path -match '^(q|back)$') { Stop-PZSetupStep }
        $path = $path.Trim().Trim('"')
        if (-not $path) { continue }
        try {
            $path = [Environment]::ExpandEnvironmentVariables($path)
            if (-not [IO.Path]::IsPathRooted($path)) { $path = Join-Path $script:PZSetupRoot $path }
            $path = [IO.Path]::GetFullPath($path)
            $pathType = if ($Kind -eq 'File') { 'Leaf' } else { 'Container' }
            if (Test-Path -LiteralPath $path -PathType $pathType) { return $path }
            if ($Kind -eq 'Directory' -and $AllowNewDirectory -and -not (Test-Path -LiteralPath $path)) { return $path }
        } catch { }
        Write-Host "  That $($Kind.ToLowerInvariant()) was not found. Choose another location." -ForegroundColor Yellow
    }
}

function Select-PZSetupServerIni {
    $directory = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Zomboid/Server'
    $files = @(if (Test-Path -LiteralPath $directory -PathType Container) { Get-ChildItem -LiteralPath $directory -Filter '*.ini' -File | Sort-Object Name })
    Write-Host ''
    Write-Host '  Which server settings should be updated?' -ForegroundColor White
    $items = @($files | ForEach-Object { "Update $($_.BaseName)  ($($_.FullName))" })
    $items += @('Choose another server settings file', 'Generate settings only; apply them myself')
    $default = if ($files.Count -gt 0) { 1 } else { $items.Count }
    $choice = Read-PZSetupChoice -Items $items -Default $default
    if ($choice -eq 0) { Stop-PZSetupStep }
    if ($choice -le $files.Count) { return $files[$choice - 1].FullName }
    if ($choice -eq $files.Count + 1) { return (Select-PZSetupPath -Label 'Select the server settings INI' -Kind File -Filter 'Server settings (*.ini)|*.ini') }
    return $null
}

function Get-PZSetupParameters {
    param([ValidateSet('Client','Server')][string]$Mode, [ValidateSet('Download','Existing','Preview')][string]$Action)
    $parameters = @{ Mode = $Mode; CatalogPath = (Join-Path $script:PZSetupRoot 'mods.catalog.json') }
    $parameters.OutputDirectory = Join-Path $script:PZSetupRoot 'output'
    if ($Mode -eq 'Client') { $parameters.OutputDirectory = Join-Path $parameters.OutputDirectory 'client' }
    if ($Action -eq 'Preview') {
        $parameters.PlanOnly = $true
        $parameters.OutputDirectory = Join-Path (Join-Path $script:PZSetupRoot 'output/preview') $Mode.ToLowerInvariant()
    }
    Show-PZSetupScreen -Title "$Mode setup / choose mods" -Description 'Use 0 in menus or Q in text prompts to go back.'
    if ($Mode -eq 'Client') {
        Write-Host '  Using the mod list from this repository: mods.catalog.json.' -ForegroundColor Cyan
        $parameters.BuildVersion = Read-PZSetupBuild
        $parameters.ClientDataDirectory = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Zomboid'
        if ($Action -eq 'Download') {
            Write-Host ''
            Write-Host '  Keep Steam open and signed in. Close Project Zomboid.' -ForegroundColor Gray
            try { $parameters.GameDirectory = Get-PZSteamGameDirectory } catch {
                $parameters.GameDirectory = Select-PZSetupPath -Label 'Select the Project Zomboid game folder'
            }
            Write-Host "  Game found: $($parameters.GameDirectory)" -ForegroundColor Gray
        }
    } else {
        $parameters.BuildVersion = Read-PZSetupBuild
        if ($Action -eq 'Download') {
            $parameters.SteamCmdDirectory = Select-PZSetupPath -Label 'Server installation folder, or a folder for mod downloads' -DefaultPath (Join-Path $script:PZSetupRoot 'steamcmd') -AllowNewDirectory
            Write-Host ''
            Write-Host '  How should the downloader sign in to Steam?' -ForegroundColor White
            $login = Read-PZSetupChoice -Items @('Use my Steam account', 'Try anonymous access')
            if ($login -eq 0) { Stop-PZSetupStep }
            if ($login -eq 1) {
                Write-Host '  Steam asks for your password and Steam Guard code during download.' -ForegroundColor Gray
                while ($true) {
                    $name = Read-PZSetupAnswer '  Steam account login name (Q = back)'
                    if ($name -match '^(q|back)$') { Stop-PZSetupStep }
                    if ($name -match '^[A-Za-z0-9_@.-]+$') { $parameters.SteamUser = $name; break }
                    Write-Host '  Enter your Steam login name, not your password.' -ForegroundColor Yellow
                }
            } else { $parameters.SteamUser = 'anonymous' }
        }
        if ($Action -ne 'Preview') {
            $ini = Select-PZSetupServerIni
            if ($ini) { $parameters.ServerIni = $ini }
        }
    }
    if ($Action -eq 'Existing') {
        $parameters.SkipDownload = $true
        $suggested = $null
        if ($Mode -eq 'Server') { $suggested = Join-Path $script:PZSetupRoot 'steamcmd/steamapps/workshop/content/108600' }
        else {
            try {
                $game = Get-PZSteamGameDirectory
                $steamapps = Split-Path -Parent (Split-Path -Parent $game)
                $suggested = Join-Path $steamapps 'workshop/content/108600'
            } catch { }
        }
        if ($suggested -and -not (Test-Path -LiteralPath $suggested -PathType Container)) { $suggested = $null }
        $parameters.WorkshopContentPath = Select-PZSetupPath -Label 'Select the Workshop mods folder named 108600' -DefaultPath $suggested
    }
    return $parameters
}

function Show-PZSetupSummary {
    param([hashtable]$Parameters, [string]$Action)
    Show-PZSetupScreen -Title 'Ready to start' -Description 'Review your setup below.'
    $build = $Parameters.BuildVersion
    Write-Host "  Setup:       $($Parameters.Mode)" -ForegroundColor White
    Write-Host "  Target build: $build" -ForegroundColor White
    $actionLabel = switch ($Action) { Download { 'Download/update mods and set up' }; Existing { 'Check existing mods and set up' }; Preview { 'Preview only; no downloads or profile installation' } }
    Write-Host "  Action:      $actionLabel" -ForegroundColor White
    Write-Host '  Mod list:    Repository multiplayer selection (mods.catalog.json)' -ForegroundColor Gray
    if (Test-Path -LiteralPath $Parameters.CatalogPath -PathType Leaf) {
        $catalog = Get-Content -LiteralPath $Parameters.CatalogPath -Raw | ConvertFrom-Json
        $enabled = @($catalog.Mods | Where-Object { $_.MultiplayerEnabled })
        $disabled = @($catalog.Mods | Where-Object { -not $_.MultiplayerEnabled })
        Write-Host "  Mods:        $($catalog.Mods.Count) requested; $($enabled.Count) selected, plus required libraries" -ForegroundColor Gray
        Write-Host "  Held back:   $($disabled.Count) requested mods; reasons are available in menu 3 and the report" -ForegroundColor Yellow
    }
    $labels = [ordered]@{ GameDirectory = 'Game folder'; SteamCmdDirectory = 'Download folder'; WorkshopContentPath = 'Existing mods'; ServerIni = 'Server settings'; ClientDataDirectory = 'Game profile folder' }
    foreach ($key in $labels.Keys) {
        if ($Parameters.ContainsKey($key)) { Write-Host "  $($labels[$key]): $($Parameters[$key])" -ForegroundColor Gray }
    }
    Write-Host "  Results:     $($Parameters.OutputDirectory)" -ForegroundColor Gray
    Write-Host ''
    if ($Parameters.Mode -eq 'Client' -and $Action -ne 'Preview') {
        Write-Host '  Your current mod profile will be backed up.' -ForegroundColor Green
        Write-Host '  Only the selected mods will be enabled in the new default profile.' -ForegroundColor Gray
        Write-Host '  Your other subscriptions and downloaded mods are kept.' -ForegroundColor Gray
    }
    if ($Parameters.ContainsKey('ServerIni')) {
        Write-Host '  Stop the server before continuing. Its settings will be backed up.' -ForegroundColor Yellow
    }
    Write-Host ''
    return (Read-PZSetupChoice -Items @('Start setup') -BackLabel 'Back to main menu') -eq 1
}

function Invoke-PZSetupRun {
    param([hashtable]$Parameters)
    & (Join-Path $script:PZSetupRoot 'Download-PZMods.ps1') @Parameters
    $statusPath = Join-Path $Parameters.OutputDirectory 'run-status.json'
    $status = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
    $expected = if ($Parameters.ContainsKey('PlanOnly') -and $Parameters.PlanOnly) { 'preview' } else { 'validated' }
    if ($status.Status -ne $expected -or ($expected -eq 'validated' -and $Parameters.Mode -eq 'Client' -and -not $status.ClientProfileInstalled)) {
        throw 'Setup did not report successful completion. Check the results folder for details.'
    }
}

function Show-PZSetupResult {
    param([hashtable]$Parameters, [string]$Action)
    Show-PZSetupScreen -Title 'Setup complete' -Description 'Your results are ready.' -KeepOutput
    if ($Action -eq 'Preview') { Write-Host '  Preview created. Downloads and live settings were not changed.' -ForegroundColor Green }
    elseif ($Parameters.Mode -eq 'Client') {
        Write-Host '  Your repository mod profile is installed.' -ForegroundColor Green
        Write-Host '  Check texture mods in the game menu, restart if needed, then join.' -ForegroundColor Gray
    } else {
        Write-Host '  Server mod metadata checked and settings generated.' -ForegroundColor Green
        if ($Parameters.ContainsKey('ServerIni')) { Write-Host '  Server settings updated. You can restart your server.' -ForegroundColor Gray }
        else { Write-Host '  Apply server-mods.ini to your server settings before restarting.' -ForegroundColor Gray }
        Write-Host "  Share this ZIP with players: $($Parameters.OutputDirectory)\player-setup.zip" -ForegroundColor Cyan
    }
    if ($Action -ne 'Preview') {
        $report = Get-Content -LiteralPath (Join-Path $Parameters.OutputDirectory 'validation.json') -Raw | ConvertFrom-Json
        if ($report.PSObject.Properties['SetupActions']) {
            foreach ($actionItem in $report.SetupActions) { Write-Host "  Next step: $($actionItem.Text)" -ForegroundColor Yellow }
        }
        Write-Host '  Metadata checks do not replace a server startup and gameplay test.' -ForegroundColor Gray
    }
    Write-Host "  Results: $($Parameters.OutputDirectory)" -ForegroundColor Gray
    Write-Host ''
    $canPlay = $Parameters.Mode -eq 'Client' -and $Action -ne 'Preview'
    while ($true) {
        $items = @('Open results folder', 'Return to the main menu')
        if ($canPlay) { $items = @('Start Project Zomboid') + $items }
        $choice = Read-PZSetupChoice -Items $items -BackLabel 'Exit' -Default $items.Count
        if ($choice -eq 0) { return $false }
        if ($choice -eq $items.Count) { return $true }
        if ($canPlay -and $choice -eq 1) { Start-Process 'steam://rungameid/108600' | Out-Null }
        else { Invoke-Item -LiteralPath $Parameters.OutputDirectory }
    }
}

function Show-PZSetupModList {
    Show-PZSetupScreen -Title 'Included mod list' -Description 'This is the mod selection from this repository.'
    $catalog = Get-Content -LiteralPath (Join-Path $script:PZSetupRoot 'mods.catalog.json') -Raw | ConvertFrom-Json
    $enabled = @($catalog.Mods | Where-Object { $_.MultiplayerEnabled })
    Write-Host "  $($enabled.Count) selected mods / $(@($enabled.WorkshopId | Select-Object -Unique).Count) selected Workshop items, plus required libraries" -ForegroundColor Cyan
    Write-Host "  $($catalog.Mods.Count) requested mods / $(@($catalog.Mods.WorkshopId | Select-Object -Unique).Count) mapped Workshop items in total" -ForegroundColor Gray
    Write-Host ''
    foreach ($mod in $catalog.Mods) {
        $marker = if ($mod.MultiplayerEnabled) { '+' } else { '-' }
        $color = if ($mod.MultiplayerEnabled) { 'Gray' } else { 'DarkGray' }
        Write-Host "  [$marker] $($mod.ModId)" -ForegroundColor $color
        if (-not $mod.MultiplayerEnabled) { Write-Host "      $($mod.DisabledReason)" -ForegroundColor DarkYellow }
    }
    Write-Host ''
    Read-PZSetupAnswer '  Press Enter to return' | Out-Null
}

function Show-PZSetupHelp {
    Show-PZSetupScreen -Title 'Quick help' -Description 'Everything starts from this menu.'
    Write-Host '  PLAYERS' -ForegroundColor Cyan
    Write-Host '  Open Steam, sign in, install the same game build as the server,' -ForegroundColor Gray
    Write-Host '  and close the game. Choose Player, then Download/update.' -ForegroundColor Gray
    Write-Host '  Setup uses mods.catalog.json from this repository.' -ForegroundColor Gray
    Write-Host '  Use the same repository mod selection as the server.' -ForegroundColor Gray
    Write-Host '  Other subscriptions stay installed; the new profile enables' -ForegroundColor Gray
    Write-Host '  only the selected mods. The old profile is backed up.' -ForegroundColor Gray
    Write-Host '  Remove obsolete copies if setup reports duplicate mod IDs.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  SERVER OWNERS' -ForegroundColor Cyan
    Write-Host '  Stop your server. Choose Server owner and enter its game build.' -ForegroundColor Gray
    Write-Host '  Choose the server folder and the settings file to update,' -ForegroundColor Gray
    Write-Host '  or generate settings to apply yourself. Share the resulting' -ForegroundColor Gray
    Write-Host '  player-setup.zip with your players; it contains their launcher.' -ForegroundColor Gray
    Write-Host '  The game/server installation and game-version selection are' -ForegroundColor Gray
    Write-Host '  done in Steam. This tool installs mods and updates settings.' -ForegroundColor Gray
    Write-Host '  Test a fresh world with two players before using your main world.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  Preview makes no downloads or live settings changes.' -ForegroundColor Gray
    Write-Host '  Use existing downloads checks the files already on your PC.' -ForegroundColor Gray
    Write-Host '  Results and download logs are kept in the output folder.' -ForegroundColor Gray
    Write-Host ''
    Read-PZSetupAnswer '  Press Enter to return' | Out-Null
}

function Start-PZSetupMenu {
    $oldTitle = $null
    try {
        try { $oldTitle = $Host.UI.RawUI.WindowTitle; $Host.UI.RawUI.WindowTitle = 'Project Zomboid - Mod Setup' } catch { }
        while ($true) {
            try {
                Show-PZSetupScreen -Title 'Welcome' -Description 'Choose what you need. Press Enter to use the highlighted option.'
                $role = Read-PZSetupChoice -Items @('Player / set up my game for the server', 'Server owner / set up or update server mods', 'View the included mod list', 'Help') -BackLabel 'Exit'
                if ($role -eq 0) { return }
                if ($role -eq 3) { Show-PZSetupModList; continue }
                if ($role -eq 4) { Show-PZSetupHelp; continue }
                $mode = if ($role -eq 1) { 'Client' } else { 'Server' }
                Show-PZSetupScreen -Title "$mode setup" -Description 'Choose how to prepare the mods.'
                $task = Read-PZSetupChoice -Items @('Download or update mods and set up', 'Use mods already downloaded on this PC', 'Preview the setup without downloading')
                if ($task -eq 0) { continue }
                $action = @('Download','Existing','Preview')[$task - 1]
                $parameters = Get-PZSetupParameters -Mode $mode -Action $action
                if (-not (Show-PZSetupSummary -Parameters $parameters -Action $action)) { continue }
                Show-PZSetupScreen -Title 'Setup in progress' -Description 'Progress and download messages appear below. Keep this window open.'
                Invoke-PZSetupRun -Parameters $parameters
                if (-not (Show-PZSetupResult -Parameters $parameters -Action $action)) { return }
            } catch [OperationCanceledException] { continue }
            catch [IO.EndOfStreamException] { return }
            catch {
                Write-Host ''
                Write-Host '  SETUP NEEDS ATTENTION' -ForegroundColor Red
                Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow
                Write-Host '  Fix the issue, then choose setup again from the menu.' -ForegroundColor Gray
                Read-PZSetupAnswer '  Press Enter to return to the main menu' | Out-Null
            }
        }
    } finally { if ($null -ne $oldTitle) { try { $Host.UI.RawUI.WindowTitle = $oldTitle } catch { } } }
}

if (-not $NoStart) { Start-PZSetupMenu }
