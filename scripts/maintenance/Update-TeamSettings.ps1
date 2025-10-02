<#
.SYNOPSIS
    Bulk update Microsoft Teams settings.

.DESCRIPTION
    Apply consistent settings across multiple teams for governance and standardization.

.PARAMETER TeamIds
    Array of team IDs to update

.PARAMETER AllTeams
    Update all teams in the organization

.PARAMETER Settings
    Hashtable of settings to apply

.EXAMPLE
    .\Update-TeamSettings.ps1 -AllTeams -Settings @{AllowGiphy=$false; AllowCustomMemes=$false}

.EXAMPLE
    $settings = @{
        AllowUserEditMessages = $true
        AllowUserDeleteMessages = $false
        AllowTeamMentions = $true
    }
    .\Update-TeamSettings.ps1 -TeamIds @("abc-123", "xyz-789") -Settings $settings
#>

[CmdletBinding()]
param(
    [string[]]$TeamIds,
    [switch]$AllTeams,
    [hashtable]$Settings
)

Import-Module MicrosoftTeams

try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== Bulk Team Settings Update ===" -ForegroundColor Cyan

if (!$Settings -or $Settings.Count -eq 0) {
    Write-Error "No settings specified. Use -Settings parameter with hashtable."
    exit 1
}

Write-Host "Settings to apply:" -ForegroundColor Yellow
$Settings.GetEnumerator() | ForEach-Object { Write-Host "  $($_.Key) = $($_.Value)" -ForegroundColor White }
Write-Host ""

$teams = if ($AllTeams) { Get-Team } else { $TeamIds | ForEach-Object { Get-Team -GroupId $_ } }

Write-Host "Updating $($teams.Count) teams...`n" -ForegroundColor Green

$results = @{Success=0; Failed=0}

foreach ($team in $teams) {
    Write-Host "Updating: $($team.DisplayName)" -ForegroundColor Yellow
    try {
        $params = @{GroupId = $team.GroupId}
        $Settings.GetEnumerator() | ForEach-Object { $params[$_.Key] = $_.Value }
        Set-Team @params
        Write-Host "  ✓ Updated" -ForegroundColor Green
        $results.Success++
    } catch {
        Write-Host "  ✗ Failed: $_" -ForegroundColor Red
        $results.Failed++
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Success: $($results.Success)" -ForegroundColor Green
Write-Host "Failed: $($results.Failed)" -ForegroundColor $(if ($results.Failed -gt 0) {"Red"} else {"Green"})
Write-Host ""

return $results
