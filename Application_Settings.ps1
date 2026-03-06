<#

This is the silent install script to utilize with Intune
to add to intune use the https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool
instead of adding the application you will add this as a .ps1
#>
<#  
    Build Script
    Installs:
    - Remove Baked Microsoft 365
    - Install Chrome, Slack, Teams, Office via winget
    - Install Adobe Creative Cloud from URL
    - Disable Task View
    - Disable Widgets
    - Align taskbar to the left to make it appear more like Windows 10
#>

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# 1. Remove Microsoft 365 (Click-to-Run)

$officeProducts = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%Microsoft 365%'" -ErrorAction SilentlyContinue

if ($officeProducts) {
    foreach ($product in $officeProducts) {
        $product.Uninstall() | Out-Null 2>&1
    }
}

<#  
2. Install apps via winget  
more packages can be found here https://winget.run/  
if a package is added don't forget to use quotation marks and add the comma  
#>

$apps = @(
    "Google.Chrome",
    "SlackTechnologies.Slack",
    "Microsoft.Teams",
    "Microsoft.Office"
)

foreach ($app in $apps) {
    winget install -e --id $app --accept-source-agreements --accept-package-agreements | Out-Null 2>&1
}

<#  
3. Install Adobe Creative Cloud from URL  
More installers can be added as needed. Just need to replace everything as it relates to Adobe and replace with _____  
#>

$tempZip = "$env:TEMP\ACCC.zip"
$extractPath = "$env:TEMP\ACCC"

Invoke-WebRequest -Uri "https://ccmdls.adobe.com/AdobeProducts/StandaloneBuilds/ACCC/ESD/6.8.1/865/win64/ACCCx6_8_1_865.zip" -OutFile $tempZip -UseBasicParsing

Expand-Archive -Path $tempZip -DestinationPath $extractPath -Force -ErrorAction SilentlyContinue

$installer = Get-ChildItem -Path $extractPath -Recurse -Filter "*.exe" | Select-Object -First 1

if ($installer) {
    Start-Process $installer.FullName -ArgumentList "--silent" -Wait -WindowStyle Hidden
}

# 4. Disable Task View

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    /v ShowTaskViewButton /t REG_DWORD /d 0 /f > $null 2>&1

# 5. Disable Widgets

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    /v TaskbarDa /t REG_DWORD /d 0 /f > $null 2>&1

# 6. Align Taskbar to the Left

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    /v TaskbarAl /t REG_DWORD /d 0 /f > $null 2>&1

# 7. Restart Explorer to apply changes

Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
