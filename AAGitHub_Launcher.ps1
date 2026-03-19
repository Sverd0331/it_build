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

        # Multi-line .SYNOPSIS extraction
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

        # Multi-line .DESCRIPTION extraction
        if ($text -match '(?s)\.DESCRIPTION\s*(.+?)(?=\.\w+|#>)') {
            return ($matches[1].Trim() -replace '\s+', ' ')
        }
    }
    catch {}

    return "No description found"
}

# Pull file list from GitHub
$apiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/contents?ref=$Branch"
$files = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }

# Filter for PowerShell scripts
$psScripts = $files | Where-Object { $_.name -like "*.ps1" }

# Build table with Name, Synopsis, Description
$scriptList = foreach ($file in $psScripts) {
    $synopsis    = Get-ScriptSynopsis $file.download_url
    $description = Get-ScriptDescription $file.download_url

    [PSCustomObject]@{
        Name        = $file.name
        Synopsis    = $synopsis
        Description = $description
        Path        = $file.path
        Url         = $file.download_url
    }
}

# Display in Out-GridView
$selection = $scriptList | Out-GridView -Title "Select a script to run" -PassThru

if (-not $selection) {
    Write-Host "No script selected."
    exit
}

# Download and run selected script
$tempPath = Join-Path $env:TEMP $selection.Name
Invoke-WebRequest -Uri $selection.Url -OutFile $tempPath

Write-Host "Running $($selection.Name) from GitHub..."
& $tempPath
