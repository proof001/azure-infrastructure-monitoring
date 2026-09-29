# Azure Infrastructure and Monitoring Automation

Portfolio project by **Proof Higgins** (IT Systems Administrator → DevOps). This repository automates infrastructure health visibility and reporting. The **repository is public** for portfolio visibility. **Phase 1 is entirely local**: PowerShell collects OS metrics, validates configuration, evaluates thresholds, and writes JSON/HTML reports. Phase 1 does **not** use Azure subscriptions, billing, or deploy any cloud resources.

## Phase 1 scope (current)

| Area | Description |
|------|-------------|
| Local health | CPU, memory, and disk utilization from the host OS (Windows, Linux, or macOS) |
| Configuration | JSON config with validated warning/critical thresholds |
| Reporting | Timestamped JSON and HTML under `reports/` (gitignored output) |
| Alerts | Console messages and script exit codes (`0` = ok/warning, `1` = critical) |
| Quality | Pester unit/integration tests and PSScriptAnalyzer in CI |

**Explicitly out of scope for Phase 1:** `Connect-AzAccount`, ARM/Bicep deploy, Log Analytics, Action Groups, storage of secrets in repo, and any step that creates billable Azure resources.

## Phase 2+ (gated)

Future phases (only after explicit approval) may include Azure Monitor, automated remediation, and optional publication of static reports. Those workflows will be separate branches/jobs and will not run from the default Phase 1 CI pipeline.

## Repository layout

```text
.
├── config/                 # Example config (EXAMPLE only) + README
├── reports/                # Generated reports (.gitkeep only in git)
├── scripts/                # CLI entry points
│   └── Run-LocalHealthReport.ps1
├── src/AzInfraMonitor/     # Phase 1 PowerShell module
├── tests/                  # Pester tests
└── .github/workflows/ci.yml
```

## Prerequisites

- [PowerShell 7+](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)
- Modules (local dev): `Pester` 5.x, `PSScriptAnalyzer` (CI installs these automatically)

## Run locally

From the repository root:

```powershell
# Optional: copy example config and adjust thresholds (local file is gitignored)
Copy-Item ./config/health-config.example.json ./config/health-config.local.json

# Run Phase 1 pipeline (uses example config by default)
./scripts/Run-LocalHealthReport.ps1

# Or specify a config path
./scripts/Run-LocalHealthReport.ps1 -ConfigPath ./config/health-config.local.json
```

Reports appear under `reports/` with a UTC timestamp in the filename. The process exit code is `1` when any metric exceeds a **critical** threshold.

### Run tests and static analysis

```powershell
Install-Module Pester, PSScriptAnalyzer -Scope CurrentUser -Force
Invoke-ScriptAnalyzer -Path ./src, ./scripts -Recurse
Invoke-Pester -Path ./tests
```

## Continuous integration

Workflow: [`.github/workflows/ci.yml`](.github/workflows/ci.yml)

On push and pull requests to `main` (and `cursor/**` branches):

1. **PSScriptAnalyzer** on `src/` and `scripts/` (fails on Error severity)
2. **Pester** on `tests/`

There is **no** deploy job, **no** Azure login, and **no** artifact publish to public endpoints in Phase 1.

## Security and privacy

- This is a **public** portfolio repository: do not commit secrets, API keys, or production connection strings.
- Use `config/health-config.example.json` as a template only; local overrides belong in gitignored `*.local.json` files and must stay out of git.
- Generated reports may contain hostnames and host metrics — treat `reports/` as sensitive if copied off-machine or shared.

## License / attribution

Portfolio demonstration code. Extend and harden before production use.
