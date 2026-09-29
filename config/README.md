# Configuration (Phase 1)

| File | Purpose |
|------|---------|
| `health-config.example.json` | **EXAMPLE ONLY** — safe to commit; copy to `health-config.local.json` for local overrides (gitignored). |

Validation is performed by `Test-HealthConfig` in the `AzInfraMonitor` module. Phase 1 does not load secrets or Azure connection settings from this directory.
