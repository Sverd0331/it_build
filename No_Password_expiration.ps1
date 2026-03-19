<#
.SYNOPSIS
Runs a report of users who have password expiration disable

.DESCRIPTION
This will create a report and put it on the desktop in a time stamped folder

#>

if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh = "C:\Program Files\PowerShell\7\pwsh.exe"
    & $pwsh -File $PSCommandPath
    exit
}

$nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
if (-not $nuget) {
    Install-PackageProvider -Name NuGet -Force -Scope AllUsers -ErrorAction Stop
}

$repo = Get-PSRepository -Name "PSGallery"
if ($repo.InstallationPolicy -ne "Trusted") {
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
}

$Modules = @(
    "Microsoft.Graph",
    "Microsoft.Graph.Users"
)

foreach ($Module in $Modules) {
    if (-not (Get-Module -ListAvailable -Name $Module)) {
        Install-Module -Name $Module -Force -ErrorAction Stop
    }
    Import-Module $Module -Force -ErrorAction Stop
}

Set-MgGraphOption -DisableLoginByWAM $true

$Desktop = [Environment]::GetFolderPath("Desktop")
$Timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
$ExportFolder = Join-Path $Desktop "PasswordExpirationReport_$Timestamp"
New-Item -ItemType Directory -Path $ExportFolder -Force | Out-Null
$ExportFile = Join-Path $ExportFolder "UsersWithDisabledPasswordExpiration.csv"

Connect-MgGraph -Scopes "User.Read.All"

$users = Get-MgUser -All -Property "displayName,userPrincipalName,passwordPolicies" |
    Where-Object { $_.passwordPolicies -match "DisablePasswordExpiration" } |
    Select-Object DisplayName, UserPrincipalName

$users | Export-Csv -Path $ExportFile -NoTypeInformation -Encoding UTF8