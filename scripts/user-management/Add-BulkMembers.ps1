<#
.SYNOPSIS
    Add users to multiple Teams in bulk from CSV or array.

.DESCRIPTION
    Efficiently adds users to one or more Teams with role assignment.
    Supports CSV input or PowerShell arrays.

.PARAMETER CSVPath
    Path to CSV file with columns: TeamId, User, Role

.PARAMETER TeamId
    Single team GroupId to add users to

.PARAMETER Users
    Array of user email addresses

.PARAMETER Role
    Role to assign: Member or Owner (default: Member)

.EXAMPLE
    .\Add-BulkMembers.ps1 -TeamId "abc-123" -Users @("user1@contoso.com", "user2@contoso.com")

.EXAMPLE
    .\Add-BulkMembers.ps1 -CSVPath ".\users.csv"

.NOTES
    CSV Format: TeamId,User,Role
    Handles rate limiting and error recovery
#>

[CmdletBinding(DefaultParameterSetName='SingleTeam')]
param(
    [Parameter(ParameterSetName='CSV', Mandatory=$true)]
    [string]$CSVPath,

    [Parameter(ParameterSetName='SingleTeam', Mandatory=$true)]
    [string]$TeamId,

    [Parameter(ParameterSetName='SingleTeam', Mandatory=$true)]
    [string[]]$Users,

    [Parameter(ParameterSetName='SingleTeam')]
    [ValidateSet("Member", "Owner")]
    [string]$Role = "Member",

    [int]$ThrottleDelay = 1
)

Import-Module MicrosoftTeams

# Ensure connection
try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== Bulk Member Addition ===" -ForegroundColor Cyan

$results = @{
    Success = 0
    Failed = 0
    Errors = @()
}

# Handle CSV input
if ($CSVPath) {
    if (!(Test-Path $CSVPath)) {
        Write-Error "CSV file not found: $CSVPath"
        exit 1
    }

    $operations = Import-Csv $CSVPath
    Write-Host "Loading from CSV: $($operations.Count) operations`n" -ForegroundColor White

    foreach ($op in $operations) {
        try {
            Add-TeamUser -GroupId $op.TeamId -User $op.User -Role $op.Role
            Write-Host "✓ Added $($op.User) to team $($op.TeamId) as $($op.Role)" -ForegroundColor Green
            $results.Success++
        } catch {
            Write-Host "✗ Failed to add $($op.User): $_" -ForegroundColor Red
            $results.Failed++
            $results.Errors += "User: $($op.User), Team: $($op.TeamId), Error: $_"
        }

        Start-Sleep -Seconds $ThrottleDelay
    }
}
# Handle single team input
else {
    Write-Host "Team ID: $TeamId" -ForegroundColor White
    Write-Host "Users to add: $($Users.Count)" -ForegroundColor White
    Write-Host "Role: $Role`n" -ForegroundColor White

    $counter = 0
    foreach ($user in $Users) {
        $counter++
        try {
            Add-TeamUser -GroupId $TeamId -User $user -Role $Role
            Write-Host "[$counter/$($Users.Count)] ✓ Added: $user" -ForegroundColor Green
            $results.Success++
        } catch {
            Write-Host "[$counter/$($Users.Count)] ✗ Failed: $user - $_" -ForegroundColor Red
            $results.Failed++
            $results.Errors += "User: $user, Error: $_"
        }

        if ($counter % 10 -eq 0) {
            Start-Sleep -Seconds $ThrottleDelay
        }
    }
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Successful: $($results.Success)" -ForegroundColor Green
Write-Host "Failed: $($results.Failed)" -ForegroundColor $(if ($results.Failed -gt 0) { "Red" } else { "Green" })

if ($results.Errors.Count -gt 0) {
    Write-Host "`nErrors:" -ForegroundColor Red
    $results.Errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}

Write-Host ""
return $results
