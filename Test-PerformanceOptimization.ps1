# WSL Performance Optimization Module Test Script

# Import modules
Import-Module "$PSScriptRoot\WSL-ConfigManager.psm1" -Force
Import-Module "$PSScriptRoot\WSL-PerformanceOptimizer.psm1" -Force

Write-Host "=== WSL Performance Optimization Module Test ===" -ForegroundColor Cyan

# Test 1: Verify module import
Write-Host "`n1. Testing module import..." -ForegroundColor Yellow
$functions = Get-Command -Module WSL-PerformanceOptimizer
Write-Host "Imported $($functions.Count) functions:" -ForegroundColor Green
$functions.Name | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }

# Test 2: Test system hardware information
Write-Host "`n2. Testing system hardware information..." -ForegroundColor Yellow
$hardwareInfo = Get-SystemHardwareInfo
if ($hardwareInfo) {
    Write-Host "✓ System hardware information retrieved successfully" -ForegroundColor Green
    Write-Host "  Total Memory: $($hardwareInfo.TotalMemoryGB) GB" -ForegroundColor Gray
    Write-Host "  Logical Processors: $($hardwareInfo.LogicalProcessors)" -ForegroundColor Gray
} else {
    Write-Host "✗ Failed to retrieve system hardware information" -ForegroundColor Red
}

# Test 3: Test optimal resource limits calculation
Write-Host "`n3. Testing optimal resource limits calculation..." -ForegroundColor Yellow
$profiles = @("development", "gaming", "server", "minimal", "docker")
foreach ($profile in $profiles) {
    Write-Host "  Testing profile: $profile" -ForegroundColor Gray
    $limits = Get-OptimalResourceLimits -UsageProfile $profile
    if ($limits) {
        Write-Host "    ✓ $profile profile: Memory=$($limits.Memory), Processors=$($limits.Processors)" -ForegroundColor Green
    } else {
        Write-Host "    ✗ Failed to calculate limits for $profile profile" -ForegroundColor Red
    }
}

# Test 4: Test performance profile application (without applying)
Write-Host "`n4. Testing performance profile application..." -ForegroundColor Yellow
$testProfiles = @("gaming", "server", "minimal", "docker-optimized")
foreach ($profile in $testProfiles) {
    Write-Host "  Testing profile: $profile" -ForegroundColor Gray
    try {
        # Create a test configuration without applying
        $testConfigPath = "$PSScriptRoot\test-config\.wslconfig-$profile"
        
        # Get the profile configuration and create test config
        $result = Set-WSLPerformanceProfile -ProfileName $profile
        if ($result.Success) {
            Write-Host "    ✓ $profile profile configuration created successfully" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Failed to create $profile profile configuration: $($result.Error)" -ForegroundColor Red
        }
    } catch {
        Write-Host "    ✗ Exception testing $profile profile: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 5: Test network optimization
Write-Host "`n5. Testing network optimization..." -ForegroundColor Yellow
$networkTypes = @("high-throughput", "low-latency", "balanced")
foreach ($type in $networkTypes) {
    Write-Host "  Testing network optimization: $type" -ForegroundColor Gray
    try {
        $result = Optimize-WSLNetwork -OptimizationType $type
        if ($result.Success) {
            Write-Host "    ✓ $type network optimization applied successfully" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Failed to apply $type network optimization: $($result.Error)" -ForegroundColor Red
        }
    } catch {
        Write-Host "    ✗ Exception testing $type network optimization: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 6: Test storage optimization
Write-Host "`n6. Testing storage optimization..." -ForegroundColor Yellow
$storageTypes = @("performance", "space-saving", "balanced")
foreach ($type in $storageTypes) {
    Write-Host "  Testing storage optimization: $type" -ForegroundColor Gray
    try {
        $result = Optimize-WSLStorage -OptimizationType $type
        if ($result.Success) {
            Write-Host "    ✓ $type storage optimization applied successfully" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Failed to apply $type storage optimization: $($result.Error)" -ForegroundColor Red
        }
    } catch {
        Write-Host "    ✗ Exception testing $type storage optimization: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 7: Test comprehensive optimization configuration
Write-Host "`n7. Testing comprehensive optimization configuration..." -ForegroundColor Yellow
try {
    $result = New-WSLOptimizedConfig -UsageProfile "development" -NetworkOptimization "balanced" -StorageOptimization "balanced"
    if ($result.Success) {
        Write-Host "✓ Comprehensive optimization configuration created successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to create comprehensive optimization configuration: $($result.Error)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Exception testing comprehensive optimization: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 8: Test performance profile switching
Write-Host "`n8. Testing performance profile switching..." -ForegroundColor Yellow
$switchProfiles = @("development", "balanced", "high-performance")
foreach ($profile in $switchProfiles) {
    Write-Host "  Testing profile switch: $profile" -ForegroundColor Gray
    try {
        $result = Switch-WSLPerformanceProfile -ProfileName $profile
        if ($result.Success) {
            Write-Host "    ✓ Successfully switched to $profile profile" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Failed to switch to $profile profile: $($result.Error)" -ForegroundColor Red
        }
    } catch {
        Write-Host "    ✗ Exception switching to $profile profile: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 9: Test performance metrics
Write-Host "`n9. Testing performance metrics..." -ForegroundColor Yellow
try {
    $metrics = Get-WSLPerformanceMetrics
    if ($metrics) {
        Write-Host "✓ Performance metrics retrieved successfully" -ForegroundColor Green
        Write-Host "  WSL Processes: $($metrics.WSLProcesses)" -ForegroundColor Gray
        Write-Host "  Memory Usage: $($metrics.TotalMemoryUsageMB) MB" -ForegroundColor Gray
    } else {
        Write-Host "✗ Failed to retrieve performance metrics" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Exception testing performance metrics: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 10: Verify configuration files
Write-Host "`n10. Verifying configuration files..." -ForegroundColor Yellow
$configPath = "$env:USERPROFILE\.wslconfig"
if (Test-Path $configPath) {
    Write-Host "✓ WSL configuration file exists: $configPath" -ForegroundColor Green
    
    # Read and display current configuration
    try {
        $currentConfig = Get-WSLConfig -ConfigPath $configPath
    } catch {
        # Try to read the file directly if the function is not available
        $currentConfig = Get-Content $configPath -Raw
    }
    if ($currentConfig) {
        Write-Host "✓ Configuration file is valid and readable" -ForegroundColor Green
        Write-Host "Current configuration sections:" -ForegroundColor Gray
        $currentConfig.Keys | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    } else {
        Write-Host "✗ Configuration file exists but is not readable" -ForegroundColor Red
    }
} else {
    Write-Host "! No WSL configuration file found (this is normal if no configuration has been applied)" -ForegroundColor Yellow
}

# Cleanup
Write-Host "`n11. Cleanup..." -ForegroundColor Yellow
$testDir = "$PSScriptRoot\test-config"
if (Test-Path $testDir) {
    Remove-Item $testDir -Recurse -Force
    Write-Host "✓ Cleaned up test directory" -ForegroundColor Green
}

Write-Host "`n=== WSL Performance Optimization Module Test Complete ===" -ForegroundColor Cyan