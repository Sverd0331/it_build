<#
.SYNOPSIS
This will connect to my Github
.DESCRIPTION

V 1.2
Made this work with a folder structure for organization
Added a question in the beginning to open Github directly
Made it so the script launcher doesn't close unless you say N



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
    [string]$Branch = "main"
)

function Get-ScriptSynopsis {
    param([string]$RawUrl)
    try {
        $content = Invoke-WebRequest -Uri $RawUrl -UseBasicParsing
        $text = $content.Content
        if ($text -match '(?s)\.SYNOPSIS\s*(.+?)(?=\.DESCRIPTION|#>|\.NOTES|\.EXAMPLE|\.PARAMETER)') {
            return ($matches[1].Trim() -replace '\s+', ' ')
        }
    } catch {}
    return "No synopsis found"
}

Write-Host "`nWhat would you like to do?" -ForegroundColor Cyan
Write-Host "1. Open GitHub Repository"
Write-Host "2. Run Script Launcher"
Write-Host "3. Exit`n"
$startupChoice = Read-Host "Choose an option (1/2/3)"

switch ($startupChoice) {
    "1" {
        $repoUrl = "https://github.com/$RepoOwner/$RepoName"
        Start-Process $repoUrl
        return
    }
    "3" {
        Write-Host "Exiting launcher." -ForegroundColor Yellow
        return
    }
}

Write-Host "`nLoading scripts from GitHub..." -ForegroundColor Cyan
$rootUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/contents?ref=$Branch"
$rootItems = Invoke-RestMethod -Uri $rootUrl -Headers @{ "User-Agent" = "PowerShell" }
$displayList = @()

foreach ($item in $rootItems) {
    if ($item.type -eq "dir") {
        $displayList += [PSCustomObject]@{
            Name = "[Folder] $($item.name)"
            Path = $item.path
            Synopsis = "Folder"
            IsFolder = $true
        }
        $folderUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/contents/$($item.path)?ref=$Branch"
        $folderItems = Invoke-RestMethod -Uri $folderUrl -Headers @{ "User-Agent" = "PowerShell" }
        foreach ($f in $folderItems) {
            if ($f.type -eq "file" -and $f.name -like "*.ps1") {
                $rawUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/$($f.path)"
                $synopsis = Get-ScriptSynopsis -RawUrl $rawUrl
                $displayList += [PSCustomObject]@{
                    Name = "    $($f.name)"
                    Path = $f.path
                    Synopsis = $synopsis
                    IsFolder = $false
                }
            }
        }
    }
    elseif ($item.type -eq "file" -and $item.name -like "*.ps1") {
        $rawUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/$($item.path)"
        $synopsis = Get-ScriptSynopsis -RawUrl $rawUrl
        $displayList += [PSCustomObject]@{
            Name = $item.name
            Path = $item.path
            Synopsis = $synopsis
            IsFolder = $false
        }
    }
}

Write-Host "Scripts loaded. Opening launcher..." -ForegroundColor Green

while ($true) {
    $selection = $displayList | Out-GridView -Title "Scripts by Folder" -PassThru
    if (-not $selection) { break }
    if (-not $selection.IsFolder) {
        if ($startupChoice -eq "2") {
            $rawUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/$($selection.Path)"
            $tempPath = Join-Path $env:TEMP ($selection.Path.Split('/')[-1])
            Invoke-WebRequest -Uri $rawUrl -OutFile $tempPath -UseBasicParsing
            Unblock-File -Path $tempPath
            Start-Process powershell.exe -ArgumentList "-NoExit", "-File `"$tempPath`""
        }
        if ($startupChoice -eq "1") {
            $githubUrl = "https://github.com/$RepoOwner/$RepoName/blob/$Branch/$($selection.Path)"
            Start-Process $githubUrl
        }
    }
    $again = Read-Host "Run another script? (Y/N)"
    if ($again -notmatch '^(Y|y)$') { break }
}

Write-Host "Launcher closed." -ForegroundColor Yellow
