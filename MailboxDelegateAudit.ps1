<#
V1
Run as admin to confirm modules are installed
Audit all mailbox-level and folder-level permissions for a specified delegate.
Good use case is prior to Claude Co work being enabled

Checks:
- Full Access
- Send As
- Send on Behalf
- Folder-level permissions (Inbox, Calendar, Contacts)
#>


# Install and Import Required Module


Write-Host "Checking for Exchange Online module..."

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "ExchangeOnlineManagement module not found. Installing..."
    Install-Module ExchangeOnlineManagement -Force -Scope CurrentUser
}

Import-Module ExchangeOnlineManagement -Force


# Prompt for Delegate



$DelegateUPN = Read-Host "Enter the Email of the delegate user to audit"


# Connect to Exchange Online


Write-Host "Connecting to Exchange Online"
Connect-ExchangeOnline -ShowBanner:$false


<# 
Retrieve Mailboxes
This will go through the entire tenant, depending on amount of mailboxes it could take some time
V2 will trial with multi threading to make this proccess faster
#>


Write-Host "Retrieving all mailboxes"
$mailboxes = Get-ExoMailbox -ResultSize Unlimited

$results = @()

foreach ($mbx in $mailboxes) {

    $mailboxId = $mbx.PrimarySmtpAddress.ToString()

    
    # Checks Full Access
   
    $fullAccess = Get-ExoMailboxPermission -Identity $mailboxId -ResultSize Unlimited `
        | Where-Object {
            $_.UserPrincipalName -eq $DelegateUPN -and
            $_.AccessRights -contains "FullAccess" -and
            $_.IsInherited -eq $false
        }

    foreach ($fa in $fullAccess) {
        $results += [pscustomobject]@{
            Mailbox        = $mailboxId
            MailboxType    = $mbx.RecipientTypeDetails
            PermissionType = "Full Access"
            Folder         = ""
            Rights         = "FullAccess"
            GrantedTo      = $DelegateUPN
        }
    }

    
    # Checks Send As
    
    $sendAs = Get-ExoRecipientPermission -Identity $mailboxId -ResultSize Unlimited `
        | Where-Object {
            $_.Trustee -eq $DelegateUPN -and
            $_.AccessRights -contains "SendAs"
        }

    foreach ($sa in $sendAs) {
        $results += [pscustomobject]@{
            Mailbox        = $mailboxId
            MailboxType    = $mbx.RecipientTypeDetails
            PermissionType = "Send As"
            Folder         = ""
            Rights         = "SendAs"
            GrantedTo      = $DelegateUPN
        }
    }

    
    # Checks Send on Behalf
    
    if ($mbx.GrantSendOnBehalfTo -contains $DelegateUPN) {
        $results += [pscustomobject]@{
            Mailbox        = $mailboxId
            MailboxType    = $mbx.RecipientTypeDetails
            PermissionType = "Send on Behalf"
            Folder         = ""
            Rights         = "SendOnBehalf"
            GrantedTo      = $DelegateUPN
        }
    }

   
    <# 
    V2 need to fix this as this portion takes the longest time
    --Looking into multi threading
    Folder-Level (Inbox, Calendar, Contacts)
    Warning will populate for multiple reasons
    -Mailbox isn't active
    -System created
    -Resource
    -No folder level structure
    -Too many folders
    The warning prevents the script from stopping and is safe to ignore
    #>

    
    try {
        
        $folders = Get-ExoMailboxFolderPermission -Identity "${mailboxId}:\*" -ResultSize Unlimited -ErrorAction Stop
    }
    catch {
        Write-Warning "Could not enumerate folders for $mailboxId"
        continue
    }

    foreach ($folder in $folders) {
        foreach ($perm in $folder.Permission) {
            if ($perm.User -eq $DelegateUPN) {
                $results += [pscustomobject]@{
                    Mailbox        = $mailboxId
                    MailboxType    = $mbx.RecipientTypeDetails
                    PermissionType = "Folder Permission"
                    Folder         = $folder.FolderName
                    Rights         = ($perm.AccessRights -join ", ")
                    GrantedTo      = $DelegateUPN
                }
            }
        }
    }
}


<# 
Output Results as a table
V2 will output as a file onto the desktop
#>


Write-Host "`n Delegate Permissions Found `n"
$results | Format-Table -AutoSize