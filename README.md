# 👥 Microsoft Teams Automation PowerShell Toolkit
### Enterprise User Management and Team Provisioning

[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-5391FE?style=for-the-badge&logo=powershell)](https://docs.microsoft.com/powershell/)
[![Teams](https://img.shields.io/badge/Teams-2.0+-6264A7?style=for-the-badge&logo=microsoft-teams)](https://www.microsoft.com/teams)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

## 🎯 Overview

PowerShell scripts for automating Microsoft Teams administration tasks. Handle user provisioning, team creation, policy management, and governance at scale. Built for IT admins managing enterprise Teams environments.

### 📊 Core Functions

- **Bulk Team Creation** from templates or CSV
- **User Provisioning** with automatic policy assignment
- **Channel Management** across multiple teams
- **Guest Access Control** and external sharing
- **Compliance Reporting** for governance
- **Automated Cleanup** of inactive teams

## 💡 Key Scripts

### Team Management
```powershell
# Create teams from CSV
Import-Csv teams.csv | ForEach-Object {
    New-Team -DisplayName $_.TeamName `
             -Description $_.Description `
             -Visibility $_.Type `
             -Template $_.Template
}

# Archive old teams
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

## ⚡ Quick Start

```powershell
# Install Teams module
Install-Module MicrosoftTeams
Import-Module MicrosoftTeams

# Connect to Teams
Connect-MicrosoftTeams

# Load toolkit
. .\TeamsAutomation.ps1

# Run first automation
New-BulkTeams -Template "ProjectTeam" -Count 10
```

## 🛠️ Included Scripts

### Provisioning
- `New-BulkTeams.ps1` - Create multiple teams
- `Import-TeamsFromCSV.ps1` - CSV-based provisioning
- `New-DepartmentTeam.ps1` - Department-specific teams
- `Clone-TeamTemplate.ps1` - Duplicate team structures
- `New-ClassTeams.ps1` - Education class teams

### User Management
- `Add-BulkMembers.ps1` - Add users to teams
- `Sync-ADGroups.ps1` - Sync with Active Directory
- `Set-UserPolicies.ps1` - Apply policies in bulk
- `Remove-InactiveUsers.ps1` - Clean up inactive members
- `Export-TeamMembers.ps1` - Membership reports

### Governance
- `Get-TeamsActivity.ps1` - Activity reports
- `Find-OrphanedTeams.ps1` - Teams without owners
- `Set-TeamExpiration.ps1` - Lifecycle management
- `Audit-GuestAccess.ps1` - External user audit
- `Enforce-NamingPolicy.ps1` - Naming conventions

### Maintenance
- `Archive-OldTeams.ps1` - Archive inactive teams
- `Clean-DeletedTeams.ps1` - Purge soft-deleted teams
- `Update-TeamSettings.ps1` - Bulk settings updates
- `Backup-TeamConfig.ps1` - Configuration backup
- `Restore-Team.ps1` - Restore from backup

## 📈 Features

### Template System
```powershell
# Define team template
$template = @{
    Channels = @("General", "Planning", "Development")
    Apps = @("Planner", "OneNote", "GitHub")
    Settings = @{
        AllowGuestAccess = $false
        AllowMemberAddRemove = $true
    }
}

# Apply template
New-TeamFromTemplate -Template $template -Name "New Project"
```

### Policy Management
```powershell
# Create custom policy
New-CsTeamsMessagingPolicy -Identity "RestrictedChat" `
    -AllowUserChat $false `
    -AllowGiphy $false

# Apply to users
Grant-PolicyToGroup -Group "Interns" -Policy "RestrictedChat"
```

### Reporting
```powershell
# Generate usage report
Get-TeamsUsageReport -Days 30 |
    Export-Excel -Path "TeamsUsage.xlsx" -AutoSize

# Compliance audit
Get-TeamsComplianceReport |
    Send-MailMessage -To "compliance@company.com"
```

## 🔧 Advanced Usage

### Scheduled Tasks
```powershell
# Daily team cleanup
Register-ScheduledTask -TaskName "TeamsCleanup" `
    -Action (New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-File C:\Scripts\Clean-Teams.ps1") `
    -Trigger (New-ScheduledTaskTrigger -Daily -At 2am)
```

### Error Handling
```powershell
# Robust error handling
try {
    New-Team -DisplayName $name
} catch {
    Write-Log "Failed to create team: $_"
    Send-Alert -Message "Team creation failed"
}
```

## 📊 Bulk Operations

Handle thousands of users/teams efficiently:

```powershell
# Parallel processing
$teams | ForEach-Object -Parallel {
    Set-TeamPicture -GroupId $_.GroupId -ImagePath "logo.png"
} -ThrottleLimit 5

# Batch processing
Process-InBatches -Items $users -BatchSize 100 -ScriptBlock {
    param($batch)
    Add-TeamUser -GroupId $teamId -Users $batch
}
```

## 🔒 Security

- **RBAC Support** - Role-based access control
- **Audit Logging** - Track all changes
- **MFA Required** - Multi-factor authentication
- **Secure Storage** - Encrypted credentials
- **Compliance Ready** - GDPR/HIPAA compliant

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| Connection timeout | Use Connect-MicrosoftTeams -UseDeviceAuthentication |
| Throttling | Implement delays between operations |
| Permission denied | Check Teams admin role assignment |
| Team not found | Ensure team is not archived |

## 📚 Resources

- [Script Documentation](docs/README.md)
- [Teams PowerShell Reference](https://docs.microsoft.com/powershell/teams)
- [Best Practices Guide](docs/best-practices.md)
- [Troubleshooting Guide](docs/troubleshooting.md)

## 🤝 Contributing

Share your Teams automation scripts with the community!

## 📜 License

MIT License - Free for all use

---

<div align="center">

**Automate Teams Management at Scale**

[![Download](https://img.shields.io/badge/Download-Scripts-brightgreen?style=for-the-badge)](https://github.com/yourusername/teams-automation/releases)

*Free • Open Source • Enterprise Ready*

</div>