# WSL权限管理功能测试脚本

# 导入模块
Import-Module .\WSL-SecurityManager.psm1 -Force

Write-Host "=== WSL权限管理功能测试 ===" -ForegroundColor Green

# 获取可用的WSL发行版
$distributions = wsl -l -q
if (-not $distributions) {
    Write-Error "未找到已安装的WSL发行版"
    exit 1
}

$testDistribution = $distributions[0]
Write-Host "使用发行版进行测试: $testDistribution" -ForegroundColor Yellow

# 测试1: 检查用户权限
Write-Host "`n--- 测试1: 检查用户权限 ---" -ForegroundColor Cyan
try {
    # 获取当前用户
    $currentUser = wsl -d $testDistribution -- whoami
    Write-Host "当前用户: $currentUser"
    
    $userPermissions = Test-WSLUserPermissions -DistributionName $testDistribution -UserName $currentUser
    if ($userPermissions) {
        Write-Host "用户权限检查成功" -ForegroundColor Green
        Write-Host "用户信息: $($userPermissions.UserInfo)"
        Write-Host "所属组: $($userPermissions.Groups)"
        Write-Host "Sudo权限: $($userPermissions.HasSudo)"
        Write-Host "在Sudo组中: $($userPermissions.InSudoGroup)"
    } else {
        Write-Warning "用户权限检查失败"
    }
}
catch {
    Write-Error "测试1失败: $($_.Exception.Message)"
}

# 测试2: 检查文件系统权限
Write-Host "`n--- 测试2: 检查文件系统权限 ---" -ForegroundColor Cyan
try {
    $homeDir = wsl -d $testDistribution -- eval 'echo $HOME'
    Write-Host "检查主目录权限: $homeDir"
    
    $fsPermissions = Test-WSLFileSystemPermissions -DistributionName $testDistribution -Path $homeDir
    if ($fsPermissions) {
        Write-Host "文件系统权限检查成功" -ForegroundColor Green
        Write-Host "路径: $($fsPermissions.Path)"
        if ($fsPermissions.WorldWritableFiles) {
            Write-Warning "发现全局可写文件: $($fsPermissions.WorldWritableFiles)"
        }
        if ($fsPermissions.SetuidFiles) {
            Write-Warning "发现Setuid文件: $($fsPermissions.SetuidFiles)"
        }
    } else {
        Write-Warning "文件系统权限检查失败"
    }
}
catch {
    Write-Error "测试2失败: $($_.Exception.Message)"
}

# 测试3: 创建测试目录并设置权限
Write-Host "`n--- 测试3: 设置文件系统权限 ---" -ForegroundColor Cyan
try {
    $testDir = "/tmp/wsl-security-test"
    Write-Host "创建测试目录: $testDir"
    
    # 创建测试目录
    wsl -d $testDistribution -- mkdir -p $testDir
    wsl -d $testDistribution -- sh -c "echo 'test content' > $testDir/test.txt"
    
    # 设置权限
    $permResult = Set-WSLFileSystemPermissions -DistributionName $testDistribution -Path $testDir -Mode "755" -Recursive
    if ($permResult) {
        Write-Host "权限设置成功" -ForegroundColor Green
        Write-Host "变更: $($permResult.Changes -join ', ')"
        
        # 验证权限设置
        $verifyPerms = wsl -d $testDistribution -- ls -la $testDir
        Write-Host "验证权限: $verifyPerms"
    } else {
        Write-Warning "权限设置失败"
    }
    
    # 清理测试目录
    wsl -d $testDistribution -- rm -rf $testDir
}
catch {
    Write-Error "测试3失败: $($_.Exception.Message)"
}

# 测试4: 生成权限审计报告
Write-Host "`n--- 测试4: 生成权限审计报告 ---" -ForegroundColor Cyan
try {
    $auditResult = New-WSLPermissionAuditReport -DistributionName $testDistribution -OutputPath ".\security-audit-test"
    if ($auditResult) {
        Write-Host "权限审计报告生成成功" -ForegroundColor Green
        Write-Host "JSON报告: $($auditResult.JsonReport)"
        Write-Host "HTML报告: $($auditResult.HtmlReport)"
        
        # 显示报告摘要
        $reportData = $auditResult.ReportData
        Write-Host "用户数量: $($reportData.Users.Count)"
        Write-Host "安全问题数量: $($reportData.SecurityIssues.Count)"
        
        if ($reportData.SecurityIssues.Count -gt 0) {
            Write-Host "发现的安全问题:" -ForegroundColor Yellow
            foreach ($issue in $reportData.SecurityIssues) {
                Write-Host "  - $($issue.Type): $($issue.Description) (严重程度: $($issue.Severity))" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Warning "权限审计报告生成失败"
    }
}
catch {
    Write-Error "测试4失败: $($_.Exception.Message)"
}

# 测试5: 用户权限设置（如果有sudo权限）
Write-Host "`n--- 测试5: 用户权限设置测试 ---" -ForegroundColor Cyan
try {
    # 检查是否有sudo权限
    $hasSudo = wsl -d $testDistribution -- sudo -n true 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "当前用户有sudo权限，测试权限设置功能"
        
        # 创建测试用户（如果不存在）
        $testUser = "wsl-test-user"
        $userExists = wsl -d $testDistribution -- id $testUser 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "创建测试用户: $testUser"
            wsl -d $testDistribution -- sudo useradd -m $testUser 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "测试用户创建成功"
                
                # 测试权限设置
                $permSetResult = Set-WSLUserPermissions -DistributionName $testDistribution -UserName $testUser -Groups @("users")
                if ($permSetResult) {
                    Write-Host "用户权限设置成功" -ForegroundColor Green
                    Write-Host "变更: $($permSetResult.Changes -join ', ')"
                }
                
                # 清理测试用户
                wsl -d $testDistribution -- sudo userdel -r $testUser 2>$null
                Write-Host "测试用户已清理"
            } else {
                Write-Warning "无法创建测试用户"
            }
        } else {
            Write-Host "测试用户已存在，跳过创建"
        }
    } else {
        Write-Host "当前用户没有sudo权限，跳过用户权限设置测试" -ForegroundColor Yellow
    }
}
catch {
    Write-Error "测试5失败: $($_.Exception.Message)"
}

Write-Host "`n=== WSL权限管理功能测试完成 ===" -ForegroundColor Green