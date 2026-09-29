function Test-HealthConfig {
    <#
    .SYNOPSIS
        Validates a health monitoring configuration file (JSON).
    .OUTPUTS
        System.Boolean — $true when valid; throws or writes errors when invalid.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$Path
    )

    $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
    try {
        $config = $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Config is not valid JSON: $($_.Exception.Message)"
    }

    $requiredThresholdKeys = @(
        'cpuPercentWarning', 'cpuPercentCritical'
        'memoryPercentWarning', 'memoryPercentCritical'
        'diskPercentWarning', 'diskPercentCritical'
    )

    if (-not $config.thresholds) {
        throw 'Config missing required object: thresholds'
    }

    foreach ($key in $requiredThresholdKeys) {
        $value = $config.thresholds.$key
        if ($null -eq $value) {
            throw "Config thresholds missing required property: $key"
        }
        if ($value -isnot [int] -and $value -isnot [long] -and $value -isnot [double]) {
            throw "Threshold $key must be numeric"
        }
        if ($value -lt 0 -or $value -gt 100) {
            throw "Threshold $key must be between 0 and 100"
        }
    }

    if ($config.thresholds.cpuPercentWarning -ge $config.thresholds.cpuPercentCritical) {
        throw 'cpuPercentWarning must be less than cpuPercentCritical'
    }
    if ($config.thresholds.memoryPercentWarning -ge $config.thresholds.memoryPercentCritical) {
        throw 'memoryPercentWarning must be less than memoryPercentCritical'
    }
    if ($config.thresholds.diskPercentWarning -ge $config.thresholds.diskPercentCritical) {
        throw 'diskPercentWarning must be less than diskPercentCritical'
    }

    if (-not $config.reporting) {
        throw 'Config missing required object: reporting'
    }
    if ([string]::IsNullOrWhiteSpace($config.reporting.outputDirectory)) {
        throw 'reporting.outputDirectory is required'
    }

    Write-Verbose 'Health configuration validation succeeded.'
    return $true
}
