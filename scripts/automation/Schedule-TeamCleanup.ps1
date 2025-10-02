<#
.SYNOPSIS
    Schedule automated Teams cleanup tasks.

.DESCRIPTION
    Creates scheduled tasks for routine Teams maintenance operations.

.PARAMETER TaskName
    Name for the scheduled task

.PARAMETER ScriptPath
    Path to the cleanup script to run

.PARAMETER Schedule
    Schedule type: Daily, Weekly, Monthly

.PARAMETER Time
    Time to run (24-hour format, e.g., "02:00")

.EXAMPLE
    .\Schedule-TeamCleanup.ps1 -TaskName "Archive Old Teams" -ScriptPath ".\Archive-OldTeams.ps1" -Schedule Daily -Time "02:00"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$TaskName,

    [Parameter(Mandatory=$true)]
    [string]$ScriptPath,

    [ValidateSet("Daily", "Weekly", "Monthly")]
    [string]$Schedule = "Daily",

    [string]$Time = "02:00"
)

Write-Host "`n=== Schedule Teams Cleanup Task ===" -ForegroundColor Cyan

$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

$trigger = switch ($Schedule) {
    "Daily" { New-ScheduledTaskTrigger -Daily -At $Time }
    "Weekly" { New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At $Time }
    "Monthly" { New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek Monday -At $Time }
}

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Description "Automated Teams cleanup task"

Write-Host "✓ Scheduled task created: $TaskName" -ForegroundColor Green
Write-Host "  Schedule: $Schedule at $Time" -ForegroundColor White
Write-Host "  Script: $ScriptPath`n" -ForegroundColor White
