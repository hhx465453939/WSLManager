# WSL Health Monitor Module
# Provides health check, monitoring and diagnostic functions for WSL environment

# Import necessary modules
if (Get-Module WSL-Detection) { Remove-Module WSL-Detection }
Import-Module "$PSScriptRoot\WSL-Detection.psm1" -Force

# WSL service status detection function
function Test-WSLServiceStatus {
    <#
    .SYNOPSIS
    Detect the running status of WSL related services
    
    .DESCRIPTION
    Check WSL service, LxssManager service and related system components status
    
    .PARAMETER Detailed
    Return detailed service information
    
    .EXAMPLE
    Test-WSLServiceStatus
    Test-WSLServiceStatus -Detailed
    #>
    [CmdletBinding()]
    param(
        [switch]$Detailed
    )
    
    Write-Host "Checking WSL service status..." -ForegroundColor Yellow
    
    $serviceStatus = @{
        WSLService = $null
        LxssManager = $null
        HyperV = $null
        VirtualMachinePlatform = $null
        OverallStatus = "Unknown"
    }
    
    # Check WSL service status
    $wslProcess = Get-Process -Name "wsl" -ErrorAction SilentlyContinue
    $serviceStatus.WSLService = if ($wslProcess) { "Running" } else { "Stopped" }
    
    # Check LxssManager service
    $lxssService = Get-Service -Name "LxssManager" -ErrorAction SilentlyContinue
    $serviceStatus.LxssManager = if ($lxssService) { $lxssService.Status.ToString() } else { "NotInstalled" }
    
    # Check Hyper-V status
    $hyperVFeature = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-All" -ErrorAction SilentlyContinue
    $serviceStatus.HyperV = if ($hyperVFeature) { $hyperVFeature.State.ToString() } else { "NotAvailable" }
    
    # Check Virtual Machine Platform
    $vmPlatform = Get-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -ErrorAction SilentlyContinue
    $serviceStatus.VirtualMachinePlatform = if ($vmPlatform) { $vmPlatform.State.ToString() } else { "NotAvailable" }
    
    # Determine overall status
    if ($serviceStatus.LxssManager -eq "Running" -and $serviceStatus.VirtualMachinePlatform -eq "Enabled") {
        $serviceStatus.OverallStatus = "Healthy"
    } elseif ($serviceStatus.LxssManager -eq "Stopped") {
        $serviceStatus.OverallStatus = "Stopped"
    } else {
        $serviceStatus.OverallStatus = "Unhealthy"
    }
    
    if ($Detailed) {
        Write-Host "`n=== WSL Service Detailed Status ===" -ForegroundColor Cyan
        Write-Host "WSL Process Status: $($serviceStatus.WSLService)" -ForegroundColor $(if($serviceStatus.WSLService -eq "Running") {"Green"} else {"Red"})
        Write-Host "LxssManager Service: $($serviceStatus.LxssManager)" -ForegroundColor $(if($serviceStatus.LxssManager -eq "Running") {"Green"} else {"Red"})
        Write-Host "Hyper-V Feature: $($serviceStatus.HyperV)" -ForegroundColor $(if($serviceStatus.HyperV -eq "Enabled") {"Green"} else {"Yellow"})
        Write-Host "Virtual Machine Platform: $($serviceStatus.VirtualMachinePlatform)" -ForegroundColor $(if($serviceStatus.VirtualMachinePlatform -eq "Enabled") {"Green"} else {"Red"})
        Write-Host "Overall Status: $($serviceStatus.OverallStatus)" -ForegroundColor $(if($serviceStatus.OverallStatus -eq "Healthy") {"Green"} else {"Red"})
    }
    
    return $serviceStatus
}

# Memory, CPU and disk usage monitoring function
function Get-WSLResourceUsage {
    <#
    .SYNOPSIS
    Get WSL environment resource usage
    
    .DESCRIPTION
    Monitor WSL related processes memory, CPU usage, and WSL disk space usage
    
    .PARAMETER DistributionName
    Specify the WSL distribution name to monitor
    
    .EXAMPLE
    Get-WSLResourceUsage
    Get-WSLResourceUsage -DistributionName "Ubuntu"
    #>
    [CmdletBinding()]
    param(
        [string]$DistributionName
    )
    
    Write-Host "Collecting WSL resource usage..." -ForegroundColor Yellow
    
    $resourceInfo = @{
        SystemMemory = @{}
        WSLProcesses = @()
        DiskUsage = @{}
        NetworkStatus = @{}
        Timestamp = Get-Date
    }
    
    # Get system memory information
    $memInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $totalMemoryGB = [math]::Round($memInfo.TotalVisibleMemorySize / 1MB, 2)
    $freeMemoryGB = [math]::Round($memInfo.FreePhysicalMemory / 1MB, 2)
    $usedMemoryGB = [math]::Round($totalMemoryGB - $freeMemoryGB, 2)
    
    $resourceInfo.SystemMemory = @{
        TotalGB = $totalMemoryGB
        UsedGB = $usedMemoryGB
        FreeGB = $freeMemoryGB
        UsagePercent = [math]::Round(($usedMemoryGB / $totalMemoryGB) * 100, 1)
    }
    
    # Get WSL related process information
    $wslProcesses = Get-Process | Where-Object { 
        $_.ProcessName -match "wsl|lxss" -or 
        $_.MainWindowTitle -match "WSL|Ubuntu|Debian|SUSE" 
    }
    
    foreach ($proc in $wslProcesses) {
        $resourceInfo.WSLProcesses += @{
            ProcessName = $proc.ProcessName
            PID = $proc.Id
            MemoryMB = [math]::Round($proc.WorkingSet / 1MB, 2)
            StartTime = $proc.StartTime
        }
    }
    
    # Get WSL disk usage
    if (Test-Path "$env:LOCALAPPDATA\Packages") {
        $wslPackages = Get-ChildItem "$env:LOCALAPPDATA\Packages" | Where-Object { $_.Name -match "CanonicalGroupLimited|SUSE|Debian" }
        
        foreach ($package in $wslPackages) {
            $packageSize = 0
            $packageSize = [math]::Round((Get-ChildItem $package.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
            
            $resourceInfo.DiskUsage[$package.Name] = @{
                SizeMB = $packageSize
                Path = $package.FullName
            }
        }
    }
    
    # Check WSL virtual disk files
    $vhdxFiles = Get-ChildItem "$env:LOCALAPPDATA\Docker\wsl" -Filter "*.vhdx" -ErrorAction SilentlyContinue
    if ($vhdxFiles) {
        foreach ($vhdx in $vhdxFiles) {
            $resourceInfo.DiskUsage["VHDX_$($vhdx.BaseName)"] = @{
                SizeMB = [math]::Round($vhdx.Length / 1MB, 2)
                Path = $vhdx.FullName
            }
        }
    }
    
    # Display resource usage summary
    Write-Host "`n=== WSL Resource Usage ===" -ForegroundColor Cyan
    Write-Host "System Memory: $($resourceInfo.SystemMemory.UsedGB)GB / $($resourceInfo.SystemMemory.TotalGB)GB ($($resourceInfo.SystemMemory.UsagePercent)%)" -ForegroundColor $(if($resourceInfo.SystemMemory.UsagePercent -gt 80) {"Red"} elseif($resourceInfo.SystemMemory.UsagePercent -gt 60) {"Yellow"} else {"Green"})
    
    if ($resourceInfo.WSLProcesses.Count -gt 0) {
        Write-Host "`nWSL Processes:" -ForegroundColor White
        foreach ($proc in $resourceInfo.WSLProcesses) {
            Write-Host "  $($proc.ProcessName) (PID: $($proc.PID)): $($proc.MemoryMB)MB" -ForegroundColor Gray
        }
    } else {
        Write-Host "No running WSL processes found" -ForegroundColor Yellow
    }
    
    if ($resourceInfo.DiskUsage.Count -gt 0) {
        Write-Host "`nWSL Disk Usage:" -ForegroundColor White
        foreach ($disk in $resourceInfo.DiskUsage.GetEnumerator()) {
            Write-Host "  $($disk.Key): $($disk.Value.SizeMB)MB" -ForegroundColor Gray
        }
    }
    
    return $resourceInfo
}

# Network connectivity status check function
function Test-WSLNetworkConnectivity {
    <#
    .SYNOPSIS
    Check WSL network connectivity status
    
    .DESCRIPTION
    Test WSL environment network connectivity, including DNS resolution, external network connection, etc.
    
    .PARAMETER DistributionName
    Specify the WSL distribution to test
    
    .PARAMETER TestUrls
    Specify the list of URLs to test
    
    .EXAMPLE
    Test-WSLNetworkConnectivity
    Test-WSLNetworkConnectivity -DistributionName "Ubuntu" -TestUrls @("google.com", "github.com")
    #>
    [CmdletBinding()]
    param(
        [string]$DistributionName,
        [string[]]$TestUrls = @("google.com", "github.com", "microsoft.com")
    )
    
    Write-Host "Checking WSL network connectivity..." -ForegroundColor Yellow
    
    $networkStatus = @{
        WindowsNetworkStatus = $null
        WSLNetworkStatus = @{}
        DNSResolution = @{}
        ConnectivityTests = @{}
        OverallStatus = "Unknown"
    }
    
    # Check Windows host network status
    $windowsConnectivity = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet -ErrorAction SilentlyContinue
    $networkStatus.WindowsNetworkStatus = if ($windowsConnectivity) { "Connected" } else { "Disconnected" }
    
    # Get WSL network adapter information
    $wslAdapters = Get-NetAdapter | Where-Object { $_.Name -match "WSL|vEthernet" }
    foreach ($adapter in $wslAdapters) {
        $networkStatus.WSLNetworkStatus[$adapter.Name] = @{
            Status = $adapter.Status
            LinkSpeed = $adapter.LinkSpeed
            InterfaceDescription = $adapter.InterfaceDescription
        }
    }
    
    # Test DNS resolution
    foreach ($url in $TestUrls) {
        $dnsResult = Resolve-DnsName -Name $url -ErrorAction SilentlyContinue
        $networkStatus.DNSResolution[$url] = if ($dnsResult) { "Success" } else { "Failed" }
    }
    
    # Test network connectivity
    foreach ($url in $TestUrls) {
        $pingResult = Test-NetConnection -ComputerName $url -InformationLevel Quiet -ErrorAction SilentlyContinue
        $networkStatus.ConnectivityTests[$url] = if ($pingResult) { "Success" } else { "Failed" }
    }
    
    # If WSL distribution is specified, test WSL internal network
    if ($DistributionName -and (wsl -l -q | Select-String $DistributionName)) {
        $wslPingResult = wsl -d $DistributionName -- ping -c 1 google.com 2>$null
        $networkStatus.WSLInternalNetwork = if ($LASTEXITCODE -eq 0) { "Success" } else { "Failed" }
    }
    
    # Determine overall network status
    $successfulTests = ($networkStatus.ConnectivityTests.Values | Where-Object { $_ -eq "Success" }).Count
    $totalTests = $networkStatus.ConnectivityTests.Count
    
    if ($networkStatus.WindowsNetworkStatus -eq "Connected" -and $successfulTests -eq $totalTests) {
        $networkStatus.OverallStatus = "Healthy"
    } elseif ($successfulTests -gt 0) {
        $networkStatus.OverallStatus = "Partial"
    } else {
        $networkStatus.OverallStatus = "Failed"
    }
    
    # Display network status summary
    Write-Host "`n=== WSL Network Connectivity Status ===" -ForegroundColor Cyan
    Write-Host "Windows Network Status: $($networkStatus.WindowsNetworkStatus)" -ForegroundColor $(if($networkStatus.WindowsNetworkStatus -eq "Connected") {"Green"} else {"Red"})
    
    if ($networkStatus.WSLNetworkStatus.Count -gt 0) {
        Write-Host "`nWSL Network Adapters:" -ForegroundColor White
        foreach ($adapter in $networkStatus.WSLNetworkStatus.GetEnumerator()) {
            Write-Host "  $($adapter.Key): $($adapter.Value.Status)" -ForegroundColor $(if($adapter.Value.Status -eq "Up") {"Green"} else {"Red"})
        }
    }
    
    Write-Host "`nDNS Resolution Tests:" -ForegroundColor White
    foreach ($dns in $networkStatus.DNSResolution.GetEnumerator()) {
        Write-Host "  $($dns.Key): $($dns.Value)" -ForegroundColor $(if($dns.Value -eq "Success") {"Green"} else {"Red"})
    }
    
    Write-Host "`nConnectivity Tests:" -ForegroundColor White
    foreach ($test in $networkStatus.ConnectivityTests.GetEnumerator()) {
        Write-Host "  $($test.Key): $($test.Value)" -ForegroundColor $(if($test.Value -eq "Success") {"Green"} else {"Red"})
    }
    
    if ($networkStatus.WSLInternalNetwork) {
        Write-Host "WSL Internal Network: $($networkStatus.WSLInternalNetwork)" -ForegroundColor $(if($networkStatus.WSLInternalNetwork -eq "Success") {"Green"} else {"Red"})
    }
    
    Write-Host "Overall Network Status: $($networkStatus.OverallStatus)" -ForegroundColor $(if($networkStatus.OverallStatus -eq "Healthy") {"Green"} elseif($networkStatus.OverallStatus -eq "Partial") {"Yellow"} else {"Red"})
    
    return $networkStatus
}

# Comprehensive health check function
function Test-WSLHealth {
    <#
    .SYNOPSIS
    Perform comprehensive WSL environment health check
    
    .DESCRIPTION
    Perform complete WSL health check including service status, resource usage and network connectivity
    
    .PARAMETER DistributionName
    Specify the WSL distribution to check
    
    .PARAMETER OutputFormat
    Output format: Console, JSON, HTML
    
    .PARAMETER Detailed
    Show detailed information
    
    .EXAMPLE
    Test-WSLHealth
    Test-WSLHealth -DistributionName "Ubuntu" -Detailed
    Test-WSLHealth -OutputFormat "JSON"
    #>
    [CmdletBinding()]
    param(
        [string]$DistributionName,
        [ValidateSet("Console", "JSON", "HTML")]
        [string]$OutputFormat = "Console",
        [switch]$Detailed
    )
    
    Write-Host "Starting WSL environment health check..." -ForegroundColor Green
    Write-Host "Check time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host "=" * 50 -ForegroundColor Gray
    
    $healthReport = @{
        Timestamp = Get-Date
        DistributionName = $DistributionName
        ServiceStatus = $null
        ResourceUsage = $null
        NetworkStatus = $null
        OverallHealth = "Unknown"
        Recommendations = @()
    }
    
    # 1. Check service status
    Write-Host "`n1. Checking WSL service status" -ForegroundColor Blue
    $healthReport.ServiceStatus = Test-WSLServiceStatus -Detailed:$Detailed
    
    # 2. Check resource usage
    Write-Host "`n2. Checking resource usage" -ForegroundColor Blue
    $healthReport.ResourceUsage = Get-WSLResourceUsage -DistributionName $DistributionName
    
    # 3. Check network connectivity
    Write-Host "`n3. Checking network connectivity" -ForegroundColor Blue
    $healthReport.NetworkStatus = Test-WSLNetworkConnectivity -DistributionName $DistributionName
    
    # 4. Generate recommendations
    if ($healthReport.ServiceStatus.OverallStatus -ne "Healthy") {
        $healthReport.Recommendations += "WSL service status is abnormal, recommend restarting WSL service or checking system configuration"
    }
    
    if ($healthReport.ResourceUsage.SystemMemory.UsagePercent -gt 80) {
        $healthReport.Recommendations += "System memory usage is too high ($($healthReport.ResourceUsage.SystemMemory.UsagePercent)%), recommend closing unnecessary programs"
    }
    
    if ($healthReport.NetworkStatus.OverallStatus -ne "Healthy") {
        $healthReport.Recommendations += "Network connectivity issues exist, recommend checking network configuration or restarting network services"
    }
    
    # 5. Determine overall health status
    $healthyComponents = 0
    $totalComponents = 3
    
    if ($healthReport.ServiceStatus.OverallStatus -eq "Healthy") { $healthyComponents++ }
    if ($healthReport.ResourceUsage.SystemMemory.UsagePercent -lt 80) { $healthyComponents++ }
    if ($healthReport.NetworkStatus.OverallStatus -eq "Healthy") { $healthyComponents++ }
    
    if ($healthyComponents -eq $totalComponents) {
        $healthReport.OverallHealth = "Healthy"
    } elseif ($healthyComponents -ge 2) {
        $healthReport.OverallHealth = "Warning"
    } else {
        $healthReport.OverallHealth = "Critical"
    }
    
    # 6. Output results
    Write-Host "`n" + "=" * 50 -ForegroundColor Gray
    Write-Host "WSL health check completed" -ForegroundColor Green
    Write-Host "Overall health status: $($healthReport.OverallHealth)" -ForegroundColor $(
        switch ($healthReport.OverallHealth) {
            "Healthy" { "Green" }
            "Warning" { "Yellow" }
            "Critical" { "Red" }
            default { "Gray" }
        }
    )
    
    if ($healthReport.Recommendations.Count -gt 0) {
        Write-Host "`nRecommendations:" -ForegroundColor Yellow
        foreach ($recommendation in $healthReport.Recommendations) {
            Write-Host "  • $recommendation" -ForegroundColor Yellow
        }
    }
    
    # Return results based on output format
    switch ($OutputFormat) {
        "JSON" {
            return $healthReport | ConvertTo-Json -Depth 10
        }
        "HTML" {
            # Simple HTML format output
            $html = @"
<html><head><title>WSL Health Report</title></head><body>
<h1>WSL Health Report</h1>
<p>Generated: $($healthReport.Timestamp)</p>
<h2>Overall Status: $($healthReport.OverallHealth)</h2>
<h3>Service Status: $($healthReport.ServiceStatus.OverallStatus)</h3>
<h3>Memory Usage: $($healthReport.ResourceUsage.SystemMemory.UsagePercent)%</h3>
<h3>Network Status: $($healthReport.NetworkStatus.OverallStatus)</h3>
</body></html>
"@
            return $html
        }
        default {
            return $healthReport
        }
    }
}

# Performance monitoring and optimization functions

# Collect detailed resource usage information
function Get-WSLPerformanceMetrics {
    <#
    .SYNOPSIS
    Collect detailed WSL performance metrics
    
    .DESCRIPTION
    Collect comprehensive performance metrics including CPU, memory, disk I/O, and network usage
    
    .PARAMETER DistributionName
    Specify the WSL distribution to monitor
    
    .PARAMETER Duration
    Monitoring duration in seconds
    
    .EXAMPLE
    Get-WSLPerformanceMetrics
    Get-WSLPerformanceMetrics -DistributionName "Ubuntu" -Duration 30
    #>
    [CmdletBinding()]
    param(
        [string]$DistributionName,
        [int]$Duration = 10
    )
    
    Write-Host "Collecting WSL performance metrics for $Duration seconds..." -ForegroundColor Yellow
    
    $performanceData = @{
        StartTime = Get-Date
        Duration = $Duration
        SystemMetrics = @{
            CPU = @()
            Memory = @()
            Disk = @()
            Network = @()
        }
        WSLMetrics = @{
            Processes = @()
            Memory = @()
            DiskIO = @()
        }
        Averages = @{}
    }
    
    # Collect baseline metrics
    $startTime = Get-Date
    $sampleCount = 0
    
    while ((Get-Date) -lt $startTime.AddSeconds($Duration)) {
        $sampleCount++
        
        # System CPU usage
        $cpuUsage = (Get-Counter "\Processor(_Total)\% Processor Time" -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue
        $performanceData.SystemMetrics.CPU += $cpuUsage
        
        # System memory usage
        $memInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $memUsagePercent = [math]::Round((($memInfo.TotalVisibleMemorySize - $memInfo.FreePhysicalMemory) / $memInfo.TotalVisibleMemorySize) * 100, 2)
        $performanceData.SystemMetrics.Memory += $memUsagePercent
        
        # WSL process metrics
        $wslProcesses = Get-Process | Where-Object { 
            $_.ProcessName -match "wsl|lxss" -or 
            $_.MainWindowTitle -match "WSL|Ubuntu|Debian|SUSE" 
        }
        
        $wslMemoryTotal = 0
        foreach ($proc in $wslProcesses) {
            $wslMemoryTotal += $proc.WorkingSet
        }
        $performanceData.WSLMetrics.Memory += [math]::Round($wslMemoryTotal / 1MB, 2)
        
        # Disk I/O metrics
        $diskCounters = Get-Counter "\PhysicalDisk(_Total)\Disk Bytes/sec" -ErrorAction SilentlyContinue
        if ($diskCounters) {
            $diskIO = $diskCounters.CounterSamples[0].CookedValue
            $performanceData.SystemMetrics.Disk += [math]::Round($diskIO / 1MB, 2)
        }
        
        # Network I/O metrics
        $networkCounters = Get-Counter "\Network Interface(*)\Bytes Total/sec" -ErrorAction SilentlyContinue
        if ($networkCounters) {
            $networkIO = ($networkCounters.CounterSamples | Measure-Object -Property CookedValue -Sum).Sum
            $performanceData.SystemMetrics.Network += [math]::Round($networkIO / 1MB, 2)
        }
        
        Start-Sleep -Seconds 1
    }
    
    # Calculate averages
    $performanceData.Averages = @{
        CPUUsage = [math]::Round(($performanceData.SystemMetrics.CPU | Measure-Object -Average).Average, 2)
        MemoryUsage = [math]::Round(($performanceData.SystemMetrics.Memory | Measure-Object -Average).Average, 2)
        WSLMemoryUsage = [math]::Round(($performanceData.WSLMetrics.Memory | Measure-Object -Average).Average, 2)
        DiskIORate = [math]::Round(($performanceData.SystemMetrics.Disk | Measure-Object -Average).Average, 2)
        NetworkIORate = [math]::Round(($performanceData.SystemMetrics.Network | Measure-Object -Average).Average, 2)
    }
    
    $performanceData.EndTime = Get-Date
    
    # Display performance summary
    Write-Host "`n=== WSL Performance Metrics Summary ===" -ForegroundColor Cyan
    Write-Host "Monitoring Duration: $Duration seconds" -ForegroundColor White
    Write-Host "Average CPU Usage: $($performanceData.Averages.CPUUsage)%" -ForegroundColor $(if($performanceData.Averages.CPUUsage -gt 80) {"Red"} elseif($performanceData.Averages.CPUUsage -gt 60) {"Yellow"} else {"Green"})
    Write-Host "Average Memory Usage: $($performanceData.Averages.MemoryUsage)%" -ForegroundColor $(if($performanceData.Averages.MemoryUsage -gt 80) {"Red"} elseif($performanceData.Averages.MemoryUsage -gt 60) {"Yellow"} else {"Green"})
    Write-Host "Average WSL Memory Usage: $($performanceData.Averages.WSLMemoryUsage)MB" -ForegroundColor White
    Write-Host "Average Disk I/O Rate: $($performanceData.Averages.DiskIORate)MB/s" -ForegroundColor White
    Write-Host "Average Network I/O Rate: $($performanceData.Averages.NetworkIORate)MB/s" -ForegroundColor White
    
    return $performanceData
}

# Detect performance bottlenecks
function Test-WSLPerformanceBottlenecks {
    <#
    .SYNOPSIS
    Detect WSL performance bottlenecks
    
    .DESCRIPTION
    Analyze system performance and identify potential bottlenecks affecting WSL performance
    
    .PARAMETER PerformanceData
    Performance data from Get-WSLPerformanceMetrics
    
    .EXAMPLE
    $metrics = Get-WSLPerformanceMetrics
    Test-WSLPerformanceBottlenecks -PerformanceData $metrics
    #>
    [CmdletBinding()]
    param(
        [hashtable]$PerformanceData
    )
    
    Write-Host "Analyzing performance bottlenecks..." -ForegroundColor Yellow
    
    $bottlenecks = @()
    $warnings = @()
    
    # CPU bottleneck detection
    if ($PerformanceData.Averages.CPUUsage -gt 90) {
        $bottlenecks += @{
            Type = "CPU"
            Severity = "Critical"
            Description = "CPU usage is critically high ($($PerformanceData.Averages.CPUUsage)%)"
            Impact = "WSL performance will be severely degraded"
            Recommendations = @(
                "Close unnecessary applications",
                "Reduce WSL workload",
                "Consider upgrading CPU"
            )
        }
    } elseif ($PerformanceData.Averages.CPUUsage -gt 75) {
        $warnings += @{
            Type = "CPU"
            Severity = "Warning"
            Description = "CPU usage is high ($($PerformanceData.Averages.CPUUsage)%)"
            Impact = "WSL performance may be affected"
            Recommendations = @(
                "Monitor CPU usage",
                "Close unnecessary applications"
            )
        }
    }
    
    # Memory bottleneck detection
    if ($PerformanceData.Averages.MemoryUsage -gt 90) {
        $bottlenecks += @{
            Type = "Memory"
            Severity = "Critical"
            Description = "Memory usage is critically high ($($PerformanceData.Averages.MemoryUsage)%)"
            Impact = "System may become unstable, WSL may crash"
            Recommendations = @(
                "Close memory-intensive applications",
                "Restart WSL to free memory",
                "Add more RAM"
            )
        }
    } elseif ($PerformanceData.Averages.MemoryUsage -gt 80) {
        $warnings += @{
            Type = "Memory"
            Severity = "Warning"
            Description = "Memory usage is high ($($PerformanceData.Averages.MemoryUsage)%)"
            Impact = "Performance degradation likely"
            Recommendations = @(
                "Monitor memory usage",
                "Close unnecessary applications",
                "Configure WSL memory limits"
            )
        }
    }
    
    # WSL-specific memory analysis
    if ($PerformanceData.Averages.WSLMemoryUsage -gt 2048) {
        $warnings += @{
            Type = "WSL Memory"
            Severity = "Warning"
            Description = "WSL processes are using significant memory ($($PerformanceData.Averages.WSLMemoryUsage)MB)"
            Impact = "May affect overall system performance"
            Recommendations = @(
                "Review WSL workloads",
                "Configure WSL memory limits in .wslconfig",
                "Restart WSL to free memory"
            )
        }
    }
    
    # Disk I/O bottleneck detection
    if ($PerformanceData.Averages.DiskIORate -gt 100) {
        $warnings += @{
            Type = "Disk I/O"
            Severity = "Warning"
            Description = "High disk I/O activity ($($PerformanceData.Averages.DiskIORate)MB/s)"
            Impact = "May cause WSL file operations to be slow"
            Recommendations = @(
                "Check for disk-intensive processes",
                "Consider using SSD for WSL",
                "Optimize WSL file system usage"
            )
        }
    }
    
    # Network I/O analysis
    if ($PerformanceData.Averages.NetworkIORate -gt 50) {
        $warnings += @{
            Type = "Network I/O"
            Severity = "Info"
            Description = "High network activity ($($PerformanceData.Averages.NetworkIORate)MB/s)"
            Impact = "Network-intensive WSL operations detected"
            Recommendations = @(
                "Monitor network usage",
                "Check for network-intensive WSL processes"
            )
        }
    }
    
    # Display results
    Write-Host "`n=== Performance Bottleneck Analysis ===" -ForegroundColor Cyan
    
    if ($bottlenecks.Count -eq 0 -and $warnings.Count -eq 0) {
        Write-Host "No significant performance bottlenecks detected" -ForegroundColor Green
    } else {
        if ($bottlenecks.Count -gt 0) {
            Write-Host "`nCritical Bottlenecks:" -ForegroundColor Red
            foreach ($bottleneck in $bottlenecks) {
                Write-Host "  • $($bottleneck.Description)" -ForegroundColor Red
                Write-Host "    Impact: $($bottleneck.Impact)" -ForegroundColor Yellow
                Write-Host "    Recommendations:" -ForegroundColor Cyan
                foreach ($rec in $bottleneck.Recommendations) {
                    Write-Host "      - $rec" -ForegroundColor White
                }
            }
        }
        
        if ($warnings.Count -gt 0) {
            Write-Host "`nWarnings:" -ForegroundColor Yellow
            foreach ($warning in $warnings) {
                Write-Host "  • $($warning.Description)" -ForegroundColor Yellow
                Write-Host "    Impact: $($warning.Impact)" -ForegroundColor Gray
                Write-Host "    Recommendations:" -ForegroundColor Cyan
                foreach ($rec in $warning.Recommendations) {
                    Write-Host "      - $rec" -ForegroundColor White
                }
            }
        }
    }
    
    return @{
        Bottlenecks = $bottlenecks
        Warnings = $warnings
        OverallStatus = if ($bottlenecks.Count -gt 0) { "Critical" } elseif ($warnings.Count -gt 0) { "Warning" } else { "Healthy" }
    }
}

# Automatic optimization suggestions and execution
function Invoke-WSLPerformanceOptimization {
    <#
    .SYNOPSIS
    Apply automatic WSL performance optimizations
    
    .DESCRIPTION
    Analyze current WSL configuration and apply performance optimizations
    
    .PARAMETER AutoApply
    Automatically apply safe optimizations
    
    .PARAMETER OptimizationType
    Type of optimization: All, Memory, CPU, Disk, Network
    
    .EXAMPLE
    Invoke-WSLPerformanceOptimization
    Invoke-WSLPerformanceOptimization -AutoApply -OptimizationType "Memory"
    #>
    [CmdletBinding()]
    param(
        [switch]$AutoApply,
        [ValidateSet("All", "Memory", "CPU", "Disk", "Network")]
        [string]$OptimizationType = "All"
    )
    
    Write-Host "Analyzing WSL performance optimization opportunities..." -ForegroundColor Green
    
    $optimizations = @()
    $appliedOptimizations = @()
    
    # Memory optimizations
    if ($OptimizationType -eq "All" -or $OptimizationType -eq "Memory") {
        # Check current WSL memory configuration
        $wslConfigPath = "$env:USERPROFILE\.wslconfig"
        $currentConfig = @{}
        
        if (Test-Path $wslConfigPath) {
            $configContent = Get-Content $wslConfigPath -Raw
            # Parse basic .wslconfig format
            if ($configContent -match 'memory\s*=\s*(.+)') {
                $currentConfig.Memory = $matches[1].Trim()
            }
        }
        
        # Get system memory info
        $memInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $totalMemoryGB = [math]::Round($memInfo.TotalVisibleMemorySize / 1MB, 2)
        
        # Suggest memory optimization
        $recommendedMemoryGB = [math]::Floor($totalMemoryGB * 0.5)  # 50% of system memory
        
        if (-not $currentConfig.Memory -or $currentConfig.Memory -notmatch "${recommendedMemoryGB}GB") {
            $optimizations += @{
                Type = "Memory"
                Description = "Configure WSL memory limit to ${recommendedMemoryGB}GB (50% of system memory)"
                Impact = "Prevents WSL from consuming all system memory"
                ConfigChange = "memory=${recommendedMemoryGB}GB"
                Safe = $true
            }
        }
        
        # Suggest swap optimization
        if (-not $currentConfig.ContainsKey("Swap") -or $currentConfig.Swap -eq "0") {
            $recommendedSwapGB = [math]::Min(4, [math]::Floor($recommendedMemoryGB * 0.25))
            $optimizations += @{
                Type = "Memory"
                Description = "Configure WSL swap to ${recommendedSwapGB}GB"
                Impact = "Provides additional virtual memory for WSL"
                ConfigChange = "swap=${recommendedSwapGB}GB"
                Safe = $true
            }
        }
    }
    
    # CPU optimizations
    if ($OptimizationType -eq "All" -or $OptimizationType -eq "CPU") {
        $cpuCount = (Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfLogicalProcessors
        $recommendedCPUs = [math]::Max(2, [math]::Floor($cpuCount * 0.75))  # 75% of available CPUs
        
        $optimizations += @{
            Type = "CPU"
            Description = "Configure WSL to use $recommendedCPUs CPU cores (75% of available)"
            Impact = "Optimizes CPU allocation for WSL while preserving system responsiveness"
            ConfigChange = "processors=$recommendedCPUs"
            Safe = $true
        }
    }
    
    # Network optimizations
    if ($OptimizationType -eq "All" -or $OptimizationType -eq "Network") {
        $optimizations += @{
            Type = "Network"
            Description = "Enable localhost forwarding for better network performance"
            Impact = "Improves network connectivity between Windows and WSL"
            ConfigChange = "localhostForwarding=true"
            Safe = $true
        }
        
        $optimizations += @{
            Type = "Network"
            Description = "Enable automatic generation of /etc/hosts"
            Impact = "Improves name resolution performance"
            ConfigChange = "generateHosts=true"
            Safe = $true
        }
    }
    
    # Disk optimizations
    if ($OptimizationType -eq "All" -or $OptimizationType -eq "Disk") {
        $optimizations += @{
            Type = "Disk"
            Description = "Enable Windows interoperability for better file system performance"
            Impact = "Improves file access between Windows and WSL"
            ConfigChange = "interop.enabled=true"
            Safe = $true
        }
    }
    
    # Display optimization suggestions
    Write-Host "`n=== WSL Performance Optimization Suggestions ===" -ForegroundColor Cyan
    
    if ($optimizations.Count -eq 0) {
        Write-Host "No additional optimizations recommended" -ForegroundColor Green
    } else {
        foreach ($opt in $optimizations) {
            Write-Host "`n• $($opt.Description)" -ForegroundColor Yellow
            Write-Host "  Impact: $($opt.Impact)" -ForegroundColor White
            Write-Host "  Configuration: $($opt.ConfigChange)" -ForegroundColor Gray
            Write-Host "  Safe to apply: $(if($opt.Safe) {'Yes'} else {'No'})" -ForegroundColor $(if($opt.Safe) {"Green"} else {"Red"})
        }
        
        # Apply optimizations if requested
        if ($AutoApply) {
            Write-Host "`nApplying safe optimizations..." -ForegroundColor Green
            
            $safeOptimizations = $optimizations | Where-Object { $_.Safe -eq $true }
            if ($safeOptimizations.Count -gt 0) {
                $configContent = "[wsl2]`n"
                
                foreach ($opt in $safeOptimizations) {
                    $configContent += "$($opt.ConfigChange)`n"
                    $appliedOptimizations += $opt
                }
                
                # Backup existing config
                if (Test-Path $wslConfigPath) {
                    Copy-Item $wslConfigPath "$wslConfigPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                }
                
                # Write new config
                $configContent | Out-File -FilePath $wslConfigPath -Encoding UTF8
                
                Write-Host "Applied $($appliedOptimizations.Count) optimizations to .wslconfig" -ForegroundColor Green
                Write-Host "WSL restart required for changes to take effect" -ForegroundColor Yellow
                Write-Host "Run 'wsl --shutdown' and restart your WSL distribution" -ForegroundColor Yellow
            }
        } else {
            Write-Host "`nTo apply these optimizations automatically, run with -AutoApply parameter" -ForegroundColor Cyan
        }
    }
    
    return @{
        Suggestions = $optimizations
        Applied = $appliedOptimizations
        RequiresRestart = $appliedOptimizations.Count -gt 0
    }
}

# Export all functions
Export-ModuleMember -Function Test-WSLServiceStatus, Get-WSLResourceUsage, Test-WSLNetworkConnectivity, Test-WSLHealth, Get-WSLPerformanceMetrics, Test-WSLPerformanceBottlenecks, Invoke-WSLPerformanceOptimization