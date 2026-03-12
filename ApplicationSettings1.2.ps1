<# 
V1.3
tested 3/12/26
    Adobe changes
    -Now needs to be packaged from the adobe admin console
    -Reason is adobe create cloud is adobes authentication broker
    -in https://adminconsole.adobe.com/
    -packages
    -create package
    -select creative cloud and adobe

    1.3 Changes made:
    Added battery settings
    
    1.2 Changes made:
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

Start-Sleep -Seconds 2

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

    Start-Sleep -Seconds 2
    Start-Process -FilePath $ODTExe -ArgumentList "/configure `"$XMLPath`"" -Wait
    Start-Sleep -Seconds 2
}
catch { }

# Winget Installs

Start-Sleep -Seconds 2

$apps = @(
    "Google.Chrome",
    "Microsoft.Teams",
    "Microsoft.Office"
)

foreach ($app in $apps) {
    try {
        winget install -e --id $app --source winget --accept-source-agreements --accept-package-agreements | Out-Null 2>&1
        Start-Sleep -Seconds 2
    }
    catch { }
}

# Slack (once per user)

Start-Sleep -Seconds 2

try {
    $User = (Get-CimInstance Win32_ComputerSystem).UserName
    if ($User) {
        $LocalUser = $User.Split('\')[-1]
        $SlackPath = "C:\Users\$LocalUser\AppData\Local\slack\slack.exe"

        if (!(Test-Path $SlackPath)) {
            try {
                winget install -e --id SlackTechnologies.Slack --source winget --accept-source-agreements --accept-package-agreements | Out-Null 2>&1
                Start-Sleep -Seconds 2
            }
            catch { }
        }
    }
}
catch { }


# Power Settings added with V1.3

Start-Sleep -Seconds 2

# Lid behavior
powercfg /setACvalueIndex scheme_current sub_buttons lidAction 0
Start-Sleep -Seconds 2

powercfg /setDCvalueIndex scheme_current sub_buttons lidAction 1
Start-Sleep -Seconds 2

# Display timeout
powercfg /CHANGE monitor-timeout-ac 60   # Plugged in: 1 hour
Start-Sleep -Seconds 2

powercfg /CHANGE monitor-timeout-dc 20   # On battery: 20 minutes
Start-Sleep -Seconds 2

# Sleep timeout
powercfg /CHANGE standby-timeout-ac 0    # Plugged in: Never
Start-Sleep -Seconds 2

powercfg /CHANGE standby-timeout-dc 30   # On battery: 30 minutes
Start-Sleep -Seconds 2

# Apply scheme
powercfg /SETACTIVE SCHEME_CURRENT
Start-Sleep -Seconds 2

# Taskbar + Widgets Disable

Start-Sleep -Seconds 2

try {
    $User = (Get-CimInstance Win32_ComputerSystem).UserName
    if ($User) {
        $SID = (New-Object System.Security.Principal.NTAccount($User)).Translate([System.Security.Principal.SecurityIdentifier]).Value
        $UserHive = "Registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

        # Task View
        New-ItemProperty -Path $UserHive -Name "ShowTaskViewButton" -Value 0 -PropertyType DWord -Force | Out-Null
        Start-Sleep -Seconds 1

        # Widgets (policy)
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Force | Out-Null
        New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowWidgets" -Value 0 -PropertyType DWord -Force | Out-Null
        Start-Sleep -Seconds 1

        # Widgets (remove app)
        Get-AppxPackage -AllUsers *WebExperience* | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2

        Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like "*WebExperience*"} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2

        # Widgets (HKCU toggle)
        New-ItemProperty -Path $UserHive -Name "TaskbarDa" -Value 0 -PropertyType DWord -Force | Out-Null
        Start-Sleep -Seconds 1

        # Taskbar alignment
        New-ItemProperty -Path $UserHive -Name "TaskbarAl" -Value 0 -PropertyType DWord -Force | Out-Null
        Start-Sleep -Seconds 1

        # Restart Explorer
        Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
}
catch { }

# End

exit 0

