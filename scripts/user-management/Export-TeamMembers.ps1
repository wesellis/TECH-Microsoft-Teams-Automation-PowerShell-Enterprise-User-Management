<#
.SYNOPSIS
    Export Teams membership to CSV reports.

.DESCRIPTION
    Generates detailed membership reports for one or all teams.
    Includes user details, roles, and activity information.

.PARAMETER TeamId
    Specific team to export (optional - exports all teams if omitted)

.PARAMETER OutputPath
    Path for CSV export (default: TeamMembers_TIMESTAMP.csv)

.PARAMETER IncludeUserDetails
    Include additional user details (department, title, etc.)

.EXAMPLE
    .\Export-TeamMembers.ps1 -TeamId "abc-123"

.EXAMPLE
    .\Export-TeamMembers.ps1 -IncludeUserDetails -OutputPath "C:\Reports\members.csv"

.NOTES
    Exports in CSV format compatible with Import-TeamsFromCSV.ps1
#>

[CmdletBinding()]
param(
    [string]$TeamId,

    [string]$OutputPath,

    [switch]$IncludeUserDetails,

    [switch]$GroupByTeam
)

Import-Module MicrosoftTeams

# Ensure connection
try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== Exporting Team Memberships ===" -ForegroundColor Cyan

# Determine output path
if (!$OutputPath) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputPath = "TeamMembers_$timestamp.csv"
}

$memberData = @()

# Get teams
if ($TeamId) {
    $teams = @(Get-Team -GroupId $TeamId)
    Write-Host "Exporting single team: $($teams[0].DisplayName)`n" -ForegroundColor White
} else {
    $teams = Get-Team
    Write-Host "Exporting all teams: $($teams.Count)`n" -ForegroundColor White
}

$counter = 0

foreach ($team in $teams) {
    $counter++
    Write-Host "[$counter/$($teams.Count)] Processing: $($team.DisplayName)" -ForegroundColor Yellow

    try {
        $members = Get-TeamUser -GroupId $team.GroupId

        foreach ($member in $members) {
            $record = [PSCustomObject]@{
                TeamName = $team.DisplayName
                TeamId = $team.GroupId
                TeamDescription = $team.Description
                TeamVisibility = $team.Visibility
                User = $member.User
                Role = $member.Role
                UserId = $member.UserId
            }

            # Add user details if requested
            if ($IncludeUserDetails) {
                try {
                    $userDetails = Get-CsOnlineUser -Identity $member.User
                    $record | Add-Member -NotePropertyName DisplayName -NotePropertyValue $userDetails.DisplayName
                    $record | Add-Member -NotePropertyName Department -NotePropertyValue $userDetails.Department
                    $record | Add-Member -NotePropertyName Title -NotePropertyValue $userDetails.Title
                    $record | Add-Member -NotePropertyName Office -NotePropertyValue $userDetails.Office
                    $record | Add-Member -NotePropertyName WhenCreated -NotePropertyValue $userDetails.WhenCreated
                } catch {
                    Write-Host "  ⚠ Could not get details for $($member.User)" -ForegroundColor Gray
                }
            }

            $memberData += $record
        }

        Write-Host "  ✓ Exported $($members.Count) members" -ForegroundColor Green

    } catch {
        Write-Host "  ✗ Error: $_" -ForegroundColor Red
    }
}

# Export to CSV
$memberData | Export-Csv -Path $OutputPath -NoTypeInformation

Write-Host "`n=== Export Complete ===" -ForegroundColor Cyan
Write-Host "Total records: $($memberData.Count)" -ForegroundColor Green
Write-Host "Output file: $OutputPath`n" -ForegroundColor Green

# Display summary
Write-Host "Summary by Role:" -ForegroundColor Cyan
$memberData | Group-Object Role | Select-Object Name, Count | Format-Table -AutoSize

if (!$TeamId) {
    Write-Host "Summary by Team:" -ForegroundColor Cyan
    $memberData | Group-Object TeamName | Select-Object Name, Count | Sort-Object Count -Descending | Select-Object -First 10 | Format-Table -AutoSize
}

# Open file location
$OutputPath = Resolve-Path $OutputPath
Write-Host "File saved to: $OutputPath" -ForegroundColor Cyan

return $memberData
