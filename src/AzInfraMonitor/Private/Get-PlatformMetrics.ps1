function Get-PlatformCpuPercent {
    if ($IsWindows) {
        $load = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop |
            Measure-Object -Property LoadPercentage -Average
        return [math]::Round($load.Average, 2)
    }

    if ($IsLinux) {
        $line = Get-Content -Path '/proc/loadavg' -ErrorAction Stop | Select-Object -First 1
        $parts = $line -split '\s+'
        $load1 = [double]$parts[0]
        $cpuCount = (Get-Content '/proc/cpuinfo' | Select-String '^processor' | Measure-Object).Count
        if ($cpuCount -lt 1) { $cpuCount = 1 }
        $percent = ($load1 / $cpuCount) * 100
        return [math]::Round([math]::Min($percent, 100), 2)
    }

    if ($IsMacOS) {
        $line = (& sysctl -n vm.loadavg 2>$null) -replace '[{}]', ''
        if ($line) {
            $load1 = [double](($line -split '\s+')[0])
            $cpuCount = [int](& sysctl -n hw.ncpu 2>$null)
            if ($cpuCount -lt 1) { $cpuCount = 1 }
            return [math]::Round([math]::Min(($load1 / $cpuCount) * 100, 100), 2)
        }
    }

    return 0.0
}

function Get-PlatformMemoryPercent {
    if ($IsWindows) {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $total = [double]$os.TotalVisibleMemorySize
        $free = [double]$os.FreePhysicalMemory
        if ($total -le 0) { return 0.0 }
        $usedPercent = (($total - $free) / $total) * 100
        return [math]::Round($usedPercent, 2)
    }

    if ($IsLinux) {
        $mem = @{}
        Get-Content '/proc/meminfo' | ForEach-Object {
            if ($_ -match '^(\w+):\s+(\d+)') {
                $mem[$Matches[1]] = [double]$Matches[2]
            }
        }
        $total = $mem['MemTotal']
        $available = if ($mem.ContainsKey('MemAvailable')) { $mem['MemAvailable'] } else { $mem['MemFree'] }
        if ($total -le 0) { return 0.0 }
        return [math]::Round((($total - $available) / $total) * 100, 2)
    }

    if ($IsMacOS) {
        $pageSize = [uint64](& sysctl -n hw.pagesize 2>$null)
        $stats = & vm_stat 2>$null
        if (-not $stats) { return 0.0 }
        $pages = @{}
        foreach ($row in $stats) {
            if ($row -match '^Pages (\w+(?: \w+)?):\s+(\d+)') {
                $pages[$Matches[1]] = [uint64]$Matches[2]
            }
        }
        $free = ($pages['free'] + $pages['inactive']) * $pageSize
        $totalLine = (& sysctl -n hw.memsize 2>$null)
        $total = [double]$totalLine
        if ($total -le 0) { return 0.0 }
        return [math]::Round((($total - $free) / $total) * 100, 2)
    }

    return 0.0
}

function Get-PlatformDiskPercent {
    param(
        [string]$Path = '/'
    )

    if ($IsWindows) {
        $drive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
        if (-not $drive) {
            $drive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction Stop | Select-Object -First 1
        }
        if ($drive.Size -le 0) { return 0.0 }
        $used = $drive.Size - $drive.FreeSpace
        return [math]::Round(($used / $drive.Size) * 100, 2)
    }

    $dfOutput = & df -k $Path 2>$null | Select-Object -Skip 1 -First 1
    if ($dfOutput -match '\s+(\d+)%') {
        return [double]$Matches[1]
    }

    return 0.0
}
