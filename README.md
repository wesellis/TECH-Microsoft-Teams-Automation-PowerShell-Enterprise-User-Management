# 🤖 Microsoft Teams Automation Bot

[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://microsoft.com/powershell)
[![TypeScript](https://img.shields.io/badge/TypeScript-Coming%20Soon-orange.svg)](#version-20)
[![Pro Version](https://img.shields.io/badge/Pro%20Version-$29-gold.svg)](https://gumroad.com/l/teams-automation-pro)

> **Enterprise-grade Microsoft Teams automation platform - Save 20+ hours per week on repetitive tasks**

Automate team management, channel operations, user provisioning, and more with our comprehensive PowerShell toolkit.

## Table of Contents

- [Description](#description)
- [Installation](#installation)
- [Usage](#usage)
  - [Sample Script: Send a Message to a Teams Channel](#sample-script-send-a-message-to-a-teams-channel)
- [Scripts](#scripts)
- [Contributing](#contributing)
- [License](#license)

## 🎯 What Can You Automate?

### User Management
- **Bulk provisioning** - Add 100s of users in minutes
- **Role assignment** - Automate permissions and access
- **Guest management** - Control external user access
- **Offboarding** - Remove users and preserve data

### Channel Operations  
- **Bulk channel creation** - Deploy standardized channels
- **Permission management** - Control who can post/reply
- **Content migration** - Move messages between channels
- **Archive automation** - Clean up old channels

### Meeting Automation
- **Recurring meeting setup** - Create series automatically
- **Attendance tracking** - Export participant reports
- **Recording management** - Organize and share recordings
- **Calendar integration** - Sync with Outlook

### Compliance & Security
- **Activity monitoring** - Track user actions
- **Policy enforcement** - Apply governance rules
- **Audit reporting** - Generate compliance reports
- **Data retention** - Automate cleanup policies

## 📊 ROI Calculator

**Manual Teams Management**: 25 hours/week @ $50/hour = $1,250/week
**With Automation**: 5 hours/week @ $50/hour = $250/week
**Weekly Savings**: $1,000
**Annual Savings**: **$52,000**

**Pro Version ROI**: Less than 1 hour of saved time!

### 🆕 Version 2.0 - TypeScript Migration (Coming Soon)
We're building a modern TypeScript/Node.js platform:
- 🚀 **50% faster execution**
- 🔄 **Advanced error handling**
- 📦 **NPM package** (@teams-automation/bot)
- 🌐 **Web dashboard** for monitoring
- ☁️ **SaaS platform** (subscription model)

**Early Access**: Pro/Enterprise customers get v2.0 beta access

## Installation

To get started, clone the repository and install the required dependencies.

```bash
git clone https://github.com/wesellis/Microsoft-Teams-Automation-Bot.git
cd Microsoft-Teams-Automation-Bot
```

## Usage

### Sample Script: Send a Message to a Teams Channel

To send a message to a Microsoft Teams channel, use the `send-teams-message.ps1` script.

```powershell
./scripts/send-teams-message.ps1 -tenantId "<Tenant-ID>" -clientId "<Client-ID>" -clientSecret "<Client-Secret>" -channelId "<Channel-ID>" -message "Hello, Teams!"
```

### Other Scripts

- **Add-TeamsUser.ps1**: Script to add a user to a Microsoft Teams team.
- **Remove-TeamsUser.ps1**: Script to remove a user from a Microsoft Teams team.
- **List-TeamsChannels.ps1**: Script to list all channels in a Microsoft Teams team.
- **Create-TeamsChannel.ps1**: Script to create a new channel in a Microsoft Teams team.
- **Delete-TeamsChannel.ps1**: Script to delete a channel in a Microsoft Teams team.
- **Update-TeamsChannel.ps1**: Script to update a channel in a Microsoft Teams team.
- **List-TeamsMembers.ps1**: Script to list all members in a Microsoft Teams team.
- **Create-TeamsMeeting.ps1**: Script to create a new meeting in a Microsoft Teams team.
- **Delete-TeamsMeeting.ps1**: Script to delete a meeting in a Microsoft Teams team.
- **List-TeamsMeetings.ps1**: Script to list all meetings in a Microsoft Teams team.

## 💵 Pricing & Licensing

### Free Version
- Basic PowerShell scripts
- Community support
- Core automation features
- Perfect for testing

### Pro Version - $29 (One-time)
**Everything you need for Teams automation:**
- ✅ **50+ PowerShell scripts** (all current and future)
- ✅ **Advanced automation templates**
- ✅ **Setup guide & video tutorials**
- ✅ **90-day email support**
- ✅ **Priority feature requests**
- ✅ **Bulk operations scripts**
- ✅ **Security best practices guide**
- ✅ **Updates for 1 year**

**[🛒 Get Pro Version →](https://gumroad.com/l/teams-automation-pro)**

### Enterprise License - $149
**For organizations and consultants:**
- ✅ Everything in Pro
- ✅ **Unlimited organization use**
- ✅ **Priority support (24hr response)**
- ✅ **Custom script development** (2 hours included)
- ✅ **Implementation assistance**
- ✅ **Architecture consultation**
- ✅ **White-label rights**

**[🏢 Get Enterprise →](https://gumroad.com/l/teams-automation-enterprise)**

### Why Pay?
- **Save 20+ hours/week** on Teams management
- **Reduce errors** with tested automation
- **Scale operations** without adding staff
- **Professional support** when you need it
- **ROI in days**, not months

## Contributing

We welcome contributions to improve and expand this collection of scripts. Please see our [CONTRIBUTING.md](CONTRIBUTING.md) file for guidelines.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.