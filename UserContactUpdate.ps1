<#
Update users contacts infromation in Entra
Run as Admin if you need to install modules
If will ask you the users email
ask you what field you want to update (enter numerical value)
Ask if you want to update another field
if not
ask you if you want to update another user
if not exit
#>


# 1. Install & Import Modules

$modules = @("Microsoft.Graph.Users")

foreach ($m in $modules) {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing module $m"
        Install-Module $m -Force -Scope CurrentUser
    }
    Import-Module $m -Force
}


# 2. Connect to Microsoft Graph

Write-Host "Connecting to Microsoft Graph"
Connect-MgGraph -Scopes "User.ReadWrite.All"
Write-Host "Connected.`n"


# 3. Field Map

$fieldMap = @{
    "1" = @{ Label = "First Name";      GraphField = "GivenName" }
    "2" = @{ Label = "Last Name";       GraphField = "Surname" }
    "3" = @{ Label = "Display Name";    GraphField = "DisplayName" }
    "4" = @{ Label = "Job Title";       GraphField = "JobTitle" }
    "5" = @{ Label = "Department";      GraphField = "Department" }
    "6" = @{ Label = "Office";          GraphField = "OfficeLocation" }
    "7" = @{ Label = "Office Phone";    GraphField = "BusinessPhones" }
    "8" = @{ Label = "Fax Number";      GraphField = "FaxNumber" }
    "9" = @{ Label = "Mobile Phone";    GraphField = "MobilePhone" }
    "10" = @{ Label = "Street Address"; GraphField = "StreetAddress" }
}

function Show-FieldMenu {
    Write-Host "`nSelect a field to update:"


    $sortedKeys = $fieldMap.Keys |
        Where-Object { $_ -match '^\d+$' } |
        Sort-Object { [int]$_ }

    foreach ($key in $sortedKeys) {
        Write-Host "$key. $($fieldMap[$key].Label)"
    }

    Write-Host "X. Exit field updates"
}


# 4. Main Loop
while ($true) {

    $userUPN = Read-Host "`nEnter the user's UPN (or X to exit)"
    if ($userUPN -eq "X") { break }

    try {
        $user = Get-MgUser -UserId $userUPN -ErrorAction Stop
        Write-Host "Loaded user: $($user.DisplayName)`n"
    }
    catch {
        Write-Host "User not found. Try again."
        continue
    }

    while ($true) {
        Show-FieldMenu
        $choice = Read-Host "Enter choice"

        if ($choice -eq "X") { break }
        if (-not $fieldMap.ContainsKey($choice)) {
            Write-Host "Invalid choice."
            continue
        }

        $label = $fieldMap[$choice].Label
        $graphField = $fieldMap[$choice].GraphField

        $newValue = Read-Host "Enter new value for $label"

        if ($graphField -eq "BusinessPhones") {
            $body = @{ BusinessPhones = @($newValue) }
        }
        else {
            $body = @{ $graphField = $newValue }
        }

        try {
            Update-MgUser -UserId $userUPN -BodyParameter $body
            Write-Host "$label updated successfully.`n"
        }
        catch {
            Write-Host ("Failed to update {0}: {1}" -f $label, $_)
        }

        $again = Read-Host "Update another field for this user? (Y/N)"
        if ($again -ne "Y") { break }
    }

    $anotherUser = Read-Host "Update another user? (Y/N)"
    if ($anotherUser -ne "Y") { break }
}

Write-Host "`nDone."