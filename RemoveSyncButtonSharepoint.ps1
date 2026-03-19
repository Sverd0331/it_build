<#
.SYNOPSIS
Goes through the entire sharepoint tenant and removes the sync button
.DESCRIPTION
This will make it so users can only use the add shortcut to onedrive option
This is a more efficent option since it carries the sync'd folders over to devices
and new machines
Replace sharepoint url with one from  tenant
Replace admin account with global admin
#>


Install-Module -Name Microsoft.Online.SharePoint.PowerShell

Connect-SPOService -Url https://tenant-admin.sharepoint.com -credential "Admin account"


Set-SPOTenant -HideSyncButtonOnTeamSite $true

