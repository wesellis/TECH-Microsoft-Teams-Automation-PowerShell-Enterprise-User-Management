#!/usr/bin/env pwsh
# Script to update a channel in a Microsoft Teams team

param (
    [string]$tenantId,
    [string]$clientId,
    [string]$clientSecret,
    [string]$teamId,
    [string]$channelId,
    [string]$channelName,
    [string]$channelDescription
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

# Function to update a channel in a Teams team
function Update-TeamsChannel {
    param (
        [string]$accessToken,
        [string]$teamId,
        [string]$channelId,
        [string]$channelName,
        [string]$channelDescription
    )
    $body = @{
        displayName = $channelName
        description = $channelDescription
    }
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/teams/$teamId/channels/$channelId" -Method Patch -Headers @{ Authorization = "Bearer $accessToken" } -Body ($body | ConvertTo-Json -Depth 4)
}

# Main script logic
$accessToken = Get-AccessToken -tenantId $tenantId -clientId $clientId -clientSecret $clientSecret
Update-TeamsChannel -accessToken $accessToken -teamId $teamId -channelId $channelId -channelName $channelName -channelDescription $channelDescription
