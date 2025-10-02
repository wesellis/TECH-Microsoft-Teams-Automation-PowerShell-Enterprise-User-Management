<#
.SYNOPSIS
    Import and create Microsoft Teams from CSV file with full configuration.

.DESCRIPTION
    Advanced CSV import supporting team settings, channels, members, and owners.
    CSV format: DisplayName,Description,Visibility,Owners,Members,Channels

.PARAMETER CSVPath
    Path to the CSV file containing team definitions

.PARAMETER CreateChannels
    Automatically create channels specified in CSV

.PARAMETER AddMembers
    Automatically add members specified in CSV

.EXAMPLE
    .\Import-TeamsFromCSV.ps1 -CSVPath ".\teams.csv" -CreateChannels -AddMembers

.NOTES
    CSV Format:
    DisplayName,Description,Visibility,Owners,Members,Channels
    "Sales Team","Sales Dept","Private","owner@contoso.com","member1@contoso.com;member2@contoso.com","General;Planning;Reports"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$CSVPath,

    [switch]$CreateChannels,

    [switch]$AddMembers
)

Import-Module MicrosoftTeams

# Ensure connection
try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Write-Host "Connecting to Microsoft Teams..." -ForegroundColor Yellow
    Connect-MicrosoftTeams
}

# Validate CSV
if (!(Test-Path $CSVPath)) {
    Write-Error "CSV file not found: $CSVPath"
    exit 1
}

$teams = Import-Csv $CSVPath

Write-Host "`n=== Importing Teams from CSV ===" -ForegroundColor Cyan
Write-Host "Source: $CSVPath" -ForegroundColor White
Write-Host "Teams to import: $($teams.Count)`n" -ForegroundColor Green

foreach ($teamData in $teams) {
    Write-Host "Processing: $($teamData.DisplayName)" -ForegroundColor Yellow

    try {
        # Create team
        $teamParams = @{
            DisplayName = $teamData.DisplayName
            Visibility = if ($teamData.Visibility) { $teamData.Visibility } else { "Private" }
        }

        if ($teamData.Description) {
            $teamParams.Description = $teamData.Description
        }

        $team = New-Team @teamParams
        Write-Host "  ✓ Team created (ID: $($team.GroupId))" -ForegroundColor Green

        # Add owners
        if ($teamData.Owners -and $AddMembers) {
            $owners = $teamData.Owners -split ';'
            foreach ($owner in $owners) {
                $owner = $owner.Trim()
                if ($owner) {
                    Add-TeamUser -GroupId $team.GroupId -User $owner -Role Owner
                    Write-Host "  ✓ Added owner: $owner" -ForegroundColor Green
                }
            }
        }

        # Add members
        if ($teamData.Members -and $AddMembers) {
            $members = $teamData.Members -split ';'
            foreach ($member in $members) {
                $member = $member.Trim()
                if ($member) {
                    Add-TeamUser -GroupId $team.GroupId -User $member -Role Member
                    Write-Host "  ✓ Added member: $member" -ForegroundColor Green
                }
            }
        }

        # Create channels
        if ($teamData.Channels -and $CreateChannels) {
            $channels = $teamData.Channels -split ';'
            foreach ($channel in $channels) {
                $channel = $channel.Trim()
                if ($channel -and $channel -ne "General") {
                    New-TeamChannel -GroupId $team.GroupId -DisplayName $channel
                    Write-Host "  ✓ Created channel: $channel" -ForegroundColor Green
                }
            }
        }

        Write-Host "  ✓ Team configuration complete`n" -ForegroundColor Green

    } catch {
        Write-Host "  ✗ Error: $_`n" -ForegroundColor Red
    }
}

Write-Host "Import complete!" -ForegroundColor Cyan
