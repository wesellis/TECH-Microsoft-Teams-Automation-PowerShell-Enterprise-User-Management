# Microsoft Teams Automation PowerShell Toolkit

PowerShell scripts for automating Microsoft Teams administration tasks.

[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-5391FE?style=flat-square&logo=powershell)](https://docs.microsoft.com/powershell/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

## Overview

A collection of PowerShell scripts to help automate common Microsoft Teams administration tasks. Useful for IT admins managing Teams environments who want to streamline user provisioning, team creation, and policy management.

## Core Functions

- **Bulk Team Creation** - Create multiple teams from templates or CSV files
- **User Provisioning** - Add users to teams with policy assignment
- **Channel Management** - Manage channels across multiple teams
- **Guest Access Control** - Control external user access
- **Compliance Reporting** - Generate governance reports
- **Automated Cleanup** - Archive or remove inactive teams

## Prerequisites

- PowerShell 7.0 or higher
- Microsoft Teams PowerShell module
- Teams administrator permissions
- Azure AD credentials

## Quick Start

```powershell
# Install Teams module
Install-Module MicrosoftTeams
Import-Module MicrosoftTeams

# Connect to Teams
Connect-MicrosoftTeams

# Load the toolkit scripts
. .\scripts\TeamsAutomation.ps1

# Example: Create teams from CSV
Import-Csv teams.csv | ForEach-Object {
    New-Team -DisplayName $_.TeamName `
             -Description $_.Description `
             -Visibility $_.Type
}
```

## Example Scripts

### Team Management

```powershell
# Create teams from CSV
Import-Csv teams.csv | ForEach-Object {
    New-Team -DisplayName $_.TeamName `
             -Description $_.Description `
             -Visibility $_.Type `
             -Template $_.Template
}

# Archive inactive teams
Get-Team | Where {$_.LastActivity -lt (Get-Date).AddDays(-180)} |
    Set-TeamArchivedState -Archived $true

# Clone team structure
Copy-TeamStructure -SourceTeam "Template Team" `
                   -NewTeamName "Q2 Project Team"
```

### User Management

```powershell
# Add users to multiple teams
$users = Get-Content users.txt
$teams = "Sales", "Marketing", "Support"
Add-UsersToTeams -Users $users -Teams $teams

# Set policies for department
Get-CsOnlineUser -Filter "Department eq 'Engineering'" |
    Grant-CsTeamsMessagingPolicy -PolicyName "EngineeringPolicy"

# Remove external users
Get-TeamUser -GroupId $teamId |
    Where {$_.User -like "*#EXT#*"} |
    Remove-TeamUser
```

### Channel Operations

```powershell
# Create standard channels
$channels = @("General", "Planning", "Development", "Testing")
$channels | ForEach {
    New-TeamChannel -GroupId $teamId -DisplayName $_
}

# Set channel permissions
Set-TeamChannelPermissions -Channel "Confidential" `
                          -AllowNewPosts "Owners"
```

## Available Scripts

### Provisioning
- `New-BulkTeams.ps1` - Create multiple teams at once
- `Import-TeamsFromCSV.ps1` - Import teams from CSV file
- `New-DepartmentTeam.ps1` - Create department-specific teams
- `Clone-TeamTemplate.ps1` - Duplicate team structures
- `New-ClassTeams.ps1` - Create education class teams

### User Management
- `Add-BulkMembers.ps1` - Add users to teams in bulk
- `Sync-ADGroups.ps1` - Sync with Active Directory groups
- `Set-UserPolicies.ps1` - Apply policies to multiple users
- `Remove-InactiveUsers.ps1` - Clean up inactive members
- `Export-TeamMembers.ps1` - Generate membership reports

### Governance
- `Get-TeamsActivity.ps1` - Generate activity reports
- `Find-OrphanedTeams.ps1` - Find teams without owners
- `Set-TeamExpiration.ps1` - Implement lifecycle management
- `Audit-GuestAccess.ps1` - Audit external users
- `Enforce-NamingPolicy.ps1` - Apply naming conventions

### Maintenance
- `Archive-OldTeams.ps1` - Archive inactive teams
- `Clean-DeletedTeams.ps1` - Purge soft-deleted teams
- `Update-TeamSettings.ps1` - Bulk update team settings
- `Backup-TeamConfig.ps1` - Backup team configurations
- `Restore-Team.ps1` - Restore from backup

## Template System

Define reusable team templates:

```powershell
# Define team template
$template = @{
    Channels = @("General", "Planning", "Development")
    Apps = @("Planner", "OneNote")
    Settings = @{
        AllowGuestAccess = $false
        AllowMemberAddRemove = $true
    }
}

# Apply template
New-TeamFromTemplate -Template $template -Name "New Project"
```

## Policy Management

```powershell
# Create custom messaging policy
New-CsTeamsMessagingPolicy -Identity "RestrictedChat" `
    -AllowUserChat $false `
    -AllowGiphy $false

# Apply to group
Grant-PolicyToGroup -Group "Interns" -Policy "RestrictedChat"
```

## Reporting

```powershell
# Generate usage report
Get-TeamsUsageReport -Days 30 |
    Export-Csv -Path "TeamsUsage.csv" -NoTypeInformation

# Compliance audit
Get-TeamsComplianceReport |
    Export-Csv -Path "ComplianceAudit.csv"
```

## Scheduled Tasks

Automate routine maintenance:

```powershell
# Daily team cleanup
Register-ScheduledTask -TaskName "TeamsCleanup" `
    -Action (New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-File C:\Scripts\Clean-Teams.ps1") `
    -Trigger (New-ScheduledTaskTrigger -Daily -At 2am)
```

## Error Handling

```powershell
# Robust error handling example
try {
    New-Team -DisplayName $name
} catch {
    Write-Log "Failed to create team: $_"
    Send-MailMessage -To "admin@company.com" `
                     -Subject "Team creation failed" `
                     -Body $_
}
```

## Bulk Operations

Process large numbers of teams or users:

```powershell
# Parallel processing (PowerShell 7+)
$teams | ForEach-Object -Parallel {
    Set-TeamPicture -GroupId $_.GroupId -ImagePath "logo.png"
} -ThrottleLimit 5

# Batch processing
$users | ForEach-Object -Begin {$i=0} -Process {
    Add-TeamUser -GroupId $teamId -User $_
    if (++$i % 100 -eq 0) { Start-Sleep -Seconds 5 } # Throttle
}
```

## Common Issues

| Issue | Solution |
|-------|----------|
| Connection timeout | Use `Connect-MicrosoftTeams -UseDeviceAuthentication` |
| Throttling errors | Add delays between operations |
| Permission denied | Verify Teams admin role assignment |
| Team not found | Check if team is archived |

## Security Considerations

- Store credentials securely (use Windows Credential Manager or Azure Key Vault)
- Use multi-factor authentication when connecting
- Log all administrative actions for audit trails
- Follow principle of least privilege for service accounts
- Review and test scripts in non-production environment first

## Project Structure

```
teams-automation/
├── scripts/              # PowerShell scripts
├── src/                  # Source code (if applicable)
├── .github/              # GitHub workflows
├── CHANGELOG.md          # Version history
├── CONTRIBUTING.md       # Contribution guidelines
├── SECURITY.md           # Security policy
└── README.md             # This file
```

## Resources

- [Teams PowerShell Reference](https://docs.microsoft.com/powershell/teams)
- [Microsoft Teams Admin Center](https://admin.teams.microsoft.com)
- [Teams Development Documentation](https://docs.microsoft.com/microsoftteams/platform/)

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - See [LICENSE](LICENSE) for details.

---

**Note**: This is a portfolio/demonstration project. Test thoroughly in a non-production environment before using in production.
