#!/usr/bin/env pwsh
# Sample script to send a message to a Microsoft Teams channel

param (
    [string]$tenantId,
    [string]$clientId,
    [string]$clientSecret,
    [string]$channelId,
    [string]$message
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

# Function to send a message to a Teams channel
function Send-TeamsMessage {
    param (
        [string]$accessToken,
        [string]$channelId,
        [string]$message
    )
    $body = @{
        body = @{
            content = $message
        }
    }
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/teams/$channelId/messages" -Method Post -Headers @{ Authorization = "Bearer $accessToken" } -Body ($body | ConvertTo-Json -Depth 4)
}

# Main script logic
$accessToken = Get-AccessToken -tenantId $tenantId -clientId $clientId -clientSecret $clientSecret
Send-TeamsMessage -accessToken $accessToken -channelId $channelId -message $message
