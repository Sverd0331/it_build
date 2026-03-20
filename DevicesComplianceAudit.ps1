<#
.SYNOPSIS
Exports devices into Compliant and non Compliant folders

.DESCRIPTION

Exports all devices from intune
two seperate files
one complient
one non-complient
has latest sync date
drops files on Desktop

#>

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.DeviceManagement)) {
    Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser -Force
}
Import-Module Microsoft.Graph.DeviceManagement

Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"

$allDevices = Get-MgDeviceManagementManagedDevice -All

$compliant = $allDevices | Where-Object { $_.complianceState -eq "compliant" }
$nonCompliant = $allDevices | Where-Object { $_.complianceState -ne "compliant" -and $_.complianceState -ne $null }

$desktop = [Environment]::GetFolderPath("Desktop")
$compliantPath = Join-Path $desktop "Compliant_Devices.csv"
$nonCompliantPath = Join-Path $desktop "NonCompliant_Devices.csv"

$compliant | Select-Object deviceName, userPrincipalName, complianceState, operatingSystem, lastSyncDateTime |
    Export-Csv -Path $compliantPath -NoTypeInformation -Encoding UTF8

$nonCompliant | Select-Object deviceName, userPrincipalName, complianceState, operatingSystem, lastSyncDateTime |
    Export-Csv -Path $nonCompliantPath -NoTypeInformation -Encoding UTF8

Disconnect-MgGraph

Write-Host "Export complete." -ForegroundColor Green
Write-Host "Compliant devices: $compliantPath"
Write-Host "Non-compliant devices: $nonCompliantPath"