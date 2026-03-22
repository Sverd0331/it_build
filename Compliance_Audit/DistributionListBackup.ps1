<#
.SYNOPSIS
Creates CSV of all DL's

.DESCRIPTION
Run this as admin to import modules as needed
Useful to use prior to any automatic deletion scripts
Pulls the list and members of list
saves to Desktop
#>
# Install Exchange Online module
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Force
}

Import-Module ExchangeOnlineManagement


# Connect to Exchange Online

Connect-ExchangeOnline -ShowBanner:$false


# sets path as current users Desktop

$Desktop = [Environment]::GetFolderPath("Desktop")
$OutputFile = Join-Path $Desktop "All-Distribution-Group-Members.csv"


# Collect Distribution list and members

$Result = @()

$groups = Get-DistributionGroup -ResultSize Unlimited
$total = $groups.Count
$i = 1

foreach ($group in $groups) {

    Write-Progress -Activity "Processing $($group.DisplayName)" `
                   -Status "$i of $total completed"

    $members = Get-DistributionGroupMember -Identity $group.Name -ResultSize Unlimited

    foreach ($member in $members) {
        $Result += [PSCustomObject]@{
            GroupName     = $group.DisplayName
            Member        = $member.Name
            EmailAddress  = $member.PrimarySMTPAddress
            RecipientType = $member.RecipientType
        }
    }

    $i++
}


# Export to Desktop as CSV
$Result | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8

Write-Host "Export complete. File saved to: $OutputFile"