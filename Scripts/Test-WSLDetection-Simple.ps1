# Simple WSL Detection Test (No Admin Required)
# 简单WSL检测测试（无需管理员权限）

# Import WSL Detection Module
Import-Module ..\Modules\WSL-Detection.psm1 -Force

Write-Host "=== Simple WSL Detection Test ===" -ForegroundColor Green

try {
    # Test Windows version detection only
    Write-Host "`n1. Testing Windows Version Detection..." -ForegroundColor Yellow
    $windowsSupport = Test-WindowsWSLSupport
    if ($windowsSupport) {
        Write-Host "✓ Windows version detection successful" -ForegroundColor Green
        Write-Host "  OS: $($windowsSupport.OSName)" -ForegroundColor Cyan
        Write-Host "  Build: $($windowsSupport.BuildNumber)" -ForegroundColor Cyan
        Write-Host "  WSL Support: $($windowsSupport.IsWSLSupported)" -ForegroundColor $(if ($windowsSupport.IsWSLSupported) { "Green" } else { "Red" })
        Write-Host "  WSL2 Support: $($windowsSupport.IsWSL2Supported)" -ForegroundColor $(if ($windowsSupport.IsWSL2Supported) { "Green" } else { "Red" })
        Write-Host "  Support Level: $($windowsSupport.SupportLevel)" -ForegroundColor Cyan
        
        if ($windowsSupport.Recommendations.Count -gt 0) {
            Write-Host "  Recommendations:" -ForegroundColor Yellow
            $windowsSupport.Recommendations | ForEach-Object {
                Write-Host "    • $_" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "✗ Windows version detection failed" -ForegroundColor Red
    }

    # Test hardware virtualization detection
    Write-Host "`n2. Testing Hardware Virtualization Detection..." -ForegroundColor Yellow
    $hardwareSupport = Test-HardwareVirtualization
    if ($hardwareSupport) {
        Write-Host "✓ Hardware virtualization detection successful" -ForegroundColor Green
        Write-Host "  CPU: $($hardwareSupport.CPUInfo.Name)" -ForegroundColor Cyan
        Write-Host "  Manufacturer: $($hardwareSupport.CPUInfo.Manufacturer)" -ForegroundColor Cyan
        Write-Host "  Cores: $($hardwareSupport.CPUInfo.NumberOfCores)" -ForegroundColor Cyan
        Write-Host "  Logical Processors: $($hardwareSupport.CPUInfo.NumberOfLogicalProcessors)" -ForegroundColor Cyan
        Write-Host "  Virtualization Supported: $($hardwareSupport.VirtualizationSupported)" -ForegroundColor $(if ($hardwareSupport.VirtualizationSupported) { "Green" } else { "Red" })
        Write-Host "  Virtualization Enabled: $($hardwareSupport.VirtualizationEnabled)" -ForegroundColor $(if ($hardwareSupport.VirtualizationEnabled) { "Green" } else { "Red" })
        Write-Host "  WSL2 Compatible: $($hardwareSupport.WSL2Compatible)" -ForegroundColor $(if ($hardwareSupport.WSL2Compatible) { "Green" } else { "Red" })
        
        if ($hardwareSupport.Issues.Count -gt 0) {
            Write-Host "  Issues:" -ForegroundColor Red
            $hardwareSupport.Issues | ForEach-Object {
                Write-Host "    • $_" -ForegroundColor Yellow
            }
        }
        
        if ($hardwareSupport.Recommendations.Count -gt 0) {
            Write-Host "  Recommendations:" -ForegroundColor Blue
            $hardwareSupport.Recommendations | ForEach-Object {
                Write-Host "    • $_" -ForegroundColor Cyan
            }
        }
    } else {
        Write-Host "✗ Hardware virtualization detection failed" -ForegroundColor Red
    }

    Write-Host "`n=== Test Summary ===" -ForegroundColor Green
    
    if ($windowsSupport -and $hardwareSupport) {
        Write-Host "Basic Detection Functions: Working" -ForegroundColor Green
        Write-Host "Windows WSL Support: $($windowsSupport.SupportLevel)" -ForegroundColor Cyan
        Write-Host "Hardware Compatibility: $(if ($hardwareSupport.WSL2Compatible) { 'WSL2 Ready' } else { 'Limited' })" -ForegroundColor $(if ($hardwareSupport.WSL2Compatible) { "Green" } else { "Yellow" })
        
        Write-Host "`nNote: Full feature detection requires administrator privileges" -ForegroundColor Yellow
        Write-Host "Run PowerShell as Administrator for complete WSL feature status" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "`n✗ Test failed with error: $($_.Exception.Message)" -ForegroundColor Red
}

# Cleanup
Remove-Module WSL-Detection -Force -ErrorAction SilentlyContinue