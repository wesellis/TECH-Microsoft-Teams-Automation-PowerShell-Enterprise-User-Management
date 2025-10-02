<#
.SYNOPSIS
    Backup Microsoft Teams configuration to JSON.

.DESCRIPTION
    Exports team settings, channels, members, and structure to JSON backup files.
    Enables disaster recovery and team restoration.

.PARAMETER TeamId
    Specific team to backup

.PARAMETER BackupPath
    Directory for backup files (default: .\Backups)

.PARAMETER IncludeMembers
    Include member list in backup

.EXAMPLE
    .\Backup-TeamConfig.ps1 -TeamId "abc-123" -BackupPath "C:\Backups"

.EXAMPLE
    Get-Team | ForEach-Object { .\Backup-TeamConfig.ps1 -TeamId $_.GroupId -IncludeMembers }
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$TeamId,
    [string]$BackupPath = ".\Backups",
    [switch]$IncludeMembers
)

Import-Module MicrosoftTeams

try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== Team Configuration Backup ===" -ForegroundColor Cyan

# Create backup directory
if (!(Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath | Out-Null
}

try {
    $team = Get-Team -GroupId $TeamId
    Write-Host "Backing up: $($team.DisplayName)" -ForegroundColor Yellow

    # Build backup object
    $backup = @{
        TeamInfo = @{
            DisplayName = $team.DisplayName
            Description = $team.Description
            Visibility = $team.Visibility
            MailNickname = $team.MailNickname
            Archived = $team.Archived
            CreatedDateTime = $team.WhenCreated
            Settings = @{
                AllowGiphy = $team.AllowGiphy
                GiphyContentRating = $team.GiphyContentRating
                AllowStickersAndMemes = $team.AllowStickersAndMemes
                AllowCustomMemes = $team.AllowCustomMemes
                AllowAddRemoveApps = $team.AllowAddRemoveApps
                AllowCreateUpdateChannels = $team.AllowCreateUpdateChannels
                AllowDeleteChannels = $team.AllowDeleteChannels
                AllowUserEditMessages = $team.AllowUserEditMessages
                AllowUserDeleteMessages = $team.AllowUserDeleteMessages
            }
        }
        Channels = @()
        BackupDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        BackupVersion = "1.0"
    }

    # Backup channels
    $channels = Get-TeamChannel -GroupId $TeamId
    foreach ($channel in $channels) {
        $backup.Channels += @{
            DisplayName = $channel.DisplayName
            Description = $channel.Description
            MembershipType = $channel.MembershipType
        }
    }
    Write-Host "  ✓ Backed up $($channels.Count) channels" -ForegroundColor Green

    # Backup members if requested
    if ($IncludeMembers) {
        $members = Get-TeamUser -GroupId $TeamId
        $backup.Members = @()
        foreach ($member in $members) {
            $backup.Members += @{
                User = $member.User
                Role = $member.Role
            }
        }
        Write-Host "  ✓ Backed up $($members.Count) members" -ForegroundColor Green
    }

    # Save to JSON
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $safeName = $team.DisplayName -replace '[\\/:*?"<>|]', '_'
    $filename = "$BackupPath\Team_${safeName}_$timestamp.json"

    $backup | ConvertTo-Json -Depth 10 | Out-File $filename

    Write-Host "`n✓ Backup saved to: $filename" -ForegroundColor Green
    Write-Host ""

    return $backup

} catch {
    Write-Error "Backup failed: $_"
    exit 1
}
