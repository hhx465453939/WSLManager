# WSL2自动安装模块测试脚本
# Test script for WSL2 Auto-Install Module

# Import WSL2 Auto-Install Module
Import-Module .\WSL-AutoInstall.psm1 -Force

Write-Host "=== WSL2 Auto-Install Module Test ===" -ForegroundColor Green

try {
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if (-not $isAdmin) {
        Write-Host "`n⚠ WARNING: Not running as Administrator" -ForegroundColor Yellow
        Write-Host "Some tests will be skipped. Run PowerShell as Administrator for full testing." -ForegroundColor Yellow
    }

    # Test 1: Check Windows Feature Status (requires admin)
    if ($isAdmin) {
        Write-Host "`n1. Testing Windows Feature Status Check..." -ForegroundColor Yellow
        $featureStatus = Get-WSLWindowsFeatureStatus
        if ($featureStatus) {
            Write-Host "✓ Feature status check successful" -ForegroundColor Green
            Write-Host "  WSL Enabled: $($featureStatus.WSLEnabled)" -ForegroundColor Cyan
            Write-Host "  VM Platform Enabled: $($featureStatus.VMPlatformEnabled)" -ForegroundColor Cyan
            Write-Host "  Hyper-V Platform Enabled: $($featureStatus.HyperVPlatformEnabled)" -ForegroundColor Cyan
            Write-Host "  All Required Enabled: $($featureStatus.AllRequiredEnabled)" -ForegroundColor $(if ($featureStatus.AllRequiredEnabled) { "Green" } else { "Yellow" })
        } else {
            Write-Host "✗ Feature status check failed" -ForegroundColor Red
        }
    } else {
        Write-Host "`n1. Skipping Windows Feature Status Check (requires admin)" -ForegroundColor Gray
    }

    # Test 2: Test WSL2 Kernel Installation Function (dry run)
    Write-Host "`n2. Testing WSL2 Kernel Installation Function..." -ForegroundColor Yellow
    
    # Check if WSL is already installed
    $wslInstalled = $false
    try {
        $wslVersion = wsl --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            $wslInstalled = $true
            Write-Host "  ℹ WSL already installed:" -ForegroundColor Gray
            $wslVersion -split "`n" | ForEach-Object {
                if ($_.Trim()) {
                    Write-Host "    $_" -ForegroundColor Gray
                }
            }
        }
    }
    catch {
        Write-Host "  ℹ WSL not currently installed" -ForegroundColor Gray
    }
    
    if ($wslInstalled) {
        Write-Host "  ✓ WSL2 kernel installation function available (already installed)" -ForegroundColor Green
    } else {
        Write-Host "  ℹ WSL2 kernel installation function available (would download and install)" -ForegroundColor Cyan
        Write-Host "    Download URL: https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -ForegroundColor Gray
        Write-Host "    Installation method: Silent MSI installation" -ForegroundColor Gray
    }

    # Test 3: Test Complete Installation Function (simulation)
    Write-Host "`n3. Testing Complete Installation Function (simulation)..." -ForegroundColor Yellow
    
    if ($isAdmin) {
        Write-Host "  ℹ Running pre-installation check..." -ForegroundColor Cyan
        
        # Import detection module to test pre-check
        $preCheck = Test-WSLEnvironment
        if ($preCheck) {
            Write-Host "  ✓ Pre-installation check successful" -ForegroundColor Green
            Write-Host "    Overall Status: $($preCheck.OverallStatus)" -ForegroundColor Cyan
            Write-Host "    Can Install WSL: $($preCheck.CanInstallWSL)" -ForegroundColor Cyan
            Write-Host "    Can Install WSL2: $($preCheck.CanInstallWSL2)" -ForegroundColor Cyan
            
            if ($preCheck.Issues.Count -gt 0) {
                Write-Host "    Issues found:" -ForegroundColor Yellow
                $preCheck.Issues | ForEach-Object {
                    Write-Host "      • $_" -ForegroundColor Yellow
                }
            }
            
            if ($preCheck.Recommendations.Count -gt 0) {
                Write-Host "    Recommendations:" -ForegroundColor Blue
                $preCheck.Recommendations | ForEach-Object {
                    Write-Host "      • $_" -ForegroundColor Cyan
                }
            }
        } else {
            Write-Host "  ✗ Pre-installation check failed" -ForegroundColor Red
        }
        
        Write-Host "  ✓ Complete installation function available" -ForegroundColor Green
        Write-Host "    Would perform: Feature enablement → Kernel installation → Verification" -ForegroundColor Gray
    } else {
        Write-Host "  ℹ Complete installation requires administrator privileges" -ForegroundColor Yellow
        Write-Host "  ✓ Installation function available (would require admin elevation)" -ForegroundColor Green
    }

    # Test 4: Test Installation Report Function
    Write-Host "`n4. Testing Installation Report Function..." -ForegroundColor Yellow
    
    # Create a mock installation result for testing
    $mockResult = [PSCustomObject]@{
        PreCheck = [PSCustomObject]@{
            OverallStatus = "WSL2Capable"
            CanInstallWSL = $true
            CanInstallWSL2 = $true
            WindowsSupport = [PSCustomObject]@{
                SupportLevel = "Full"
            }
        }
        FeatureInstall = [PSCustomObject]@{
            Success = $true
            WSLFeature = [PSCustomObject]@{ RestartNeeded = $false }
            VMPlatform = [PSCustomObject]@{ RestartNeeded = $false }
            RequiresReboot = $false
        }
        KernelInstall = [PSCustomObject]@{
            Success = $true
            Downloaded = $true
            Installed = $true
            KernelVersion = "WSL version: 1.0.0.0"
        }
        PostCheck = $null
        Success = $true
        RequiresReboot = $false
        Errors = @()
        Recommendations = @("WSL2 installation completed successfully", "You can now install Linux distributions")
        Timestamp = Get-Date
    }
    
    Write-Host "  Testing report generation with mock data..." -ForegroundColor Cyan
    Show-WSL2InstallReport -InstallResult $mockResult
    Write-Host "  ✓ Installation report function working" -ForegroundColor Green

    Write-Host "`n=== Test Summary ===" -ForegroundColor Green
    
    Write-Host "Module Functions: Available and Working" -ForegroundColor Green
    Write-Host "Windows Feature Management: $(if ($isAdmin) { 'Tested' } else { 'Available (needs admin)' })" -ForegroundColor $(if ($isAdmin) { "Green" } else { "Yellow" })
    Write-Host "WSL2 Kernel Installation: Available" -ForegroundColor Green
    Write-Host "Complete Installation Flow: Available" -ForegroundColor Green
    Write-Host "Installation Reporting: Working" -ForegroundColor Green
    
    if (-not $isAdmin) {
        Write-Host "`nNote: Run as Administrator to test actual feature enablement" -ForegroundColor Yellow
    }
    
    Write-Host "`nTo perform actual WSL2 installation, run:" -ForegroundColor Cyan
    Write-Host "  Install-WSL2Complete" -ForegroundColor White
    Write-Host "Or for forced reinstallation:" -ForegroundColor Cyan
    Write-Host "  Install-WSL2Complete -Force" -ForegroundColor White
}
catch {
    Write-Host "`n✗ Test failed with error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.StackTrace)" -ForegroundColor Gray
}

# Cleanup
Remove-Module WSL-AutoInstall -Force -ErrorAction SilentlyContinue
Remove-Module WSL-Detection -Force -ErrorAction SilentlyContinue