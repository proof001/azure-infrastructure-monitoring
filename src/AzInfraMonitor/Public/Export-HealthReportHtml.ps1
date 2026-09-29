function Export-HealthReportHtml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$HealthData,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [Parameter()]
        [object]$ThresholdResults
    )

    $directory = Split-Path -Parent $OutputPath
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $results = if ($ThresholdResults) { $ThresholdResults } else { $HealthData.thresholdResults }
    $status = if ($results -and $results.overallStatus) { $results.overallStatus } else { 'unknown' }
    $statusClass = switch ($status) {
        'ok' { 'ok' }
        'warning' { 'warn' }
        'critical' { 'crit' }
        default { 'unknown' }
    }

    $rows = @(
        @{ Label = 'Hostname'; Value = $HealthData.hostname }
        @{ Label = 'Platform'; Value = $HealthData.platform }
        @{ Label = 'Collected (UTC)'; Value = $HealthData.collectedAtUtc }
        @{ Label = 'CPU %'; Value = $HealthData.cpuPercent }
        @{ Label = 'Memory %'; Value = $HealthData.memoryPercent }
        @{ Label = 'Disk %'; Value = $HealthData.diskPercent }
    )

    $rowHtml = ($rows | ForEach-Object {
            "<tr><th>$($_.Label)</th><td>$($_.Value)</td></tr>"
        }) -join "`n"

    $alertHtml = ''
    if ($results -and $results.alerts) {
        $items = ($results.alerts | ForEach-Object { "<li>[$($_.severity)] $($_.message)</li>" }) -join "`n"
        $alertHtml = "<h2>Alerts</h2><ul>$items</ul>"
    }

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <title>Local Health Report — Phase 1</title>
  <style>
    body { font-family: system-ui, sans-serif; margin: 2rem; color: #1a1a1a; }
    h1 { font-size: 1.25rem; }
    .badge { display: inline-block; padding: 0.25rem 0.5rem; border-radius: 4px; font-weight: 600; }
    .ok { background: #d1fae5; color: #065f46; }
    .warn { background: #fef3c7; color: #92400e; }
    .crit { background: #fee2e2; color: #991b1b; }
    .unknown { background: #e5e7eb; color: #374151; }
    table { border-collapse: collapse; margin-top: 1rem; }
    th, td { border: 1px solid #d1d5db; padding: 0.5rem 0.75rem; text-align: left; }
    th { background: #f3f4f6; width: 12rem; }
    footer { margin-top: 2rem; font-size: 0.875rem; color: #6b7280; }
  </style>
</head>
<body>
  <h1>Azure Infrastructure &amp; Monitoring — Local Health Report</h1>
  <p>Status: <span class="badge $statusClass">$status</span></p>
  <table>$rowHtml</table>
  $alertHtml
  <footer>Generated locally (Phase 1). No Azure resources queried.</footer>
</body>
</html>
"@

    Set-Content -LiteralPath $OutputPath -Value $html -Encoding utf8
    return $OutputPath
}
