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

\\\ash
git clone https://github.com/wesellis/Microsoft-Teams-Automation-Bot.git
cd Microsoft-Teams-Automation-Bot
\\\

## Usage

### Sample Script: Send a Message to a Teams Channel

To send a message to a Microsoft Teams channel, use the \send-teams-message.ps1\ script.

\\\powershell
./scripts/send-teams-message.ps1 -tenantId "<Tenant-ID>" -clientId "<Client-ID>" -clientSecret "<Client-Secret>" -channelId "<Channel-ID>" -message "Hello, Teams!"
\\\

## Scripts

- **send-teams-message.ps1**: Script to send a message to a Microsoft Teams channel.

## Contributing

We welcome contributions to improve and expand this collection of scripts. Please see our [CONTRIBUTING.md](CONTRIBUTING.md) file for guidelines.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
