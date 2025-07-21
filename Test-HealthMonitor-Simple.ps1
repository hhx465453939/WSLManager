# WSL健康监控模块简单测试脚本

# 导入模块
Import-Module "$PSScriptRoot\WSL-HealthMonitor.psm1" -Force

Write-Host "=== WSL健康监控模块测试 ===" -ForegroundColor Cyan
Write-Host "测试时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# 测试1: WSL服务状态检测
Write-Host "`n测试1: WSL服务状态检测" -ForegroundColor Yellow
$serviceStatus = Test-WSLServiceStatus -Detailed
Write-Host "✓ WSL服务状态检测完成" -ForegroundColor Green

# 测试2: 资源使用监控
Write-Host "`n测试2: 资源使用监控" -ForegroundColor Yellow
$resourceUsage = Get-WSLResourceUsage
Write-Host "✓ 资源使用监控完成" -ForegroundColor Green

# 测试3: 网络连接检查
Write-Host "`n测试3: 网络连接检查" -ForegroundColor Yellow
$networkStatus = Test-WSLNetworkConnectivity
Write-Host "✓ 网络连接检查完成" -ForegroundColor Green

# 测试4: 综合健康检查
Write-Host "`n测试4: 综合健康检查" -ForegroundColor Yellow
$healthReport = Test-WSLHealth -Detailed
Write-Host "✓ 综合健康检查完成" -ForegroundColor Green

Write-Host "`n=== 所有测试完成 ===" -ForegroundColor Cyan