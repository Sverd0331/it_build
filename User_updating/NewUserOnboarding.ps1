<# this creates a user
starts wil user details
then will ask if you want to copy groups from another user
this does not license
sign into the UI to add license after procurment confirms license is added
this is case sensitive as of 3/5/2026
case insensitive version is being worked on
#>


Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All" -NoWelcome

$tenant = Get-MgOrganization
$proceed = Read-Host "You are connected to tenant: $($tenant.DisplayName). Proceed? (yes/no)"

if ($proceed -ne "yes") {
    Write-Host "Cancelled."
    Disconnect-MgGraph
    exit
}

# Password
$PasswordProfile = @{
    Password = (Read-Host "Enter temporary password" -AsSecureString)
}

# User attributes
$DisplayName  = Read-Host "Enter Display Name"
$MailNickName = Read-Host "Enter Mail Nickname"
$Email        = Read-Host "Enter Requested email address"
$First        = Read-Host "Enter First Name"
$Last         = Read-Host "Enter Last Name"
$Department   = Read-Host "Department"
$JobTitle     = Read-Host "Title"

# Create user
New-MgUser `
    -DisplayName $DisplayName `
    -GivenName $First `
    -Surname $Last `
    -PasswordProfile $PasswordProfile `
    -AccountEnabled $true `
    -MailNickName $MailNickName `
    -UserPrincipalName $Email `
    -Department $Department `
    -JobTitle $JobTitle | Out-Null

Write-Host "User created."

# Prompt for group mirroring
Write-Host "Press ENTER to mirror groups, or ESC to skip."

do {
    $key = [Console]::ReadKey($true)
    if ($key.Key -eq "Escape") {
        Write-Host "Skipping group mirroring."
        Disconnect-MgGraph
        exit
    }
} while ($key.Key -ne "Enter")

Write-Host "Continuing to group mirroring."

# Source user
$user1 = Read-Host "Enter email of user to mirror from"

Write-Host "Copy all group memberships from $user1 to $DisplayName?"
$confirmation = Read-Host "Ready? [y/n]"

if ($confirmation -ne "y") {
    Write-Host "Cancelled."
    Disconnect-MgGraph
    exit
}

# Resolve IDs
$UserId1 = (Get-MgUser -Filter "Mail eq '$user1'" -ConsistencyLevel eventual).Id
$UserId2 = (Get-MgUser -Filter "Mail eq '$Email'" -ConsistencyLevel eventual).Id

if (-not $UserId1) { Write-Host "Source user not found."; exit }
if (-not $UserId2) { Write-Host "New user not found."; exit }

Start-Sleep -Seconds 5

# Mirror groups
$Groups = (Get-MgUserMemberOf -UserId $UserId1).Id

foreach ($Group in $Groups) {
    try {
        New-MgGroupMember -GroupId $Group -DirectoryObjectId $UserId2 -ErrorAction Stop
        Write-Host "Added to group: $Group"
    }
    catch {
        Write-Host "Skipped group $Group ($($_.Exception.Message))"
    }
}

Disconnect-MgGraph
Write-Host "Completed."





