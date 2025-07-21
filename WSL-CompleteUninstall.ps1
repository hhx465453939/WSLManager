# WSL完全卸载脚本
# 警告: 此脚本将完全删除WSL及所有相关数据
# 使用方法: .\WSL-CompleteUninstall.ps1 -BackupFirst -Force

param(
    [switch]$BackupFirst = $true,
    [switch]$Force = $false,
    [string]$BackupPath = "C:\WSL-Emergency-Backup"
)

# 检查管理员权限
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "此脚本需要管理员权限。请以管理员身份运行PowerShell。"
    exit 1
}

Write-Host "========================================" -ForegroundColor Red
Write-Host "        WSL完全卸载工具" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host "警告: 此操作将完全删除WSL及所有数据!" -ForegroundColor Yellow

if (!$Force) {
    Write-Host ""
    $Confirm = Read-Host "确认要继续吗？输入 'YES' 确认，其他任意键取消"
    if ($Confirm -ne 'YES') {
        Write-Host "操作已取消" -ForegroundColor Green
        exit 0
    }
}

# 步骤1: 备份数据
if ($BackupFirst) {
    Write-Host ""
    Write-Host "步骤1: 备份WSL发行版..." -ForegroundColor Green
    
    $BackupDir = "$BackupPath-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    
    try {
        $Distributions = wsl -l -q 2>$null | Where-Object { $_ -and $_.Trim() -ne "" }
        if ($Distributions) {
            foreach ($Dist in $Distributions) {
                $DistName = $Dist.Trim()
                Write-Host "  备份 $DistName..." -NoNewline
                wsl --export $DistName "$BackupDir\$DistName-emergency-backup.tar" 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host " 完成" -ForegroundColor Green
                } else {
                    Write-Host " 失败" -ForegroundColor Red
                }
            }
            Write-Host "备份完成，位置: $BackupDir" -ForegroundColor Cyan
        } else {
            Write-Host "  未发现WSL发行版" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "备份过程中出现错误: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 步骤2: 关闭WSL
Write-Host ""
Write-Host "步骤2: 关闭WSL服务..." -ForegroundColor Green
try {
    wsl --shutdown 2>$null
    Start-Sleep -Seconds 3
    Write-Host "  WSL已关闭" -ForegroundColor Cyan
} catch {
    Write-Host "  关闭WSL时出现错误" -ForegroundColor Yellow
}

# 步骤3: 卸载所有发行版
Write-Host ""
Write-Host "步骤3: 卸载WSL发行版..." -ForegroundColor Green
try {
    $Distributions = wsl -l -q 2>$null | Where-Object { $_ -and $_.Trim() -ne "" }
    if ($Distributions) {
        foreach ($Dist in $Distributions) {
            $DistName = $Dist.Trim()
            Write-Host "  卸载 $DistName..." -NoNewline
            wsl --unregister $DistName 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host " 完成" -ForegroundColor Green
            } else {
                Write-Host " 失败" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  未发现已安装的发行版" -ForegroundColor Yellow
    }
} catch {
    Write-Host "卸载发行版时出现错误: $($_.Exception.Message)" -ForegroundColor Red
}

# 步骤4: 停止相关服务
Write-Host ""
Write-Host "步骤4: 停止WSL相关服务..." -ForegroundColor Green
$Services = @("LxssManager", "vmcompute")
foreach ($ServiceName in $Services) {
    try {
        $Service = Get-Service $ServiceName -ErrorAction SilentlyContinue
        if ($Service) {
            Write-Host "  停止服务 $ServiceName..." -NoNewline
            Stop-Service $ServiceName -Force -ErrorAction SilentlyContinue
            Write-Host " 完成" -ForegroundColor Green
        }
    } catch {
        Write-Host " 失败" -ForegroundColor Red
    }
}

# 步骤5: 终止相关进程
Write-Host ""
Write-Host "步骤5: 终止WSL相关进程..." -ForegroundColor Green
$ProcessNames = @("wsl", "lxss", "wslhost")
foreach ($ProcessName in $ProcessNames) {
    try {
        $Processes = Get-Process -Name "*$ProcessName*" -ErrorAction SilentlyContinue
        if ($Processes) {
            Write-Host "  终止进程 $ProcessName..." -NoNewline
            $Processes | Stop-Process -Force -ErrorAction SilentlyContinue
            Write-Host " 完成" -ForegroundColor Green
        }
    } catch {
        Write-Host " 失败" -ForegroundColor Red
    }
}

# 步骤6: 禁用Windows功能
Write-Host ""
Write-Host "步骤6: 禁用Windows功能..." -ForegroundColor Green
$Features = @(
    @{Name="Microsoft-Windows-Subsystem-Linux"; Display="WSL"},
    @{Name="VirtualMachinePlatform"; Display="虚拟机平台"}
)

foreach ($Feature in $Features) {
    try {
        Write-Host "  禁用 $($Feature.Display)..." -NoNewline
        Disable-WindowsOptionalFeature -Online -FeatureName $Feature.Name -NoRestart -ErrorAction SilentlyContinue | Out-Null
        Write-Host " 完成" -ForegroundColor Green
    } catch {
        Write-Host " 失败" -ForegroundColor Red
    }
}

# 步骤7: 清理注册表
Write-Host ""
Write-Host "步骤7: 清理注册表..." -ForegroundColor Green
$RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
)

foreach ($RegPath in $RegistryPaths) {
    try {
        if (Test-Path $RegPath) {
            Write-Host "  删除注册表项 $RegPath..." -NoNewline
            Remove-Item -Path $RegPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host " 完成" -ForegroundColor Green
        }
    } catch {
        Write-Host " 失败" -ForegroundColor Red
    }
}

# 步骤8: 删除文件和目录
Write-Host ""
Write-Host "步骤8: 删除WSL文件和目录..." -ForegroundColor Green
$WSLPaths = @(
    "$env:LOCALAPPDATA\Packages\*Ubuntu*",
    "$env:LOCALAPPDATA\Packages\*Debian*",
    "$env:LOCALAPPDATA\Packages\*SUSE*",
    "$env:LOCALAPPDATA\Packages\*Kali*",
    "$env:LOCALAPPDATA\lxss",
    "$env:SYSTEMROOT\System32\lxss"
)

foreach ($Path in $WSLPaths) {
    try {
        $Items = Get-Item $Path -ErrorAction SilentlyContinue
        if ($Items) {
            foreach ($Item in $Items) {
                Write-Host "  删除 $($Item.Name)..." -NoNewline
                # 获取所有权并删除
                if ($Item.FullName -like "*System32*") {
                    takeown /f $Item.FullName /r /d y 2>$null | Out-Null
                    icacls $Item.FullName /grant administrators:F /t 2>$null | Out-Null
                }
                Remove-Item $Item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host " 完成" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host " 失败" -ForegroundColor Red
    }
}

# 步骤9: 清理环境变量
Write-Host ""
Write-Host "步骤9: 清理环境变量..." -ForegroundColor Green
try {
    $CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if ($CurrentPath -like "*lxss*") {
        Write-Host "  清理PATH环境变量..." -NoNewline
        $CleanedPath = $CurrentPath -replace ";[^;]*lxss[^;]*", ""
        [Environment]::SetEnvironmentVariable("PATH", $CleanedPath, "Machine")
        Write-Host " 完成" -ForegroundColor Green
    } else {
        Write-Host "  PATH环境变量无需清理" -ForegroundColor Yellow
    }
} catch {
    Write-Host "清理环境变量时出现错误" -ForegroundColor Red
}

# 完成
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "        WSL卸载完成!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "重要提醒:" -ForegroundColor Yellow
Write-Host "1. 请重启计算机以完成Windows功能的禁用" -ForegroundColor White
Write-Host "2. 如需重新安装WSL，请使用 WSL-CompleteReinstall.ps1 脚本" -ForegroundColor White
if ($BackupFirst -and (Test-Path $BackupDir)) {
    Write-Host "3. 备份文件位置: $BackupDir" -ForegroundColor White
}
Write-Host ""

# 询问是否立即重启
$Restart = Read-Host "是否立即重启计算机？(y/N)"
if ($Restart -eq 'y' -or $Restart -eq 'Y') {
    Write-Host "正在重启计算机..." -ForegroundColor Yellow
    Restart-Computer -Force
}