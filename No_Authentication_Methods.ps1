<#

.SYNOPSIS
This pulls all users without a registered Authentication method


.DESCRIPTION
This goes through all of the active users in the Tenet
It includes service accounts and Resources
It will tell you what accounts have no Authentication methods

#>
Connect-MgGraph -Scopes "User.Read.All","Reports.Read.All"

# Desktop export folder
$Desktop = [Environment]::GetFolderPath("Desktop")
$Timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
$ExportFolder = Join-Path $Desktop "Users_Missing_MFA_$Timestamp"
New-Item -ItemType Directory -Path $ExportFolder -Force | Out-Null

$ExportFile = Join-Path $ExportFolder "Users_Missing_MFA.csv"

# Get MFA registration details
$details = Get-MgReportAuthenticationMethodUserRegistrationDetail -All

# Filter only users with NO MFA methods registered
$noMfa = $details |
    Where-Object { $_.IsMfaRegistered -eq $false } |
    Select-Object `
        userPrincipalName,
        @{Name="MethodsRegistered";Expression={ ($_.MethodsRegistered -join "; ") }},
        @{Name="IsMfaRegistered";Expression={ $_.IsMfaRegistered }}

# Export to CSV
$noMfa | Export-Csv -Path $ExportFile -NoTypeInformation -Encoding UTF8