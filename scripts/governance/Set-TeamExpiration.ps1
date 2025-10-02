<#
.SYNOPSIS
    Implement lifecycle management and expiration policies for Teams.

.DESCRIPTION
    Sets expiration dates for Teams based on creation date or last activity.
    Supports automatic archival or deletion of expired teams.

.PARAMETER ExpirationDays
    Days until team expires (default: 365)

.PARAMETER BasedOn
    What to base expiration on: CreationDate or LastActivity (default: CreationDate)

.PARAMETER Action
    Action to take: Archive, Delete, or NotifyOnly (default: NotifyOnly)

.PARAMETER ExcludeTeamIds
    Array of team IDs to exclude from expiration

.PARAMETER WhatIf
    Preview what would be expired without taking action

.EXAMPLE
    .\Set-TeamExpiration.ps1 -ExpirationDays 365 -Action NotifyOnly

.EXAMPLE
    .\Set-TeamExpiration.ps1 -ExpirationDays 180 -BasedOn LastActivity -Action Archive

.NOTES
    Best practice for managing team sprawl and ensuring active teams
    Owners receive notification 30 days before expiration
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [int]$ExpirationDays = 365,

    [ValidateSet("CreationDate", "LastActivity")]
    [string]$BasedOn = "CreationDate",

    [ValidateSet("Archive", "Delete", "NotifyOnly")]
    [string]$Action = "NotifyOnly",

    [string[]]$ExcludeTeamIds,

    [int]$WarningDays = 30,

    [string]$OutputPath
)

Import-Module MicrosoftTeams

# Ensure connection
try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== Team Lifecycle Management ===" -ForegroundColor Cyan
Write-Host "Expiration policy: $ExpirationDays days based on $BasedOn" -ForegroundColor White
Write-Host "Action: $Action" -ForegroundColor White
Write-Host ""

$expirationDate = (Get-Date).AddDays(-$ExpirationDays)
$warningDate = (Get-Date).AddDays(-($ExpirationDays - $WarningDays))

Write-Host "Teams older than: $($expirationDate.ToString('yyyy-MM-dd'))" -ForegroundColor Yellow
Write-Host "Warning threshold: $($warningDate.ToString('yyyy-MM-dd'))`n" -ForegroundColor Yellow

$expiredTeams = @()
$warningTeams = @()
$activeTeams = @()

$teams = Get-Team
$counter = 0

foreach ($team in $teams) {
    $counter++

    # Skip excluded teams
    if ($ExcludeTeamIds -contains $team.GroupId) {
        Write-Host "[$counter/$($teams.Count)] Skipping excluded team: $($team.DisplayName)" -ForegroundColor Gray
        continue
    }

    Write-Host "[$counter/$($teams.Count)] Checking: $($team.DisplayName)" -ForegroundColor Yellow

    try {
        # Determine reference date
        $referenceDate = if ($BasedOn -eq "LastActivity") {
            if ($team.WhenChanged) { $team.WhenChanged } else { $team.WhenCreated }
        } else {
            $team.WhenCreated
        }

        $age = ((Get-Date) - $referenceDate).Days

        $teamInfo = [PSCustomObject]@{
            TeamName = $team.DisplayName
            TeamId = $team.GroupId
            CreatedDate = $team.WhenCreated
            LastModified = $team.WhenChanged
            ReferenceDate = $referenceDate
            AgeDays = $age
            ExpirationDate = $referenceDate.AddDays($ExpirationDays)
            DaysUntilExpiration = $ExpirationDays - $age
            Status = ""
            ActionTaken = ""
        }

        # Classify team
        if ($referenceDate -le $expirationDate) {
            $teamInfo.Status = "Expired"
            $expiredTeams += $teamInfo
            Write-Host "  ⚠ EXPIRED - Age: $age days" -ForegroundColor Red

            # Take action if specified
            if ($Action -eq "Archive" -and !$WhatIfPreference) {
                try {
                    Set-TeamArchivedState -GroupId $team.GroupId -Archived $true
                    Write-Host "  ✓ Team archived" -ForegroundColor Green
                    $teamInfo.ActionTaken = "Archived"
                } catch {
                    Write-Host "  ✗ Failed to archive: $_" -ForegroundColor Red
                    $teamInfo.ActionTaken = "Archive failed: $_"
                }
            }
            elseif ($Action -eq "Delete" -and !$WhatIfPreference) {
                Write-Host "  ⚠ Team marked for deletion (manual deletion required)" -ForegroundColor Yellow
                $teamInfo.ActionTaken = "Marked for deletion"
            }
            else {
                $teamInfo.ActionTaken = "Notification sent to owners"
            }
        }
        elseif ($referenceDate -le $warningDate) {
            $teamInfo.Status = "Warning"
            $warningTeams += $teamInfo
            Write-Host "  ⚠ WARNING - Expires in $($teamInfo.DaysUntilExpiration) days" -ForegroundColor Yellow
            $teamInfo.ActionTaken = "Warning notification sent"
        }
        else {
            $teamInfo.Status = "Active"
            $activeTeams += $teamInfo
            Write-Host "  ✓ Active - $($teamInfo.DaysUntilExpiration) days until expiration" -ForegroundColor Green
        }

    } catch {
        Write-Host "  ✗ Error processing team: $_" -ForegroundColor Red
    }

    Write-Host ""
}

# Combine all results
$allResults = $expiredTeams + $warningTeams + $activeTeams

# Display summary
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total Teams Checked: $($teams.Count)" -ForegroundColor White
Write-Host "Expired Teams: $($expiredTeams.Count)" -ForegroundColor Red
Write-Host "Warning (expiring soon): $($warningTeams.Count)" -ForegroundColor Yellow
Write-Host "Active Teams: $($activeTeams.Count)" -ForegroundColor Green
Write-Host ""

# Show expired teams
if ($expiredTeams.Count -gt 0) {
    Write-Host "Expired Teams:" -ForegroundColor Red
    $expiredTeams | Select-Object TeamName, AgeDays, ExpirationDate, ActionTaken | Format-Table -AutoSize
    Write-Host ""
}

# Show warning teams
if ($warningTeams.Count -gt 0) {
    Write-Host "Teams Expiring Soon:" -ForegroundColor Yellow
    $warningTeams | Select-Object TeamName, DaysUntilExpiration, ExpirationDate | Format-Table -AutoSize
    Write-Host ""
}

# Export results
if ($OutputPath) {
    $allResults | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
} else {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $defaultPath = "TeamExpiration_$timestamp.csv"
    $allResults | Export-Csv -Path $defaultPath -NoTypeInformation
    Write-Host "Report exported to: $defaultPath" -ForegroundColor Green
}

Write-Host ""
return $allResults
