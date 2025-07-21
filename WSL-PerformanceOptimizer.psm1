# WSL Performance Optimization Module
# Provides performance optimization configuration and management functionality

# Import configuration manager
if (Test-Path "$PSScriptRoot\WSL-ConfigManager.psm1") {
    Import-Module "$PSScriptRoot\WSL-ConfigManager.psm1" -Force
}

# Performance optimization profiles
$script:PerformanceProfiles = @{
    "gaming" = @{
        memory = "12GB"
        processors = 6
        swap = "4GB"
        autoMemoryReclaim = "disabled"
        sparseVhd = $false
        localhostForwarding = $true
        nestedVirtualization = $true
        pageReporting = $false
        guiApplications = $true
        kernelCommandLine = "cgroup_no_v1=all systemd.unified_cgroup_hierarchy=1"
    }
    "server" = @{
        memory = "16GB"
        processors = 8
        swap = "8GB"
        autoMemoryReclaim = "disabled"
        sparseVhd = $false
        localhostForwarding = $true
        nestedVirtualization = $false
        pageReporting = $false
        guiApplications = $false
        kernelCommandLine = "cgroup_no_v1=all"
    }
    "minimal" = @{
        memory = "1GB"
        processors = 1
        swap = "256MB"
        autoMemoryReclaim = "gradual"
        sparseVhd = $true
        localhostForwarding = $false
        nestedVirtualization = $false
        pageReporting = $true
        guiApplications = $false
        kernelCommandLine = ""
    }
    "docker-optimized" = @{
        memory = "8GB"
        processors = 4
        swap = "2GB"
        autoMemoryReclaim = "gradual"
        sparseVhd = $false
        localhostForwarding = $true
        nestedVirtualization = $true
        pageReporting = $true
        guiApplications = $false
        kernelCommandLine = "cgroup_no_v1=all systemd.unified_cgroup_hierarchy=1"
    }
}

# Network optimization settings
$script:NetworkOptimizations = @{
    "high-throughput" = @{
        generateHosts = $true
        generateResolvConf = $true
        useWindowsDnsCache = $true
        networkingMode = "mirrored"
        dnsTunneling = $true
        firewall = $true
        autoProxy = $true
    }
    "low-latency" = @{
        generateHosts = $false
        generateResolvConf = $false
        useWindowsDnsCache = $false
        networkingMode = "nat"
        dnsTunneling = $false
        firewall = $false
        autoProxy = $false
    }
    "balanced" = @{
        generateHosts = $true
        generateResolvConf = $true
        useWindowsDnsCache = $true
        networkingMode = "nat"
        dnsTunneling = $false
        firewall = $true
        autoProxy = $true
    }
}

# Storage optimization settings
$script:StorageOptimizations = @{
    "performance" = @{
        sparseVhd = $false
        pageReporting = $false
        autoMemoryReclaim = "disabled"
        vmIdleTimeout = 60000
    }
    "space-saving" = @{
        sparseVhd = $true
        pageReporting = $true
        autoMemoryReclaim = "gradual"
        vmIdleTimeout = 30000
    }
    "balanced" = @{
        sparseVhd = $true
        pageReporting = $true
        autoMemoryReclaim = "gradual"
        vmIdleTimeout = 60000
    }
}

<#
.SYNOPSIS
Get system hardware information for optimization

.DESCRIPTION
Retrieves system hardware specifications to determine optimal WSL configuration

.EXAMPLE
Get-SystemHardwareInfo
#>
function Get-SystemHardwareInfo {
    [CmdletBinding()]
    param()
    
    try {
        $computerSystem = Get-CimInstance Win32_ComputerSystem
        $processor = Get-CimInstance Win32_Processor | Select-Object -First 1
        $memory = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
        $disk = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        
        $totalMemoryGB = [math]::Round($memory.Sum / 1GB, 2)
        $availableMemoryGB = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
        
        $hardwareInfo = @{
            ProcessorName = $processor.Name
            ProcessorCores = $processor.NumberOfCores
            LogicalProcessors = $computerSystem.NumberOfLogicalProcessors
            TotalMemoryGB = $totalMemoryGB
            AvailableMemoryGB = $availableMemoryGB
            DiskInfo = $disk | Select-Object DeviceID, Size, FreeSpace
            Architecture = $processor.Architecture
            Virtualization = $processor.VirtualizationFirmwareEnabled
        }
        
        Write-Host "System Hardware Information:" -ForegroundColor Green
        Write-Host "  Processor: $($hardwareInfo.ProcessorName)" -ForegroundColor Gray
        Write-Host "  Cores: $($hardwareInfo.ProcessorCores) / Logical: $($hardwareInfo.LogicalProcessors)" -ForegroundColor Gray
        Write-Host "  Memory: $($hardwareInfo.TotalMemoryGB) GB" -ForegroundColor Gray
        Write-Host "  Virtualization: $($hardwareInfo.Virtualization)" -ForegroundColor Gray
        
        return $hardwareInfo
    }
    catch {
        Write-Error "Failed to retrieve system hardware information: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
Calculate optimal WSL resource limits

.DESCRIPTION
Calculates recommended memory and CPU limits based on system hardware and usage profile

.PARAMETER UsageProfile
Usage profile (development, gaming, server, minimal)

.PARAMETER CustomMemoryPercent
Custom memory percentage to allocate to WSL (default: auto-calculated)

.PARAMETER CustomProcessorPercent
Custom processor percentage to allocate to WSL (default: auto-calculated)

.EXAMPLE
Get-OptimalResourceLimits -UsageProfile "development"
#>
function Get-OptimalResourceLimits {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("development", "gaming", "server", "minimal", "docker")]
        [string]$UsageProfile,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(10, 90)]
        [int]$CustomMemoryPercent,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(25, 100)]
        [int]$CustomProcessorPercent
    )
    
    try {
        $hardwareInfo = Get-SystemHardwareInfo
        if (-not $hardwareInfo) {
            throw "Unable to retrieve system hardware information"
        }
        
        # Calculate memory allocation based on profile
        $memoryPercent = switch ($UsageProfile) {
            "minimal" { 25 }
            "development" { 50 }
            "gaming" { 75 }
            "server" { 80 }
            "docker" { 60 }
            default { 50 }
        }
        
        # Calculate processor allocation based on profile
        $processorPercent = switch ($UsageProfile) {
            "minimal" { 25 }
            "development" { 50 }
            "gaming" { 75 }
            "server" { 100 }
            "docker" { 75 }
            default { 50 }
        }
        
        # Apply custom percentages if provided
        if ($CustomMemoryPercent) { $memoryPercent = $CustomMemoryPercent }
        if ($CustomProcessorPercent) { $processorPercent = $CustomProcessorPercent }
        
        # Calculate actual values
        $recommendedMemoryGB = [math]::Round($hardwareInfo.TotalMemoryGB * ($memoryPercent / 100), 0)
        $recommendedProcessors = [math]::Max(1, [math]::Round($hardwareInfo.LogicalProcessors * ($processorPercent / 100), 0))
        $recommendedSwapGB = [math]::Max(1, [math]::Round($recommendedMemoryGB * 0.25, 0))
        
        # Ensure minimum values
        $recommendedMemoryGB = [math]::Max(1, $recommendedMemoryGB)
        $recommendedProcessors = [math]::Max(1, $recommendedProcessors)
        
        $recommendations = @{
            Memory = "${recommendedMemoryGB}GB"
            Processors = $recommendedProcessors
            Swap = "${recommendedSwapGB}GB"
            MemoryPercent = $memoryPercent
            ProcessorPercent = $processorPercent
            Profile = $UsageProfile
            SystemInfo = $hardwareInfo
        }
        
        Write-Host "Optimal Resource Limits for '$UsageProfile' profile:" -ForegroundColor Green
        Write-Host "  Memory: $($recommendations.Memory) ($memoryPercent% of system)" -ForegroundColor Gray
        Write-Host "  Processors: $($recommendations.Processors) ($processorPercent% of system)" -ForegroundColor Gray
        Write-Host "  Swap: $($recommendations.Swap)" -ForegroundColor Gray
        
        return $recommendations
    }
    catch {
        Write-Error "Failed to calculate optimal resource limits: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
Apply performance optimization profile

.DESCRIPTION
Applies a predefined performance optimization profile to WSL configuration

.PARAMETER ProfileName
Performance profile name

.PARAMETER CustomSettings
Custom settings to override profile defaults

.PARAMETER Apply
Whether to immediately apply the configuration

.EXAMPLE
Set-WSLPerformanceProfile -ProfileName "gaming" -Apply
#>
function Set-WSLPerformanceProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("gaming", "server", "minimal", "docker-optimized")]
        [string]$ProfileName,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$CustomSettings = @{},
        
        [Parameter(Mandatory = $false)]
        [switch]$Apply
    )
    
    try {
        Write-Host "Applying WSL performance profile: $ProfileName" -ForegroundColor Yellow
        
        # Get the profile configuration
        $profileConfig = $script:PerformanceProfiles[$ProfileName].Clone()
        
        # Apply custom settings
        foreach ($key in $CustomSettings.Keys) {
            $profileConfig[$key] = $CustomSettings[$key]
        }
        
        # Build full configuration
        $fullConfig = @{
            wsl2 = $profileConfig
        }
        
        # Apply the configuration
        $result = New-WSLConfig -ConfigData $fullConfig -Backup
        
        if ($result.Success) {
            Write-Host "Performance profile applied successfully: $ProfileName" -ForegroundColor Green
            
            if ($Apply) {
                Write-Host "Restarting WSL to apply performance optimizations..." -ForegroundColor Yellow
                $applyResult = Invoke-WSLConfigApply
                if ($applyResult.Success) {
                    Write-Host "Performance optimizations applied successfully" -ForegroundColor Green
                } else {
                    Write-Warning "Failed to apply performance optimizations: $($applyResult.Error)"
                }
            } else {
                Write-Host "Performance profile saved. Restart WSL to apply changes." -ForegroundColor Cyan
            }
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to apply WSL performance profile: $($_.Exception.Message)"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
Optimize WSL network settings

.DESCRIPTION
Applies network optimization settings based on usage scenario

.PARAMETER OptimizationType
Network optimization type (high-throughput, low-latency, balanced)

.PARAMETER Apply
Whether to immediately apply the configuration

.EXAMPLE
Optimize-WSLNetwork -OptimizationType "high-throughput" -Apply
#>
function Optimize-WSLNetwork {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("high-throughput", "low-latency", "balanced")]
        [string]$OptimizationType,
        
        [Parameter(Mandatory = $false)]
        [switch]$Apply
    )
    
    try {
        Write-Host "Optimizing WSL network settings: $OptimizationType" -ForegroundColor Yellow
        
        # Get current configuration
        $currentConfig = Get-WSLConfig
        if (-not $currentConfig) {
            $currentConfig = @{ wsl2 = @{} }
        }
        
        # Get network optimization settings
        $networkSettings = $script:NetworkOptimizations[$OptimizationType]
        
        # Apply network settings to wsl2 section
        foreach ($setting in $networkSettings.Keys) {
            $currentConfig.wsl2[$setting] = $networkSettings[$setting]
        }
        
        # Apply the configuration
        $result = New-WSLConfig -ConfigData $currentConfig -Backup
        
        if ($result.Success) {
            Write-Host "Network optimization applied successfully: $OptimizationType" -ForegroundColor Green
            
            if ($Apply) {
                Write-Host "Restarting WSL to apply network optimizations..." -ForegroundColor Yellow
                $applyResult = Invoke-WSLConfigApply
                if ($applyResult.Success) {
                    Write-Host "Network optimizations applied successfully" -ForegroundColor Green
                } else {
                    Write-Warning "Failed to apply network optimizations: $($applyResult.Error)"
                }
            }
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to optimize WSL network settings: $($_.Exception.Message)"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
Optimize WSL storage settings

.DESCRIPTION
Applies storage optimization settings based on priority (performance vs space)

.PARAMETER OptimizationType
Storage optimization type (performance, space-saving, balanced)

.PARAMETER Apply
Whether to immediately apply the configuration

.EXAMPLE
Optimize-WSLStorage -OptimizationType "performance" -Apply
#>
function Optimize-WSLStorage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("performance", "space-saving", "balanced")]
        [string]$OptimizationType,
        
        [Parameter(Mandatory = $false)]
        [switch]$Apply
    )
    
    try {
        Write-Host "Optimizing WSL storage settings: $OptimizationType" -ForegroundColor Yellow
        
        # Get current configuration
        $currentConfig = Get-WSLConfig
        if (-not $currentConfig) {
            $currentConfig = @{ wsl2 = @{}; experimental = @{} }
        }
        
        # Ensure experimental section exists
        if (-not $currentConfig.ContainsKey('experimental')) {
            $currentConfig.experimental = @{}
        }
        
        # Get storage optimization settings
        $storageSettings = $script:StorageOptimizations[$OptimizationType]
        
        # Apply storage settings
        foreach ($setting in $storageSettings.Keys) {
            if ($setting -in @('sparseVhd', 'autoMemoryReclaim')) {
                $currentConfig.experimental[$setting] = $storageSettings[$setting]
            } else {
                $currentConfig.wsl2[$setting] = $storageSettings[$setting]
            }
        }
        
        # Apply the configuration
        $result = New-WSLConfig -ConfigData $currentConfig -Backup
        
        if ($result.Success) {
            Write-Host "Storage optimization applied successfully: $OptimizationType" -ForegroundColor Green
            
            if ($Apply) {
                Write-Host "Restarting WSL to apply storage optimizations..." -ForegroundColor Yellow
                $applyResult = Invoke-WSLConfigApply
                if ($applyResult.Success) {
                    Write-Host "Storage optimizations applied successfully" -ForegroundColor Green
                } else {
                    Write-Warning "Failed to apply storage optimizations: $($applyResult.Error)"
                }
            }
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to optimize WSL storage settings: $($_.Exception.Message)"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}<#
.SY
NOPSIS
Create comprehensive performance optimization configuration

.DESCRIPTION
Creates a comprehensive WSL configuration optimized for specific use cases

.PARAMETER UsageProfile
Primary usage profile (development, gaming, server, minimal, docker)

.PARAMETER NetworkOptimization
Network optimization type (high-throughput, low-latency, balanced)

.PARAMETER StorageOptimization
Storage optimization type (performance, space-saving, balanced)

.PARAMETER CustomResourceLimits
Custom resource limits to override calculated values

.PARAMETER Apply
Whether to immediately apply the configuration

.EXAMPLE
New-WSLOptimizedConfig -UsageProfile "development" -NetworkOptimization "balanced" -StorageOptimization "balanced" -Apply
#>
function New-WSLOptimizedConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("development", "gaming", "server", "minimal", "docker")]
        [string]$UsageProfile,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("high-throughput", "low-latency", "balanced")]
        [string]$NetworkOptimization = "balanced",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("performance", "space-saving", "balanced")]
        [string]$StorageOptimization = "balanced",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$CustomResourceLimits = @{},
        
        [Parameter(Mandatory = $false)]
        [switch]$Apply
    )
    
    try {
        Write-Host "Creating optimized WSL configuration..." -ForegroundColor Yellow
        Write-Host "  Usage Profile: $UsageProfile" -ForegroundColor Gray
        Write-Host "  Network Optimization: $NetworkOptimization" -ForegroundColor Gray
        Write-Host "  Storage Optimization: $StorageOptimization" -ForegroundColor Gray
        
        # Get optimal resource limits
        $resourceLimits = Get-OptimalResourceLimits -UsageProfile $UsageProfile
        if (-not $resourceLimits) {
            throw "Failed to calculate optimal resource limits"
        }
        
        # Apply custom resource limits
        foreach ($key in $CustomResourceLimits.Keys) {
            $resourceLimits[$key] = $CustomResourceLimits[$key]
        }
        
        # Build base configuration from resource limits
        $config = @{
            wsl2 = @{
                memory = $resourceLimits.Memory
                processors = $resourceLimits.Processors
                swap = $resourceLimits.Swap
            }
            experimental = @{}
        }
        
        # Apply network optimizations
        $networkSettings = $script:NetworkOptimizations[$NetworkOptimization]
        foreach ($setting in $networkSettings.Keys) {
            $config.wsl2[$setting] = $networkSettings[$setting]
        }
        
        # Apply storage optimizations
        $storageSettings = $script:StorageOptimizations[$StorageOptimization]
        foreach ($setting in $storageSettings.Keys) {
            if ($setting -in @('sparseVhd', 'autoMemoryReclaim')) {
                $config.experimental[$setting] = $storageSettings[$setting]
            } else {
                $config.wsl2[$setting] = $storageSettings[$setting]
            }
        }
        
        # Add profile-specific optimizations
        switch ($UsageProfile) {
            "development" {
                $config.wsl2.localhostForwarding = $true
                $config.wsl2.guiApplications = $true
                $config.wsl2.debugConsole = $false
            }
            "gaming" {
                $config.wsl2.nestedVirtualization = $true
                $config.wsl2.pageReporting = $false
                $config.experimental.autoMemoryReclaim = "disabled"
            }
            "server" {
                $config.wsl2.guiApplications = $false
                $config.wsl2.debugConsole = $false
                $config.wsl2.pageReporting = $false
                $config.experimental.autoMemoryReclaim = "disabled"
            }
            "minimal" {
                $config.wsl2.guiApplications = $false
                $config.wsl2.localhostForwarding = $false
                $config.wsl2.nestedVirtualization = $false
            }
            "docker" {
                $config.wsl2.nestedVirtualization = $true
                $config.wsl2.kernelCommandLine = "cgroup_no_v1=all systemd.unified_cgroup_hierarchy=1"
            }
        }
        
        # Apply the configuration
        $result = New-WSLConfig -ConfigData $config -Backup
        
        if ($result.Success) {
            Write-Host "Optimized WSL configuration created successfully" -ForegroundColor Green
            
            # Display configuration summary
            Write-Host "`nConfiguration Summary:" -ForegroundColor Cyan
            Write-Host "  Memory: $($config.wsl2.memory)" -ForegroundColor Gray
            Write-Host "  Processors: $($config.wsl2.processors)" -ForegroundColor Gray
            Write-Host "  Swap: $($config.wsl2.swap)" -ForegroundColor Gray
            Write-Host "  Network Mode: $($config.wsl2.networkingMode)" -ForegroundColor Gray
            Write-Host "  Storage: $($StorageOptimization) optimization" -ForegroundColor Gray
            
            if ($Apply) {
                Write-Host "`nApplying optimized configuration..." -ForegroundColor Yellow
                $applyResult = Invoke-WSLConfigApply
                if ($applyResult.Success) {
                    Write-Host "Optimized configuration applied successfully" -ForegroundColor Green
                } else {
                    Write-Warning "Failed to apply optimized configuration: $($applyResult.Error)"
                }
            } else {
                Write-Host "`nConfiguration saved. Restart WSL to apply optimizations." -ForegroundColor Cyan
            }
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to create optimized WSL configuration: $($_.Exception.Message)"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
Switch between performance configuration profiles

.DESCRIPTION
Quickly switch between different performance configuration profiles

.PARAMETER ProfileName
Profile name to switch to

.PARAMETER Apply
Whether to immediately apply the configuration

.EXAMPLE
Switch-WSLPerformanceProfile -ProfileName "gaming" -Apply
#>
function Switch-WSLPerformanceProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("development", "gaming", "server", "minimal", "docker", "balanced", "high-performance", "low-resource")]
        [string]$ProfileName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Apply
    )
    
    try {
        Write-Host "Switching to WSL performance profile: $ProfileName" -ForegroundColor Yellow
        
        # Handle different profile types
        if ($ProfileName -in @("development", "gaming", "server", "minimal", "docker")) {
            # Use comprehensive optimization
            $result = New-WSLOptimizedConfig -UsageProfile $ProfileName -Apply:$Apply
        } elseif ($ProfileName -in @("gaming", "server", "minimal", "docker-optimized")) {
            # Use performance profile
            $result = Set-WSLPerformanceProfile -ProfileName $ProfileName -Apply:$Apply
        } else {
            # Use preset configuration
            $result = Set-WSLConfigPreset -PresetName $ProfileName -Apply:$Apply
        }
        
        if ($result.Success) {
            Write-Host "Successfully switched to profile: $ProfileName" -ForegroundColor Green
        } else {
            Write-Error "Failed to switch to profile: $($result.Error)"
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to switch WSL performance profile: $($_.Exception.Message)"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
Get current WSL performance metrics

.DESCRIPTION
Retrieves current WSL performance metrics and resource usage

.EXAMPLE
Get-WSLPerformanceMetrics
#>
function Get-WSLPerformanceMetrics {
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Gathering WSL performance metrics..." -ForegroundColor Yellow
        
        # Get WSL process information
        $wslProcesses = Get-Process | Where-Object { $_.ProcessName -like "*wsl*" -or $_.ProcessName -like "*vmcompute*" }
        
        # Get current configuration
        $currentConfig = Get-WSLConfig
        
        # Get system information
        $systemInfo = Get-SystemHardwareInfo
        
        # Calculate metrics
        $totalWslMemoryMB = ($wslProcesses | Measure-Object -Property WorkingSet64 -Sum).Sum / 1MB
        $totalWslCpuPercent = ($wslProcesses | Measure-Object -Property CPU -Sum).Sum
        
        $metrics = @{
            Timestamp = Get-Date
            WSLProcesses = $wslProcesses.Count
            TotalMemoryUsageMB = [math]::Round($totalWslMemoryMB, 2)
            TotalCpuUsage = [math]::Round($totalWslCpuPercent, 2)
            CurrentConfiguration = $currentConfig
            SystemInfo = $systemInfo
            ConfiguredMemory = if ($currentConfig -and $currentConfig.wsl2 -and $currentConfig.wsl2.memory) { $currentConfig.wsl2.memory } else { "Default" }
            ConfiguredProcessors = if ($currentConfig -and $currentConfig.wsl2 -and $currentConfig.wsl2.processors) { $currentConfig.wsl2.processors } else { "Default" }
        }
        
        Write-Host "WSL Performance Metrics:" -ForegroundColor Green
        Write-Host "  WSL Processes: $($metrics.WSLProcesses)" -ForegroundColor Gray
        Write-Host "  Memory Usage: $($metrics.TotalMemoryUsageMB) MB" -ForegroundColor Gray
        Write-Host "  Configured Memory Limit: $($metrics.ConfiguredMemory)" -ForegroundColor Gray
        Write-Host "  Configured Processors: $($metrics.ConfiguredProcessors)" -ForegroundColor Gray
        
        return $metrics
    }
    catch {
        Write-Error "Failed to get WSL performance metrics: $($_.Exception.Message)"
        return $null
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-SystemHardwareInfo',
    'Get-OptimalResourceLimits',
    'Set-WSLPerformanceProfile',
    'Optimize-WSLNetwork',
    'Optimize-WSLStorage',
    'New-WSLOptimizedConfig',
    'Switch-WSLPerformanceProfile',
    'Get-WSLPerformanceMetrics'
)