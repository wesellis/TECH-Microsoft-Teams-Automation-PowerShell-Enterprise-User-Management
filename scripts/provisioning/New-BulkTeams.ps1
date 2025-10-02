<#
.SYNOPSIS
    Create multiple Microsoft Teams at once from a predefined list or CSV file.

.DESCRIPTION
    Automates the creation of multiple Teams with specified settings, owners, and members.
    Supports batch creation with error handling and logging.

.PARAMETER TeamsList
    Array of team objects with properties: DisplayName, Description, Visibility, Template

.PARAMETER CSVPath
    Path to CSV file containing team definitions

.PARAMETER AddOwners
    Array of email addresses to add as owners to all teams

.PARAMETER WaitBetweenCreation
    Seconds to wait between creating teams (default: 5)

.EXAMPLE
    .\New-BulkTeams.ps1 -CSVPath "C:\teams.csv" -AddOwners @("admin@contoso.com")

.EXAMPLE
    $teams = @(
        @{DisplayName="Sales Team"; Description="Sales Department"; Visibility="Private"},
        @{DisplayName="Marketing Team"; Description="Marketing Department"; Visibility="Public"}
    )
    .\New-BulkTeams.ps1 -TeamsList $teams

.NOTES
    Requires MicrosoftTeams module and Teams administrator permissions
    Author: Wesley Ellis
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(ParameterSetName='Array')]
    [array]$TeamsList,

    [Parameter(ParameterSetName='CSV')]
    [string]$CSVPath,

    [string[]]$AddOwners,

    [int]$WaitBetweenCreation = 5
)

# Import required module
if (!(Get-Module -ListAvailable -Name MicrosoftTeams)) {
    Write-Error "MicrosoftTeams module not installed. Run: Install-Module MicrosoftTeams"
    exit 1
}

Import-Module MicrosoftTeams

# Connect to Microsoft Teams
try {
    $connection = Get-CsOnlineSession -ErrorAction SilentlyContinue
    if (!$connection) {
        Write-Host "Connecting to Microsoft Teams..." -ForegroundColor Yellow
        Connect-MicrosoftTeams
    }
} catch {
    Write-Error "Failed to connect to Microsoft Teams: $_"
    exit 1
}

# Load teams from CSV if specified
if ($CSVPath) {
    if (!(Test-Path $CSVPath)) {
        Write-Error "CSV file not found: $CSVPath"
        exit 1
    }
    $TeamsList = Import-Csv $CSVPath
}

if (!$TeamsList -or $TeamsList.Count -eq 0) {
    Write-Error "No teams to create. Provide TeamsList or CSVPath parameter."
    exit 1
}

# Initialize results tracking
$results = @{
    Success = @()
    Failed = @()
    Total = $TeamsList.Count
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Bulk Teams Creation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total teams to create: $($TeamsList.Count)" -ForegroundColor Green
Write-Host ""

$counter = 0

foreach ($team in $TeamsList) {
    $counter++

    Write-Host "[$counter/$($TeamsList.Count)] Creating team: $($team.DisplayName)" -ForegroundColor Yellow

    try {
        # Validate required properties
        if ([string]::IsNullOrWhiteSpace($team.DisplayName)) {
            throw "DisplayName is required"
        }

        # Set default visibility if not specified
        $visibility = if ($team.Visibility) { $team.Visibility } else { "Private" }

        # Create team parameters
        $teamParams = @{
            DisplayName = $team.DisplayName
            Visibility = $visibility
        }

        if ($team.Description) {
            $teamParams.Description = $team.Description
        }

        if ($team.Template) {
            $teamParams.Template = $team.Template
        }

        # Create the team
        $newTeam = New-Team @teamParams

        Write-Host "  ✓ Team created successfully (ID: $($newTeam.GroupId))" -ForegroundColor Green

        # Add additional owners if specified
        if ($AddOwners -and $AddOwners.Count -gt 0) {
            foreach ($owner in $AddOwners) {
                try {
                    Add-TeamUser -GroupId $newTeam.GroupId -User $owner -Role Owner
                    Write-Host "  ✓ Added owner: $owner" -ForegroundColor Green
                } catch {
                    Write-Host "  ⚠ Failed to add owner $owner : $_" -ForegroundColor Yellow
                }
            }
        }

        # Add to success list
        $results.Success += @{
            Name = $team.DisplayName
            GroupId = $newTeam.GroupId
            CreatedAt = Get-Date
        }

    } catch {
        Write-Host "  ✗ Failed to create team: $_" -ForegroundColor Red

        $results.Failed += @{
            Name = $team.DisplayName
            Error = $_.Exception.Message
            Timestamp = Get-Date
        }
    }

    # Wait between creations to avoid throttling
    if ($counter -lt $TeamsList.Count) {
        Write-Host "  Waiting $WaitBetweenCreation seconds before next creation..." -ForegroundColor Gray
        Start-Sleep -Seconds $WaitBetweenCreation
    }

    Write-Host ""
}

# Display summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total teams: $($results.Total)" -ForegroundColor White
Write-Host "Successful: $($results.Success.Count)" -ForegroundColor Green
Write-Host "Failed: $($results.Failed.Count)" -ForegroundColor Red
Write-Host ""

# Show failed teams details
if ($results.Failed.Count -gt 0) {
    Write-Host "Failed Teams:" -ForegroundColor Red
    foreach ($failed in $results.Failed) {
        Write-Host "  - $($failed.Name): $($failed.Error)" -ForegroundColor Red
    }
    Write-Host ""
}

# Export results to log file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath = "BulkTeamsCreation_$timestamp.log"
$results | ConvertTo-Json -Depth 3 | Out-File $logPath
Write-Host "Detailed results saved to: $logPath" -ForegroundColor Cyan
Write-Host ""

# Return results object
return $results
