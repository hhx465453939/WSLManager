# WSL运维操作手册

## 目录
1. [WSL常用命令速查手册](#wsl常用命令速查手册)
2. [WSL故障排除命令集合](#wsl故障排除命令集合)
3. [WSL备份恢复操作指南](#wsl备份恢复操作指南)
4. [WSL完全卸载和重装指南](#wsl完全卸载和重装指南)
5. [WSL环境迁移和配置优化](#wsl环境迁移和配置优化)
6. [WSL开发环境配置](#wsl开发环境配置)
7. [WSL网络和远程访问配置](#wsl网络和远程访问配置)
8. [系统优化和维护](#系统优化和维护)
9. [WSL完整部署流程](#wsl完整部署流程)

---

## WSL常用命令速查手册

### 基础WSL管理命令

#### Windows子系统功能管理
```powershell
# 开启子系统
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 

# 开启虚拟机平台
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# 关闭子系统
dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart

# 关闭虚拟机平台
dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart

# 无法安装ubuntu的话管理员打开powershell（必要步骤）
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```

#### 查看WSL状态和版本
```powershell
# 查看WSL版本
wsl --version

# 查看已安装的发行版
wsl --list --verbose
wsl -l -v

# 查看WSL状态
wsl --status

# WSL版本查看与转换
wsl --list --verbose
wsl --set-version Ubuntu-20.04 2  # 转换为WSL2
wsl --set-version Ubuntu-20.04 1  # 转换为WSL1

# 设置默认WSL版本
wsl --set-default-version 1  # 设置为WSL1
wsl --set-default-version 2  # 设置为WSL2

# 直接设定特定版本ubuntu WSL2，以Ubuntu-24.04为例
wsl --set-version Ubuntu-24.04 2
```

#### WSL发行版管理
```powershell
# 列出可用的发行版
wsl --list --online
wsl -l -o

# 安装默认发行版（Ubuntu）
wsl --install

# 安装指定发行版
wsl --install -d Ubuntu-20.04
wsl --install -d Debian

# 设置默认发行版
wsl --set-default Ubuntu-20.04

# 多个子系统时的切换和管理
wsl -d Ubuntu-24.04  # 指定激活特定发行版
wsl --set-default Ubuntu-24.04  # 切换默认发行版

# 启动指定发行版
wsl -d Ubuntu-20.04

# 以指定用户启动
wsl -d Ubuntu-20.04 -u root
```

#### WSL服务控制
```powershell
# 关闭所有WSL实例
wsl --shutdown

# 终止指定发行版
wsl --terminate Ubuntu-20.04

# 重启WSL服务
wsl --shutdown
# 等待几秒后重新启动
wsl
```

#### 文件系统操作
```powershell
# 在Windows中访问WSL文件
\\wsl$\Ubuntu-20.04\home\username

# 在WSL中访问Windows文件
/mnt/c/Users/username

# 挂载Windows驱动器
sudo mkdir /mnt/d
sudo mount -t drvfs D: /mnt/d

# 将Windows网络磁盘映射添加到WSL系统中
# 在WSL中挂载网络驱动器
sudo mkdir /mnt/networkdrive
sudo mount -t drvfs '\\server\share' /mnt/networkdrive
```

### WSL配置管理

#### .wslconfig文件配置（用户目录下）
```ini
# %USERPROFILE%\.wslconfig
[wsl2]
memory=4GB
processors=2
swap=2GB
swapFile=C:\\temp\\wsl-swap.vhdx
localhostForwarding=true
nestedVirtualization=true
```

#### wsl.conf文件配置（WSL内部）
```ini
# /etc/wsl.conf
[automount]
enabled = true
root = /mnt/
options = "metadata,umask=22,fmask=11"

[network]
generateHosts = true
generateResolvConf = true

[interop]
enabled = true
appendWindowsPath = true

# WSL1启用systemd功能配置
[boot]
systemd=true
```

### 网络和端口管理
```powershell
# 查看WSL IP地址
wsl hostname -I

# 端口转发（管理员权限）
netsh interface portproxy add v4tov4 listenport=8080 listenaddress=0.0.0.0 connectport=8080 connectaddress=172.x.x.x

# 实际端口转发示例（连接WSL内的SSH服务）
netsh interface portproxy add v4tov4 listenport=2222 connectaddress=169.254.10.67 connectport=22

# 查看WSL内网IP地址
ip a

# 查看端口转发规则
netsh interface portproxy show all

# 删除端口转发
netsh interface portproxy delete v4tov4 listenport=8080 listenaddress=0.0.0.0
```

---

## WSL故障排除命令集合

### 服务和进程问题

#### WSL服务重启
```powershell
# 完全重启WSL
wsl --shutdown
Get-Service LxssManager | Restart-Service
wsl

# 重启特定发行版
wsl --terminate Ubuntu-20.04
wsl -d Ubuntu-20.04
```

#### 检查WSL相关服务
```powershell
# 检查WSL服务状态
Get-Service LxssManager
Get-Service vmcompute

# 启动WSL服务
Start-Service LxssManager
Start-Service vmcompute

# 检查Hyper-V状态
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
```

#### WSL命令报错"系统找不到指定的路径"解决方案
```powershell
# 当WSL出现"系统找不到相关路径"或"系统找不到指定的文件"错误时
# 解决方案：重装WSL包
# 1. 访问 https://github.com/microsoft/WSL
# 2. 进入release页面，下载稳定版本安装包
# 3. 安装即可修复路径问题
```

### 路径和权限问题

#### 修复路径问题
```bash
# 在WSL内修复PATH环境变量
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# 永久修复PATH
echo 'export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >> ~/.bashrc
source ~/.bashrc
```

#### 权限修复
```bash
# 修复文件权限
sudo chmod -R 755 /path/to/directory
sudo chown -R $USER:$USER /path/to/directory

# 修复WSL挂载权限
sudo umount /mnt/c
sudo mount -t drvfs C: /mnt/c -o metadata,uid=1000,gid=1000,umask=022,fmask=133

# WSL对Windows硬盘权限修改（让RStudio-server等可以修改Windows数据盘数据）
# 在WSL中修改挂载选项
sudo umount /mnt/d
sudo mount -t drvfs D: /mnt/d -o metadata,uid=1000,gid=1000,umask=000,fmask=000
```

#### 解决权限相关的安装问题
```bash
# 解决Failed to take /etc/passwd lock：Invalid argument错误
# 这通常是WSL权限问题导致的
sudo chmod 644 /etc/passwd
sudo chmod 644 /etc/group
sudo chmod 640 /etc/shadow

# 修复sudo权限问题
# 如果用户不在sudoers文件中
su root
usermod -aG sudo $USER
# 或者直接编辑sudoers文件
visudo
```

### 网络连接修复

#### DNS问题修复
```bash
# 修复DNS解析
sudo rm /etc/resolv.conf
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo bash -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'

# 或者使用Windows DNS
sudo bash -c 'echo "nameserver 192.168.1.1" > /etc/resolv.conf'
```

#### 网络重置
```powershell
# Windows端网络重置
netsh winsock reset
netsh int ip reset
ipconfig /flushdns

# 重启网络适配器
Get-NetAdapter | Restart-NetAdapter
```

### 磁盘和存储问题

#### 清理WSL磁盘空间
```bash
# 清理包缓存
sudo apt autoremove
sudo apt autoclean
sudo apt clean

# 清理日志文件
sudo journalctl --vacuum-time=7d
sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;

# Ubuntu系统深度清理
sudo apt autoremove --purge
sudo apt autoclean
sudo apt clean
sudo journalctl --vacuum-time=3d
sudo find /tmp -type f -atime +7 -delete
sudo find /var/tmp -type f -atime +7 -delete
```

#### 压缩WSL虚拟磁盘
```powershell
# 关闭WSL
wsl --shutdown

# 压缩虚拟磁盘（管理员权限）
diskpart
# 在diskpart中执行：
select vdisk file="C:\Users\%USERNAME%\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu20.04onWindows_79rhkp1fndgsc\LocalState\ext4.vhdx"
compact vdisk
exit
```

### 注册表修复

#### 修复WSL注册表项
```powershell
# 检查WSL注册表
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"

# 重置WSL注册表（谨慎使用）
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss" -Recurse -Force
```

---

## WSL备份恢复操作指南

### 手动备份方法

#### 导出WSL发行版
```powershell
# 创建备份目录
New-Item -ItemType Directory -Path "C:\WSL-Backups" -Force

# 导出发行版
wsl --export Ubuntu-20.04 "C:\WSL-Backups\Ubuntu-20.04-backup-$(Get-Date -Format 'yyyyMMdd').tar"

# 验证备份文件
Get-ChildItem "C:\WSL-Backups\" | Select-Object Name, Length, LastWriteTime
```

#### 恢复WSL发行版
```powershell
# 删除现有发行版（可选）
wsl --unregister Ubuntu-20.04

# 从备份恢复
wsl --import Ubuntu-20.04-Restored "C:\WSL\Ubuntu-20.04-Restored" "C:\WSL-Backups\Ubuntu-20.04-backup-20240101.tar"

# 设置默认用户
Ubuntu-20.04.exe config --default-user username
```

### 自动备份脚本

#### 创建自动备份脚本
```powershell
# 保存为 WSL-AutoBackup.ps1
param(
    [string]$DistributionName = "Ubuntu-20.04",
    [string]$BackupPath = "C:\WSL-Backups",
    [int]$RetentionDays = 7
)

# 创建备份目录
if (!(Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force
}

# 生成备份文件名
$BackupFileName = "$DistributionName-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').tar"
$BackupFullPath = Join-Path $BackupPath $BackupFileName

try {
    # 执行备份
    Write-Host "开始备份 $DistributionName..."
    wsl --export $DistributionName $BackupFullPath
    
    if (Test-Path $BackupFullPath) {
        Write-Host "备份成功: $BackupFullPath"
        
        # 清理旧备份
        $OldBackups = Get-ChildItem $BackupPath -Filter "$DistributionName-backup-*.tar" | 
                     Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) }
        
        foreach ($OldBackup in $OldBackups) {
            Remove-Item $OldBackup.FullName -Force
            Write-Host "已删除旧备份: $($OldBackup.Name)"
        }
    } else {
        Write-Error "备份失败"
    }
} catch {
    Write-Error "备份过程中出现错误: $($_.Exception.Message)"
}
```

#### 设置定时备份任务
```powershell
# 创建定时任务
$TaskName = "WSL-AutoBackup"
$ScriptPath = "C:\Scripts\WSL-AutoBackup.ps1"

$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""
$Trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "WSL自动备份任务"
```

### 增量备份方案

#### 创建增量备份脚本
```bash
#!/bin/bash
# 保存为 incremental-backup.sh

BACKUP_DIR="/mnt/c/WSL-Backups/incremental"
FULL_BACKUP_DIR="/mnt/c/WSL-Backups/full"
DATE=$(date +%Y%m%d-%H%M%S)

# 创建备份目录
mkdir -p "$BACKUP_DIR"
mkdir -p "$FULL_BACKUP_DIR"

# 检查是否需要完整备份（每周一次）
if [ ! -f "$FULL_BACKUP_DIR/last_full_backup" ] || [ $(find "$FULL_BACKUP_DIR/last_full_backup" -mtime +7) ]; then
    echo "执行完整备份..."
    tar -czf "$FULL_BACKUP_DIR/full-backup-$DATE.tar.gz" /home
    echo "$DATE" > "$FULL_BACKUP_DIR/last_full_backup"
else
    echo "执行增量备份..."
    find /home -newer "$FULL_BACKUP_DIR/last_full_backup" -type f | tar -czf "$BACKUP_DIR/incremental-backup-$DATE.tar.gz" -T -
fi

# 清理旧备份
find "$BACKUP_DIR" -name "incremental-backup-*.tar.gz" -mtime +30 -delete
find "$FULL_BACKUP_DIR" -name "full-backup-*.tar.gz" -mtime +90 -delete
```

---

## WSL完全卸载和重装指南

### 完全卸载WSL

#### 步骤1：备份重要数据
```powershell
# 列出所有发行版
wsl -l -v

# 备份重要发行版
wsl --export Ubuntu-20.04 "C:\Temp\Ubuntu-backup-final.tar"
wsl --export Debian "C:\Temp\Debian-backup-final.tar"
```

#### 步骤2：卸载所有WSL发行版
```powershell
# 获取所有已安装的发行版
$Distributions = wsl -l -q

# 逐个卸载
foreach ($Dist in $Distributions) {
    if ($Dist -and $Dist.Trim() -ne "") {
        Write-Host "正在卸载: $Dist"
        wsl --unregister $Dist.Trim()
    }
}

# 验证卸载
wsl -l -v
```

#### 步骤3：停止WSL相关服务
```powershell
# 停止WSL服务
Stop-Service LxssManager -Force
Stop-Service vmcompute -Force

# 关闭所有WSL进程
Get-Process | Where-Object {$_.ProcessName -like "*wsl*" -or $_.ProcessName -like "*lxss*"} | Stop-Process -Force
```

#### 步骤4：禁用WSL功能
```powershell
# 禁用WSL功能（需要重启）
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform

# 或使用DISM
dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart
```

#### 步骤7：清理环境变量
```powershell
# 清理PATH中的WSL相关路径
$CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$CleanedPath = $CurrentPath -replace ";[^;]*lxss[^;]*", ""
[Environment]::SetEnvironmentVariable("PATH", $CleanedPath, "Machine")
```

### 重新安装WSL

#### 步骤1：启用必要功能
```powershell
# 启用WSL功能
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart

# 或使用DISM
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

Write-Host "请重启计算机以完成功能启用"
```

#### 步骤2：下载并安装WSL2内核更新
```powershell
# 下载WSL2内核更新包
$KernelUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
$KernelUpdatePath = "$env:TEMP\wsl_update_x64.msi"

Invoke-WebRequest -Uri $KernelUpdateUrl -OutFile $KernelUpdatePath
Start-Process -FilePath $KernelUpdatePath -ArgumentList "/quiet" -Wait

# 设置WSL2为默认版本
wsl --set-default-version 2
```

#### 步骤3：安装Linux发行版
```powershell
# 安装默认Ubuntu
wsl --install -d Ubuntu

# 或安装其他发行版
wsl --install -d Ubuntu-20.04
wsl --install -d Debian

# 绕开Microsoft Store安装Ubuntu的方法
# 1. 访问 https://docs.microsoft.com/en-us/windows/wsl/install-manual
# 2. 下载对应的.appx文件
# 3. 使用Add-AppxPackage安装
```

#### 步骤4：恢复备份数据
```powershell
# 从备份恢复
if (Test-Path "C:\Temp\Ubuntu-backup-final.tar") {
    wsl --import Ubuntu-Restored "C:\WSL\Ubuntu-Restored" "C:\Temp\Ubuntu-backup-final.tar"
    Write-Host "Ubuntu环境已从备份恢复"
}
```

---

## WSL环境迁移和配置优化

### WSL迁移操作

#### WSL从C盘迁移到其他盘区
```powershell
# 1. 导出现有发行版
wsl --export Ubuntu-20.04 "D:\WSL-Backup\Ubuntu-20.04.tar"

# 2. 注销原发行版
wsl --unregister Ubuntu-20.04

# 3. 导入到新位置
wsl --import Ubuntu-20.04 "D:\WSL\Ubuntu-20.04" "D:\WSL-Backup\Ubuntu-20.04.tar"

# 4. 设置默认用户（如果需要）
# 创建/etc/wsl.conf文件设置默认用户
```

### Ubuntu软件源配置
```bash
# 清华大学镜像源配置
# 编辑 /etc/apt/sources.list
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse
EOF

sudo apt update
```

---

## WSL开发环境配置

### 权限和用户管理

#### 新系统权限配置
```powershell
# 新系统第一件事：给管理员用户设置磁盘权限
# 1. 右键每个磁盘 -> 属性 -> 安全 -> 编辑
# 2. 添加当前用户，设置完全控制权限
# 3. 特别注意Anaconda的env路径权限设置

# PowerShell管理员权限设置
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# VSCode默认管理员权限
# 右键code.exe -> 属性 -> 兼容性 -> 始终以管理员身份运行此程序
```

#### WSL用户名与SSH访问设置
```bash
# 添加用户到sudo组
sudo usermod -aG sudo username

# 修改用户权限
sudo visudo
# 添加: username ALL=(ALL) NOPASSWD:ALL

# 设置SSH密钥认证
mkdir -p ~/.ssh
chmod 700 ~/.ssh
# 复制公钥到 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 添加新用户并配置权限
sudo adduser damncheater
sudo passwd damncheater

# 如果有旧用户名可以这样操作
sudo cp -r /home/old_username /home/damncheater
sudo deluser old_username

# 添加最高权限到新用户名
sudo chown -R damncheater:damncheater /home/damncheater

# 编辑配置文件
sudo nano /etc/sudoers
# 增加配置, 在打开的配置文件中，找到root ALL=(ALL) ALL, 在下面添加一行
# 其中xxx是你要加入的用户名称
damncheater ALL=(ALL) ALL
```

### 开发工具配置

#### Anaconda/Miniconda配置
```bash
# 命令行安装Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

# 添加或删除默认环境创建路径
conda config --add envs_dirs /path/to/new/envs
conda config --remove envs_dirs /path/to/old/envs

# 查看环境路径
conda info --envs
```

#### Python包管理
```bash
# pip使用国内镜像
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple package_name

# 永久配置pip镜像
mkdir -p ~/.pip
cat > ~/.pip/pip.conf << EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF

# PyTorch下载加速
pip install torch torchvision torchaudio -i https://pypi.tuna.tsinghua.edu.cn/simple
```

#### R语言环境配置
```bash
# 解决R包安装权限问题
# 安装xml2包时的权限错误解决
install.packages("xml2", dependencies=TRUE, INSTALL_opts = c('--no-lock'))

# 修复R包安装权限
sudo chown -R $USER:$USER /usr/local/lib/R/site-library
```

---

## WSL网络和远程访问配置

### SSH服务配置

#### WSL SSH服务器配置
```bash
# 卸载并重新安装SSH服务
sudo apt purge openssh-server
sudo apt install openssh-server

# SSH服务管理
sudo service ssh stop
sudo service ssh start
sudo service ssh restart

# 配置SSH服务
sudo nano /etc/ssh/sshd_config
# 修改以下配置：
Port 22
ListenAddress 0.0.0.0
ListenAddress ::
PermitRootLogin no
PasswordAuthentication yes
Subsystem sftp internal-sftp

# 重启服务
sudo service ssh start

# 开机启动ssh
sudo systemctl enable ssh
```

#### Windows SSH服务配置
```powershell
# 启用Windows SSH服务
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# 配置防火墙
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

### 网络配置和端口转发

#### WSL2网络配置
```powershell
# WSL2端口转发脚本示例
# 将WSL2的服务端口转发到Windows主机
$wslIP = (wsl hostname -I).Trim()
$ports = @(22, 80, 443, 3000, 8080)

foreach ($port in $ports) {
    netsh interface portproxy add v4tov4 listenport=$port listenaddress=0.0.0.0 connectport=$port connectaddress=$wslIP
}

# 查看转发规则
netsh interface portproxy show all

# 删除转发规则
foreach ($port in $ports) {
    netsh interface portproxy delete v4tov4 listenport=$port listenaddress=0.0.0.0
}
```

#### WSL IP固定配置
```bash
# 在WSL中固定IP地址
# 编辑 /etc/netplan/01-netcfg.yaml (Ubuntu 18.04+)
sudo nano /etc/netplan/01-netcfg.yaml

# 示例配置：
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses: [192.168.1.100/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

# 应用配置
sudo netplan apply
```

### 内网穿透和远程访问

#### Tailscale内网穿透
```bash
# 安装Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# 启动Tailscale
sudo tailscale up

# 在客户端也安装并连接到同一账号
# 之后可以通过Tailscale IP直接访问
```

#### 花生壳内网穿透
```bash
# 下载花生壳客户端
# 访问 https://hsk.oray.com/download/
# 按照官方文档配置特定端口穿透
```

#### rsync断点传输
```bash
# 大文件断点传输
rsync -avz --progress --partial source_file user@remote_host:/path/to/destination/

# SSH断点传输示例
rsync -avz -e "ssh -p 22" --progress --partial /local/path/ user@remote:/remote/path/
```

---

## 系统优化和维护

### Windows系统优化

#### 内存和存储优化
```powershell
# 调整休眠文件大小
powercfg -h size 50  # 设置为50%
# 或完全关闭休眠
powercfg -h off

# 关闭快速启动（避免内存状态保存到hiberfil.sys）
# 控制面板 -> 电源选项 -> 选择电源按钮的功能 -> 更改当前不可用的设置
# 取消勾选"启用快速启动"
```

#### 网络优先级设置
```powershell
# 设置网络适配器优先级
# 当同时连接有线和无线网络时
Get-NetAdapter | Sort-Object InterfaceMetric
Set-NetIPInterface -InterfaceAlias "以太网" -InterfaceMetric 1
Set-NetIPInterface -InterfaceAlias "WLAN" -InterfaceMetric 2
```

#### 静态IP配置
```powershell
# Windows设置静态IP
# 建议使用较大的IP地址（如192.168.1.188而不是192.168.1.100）
# 避免关机后被其他设备占用

New-NetIPAddress -InterfaceAlias "以太网" -IPAddress 192.168.1.188 -PrefixLength 24 -DefaultGateway 192.168.1.1
Set-DnsClientServerAddress -InterfaceAlias "以太网" -ServerAddresses 8.8.8.8,8.8.4.4
```

### 环境变量管理

#### 解决环境变量字符超标问题
```powershell
# 当PATH环境变量超过2047字符限制时
# 1. 创建新的系统变量存储长路径
[Environment]::SetEnvironmentVariable("LONG_PATHS", "C:\Very\Long\Path1;C:\Very\Long\Path2", "Machine")

# 2. 在PATH中引用新变量
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$newPath = $currentPath + ";%LONG_PATHS%"
[Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
```

### 开机自启动配置

#### WSL开机自启动
```powershell
# 创建开机启动脚本
# 保存到 shell:startup 目录
# Win+R 输入: shell:startup

# WSL-Startup.bat 内容：
@echo off
wsl -d Ubuntu-20.04 -u root service ssh start
wsl -d Ubuntu-20.04 -u root service nginx start
```

#### WSL内服务自启动
```bash
# 创建 /etc/init.wsl 文件
cd /etc
sudo chmod 777 init.wsl
sudo nano /etc/init.wsl

#!/bin/sh
# 填写任意服务，rstudio-server之类的也可以
service ssh restart
#service rstudio-server start
#service redis-server start
#service mysql start
#service nginx start

# 设置执行权限
sudo chmod +x /etc/init.wsl

# PowerShell命令，这个ubuntu版本看自己的实际版本号填写
wsl -d Ubuntu-24.04 -u root /etc/init.wsl start
```

#### Windows开机自启动WSL脚本
```vbscript
# 新建文件wsl2run_Ubuntu_redis.vbs（文件名自命名，扩展名是vbs就行）
# 填写注意ubuntu版本号别输错了，自己从store下载的版本是多少记住，或者开始菜单输入ubuntu就可以查到安装的版本
rem Msgbox "Win10开机自动启动wsl2的Ubuntu，并由其启动redis"
Set ws = CreateObject("Wscript.Shell")
ws.run "wsl -d Ubuntu-24.04 -u root /etc/init.wsl start", vbhide
```

### 系统清理和维护

#### C盘清理
```powershell
# 清理Windows更新缓存
dism /online /cleanup-image /startcomponentcleanup
dism /online /cleanup-image /spsuperseded

# 清理临时文件
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# 清理系统日志
wevtutil cl Application
wevtutil cl System
wevtutil cl Security
```

#### 多硬盘存储池配置
```powershell
# 创建存储池（多硬盘合并）
# 设置 -> 系统 -> 存储 -> 管理存储空间 -> 创建存储池
# 或使用PowerShell：
New-StoragePool -FriendlyName "DataPool" -StorageSubsystemFriendlyName "Windows Storage*" -PhysicalDisks (Get-PhysicalDisk -CanPool $true)
```

---

## WSL完整部署流程

### 标准部署流程（基于win10WSL运维流程.sh）

#### 第一阶段：Windows部分子系统管理
```powershell
# 1. 开启子系统
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 

# 2. 开启虚拟机平台
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# 3. 无法安装ubuntu的话管理员打开powershell（必要步骤）
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

# 4. 去Windows商店下载ubuntu，去开始菜单打开后自动安装，并配置用户名
# 推荐：Ubuntu 24.04.1 LTS

# 5. 安装好以后powershell管理员权限下更改默认为wsl 1模式
# 注意WSL1无法使用 systemd，但是win 10 + WSL2的ssh服务配置老是出错比较麻烦
# 因为WSL多出来了一个独立的虚拟机ip，没有特殊原因的话这里默认先用WSL1
wsl --set-default-version 1
wsl --list --verbose

# 6. 在 /etc/wsl.conf（文件不存在则创建）添加如下内容,打开 WSL 1 的systemd功能：
sudo nano /etc/wsl.conf
[boot]
systemd=true

# 7. 重启WSL
# powershell 
wsl --shutdown
wsl

# 8. 用snap测试一下
snap version

# 如果要设置WSL2，则
wsl --set-default-version 2
wsl --list --verbose
# 直接设定特定版本ubuntu WSL2，以Ubuntu-24.04为例
wsl --set-version Ubuntu-24.04 2
```

#### 第二阶段：基础软件安装和配置
```bash
# 1. 更新系统
sudo apt update
sudo apt install software-properties-common
sudo apt update

# 2. 安装ssh服务
sudo apt purge openssh-server
sudo apt install openssh-server

sudo service ssh stop
sudo service ssh start
sudo service ssh restart

# 3. 配置SSH文档
sudo nano /etc/ssh/sshd_config
Port 22
ListenAddress 0.0.0.0
ListenAddress ::
PermitRootLogin no
PasswordAuthentication yes
Subsystem sftp internal-sftp

# 4. 重启服务
sudo service ssh start

# 5. 开机启动ssh
sudo systemctl enable ssh
```

#### 第三阶段：用户管理和权限配置
```bash
# 1. 修改用户名并添加到root
sudo adduser damncheater
sudo passwd damncheater

# 2. 如果有旧用户名可以这样操作
sudo cp -r /home/old_username /home/damncheater
sudo deluser old_username

# 3. 添加最高权限到新用户名
sudo chown -R damncheater:damncheater /home/damncheater

# 4. 编辑配置文件
sudo nano /etc/sudoers
# 增加配置, 在打开的配置文件中，找到root ALL=(ALL) ALL, 在下面添加一行
# 其中xxx是你要加入的用户名称
damncheater ALL=(ALL) ALL

# 5. 保存退出，重启服务
sudo service ssh restart
```

#### 第四阶段：网络配置和远程访问
```bash
# 1. 查看WSL内网IP
ip a

# 2. 选一个以太网或者无线ip到转发端口上，cmd管理员命令
netsh interface portproxy add v4tov4 listenport=2222 connectaddress=169.254.10.67 connectport=22

# 3. 这里开始就可以使用finalshell之类的进行连接了
```

#### 第五阶段：配置开机自启动
```bash
# 1. 这一步在WSL界面用root权限完成
cd /etc
sudo chmod 777 init.wsl
sudo nano /etc/init.wsl

#!/bin/sh
# 填写任意服务，rstudio-server之类的也可以
service ssh restart
#service rstudio-server start
#service redis-server start
#service mysql start
#service nginx start

# 2. 保存退出，设置执行权限
sudo chmod +x /etc/init.wsl

# 3. powershell命令，这个ubuntu版本看自己的实际版本号填写
wsl -d Ubuntu-24.04 -u root /etc/init.wsl start
```

#### 第六阶段：Windows开机自启动配置
```powershell
# 1. win+r: shell:startup 进入开机自启文件夹

# 2. 新建文件wsl2run_Ubuntu_redis.vbs（文件名自命名，扩展名是vbs就行）
# 填写注意ubuntu版本号别输错了，自己从store下载的版本是多少记住
```

```vbscript
rem Msgbox "Win10开机自动启动wsl2的Ubuntu，并由其启动redis"
Set ws = CreateObject("Wscript.Shell")
ws.run "wsl -d Ubuntu-24.04 -u root /etc/init.wsl start", vbhide
```

```powershell
# 3. 保存好以后重启一下电脑就好，后面应该可以直接从finalshell开机直连
```

### 部署验证清单

#### 功能验证
```bash
# 1. 验证WSL版本和状态
wsl --list --verbose

# 2. 验证SSH服务
sudo service ssh status

# 3. 验证用户权限
sudo whoami

# 4. 验证网络连接
ip a
ping 8.8.8.8

# 5. 验证systemd功能（如果启用）
snap version
```

#### 远程访问验证
```powershell
# 1. 验证端口转发
netsh interface portproxy show all

# 2. 测试SSH连接
# 使用finalshell或其他SSH客户端连接到 localhost:2222
```

---

## 使用说明

1. **复制粘贴使用**: 本手册中的所有命令都可以直接复制粘贴到PowerShell或WSL终端中运行
2. **管理员权限**: 标注需要管理员权限的命令请以管理员身份运行PowerShell
3. **备份重要**: 在执行任何重大操作前，请务必备份重要数据
4. **测试环境**: 建议先在测试环境中验证命令的效果
5. **版本兼容**: 部分命令可能因Windows版本不同而有所差异
6. **权限设置**: 新系统建议先配置好各磁盘的管理员权限，避免后续权限问题
7. **网络配置**: 内网穿透和远程访问配置需要根据实际网络环境调整
8. **完整部署**: 建议按照完整部署流程章节的步骤进行标准化部署

## 注意事项

- 执行完全卸载前请确保已备份所有重要数据
- 某些操作需要重启计算机才能生效
- 网络问题可能影响发行版的下载和安装
- 企业环境可能有额外的安全策略限制
- 权限问题是WSL使用中的常见问题，建议提前配置好相关权限
- 使用内网穿透时注意安全性，避免暴露敏感服务
- WSL1和WSL2在网络配置上有显著差异，选择版本时需要考虑具体使用场景
- 开机自启动脚本需要根据实际安装的Ubuntu版本号进行调整

---

*最后更新: 2024年1月*
*整合日常问题解决方案和完整部署流程: 2024年1月*
### Windows系统优化

#### 内存和存储优化
```powershell
# 调整休眠文件大小
powercfg -h size 50  # 设置为50%
# 或完全关闭休眠
powercfg -h off

# 关闭快速启动（避免内存状态保存到hiberfil.sys）
# 控制面板 -> 电源选项 -> 选择电源按钮的功能 -> 更改当前不可用的设置
# 取消勾选"启用快速启动"
```

#### 网络优先级设置
```powershell
# 设置网络适配器优先级
# 当同时连接有线和无线网络时
Get-NetAdapter | Sort-Object InterfaceMetric
Set-NetIPInterface -InterfaceAlias "以太网" -InterfaceMetric 1
Set-NetIPInterface -InterfaceAlias "WLAN" -InterfaceMetric 2
```

#### 静态IP配置
```powershell
# Windows设置静态IP
# 建议使用较大的IP地址（如192.168.1.188而不是192.168.1.100）
# 避免关机后被其他设备占用

New-NetIPAddress -InterfaceAlias "以太网" -IPAddress 192.168.1.188 -PrefixLength 24 -DefaultGateway 192.168.1.1
Set-DnsClientServerAddress -InterfaceAlias "以太网" -ServerAddresses 8.8.8.8,8.8.4.4
```

### 环境变量管理

#### 解决环境变量字符超标问题
```powershell
# 当PATH环境变量超过2047字符限制时
# 1. 创建新的系统变量存储长路径
[Environment]::SetEnvironmentVariable("LONG_PATHS", "C:\Very\Long\Path1;C:\Very\Long\Path2", "Machine")

# 2. 在PATH中引用新变量
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$newPath = $currentPath + ";%LONG_PATHS%"
[Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
```

### 开机自启动配置

#### WSL开机自启动
```powershell
# 创建开机启动脚本
# 保存到 shell:startup 目录
# Win+R 输入: shell:startup

# WSL-Startup.bat 内容：
@echo off
wsl -d Ubuntu-20.04 -u root service ssh start
wsl -d Ubuntu-20.04 -u root service nginx start
```

#### WSL内服务自启动
```bash
# 创建 /etc/init.wsl 文件
cd /etc
sudo chmod 777 init.wsl
sudo nano /etc/init.wsl

#!/bin/sh
# 填写任意服务，rstudio-server之类的也可以
service ssh restart
#service rstudio-server start
#service redis-server start
#service mysql start
#service nginx start

# 设置执行权限
sudo chmod +x /etc/init.wsl

# PowerShell命令，这个ubuntu版本看自己的实际版本号填写
wsl -d Ubuntu-24.04 -u root /etc/init.wsl start
```

#### Windows开机自启动WSL脚本
```vbscript
# 新建文件wsl2run_Ubuntu_redis.vbs（文件名自命名，扩展名是vbs就行）
# 填写注意ubuntu版本号别输错了，自己从store下载的版本是多少记住，或者开始菜单输入ubuntu就可以查到安装的版本
rem Msgbox "Win10开机自动启动wsl2的Ubuntu，并由其启动redis"
Set ws = CreateObject("Wscript.Shell")
ws.run "wsl -d Ubuntu-24.04 -u root /etc/init.wsl start", vbhide
```

### 系统清理和维护

#### C盘清理
```powershell
# 清理Windows更新缓存
dism /online /cleanup-image /startcomponentcleanup
dism /online /cleanup-image /spsuperseded

# 清理临时文件
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# 清理系统日志
wevtutil cl Application
wevtutil cl System
wevtutil cl Security
```

#### 多硬盘存储池配置
```powershell
# 创建存储池（多硬盘合并）
# 设置 -> 系统 -> 存储 -> 管理存储空间 -> 创建存储池
# 或使用PowerShell：
New-StoragePool -FriendlyName "DataPool" -StorageSubsystemFriendlyName "Windows Storage*" -PhysicalDisks (Get-PhysicalDisk -CanPool $true)
```

---

## WSL完整部署流程

### 标准部署流程（基于win10WSL运维流程.sh）

#### 第一阶段：Windows部分子系统管理
```powershell
# 1. 开启子系统
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 

# 2. 开启虚拟机平台
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# 3. 无法安装ubuntu的话管理员打开powershell（必要步骤）
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

# 4. 去Windows商店下载ubuntu，去开始菜单打开后自动安装，并配置用户名
# 推荐：Ubuntu 24.04.1 LTS

# 5. 安装好以后powershell管理员权限下更改默认为wsl 1模式
# 注意WSL1无法使用 systemd，但是win 10 + WSL2的ssh服务配置老是出错比较麻烦
# 因为WSL多出来了一个独立的虚拟机ip，没有特殊原因的话这里默认先用WSL1
wsl --set-default-version 1
wsl --list --verbose

# 6. 在 /etc/wsl.conf（文件不存在则创建）添加如下内容,打开 WSL 1 的systemd功能：
sudo nano /etc/wsl.conf
[boot]
systemd=true

# 7. 重启WSL
# powershell 
wsl --shutdown
wsl

# 8. 用snap测试一下
snap version

# 如果要设置WSL2，则
wsl --set-default-version 2
wsl --list --verbose
# 直接设定特定版本ubuntu WSL2，以Ubuntu-24.04为例
wsl --set-version Ubuntu-24.04 2
```

#### 第二阶段：基础软件安装和配置
```bash
# 1. 更新系统
sudo apt update
sudo apt install software-properties-common
sudo apt update

# 2. 安装ssh服务
sudo apt purge openssh-server
sudo apt install openssh-server

sudo service ssh stop
sudo service ssh start
sudo service ssh restart

# 3. 配置SSH文档
sudo nano /etc/ssh/sshd_config
Port 22
ListenAddress 0.0.0.0
ListenAddress ::
PermitRootLogin no
PasswordAuthentication yes
Subsystem sftp internal-sftp

# 4. 重启服务
sudo service ssh start

# 5. 开机启动ssh
sudo systemctl enable ssh
```

#### 第三阶段：用户管理和权限配置
```bash
# 1. 修改用户名并添加到root
sudo adduser damncheater
sudo passwd damncheater

# 2. 如果有旧用户名可以这样操作
sudo cp -r /home/old_username /home/damncheater
sudo deluser old_username

# 3. 添加最高权限到新用户名
sudo chown -R damncheater:damncheater /home/damncheater

# 4. 编辑配置文件
sudo nano /etc/sudoers
# 增加配置, 在打开的配置文件中，找到root ALL=(ALL) ALL, 在下面添加一行
# 其中xxx是你要加入的用户名称
damncheater ALL=(ALL) ALL

# 5. 保存退出，重启服务
sudo service ssh restart
```

#### 第四阶段：网络配置和远程访问
```bash
# 1. 查看WSL内网IP
ip a

# 2. 选一个以太网或者无线ip到转发端口上，cmd管理员命令
netsh interface portproxy add v4tov4 listenport=2222 connectaddress=169.254.10.67 connectport=22

# 3. 这里开始就可以使用finalshell之类的进行连接了
```

#### 第五阶段：配置开机自启动
```bash
# 1. 这一步在WSL界面用root权限完成
cd /etc
sudo chmod 777 init.wsl
sudo nano /etc/init.wsl

#!/bin/sh
# 填写任意服务，rstudio-server之类的也可以
service ssh restart
#service rstudio-server start
#service redis-server start
#service mysql start
#service nginx start

# 2. 保存退出，设置执行权限
sudo chmod +x /etc/init.wsl

# 3. powershell命令，这个ubuntu版本看自己的实际版本号填写
wsl -d Ubuntu-24.04 -u root /etc/init.wsl start
```

#### 第六阶段：Windows开机自启动配置
```powershell
# 1. win+r: shell:startup 进入开机自启文件夹

# 2. 新建文件wsl2run_Ubuntu_redis.vbs（文件名自命名，扩展名是vbs就行）
# 填写注意ubuntu版本号别输错了，自己从store下载的版本是多少记住
```

```vbscript
rem Msgbox "Win10开机自动启动wsl2的Ubuntu，并由其启动redis"
Set ws = CreateObject("Wscript.Shell")
ws.run "wsl -d Ubuntu-24.04 -u root /etc/init.wsl start", vbhide
```

```powershell
# 3. 保存好以后重启一下电脑就好，后面应该可以直接从finalshell开机直连
```

### 部署验证清单

#### 功能验证
```bash
# 1. 验证WSL版本和状态
wsl --list --verbose

# 2. 验证SSH服务
sudo service ssh status

# 3. 验证用户权限
sudo whoami

# 4. 验证网络连接
ip a
ping 8.8.8.8

# 5. 验证systemd功能（如果启用）
snap version
```

#### 远程访问验证
```powershell
# 1. 验证端口转发
netsh interface portproxy show all

# 2. 测试SSH连接
# 使用finalshell或其他SSH客户端连接到 localhost:2222
```

---

## 使用说明

1. **复制粘贴使用**: 本手册中的所有命令都可以直接复制粘贴到PowerShell或WSL终端中运行
2. **管理员权限**: 标注需要管理员权限的命令请以管理员身份运行PowerShell
3. **备份重要**: 在执行任何重大操作前，请务必备份重要数据
4. **测试环境**: 建议先在测试环境中验证命令的效果
5. **版本兼容**: 部分命令可能因Windows版本不同而有所差异
6. **权限设置**: 新系统建议先配置好各磁盘的管理员权限，避免后续权限问题
7. **网络配置**: 内网穿透和远程访问配置需要根据实际网络环境调整
8. **完整部署**: 建议按照完整部署流程章节的步骤进行标准化部署

## 注意事项

- 执行完全卸载前请确保已备份所有重要数据
- 某些操作需要重启计算机才能生效
- 网络问题可能影响发行版的下载和安装
- 企业环境可能有额外的安全策略限制
- 权限问题是WSL使用中的常见问题，建议提前配置好相关权限
- 使用内网穿透时注意安全性，避免暴露敏感服务
- WSL1和WSL2在网络配置上有显著差异，选择版本时需要考虑具体使用场景
- 开机自启动脚本需要根据实际安装的Ubuntu版本号进行调整

---

*最后更新: 2024年1月*
*整合日常问题解决方案和完整部署流程: 2024年1月*
