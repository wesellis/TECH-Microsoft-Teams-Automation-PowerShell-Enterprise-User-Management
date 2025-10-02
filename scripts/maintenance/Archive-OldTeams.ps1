<#
.SYNOPSIS
    Archive inactive or old Microsoft Teams.

.DESCRIPTION
    Identifies and archives teams based on age or inactivity criteria.
    Archived teams are read-only but data is preserved.

.PARAMETER InactiveDays
    Days of inactivity before archiving (default: 180)

.PARAMETER AgeInDays
    Archive teams older than specified days

.PARAMETER ExcludeTeamIds
    Teams to exclude from archival

.PARAMETER AutoArchive
    Automatically archive without confirmation

.PARAMETER WhatIf
    Preview what would be archived

.EXAMPLE
    .\Archive-OldTeams.ps1 -InactiveDays 180 -WhatIf

.EXAMPLE
    .\Archive-OldTeams.ps1 -AgeInDays 365 -AutoArchive

.NOTES
    Archiving preserves all data while preventing new activity
    Can be unarchived if needed later
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [int]$InactiveDays,

    [int]$AgeInDays,

    [string[]]$ExcludeTeamIds,

    [switch]$AutoArchive,

    [string]$OutputPath
)

Import-Module MicrosoftTeams

# Ensure connection
try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== Team Archival Process ===" -ForegroundColor Cyan

# Determine criteria
$criteria = @()
if ($InactiveDays) {
    $inactivityCutoff = (Get-Date).AddDays(-$InactiveDays)
    $criteria += "Inactive for $InactiveDays days"
    Write-Host "Criteria: Inactive since $($inactivityCutoff.ToString('yyyy-MM-dd'))" -ForegroundColor White
}
if ($AgeInDays) {
    $ageCutoff = (Get-Date).AddDays(-$AgeInDays)
    $criteria += "Older than $AgeInDays days"
    Write-Host "Criteria: Created before $($ageCutoff.ToString('yyyy-MM-dd'))" -ForegroundColor White
}

if ($criteria.Count -eq 0) {
    Write-Error "Must specify either -InactiveDays or -AgeInDays"
    exit 1
}

Write-Host ""

$teamsToArchive = @()
$alreadyArchived = @()
$excluded = @()
$active = @()

$teams = Get-Team | Where-Object {$_.Archived -eq $false}
Write-Host "Scanning $($teams.Count) active teams...`n" -ForegroundColor Yellow

$counter = 0

foreach ($team in $teams) {
    $counter++

    # Skip excluded teams
    if ($ExcludeTeamIds -contains $team.GroupId) {
        $excluded += $team
        Write-Host "[$counter/$($teams.Count)] Skipping excluded: $($team.DisplayName)" -ForegroundColor Gray
        continue
    }

    Write-Host "[$counter/$($teams.Count)] Checking: $($team.DisplayName)" -ForegroundColor Yellow

    $shouldArchive = $false
    $reason = @()

    # Check inactivity
    if ($InactiveDays -and $team.WhenChanged) {
        if ($team.WhenChanged -lt $inactivityCutoff) {
            $shouldArchive = $true
            $daysSinceActivity = ((Get-Date) - $team.WhenChanged).Days
            $reason += "Inactive for $daysSinceActivity days"
        }
    }

    # Check age
    if ($AgeInDays -and $team.WhenCreated) {
        if ($team.WhenCreated -lt $ageCutoff) {
            $shouldArchive = $true
            $ageInDays = ((Get-Date) - $team.WhenCreated).Days
            $reason += "Age: $ageInDays days old"
        }
    }

    $teamInfo = [PSCustomObject]@{
        TeamName = $team.DisplayName
        TeamId = $team.GroupId
        Created = $team.WhenCreated
        LastActivity = $team.WhenChanged
        Reason = ($reason -join "; ")
        Status = ""
        ActionTaken = ""
    }

    if ($shouldArchive) {
        $teamsToArchive += $teamInfo
        Write-Host "  ⚠ Eligible for archival: $($reason -join ', ')" -ForegroundColor Yellow
        $teamInfo.Status = "Eligible for archival"
    }
    else {
        $active += $teamInfo
        Write-Host "  ✓ Active team" -ForegroundColor Green
        $teamInfo.Status = "Active"
    }

    Write-Host ""
}

# Display summary
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total Teams Scanned: $($teams.Count)" -ForegroundColor White
Write-Host "Eligible for Archival: $($teamsToArchive.Count)" -ForegroundColor Yellow
Write-Host "Excluded: $($excluded.Count)" -ForegroundColor Gray
Write-Host "Active: $($active.Count)" -ForegroundColor Green
Write-Host ""

if ($teamsToArchive.Count -eq 0) {
    Write-Host "No teams eligible for archival!" -ForegroundColor Green
    exit 0
}

# Show teams to archive
Write-Host "Teams Eligible for Archival:" -ForegroundColor Yellow
$teamsToArchive | Select-Object TeamName, Created, LastActivity, Reason | Format-Table -AutoSize

# Archive teams
if (!$WhatIfPreference) {
    if (!$AutoArchive) {
        $confirmation = Read-Host "`nArchive $($teamsToArchive.Count) teams? (yes/no)"
        if ($confirmation -ne "yes") {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            exit 0
        }
    }

    Write-Host "`nArchiving teams..." -ForegroundColor Yellow
    $archived = 0

    foreach ($team in $teamsToArchive) {
        try {
            Set-TeamArchivedState -GroupId $team.TeamId -Archived $true
            Write-Host "  ✓ Archived: $($team.TeamName)" -ForegroundColor Green
            $team.ActionTaken = "Archived"
            $archived++
        } catch {
            Write-Host "  ✗ Failed to archive $($team.TeamName): $_" -ForegroundColor Red
            $team.ActionTaken = "Archive failed: $_"
        }
    }

    Write-Host "`n✓ Archived $archived/$($teamsToArchive.Count) teams" -ForegroundColor Green
}
else {
    Write-Host "WhatIf: Would archive $($teamsToArchive.Count) teams" -ForegroundColor Cyan
}

# Export results
if ($OutputPath) {
    $teamsToArchive | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
} else {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $defaultPath = "ArchivedTeams_$timestamp.csv"
    $teamsToArchive | Export-Csv -Path $defaultPath -NoTypeInformation
    Write-Host "Report exported to: $defaultPath" -ForegroundColor Green
}

Write-Host ""
return $teamsToArchive
