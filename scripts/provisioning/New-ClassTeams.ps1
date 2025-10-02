<#
.SYNOPSIS
    Create Microsoft Teams for educational classes using EDU template.

.DESCRIPTION
    Automated creation of class teams with education-specific channels and settings.
    Optimized for K-12 and higher education environments.

.PARAMETER ClassName
    Name of the class (e.g., "Math 101", "Biology 201")

.PARAMETER Teacher
    Email address of the primary teacher (will be owner)

.PARAMETER Students
    Array of student email addresses

.PARAMETER Semester
    Semester identifier (e.g., "Fall 2024", "Spring 2025")

.EXAMPLE
    .\New-ClassTeams.ps1 -ClassName "Math 101" -Teacher "teacher@school.edu" -Students $studentList -Semester "Fall 2024"

.NOTES
    Uses Education template with standard channels:
    - General, Announcements, Assignments, Resources, Office Hours
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ClassName,

    [Parameter(Mandatory=$true)]
    [string]$Teacher,

    [string[]]$Students,

    [string]$Semester,

    [string]$CourseCode,

    [switch]$IncludeBreakoutRooms
)

Import-Module MicrosoftTeams

# Ensure connection
try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== Creating Class Team ===" -ForegroundColor Cyan
Write-Host "Class: $ClassName" -ForegroundColor White
Write-Host "Teacher: $Teacher" -ForegroundColor White

if ($Semester) {
    Write-Host "Semester: $Semester" -ForegroundColor White
}
Write-Host ""

try {
    # Build team name and description
    $teamName = if ($Semester) { "$ClassName - $Semester" } else { $ClassName }
    $description = "Class team for $ClassName"
    if ($CourseCode) {
        $description += " ($CourseCode)"
    }

    # Create class team with EDU template
    $teamParams = @{
        DisplayName = $teamName
        Description = $description
        Visibility = "Private"
        Template = "EDU_Class"  # Education template
    }

    $team = New-Team @teamParams
    Write-Host "✓ Class team created: $teamName" -ForegroundColor Green
    Write-Host "  ID: $($team.GroupId)" -ForegroundColor Gray

    # Add teacher as owner
    Add-TeamUser -GroupId $team.GroupId -User $Teacher -Role Owner
    Write-Host "✓ Added teacher as owner: $Teacher" -ForegroundColor Green

    # Add students as members
    if ($Students -and $Students.Count -gt 0) {
        Write-Host "`nAdding students..." -ForegroundColor Yellow
        $successCount = 0

        foreach ($student in $Students) {
            try {
                Add-TeamUser -GroupId $team.GroupId -User $student -Role Member
                $successCount++

                if ($successCount % 10 -eq 0) {
                    Write-Host "  Added $successCount students..." -ForegroundColor Gray
                }
            } catch {
                Write-Host "  ⚠ Failed to add $student : $_" -ForegroundColor Yellow
            }
        }

        Write-Host "✓ Added $successCount/$($Students.Count) students" -ForegroundColor Green
    }

    # Create education-specific channels
    Write-Host "`nCreating channels..." -ForegroundColor Yellow

    $channels = @(
        @{Name="Announcements"; Description="Class announcements and updates"},
        @{Name="Assignments"; Description="Homework and assignments"},
        @{Name="Resources"; Description="Course materials and resources"},
        @{Name="Office Hours"; Description="Virtual office hours and Q&A"},
        @{Name="Study Group"; Description="Student collaboration space"}
    )

    if ($IncludeBreakoutRooms) {
        $channels += @(
            @{Name="Breakout Room 1"; Description="Small group discussions"},
            @{Name="Breakout Room 2"; Description="Small group discussions"},
            @{Name="Breakout Room 3"; Description="Small group discussions"}
        )
    }

    foreach ($channel in $channels) {
        try {
            New-TeamChannel -GroupId $team.GroupId `
                           -DisplayName $channel.Name `
                           -Description $channel.Description
            Write-Host "  ✓ Created channel: $($channel.Name)" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠ Failed to create channel $($channel.Name): $_" -ForegroundColor Yellow
        }
    }

    # Configure class team settings
    Set-Team -GroupId $team.GroupId `
             -AllowGiphy $false `
             -AllowStickersAndMemes $false `
             -AllowCustomMemes $false `
             -AllowUserEditMessages $true `
             -AllowUserDeleteMessages $false `
             -AllowOwnerDeleteMessages $true `
             -AllowTeamMentions $true `
             -AllowChannelMentions $true

    Write-Host "`n✓ Class team setup complete!" -ForegroundColor Green
    Write-Host "`nClass Team Details:" -ForegroundColor Cyan
    Write-Host "  Name: $teamName" -ForegroundColor White
    Write-Host "  Team ID: $($team.GroupId)" -ForegroundColor White
    Write-Host "  Teacher: $Teacher" -ForegroundColor White

    if ($Students) {
        Write-Host "  Students: $($Students.Count)" -ForegroundColor White
    }

    Write-Host "  Channels: $($channels.Count + 1)" -ForegroundColor White
    Write-Host ""

    return $team

} catch {
    Write-Error "Failed to create class team: $_"
    exit 1
}
