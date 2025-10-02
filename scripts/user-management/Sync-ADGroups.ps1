<#
.SYNOPSIS
    Synchronize Active Directory group membership with Microsoft Teams.

.DESCRIPTION
    Keeps Teams membership in sync with AD group membership.
    Adds new AD group members to Teams and optionally removes users no longer in AD group.

.PARAMETER ADGroupName
    Name of the Active Directory group

.PARAMETER TeamId
    GroupId of the Microsoft Team

.PARAMETER RemoveObsoleteMembers
    Remove users from Teams who are no longer in AD group

.PARAMETER Role
    Role to assign to synced members (default: Member)

.EXAMPLE
    .\Sync-ADGroups.ps1 -ADGroupName "Sales-Team" -TeamId "abc-123"

.EXAMPLE
    .\Sync-ADGroups.ps1 -ADGroupName "Engineering" -TeamId "xyz-789" -RemoveObsoleteMembers -Role Member

.NOTES
    Requires Active Directory PowerShell module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ADGroupName,

    [Parameter(Mandatory=$true)]
    [string]$TeamId,

    [switch]$RemoveObsoleteMembers,

    [ValidateSet("Member", "Owner")]
    [string]$Role = "Member"
)

# Import modules
Import-Module MicrosoftTeams
Import-Module ActiveDirectory -ErrorAction Stop

# Ensure Teams connection
try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== AD Group Sync ===" -ForegroundColor Cyan
Write-Host "AD Group: $ADGroupName" -ForegroundColor White
Write-Host "Team ID: $TeamId`n" -ForegroundColor White

try {
    # Get AD group members
    $adMembers = Get-ADGroupMember -Identity $ADGroupName | Where-Object {$_.objectClass -eq "user"}
    $adUsers = $adMembers | Get-ADUser -Properties mail | Where-Object {$_.mail} | Select-Object -ExpandProperty mail

    Write-Host "AD Group Members: $($adUsers.Count)" -ForegroundColor Green

    # Get current Teams members
    $teamMembers = Get-TeamUser -GroupId $TeamId | Where-Object {$_.Role -eq $Role}
    Write-Host "Current Team Members: $($teamMembers.Count)" -ForegroundColor Green
    Write-Host ""

    # Find users to add
    $usersToAdd = $adUsers | Where-Object {$_ -notin $teamMembers.User}

    # Find users to remove
    $usersToRemove = @()
    if ($RemoveObsoleteMembers) {
        $usersToRemove = $teamMembers.User | Where-Object {$_ -notin $adUsers}
    }

    Write-Host "Users to add: $($usersToAdd.Count)" -ForegroundColor Yellow
    Write-Host "Users to remove: $($usersToRemove.Count)" -ForegroundColor Yellow
    Write-Host ""

    # Add new users
    if ($usersToAdd.Count -gt 0) {
        Write-Host "Adding new members..." -ForegroundColor Yellow
        foreach ($user in $usersToAdd) {
            try {
                Add-TeamUser -GroupId $TeamId -User $user -Role $Role
                Write-Host "  ✓ Added: $user" -ForegroundColor Green
            } catch {
                Write-Host "  ✗ Failed to add $user : $_" -ForegroundColor Red
            }
        }
    }

    # Remove obsolete users
    if ($RemoveObsoleteMembers -and $usersToRemove.Count -gt 0) {
        Write-Host "`nRemoving obsolete members..." -ForegroundColor Yellow
        foreach ($user in $usersToRemove) {
            try {
                Remove-TeamUser -GroupId $TeamId -User $user
                Write-Host "  ✓ Removed: $user" -ForegroundColor Green
            } catch {
                Write-Host "  ✗ Failed to remove $user : $_" -ForegroundColor Red
            }
        }
    }

    Write-Host "`n✓ Synchronization complete!" -ForegroundColor Green
    Write-Host ""

    return @{
        ADMembers = $adUsers.Count
        TeamMembers = $teamMembers.Count
        Added = $usersToAdd.Count
        Removed = $usersToRemove.Count
    }

} catch {
    Write-Error "Sync failed: $_"
    exit 1
}
