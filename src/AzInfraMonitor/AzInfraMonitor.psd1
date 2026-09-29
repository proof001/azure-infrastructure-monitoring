@{
    RootModule        = 'AzInfraMonitor.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'Proof Higgins'
    Description       = 'Phase 1 local health monitoring (no Azure). Azure integration is Phase 2+ only.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Test-HealthConfig'
        'Get-LocalHealthMetrics'
        'Export-HealthReportJson'
        'Export-HealthReportHtml'
        'Test-HealthThresholds'
        'Invoke-LocalHealthPipeline'
    )
    PrivateData       = @{
        PSData = @{
            Tags = @('DevOps', 'Monitoring', 'Local', 'Phase1')
        }
    }
}
