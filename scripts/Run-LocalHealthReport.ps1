#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Phase 1 entry point: local health check and report generation (no Azure).
.EXAMPLE
    ./scripts/Run-LocalHealthReport.ps1 -ConfigPath ./config/health-config.example.json
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..' 'config' 'health-config.example.json'),

    [Parameter()]
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $RepositoryRoot 'src' 'AzInfraMonitor' 'AzInfraMonitor.psm1'
if (-not (Test-Path -LiteralPath $modulePath)) {
    throw "Module not found at $modulePath"
}

Import-Module $modulePath -Force

$result = Invoke-LocalHealthPipeline -ConfigPath $ConfigPath -RepositoryRoot $RepositoryRoot

Write-Host "Reports written:"
$result.reportPaths | ForEach-Object { Write-Host "  $_" }

if ($result.thresholdResults.alerts.Count -eq 0) {
    Write-Host 'All metrics within configured thresholds.' -ForegroundColor Green
}

exit $result.exitCode
