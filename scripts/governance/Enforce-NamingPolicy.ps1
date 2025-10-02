<#
.SYNOPSIS
    Enforce naming conventions and policies for Microsoft Teams.

.DESCRIPTION
    Validates and corrects team names based on organizational naming standards.
    Supports prefixes, suffixes, and pattern matching.

.PARAMETER NamingPrefix
    Required prefix for team names (e.g., "DEPT-")

.PARAMETER NamingSuffix
    Required suffix for team names (e.g., "-TEAM")

.PARAMETER AllowedPattern
    Regex pattern team names must match

.PARAMETER FixNonCompliant
    Automatically rename non-compliant teams

.PARAMETER ExcludeTeamIds
    Teams to exclude from policy enforcement

.EXAMPLE
    .\Enforce-NamingPolicy.ps1 -NamingPrefix "DEPT-" -FixNonCompliant

.EXAMPLE
    .\Enforce-NamingPolicy.ps1 -AllowedPattern "^[A-Z]{2,4}-.*" -NamingSuffix "-2024"

.NOTES
    Helps maintain consistency and organization
    Supports department-based prefixes and date-based suffixes
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$NamingPrefix,

    [string]$NamingSuffix,

    [string]$AllowedPattern,

    [switch]$FixNonCompliant,

    [string[]]$ExcludeTeamIds,

    [string]$OutputPath,

    [switch]$ForceRename
)

Import-Module MicrosoftTeams

# Ensure connection
try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== Team Naming Policy Enforcement ===" -ForegroundColor Cyan

# Display policy rules
Write-Host "Policy Rules:" -ForegroundColor White
if ($NamingPrefix) { Write-Host "  Prefix: $NamingPrefix" -ForegroundColor Yellow }
if ($NamingSuffix) { Write-Host "  Suffix: $NamingSuffix" -ForegroundColor Yellow }
if ($AllowedPattern) { Write-Host "  Pattern: $AllowedPattern" -ForegroundColor Yellow }
Write-Host ""

$compliantTeams = @()
$nonCompliantTeams = @()
$renamedTeams = @()

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

    $isCompliant = $true
    $issues = @()
    $suggestedName = $team.DisplayName

    # Check prefix
    if ($NamingPrefix -and !$team.DisplayName.StartsWith($NamingPrefix)) {
        $isCompliant = $false
        $issues += "Missing prefix: $NamingPrefix"
        $suggestedName = "$NamingPrefix$suggestedName"
    }

    # Check suffix
    if ($NamingSuffix -and !$team.DisplayName.EndsWith($NamingSuffix)) {
        $isCompliant = $false
        $issues += "Missing suffix: $NamingSuffix"
        $suggestedName = "$suggestedName$NamingSuffix"
    }

    # Check pattern
    if ($AllowedPattern -and $team.DisplayName -notmatch $AllowedPattern) {
        $isCompliant = $false
        $issues += "Does not match required pattern"
    }

    $teamInfo = [PSCustomObject]@{
        TeamName = $team.DisplayName
        TeamId = $team.GroupId
        IsCompliant = $isCompliant
        Issues = ($issues -join "; ")
        SuggestedName = $suggestedName
        ActionTaken = ""
    }

    if ($isCompliant) {
        $compliantTeams += $teamInfo
        Write-Host "  ✓ Compliant" -ForegroundColor Green
    }
    else {
        $nonCompliantTeams += $teamInfo
        Write-Host "  ✗ Non-compliant: $($issues -join ', ')" -ForegroundColor Red
        Write-Host "    Suggested name: $suggestedName" -ForegroundColor Cyan

        # Fix if requested
        if ($FixNonCompliant) {
            if (!$ForceRename) {
                $confirm = Read-Host "    Rename to '$suggestedName'? (yes/no)"
                $shouldRename = $confirm -eq "yes"
            } else {
                $shouldRename = $true
            }

            if ($shouldRename -and !$WhatIfPreference) {
                try {
                    Set-Team -GroupId $team.GroupId -DisplayName $suggestedName
                    Write-Host "    ✓ Team renamed to: $suggestedName" -ForegroundColor Green
                    $teamInfo.ActionTaken = "Renamed"
                    $renamedTeams += $teamInfo
                } catch {
                    Write-Host "    ✗ Failed to rename: $_" -ForegroundColor Red
                    $teamInfo.ActionTaken = "Rename failed: $_"
                }
            }
            else {
                $teamInfo.ActionTaken = "User declined rename"
            }
        }
    }

    Write-Host ""
}

# Combine all results
$allResults = $compliantTeams + $nonCompliantTeams

# Display summary
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total Teams: $($teams.Count)" -ForegroundColor White
Write-Host "Compliant: $($compliantTeams.Count)" -ForegroundColor Green
Write-Host "Non-Compliant: $($nonCompliantTeams.Count)" -ForegroundColor Red
if ($FixNonCompliant) {
    Write-Host "Renamed: $($renamedTeams.Count)" -ForegroundColor Yellow
}
Write-Host ""

# Show non-compliant teams
if ($nonCompliantTeams.Count -gt 0) {
    Write-Host "Non-Compliant Teams:" -ForegroundColor Red
    $nonCompliantTeams | Select-Object TeamName, Issues, SuggestedName, ActionTaken | Format-Table -AutoSize
    Write-Host ""
}

# Export results
if ($OutputPath) {
    $allResults | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
} else {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $defaultPath = "NamingPolicyReport_$timestamp.csv"
    $allResults | Export-Csv -Path $defaultPath -NoTypeInformation
    Write-Host "Report exported to: $defaultPath" -ForegroundColor Green
}

# Recommendations
if ($nonCompliantTeams.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Cyan
    Write-Host "1. Review and rename non-compliant teams" -ForegroundColor White
    Write-Host "2. Run with -FixNonCompliant to automatically rename teams" -ForegroundColor White
    Write-Host "3. Implement Azure AD naming policy to prevent future violations" -ForegroundColor White
    Write-Host "4. Educate team creators on naming standards" -ForegroundColor White
}

Write-Host ""
return $allResults
