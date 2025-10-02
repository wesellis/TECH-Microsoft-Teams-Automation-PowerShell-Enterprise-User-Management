# Changelog

All notable changes to the Microsoft Teams Automation Bot project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2025-10-02

### Added
- **25+ Enterprise PowerShell Scripts** across 5 categories
- **Provisioning**: New-BulkTeams, Import-TeamsFromCSV, New-DepartmentTeam, Clone-TeamTemplate, New-ClassTeams
- **User Management**: Add-BulkMembers, Sync-ADGroups, Set-UserPolicies, Remove-InactiveUsers, Export-TeamMembers
- **Governance**: Get-TeamsActivity, Find-OrphanedTeams, Set-TeamExpiration, Audit-GuestAccess, Enforce-NamingPolicy
- **Maintenance**: Archive-OldTeams, Clean-DeletedTeams, Update-TeamSettings, Backup-TeamConfig, Restore-Team
- **Templates & Automation**: TeamTemplate.json with 4 predefined templates, Apply-TeamTemplate.ps1, Schedule-TeamCleanup.ps1
- Complete enterprise documentation
- Organized script directory structure

### Changed
- Updated README to reflect [100% Complete] status
- Enhanced all script documentation with comprehensive examples
- Improved error handling and logging across all scripts

### Fixed
- Project structure organization
- Script categorization and discoverability

## [1.1.0] - 2025-05-23

### Added
- Repository standardization with professional structure
- Documentation improvements

### Changed
- Enhanced code formatting and structure

### Fixed
- Documentation formatting issues

## [1.0.0] - 2024-12-01

### Added
- Initial release of Microsoft Teams Automation Bot
- PowerShell scripts for Teams management via Microsoft Graph API
- Core functionality for Teams operations

### Features
- **Send Messages** - Send messages to Teams channels
- **User Management** - Add and remove users from Teams
- **Channel Management** - Create, update, delete, and list channels
- **Meeting Management** - Create, delete, and list meetings
- **Member Management** - List team members

### Scripts Included
- `send-teams-message.ps1` - Send messages to Teams channels
- `Add-TeamsUser.ps1` - Add users to Teams
- `Remove-TeamsUser.ps1` - Remove users from Teams
- `List-TeamsChannels.ps1` - List all channels in a team
- `Create-TeamsChannel.ps1` - Create new channels
- `Delete-TeamsChannel.ps1` - Delete channels
- `Update-TeamsChannel.ps1` - Update channel properties
- `List-TeamsMembers.ps1` - List team members
- `Create-TeamsMeeting.ps1` - Create new meetings
- `Delete-TeamsMeeting.ps1` - Delete meetings
- `List-TeamsMeetings.ps1` - List team meetings

### Requirements
- PowerShell 5.1 or later
- Microsoft Graph API access
- Appropriate Azure AD app registration
- Teams administrator permissions