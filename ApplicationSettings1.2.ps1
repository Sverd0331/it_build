<# 
V1.2
tested 3/12/26
    CURRENT BUGS:
    DISABLED THE ADOBE INSTALLER
    DUE TO THE NEW WAY CREATIVE CLOUD INSTALLS IT REQUIRES A SIGN IN JUST TO DOWNLOAD
    THIS PREVENTS THE SCRIPT FROM RUNNING
    WILL BE CHECKING ADOBE DOCUMENTATION TO FIND A WORK AROUND
    
    Changes made:
    Updated the URL for Microsoft uninstaller 
    This was failing due to microsoft changing the URL

    Updated the slack install to be once per user
    Slack is a user level install

    Updated the widget removal
    After log off and back in the widgets removed

This is the silent install script to utilize with Intune
You can run as a powersehll script policy or package as a win32 app using the below tool
to add to intune as a win32 app use the https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool
instead of adding the application you will add this as a .ps1
the install cmd for will be 
%SystemRoot%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoLogo -NoProfile -WindowStyle Hidden -File "%~dp0install.ps1"
#>


# Ensure $PSScriptRoot is populated
if (-not $PSScriptRoot) {
    try { $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
    catch { $PSScriptRoot = Get-Location }
}

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"


# Office Removal (ODT Download)


try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $TempPath = Join-Path $env:TEMP "ODT"
    if (!(Test-Path $TempPath)) { New-Item -ItemType Directory -Path $TempPath | Out-Null }

    $ODTExe = Join-Path $TempPath "setup.exe"
    $XMLPath = Join-Path $TempPath "uninstall.xml"
    $url = "https://officecdn.microsoft.com/pr/wsus/setup.exe"

    if (Test-Path $ODTExe) { Remove-Item $ODTExe -Force }

    # Download ODT silently
    $fileStream = [System.IO.File]::Create($ODTExe)
    $fileStream.Close()

    $request = [System.Net.HttpWebRequest]::Create($url)
    $response = $request.GetResponse()
    $stream = $response.GetResponseStream()
    $buffer = New-Object byte[] 65536
    $fileStream = New-Object System.IO.FileStream($ODTExe, [System.IO.FileMode]::Append)

    while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $fileStream.Write($buffer, 0, $bytesRead)
    }

    $fileStream.Close()
    $stream.Close()
    $response.Close()

@"
<Configuration>
  <Remove All="TRUE" />
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
"@ | Out-File -FilePath $XMLPath -Encoding UTF8 -Force

    Start-Process -FilePath $ODTExe -ArgumentList "/configure `"$XMLPath`"" -Wait
}
catch { }


# Winget Installs


$apps = @(
    "Google.Chrome",
    "Microsoft.Teams",
    "Microsoft.Office"
)

foreach ($app in $apps) {
    try {
        winget install -e --id $app --source winget --accept-source-agreements --accept-package-agreements | Out-Null 2>&1
    }
    catch { }
}


# Slack (once per user)


try {
    $User = (Get-CimInstance Win32_ComputerSystem).UserName
    if ($User) {
        $LocalUser = $User.Split('\')[-1]
        $SlackPath = "C:\Users\$LocalUser\AppData\Local\slack\slack.exe"

        if (!(Test-Path $SlackPath)) {
            try {
                winget install -e --id SlackTechnologies.Slack --source winget --accept-source-agreements --accept-package-agreements | Out-Null 2>&1
            }
            catch { }
        }
    }
}
catch { }


# Taskbar + Widgets Disable


try {
    $User = (Get-CimInstance Win32_ComputerSystem).UserName
    if ($User) {
        $SID = (New-Object System.Security.Principal.NTAccount($User)).Translate([System.Security.Principal.SecurityIdentifier]).Value
        $UserHive = "Registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

        # Task View
        New-ItemProperty -Path $UserHive -Name "ShowTaskViewButton" -Value 0 -PropertyType DWord -Force | Out-Null

        # Widgets (policy)
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Force | Out-Null
        New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowWidgets" -Value 0 -PropertyType DWord -Force | Out-Null

        # Widgets (remove app)
        Get-AppxPackage -AllUsers *WebExperience* | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like "*WebExperience*"} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

        # Widgets (HKCU toggle)
        New-ItemProperty -Path $UserHive -Name "TaskbarDa" -Value 0 -PropertyType DWord -Force | Out-Null

        # Taskbar alignment
        New-ItemProperty -Path $UserHive -Name "TaskbarAl" -Value 0 -PropertyType DWord -Force | Out-Null

        # Restart Explorer
        Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}
catch { }


# End

exit 0
