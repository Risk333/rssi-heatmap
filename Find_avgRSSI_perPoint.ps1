# By - Ravi, Vasu, Vatsal
# powershell.exe -noprofile -executionpolicy bypass -file .\Find_avgRSSI_perPoint.ps1

$exePath    = ".\WifiInfoView.exe"
$saveDir    = ".\WiFiMeasurements"
$targetSSID = "IIT-Mandi-WiFi"
$maxFreq    = 2.5
$samples  = 5
$interval   = 1

# Ensure output folder exists
if (-not (Test-Path $saveDir)) {
    New-Item -ItemType Directory -Path $saveDir | Out-Null
}

Write-Host "`n=== WiFi RSSI Mapper (Best-Signal Mode) ==="
Write-Host "SSID: $targetSSID   |   2.4 GHz < $maxFreq MHz"
Write-Host "Snapshots + log → $saveDir`n"

while ($true) {
    Read-Host "Press [Enter] to start a $samples-sample measurement (Ctrl+C to exit)"
    $ts           = Get-Date -Format "yyyyMMdd_HHmmss"
    $snapshotFile = Join-Path $saveDir "snapshot_$ts.csv"
    $logFile      = Join-Path $saveDir "average_rssi.log"

    # Arrays to collect per-interval bests
    $bestRSSIs = @()
    $bestMACs  = @()

    # Write CSV header once
    $header = @(
        "SSID",
        "MAC Address",
        "PHY Type",
        "RSSI",
        "Signal Quality",
        "Average Signal Quality",
        "Frequency",
        "Channel",
        "Information Size",
        "Elements Count",
        "Company",
        "Router Model",
        "Router Name",
        "Security",
        "Cipher",
        "Maximum Speed",
        "Channel Width",
        "Channels Range",
        "BSS Type",
        "WPS Support",
        "First Detection",
        "Last Detection",
        "Detection Count",
        "Start Time",
        "Minimum Signal Quality",
        "Maximum Signal Quality",
        "802.11 Standards",
        "Connected",
        "Stations Count",
        "Channel Utilization",
        "Country Code",
        "Description",
        "MAC Group"
        ) -join ","
    $columnCount = ($header -split ",").Count
    $emptyLine   = @("," * ($columnCount - 1)) -join ""

    $header | Out-File -FilePath $snapshotFile -Encoding ASCII

    Write-Host "`nTaking $samples snapshots..."

    for ($i = 1; $i -le $samples; $i++) {
        Write-Host "Snapshot #$i..."

        $tmp = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName() + ".csv")
        Get-Process WifiInfoView -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue

        Start-Process -FilePath $exePath `
                      -ArgumentList "/scomma `"$tmp`" /NoGui /ExitWhenDone" `
                      -NoNewWindow -Wait

        Start-Sleep -Milliseconds 200

        if (Test-Path $tmp) {
            try {
                $rows = Import-Csv $tmp |
                    Where-Object {
                        ($_.SSID -eq $targetSSID) -and
                        ([int]$_.Frequency -lt $maxFreq)
                    } |
                    Sort-Object -Property "MAC Address"
            }
            catch {
                Write-Warning "Failed to parse snapshot #$i"
                $rows = @()
            }
        }
        else {
            Write-Warning "Snapshot file missing at #$i"
            $rows = @()
        }

        if ($rows.Count -gt 0) {
            $bestRow = $rows | Sort-Object -Property { [int]$_.RSSI } -Descending | Select-Object -First 1
            $bestRSSIs += [int]$bestRow.RSSI
            $bestMACs  += $bestRow."MAC Address"
        }
        else {
            $bestRSSIs += $null
            $bestMACs  += "NONE"
        }

        $rows | Export-Csv -NoTypeInformation -Append -Path $snapshotFile
        Add-Content -Path $snapshotFile -Value $emptyLine
        Remove-Item $tmp -ErrorAction SilentlyContinue

        Start-Sleep -Seconds $interval
    }

    # Post processing
    $validRSSIs = @()
    $macAndRssi = @()

    for ($j = 0; $j -lt $samples; $j++) {
        if ($bestRSSIs[$j] -ne $null) {
            $validRSSIs += $bestRSSIs[$j]
            $macAndRssi += "$($bestMACs[$j]):$($bestRSSIs[$j])"
        }
        else {
            $macAndRssi += "NONE:N/A"
        }
    }

    $avgBest = if ($validRSSIs.Count -gt 0) {
        [math]::Round(($validRSSIs | Measure-Object -Average).Average, 2)
    } else { "N/A" }

    $entry = "$ts , AvgBestRSSI = $avgBest dBm , $samples samples , Best MACs = " + ($macAndRssi -join " ; ")

    Write-Host "`n>>> $entry"
    Add-Content -Path $logFile -Value $entry
    Write-Host "Logged to: $logFile`n"
}
