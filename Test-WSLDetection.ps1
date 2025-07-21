# WSL检测模块测试脚本
# Test script for WSL Detection Module

# 导入WSL检测模块
Import-Module .\WSL-Detection.psm1 -Force

Write-Host "=== WSL功能检测模块测试 ===" -ForegroundColor Green

try {
    # 测试Windows版本检测
    Write-Host "`n1. 测试Windows版本检测..." -ForegroundColor Yellow
    $windowsSupport = Test-WindowsWSLSupport
    if ($windowsSupport) {
        Write-Host "✓ Windows版本检测成功" -ForegroundColor Green
        Write-Host "  操作系统: $($windowsSupport.OSName)"
        Write-Host "  内部版本号: $($windowsSupport.BuildNumber)"
        Write-Host "  WSL支持: $($windowsSupport.IsWSLSupported)"
        Write-Host "  WSL2支持: $($windowsSupport.IsWSL2Supported)"
    } else {
        Write-Host "✗ Windows版本检测失败" -ForegroundColor Red
    }

    # 测试Hyper-V功能检测
    Write-Host "`n2. 测试Hyper-V功能检测..." -ForegroundColor Yellow
    $hyperVStatus = Test-HyperVFeature
    if ($hyperVStatus) {
        Write-Host "✓ Hyper-V功能检测成功" -ForegroundColor Green
        Write-Host "  虚拟机平台: $($hyperVStatus.VirtualMachinePlatformEnabled)"
        Write-Host "  WSL2就绪: $($hyperVStatus.WSL2Ready)"
        if ($hyperVStatus.MissingFeatures.Count -gt 0) {
            Write-Host "  缺少功能: $($hyperVStatus.MissingFeatures -join ', ')" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✗ Hyper-V功能检测失败" -ForegroundColor Red
    }

    # 测试WSL功能检测
    Write-Host "`n3. 测试WSL功能检测..." -ForegroundColor Yellow
    $wslStatus = Test-WSLFeature
    if ($wslStatus) {
        Write-Host "✓ WSL功能检测成功" -ForegroundColor Green
        Write-Host "  WSL功能启用: $($wslStatus.WSLFeatureEnabled)"
        Write-Host "  WSL已安装: $($wslStatus.WSLInstalled)"
        Write-Host "  WSL就绪: $($wslStatus.WSLReady)"
    } else {
        Write-Host "✗ WSL功能检测失败" -ForegroundColor Red
    }

    # 测试硬件虚拟化检测
    Write-Host "`n4. 测试硬件虚拟化检测..." -ForegroundColor Yellow
    $hardwareSupport = Test-HardwareVirtualization
    if ($hardwareSupport) {
        Write-Host "✓ 硬件虚拟化检测成功" -ForegroundColor Green
        Write-Host "  CPU: $($hardwareSupport.CPUInfo.Name)"
        Write-Host "  虚拟化支持: $($hardwareSupport.VirtualizationSupported)"
        Write-Host "  虚拟化启用: $($hardwareSupport.VirtualizationEnabled)"
        Write-Host "  WSL2兼容: $($hardwareSupport.WSL2Compatible)"
        if ($hardwareSupport.Issues.Count -gt 0) {
            Write-Host "  问题: $($hardwareSupport.Issues -join '; ')" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✗ 硬件虚拟化检测失败" -ForegroundColor Red
    }

    # 测试综合检测
    Write-Host "`n5. 测试综合WSL环境检测..." -ForegroundColor Yellow
    $detectionResult = Test-WSLEnvironment -Detailed
    if ($detectionResult) {
        Write-Host "✓ 综合检测成功" -ForegroundColor Green
        Show-WSLDetectionReport -DetectionResult $detectionResult -ShowDetails
    } else {
        Write-Host "✗ 综合检测失败" -ForegroundColor Red
    }

    Write-Host "`n=== 测试完成 ===" -ForegroundColor Green
}
catch {
    Write-Host "`n✗ 测试过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "错误详情: $($_.Exception.StackTrace)" -ForegroundColor Gray
}

# 清理
Remove-Module WSL-Detection -Force -ErrorAction SilentlyContinue