<#
.SYNOPSIS
    Apply Teams policies to multiple users based on criteria.

.DESCRIPTION
    Bulk assignment of messaging, meeting, and calling policies to users.
    Supports department-based, group-based, or direct user list assignments.

.PARAMETER Users
    Array of user email addresses

.PARAMETER Department
    Target users by department

.PARAMETER MessagingPolicy
    Messaging policy to apply

.PARAMETER MeetingPolicy
    Meeting policy to apply

.PARAMETER CallingPolicy
    Calling policy to apply

.EXAMPLE
    .\Set-UserPolicies.ps1 -Department "Engineering" -MessagingPolicy "EngineeringMessaging"

.EXAMPLE
    .\Set-UserPolicies.ps1 -Users @("user1@contoso.com", "user2@contoso.com") -MeetingPolicy "SecureMeetings"

.NOTES
    Requires Teams administrator permissions
#>

[CmdletBinding(DefaultParameterSetName='Users')]
param(
    [Parameter(ParameterSetName='Users', Mandatory=$true)]
    [string[]]$Users,

    [Parameter(ParameterSetName='Department', Mandatory=$true)]
    [string]$Department,

    [string]$MessagingPolicy,

    [string]$MeetingPolicy,

    [string]$CallingPolicy,

    [string]$AppPermissionPolicy,

    [string]$AppSetupPolicy
)

Import-Module MicrosoftTeams

# Ensure connection
try {
    Get-CsOnlineUser -ResultSize 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== User Policy Assignment ===" -ForegroundColor Cyan

# Get target users
if ($Department) {
    Write-Host "Getting users from department: $Department" -ForegroundColor Yellow
    $targetUsers = Get-CsOnlineUser -Filter "Department -eq '$Department'" | Select-Object -ExpandProperty UserPrincipalName
} else {
    $targetUsers = $Users
}

Write-Host "Target users: $($targetUsers.Count)`n" -ForegroundColor Green

$results = @{
    Success = 0
    Failed = 0
}

foreach ($user in $targetUsers) {
    Write-Host "Processing: $user" -ForegroundColor Yellow
    $hasError = $false

    try {
        # Apply messaging policy
        if ($MessagingPolicy) {
            Grant-CsTeamsMessagingPolicy -Identity $user -PolicyName $MessagingPolicy
            Write-Host "  ✓ Messaging policy applied: $MessagingPolicy" -ForegroundColor Green
        }

        # Apply meeting policy
        if ($MeetingPolicy) {
            Grant-CsTeamsMeetingPolicy -Identity $user -PolicyName $MeetingPolicy
            Write-Host "  ✓ Meeting policy applied: $MeetingPolicy" -ForegroundColor Green
        }

        # Apply calling policy
        if ($CallingPolicy) {
            Grant-CsTeamsCallingPolicy -Identity $user -PolicyName $CallingPolicy
            Write-Host "  ✓ Calling policy applied: $CallingPolicy" -ForegroundColor Green
        }

        # Apply app permission policy
        if ($AppPermissionPolicy) {
            Grant-CsTeamsAppPermissionPolicy -Identity $user -PolicyName $AppPermissionPolicy
            Write-Host "  ✓ App permission policy applied: $AppPermissionPolicy" -ForegroundColor Green
        }

        # Apply app setup policy
        if ($AppSetupPolicy) {
            Grant-CsTeamsAppSetupPolicy -Identity $user -PolicyName $AppSetupPolicy
            Write-Host "  ✓ App setup policy applied: $AppSetupPolicy" -ForegroundColor Green
        }

        $results.Success++

    } catch {
        Write-Host "  ✗ Error: $_" -ForegroundColor Red
        $results.Failed++
    }

    Write-Host ""
}

# Summary
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Successful: $($results.Success)" -ForegroundColor Green
Write-Host "Failed: $($results.Failed)" -ForegroundColor $(if ($results.Failed -gt 0) { "Red" } else { "Green" })
Write-Host ""

return $results
