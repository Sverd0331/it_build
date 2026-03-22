<# 
.SYNOPSIS
Gives sames group permissions as another user

.Description
this script connects to the tenant via microsoft graph
it then asks the source user by email
then asks for user you will be copying groups to
as of 3/5/26 error handling has not been tested
case sensitive
#>
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All" -NoWelcome

# Prompt for users
$user1 = Read-Host "Enter email of user to mirror FROM"
$user2 = Read-Host "Enter email of user to mirror TO"

# Confirm
Write-Host "Copy all group memberships from $user1 to $user2 ?"
$confirmation = Read-Host "Proceed? [y/n]"
if ($confirmation -ne "y") { Write-Host "Cancelled."; exit }

# Resolve users
$u1 = Get-MgUser -Filter "mail eq '$user1'" -ConsistencyLevel eventual
$u2 = Get-MgUser -Filter "mail eq '$user2'" -ConsistencyLevel eventual

if (-not $u1) { Write-Host "Source user not found."; exit }
if (-not $u2) { Write-Host "Target user not found."; exit }

$userid1 = $u1.Id
$userid2 = $u2.Id

# Get only groups (exclude roles, AUs, etc.)
$groups = Get-MgUserMemberOf -UserId $userid1 |
    Where-Object { $_.'@odata.type' -eq "#microsoft.graph.group" }

Write-Host "Found $($groups.Count) groups to evaluate."

foreach ($g in $groups) {

    # Skip dynamic groups
    if ($g.GroupTypes -contains "DynamicMembership") {
        Write-Host "Skipping dynamic group: $($g.DisplayName)"
        continue
    }

    # Check if user is already a member
    $already = Get-MgGroupMember -GroupId $g.Id -All |
        Where-Object { $_.Id -eq $userid2 }

    if ($already) {
        Write-Host "Already a member: $($g.DisplayName)"
        continue
    }

    # Add membership
    try {
        New-MgGroupMember -GroupId $g.Id -DirectoryObjectId $userid2 -ErrorAction Stop
        Write-Host "Added to: $($g.DisplayName)"
    }
    catch {
        Write-Host "Failed to add to $($g.DisplayName): $($_.Exception.Message)"
    }
}

Disconnect-MgGraph


