#!/usr/bin/env pwsh
# Script to create a new channel in a Microsoft Teams team

param (
    [string]$tenantId,
    [string]$clientId,
    [string]$clientSecret,
    [string]$teamId,
    [string]$channelName
)

# Function to get an access token
function Get-AccessToken {
    param (
        [string]$tenantId,
        [string]$clientId,
        [string]$clientSecret
    )
    $body = @{
        grant_type    = "client_credentials"
        scope         = "https://graph.microsoft.com/.default"
        client_id     = $clientId
        client_secret = $clientSecret
    }
    $response = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method Post -Body $body
    return $response.access_token
}

# Function to create a new channel in a Teams team
function Create-TeamsChannel {
    param (
        [string]$accessToken,
        [string]$teamId,
        [string]$channelName
    )
    $body = @{
        displayName = $channelName
        description = "Created via PowerShell script"
    }
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/teams/$teamId/channels" -Method Post -Headers @{ Authorization = "Bearer $accessToken" } -Body ($body | ConvertTo-Json -Depth 4)
}

# Main script logic
$accessToken = Get-AccessToken -tenantId $tenantId -clientId $clientId -clientSecret $clientSecret
Create-TeamsChannel -accessToken $accessToken -teamId $teamId -channelName $channelName
