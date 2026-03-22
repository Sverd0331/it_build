<#
.SYNOPSIS
Verifies all user calendars a user has access to

.DESCRIPTION
This script runs cleanly in Powershell 7
It connectes to exchange
Asks the user you want to check
Scans every inbox in the tenant specifically the calendar folder
Outputs what Calendar the user has access to
It does take a few mins for it to run

#>



# Ensure ExchangeOnlineManagement module is installed
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Force -Scope CurrentUser
}

# Import the module
Import-Module ExchangeOnlineManagement -Force

# Connect to Exchange Online if not already connected
try {
    Get-EXOMailbox -ResultSize 1 | Out-Null
} catch {
    Connect-ExchangeOnline -ShowBanner:$false
}

# Ask for the user to check
$Delegate = Read-Host "Enter the UPN of the user to check"

# Get all mailboxes
$mailboxes = Get-EXOMailbox -ResultSize Unlimited
$total = $mailboxes.Count
$count = 0

<# 
Scan all mailboxes for calendar permissions
This is intentionally verbose so you can see progress
#> 
$results = foreach ($mbx in $mailboxes) {
    $count++
    Write-Host "[$count / $total] Checking $($mbx.PrimarySmtpAddress)..." -ForegroundColor DarkGray

    $calendarPath = "$($mbx.PrimarySmtpAddress):\Calendar"
    try {
        $perm = Get-MailboxFolderPermission -Identity $calendarPath -User $Delegate -ErrorAction Stop
        [PSCustomObject]@{
            Mailbox      = $mbx.PrimarySmtpAddress
            CalendarPath = $calendarPath
            User         = $perm.User
            AccessRights = $perm.AccessRights -join ", "
        }
    } catch {}
}

# Output results
$results | Format-Table -AutoSize