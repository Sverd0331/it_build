<#
.SYNOPSIS
    Wi-Fi signal & roaming monitor


.DESCRIPTION    
    Perfect for checking drops in an AP while roaming office

    Monitors the active Wi-Fi interface, logging:
    - Time, SSID, BSSID, Signal, Channel, RX/TX rate
    - Roaming events (BSSID change)
    - Signal threshold breaches

    Outputs
    - Live console table
    - CSV log file
    Sampling interval in seconds.
    Path to CSV log file.
    Signal (%) below which we flag a warning.

#>

param(
    [int]$IntervalSeconds = 3,
    [string]$LogPath = "$env:USERPROFILE\Desktop\WiFiMonitorLog.csv",
    [int]$SignalWarn = 50
)

Write-Host "Wi-Fi Signal & Roaming Monitor" -ForegroundColor Cyan
Write-Host "Interval: $IntervalSeconds s | Log: $LogPath | Warn < $SignalWarn%" -ForegroundColor DarkGray
Write-Host "Press Ctrl+C to stop.`n"

# Ensure log has header
if (-not (Test-Path $LogPath)) {
    "Timestamp,SSID,BSSID,SignalPercent,Channel,ReceiveRateMbps,TransmitRateMbps,Roamed,Note" |
        Out-File -FilePath $LogPath -Encoding UTF8
}

function Get-WiFiStatus {
    $raw = netsh wlan show interfaces
    if (-not $raw) { return $null }

    $obj = [PSCustomObject]@{
        Timestamp          = Get-Date
        SSID               = $null
        BSSID              = $null
        SignalPercent      = $null
        Channel            = $null
        ReceiveRateMbps    = $null
        TransmitRateMbps   = $null
    }

    foreach ($line in $raw) {
        if ($line -match "^\s*SSID\s*:\s*(.+)$")          { $obj.SSID            = $matches[1].Trim() }
        elseif ($line -match "^\s*BSSID\s*:\s*(.+)$")     { $obj.BSSID           = $matches[1].Trim() }
        elseif ($line -match "^\s*Signal\s*:\s*(\d+)%")   { $obj.SignalPercent   = [int]$matches[1] }
        elseif ($line -match "^\s*Channel\s*:\s*(\d+)")   { $obj.Channel         = [int]$matches[1] }
        elseif ($line -match "^\s*Receive rate\s*:\s*(\d+)\s*Mbps") { $obj.ReceiveRateMbps = [int]$matches[1] }
        elseif ($line -match "^\s*Transmit rate\s*:\s*(\d+)\s*Mbps") { $obj.TransmitRateMbps = [int]$matches[1] }
    }

    if (-not $obj.SSID) { return $null }
    return $obj
}

$lastBssid = $null
$lastSsid  = $null

while ($true) {
    $status = Get-WiFiStatus

    if (-not $status) {
        Write-Host "$(Get-Date -Format HH:mm:ss)  No Wi-Fi interface connected." -ForegroundColor Yellow
        Start-Sleep -Seconds $IntervalSeconds
        continue
    }

    $roamed = $false
    $note   = ""

    if ($lastBssid -and $status.BSSID -ne $lastBssid) {
        $roamed = $true
        $note   = "Roamed from $lastBssid to $($status.BSSID)"
    }

    if ($status.SignalPercent -lt $SignalWarn) {
        if ($note) { $note += " | " }
        $note += "Low signal ($($status.SignalPercent)%)"
    }

    $lastBssid = $status.BSSID
    $lastSsid  = $status.SSID

    # Console output
    $color = if ($status.SignalPercent -ge 70) { "Green" }
             elseif ($status.SignalPercent -ge 50) { "Yellow" }
             else { "Red" }

    $roamFlag = if ($roamed) { "*" } else { " " }

    Write-Host ("{0} [{1}] {2,-20} {3,-18} Sig:{4,3}% Ch:{5,-3} RX:{6,4} TX:{7,4} {8}" -f `
        $status.Timestamp.ToString("HH:mm:ss"),
        $roamFlag,
        $status.SSID,
        $status.BSSID,
        $status.SignalPercent,
        $status.Channel,
        $status.ReceiveRateMbps,
        $status.TransmitRateMbps,
        $note) -ForegroundColor $color

    # CSV log
    $csvLine = ('{0},{1},{2},{3},{4},{5},{6},{7},{8}' -f `
        $status.Timestamp.ToString("o"),
        $status.SSID,
        $status.BSSID,
        $status.SignalPercent,
        $status.Channel,
        $status.ReceiveRateMbps,
        $status.TransmitRateMbps,
        $roamed,
        ($note -replace ',', ';') )

    Add-Content -Path $LogPath -Value $csvLine

    Start-Sleep -Seconds $IntervalSeconds
}