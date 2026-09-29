BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path $script:repoRoot 'src/AzInfraMonitor/AzInfraMonitor.psm1') -Force
}

Describe 'Test-HealthConfig' {
    It 'accepts the example configuration' {
        $example = Join-Path $script:repoRoot 'config/health-config.example.json'
        { Test-HealthConfig -Path $example } | Should -Not -Throw
        Test-HealthConfig -Path $example | Should -Be $true
    }

    It 'rejects invalid JSON' {
        $bad = New-TemporaryFile
        try {
            Set-Content -LiteralPath $bad -Value '{ not json'
            { Test-HealthConfig -Path $bad } | Should -Throw
        }
        finally {
            Remove-Item -LiteralPath $bad -Force -ErrorAction SilentlyContinue
        }
    }

    It 'rejects missing thresholds' {
        $bad = New-TemporaryFile
        try {
            @{ reporting = @{ outputDirectory = 'reports' } } | ConvertTo-Json | Set-Content -LiteralPath $bad
            { Test-HealthConfig -Path $bad } | Should -Throw 'thresholds'
        }
        finally {
            Remove-Item -LiteralPath $bad -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Get-LocalHealthMetrics' {
    It 'returns structured local metrics without calling Azure' {
        $metrics = Get-LocalHealthMetrics
        $metrics.phase | Should -Be '1-local'
        $metrics.hostname | Should -Not -BeNullOrEmpty
        $metrics.cpuPercent | Should -Not -BeNull
        $metrics.memoryPercent | Should -Not -BeNull
        $metrics.diskPercent | Should -Not -BeNull
    }
}

Describe 'Test-HealthThresholds' {
    It 'returns exit code 0 for healthy metrics' {
        $metrics = [pscustomobject]@{
            cpuPercent    = 10
            memoryPercent = 20
            diskPercent   = 30
        }
        $thresholds = [pscustomobject]@{
            cpuPercentWarning    = 80
            cpuPercentCritical   = 95
            memoryPercentWarning = 85
            memoryPercentCritical = 95
            diskPercentWarning   = 80
            diskPercentCritical  = 90
        }
        $result = Test-HealthThresholds -Metrics $metrics -Thresholds $thresholds -PassThru
        $result.overallStatus | Should -Be 'ok'
        $result.exitCode | Should -Be 0
    }

    It 'returns exit code 1 for critical metrics' {
        $metrics = [pscustomobject]@{
            cpuPercent    = 99
            memoryPercent = 20
            diskPercent   = 30
        }
        $thresholds = [pscustomobject]@{
            cpuPercentWarning    = 80
            cpuPercentCritical   = 95
            memoryPercentWarning = 85
            memoryPercentCritical = 95
            diskPercentWarning   = 80
            diskPercentCritical  = 90
        }
        $result = Test-HealthThresholds -Metrics $metrics -Thresholds $thresholds -PassThru
        $result.overallStatus | Should -Be 'critical'
        $result.exitCode | Should -Be 1
    }
}

Describe 'Report writers' {
    It 'writes JSON and HTML files' {
        $temp = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'reports') -Force
        $metrics = Get-LocalHealthMetrics
        $thresholdResults = [pscustomobject]@{
            overallStatus = 'ok'
            alerts        = @()
            exitCode      = 0
        }

        $jsonPath = Join-Path $temp.FullName 'test.json'
        $htmlPath = Join-Path $temp.FullName 'test.html'

        Export-HealthReportJson -HealthData $metrics -OutputPath $jsonPath | Should -Be $jsonPath
        Export-HealthReportHtml -HealthData $metrics -OutputPath $htmlPath -ThresholdResults $thresholdResults | Should -Be $htmlPath

        Test-Path $jsonPath | Should -Be $true
        Test-Path $htmlPath | Should -Be $true
        (Get-Content $jsonPath -Raw) | Should -Match 'reportVersion'
        (Get-Content $htmlPath -Raw) | Should -Match 'Local Health Report'
    }
}

Describe 'Invoke-LocalHealthPipeline' {
    It 'runs end-to-end against the example config' {
        $example = Join-Path $script:repoRoot 'config/health-config.example.json'
        $result = Invoke-LocalHealthPipeline -ConfigPath $example -RepositoryRoot $script:repoRoot
        $result.reportPaths.Count | Should -BeGreaterThan 0
        $result.reportPaths | ForEach-Object { Test-Path $_ | Should -Be $true }
    }
}
