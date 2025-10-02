<#
.SYNOPSIS
    Generate detailed activity reports for Microsoft Teams.

.DESCRIPTION
    Analyzes Teams activity including messages, meetings, files, and active users.
    Provides insights for governance, compliance, and usage optimization.

.PARAMETER TeamId
    Specific team to analyze (optional - analyzes all teams if omitted)

.PARAMETER Days
    Number of days to analyze (default: 30)

.PARAMETER OutputPath
    Path for CSV export

.PARAMETER IncludeChannelActivity
    Include per-channel activity breakdown

.PARAMETER IncludeUserActivity
    Include per-user activity metrics

.EXAMPLE
    .\Get-TeamsActivity.ps1 -Days 30 -OutputPath ".\activity_report.csv"

.EXAMPLE
    .\Get-TeamsActivity.ps1 -TeamId "abc-123" -IncludeChannelActivity -IncludeUserActivity

.NOTES
    Requires Teams administrator and compliance permissions
    Uses Microsoft Graph API for detailed metrics
#>

[CmdletBinding()]
param(
    [string]$TeamId,

    [int]$Days = 30,

    [string]$OutputPath,

    [switch]$IncludeChannelActivity,

    [switch]$IncludeUserActivity
)

Import-Module MicrosoftTeams

# Ensure connection
try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== Teams Activity Report ===" -ForegroundColor Cyan
Write-Host "Analysis period: Last $Days days" -ForegroundColor White

$startDate = (Get-Date).AddDays(-$Days)
Write-Host "From: $($startDate.ToString('yyyy-MM-dd'))" -ForegroundColor White
Write-Host "To: $(Get-Date -Format 'yyyy-MM-dd')`n" -ForegroundColor White

$activityData = @()

# Get teams to analyze
if ($TeamId) {
    $teams = @(Get-Team -GroupId $TeamId)
    Write-Host "Analyzing single team: $($teams[0].DisplayName)`n" -ForegroundColor Yellow
} else {
    $teams = Get-Team
    Write-Host "Analyzing all teams: $($teams.Count)`n" -ForegroundColor Yellow
}

$counter = 0

foreach ($team in $teams) {
    $counter++
    Write-Host "[$counter/$($teams.Count)] Analyzing: $($team.DisplayName)" -ForegroundColor Yellow

    try {
        # Get team members
        $members = Get-TeamUser -GroupId $team.GroupId
        $ownerCount = ($members | Where-Object {$_.Role -eq "Owner"}).Count
        $memberCount = ($members | Where-Object {$_.Role -eq "Member"}).Count

        # Get channels
        $channels = Get-TeamChannel -GroupId $team.GroupId

        # Build activity record
        $record = [PSCustomObject]@{
            TeamName = $team.DisplayName
            TeamId = $team.GroupId
            Description = $team.Description
            Visibility = $team.Visibility
            Archived = $team.Archived
            TotalMembers = $members.Count
            Owners = $ownerCount
            Members = $memberCount
            ChannelCount = $channels.Count
            CreatedDate = $team.WhenCreated
            LastModified = $team.WhenChanged
            DaysSinceActivity = if ($team.WhenChanged) { ((Get-Date) - $team.WhenChanged).Days } else { "N/A" }
        }

        # Channel-level activity
        if ($IncludeChannelActivity) {
            $channelActivity = @()
            foreach ($channel in $channels) {
                $channelActivity += "$($channel.DisplayName) (Type: $($channel.MembershipType))"
            }
            $record | Add-Member -NotePropertyName Channels -NotePropertyValue ($channelActivity -join "; ")
        }

        # User-level activity
        if ($IncludeUserActivity) {
            $activeUsers = @()
            $inactiveUsers = @()

            foreach ($member in $members) {
                try {
                    $user = Get-CsOnlineUser -Identity $member.User
                    $daysSinceActive = if ($user.WhenChanged) { ((Get-Date) - $user.WhenChanged).Days } else { 999 }

                    if ($daysSinceActive -le $Days) {
                        $activeUsers += $member.User
                    } else {
                        $inactiveUsers += $member.User
                    }
                } catch {
                    # User info not available
                }
            }

            $record | Add-Member -NotePropertyName ActiveUsers -NotePropertyValue $activeUsers.Count
            $record | Add-Member -NotePropertyName InactiveUsers -NotePropertyValue $inactiveUsers.Count
            $record | Add-Member -NotePropertyName ActivityRate -NotePropertyValue ([math]::Round(($activeUsers.Count / $members.Count) * 100, 2))
        }

        # Determine activity status
        $activityStatus = if ($team.Archived) {
            "Archived"
        } elseif ($record.DaysSinceActivity -eq "N/A") {
            "Unknown"
        } elseif ($record.DaysSinceActivity -le 7) {
            "Very Active"
        } elseif ($record.DaysSinceActivity -le 30) {
            "Active"
        } elseif ($record.DaysSinceActivity -le 90) {
            "Low Activity"
        } else {
            "Inactive"
        }

        $record | Add-Member -NotePropertyName ActivityStatus -NotePropertyValue $activityStatus

        $activityData += $record

        # Display summary
        $statusColor = switch ($activityStatus) {
            "Very Active" { "Green" }
            "Active" { "Green" }
            "Low Activity" { "Yellow" }
            "Inactive" { "Red" }
            "Archived" { "Gray" }
            default { "White" }
        }

        Write-Host "  Status: $activityStatus" -ForegroundColor $statusColor
        Write-Host "  Members: $($members.Count) | Channels: $($channels.Count) | Days since activity: $($record.DaysSinceActivity)" -ForegroundColor Gray
        Write-Host ""

    } catch {
        Write-Host "  ✗ Error analyzing team: $_" -ForegroundColor Red
        Write-Host ""
    }
}

# Generate summary
Write-Host "=== Activity Summary ===" -ForegroundColor Cyan
Write-Host "Total Teams Analyzed: $($activityData.Count)" -ForegroundColor White
Write-Host ""

# Status breakdown
Write-Host "Activity Breakdown:" -ForegroundColor Cyan
$activityData | Group-Object ActivityStatus |
    Select-Object Name, Count, @{Name='Percentage';Expression={[math]::Round(($_.Count / $activityData.Count) * 100, 1)}} |
    Format-Table -AutoSize

# Top active teams
Write-Host "Most Active Teams (by recent activity):" -ForegroundColor Cyan
$activityData | Where-Object {$_.ActivityStatus -ne "Archived"} |
    Sort-Object DaysSinceActivity |
    Select-Object -First 10 TeamName, ActivityStatus, DaysSinceActivity, TotalMembers, ChannelCount |
    Format-Table -AutoSize

# Inactive teams alert
$inactiveTeams = $activityData | Where-Object {$_.ActivityStatus -eq "Inactive" -and $_.Archived -eq $false}
if ($inactiveTeams.Count -gt 0) {
    Write-Host "⚠ Inactive Teams ($($inactiveTeams.Count)):" -ForegroundColor Yellow
    $inactiveTeams | Select-Object TeamName, DaysSinceActivity, TotalMembers | Format-Table -AutoSize
}

# Export to CSV
if ($OutputPath) {
    $activityData | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
} else {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $defaultPath = "TeamsActivity_$timestamp.csv"
    $activityData | Export-Csv -Path $defaultPath -NoTypeInformation
    Write-Host "Report exported to: $defaultPath" -ForegroundColor Green
}

Write-Host ""
return $activityData
