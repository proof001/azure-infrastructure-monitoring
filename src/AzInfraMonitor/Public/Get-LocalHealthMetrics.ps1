function Get-LocalHealthMetrics {
    <#
    .SYNOPSIS
        Collects OS-local CPU, memory, and disk utilization (no cloud APIs).
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$Checks = @{
            includeCpu    = $true
            includeMemory = $true
            includeDisk   = $true
        }
    )

    $timestamp = (Get-Date).ToUniversalTime().ToString('o')
    $hostName = [System.Environment]::MachineName
    $platform = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } elseif ($IsMacOS) { 'macOS' } else { 'Unknown' }

    $metrics = [ordered]@{
        collectedAtUtc = $timestamp
        hostname       = $hostName
        platform       = $platform
        phase          = '1-local'
        cpuPercent     = $null
        memoryPercent  = $null
        diskPercent    = $null
    }

    if ($Checks.includeCpu -ne $false) {
        $metrics.cpuPercent = Get-PlatformCpuPercent
    }
    if ($Checks.includeMemory -ne $false) {
        $metrics.memoryPercent = Get-PlatformMemoryPercent
    }
    if ($Checks.includeDisk -ne $false) {
        $metrics.diskPercent = Get-PlatformDiskPercent
    }

    return [pscustomobject]$metrics
}
