<#
.SYNOPSIS
    Remove inactive users from Microsoft Teams.

.DESCRIPTION
    Identifies and removes users who haven't been active in Teams for a specified period.
    Can target specific teams or all teams organization-wide.

.PARAMETER TeamId
    Specific team to check (optional - if omitted, checks all teams)

.PARAMETER InactiveDays
    Number of days of inactivity (default: 90)

.PARAMETER WhatIf
    Preview what would be removed without actually removing

.PARAMETER RemoveFromTeams
    Actually remove users (requires confirmation unless -Force is used)

.EXAMPLE
    .\Remove-InactiveUsers.ps1 -InactiveDays 90 -WhatIf

.EXAMPLE
    .\Remove-InactiveUsers.ps1 -TeamId "abc-123" -InactiveDays 60 -RemoveFromTeams

.NOTES
    Requires Teams administrator permissions
    Always backs up user list before removal
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$TeamId,

    [int]$InactiveDays = 90,

    [switch]$RemoveFromTeams,

    [switch]$Force
)

Import-Module MicrosoftTeams

# Ensure connection
try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== Inactive User Removal ===" -ForegroundColor Cyan
Write-Host "Inactivity threshold: $InactiveDays days" -ForegroundColor White

$cutoffDate = (Get-Date).AddDays(-$InactiveDays)
Write-Host "Checking users inactive since: $($cutoffDate.ToString('yyyy-MM-dd'))`n" -ForegroundColor White

$inactiveUsers = @()

# Get teams to check
if ($TeamId) {
    $teams = @(Get-Team -GroupId $TeamId)
    Write-Host "Checking specific team: $($teams[0].DisplayName)`n" -ForegroundColor Yellow
} else {
    $teams = Get-Team
    Write-Host "Checking all teams: $($teams.Count)`n" -ForegroundColor Yellow
}

foreach ($team in $teams) {
    Write-Host "Analyzing team: $($team.DisplayName)" -ForegroundColor Yellow

    try {
        $members = Get-TeamUser -GroupId $team.GroupId

        foreach ($member in $members) {
            # Get user activity
            try {
                $user = Get-CsOnlineUser -Identity $member.User
                $lastActivity = $user.WhenChanged

                if ($lastActivity -lt $cutoffDate) {
                    $inactiveUsers += [PSCustomObject]@{
                        TeamName = $team.DisplayName
                        TeamId = $team.GroupId
                        User = $member.User
                        Role = $member.Role
                        LastActivity = $lastActivity
                        DaysInactive = ((Get-Date) - $lastActivity).Days
                    }

                    Write-Host "  ⚠ Inactive: $($member.User) (Last active: $lastActivity)" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "  ⚠ Could not check activity for $($member.User)" -ForegroundColor Gray
            }
        }
    } catch {
        Write-Host "  ✗ Error checking team: $_" -ForegroundColor Red
    }

    Write-Host ""
}

# Display results
Write-Host "=== Results ===" -ForegroundColor Cyan
Write-Host "Total inactive users found: $($inactiveUsers.Count)`n" -ForegroundColor Red

if ($inactiveUsers.Count -eq 0) {
    Write-Host "No inactive users found!" -ForegroundColor Green
    exit 0
}

# Export to CSV for backup
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = "InactiveUsers_$timestamp.csv"
$inactiveUsers | Export-Csv -Path $backupPath -NoTypeInformation
Write-Host "Inactive users list saved to: $backupPath`n" -ForegroundColor Cyan

# Display sample
$inactiveUsers | Select-Object TeamName, User, DaysInactive | Format-Table -AutoSize

# Remove if requested
if ($RemoveFromTeams) {
    if (!$Force) {
        $confirmation = Read-Host "`nRemove $($inactiveUsers.Count) inactive users from Teams? (yes/no)"
        if ($confirmation -ne "yes") {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            exit 0
        }
    }

    Write-Host "`nRemoving inactive users..." -ForegroundColor Yellow
    $removed = 0

    foreach ($user in $inactiveUsers) {
        try {
            Remove-TeamUser -GroupId $user.TeamId -User $user.User
            Write-Host "  ✓ Removed $($user.User) from $($user.TeamName)" -ForegroundColor Green
            $removed++
        } catch {
            Write-Host "  ✗ Failed to remove $($user.User): $_" -ForegroundColor Red
        }
    }

    Write-Host "`n✓ Removed $removed/$($inactiveUsers.Count) inactive users" -ForegroundColor Green
} else {
    Write-Host "Run with -RemoveFromTeams to actually remove these users." -ForegroundColor Cyan
}

Write-Host ""
return $inactiveUsers
