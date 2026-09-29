function Invoke-LocalHealthPipeline {
    <#
    .SYNOPSIS
        End-to-end Phase 1 run: validate config, collect metrics, evaluate thresholds, write reports.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [Parameter()]
        [string]$RepositoryRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    )

    $null = Test-HealthConfig -Path $ConfigPath
    $config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json

    $checks = @{
        includeCpu    = $true
        includeMemory = $true
        includeDisk   = $true
    }
    if ($config.checks) {
        if ($null -ne $config.checks.includeCpu) { $checks.includeCpu = [bool]$config.checks.includeCpu }
        if ($null -ne $config.checks.includeMemory) { $checks.includeMemory = [bool]$config.checks.includeMemory }
        if ($null -ne $config.checks.includeDisk) { $checks.includeDisk = [bool]$config.checks.includeDisk }
    }

    $metrics = Get-LocalHealthMetrics -Checks $checks
    $thresholdResults = Test-HealthThresholds -Metrics $metrics -Thresholds $config.thresholds -PassThru

    $outputDir = $config.reporting.outputDirectory
    if (-not [System.IO.Path]::IsPathRooted($outputDir)) {
        $outputDir = Join-Path $RepositoryRoot $outputDir
    }

    $prefix = if ($config.reporting.fileNamePrefix) { $config.reporting.fileNamePrefix } else { 'health-report' }
    $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
    $baseName = "${prefix}-${stamp}"

    $reportObject = [pscustomobject]@{
        collectedAtUtc   = $metrics.collectedAtUtc
        hostname         = $metrics.hostname
        platform         = $metrics.platform
        phase            = $metrics.phase
        cpuPercent       = $metrics.cpuPercent
        memoryPercent    = $metrics.memoryPercent
        diskPercent      = $metrics.diskPercent
        thresholdResults = $thresholdResults
    }

    $written = @()
    $formats = @($config.reporting.formats)
    if ($formats.Count -eq 0) { $formats = @('json') }

    foreach ($format in $formats) {
        switch ($format.ToLowerInvariant()) {
            'json' {
                $path = Join-Path $outputDir "$baseName.json"
                $written += Export-HealthReportJson -HealthData $reportObject -OutputPath $path
            }
            'html' {
                $path = Join-Path $outputDir "$baseName.html"
                $written += Export-HealthReportHtml -HealthData $metrics -OutputPath $path -ThresholdResults $thresholdResults
            }
        }
    }

    return [pscustomobject]@{
        metrics          = $metrics
        thresholdResults = $thresholdResults
        reportPaths      = $written
        exitCode         = $thresholdResults.exitCode
    }
}
