<#
.SYNOPSIS
    Restore Microsoft Teams from JSON backup.

.DESCRIPTION
    Recreates team from backup file including channels, settings, and optionally members.

.PARAMETER BackupFile
    Path to JSON backup file

.PARAMETER NewTeamName
    Name for restored team (uses backup name if not specified)

.PARAMETER RestoreMembers
    Restore team members from backup

.EXAMPLE
    .\Restore-Team.ps1 -BackupFile ".\Backups\Team_Sales_20240101.json"

.EXAMPLE
    .\Restore-Team.ps1 -BackupFile ".\backup.json" -NewTeamName "Sales Team (Restored)" -RestoreMembers
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFile,
    [string]$NewTeamName,
    [switch]$RestoreMembers
)

Import-Module MicrosoftTeams

try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== Team Restoration ===" -ForegroundColor Cyan

if (!(Test-Path $BackupFile)) {
    Write-Error "Backup file not found: $BackupFile"
    exit 1
}

try {
    # Load backup
    $backup = Get-Content $BackupFile | ConvertFrom-Json
    Write-Host "Loading backup from: $BackupFile" -ForegroundColor Yellow
    Write-Host "Original team: $($backup.TeamInfo.DisplayName)" -ForegroundColor White
    Write-Host "Backup date: $($backup.BackupDate)`n" -ForegroundColor Gray

    # Determine team name
    $teamName = if ($NewTeamName) { $NewTeamName } else { $backup.TeamInfo.DisplayName }

    # Create team
    Write-Host "Creating team: $teamName" -ForegroundColor Yellow
    $team = New-Team -DisplayName $teamName `
                     -Description $backup.TeamInfo.Description `
                     -Visibility $backup.TeamInfo.Visibility

    Write-Host "  ✓ Team created (ID: $($team.GroupId))" -ForegroundColor Green

    # Restore settings
    Write-Host "`nRestoring settings..." -ForegroundColor Yellow
    $settings = $backup.TeamInfo.Settings
    Set-Team -GroupId $team.GroupId `
             -AllowGiphy $settings.AllowGiphy `
             -GiphyContentRating $settings.GiphyContentRating `
             -AllowStickersAndMemes $settings.AllowStickersAndMemes `
             -AllowCustomMemes $settings.AllowCustomMemes
    Write-Host "  ✓ Settings restored" -ForegroundColor Green

    # Restore channels
    Write-Host "`nRestoring channels..." -ForegroundColor Yellow
    foreach ($channel in $backup.Channels) {
        if ($channel.DisplayName -ne "General") {
            try {
                New-TeamChannel -GroupId $team.GroupId `
                               -DisplayName $channel.DisplayName `
                               -Description $channel.Description `
                               -MembershipType $channel.MembershipType
                Write-Host "  ✓ Created channel: $($channel.DisplayName)" -ForegroundColor Green
            } catch {
                Write-Host "  ⚠ Failed to create channel $($channel.DisplayName): $_" -ForegroundColor Yellow
            }
        }
    }

    # Restore members if requested
    if ($RestoreMembers -and $backup.Members) {
        Write-Host "`nRestoring members..." -ForegroundColor Yellow
        foreach ($member in $backup.Members) {
            try {
                Add-TeamUser -GroupId $team.GroupId `
                           -User $member.User `
                           -Role $member.Role
                Write-Host "  ✓ Added $($member.Role): $($member.User)" -ForegroundColor Green
            } catch {
                Write-Host "  ⚠ Failed to add $($member.User): $_" -ForegroundColor Yellow
            }
        }
    }

    Write-Host "`n✓ Team restoration complete!" -ForegroundColor Green
    Write-Host "`nRestored Team Details:" -ForegroundColor Cyan
    Write-Host "  Name: $teamName" -ForegroundColor White
    Write-Host "  ID: $($team.GroupId)" -ForegroundColor White
    Write-Host "  Channels: $(($backup.Channels).Count)" -ForegroundColor White
    if ($RestoreMembers) {
        Write-Host "  Members: $(($backup.Members).Count)" -ForegroundColor White
    }
    Write-Host ""

    return $team

} catch {
    Write-Error "Restoration failed: $_"
    exit 1
}
