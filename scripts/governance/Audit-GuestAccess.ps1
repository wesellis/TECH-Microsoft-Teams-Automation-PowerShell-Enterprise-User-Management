<#
.SYNOPSIS
    Audit external guest user access across Microsoft Teams.

.DESCRIPTION
    Comprehensive audit of guest users, their access levels, and activity.
    Identifies security risks and compliance issues with external access.

.PARAMETER OutputPath
    Path for CSV export

.PARAMETER IncludeInactiveGuests
    Include guests who haven't been active recently

.PARAMETER InactiveDays
    Days of inactivity to flag guests (default: 90)

.PARAMETER RemoveInactiveGuests
    Automatically remove inactive guest users

.EXAMPLE
    .\Audit-GuestAccess.ps1 -OutputPath ".\guest_audit.csv"

.EXAMPLE
    .\Audit-GuestAccess.ps1 -IncludeInactiveGuests -InactiveDays 60 -RemoveInactiveGuests

.NOTES
    Critical for security and compliance
    Helps manage external collaboration risks
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$OutputPath,

    [switch]$IncludeInactiveGuests,

    [int]$InactiveDays = 90,

    [switch]$RemoveInactiveGuests,

    [switch]$DetailedReport
)

Import-Module MicrosoftTeams

# Ensure connection
try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== Guest Access Audit ===" -ForegroundColor Cyan
Write-Host "Scanning all teams for external guest users...`n" -ForegroundColor White

$guestData = @()
$teams = Get-Team
$totalGuests = 0
$inactiveGuests = 0
$cutoffDate = (Get-Date).AddDays(-$InactiveDays)

$counter = 0

foreach ($team in $teams) {
    $counter++
    Write-Host "[$counter/$($teams.Count)] Scanning: $($team.DisplayName)" -ForegroundColor Yellow

    try {
        $members = Get-TeamUser -GroupId $team.GroupId
        $guests = $members | Where-Object {$_.User -like "*#EXT#*"}

        if ($guests.Count -gt 0) {
            Write-Host "  Found $($guests.Count) guest(s)" -ForegroundColor Cyan

            foreach ($guest in $guests) {
                $totalGuests++

                try {
                    # Get guest user details
                    $guestUser = Get-CsOnlineUser -Identity $guest.User -ErrorAction SilentlyContinue

                    $guestInfo = [PSCustomObject]@{
                        GuestEmail = $guest.User
                        DisplayName = if ($guestUser) { $guestUser.DisplayName } else { "Unknown" }
                        TeamName = $team.DisplayName
                        TeamId = $team.GroupId
                        Role = $guest.Role
                        Domain = if ($guest.User -match "@(.+)#EXT#") { $matches[1] } else { "Unknown" }
                        WhenCreated = if ($guestUser) { $guestUser.WhenCreated } else { $null }
                        LastActivity = if ($guestUser) { $guestUser.WhenChanged } else { $null }
                        DaysInactive = if ($guestUser.WhenChanged) {
                            ((Get-Date) - $guestUser.WhenChanged).Days
                        } else { "N/A" }
                        Status = ""
                        Risk = ""
                    }

                    # Assess activity status
                    if ($guestInfo.LastActivity -and $guestInfo.LastActivity -lt $cutoffDate) {
                        $guestInfo.Status = "Inactive"
                        $guestInfo.Risk = "High"
                        $inactiveGuests++
                        Write-Host "    ⚠ Inactive guest: $($guest.User) (Last active: $($guestInfo.LastActivity))" -ForegroundColor Yellow
                    }
                    elseif ($guestInfo.Role -eq "Owner") {
                        $guestInfo.Status = "Active"
                        $guestInfo.Risk = "Medium"
                        Write-Host "    ⚠ Guest has Owner role: $($guest.User)" -ForegroundColor Yellow
                    }
                    else {
                        $guestInfo.Status = "Active"
                        $guestInfo.Risk = "Low"
                        Write-Host "    ✓ Active guest: $($guest.User)" -ForegroundColor Green
                    }

                    # Add detailed info if requested
                    if ($DetailedReport -and $guestUser) {
                        $guestInfo | Add-Member -NotePropertyName Department -NotePropertyValue $guestUser.Department
                        $guestInfo | Add-Member -NotePropertyName Title -NotePropertyValue $guestUser.Title
                        $guestInfo | Add-Member -NotePropertyName CompanyName -NotePropertyValue $guestUser.CompanyName
                    }

                    $guestData += $guestInfo

                    # Remove inactive guests if requested
                    if ($RemoveInactiveGuests -and $guestInfo.Status -eq "Inactive" -and !$WhatIfPreference) {
                        try {
                            Remove-TeamUser -GroupId $team.GroupId -User $guest.User
                            Write-Host "    ✓ Removed inactive guest: $($guest.User)" -ForegroundColor Green
                            $guestInfo | Add-Member -NotePropertyName ActionTaken -NotePropertyValue "Removed"
                        } catch {
                            Write-Host "    ✗ Failed to remove guest: $_" -ForegroundColor Red
                            $guestInfo | Add-Member -NotePropertyName ActionTaken -NotePropertyValue "Removal failed"
                        }
                    }

                } catch {
                    Write-Host "    ⚠ Could not get details for $($guest.User): $_" -ForegroundColor Gray
                }
            }
        }

    } catch {
        Write-Host "  ✗ Error scanning team: $_" -ForegroundColor Red
    }

    Write-Host ""
}

# Display summary
Write-Host "=== Audit Summary ===" -ForegroundColor Cyan
Write-Host "Total Teams Scanned: $($teams.Count)" -ForegroundColor White
Write-Host "Total Guest Users: $totalGuests" -ForegroundColor White
Write-Host "Inactive Guests: $inactiveGuests" -ForegroundColor Yellow
Write-Host ""

# Guest statistics
if ($guestData.Count -gt 0) {
    Write-Host "Guest Access by Domain:" -ForegroundColor Cyan
    $guestData | Group-Object Domain |
        Select-Object Name, Count |
        Sort-Object Count -Descending |
        Format-Table -AutoSize

    Write-Host "Guest Access by Risk Level:" -ForegroundColor Cyan
    $guestData | Group-Object Risk |
        Select-Object Name, Count |
        Format-Table -AutoSize

    Write-Host "Teams with Most Guests:" -ForegroundColor Cyan
    $guestData | Group-Object TeamName |
        Select-Object Name, Count |
        Sort-Object Count -Descending |
        Select-Object -First 10 |
        Format-Table -AutoSize

    # High-risk guests
    $highRiskGuests = $guestData | Where-Object {$_.Risk -eq "High" -or $_.Risk -eq "Medium"}
    if ($highRiskGuests.Count -gt 0) {
        Write-Host "⚠ High-Risk Guests ($($highRiskGuests.Count)):" -ForegroundColor Yellow
        $highRiskGuests | Select-Object GuestEmail, TeamName, Role, Status, DaysInactive | Format-Table -AutoSize
    }
}

# Export results
if ($OutputPath) {
    $guestData | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host "Full audit report exported to: $OutputPath" -ForegroundColor Green
} else {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $defaultPath = "GuestAudit_$timestamp.csv"
    $guestData | Export-Csv -Path $defaultPath -NoTypeInformation
    Write-Host "Full audit report exported to: $defaultPath" -ForegroundColor Green
}

# Recommendations
if ($inactiveGuests -gt 0 -or $highRiskGuests.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Cyan
    Write-Host "1. Review and remove inactive guest accounts" -ForegroundColor White
    Write-Host "2. Verify guest owner permissions are appropriate" -ForegroundColor White
    Write-Host "3. Implement guest access policies and expiration" -ForegroundColor White
    Write-Host "4. Regular guest access audits (monthly recommended)" -ForegroundColor White
}

Write-Host ""
return $guestData
