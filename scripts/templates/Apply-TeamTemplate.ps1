<#
.SYNOPSIS
    Apply predefined template to Microsoft Team.

.DESCRIPTION
    Applies settings, channels, and configuration from JSON template file to teams.

.PARAMETER TeamId
    Team to apply template to

.PARAMETER TemplateName
    Name of template to apply (standard, project, executive, education)

.PARAMETER TemplateFile
    Path to custom template JSON file

.EXAMPLE
    .\Apply-TeamTemplate.ps1 -TeamId "abc-123" -TemplateName "project"

.EXAMPLE
    .\Apply-TeamTemplate.ps1 -TeamId "xyz-789" -TemplateFile ".\custom-template.json"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$TeamId,

    [string]$TemplateName,

    [string]$TemplateFile
)

Import-Module MicrosoftTeams

try {
    Get-Team -NumberOfTeams 1 -ErrorAction Stop | Out-Null
} catch {
    Connect-MicrosoftTeams
}

Write-Host "`n=== Apply Team Template ===" -ForegroundColor Cyan

# Load template
if ($TemplateFile) {
    $templates = Get-Content $TemplateFile | ConvertFrom-Json
} else {
    $defaultTemplateFile = Join-Path $PSScriptRoot "TeamTemplate.json"
    if (!(Test-Path $defaultTemplateFile)) {
        Write-Error "Template file not found: $defaultTemplateFile"
        exit 1
    }
    $templates = Get-Content $defaultTemplateFile | ConvertFrom-Json
}

# Get template
$template = if ($TemplateName) {
    $templates.templates.$TemplateName
} else {
    $templates.templates.standard
}

if (!$template) {
    Write-Error "Template not found: $TemplateName"
    exit 1
}

Write-Host "Applying template: $($template.name)" -ForegroundColor Yellow
Write-Host "Description: $($template.description)`n" -ForegroundColor Gray

try {
    $team = Get-Team -GroupId $TeamId
    Write-Host "Target team: $($team.DisplayName)`n" -ForegroundColor White

    # Apply settings
    Write-Host "Applying settings..." -ForegroundColor Yellow
    $settings = $template.settings
    Set-Team -GroupId $TeamId `
             -AllowGiphy $settings.AllowGiphy `
             -GiphyContentRating $settings.GiphyContentRating `
             -AllowStickersAndMemes $settings.AllowStickersAndMemes `
             -AllowCustomMemes $settings.AllowCustomMemes `
             -AllowAddRemoveApps $settings.AllowAddRemoveApps `
             -AllowCreateUpdateChannels $settings.AllowCreateUpdateChannels `
             -AllowDeleteChannels $settings.AllowDeleteChannels `
             -AllowUserEditMessages $settings.AllowUserEditMessages `
             -AllowUserDeleteMessages $settings.AllowUserDeleteMessages
    Write-Host "  ✓ Settings applied" -ForegroundColor Green

    # Create channels
    Write-Host "`nCreating channels..." -ForegroundColor Yellow
    foreach ($channel in $template.channels) {
        try {
            $params = @{
                GroupId = $TeamId
                DisplayName = $channel.name
                Description = $channel.description
            }
            if ($channel.membershipType) {
                $params.MembershipType = $channel.membershipType
            }
            New-TeamChannel @params
            Write-Host "  ✓ Created channel: $($channel.name)" -ForegroundColor Green
        } catch {
            if ($_ -match "already exists") {
                Write-Host "  ⚠ Channel already exists: $($channel.name)" -ForegroundColor Yellow
            } else {
                Write-Host "  ✗ Failed to create channel $($channel.name): $_" -ForegroundColor Red
            }
        }
    }

    Write-Host "`n✓ Template applied successfully!" -ForegroundColor Green
    Write-Host ""

} catch {
    Write-Error "Failed to apply template: $_"
    exit 1
}
