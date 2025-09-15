#!/usr/bin/env pwsh
# Script to add a user to a Microsoft Teams team

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

# Function to add a user to a Teams team
function Add-TeamsUser {
    param (
        [string]$accessToken,
        [string]$teamId,
        [string]$userId
    )
    $body = @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/users/$userId"
    }
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/groups/$teamId/members/\$ref" -Method Post -Headers @{ Authorization = "Bearer $accessToken" } -Body ($body | ConvertTo-Json -Depth 4)
}

# Main script logic
$accessToken = Get-AccessToken -tenantId $tenantId -clientId $clientId -clientSecret $clientSecret
Add-TeamsUser -accessToken $accessToken -teamId $teamId -userId $userId
