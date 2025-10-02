<#
.SYNOPSIS
    Find Microsoft Teams without owners or with insufficient owners.

.DESCRIPTION
    Identifies teams that are orphaned (no owners) or at risk (only one owner).
    Critical for governance to ensure all teams have proper ownership.

.PARAMETER MinimumOwners
    Minimum number of owners required (default: 2)

.PARAMETER FixAutomatically
    Automatically promote members to owners to meet minimum requirement

.PARAMETER NotifyUsers
    Send notification to team members about orphan status

.PARAMETER OutputPath
    Path for CSV export

.EXAMPLE
    .\Find-OrphanedTeams.ps1

.EXAMPLE
    .\Find-OrphanedTeams.ps1 -MinimumOwners 2 -FixAutomatically

.NOTES
    Best practice: Every team should have at least 2 owners
    Helps prevent access loss if single owner leaves organization
#>

[CmdletBinding()]
param(
    [int]$MinimumOwners = 2,

    [switch]$FixAutomatically,

    [switch]$NotifyUsers,

    [string]$OutputPath,

    [string]$DefaultOwnerEmail
)

Import-Module MicrosoftTeams

# Ensure connection
try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== Orphaned Teams Detection ===" -ForegroundColor Cyan
Write-Host "Minimum owners required: $MinimumOwners" -ForegroundColor White
Write-Host ""

$orphanedTeams = @()
$atRiskTeams = @()
$healthyTeams = @()

$teams = Get-Team
$counter = 0

foreach ($team in $teams) {
    $counter++
    Write-Host "[$counter/$($teams.Count)] Checking: $($team.DisplayName)" -ForegroundColor Yellow

    try {
        $members = Get-TeamUser -GroupId $team.GroupId
        $owners = $members | Where-Object {$_.Role -eq "Owner"}
        $regularMembers = $members | Where-Object {$_.Role -eq "Member"}

        $teamInfo = [PSCustomObject]@{
            TeamName = $team.DisplayName
            TeamId = $team.GroupId
            Visibility = $team.Visibility
            OwnerCount = $owners.Count
            MemberCount = $regularMembers.Count
            TotalUsers = $members.Count
            Owners = ($owners | Select-Object -ExpandProperty User) -join "; "
            Status = ""
            Action = ""
        }

        # Classify team status
        if ($owners.Count -eq 0) {
            $teamInfo.Status = "Orphaned"
            $teamInfo.Action = "CRITICAL - No owners"
            $orphanedTeams += $teamInfo
            Write-Host "  ⚠ ORPHANED - No owners!" -ForegroundColor Red
        }
        elseif ($owners.Count -lt $MinimumOwners) {
            $teamInfo.Status = "At Risk"
            $teamInfo.Action = "WARNING - Only $($owners.Count) owner(s)"
            $atRiskTeams += $teamInfo
            Write-Host "  ⚠ AT RISK - Only $($owners.Count) owner(s)" -ForegroundColor Yellow
        }
        else {
            $teamInfo.Status = "Healthy"
            $teamInfo.Action = "OK"
            $healthyTeams += $teamInfo
            Write-Host "  ✓ Healthy - $($owners.Count) owners" -ForegroundColor Green
        }

        # Auto-fix if requested
        if ($FixAutomatically) {
            if ($owners.Count -eq 0 -and $DefaultOwnerEmail) {
                # Add default owner to orphaned team
                try {
                    Add-TeamUser -GroupId $team.GroupId -User $DefaultOwnerEmail -Role Owner
                    Write-Host "  ✓ Added default owner: $DefaultOwnerEmail" -ForegroundColor Green
                    $teamInfo.Action += " - Fixed (added default owner)"
                } catch {
                    Write-Host "  ✗ Failed to add default owner: $_" -ForegroundColor Red
                }
            }
            elseif ($owners.Count -lt $MinimumOwners -and $regularMembers.Count -gt 0) {
                # Promote a member to owner
                $membersNeeded = $MinimumOwners - $owners.Count
                $membersToPromote = $regularMembers | Select-Object -First $membersNeeded

                foreach ($member in $membersToPromote) {
                    try {
                        Add-TeamUser -GroupId $team.GroupId -User $member.User -Role Owner
                        Write-Host "  ✓ Promoted to owner: $($member.User)" -ForegroundColor Green
                        $teamInfo.Action += " - Fixed (promoted member)"
                    } catch {
                        Write-Host "  ✗ Failed to promote $($member.User): $_" -ForegroundColor Red
                    }
                }
            }
        }

    } catch {
        Write-Host "  ✗ Error checking team: $_" -ForegroundColor Red
    }

    Write-Host ""
}

# Combine all results
$allResults = $orphanedTeams + $atRiskTeams + $healthyTeams

# Display summary
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total Teams: $($teams.Count)" -ForegroundColor White
Write-Host "Orphaned (0 owners): $($orphanedTeams.Count)" -ForegroundColor Red
Write-Host "At Risk (<$MinimumOwners owners): $($atRiskTeams.Count)" -ForegroundColor Yellow
Write-Host "Healthy (>=$MinimumOwners owners): $($healthyTeams.Count)" -ForegroundColor Green
Write-Host ""

# Show critical orphaned teams
if ($orphanedTeams.Count -gt 0) {
    Write-Host "CRITICAL - Orphaned Teams:" -ForegroundColor Red
    $orphanedTeams | Select-Object TeamName, TotalUsers, Action | Format-Table -AutoSize
    Write-Host ""
}

# Show at-risk teams
if ($atRiskTeams.Count -gt 0) {
    Write-Host "WARNING - At-Risk Teams:" -ForegroundColor Yellow
    $atRiskTeams | Select-Object TeamName, OwnerCount, MemberCount, Owners | Format-Table -AutoSize
    Write-Host ""
}

# Export results
if ($OutputPath) {
    $allResults | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host "Full report exported to: $OutputPath" -ForegroundColor Green
} else {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $defaultPath = "OrphanedTeams_$timestamp.csv"
    $allResults | Export-Csv -Path $defaultPath -NoTypeInformation
    Write-Host "Full report exported to: $defaultPath" -ForegroundColor Green
}

# Recommendations
if ($orphanedTeams.Count -gt 0 -or $atRiskTeams.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Cyan
    Write-Host "1. Review orphaned teams and assign owners immediately" -ForegroundColor White
    Write-Host "2. Promote additional members to owner role for at-risk teams" -ForegroundColor White
    Write-Host "3. Consider implementing governance policies to prevent orphaned teams" -ForegroundColor White
    Write-Host "4. Run with -FixAutomatically to auto-promote members" -ForegroundColor White
}

Write-Host ""
return $allResults
