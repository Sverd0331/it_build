# Detection: return 0 when Dropbox is fully removed, 1 when any artifact remains.

$UserDirs = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue

$paths = @(
    "C:\Program Files\Dropbox",
    "C:\Program Files\Dropbox\Client\Dropbox.exe",
    "C:\Program Files (x86)\Dropbox",
    "C:\Program Files (x86)\Dropbox\Client\Dropbox.exe",
    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Dropbox.lnk"
)

foreach ($u in $UserDirs) {
    $paths += Join-Path $u.FullName "AppData\Local\Dropbox"
    $paths += Join-Path $u.FullName "AppData\Roaming\Dropbox"
    $paths += Join-Path $u.FullName "AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Dropbox.lnk"
}


$regKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Dropbox.exe",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Dropbox",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Dropbox",
    "HKLM:\SOFTWARE\Dropbox",
    "HKCU:\SOFTWARE\Dropbox"
)

foreach ($p in $paths) {
    if (Test-Path $p) {
        exit 1  
    }
}

foreach ($rk in $regKeys) {
    if (Test-Path $rk) {
        exit 1  
    }
}

exit 0 