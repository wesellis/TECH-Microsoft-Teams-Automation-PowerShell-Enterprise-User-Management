<#
.SYNOPSIS
    Create department-specific Microsoft Teams with standard configuration.

.DESCRIPTION
    Creates Teams for departments with predefined channels, settings, and policies.
    Includes standard channels: General, Announcements, Resources, Projects

.PARAMETER DepartmentName
    Name of the department (e.g., "Engineering", "Sales", "HR")

.PARAMETER Manager
    Email of department manager (will be added as owner)

.PARAMETER Members
    Array of member email addresses

.PARAMETER IncludeStandardChannels
    Add standard department channels

.EXAMPLE
    .\New-DepartmentTeam.ps1 -DepartmentName "Engineering" -Manager "manager@contoso.com" -IncludeStandardChannels

.NOTES
    Creates private team by default with standardized department setup
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$DepartmentName,

    [Parameter(Mandatory=$true)]
    [string]$Manager,

    [string[]]$Members,

    [switch]$IncludeStandardChannels,

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

Write-Host "`n=== Creating Department Team ===" -ForegroundColor Cyan
Write-Host "Department: $DepartmentName" -ForegroundColor White
Write-Host "Manager: $Manager" -ForegroundColor White
Write-Host ""

try {
    # Create team
    $teamName = "$DepartmentName Department"
    $description = "Official Microsoft Teams workspace for the $DepartmentName department"

    $team = New-Team -DisplayName $teamName -Description $description -Visibility $Visibility
    Write-Host "✓ Team created: $teamName" -ForegroundColor Green
    Write-Host "  ID: $($team.GroupId)" -ForegroundColor Gray

    # Add manager as owner
    Add-TeamUser -GroupId $team.GroupId -User $Manager -Role Owner
    Write-Host "✓ Added manager as owner: $Manager" -ForegroundColor Green

    # Add members
    if ($Members -and $Members.Count -gt 0) {
        foreach ($member in $Members) {
            try {
                Add-TeamUser -GroupId $team.GroupId -User $member -Role Member
                Write-Host "✓ Added member: $member" -ForegroundColor Green
            } catch {
                Write-Host "⚠ Failed to add member $member : $_" -ForegroundColor Yellow
            }
        }
    }

    # Create standard channels
    if ($IncludeStandardChannels) {
        $channels = @(
            @{Name="Announcements"; Description="Department announcements and updates"},
            @{Name="Resources"; Description="Shared resources and documentation"},
            @{Name="Projects"; Description="Current department projects"},
            @{Name="Team Building"; Description="Social and team building activities"}
        )

        foreach ($channel in $channels) {
            try {
                New-TeamChannel -GroupId $team.GroupId `
                               -DisplayName $channel.Name `
                               -Description $channel.Description
                Write-Host "✓ Created channel: $($channel.Name)" -ForegroundColor Green
            } catch {
                Write-Host "⚠ Failed to create channel $($channel.Name): $_" -ForegroundColor Yellow
            }
        }
    }

    # Configure team settings
    Set-Team -GroupId $team.GroupId `
             -AllowGiphy $true `
             -GiphyContentRating Moderate `
             -AllowStickersAndMemes $true `
             -AllowCustomMemes $true

    Write-Host "`n✓ Department team setup complete!" -ForegroundColor Green
    Write-Host "`nTeam Details:" -ForegroundColor Cyan
    Write-Host "  Name: $teamName" -ForegroundColor White
    Write-Host "  ID: $($team.GroupId)" -ForegroundColor White
    Write-Host "  Visibility: $Visibility" -ForegroundColor White
    Write-Host ""

    return $team

} catch {
    Write-Error "Failed to create department team: $_"
    exit 1
}
