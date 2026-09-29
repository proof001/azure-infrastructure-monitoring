function Test-HealthThresholds {
    <#
    .SYNOPSIS
        Compares metrics to config thresholds; writes alerts to the host and returns structured results.
    .OUTPUTS
        Exit code convention for scripts: 0 ok/warning-only, 1 critical (caller may exit).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Metrics,

        [Parameter(Mandatory)]
        [object]$Thresholds,

        [switch]$PassThru
    )

    $alerts = [System.Collections.Generic.List[object]]::new()
    $maxSeverity = 'ok'

    function Add-Alert {
        param([string]$Severity, [string]$Message)
        $alerts.Add([pscustomobject]@{ severity = $Severity; message = $Message })
        $script:maxSeverity = switch ($Severity) {
            'critical' { 'critical' }
            'warning' {
                if ($script:maxSeverity -ne 'critical') { 'warning' } else { $script:maxSeverity }
            }
            default { $script:maxSeverity }
        }
        $color = switch ($Severity) {
            'critical' { 'Red' }
            'warning' { 'Yellow' }
            default { 'Gray' }
        }
        Write-Host "[$Severity] $Message" -ForegroundColor $color
    }

    if ($null -ne $Metrics.cpuPercent) {
        if ($Metrics.cpuPercent -ge $Thresholds.cpuPercentCritical) {
            Add-Alert -Severity 'critical' -Message "CPU at $($Metrics.cpuPercent)% (critical >= $($Thresholds.cpuPercentCritical)%)"
        }
        elseif ($Metrics.cpuPercent -ge $Thresholds.cpuPercentWarning) {
            Add-Alert -Severity 'warning' -Message "CPU at $($Metrics.cpuPercent)% (warning >= $($Thresholds.cpuPercentWarning)%)"
        }
    }

    if ($null -ne $Metrics.memoryPercent) {
        if ($Metrics.memoryPercent -ge $Thresholds.memoryPercentCritical) {
            Add-Alert -Severity 'critical' -Message "Memory at $($Metrics.memoryPercent)% (critical >= $($Thresholds.memoryPercentCritical)%)"
        }
        elseif ($Metrics.memoryPercent -ge $Thresholds.memoryPercentWarning) {
            Add-Alert -Severity 'warning' -Message "Memory at $($Metrics.memoryPercent)% (warning >= $($Thresholds.memoryPercentWarning)%)"
        }
    }

    if ($null -ne $Metrics.diskPercent) {
        if ($Metrics.diskPercent -ge $Thresholds.diskPercentCritical) {
            Add-Alert -Severity 'critical' -Message "Disk at $($Metrics.diskPercent)% (critical >= $($Thresholds.diskPercentCritical)%)"
        }
        elseif ($Metrics.diskPercent -ge $Thresholds.diskPercentWarning) {
            Add-Alert -Severity 'warning' -Message "Disk at $($Metrics.diskPercent)% (warning >= $($Thresholds.diskPercentWarning)%)"
        }
    }

    $result = [pscustomobject]@{
        overallStatus = $maxSeverity
        alerts        = $alerts.ToArray()
        exitCode      = if ($maxSeverity -eq 'critical') { 1 } else { 0 }
    }

    if ($PassThru) {
        return $result
    }

    return $result.exitCode -eq 0
}
