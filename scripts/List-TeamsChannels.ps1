#!/usr/bin/env pwsh
# Script to list all channels in a Microsoft Teams team

param (
    [string]$tenantId,
    [string]$clientId,
    [string]$clientSecret,
    [string]$teamId
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

# Function to list all channels in a Teams team
function List-TeamsChannels {
    param (
        [string]$accessToken,
        [string]$teamId
    )
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/teams/$teamId/channels" -Method Get -Headers @{ Authorization = "Bearer $accessToken" }
}

# Main script logic
$accessToken = Get-AccessToken -tenantId $tenantId -clientId $clientId -clientSecret $clientSecret
List-TeamsChannels -accessToken $accessToken -teamId $teamId
