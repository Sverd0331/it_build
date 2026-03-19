<#
.SYNOPSIS
This will connect to my Github
.DESCRIPTION
It pulls up a UI where you can select the scripts to run
This will allow you to run most scripts without referencing github
This may not work for ALL scripts. I will be going through them and adding the modules they need to verify dependencies come with the script
Will also be adding . SYNOPSIS to make them easier to sort

#>
param(
    [string]$RepoOwner = "Sverd0331",
    [string]$RepoName = "it_build",
    [string]$Branch = "main"
)

function Get-ScriptSynopsis {
    param([string]$RawUrl)

    try {
        $content = Invoke-WebRequest -Uri $RawUrl -UseBasicParsing
        $text = $content.Content

        if ($text -match '(?s)\.SYNOPSIS\s*(.+?)(?=\.\w+|#>)') {
            return ($matches[1].Trim() -replace '\s+', ' ')
        }
    }
    catch {}

    return "No synopsis found"
}

function Get-ScriptDescription {
    param([string]$RawUrl)

    try {
        $content = Invoke-WebRequest -Uri $RawUrl -UseBasicParsing
        $text = $content.Content

        if ($text -match '(?s)\.DESCRIPTION\s*(.+?)(?=\.\w+|#>)') {
            return ($matches[1].Trim() -replace '\s+', ' ')
        }
    }
    catch {}

    return "No description found"
}

$apiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/contents?ref=$Branch"
$files = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }

$psScripts = $files | Where-Object { $_.name -like "*.ps1" }

$scriptList = foreach ($file in $psScripts) {
    [PSCustomObject]@{
        Name        = $file.name
        Synopsis    = Get-ScriptSynopsis $file.download_url
        Description = Get-ScriptDescription $file.download_url
        Path        = $file.path
        Url         = $file.download_url
    }
}

$selection = $scriptList | Out-GridView -Title "Select a script to run" -PassThru
if (-not $selection) { exit }

$tempPath = Join-Path $env:TEMP $selection.Name
Invoke-WebRequest -Uri $selection.Url -OutFile $tempPath

Unblock-File -Path $tempPath

& $tempPath
Write-Host "Running $($selection.Name) from GitHub..."
& $tempPath
