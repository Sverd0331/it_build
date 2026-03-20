<#
.SYNOPSIS
Creates file of Users with >75GB of Mailbox

.DESCRIPTION

Pulls inboxes with mailboxes over 75GB
#>

# Install and import Exchange Online module
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force
}
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online
Connect-ExchangeOnline

<# 
Retrieve mailboxes over 75GB
Update number on line 20 for mailbox size in GB
#>
$mailboxes = Get-ExoMailbox -ResultSize Unlimited |
    Get-ExoMailboxStatistics |
    Where-Object { $_.TotalItemSize.Value.ToGB() -gt 75 } |
    Select-Object DisplayName, @{n="TotalSizeGB";e={$_.TotalItemSize.Value.ToGB()}}

# Prepare Desktop export path
$desktop = [Environment]::GetFolderPath("Desktop")
$exportPath = Join-Path $desktop "Mailboxes_Over_75GB.csv"

# Export results
$mailboxes | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8

# Disconnect
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "Export complete. File saved to: $exportPath" -ForegroundColor Green