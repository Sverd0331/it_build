<#
.SYNOPSIS
Finds all users who have not signed in within the last 90 days.

.DESCRIPTION
This script retrieves all users, retrieves all sign-in logs once
groups them by userId 
and identifies users whose most recent sign-in
if older than 90 days or who have never signed in.

A timestamped folder is created on the Desktop with CSV
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
    "Microsoft.Graph.Users",
    "Microsoft.Graph.Reports"
)

foreach ($Module in $Modules) {
    if (-not (Get-Module -ListAvailable -Name $Module)) {
        Install-Module -Name $Module -Force -ErrorAction Stop
    }
    Import-Module $Module -Force -ErrorAction Stop
}

$ClientId     = "<APPID>"
$TenantId     = "<TENANTID>"
$ClientSecret = "<SECRET>"

Connect-MgGraph -ClientId $ClientId -TenantId $TenantId -ClientSecret $ClientSecret

$cutoff = (Get-Date).AddDays(-90)

$Desktop = [Environment]::GetFolderPath("Desktop")
$Timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
$ExportFolder = Join-Path $Desktop "UsersNotSignedIn_$Timestamp"
New-Item -ItemType Directory -Path $ExportFolder -Force | Out-Null
$ExportFile = Join-Path $ExportFolder "UsersNotSignedIn90Days.csv"

$users = Get-MgUser -All -Property "id,displayName,userPrincipalName"

$allSignins = Get-MgAuditLogSignIn -All -Property "userId,createdDateTime" `
    -Filter "userId ne null"

$latestByUser = $allSignins |
    Group-Object userId |
    ForEach-Object {
        $_.Group | Sort-Object createdDateTime -Descending | Select-Object -First 1
    }

$results = foreach ($u in $users) {
    $last = $latestByUser | Where-Object { $_.userId -eq $u.Id }

    $lastSignIn = if ($last) { $last.createdDateTime } else { $null }

    if (-not $lastSignIn -or $lastSignIn -lt $cutoff) {
        [PSCustomObject]@{
            DisplayName       = $u.DisplayName
            UserPrincipalName = $u.UserPrincipalName
        }
    }
}

$results | Export-Csv -Path $ExportFile -NoTypeInformation -Encoding UTF8