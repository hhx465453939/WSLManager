# WSL健康监控模块测试脚本

# 导入模块
Import-Module "$PSScriptRoot\WSL-HealthMonitor.psm1" -Force

Write-Host "=== WSL健康监控模块测试 ===" -ForegroundColor Cyan
Write-Host "测试时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# 测试1: WSL服务状态检测
Write-Host "`n测试1: WSL服务状态检测" -ForegroundColor Yellow
try {
    $serviceStatus = Test-WSLServiceStatus -Detailed
    Write-Host "✓ WSL服务状态检测成功" -ForegroundColor Green
    Write-Host "  整体状态: $($serviceStatus.OverallStatus)" -ForegroundColor White
}
catch {
    Write-Host "✗ WSL服务状态检测失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试2: 资源使用监控
Write-Host "`n测试2: 资源使用监控" -ForegroundColor Yellow
try {
    $resourceUsage = Get-WSLResourceUsage
    Write-Host "✓ 资源使用监控成功" -ForegroundColor Green
    Write-Host "  系统内存使用率: $($resourceUsage.SystemMemory.UsagePercent)%" -ForegroundColor White
    Write-Host "  WSL进程数量: $($resourceUsage.WSLProcesses.Count)" -ForegroundColor White
}
catch {
    Write-Host "✗ 资源使用监控失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试3: 网络连接检查
Write-Host "`n测试3: 网络连接检查" -ForegroundColor Yellow
try {
    $networkStatus = Test-WSLNetworkConnectivity
    Write-Host "✓ 网络连接检查成功" -ForegroundColor Green
    Write-Host "  整体网络状态: $($networkStatus.OverallStatus)" -ForegroundColor White
    Write-Host "  Windows网络状态: $($networkStatus.WindowsNetworkStatus)" -ForegroundColor White
}
catch {
    Write-Host "✗ 网络连接检查失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试4: 综合健康检查
Write-Host "`n测试4: 综合健康检查" -ForegroundColor Yellow
try {
    $healthReport = Test-WSLHealth -Detailed
    Write-Host "✓ 综合健康检查成功" -ForegroundColor Green
    Write-Host "  整体健康状态: $($healthReport.OverallHealth)" -ForegroundColor White
    Write-Host "  建议数量: $($healthReport.Recommendations.Count)" -ForegroundColor White
}
catch {
    Write-Host "✗ 综合健康检查失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试5: JSON格式输出
Write-Host "`n测试5: JSON格式输出" -ForegroundColor Yellow
try {
    $jsonReport = Test-WSLHealth -OutputFormat "JSON"
    if ($jsonReport -and $jsonReport.StartsWith("{")) {
        Write-Host "✓ JSON格式输出成功" -ForegroundColor Green
        Write-Host "  JSON长度: $($jsonReport.Length) 字符" -ForegroundColor White
    } else {
        Write-Host "✗ JSON格式输出格式错误" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ JSON格式输出失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试6: HTML格式输出
Write-Host "`n测试6: HTML格式输出" -ForegroundColor Yellow
try {
    $htmlReport = Test-WSLHealth -OutputFormat "HTML"
    if ($htmlReport -and $htmlReport.Contains("<html>")) {
        Write-Host "✓ HTML格式输出成功" -ForegroundColor Green
        Write-Host "  HTML长度: $($htmlReport.Length) 字符" -ForegroundColor White
    } else {
        Write-Host "✗ HTML格式输出格式错误" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ HTML格式输出失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Cyan