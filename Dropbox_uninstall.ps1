<#
Intune Ready Removes Dropbox
Use win 32 wrapper and detection script in repository
Install command
powershell.exe -ExecutionPolicy Bypass -File .\Dropbox_uninstall.ps1
uninstall command
powershell.exe -ExecutionPolicy Bypass -File .\Dropbox_uninstall.ps1
#>


Get-Process "Dropbox" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$uninstallerX86 = "C:\Program Files (x86)\Dropbox\Client\DropboxUninstaller.exe"
$uninstallerX64 = "C:\Program Files\Dropbox\Client\DropboxUninstaller.exe"

foreach ($uninstaller in @($uninstallerX86, $uninstallerX64)) {
    if (Test-Path $uninstaller) {
        Start-Process -FilePath $uninstaller `
            -ArgumentList "/InstallType:MACHINE /SILENT" `
            -WindowStyle Hidden `
            -NoNewWindow `
            -Wait
    }
}


$service = Get-Service "DropboxUpdate" -ErrorAction SilentlyContinue
if ($service) {
    sc.exe stop "DropboxUpdate" | Out-Null
    sc.exe delete "DropboxUpdate" | Out-Null
}


$tasks = @(
    "\DropboxUpdateTaskMachineCore",
    "\DropboxUpdateTaskMachineUA"
)

foreach ($t in $tasks) {
    schtasks.exe /Delete /TN $t /F | Out-Null
}


$updaterPaths = @(
    "C:\Program Files\Dropbox",
    "C:\Program Files (x86)\Dropbox"
)

foreach ($p in $updaterPaths) {
    Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
}


$users = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue
foreach ($u in $users) {
    $local   = Join-Path $u.FullName "AppData\Local\Dropbox"
    $roaming = Join-Path $u.FullName "AppData\Roaming\Dropbox"
    $userShortcut = Join-Path $u.FullName "AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Dropbox.lnk"

    Remove-Item $local -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $roaming -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path $userShortcut) {
        Remove-Item $userShortcut -Force -ErrorAction SilentlyContinue
    }
}


$systemShortcut = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Dropbox.lnk"
if (Test-Path $systemShortcut) {
    Remove-Item $systemShortcut -Force -ErrorAction SilentlyContinue
}


Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Dropbox.exe" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Dropbox" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Dropbox" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "HKLM:\SOFTWARE\Dropbox" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "HKCU:\SOFTWARE\Dropbox" -Recurse -Force -ErrorAction SilentlyContinue

exit 0