<#
.SYNOPSIS
This will pull groups without an owner assigned


.DESCRIPTION
This goes through the entire tenant
Pulls groups without owner assigned
creates a CSV and puts it on the desktop
#>

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
    "Microsoft.Graph.Groups"
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
$ExportFolder = Join-Path $Desktop "OwnerlessGroups_$Timestamp"
New-Item -ItemType Directory -Path $ExportFolder -Force | Out-Null
$ExportFile = Join-Path $ExportFolder "OwnerlessSecurityGroups.csv"

Connect-MgGraph -Scopes "Group.Read.All"

$groups = Get-MgGroup -All -Filter "securityEnabled eq true" -Property "id,displayName" |
    Where-Object {
        (Get-MgGroupOwner -GroupId $_.Id -ErrorAction SilentlyContinue).Count -eq 0
    } |
    Select-Object DisplayName, Id

$groups | Export-Csv -Path $ExportFile -NoTypeInformation -Encoding UTF8