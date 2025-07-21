# WSL自动备份脚本
# 使用方法: .\WSL-AutoBackup.ps1 -DistributionName "Ubuntu-20.04" -BackupPath "C:\WSL-Backups"

param(
    [string]$DistributionName = "Ubuntu-20.04",
    [string]$BackupPath = "C:\WSL-Backups",
    [int]$RetentionDays = 7,
    [switch]$Verbose = $false
)

# 创建备份目录
if (!(Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    if ($Verbose) { Write-Host "创建备份目录: $BackupPath" -ForegroundColor Green }
}

# 检查发行版是否存在
$AvailableDistros = wsl -l -q | Where-Object { $_ -and $_.Trim() -ne "" }
if ($DistributionName -notin $AvailableDistros.Trim()) {
    Write-Error "发行版 '$DistributionName' 不存在。可用发行版: $($AvailableDistros -join ', ')"
    exit 1
}

# 生成备份文件名
$BackupFileName = "$DistributionName-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').tar"
$BackupFullPath = Join-Path $BackupPath $BackupFileName

try {
    # 执行备份
    Write-Host "开始备份 $DistributionName..." -ForegroundColor Yellow
    $StartTime = Get-Date
    
    wsl --export $DistributionName $BackupFullPath
    
    if (Test-Path $BackupFullPath) {
        $EndTime = Get-Date
        $Duration = $EndTime - $StartTime
        $FileSize = (Get-Item $BackupFullPath).Length / 1MB
        
        Write-Host "备份成功完成!" -ForegroundColor Green
        Write-Host "文件位置: $BackupFullPath" -ForegroundColor Cyan
        Write-Host "文件大小: $([math]::Round($FileSize, 2)) MB" -ForegroundColor Cyan
        Write-Host "耗时: $($Duration.Minutes) 分 $($Duration.Seconds) 秒" -ForegroundColor Cyan
        
        # 清理旧备份
        $OldBackups = Get-ChildItem $BackupPath -Filter "$DistributionName-backup-*.tar" | 
                     Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) }
        
        if ($OldBackups.Count -gt 0) {
            Write-Host "清理 $($OldBackups.Count) 个旧备份文件..." -ForegroundColor Yellow
            foreach ($OldBackup in $OldBackups) {
                Remove-Item $OldBackup.FullName -Force
                if ($Verbose) { Write-Host "已删除: $($OldBackup.Name)" -ForegroundColor Gray }
            }
        }
        
        # 生成备份报告
        $Report = @{
            DistributionName = $DistributionName
            BackupTime = $StartTime
            BackupFile = $BackupFullPath
            FileSize = "$([math]::Round($FileSize, 2)) MB"
            Duration = "$($Duration.Minutes)m $($Duration.Seconds)s"
            Status = "Success"
        }
        
        $ReportPath = Join-Path $BackupPath "backup-report-$(Get-Date -Format 'yyyyMMdd').json"
        $Report | ConvertTo-Json | Out-File $ReportPath -Encoding UTF8
        
    } else {
        Write-Error "备份失败: 未找到备份文件"
        exit 1
    }
} catch {
    Write-Error "备份过程中出现错误: $($_.Exception.Message)"
    exit 1
}