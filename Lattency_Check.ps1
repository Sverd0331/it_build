<#
.SYNOPSIS
Latency check
.Description
Pings 8.8.8.8 with timestamp
WiFi troubleshooting 
#>


$target = "8.8.8.8"

1..50 | ForEach-Object {
    $r = Test-Connection $target -Count 1
    Write-Host ("{0}  {1} ms" -f (Get-Date), $r.ResponseTime)
    Start-Sleep -Seconds 1
}
