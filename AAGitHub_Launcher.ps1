<#
.SYNOPSIS
This will connect to my Github
.DESCRIPTION
WORKING ON WHILE LOOP Some of the WIFI specific scripts are set to close powershell
Will be updating those scripts as I use them to be able to keep the window open

It pulls up a UI where you can select the scripts to run
This will allow you to run most scripts without referencing github
This may not work for ALL scripts. I will be going through them and adding the modules they need to verify dependencies come with the script
Will also be adding .SYNOPSIS to make them easier to sort
#>

param(
    [string]$RepoOwner = "Sverd0331",
    [string]$RepoName  = "it_build",
    [string]$Branch    = "main"
)

function Get-ScriptSynopsis {
    param([string]$RawUrl)

    try {
        $content = Invoke-WebRequest -Uri $RawUrl -UseBasicParsing
        $text = $content.Content

        if ($text -match '(?s)\.SYNOPSIS\s*(.+?)(?=\.DESCRIPTION|#>|\.NOTES|\.EXAMPLE|\.PARAMETER)') {
            return ($matches[1].Trim() -replace '\s+', ' ')
        }
    }
    catch {}

    return "No synopsis found"
}

while ($true) {

    $apiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/contents?ref=$Branch"
    $files = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }

    $psScripts = $files | Where-Object { $_.name -like "*.ps1" }

    $scriptList = foreach ($file in $psScripts) {
        [PSCustomObject]@{
            Name     = $file.name
            Synopsis = Get-ScriptSynopsis $file.download_url
            Path     = $file.path
            Url      = $file.download_url
        }
    }

    $selection = $scriptList | Out-GridView -Title "Select a script to run" -PassThru
    if (-not $selection) { break }

    $tempPath = Join-Path $env:TEMP $selection.Name
    Invoke-WebRequest -Uri $selection.Url -OutFile $tempPath
    Unblock-File -Path $tempPath

    & $tempPath

    $again = Read-Host "Run another script? (Y/N)"
    if ($again -notmatch '^(Y|y)$') { break }
}
