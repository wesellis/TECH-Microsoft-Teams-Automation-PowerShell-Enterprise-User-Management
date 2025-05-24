# Microsoft Teams Automation Bot

This repository contains scripts and configurations for automating tasks in Microsoft Teams using PowerShell and the Microsoft Graph API.

## Table of Contents

- [Description](#description)
- [Installation](#installation)
- [Usage](#usage)
  - [Sample Script: Send a Message to a Teams Channel](#sample-script-send-a-message-to-a-teams-channel)
- [Scripts](#scripts)
- [Contributing](#contributing)
- [License](#license)

## Description

The Microsoft Teams Automation Bot project aims to streamline and automate various tasks within Microsoft Teams. Using PowerShell and the Microsoft Graph API, these scripts enable efficient management and operation of Teams functionalities.

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

## Contributing

We welcome contributions to improve and expand this collection of scripts. Please see our [CONTRIBUTING.md](CONTRIBUTING.md) file for guidelines.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.