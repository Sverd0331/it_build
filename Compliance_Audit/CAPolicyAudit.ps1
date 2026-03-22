<#
.SYNOPSIS
Pulls the conditional access policies from the tenant


.DESCRIPTION
Creates a folder on the Desktop
Files are JSON files
Open with Visual Studio code to read
in export State will tell you if the policy is enabled
#>


#Import or install required Graph modules
-
$modules = @(
    "Microsoft.Graph",
    "Microsoft.Graph.Identity.SignIns"
)

foreach ($m in $modules) {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Module $m not found. Installing..." -ForegroundColor Yellow
        Install-Module $m -Scope CurrentUser -Force
    }
}

Import-Module Microsoft.Graph.Identity.SignIns -ErrorAction Stop

#Connect to Microsoft Graph

$scopes = @(
    "Policy.Read.All",
    "Directory.Read.All"
)

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes $scopes

$context = Get-MgContext
if (-not $context.Account) {
    Write-Host "Graph connection failed. Exiting." -ForegroundColor Red
    exit 1
}

Write-Host "Connected as: $($context.Account)" -ForegroundColor Green
Write-Host "Tenant ID:   $($context.TenantId)" -ForegroundColor Green


#Retrieve Conditional Access policies

Write-Host "Retrieving Conditional Access policies..." -ForegroundColor Cyan

$policies = Get-MgIdentityConditionalAccessPolicy -All

if (-not $policies) {
    Write-Host "No Conditional Access policies found." -ForegroundColor Yellow
    exit 0
}


#Prepare Desktop export folder

$desktop = [Environment]::GetFolderPath("Desktop")
$exportPath = Join-Path $desktop "CA_Policies_Export"

if (-not (Test-Path $exportPath)) {
    New-Item -ItemType Directory -Path $exportPath | Out-Null
}

Write-Host "Export folder: $exportPath" -ForegroundColor Cyan


#Export each policy as a JSON file

foreach ($policy in $policies) {

    
    $safeName = ($policy.DisplayName -replace '[^a-zA-Z0-9\- ]','')
    $fileName = Join-Path $exportPath "$safeName.json"

    $policy | ConvertTo-Json -Depth 10 | Out-File -FilePath $fileName -Encoding UTF8

    Write-Host "Exported: $safeName" -ForegroundColor Green
}

Write-Host "Export complete. Files saved to Desktop." -ForegroundColor Cyan


# Disconnect from Graph

Disconnect-MgGraph
Write-Host "Disconnected from Microsoft Graph." -ForegroundColor DarkGray