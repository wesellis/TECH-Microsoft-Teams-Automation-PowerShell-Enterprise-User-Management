<#
.SYNOPSIS
    Clone an existing Microsoft Team structure to create a new team.

.DESCRIPTION
    Duplicates team structure including channels, settings, and optionally members.
    Useful for creating similar teams based on a template.

.PARAMETER SourceTeamId
    GroupId of the team to clone

.PARAMETER NewTeamName
    Name for the new team

.PARAMETER IncludeMembers
    Copy members from source team

.PARAMETER IncludeSettings
    Copy team settings

.EXAMPLE
    .\Clone-TeamTemplate.ps1 -SourceTeamId "abc-123" -NewTeamName "Q2 Project Team"

.EXAMPLE
    .\Clone-TeamTemplate.ps1 -SourceTeamId "abc-123" -NewTeamName "New Team" -IncludeMembers -IncludeSettings

.NOTES
    Does not clone: messages, files, or meeting history
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SourceTeamId,

    [Parameter(Mandatory=$true)]
    [string]$NewTeamName,

    [string]$NewTeamDescription,

    [switch]$IncludeMembers,

    [switch]$IncludeSettings,

    [ValidateSet("Public", "Private")]
    [string]$Visibility = "Private"
)

Import-Module MicrosoftTeams

# Ensure connection
try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== Cloning Team ===" -ForegroundColor Cyan

try {
    # Get source team details
    $sourceTeam = Get-Team -GroupId $SourceTeamId
    Write-Host "Source Team: $($sourceTeam.DisplayName)" -ForegroundColor White

    # Create new team
    $description = if ($NewTeamDescription) { $NewTeamDescription } else { "Cloned from: $($sourceTeam.DisplayName)" }

    $newTeam = New-Team -DisplayName $NewTeamName -Description $description -Visibility $Visibility
    Write-Host "✓ New team created: $NewTeamName (ID: $($newTeam.GroupId))" -ForegroundColor Green

    # Clone channels
    $channels = Get-TeamChannel -GroupId $SourceTeamId
    Write-Host "`nCloning channels..." -ForegroundColor Yellow

    foreach ($channel in $channels) {
        if ($channel.DisplayName -ne "General") {
            try {
                New-TeamChannel -GroupId $newTeam.GroupId `
                               -DisplayName $channel.DisplayName `
                               -Description $channel.Description `
                               -MembershipType $channel.MembershipType
                Write-Host "  ✓ Cloned channel: $($channel.DisplayName)" -ForegroundColor Green
            } catch {
                Write-Host "  ⚠ Failed to clone channel $($channel.DisplayName): $_" -ForegroundColor Yellow
            }
        }
    }

    # Clone members if requested
    if ($IncludeMembers) {
        Write-Host "`nCloning members..." -ForegroundColor Yellow
        $members = Get-TeamUser -GroupId $SourceTeamId

        foreach ($member in $members) {
            try {
                Add-TeamUser -GroupId $newTeam.GroupId -User $member.User -Role $member.Role
                Write-Host "  ✓ Added $($member.Role): $($member.User)" -ForegroundColor Green
            } catch {
                Write-Host "  ⚠ Failed to add $($member.User): $_" -ForegroundColor Yellow
            }
        }
    }

    # Clone settings if requested
    if ($IncludeSettings) {
        Write-Host "`nCloning settings..." -ForegroundColor Yellow

        $settings = @{
            GroupId = $newTeam.GroupId
            AllowGiphy = $sourceTeam.AllowGiphy
            GiphyContentRating = $sourceTeam.GiphyContentRating
            AllowStickersAndMemes = $sourceTeam.AllowStickersAndMemes
            AllowCustomMemes = $sourceTeam.AllowCustomMemes
            AllowAddRemoveApps = $sourceTeam.AllowAddRemoveApps
            AllowCreateUpdateChannels = $sourceTeam.AllowCreateUpdateChannels
            AllowDeleteChannels = $sourceTeam.AllowDeleteChannels
        }

        Set-Team @settings
        Write-Host "  ✓ Settings applied" -ForegroundColor Green
    }

    Write-Host "`n✓ Team cloning complete!" -ForegroundColor Green
    Write-Host "`nNew Team:" -ForegroundColor Cyan
    Write-Host "  Name: $NewTeamName" -ForegroundColor White
    Write-Host "  ID: $($newTeam.GroupId)" -ForegroundColor White
    Write-Host "  Channels: $(($channels.Count))" -ForegroundColor White

    if ($IncludeMembers) {
        Write-Host "  Members: $(($members.Count))" -ForegroundColor White
    }
    Write-Host ""

    return $newTeam

} catch {
    Write-Error "Failed to clone team: $_"
    exit 1
}
