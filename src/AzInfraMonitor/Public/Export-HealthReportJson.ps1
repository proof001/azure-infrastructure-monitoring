function Export-HealthReportJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$HealthData,

        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    $directory = Split-Path -Parent $OutputPath
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $payload = @{
        reportVersion    = '1.0'
        generatedAtUtc   = (Get-Date).ToUniversalTime().ToString('o')
        metrics          = $HealthData
        thresholdResults = $null
    }

    if ($HealthData.PSObject.Properties['thresholdResults']) {
        $payload.thresholdResults = $HealthData.thresholdResults
        $payload.metrics = $HealthData | Select-Object * -ExcludeProperty thresholdResults
    }

    $payload | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding utf8
    return $OutputPath
}
