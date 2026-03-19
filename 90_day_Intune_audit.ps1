<#
.SYNOPSIS
Audits computers in intune. 
Anythong over 90 days gets flagged
exports to desktop
#>


# Install required modules if missing
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.DeviceManagement)) {
    Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser -Force
}

Import-Module Microsoft.Graph.DeviceManagement

# Connect to Graph with least privilege
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"

# Retrieve all Intune-managed devices
$devices = Get-MgDeviceManagementManagedDevice -All

# Calculate cutoff date (90 days ago)
$cutoff = (Get-Date).AddDays(-90)

# Filter devices that have not synced in 90+ days
$staleDevices = $devices | Where-Object {
    $_.lastSyncDateTime -lt $cutoff -or $_.lastSyncDateTime -eq $null
}

# Export to Desktop
$desktop = [Environment]::GetFolderPath("Desktop")
$exportPath = Join-Path $desktop "Devices_Not_Synced_90_Days.csv"

$staleDevices |
    Select-Object deviceName, userPrincipalName, operatingSystem, complianceState, lastSyncDateTime |
    Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8

Disconnect-MgGraph

Write-Host "Export complete." -ForegroundColor Green
Write-Host "File saved to: $exportPath"