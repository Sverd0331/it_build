<#
This will connect to my Github
It pulls up a UI where you can select the scripts to run
This will allow you to run most scripts without referencing github
This may not work for ALL scripts. I will be going through them and adding the modules they need to verify dependencies come with the script

#>
param(
    [string]$RepoOwner = "sverd0331",
    [string]$RepoName = "it_build",
    [string]$Branch = "main"
)

# 1. Pull file list from GitHub API
$apiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/contents?ref=$Branch"
$files = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }

# 2. Filter for PowerShell scripts
$psScripts = $files | Where-Object { $_.name -like "*.ps1" }

if (-not $psScripts) {
    Write-Host "No PowerShell scripts found in the repo."
    exit
}

# 3. Interactive menu
$selection = $psScripts | Out-GridView -Title "Select a script to run" -PassThru

if (-not $selection) {
    Write-Host "No script selected."
    exit
}

# 4. Download selected script
$tempPath = Join-Path $env:TEMP $selection.name
Invoke-WebRequest -Uri $selection.download_url -OutFile $tempPath

Write-Host "Running $($selection.name) from GitHub..."
Write-Host "Local temp copy: $tempPath"

# 5. Execute
& $tempPath
