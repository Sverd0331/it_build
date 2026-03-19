<#
.SYNOPSIS
Audits computers in intune. 
Anythong over 90 days gets flagged
exports to desktop
#>

$nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
if (-not $nuget) {
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
}

Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.DeviceManagement)) {
    Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser -Force -AllowClobber
}

Import-Module Microsoft.Graph.DeviceManagement

Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"

$devices = Get-MgDeviceManagementManagedDevice -All

$cutoff = (Get-Date).AddDays(-90)

$staleDevices = $devices | Where-Object {
    $_.lastSyncDateTime -lt $cutoff -or $_.lastSyncDateTime -eq $null
}

$desktop = [Environment]::GetFolderPath("Desktop")
$exportPath = Join-Path $desktop "Devices_Not_Synced_90_Days.csv"

$staleDevices |
    Select-Object deviceName,
                  userPrincipalName,
                  operatingSystem,
                  complianceState,
                  managementAgent,
                  ownerType,
                  lastSyncDateTime |
    Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8

Disconnect-MgGraph

Write-Host "Export complete." -ForegroundColor Green
Write-Host "Saved to: $exportPath"
