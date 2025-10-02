# [100% Complete] Microsoft Teams Automation PowerShell Toolkit

Enterprise-grade PowerShell automation suite for Microsoft Teams administration, provisioning, and governance.

[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-5391FE?style=flat-square&logo=powershell&logoColor=white)](https://docs.microsoft.com/powershell/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/wesellis/TECH-Microsoft-Teams-Automation-PowerShell-Enterprise-User-Management?style=flat-square)](https://github.com/wesellis/TECH-Microsoft-Teams-Automation-PowerShell-Enterprise-User-Management/stargazers)
[![Last Commit](https://img.shields.io/github/last-commit/wesellis/TECH-Microsoft-Teams-Automation-PowerShell-Enterprise-User-Management?style=flat-square)](https://github.com/wesellis/TECH-Microsoft-Teams-Automation-PowerShell-Enterprise-User-Management/commits)

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

## Complete Script Library (25+ Scripts)

### 📁 Provisioning (`scripts/provisioning/`)
- `New-BulkTeams.ps1` - Create multiple teams from CSV or array with throttling
- `Import-TeamsFromCSV.ps1` - Advanced CSV import with channels, members, and roles
- `New-DepartmentTeam.ps1` - Department-specific teams with standard structure
- `Clone-TeamTemplate.ps1` - Clone existing teams including settings and channels
- `New-ClassTeams.ps1` - Education class teams with EDU template

### 👥 User Management (`scripts/user-management/`)
- `Add-BulkMembers.ps1` - Bulk user addition with role assignment and CSV support
- `Sync-ADGroups.ps1` - Active Directory group synchronization with cleanup
- `Set-UserPolicies.ps1` - Apply messaging, meeting, and calling policies
- `Remove-InactiveUsers.ps1` - Identify and remove inactive users with backup
- `Export-TeamMembers.ps1` - Generate detailed membership reports with user details

### 🛡️ Governance (`scripts/governance/`)
- `Get-TeamsActivity.ps1` - Comprehensive activity analysis with metrics and insights
- `Find-OrphanedTeams.ps1` - Detect teams with insufficient owners and auto-fix
- `Set-TeamExpiration.ps1` - Lifecycle management with auto-archival
- `Audit-GuestAccess.ps1` - External guest audit with security risk assessment
- `Enforce-NamingPolicy.ps1` - Naming convention enforcement with auto-rename

### 🔧 Maintenance (`scripts/maintenance/`)
- `Archive-OldTeams.ps1` - Archive inactive teams based on age or activity
- `Clean-DeletedTeams.ps1` - Purge soft-deleted teams from recycle bin
- `Update-TeamSettings.ps1` - Bulk settings updates across teams
- `Backup-TeamConfig.ps1` - Export teams to JSON for disaster recovery
- `Restore-Team.ps1` - Restore teams from JSON backups

### 📋 Templates & Automation (`scripts/templates/`, `scripts/automation/`)
- `TeamTemplate.json` - Predefined templates (standard, project, executive, education)
- `Apply-TeamTemplate.ps1` - Apply JSON templates to teams
- `Schedule-TeamCleanup.ps1` - Schedule automated maintenance tasks

### 🔌 Core Operations (already existing)
- Message management, channel operations, meeting automation
- 11 additional scripts for day-to-day operations

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

---

## Project Status

**Completion: 100% ✅**

### Completed Features
- ✅ **25+ PowerShell Scripts** - Full enterprise automation suite
- ✅ **Provisioning Automation** - Bulk team creation, CSV import, department & class teams
- ✅ **User Management** - Bulk operations, AD sync, policy assignment, inactive user cleanup
- ✅ **Governance & Compliance** - Activity reporting, orphan detection, expiration policies, guest audits, naming enforcement
- ✅ **Maintenance Operations** - Archival, backup/restore, settings management
- ✅ **Template System** - Reusable JSON templates for consistent team creation
- ✅ **TypeScript Bot Framework** - Graph API integration, webhooks, scheduling
- ✅ **Enterprise Documentation** - Comprehensive guides and examples

### Current Status
Production-ready PowerShell automation suite for Microsoft Teams enterprise management. Complete with all core scripts, governance tools, and enterprise features.

**Note**: All 25+ enterprise scripts implemented and ready for deployment.
