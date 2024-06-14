#!/usr/bin/env pwsh
# Script to remove a user from a Microsoft Teams team

param (
    [string]$tenantId,
    [string]$clientId,
    [string]$clientSecret,
    [string]$teamId,
    [string]$userId
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

# Function to remove a user from a Teams team
function Remove-TeamsUser {
    param (
        [string]$accessToken,
        [string]$teamId,
        [string]$userId
    )
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/groups/$teamId/members/$userId/\$ref" -Method Delete -Headers @{ Authorization = "Bearer $accessToken" }
}

# Main script logic
$accessToken = Get-AccessToken -tenantId $tenantId -clientId $clientId -clientSecret $clientSecret
Remove-TeamsUser -accessToken $accessToken -teamId $teamId -userId $userId
