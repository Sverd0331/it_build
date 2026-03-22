#WARNING THIS IS UNTESTED 
#WILL GRANT DELEGATE ACCESS FOR AN EA




























#connect to mcirosoft exchange to run this script
Connect-ExchangeOnline



$user1 = Read-Host "Enter email of Primary user"


$user2 = Read-Host "Enter email of user who is getting permissions"




Add-MailboxFolderPermission -Identity "'$user1':\Calendar" -User $user2 -AccessRights Reviewer 



#Does User need delegate access


$delegateAccess = Read-Host "Does user need delegate access? (Y/N)"






if ($delegateAccess -eq 'Y') {
    # Grant delegate access to the calendar folder
    Set-MailboxFolderPermission -Identity "'$user1':\Calendar" -User $user2 -AccessRights Editor -SharingPermissionFlags Delegate -SendNotificationToUser $true
} else {
    # Grant read-only access to the calendar folder
    Set-MailboxFolderPermission -Identity "'$user1':\Calendar" -User $user2 -AccessRights Reviewer
}


