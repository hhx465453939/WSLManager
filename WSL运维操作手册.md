# WSL Operations Manual: From Beginner to Expert / WSL 运维操作手册：从入门到精通

**Welcome to the WSL Operations Manual!** This manual aims to provide you with a one-stop solution for WSL management and maintenance. Whether you are a beginner or an experienced developer, you will find the help you need here.

This manual not only covers the basic operations of WSL but also delves into advanced application scenarios, such as environment migration, performance optimization, and security hardening. We have prepared a large number of command examples that you can copy and paste directly, as well as detailed troubleshooting guides to help you easily tackle various challenges.

---

**欢迎使用 WSL 运维操作手册！** 本手册旨在为您提供一站式的 WSL 管理和维护解决方案，无论您是初学者还是经验丰富的开发者，都能在这里找到所需的帮助。

本手册不仅涵盖了 WSL 的基础操作，还深入探讨了高级应用场景，例如环境迁移、性能优化和安全加固等。我们为您准备了大量可直接复制粘贴的命令示例，以及详细的故障排除指南，助您轻松应对各种挑战。

**Main contents include / 主要内容包括：**

- **Quick Command Reference:** Quickly find and execute common WSL commands. / **常用命令速查：** 快速查找并执行常用的 WSL 命令。
- **Troubleshooting Guide:** Solve common issues like path problems, service restarts, and network repairs. / **故障排除指南：** 解决路径问题、服务重启、网络修复等常见问题。
- **Backup and Recovery:** Provides one-click backup and recovery scripts to ensure your data security. / **备份与恢复：** 提供一键式备份和恢复脚本，保障您的数据安全。
- **Complete Uninstall and Reinstall:** Detailed steps and commands to help you completely clean and reset your WSL environment. / **完全卸载与重装：** 详细的步骤和命令，助您彻底清理和重置 WSL 环境。
- **Environment Migration and Configuration Optimization:** Easily achieve cross-device environment migration and optimize system performance. / **环境迁移与配置优化：** 轻松实现跨设备环境迁移，并优化系统性能。
- **Development Environment Configuration:** Quickly set up an efficient WSL development environment. / **开发环境配置：** 快速搭建高效的 WSL 开发环境。
- **Network and Remote Access:** Configure WSL networking to enable remote access and port forwarding. / **网络与远程访问：** 配置 WSL 网络，实现远程访问和端口转发。
- **System Optimization and Maintenance:** Master the best practices for system optimization to ensure long-term stable operation. / **系统优化与维护：** 掌握系统优化的最佳实践，确保持久稳定运行。

Let's start exploring the powerful features of WSL! / 让我们开始探索 WSL 的强大功能吧！


## Table of Contents / 目录
1. [WSL Common Commands Quick Reference](#wsl-common-commands-quick-reference--wsl常用命令速查手册)
2. [WSL Troubleshooting Command Collection](#wsl-troubleshooting-command-collection--wsl故障排除命令集合)
3. [WSL Backup and Recovery Guide](#wsl-backup-and-recovery-guide--wsl备份恢复操作指南)
4. [WSL Complete Uninstall and Reinstall Guide](#wsl-complete-uninstall-and-reinstall-guide--wsl完全卸载和重装指南)
5. [WSL Environment Migration and Configuration Optimization](#wsl-environment-migration-and-configuration-optimization--wsl环境迁移和配置优化)
6. [WSL Development Environment Configuration](#wsl-development-environment-configuration--wsl开发环境配置)
7. [WSL Network and Remote Access Configuration](#wsl-network-and-remote-access-configuration--wsl网络和远程访问配置)
8. [System Optimization and Maintenance](#system-optimization-and-maintenance--系统优化和维护)
9. [WSL Complete Deployment Process](#wsl-complete-deployment-process--wsl完整部署流程)

---

## 1. WSL Common Commands Quick Reference / WSL常用命令速查手册

This section provides the most commonly used commands for daily WSL management. You can use it as a quick reference to find and execute the necessary operations.

---

本章节提供了 WSL 日常管理中最常用的命令，您可以将其用作快速参考，以便在需要时迅速找到并执行相应的操作。

### Basic WSL Management Commands / 基础WSL管理命令

### 1.1 Windows Subsystem Feature Management / Windows 子系统功能管理

Before you start using WSL, you need to ensure that the relevant Windows features are enabled. The following commands can help you do this quickly:

---

在开始使用 WSL 之前，您需要确保已启用相关的 Windows 功能。以下命令可帮助您快速完成此操作：

- **Enable Windows Subsystem for Linux feature / 开启 Windows 子系统功能**

  ```powershell
  # Enable the WSL feature, this operation requires administrator privileges
  # 启用 WSL 功能，此操作需要管理员权限
  dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
  ```

- **Enable Virtual Machine Platform feature / 开启虚拟机平台功能**

  ```powershell
  # Enable the Virtual Machine Platform, which is necessary to run WSL 2
  # 启用虚拟机平台，这是运行 WSL 2 的必要条件
  dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
  ```

- **Disable related features / 关闭相关功能**

  ```powershell
  # If needed, you can also disable these features at any time
  # 如果需要，您也可以随时禁用这些功能
  dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
  dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart
  ```

```powershell
  dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart
  ```

```powershell
# Enable subsystem
# 开启子系统
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 

# Enable virtual machine platform
# 开启虚拟机平台
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Disable subsystem
# 关闭子系统
dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart

# Disable virtual machine platform
# 关闭虚拟机平台
dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart

# If you can't install ubuntu, open powershell as an administrator (necessary step)
# 无法安装ubuntu的话管理员打开powershell（必要步骤）
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```

### 1.2 View WSL Status and Version / 查看 WSL 状态和版本

Understanding the current running status and version information of WSL is the first step to effective management. You can use the following commands to get this information:

---

了解当前 WSL 的运行状态和版本信息，是进行有效管理的第一步。您可以使用以下命令来获取这些信息：

- **View installed distributions / 查看已安装的发行版**

  ```powershell
  # List all installed Linux distributions and their status
  # 列出所有已安装的 Linux 发行版及其状态
  wsl --list --verbose
  # Or use the shorthand form
  # 或者使用简写形式
  wsl -l -v
  ```

- **View overall WSL status / 查看 WSL 整体状态**

  ```powershell
  # Display global WSL configuration information, such as the default distribution and kernel version
  # 显示 WSL 的全局配置信息，例如默认发行版和内核版本
  wsl --status
  ```

- **Version conversion and settings / 版本转换与设置**

  ```powershell
  # Convert the specified distribution (e.g., Ubuntu-20.04) to WSL 2
  # 将指定的发行版（例如 Ubuntu-20.04）转换为 WSL 2
  wsl --set-version Ubuntu-20.04 2

  # Convert it back to WSL 1
  # 将其转换回 WSL 1
  wsl --set-version Ubuntu-20.04 1

  # Set the default WSL version for future installations
  # 设置未来安装的默认 WSL 版本
  wsl --set-default-version 2
  ```

```powershell
# View WSL version
# 查看WSL版本
wsl --version

# View installed distributions
# 查看已安装的发行版
wsl --list --verbose
wsl -l -v

# View WSL status
# 查看WSL状态
wsl --status

# View and convert WSL versions
# WSL版本查看与转换
wsl --list --verbose
wsl --set-version Ubuntu-20.04 2  # Convert to WSL2
wsl --set-version Ubuntu-20.04 1  # Convert to WSL1

# Set default WSL version
# 设置默认WSL版本
wsl --set-default-version 1  # Set to WSL1
wsl --set-default-version 2  # Set to WSL2

# Directly set a specific version of ubuntu to WSL2, taking Ubuntu-24.04 as an example
# 直接设定特定版本ubuntu WSL2，以Ubuntu-24.04为例
wsl --set-version Ubuntu-24.04 2
```

### 1.3 WSL Distribution Management / WSL 发行版管理

WSL supports running multiple Linux distributions at the same time, and you can install, switch, and manage them as needed.

---

WSL 支持同时运行多个 Linux 发行版，您可以根据需要进行安装、切换和管理。

- **Installation and Uninstallation / 安装与卸载**

  ```powershell
  # View the list of distributions available for online installation
  # 查看可在线安装的发行版列表
  wsl --list --online

  # Install the specified distribution, e.g., Debian
  # 安装指定的发行版，例如 Debian
  wsl --install -d Debian

  # Uninstall a distribution that is no longer needed
  # 卸载不再需要的发行版
  wsl --unregister Ubuntu-20.04
  ```

- **Switching and Starting / 切换与启动**

  ```powershell
  # Set the default startup distribution
  # 设置默认启动的发行版
  wsl --set-default Ubuntu-24.04

  # Start a non-default distribution
  # 启动非默认的发行版
  wsl -d Debian

  # Start as a specific user (e.g., root)
  # 以特定用户（例如 root）启动
  wsl -d Ubuntu-24.04 -u root
  ```

```powershell
# List available distributions
# 列出可用的发行版
wsl --list --online
wsl -l -o

# Install the default distribution (Ubuntu)
# 安装默认发行版（Ubuntu）
wsl --install

# Install a specified distribution
# 安装指定发行版
wsl --install -d Ubuntu-20.04
wsl --install -d Debian

# Set the default distribution
# 设置默认发行版
wsl --set-default Ubuntu-20.04

# Switching and managing multiple subsystems
# 多个子系统时的切换和管理
wsl -d Ubuntu-24.04  # Specify to activate a specific distribution
wsl --set-default Ubuntu-24.04  # Switch the default distribution

# Start a specified distribution
# 启动指定发行版
wsl -d Ubuntu-20.04

# Start as a specified user
# 以指定用户启动
wsl -d Ubuntu-20.04 -u root
```

### 1.4 WSL Service Control / WSL 服务控制

In some cases, you may need to manually control the running state of the WSL service, for example, during troubleshooting or resource optimization.

---

在某些情况下，您可能需要手动控制 WSL 服务的运行状态，例如在进行故障排除或资源优化时。

- **Shutdown and Restart / 关闭与重启**

  ```powershell
  # Immediately shut down all running WSL instances
  # 立即关闭所有正在运行的 WSL 实例
  wsl --shutdown

  # Terminate the specified distribution
  # 终止指定的发行版
  wsl --terminate Ubuntu-20.04

  # Restart the WSL service (shut down first, then start)
  # 重启 WSL 服务（先关闭再启动）
  wsl --shutdown
  # After waiting a few seconds, restart by executing any wsl command
  # 等待几秒后，通过执行任何 wsl 命令来重新启动
  wsl -l -v
  ```

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

### 1.5 File System Operations / 文件系统操作

WSL and Windows can easily share files, which provides great convenience for development and data exchange.

---

WSL 与 Windows 之间可以方便地共享文件，这为开发和数据交换提供了极大的便利。

- **Accessing Files / 访问文件**

  ```powershell
  # Access the WSL file system in Windows File Explorer
  # 在 Windows 文件资源管理器中访问 WSL 文件系统
  # Just enter the following path in the address bar
  # 只需在地址栏输入以下路径即可
  \\wsl$\
  # Or directly access a specific distribution
  # 或者直接访问特定的发行版
  \\wsl$\Ubuntu-24.04\

  # Access Windows files in WSL
  # 在 WSL 中访问 Windows 文件
  # Windows drives are automatically mounted under the /mnt/ directory
  # Windows 的驱动器会自动挂载到 /mnt/ 目录下
  ls /mnt/c/Users/
  ```

- **Mounting Drives / 挂载驱动器**

  ```powershell
  # Manually mount other drives or network shares in WSL
  # 在 WSL 中手动挂载其他驱动器或网络共享
  # First create a mount point
  # 首先创建一个挂载点
  sudo mkdir /mnt/data
  # Then perform the mount operation
  # 然后执行挂载操作
  sudo mount -t drvfs D: /mnt/data

  # Mount a network share
  # 挂载网络共享
  sudo mkdir /mnt/network
  sudo mount -t drvfs '\\server\share' /mnt/network
  ```

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

### WSL Configuration Management / WSL配置管理

#### .wslconfig File Configuration (in user directory) / .wslconfig文件配置（用户目录下）
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

#### wsl.conf File Configuration (inside WSL) / wsl.conf文件配置（WSL内部）
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

# Enable systemd for WSL1
# WSL1启用systemd功能配置
[boot]
systemd=true
```

### Network and Port Management / 网络和端口管理
```powershell
# View WSL IP address
# 查看WSL IP地址
wsl hostname -I

# Port forwarding (administrator privileges)
# 端口转发（管理员权限）
netsh interface portproxy add v4tov4 listenport=8080 listenaddress=0.0.0.0 connectport=8080 connectaddress=172.x.x.x

# Practical port forwarding example (connecting to SSH service within WSL)
# 实际端口转发示例（连接WSL内的SSH服务）
netsh interface portproxy add v4tov4 listenport=2222 connectaddress=169.254.10.67 connectport=22

# View WSL internal IP address
# 查看WSL内网IP地址
ip a

# View port forwarding rules
# 查看端口转发规则
netsh interface portproxy show all

# Delete port forwarding
# 删除端口转发
netsh interface portproxy delete v4tov4 listenport=8080 listenaddress=0.0.0.0
```

---

## 2. WSL Troubleshooting Command Collection / WSL 故障排除命令集合

This chapter collects practical commands and tips for solving common WSL problems, hoping to help you quickly resume normal work.

---

本章节汇集了解决 WSL 常见问题的实用命令和技巧，希望能帮助您快速恢复正常工作。

### 2.1 Service and Process Issues / 服务和进程问题

When WSL fails to start or responds slowly, you should first check whether the relevant services and processes are running normally.

---

当 WSL 无法启动或响应迟缓时，首先应检查相关的服务和进程是否正常运行。

- **Restarting the WSL Service / 重启 WSL 服务**

  ```powershell
  # Forcibly restart the WSL service, which can solve many connection and startup problems
  # 强制重启 WSL 服务，这可以解决许多连接和启动问题
  wsl --shutdown
  Get-Service LxssManager | Restart-Service
  # After a short wait, try to start WSL again
  # 稍等片刻后，尝试再次启动 WSL
  wsl
  ```

- **Checking WSL-related Services / 检查 WSL 相关服务**

  ```powershell
  # Confirm whether the core services of WSL are running
  # 确认 WSL 的核心服务是否正在运行
  Get-Service LxssManager
  Get-Service vmcompute
  ```


#### WSL Service Restart / WSL服务重启
```powershell
# Completely restart WSL
# 完全重启WSL
wsl --shutdown
Get-Service LxssManager | Restart-Service
wsl

# Restart a specific distribution
# 重启特定发行版
wsl --terminate Ubuntu-20.04
wsl -d Ubuntu-20.04
```

#### Check WSL-related Services / 检查WSL相关服务
```powershell
# Check WSL service status
# 检查WSL服务状态
Get-Service LxssManager
Get-Service vmcompute

# Start WSL services
# 启动WSL服务
Start-Service LxssManager
Start-Service vmcompute

# Check Hyper-V status
# 检查Hyper-V状态
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
```

#### Solution for WSL command error "The system cannot find the path specified" / WSL命令报错"系统找不到指定的路径"解决方案
```powershell
# When WSL shows the error "The system cannot find the path specified" or "The system cannot find the file specified"
# 当WSL出现"系统找不到相关路径"或"系统找不到指定的文件"错误时
# Solution: Reinstall the WSL package
# 解决方案：重装WSL包
# 1. Visit https://github.com/microsoft/WSL
# 1. 访问 https://github.com/microsoft/WSL
# 2. Go to the release page and download the stable version installation package
# 2. 进入release页面，下载稳定版本安装包
# 3. Install to fix the path issue
# 3. 安装即可修复路径问题
```

### Path and Permission Issues / 路径和权限问题

#### Fix Path Issues / 修复路径问题
```bash
# Fix the PATH environment variable within WSL
# 在WSL内修复PATH环境变量
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Permanently fix the PATH
# 永久修复PATH
echo 'export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >> ~/.bashrc
source ~/.bashrc
```

#### Fix Permissions / 权限修复
```bash
# Fix file permissions
# 修复文件权限
sudo chmod -R 755 /path/to/directory
sudo chown -R $USER:$USER /path/to/directory

# Fix WSL mount permissions
# 修复WSL挂载权限
sudo umount /mnt/c
sudo mount -t drvfs C: /mnt/c -o metadata,uid=1000,gid=1000,umask=022,fmask=133

# Modify WSL permissions for Windows hard drives (to allow RStudio-server etc. to modify data on Windows data disks)
# WSL对Windows硬盘权限修改（让RStudio-server等可以修改Windows数据盘数据）
# Modify mount options in WSL
# 在WSL中修改挂载选项
sudo umount /mnt/d
sudo mount -t drvfs D: /mnt/d -o metadata,uid=1000,gid=1000,umask=000,fmask=000
```

#### Solve Installation Issues Related to Permissions / 解决权限相关的安装问题
```bash
# Solve "Failed to take /etc/passwd lock: Invalid argument" error
# 解决Failed to take /etc/passwd lock：Invalid argument错误
# This is usually caused by WSL permission issues
# 这通常是WSL权限问题导致的
sudo chmod 644 /etc/passwd
sudo chmod 644 /etc/group
sudo chmod 640 /etc/shadow

# Fix sudo permission issues
# 修复sudo权限问题
# If the user is not in the sudoers file
# 如果用户不在sudoers文件中
su root
usermod -aG sudo $USER
# Or edit the sudoers file directly
# 或者直接编辑sudoers文件
visudo
```

### Network Connection Repair / 网络连接修复

#### DNS Issue Repair / DNS问题修复
```bash
# Fix DNS resolution
# 修复DNS解析
sudo rm /etc/resolv.conf
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo bash -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'

# Or use Windows DNS
# 或者使用Windows DNS
sudo bash -c 'echo "nameserver 192.168.1.1" > /etc/resolv.conf'
```

#### Network Reset / 网络重置
```powershell
# Network reset on the Windows side
# Windows端网络重置
netsh winsock reset
netsh int ip reset
ipconfig /flushdns

# Restart network adapters
# 重启网络适配器
Get-NetAdapter | Restart-NetAdapter
```

### Disk and Storage Issues / 磁盘和存储问题

#### Clean Up WSL Disk Space / 清理WSL磁盘空间
```bash
# Clean package cache
# 清理包缓存
sudo apt autoremove
sudo apt autoclean
sudo apt clean

# Clean log files
# 清理日志文件
sudo journalctl --vacuum-time=7d
sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;

# Deep clean Ubuntu system
# Ubuntu系统深度清理
sudo apt autoremove --purge
sudo apt autoclean
sudo apt clean
sudo journalctl --vacuum-time=3d
sudo find /tmp -type f -atime +7 -delete
sudo find /var/tmp -type f -atime +7 -delete
```

#### Compact WSL Virtual Disk / 压缩WSL虚拟磁盘
```powershell
# Shut down WSL
# 关闭WSL
wsl --shutdown

# Compact the virtual disk (administrator privileges)
# 压缩虚拟磁盘（管理员权限）
diskpart
# Execute in diskpart:
# 在diskpart中执行：
select vdisk file="C:\Users\%USERNAME%\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu20.04onWindows_79rhkp1fndgsc\LocalState\ext4.vhdx"
compact vdisk
exit
```

### Registry Repair / 注册表修复

#### Repair WSL Registry Entries / 修复WSL注册表项
```powershell
# Check the WSL registry
# 检查WSL注册表
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"

# Reset the WSL registry (use with caution)
# 重置WSL注册表（谨慎使用）
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss" -Recurse -Force
```

---

## 3. WSL Backup and Recovery Guide / WSL 备份恢复操作指南

Data security is crucial. This chapter will guide you on how to effectively back up and restore your WSL environment to ensure your work is safe.

---

数据安全至关重要。本章节将指导您如何有效地备份和恢复 WSL 环境，确保您的工作成果万无一失。

### 3.1 Backing Up a WSL Distribution / 备份 WSL 发行版

You can export an entire WSL distribution to a `tar` file for later recovery or migration.

---

您可以将整个 WSL 发行版导出为一个 `tar` 文件，以便后续恢复或迁移。

```powershell
# Create a directory to store backups
# 创建用于存放备份的目录
md D:\WSL-Backups

# Back up the distribution named Ubuntu-24.04 to the specified path
# 将名为 Ubuntu-24.04 的发行版备份到指定路径
wsl --export Ubuntu-24.04 D:\WSL-Backups\ubuntu-24.04-backup.tar
```

### 3.2 Restoring a WSL Distribution / 恢复 WSL 发行版

When needed, you can quickly restore your WSL environment from a backup file.

---

当需要时，您可以从备份文件快速恢复 WSL 环境。

```powershell
# Restore from a backup file and install it to a new location
# 从备份文件恢复，并将其安装到新的位置
# wsl --import <DistributionName> <InstallLocation> <BackupFilePath>
# wsl --import <发行版名称> <安装路径> <备份文件路径>
wsl --import Ubuntu-24.04-Restored D:\WSL\Restored D:\WSL-Backups\ubuntu-24.04-backup.tar

# After restoration, you can start it as usual
# 恢复后，您可以像平常一样启动它
wsl -d Ubuntu-24.04-Restored
```


### Manual Backup Method / 手动备份方法

#### Export WSL Distribution / 导出WSL发行版
```powershell
# Create backup directory
# 创建备份目录
New-Item -ItemType Directory -Path "C:\WSL-Backups" -Force

# Export the distribution
# 导出发行版
wsl --export Ubuntu-20.04 "C:\WSL-Backups\Ubuntu-20.04-backup-$(Get-Date -Format 'yyyyMMdd').tar"

# Verify the backup file
# 验证备份文件
Get-ChildItem "C:\WSL-Backups\" | Select-Object Name, Length, LastWriteTime
```

#### Restore WSL Distribution / 恢复WSL发行版
```powershell
# Uninstall the existing distribution (optional)
# 删除现有发行版（可选）
wsl --unregister Ubuntu-20.04

# Restore from backup
# 从备份恢复
wsl --import Ubuntu-20.04-Restored "C:\WSL\Ubuntu-20.04-Restored" "C:\WSL-Backups\Ubuntu-20.04-backup-20240101.tar"

# Set the default user
# 设置默认用户
Ubuntu-20.04.exe config --default-user username
```

### Automated Backup Script / 自动备份脚本

#### Create Automated Backup Script / 创建自动备份脚本
```powershell
# Save as WSL-AutoBackup.ps1
# 保存为 WSL-AutoBackup.ps1
param(
    [string]$DistributionName = "Ubuntu-20.04",
    [string]$BackupPath = "C:\WSL-Backups",
    [int]$RetentionDays = 7
)

# Create backup directory
# 创建备份目录
if (!(Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force
}

# Generate backup file name
# 生成备份文件名
$BackupFileName = "$DistributionName-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').tar"
$BackupFullPath = Join-Path $BackupPath $BackupFileName

try {
    # Execute backup
    # 执行备份
    Write-Host "Starting backup of $DistributionName..."
    Write-Host "开始备份 $DistributionName..."
    wsl --export $DistributionName $BackupFullPath
    
    if (Test-Path $BackupFullPath) {
        Write-Host "Backup successful: $BackupFullPath"
        Write-Host "备份成功: $BackupFullPath"
        
        # Clean up old backups
        # 清理旧备份
        $OldBackups = Get-ChildItem $BackupPath -Filter "$DistributionName-backup-*.tar" | 
                     Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) }
        
        foreach ($OldBackup in $OldBackups) {
            Remove-Item $OldBackup.FullName -Force
            Write-Host "Deleted old backup: $($OldBackup.Name)"
            Write-Host "已删除旧备份: $($OldBackup.Name)"
        }
    } else {
        Write-Error "Backup failed"
        Write-Error "备份失败"
    }
} catch {
    Write-Error "An error occurred during backup: $($_.Exception.Message)"
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

### Incremental Backup Solution / 增量备份方案

#### Create Incremental Backup Script / 创建增量备份脚本
```bash
#!/bin/bash
# Save as incremental-backup.sh
# 保存为 incremental-backup.sh

BACKUP_DIR="/mnt/c/WSL-Backups/incremental"
FULL_BACKUP_DIR="/mnt/c/WSL-Backups/full"
DATE=$(date +%Y%m%d-%H%M%S)

# Create backup directories
# 创建备份目录
mkdir -p "$BACKUP_DIR"
mkdir -p "$FULL_BACKUP_DIR"

# Check if a full backup is needed (weekly)
# 检查是否需要完整备份（每周一次）
if [ ! -f "$FULL_BACKUP_DIR/last_full_backup" ] || [ $(find "$FULL_BACKUP_DIR/last_full_backup" -mtime +7) ]; then
    echo "Performing full backup..."
    echo "执行完整备份..."
    tar -czf "$FULL_BACKUP_DIR/full-backup-$DATE.tar.gz" /home
    echo "$DATE" > "$FULL_BACKUP_DIR/last_full_backup"
else
    echo "Performing incremental backup..."
    echo "执行增量备份..."
    find /home -newer "$FULL_BACKUP_DIR/last_full_backup" -type f | tar -czf "$BACKUP_DIR/incremental-backup-$DATE.tar.gz" -T -
fi

# Clean up old backups
# 清理旧备份
find "$BACKUP_DIR" -name "incremental-backup-*.tar.gz" -mtime +30 -delete
find "$FULL_BACKUP_DIR" -name "full-backup-*.tar.gz" -mtime +90 -delete
```

---

## 4. WSL Complete Uninstall and Reinstall Guide / WSL 完全卸载和重装指南

In some cases, you may need to completely uninstall and reinstall WSL to resolve tricky issues or reset the environment. Please follow these steps strictly to avoid problems caused by residual files. / 在某些情况下，您可能需要彻底卸载并重新安装 WSL，以解决一些棘手的问题或进行环境重置。请严格按照以下步骤操作，以避免残留文件导致的问题。

### 4.1 Uninstall WSL Distributions / 卸载 WSL 发行版

First, uninstall all installed Linux distributions. / 首先，卸载所有已安装的 Linux 发行版。

```powershell
# List installed distributions
# 查看已安装的发行版
wsl -l -v

# Unregister all distributions one by one
# 逐个注销所有发行版
wsl --unregister Ubuntu-24.04
wsl --unregister Debian
# ... repeat for all other distributions
# ... 对所有其他发行版重复此操作
```

### 4.2 Disable WSL-Related Features / 关闭 WSL 相关功能

Next, disable the WSL and Virtual Machine Platform features. / 接下来，禁用 WSL 和虚拟机平台功能。

```powershell
# Run PowerShell as Administrator
# 以管理员权限运行 PowerShell
dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart
```

### 4.3 Restart Your Computer / 重启计算机

To ensure all changes take effect, be sure to restart your computer. / 为了确保所有更改生效，请务必重启您的计算机。

```powershell
Restart-Computer
```

### 4.4 Reinstall WSL / 重新安装 WSL

After restarting, you can follow the guide in Chapter 1 of this manual to re-enable the relevant features and install the distributions you need. / 重启后，您可以按照本手册第一章的指引，重新启用相关功能并安装您需要的发行版。

```powershell
# Re-enable features
# 重新启用功能
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart the computer again
# 再次重启计算机
Restart-Computer

# Install WSL
# 安装 WSL
wsl --install
```


### Complete Uninstall of WSL / 完全卸载WSL

#### Step 1: Back Up Important Data / 步骤1：备份重要数据
```powershell
# List all distributions
# 列出所有发行版
wsl -l -v

# Back up important distributions
# 备份重要发行版
wsl --export Ubuntu-20.04 "C:\Temp\Ubuntu-backup-final.tar"
wsl --export Debian "C:\Temp\Debian-backup-final.tar"
```

#### Step 2: Uninstall All WSL Distributions / 步骤2：卸载所有WSL发行版
```powershell
# Get all installed distributions
# 获取所有已安装的发行版
$Distributions = wsl -l -q

# Uninstall one by one
# 逐个卸载
foreach ($Dist in $Distributions) {
    if ($Dist -and $Dist.Trim() -ne "") {
        Write-Host "Uninstalling: $Dist"
        Write-Host "正在卸载: $Dist"
        wsl --unregister $Dist.Trim()
    }
}

# Verify uninstallation
# 验证卸载
wsl -l -v
```

#### Step 3: Stop WSL-Related Services / 步骤3：停止WSL相关服务
```powershell
# Stop WSL services
# 停止WSL服务
Stop-Service LxssManager -Force
Stop-Service vmcompute -Force

# Kill all WSL processes
# 关闭所有WSL进程
Get-Process | Where-Object {$_.ProcessName -like "*wsl*" -or $_.ProcessName -like "*lxss*"} | Stop-Process -Force
```

#### Step 4: Disable WSL Features / 步骤4：禁用WSL功能
```powershell
# Disable WSL features (requires restart)
# 禁用WSL功能（需要重启）
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform

# Or use DISM
# 或使用DISM
dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart
```

#### Step 7: Clean Up Environment Variables / 步骤7：清理环境变量
```powershell
# Clean up WSL-related paths from PATH
# 清理PATH中的WSL相关路径
$CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$CleanedPath = $CurrentPath -replace ";[^;]*lxss[^;]*", ""
[Environment]::SetEnvironmentVariable("PATH", $CleanedPath, "Machine")
```

### Reinstalling WSL / 重新安装WSL

#### Step 1: Enable Necessary Features / 步骤1：启用必要功能
```powershell
# Enable WSL features
# 启用WSL功能
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart

# Or use DISM
# 或使用DISM
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

Write-Host "Please restart your computer to complete feature enablement"
Write-Host "请重启计算机以完成功能启用"
```

#### Step 2: Download and Install the WSL2 Kernel Update / 步骤2：下载并安装WSL2内核更新
```powershell
# Download the WSL2 kernel update package
# 下载WSL2内核更新包
$KernelUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
$KernelUpdatePath = "$env:TEMP\wsl_update_x64.msi"

Invoke-WebRequest -Uri $KernelUpdateUrl -OutFile $KernelUpdatePath
Start-Process -FilePath $KernelUpdatePath -ArgumentList "/quiet" -Wait

# Set WSL2 as the default version
# 设置WSL2为默认版本
wsl --set-default-version 2
```

#### Step 3: Install a Linux Distribution / 步骤3：安装Linux发行版
```powershell
# Install the default Ubuntu
# 安装默认Ubuntu
wsl --install -d Ubuntu

# Or install other distributions
# 或安装其他发行版
wsl --install -d Ubuntu-20.04
wsl --install -d Debian

# Method to install Ubuntu without the Microsoft Store
# 绕开Microsoft Store安装Ubuntu的方法
# 1. Visit https://docs.microsoft.com/en-us/windows/wsl/install-manual
# 1. 访问 https://docs.microsoft.com/en-us/windows/wsl/install-manual
# 2. Download the corresponding .appx file
# 2. 下载对应的.appx文件
# 3. Use Add-AppxPackage to install
# 3. 使用Add-AppxPackage安装
```

#### Step 4: Restore Backup Data / 步骤4：恢复备份数据
```powershell
# Restore from backup
# 从备份恢复
if (Test-Path "C:\Temp\Ubuntu-backup-final.tar") {
    wsl --import Ubuntu-Restored "C:\WSL\Ubuntu-Restored" "C:\Temp\Ubuntu-backup-final.tar"
    Write-Host "Ubuntu environment has been restored from backup"
    Write-Host "Ubuntu环境已从备份恢复"
}
```

---

## 5. WSL Environment Migration and Configuration Optimization / 5. WSL 环境迁移和配置优化

This chapter will introduce how to migrate your WSL environment from one computer to another, and how to improve performance through configuration optimization. / 本章节将介绍如何将您的 WSL 环境从一台计算机迁移到另一台，以及如何通过优化配置来提升性能。

### 5.1 Environment Migration / 5.1 环境迁移

The migration of the WSL environment mainly relies on the `wsl --export` and `wsl --import` commands. This process is very similar to backup and recovery. / WSL 环境的迁移主要依赖于 `wsl --export` 和 `wsl --import` 命令。这个过程与备份和恢复非常相似。

**Steps:** / **步骤：**

1.  **On the source computer:** / **在源计算机上：**
    -   Use the `wsl --export` command to package your distribution into a `tar` file. / 使用 `wsl --export` 命令将您的发行版打包成一个 `tar` 文件。
    -   Copy the generated `tar` file to the target computer (e.g., via a USB drive or network share). / 将生成的 `tar` 文件复制到目标计算机（例如，通过 U 盘或网络共享）。

2.  **On the target computer:** / **在目标计算机上：**
    -   Ensure WSL is installed and enabled. / 确保已安装并启用 WSL。
    -   Use the `wsl --import` command to import the `tar` file as a new distribution. / 使用 `wsl --import` 命令将 `tar` 文件导入为新的发行版。

```powershell
# Source computer operation
# 源计算机操作
wsl --export Ubuntu-24.04 D:\Transfer\my-wsl-env.tar

# Target computer operation
# 目标计算机操作
wsl --import My-Dev-Env C:\WSL\My-Dev-Env D:\Transfer\my-wsl-env.tar
```

### 5.2 Configuration Optimization (` .wslconfig`) / 5.2 配置优化 (` .wslconfig`)

By creating and editing the `.wslconfig` file in your Windows user directory, you can fine-tune the resource allocation of WSL 2. / 通过在您的 Windows 用户目录下创建和编辑 `.wslconfig` 文件，您可以精细地控制 WSL 2 的资源分配。

**Example Configuration:** / **示例配置：**

```ini
# Path: %USERPROFILE%\.wslconfig
# 路径: %USERPROFILE%\.wslconfig

[wsl2]
# Limit WSL 2 memory to 8GB
# 限制 WSL 2 可用的内存为 8GB
memory=8GB

# Allocate 4 processor cores
# 分配 4 个处理器核心
processors=4

# Disable swap for better performance, but ensure sufficient memory
# 关闭交换空间以获得更好的性能，但需确保内存充足
swap=0

# Enable nested virtualization to run VMs or Docker in WSL
# 启用嵌套虚拟化，方便在 WSL 中运行虚拟机或 Docker
nestedVirtualization=true

# Enable localhost port forwarding
# 启用 localhost 端口转发
localhostForwarding=true
```

**Note:** After modifying the `.wslconfig` file, you need to run `wsl --shutdown` and restart WSL for the changes to take effect. / **注意：** 修改 `.wslconfig` 文件后，需要运行 `wsl --shutdown` 并重启 WSL 才能使更改生效。


### WSL Migration Operations / WSL迁移操作

#### Migrating WSL from C drive to another drive / WSL从C盘迁移到其他盘区
```powershell
# 1. Export the existing distribution
# 1. 导出现有发行版
wsl --export Ubuntu-20.04 "D:\WSL-Backup\Ubuntu-20.04.tar"

# 2. Unregister the original distribution
# 2. 注销原发行版
wsl --unregister Ubuntu-20.04

# 3. Import to the new location
# 3. 导入到新位置
wsl --import Ubuntu-20.04 "D:\WSL\Ubuntu-20.04" "D:\WSL-Backup\Ubuntu-20.04.tar"

# 4. Set the default user (if needed)
# 4. 设置默认用户（如果需要）
# Create /etc/wsl.conf file to set the default user
# 创建/etc/wsl.conf文件设置默认用户
```

### Ubuntu Software Source Configuration / Ubuntu软件源配置
```bash
# Tsinghua University mirror source configuration
# 清华大学镜像源配置
# Edit /etc/apt/sources.list
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

## 6. WSL Development Environment Configuration / 6. WSL 开发环境配置

With WSL, you can build a Linux development environment that is highly consistent with your production environment. This section will illustrate this by configuring a Node.js and Python environment. / 利用 WSL，您可以构建一个与生产环境高度一致的 Linux 开发环境。本节将以配置一个 Node.js 和 Python 环境为例进行说明。

### 6.1 Install Visual Studio Code / 6.1 安装 Visual Studio Code

VS Code provides powerful remote development extensions and is the preferred editor for WSL development. / VS Code 提供了强大的远程开发扩展，是 WSL 开发的首选编辑器。

1.  Install [Visual Studio Code](https://code.visualstudio.com/) on Windows. / 在 Windows 上安装 [Visual Studio Code](https://code.visualstudio.com/)。
2.  Install the **Remote - WSL** extension in VS Code. / 在 VS Code 中安装 **Remote - WSL** 扩展。

After installation, you can directly type `code .` in the WSL terminal to open the current directory, and VS Code will automatically connect to the WSL environment. / 安装后，您可以在 WSL 终端中直接输入 `code .` 来打开当前目录，VS Code 将自动连接到 WSL 环境。

### 6.2 Configure Node.js Development Environment / 6.2 配置 Node.js 开发环境

```bash
# Update package list
# 更新包列表
sudo apt update

# Install nvm (Node Version Manager) to manage multiple Node.js versions
# 安装 nvm (Node Version Manager)，用于管理多个 Node.js 版本
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# Make the nvm command effective
# 使 nvm 命令生效
source ~/.bashrc

# Install the latest LTS version of Node.js
# 安装最新的 LTS 版本的 Node.js
nvm install --lts

# Verify installation
# 验证安装
node -v
npm -v
```

### 6.3 Configure Python Development Environment / 6.3 配置 Python 开发环境

```bash
# Install Python and related tools
# 安装 Python 和相关工具
sudo apt install python3 python3-pip python3-venv -y

# Create and activate a virtual environment
# 创建并激活一个虚拟环境
python3 -m venv my-python-project
source my-python-project/bin/activate

# Install dependencies in the virtual environment
# 在虚拟环境中安装依赖包
pip install requests django flask

# Verify installation
# 验证安装
python --version
pip list
```


### Permission and User Management / 权限和用户管理

#### New System Permission Configuration / 新系统权限配置
```powershell
# First thing on a new system: set disk permissions for the admin user
# 新系统第一件事：给管理员用户设置磁盘权限
# 1. Right-click each drive -> Properties -> Security -> Edit
# 1. 右键每个磁盘 -> 属性 -> 安全 -> 编辑
# 2. Add the current user and set Full control permissions
# 2. 添加当前用户，设置完全控制权限
# 3. Pay special attention to the permission settings for Anaconda's env path
# 3. 特别注意Anaconda的env路径权限设置

# PowerShell admin permission settings
# PowerShell管理员权限设置
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# VSCode default admin permissions
# VSCode默认管理员权限
# Right-click code.exe -> Properties -> Compatibility -> Always run this program as an administrator
# 右键code.exe -> 属性 -> 兼容性 -> 始终以管理员身份运行此程序
```

#### WSL Username and SSH Access Settings / WSL用户名与SSH访问设置
```bash
# Add user to the sudo group
# 添加用户到sudo组
sudo usermod -aG sudo username

# Modify user permissions
# 修改用户权限
sudo visudo
# Add: username ALL=(ALL) NOPASSWD:ALL
# 添加: username ALL=(ALL) NOPASSWD:ALL

# Set up SSH key authentication
# 设置SSH密钥认证
mkdir -p ~/.ssh
chmod 700 ~/.ssh
# Copy public key to ~/.ssh/authorized_keys
# 复制公钥到 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Add a new user and configure permissions
# 添加新用户并配置权限
sudo adduser damncheater
sudo passwd damncheater

# If you have an old username, you can do this
# 如果有旧用户名可以这样操作
sudo cp -r /home/old_username /home/damncheater
sudo deluser old_username

# Grant highest permissions to the new username
# 添加最高权限到新用户名
sudo chown -R damncheater:damncheater /home/damncheater

# Edit the configuration file
# 编辑配置文件
sudo nano /etc/sudoers
# Add configuration, in the opened config file, find root ALL=(ALL) ALL, and add a line below
# 增加配置, 在打开的配置文件中，找到root ALL=(ALL) ALL, 在下面添加一行
# where xxx is the username you want to add
# 其中xxx是你要加入的用户名称
damncheater ALL=(ALL) ALL
```

### Development Tool Configuration / 开发工具配置

#### Anaconda/Miniconda Configuration / Anaconda/Miniconda配置
```bash
# Install Miniconda from the command line
# 命令行安装Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

# Add or remove default environment creation paths
# 添加或删除默认环境创建路径
conda config --add envs_dirs /path/to/new/envs
conda config --remove envs_dirs /path/to/old/envs

# View environment paths
# 查看环境路径
conda info --envs
```

#### Python Package Management / Python包管理
```bash
# Use a domestic mirror for pip
# pip使用国内镜像
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple package_name

# Permanently configure pip mirror
# 永久配置pip镜像
mkdir -p ~/.pip
cat > ~/.pip/pip.conf << EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF

# Accelerate PyTorch download
# PyTorch下载加速
pip install torch torchvision torchaudio -i https://pypi.tuna.tsinghua.edu.cn/simple
```

#### R Environment Configuration / R语言环境配置
```bash
# Resolve R package installation permission issues
# 解决R包安装权限问题
# Fix for permission error when installing the xml2 package
# 安装xml2包时的权限错误解决
install.packages("xml2", dependencies=TRUE, INSTALL_opts = c('--no-lock'))

# Fix R package installation permissions
# 修复R包安装权限
sudo chown -R $USER:$USER /usr/local/lib/R/site-library
```

---

## 7. WSL Network and Remote Access Configuration / WSL 网络和远程访问配置

This section describes how to configure the WSL network, including obtaining the IP address, setting up port forwarding, and enabling remote access.
本节将介绍如何配置 WSL 的网络，包括获取 IP 地址、进行端口转发以及实现远程访问。

### 7.1 Obtaining WSL's IP Address / 获取 WSL 的 IP 地址

Since WSL 2 runs in a virtual network, its IP address may change after each restart. You can use the following command to get the current IP address:
由于 WSL 2 运行在虚拟网络中，其 IP 地址可能会在每次重启后发生变化。您可以使用以下命令获取当前的 IP 地址：

```bash
# Execute in WSL terminal
# 在 WSL 终端中执行
ip addr | grep eth0
# or
# 或者
hostname -I
```

### 7.2 Port Forwarding / 端口转发

To access services running in WSL from Windows (e.g., a web server), you need to set up port forwarding.
要从 Windows 访问在 WSL 中运行的服务（例如 Web 服务器），您需要设置端口转发。

**Example: Forward Windows port 8080 to WSL port 8080**
**示例：将 Windows 的 8080 端口转发到 WSL 的 8080 端口**

1.  **Get WSL's IP address** (assuming it's `172.20.30.40`).
1.  **获取 WSL 的 IP 地址**（假设为 `172.20.30.40`）。
2.  **Open PowerShell with administrator privileges** and execute the following command:
2.  **以管理员权限打开 PowerShell** 并执行以下命令：

    ```powershell
    # Add port forwarding rule
    # 添加端口转发规则
    netsh interface portproxy add v4tov4 listenport=8080 listenaddress=0.0.0.0 connectport=8080 connectaddress=172.20.30.40

    # View existing rules
    # 查看已设置的规则
    netsh interface portproxy show all

    # Delete a rule
    # 删除规则
    netsh interface portproxy delete v4tov4 listenport=8080 listenaddress=0.0.0.0
    ```

### 7.3 Configuring SSH for Remote Access / 配置 SSH 实现远程访问

By enabling the SSH service in WSL, you can remotely connect to your WSL environment from other devices on the local network.
通过在 WSL 中启用 SSH 服务，您可以从局域网内的其他设备远程连接到您的 WSL 环境。

**Steps:**
**步骤：**

1.  **Install and configure the SSH server**
1.  **安装并配置 SSH 服务器**

    ```bash
    sudo apt update
    sudo apt install openssh-server
    # Modify SSH configuration, e.g., to allow password authentication
    # 修改 SSH 配置，例如允许密码登录
    sudo nano /etc/ssh/sshd_config
    # Find and change PasswordAuthentication yes
    # 找到并修改 PasswordAuthentication yes
    sudo service ssh start
    ```

2.  **Set up port forwarding**
2.  **设置端口转发**

    -   Forward a Windows port (e.g., 2222) to WSL's port 22.
    -   将 Windows 的某个端口（例如 2222）转发到 WSL 的 22 端口。

3.  **Connect using an SSH client**
3.  **使用 SSH 客户端连接**

    -   `ssh <your-wsl-username>@<your-windows-ip> -p 2222`


### SSH Service Configuration / SSH服务配置

#### WSL SSH Server Configuration / WSL SSH服务器配置
```bash
# Uninstall and reinstall SSH service
# 卸载并重新安装SSH服务
sudo apt purge openssh-server
sudo apt install openssh-server

# SSH service management
# SSH服务管理
sudo service ssh stop
sudo service ssh start
sudo service ssh restart

# Configure SSH service
# 配置SSH服务
sudo nano /etc/ssh/sshd_config
# Modify the following configurations:
# 修改以下配置：
Port 22
ListenAddress 0.0.0.0
ListenAddress ::
PermitRootLogin no
PasswordAuthentication yes
Subsystem sftp internal-sftp

# Restart the service
# 重启服务
sudo service ssh start

# Enable SSH on startup
# 开机启动ssh
sudo systemctl enable ssh
```

#### Windows SSH Service Configuration / Windows SSH服务配置
```powershell
# Enable Windows SSH service
# 启用Windows SSH服务
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Configure firewall
# 配置防火墙
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

### Network Configuration and Port Forwarding / 网络配置和端口转发

#### WSL2 Network Configuration / WSL2网络配置
```powershell
# WSL2 port forwarding script example
# WSL2端口转发脚本示例
# Forward WSL2 service ports to the Windows host
# 将WSL2的服务端口转发到Windows主机
$wslIP = (wsl hostname -I).Trim()
$ports = @(22, 80, 443, 3000, 8080)

foreach ($port in $ports) {
    netsh interface portproxy add v4tov4 listenport=$port listenaddress=0.0.0.0 connectport=$port connectaddress=$wslIP
}

# View forwarding rules
# 查看转发规则
netsh interface portproxy show all

# Delete forwarding rules
# 删除转发规则
foreach ($port in $ports) {
    netsh interface portproxy delete v4tov4 listenport=$port listenaddress=0.0.0.0
}
```

#### WSL Static IP Configuration / WSL IP固定配置
```bash
# Set a static IP address in WSL
# 在WSL中固定IP地址
# Edit /etc/netplan/01-netcfg.yaml (Ubuntu 18.04+)
# 编辑 /etc/netplan/01-netcfg.yaml (Ubuntu 18.04+)
sudo nano /etc/netplan/01-netcfg.yaml

# Example configuration:
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

# Apply the configuration
# 应用配置
sudo netplan apply
```

### NAT Traversal and Remote Access / 内网穿透和远程访问

#### Tailscale NAT Traversal / Tailscale内网穿透
```bash
# Install Tailscale
# 安装Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale
# 启动Tailscale
sudo tailscale up

# Also install and connect to the same account on the client
# 在客户端也安装并连接到同一账号
# Then you can access directly via the Tailscale IP
# 之后可以通过Tailscale IP直接访问
```

#### Oray (花生壳) NAT Traversal / 花生壳内网穿透
```bash
# Download the Oray client
# 下载花生壳客户端
# Visit https://hsk.oray.com/download/
# 访问 https://hsk.oray.com/download/
# Follow the official documentation to configure specific port penetration
# 按照官方文档配置特定端口穿透
```

#### rsync Resumable Transfer / rsync断点传输
```bash
# Resumable transfer for large files
# 大文件断点传输
rsync -avz --progress --partial source_file user@remote_host:/path/to/destination/

# Example of resumable transfer over SSH
# SSH断点传输示例
rsync -avz -e "ssh -p 22" --progress --partial /local/path/ user@remote:/remote/path/
```

---

## 8. System Optimization and Maintenance / 系统优化和维护

Regular optimization and maintenance are essential to ensure the long-term stability and efficient operation of WSL.
为了确保 WSL 的长期稳定和高效运行，定期的优化和维护是必不可少的。

### 8.1 Disk Space Cleanup / 磁盘空间清理

WSL 2's virtual disk file (`ext4.vhdx`) does not shrink automatically. You can use the `diskpart` tool to manually reclaim unused space.
WSL 2 的虚拟磁盘文件 (`ext4.vhdx`) 不会自动收缩。您可以使用 `diskpart` 工具来手动回收未使用的空间。

**Steps:**
**步骤：**

1.  **Shutdown WSL:** `wsl --shutdown`
1.  **关闭 WSL：** `wsl --shutdown`
2.  **Run `diskpart` as an administrator**
2.  **以管理员身份运行 `diskpart`**
3.  **Execute the following commands in `diskpart`:**
3.  **在 `diskpart` 中执行以下命令：**

    ```diskpart
    # 选择虚拟磁盘文件
    select vdisk file="C:\Users\YourUser\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu24.04_...\LocalState\ext4.vhdx"

    # 压缩磁盘
    compact vdisk

    # 分离磁盘
    detach vdisk
    ```

### 8.2 Updates and Upgrades / 更新和升级

Regularly update your Linux distribution and the WSL kernel to get the latest features and security patches.
定期更新您的 Linux 发行版和 WSL 内核，以获取最新的功能和安全补丁。

```bash
# Update package lists and installed packages
# 更新包列表和已安装的软件包
sudo apt update && sudo apt upgrade -y
```

```powershell
# Update the WSL kernel in PowerShell
# 在 PowerShell 中更新 WSL 内核
wsl --update
```


### Windows System Optimization / Windows系统优化

#### Memory and Storage Optimization / 内存和存储优化
```powershell
# Adjust the size of the hibernation file
# 调整休眠文件大小
powercfg -h size 50  # Set to 50%
# Or disable hibernation completely
# 或完全关闭休眠
powercfg -h off

# Disable Fast Startup (to avoid saving memory state to hiberfil.sys)
# 关闭快速启动（避免内存状态保存到hiberfil.sys）
# Control Panel -> Power Options -> Choose what the power buttons do -> Change settings that are currently unavailable
# 控制面板 -> 电源选项 -> 选择电源按钮的功能 -> 更改当前不可用的设置
# Uncheck "Turn on fast startup"
# 取消勾选"启用快速启动"
```

#### Network Priority Settings / 网络优先级设置
```powershell
# Set network adapter priority
# 设置网络适配器优先级
# When connected to both wired and wireless networks
# 当同时连接有线和无线网络时
Get-NetAdapter | Sort-Object InterfaceMetric
Set-NetIPInterface -InterfaceAlias "Ethernet" -InterfaceMetric 1
Set-NetIPInterface -InterfaceAlias "WLAN" -InterfaceMetric 2
```

#### Static IP Configuration / 静态IP配置
```powershell
# Set a static IP in Windows
# Windows设置静态IP
# It is recommended to use a higher IP address (e.g., 192.168.1.188 instead of 192.168.1.100)
# 建议使用较大的IP地址（如192.168.1.188而不是192.168.1.100）
# to avoid it being occupied by other devices after shutdown
# 避免关机后被其他设备占用

New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.188 -PrefixLength 24 -DefaultGateway 192.168.1.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 8.8.8.8,8.8.4.4
```

### Environment Variable Management / 环境变量管理

#### Resolving Environment Variable Character Limit Issues / 解决环境变量字符超标问题
```powershell
# When the PATH environment variable exceeds the 2047 character limit
# 当PATH环境变量超过2047字符限制时
# 1. Create a new system variable to store long paths
# 1. 创建新的系统变量存储长路径
[Environment]::SetEnvironmentVariable("LONG_PATHS", "C:\Very\Long\Path1;C:\Very\Long\Path2", "Machine")

# 2. Reference the new variable in PATH
# 2. 在PATH中引用新变量
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$newPath = $currentPath + ";%LONG_PATHS%"
[Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
```

### Startup Configuration / 开机自启动配置

#### WSL Auto-start on Boot / WSL开机自启动
```powershell
# Create a startup script
# 创建开机启动脚本
# Save to the shell:startup directory
# 保存到 shell:startup 目录
# Win+R, type: shell:startup
# Win+R 输入: shell:startup

# WSL-Startup.bat content:
# WSL-Startup.bat 内容：
@echo off
wsl -d Ubuntu-20.04 -u root service ssh start
wsl -d Ubuntu-20.04 -u root service nginx start
```

#### Auto-start Services within WSL / WSL内服务自启动
```bash
# Create the /etc/init.wsl file
# 创建 /etc/init.wsl 文件
cd /etc
sudo chmod 777 init.wsl
sudo nano /etc/init.wsl

#!/bin/sh
# Fill in any service, rstudio-server is also fine
# 填写任意服务，rstudio-server之类的也可以
service ssh restart
#service rstudio-server start
#service redis-server start
#service mysql start
#service nginx start

# Set execution permissions
# 设置执行权限
sudo chmod +x /etc/init.wsl

# PowerShell command, fill in your actual ubuntu version number
# PowerShell命令，这个ubuntu版本看自己的实际版本号填写
wsl -d Ubuntu-24.04 -u root /etc/init.wsl start
```

#### Windows Startup Script for WSL / Windows开机自启动WSL脚本
```vbscript
# Create a new file wsl2run_Ubuntu_redis.vbs (name it yourself, the extension must be vbs)
# 新建文件wsl2run_Ubuntu_redis.vbs（文件名自命名，扩展名是vbs就行）
# Be careful not to enter the wrong ubuntu version number, remember the version you downloaded from the store, or you can find the installed version by typing ubuntu in the start menu
# 填写注意ubuntu版本号别输错了，自己从store下载的版本是多少记住，或者开始菜单输入ubuntu就可以查到安装的版本
rem Msgbox "Auto-start wsl2's Ubuntu on Win10 boot and start redis"
rem Msgbox "Win10开机自动启动wsl2的Ubuntu，并由其启动redis"
Set ws = CreateObject("Wscript.Shell")
ws.run "wsl -d Ubuntu-24.04 -u root /etc/init.wsl start", vbhide
```

### System Cleanup and Maintenance / 系统清理和维护

#### C Drive Cleanup / C盘清理
```powershell
# Clean up Windows Update cache
# 清理Windows更新缓存
dism /online /cleanup-image /startcomponentcleanup
dism /online /cleanup-image /spsuperseded

# Clean up temporary files
# 清理临时文件
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clean up system logs
# 清理系统日志
wevtutil cl Application
wevtutil cl System
wevtutil cl Security
```

#### Multi-disk Storage Pool Configuration / 多硬盘存储池配置
```powershell
# Create a storage pool (merge multiple hard drives)
# 创建存储池（多硬盘合并）
# Settings -> System -> Storage -> Manage Storage Spaces -> Create a new pool and storage space
# 设置 -> 系统 -> 存储 -> 管理存储空间 -> 创建存储池
# Or use PowerShell:
# 或使用PowerShell：
New-StoragePool -FriendlyName "DataPool" -StorageSubsystemFriendlyName "Windows Storage*" -PhysicalDisks (Get-PhysicalDisk -CanPool $true)
```

---

## 9. WSL 完整部署流程 | 9. Complete WSL Deployment Process

本章节提供了一个从零开始部署生产级 WSL 环境的完整流程，涵盖了从安装到安全加固的各个环节。
This section provides a complete process for deploying a production-grade WSL environment from scratch, covering all aspects from installation to security hardening.

### 9.1 初始安装与配置 | 9.1 Initial Installation and Configuration

1.  **启用 WSL 和虚拟机平台功能**（参见章节 1.1）。
    **Enable WSL and Virtual Machine Platform features** (see section 1.1).
2.  **重启计算机**。
    **Restart the computer.**
3.  **安装指定的 Linux 发行版**（例如 `wsl --install -d Ubuntu-24.04`）。
    **Install the specified Linux distribution** (e.g., `wsl --install -d Ubuntu-24.04`).
4.  **创建用户并设置密码**。
    **Create user and set password.**

### 9.2 系统更新与基础工具安装 | 9.2 System Update and Basic Tools Installation

```bash
# 更新系统 | Update system
sudo apt update && sudo apt upgrade -y

# 安装常用工具 | Install common tools
sudo apt install -y curl wget git zip unzip build-essential
```

### 9.3 开发环境配置 | 9.3 Development Environment Configuration

-   根据您的需求，安装和配置开发语言环境（例如 Node.js, Python, Docker 等），具体可参考章节 6。
    Install and configure development language environments (e.g., Node.js, Python, Docker) according to your needs, refer to section 6 for details.

### 9.4 性能与资源优化 | 9.4 Performance and Resource Optimization

-   根据您的硬件和使用场景，创建并配置 `.wslconfig` 文件，以优化内存、CPU 等资源分配（参见章节 5.2）。
    Create and configure the `.wslconfig` file according to your hardware and usage scenarios to optimize resource allocation such as memory and CPU (see section 5.2).

### 9.5 安全加固 | 9.5 Security Hardening

-   **配置防火墙：** 在 WSL 内部使用 `ufw` 等工具来管理网络访问。
    **Configure firewall:** Use tools like `ufw` inside WSL to manage network access.
-   **SSH 安全设置：** 禁用 root 登录，使用密钥认证代替密码认证。
    **SSH security settings:** Disable root login, use key authentication instead of password authentication.
-   **定期安全审计：** 使用 `lynis` 或 `chkrootkit` 等工具检查系统安全状况。
    **Regular security auditing:** Use tools like `lynis` or `chkrootkit` to check system security status.

### 9.6 备份策略 | 9.6 Backup Strategy

-   设置定期任务（例如使用 Windows 任务计划程序和 `wsl --export`），自动备份您的 WSL 环境。
    Set up regular tasks (e.g., using Windows Task Scheduler and `wsl --export`) to automatically back up your WSL environment.

通过遵循以上流程，您可以构建一个稳定、高效且安全的 WSL 工作环境。
By following this process, you can build a stable, efficient, and secure WSL working environment.

### 标准部署流程（基于win10WSL运维流程.sh）| Standard Deployment Process (Based on win10WSL运维流程.sh)

#### 第一阶段：Windows部分子系统管理 | Phase 1: Windows Subsystem Management
```powershell
# 1. 开启子系统 | Enable subsystem
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 

# 2. 开启虚拟机平台 | Enable virtual machine platform
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# 3. 无法安装ubuntu的话管理员打开powershell（必要步骤）
# If unable to install Ubuntu, open PowerShell as administrator (necessary step)
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

# 4. 去Windows商店下载ubuntu，去开始菜单打开后自动安装，并配置用户名
# Go to Windows Store to download Ubuntu, open from start menu to auto-install and configure username
# 推荐：Ubuntu 24.04.1 LTS | Recommended: Ubuntu 24.04.1 LTS

# 5. 安装好以后powershell管理员权限下更改默认为wsl 1模式
# After installation, change default to WSL 1 mode in PowerShell admin
# 注意WSL1无法使用 systemd，但是win 10 + WSL2的ssh服务配置老是出错比较麻烦
# Note: WSL1 cannot use systemd, but win 10 + WSL2 SSH service configuration often has issues
# 因为WSL多出来了一个独立的虚拟机ip，没有特殊原因的话这里默认先用WSL1
# Because WSL adds an independent VM IP, use WSL1 by default without special reasons
wsl --set-default-version 1
wsl --list --verbose

# 6. 在 /etc/wsl.conf（文件不存在则创建）添加如下内容,打开 WSL 1 的systemd功能：
# Add the following content to /etc/wsl.conf (create if file doesn't exist), enable systemd for WSL 1:
sudo nano /etc/wsl.conf
[boot]
systemd=true

# 7. 重启WSL | Restart WSL
# powershell 
wsl --shutdown
wsl

# 8. 用snap测试一下 | Test with snap
snap version

# 如果要设置WSL2，则 | If setting WSL2:
wsl --set-default-version 2
wsl --list --verbose
# 直接设定特定版本ubuntu WSL2，以Ubuntu-24.04为例
# Directly set specific Ubuntu version to WSL2, example: Ubuntu-24.04
wsl --set-version Ubuntu-24.04 2
```

#### 第二阶段：基础软件安装和配置 | Phase 2: Basic Software Installation and Configuration
```bash
# 1. 更新系统 | Update system
sudo apt update
sudo apt install software-properties-common
sudo apt update

# 2. 安装ssh服务 | Install SSH service
sudo apt purge openssh-server
sudo apt install openssh-server

sudo service ssh stop
sudo service ssh start
sudo service ssh restart

# 3. 配置SSH文档 | Configure SSH config
sudo nano /etc/ssh/sshd_config
Port 22
ListenAddress 0.0.0.0
ListenAddress ::
PermitRootLogin no
PasswordAuthentication yes
Subsystem sftp internal-sftp

# 4. 重启服务 | Restart service
sudo service ssh start

# 5. 开机启动ssh | Enable SSH on boot
sudo systemctl enable ssh
```

#### 第三阶段：用户管理和权限配置 | Phase 3: User Management and Permission Configuration
```bash
# 1. 修改用户名并添加到root | Modify username and add to root
sudo adduser damncheater
sudo passwd damncheater

# 2. 如果有旧用户名可以这样操作 | If there is an old username, you can do this
sudo cp -r /home/old_username /home/damncheater
sudo deluser old_username

# 3. 添加最高权限到新用户名 | Add highest permissions to new username
sudo chown -R damncheater:damncheater /home/damncheater

# 4. 编辑配置文件 | Edit configuration file
sudo nano /etc/sudoers
# 增加配置, 在打开的配置文件中，找到root ALL=(ALL) ALL, 在下面添加一行
# Add configuration, in the opened config file, find root ALL=(ALL) ALL, add one line below
# 其中xxx是你要加入的用户名称 | where xxx is the username you want to add
damncheater ALL=(ALL) ALL

# 5. 保存退出，重启服务 | Save and exit, restart service
sudo service ssh restart
```

#### 第四阶段：网络配置和远程访问 | Phase 4: Network Configuration and Remote Access
```bash
# 1. 查看WSL内网IP | Check WSL internal IP
ip a

# 2. 选一个以太网或者无线ip到转发端口上，cmd管理员命令
# Select an ethernet or wireless IP for port forwarding, cmd admin command
netsh interface portproxy add v4tov4 listenport=2222 connectaddress=169.254.10.67 connectport=22

# 3. 这里开始就可以使用finalshell之类的进行连接了
# From here you can use finalshell or similar tools to connect
```

#### 第五阶段：配置开机自启动 | Phase 5: Configure Boot Auto-start
```bash
# 1. 这一步在WSL界面用root权限完成
# This step is completed in WSL interface with root privileges
cd /etc
sudo chmod 777 init.wsl
sudo nano /etc/init.wsl

#!/bin/sh
# 填写任意服务，rstudio-server之类的也可以
# Fill in any services, rstudio-server etc.
service ssh restart
#service rstudio-server start
#service redis-server start
#service mysql start
#service nginx start

# 2. 保存退出，设置执行权限 | Save and exit, set execution permissions
sudo chmod +x /etc/init.wsl

# 3. powershell命令，这个ubuntu版本看自己的实际版本号填写
# PowerShell command, fill in your actual Ubuntu version number
wsl -d Ubuntu-24.04 -u root /etc/init.wsl start
```

#### 第六阶段：Windows开机自启动配置 | Phase 6: Windows Boot Auto-start Configuration
```powershell
# 1. win+r: shell:startup 进入开机自启文件夹
# win+r: shell:startup to enter startup folder

# 2. 新建文件wsl2run_Ubuntu_redis.vbs（文件名自命名，扩展名是vbs就行）
# Create new file wsl2run_Ubuntu_redis.vbs (filename customizable, extension must be vbs)
# 填写注意ubuntu版本号别输错了，自己从store下载的版本是多少记住
# Note: be careful not to enter the wrong Ubuntu version number, remember what you downloaded from the store
```

```vbscript
rem Msgbox "Win10开机自动启动wsl2的Ubuntu，并由其启动redis"
Set ws = CreateObject("Wscript.Shell")
ws.run "wsl -d Ubuntu-24.04 -u root /etc/init.wsl start", vbhide
```

```powershell
# 3. 保存好以后重启一下电脑就好，后面应该可以直接从finalshell开机直连
```

### 部署验证清单 | Deployment Verification Checklist

#### 功能验证 | Function Verification
```bash
# 1. 验证WSL版本和状态 | Verify WSL version and status
wsl --list --verbose

# 2. 验证SSH服务 | Verify SSH service
sudo service ssh status

# 3. 验证用户权限 | Verify user permissions
sudo whoami

# 4. 验证网络连接 | Verify network connection
ip a
ping 8.8.8.8

# 5. 验证systemd功能（如果启用）| Verify systemd functionality (if enabled)
snap version
```

#### 远程访问验证 | Remote Access Verification
```powershell
# 1. 验证端口转发 | Verify port forwarding
netsh interface portproxy show all

# 2. 测试SSH连接 | Test SSH connection
# 使用finalshell或其他SSH客户端连接到 localhost:2222
# Use finalshell or other SSH clients to connect to localhost:2222
```

---

## 使用说明 | Usage Instructions

1. **复制粘贴使用**: 本手册中的所有命令都可以直接复制粘贴到PowerShell或WSL终端中运行
   **Copy-paste usage**: All commands in this manual can be directly copied and pasted into PowerShell or WSL terminal for execution
2. **管理员权限**: 标注需要管理员权限的命令请以管理员身份运行PowerShell
   **Administrator privileges**: Commands marked as requiring administrator privileges should be run in PowerShell as administrator
3. **备份重要**: 在执行任何重大操作前，请务必备份重要数据
   **Backup important data**: Always back up important data before performing any major operations
4. **测试环境**: 建议先在测试环境中验证命令的效果
   **Test environment**: It is recommended to verify command effects in a test environment first
5. **版本兼容**: 部分命令可能因Windows版本不同而有所差异
   **Version compatibility**: Some commands may vary due to different Windows versions
6. **权限设置**: 新系统建议先配置好各磁盘的管理员权限，避免后续权限问题
   **Permission settings**: New systems should configure administrator permissions for all disks to avoid subsequent permission issues
7. **网络配置**: 内网穿透和远程访问配置需要根据实际网络环境调整
   **Network configuration**: Intranet penetration and remote access configurations need to be adjusted according to actual network environment
8. **完整部署**: 建议按照完整部署流程章节的步骤进行标准化部署
   **Complete deployment**: It is recommended to follow the steps in the complete deployment process section for standardized deployment

## 注意事项 | Important Notes

- 执行完全卸载前请确保已备份所有重要数据
  Before performing complete uninstallation, ensure all important data has been backed up
- 某些操作需要重启计算机才能生效
  Some operations require computer restart to take effect
- 网络问题可能影响发行版的下载和安装
  Network issues may affect distribution download and installation
- 企业环境可能有额外的安全策略限制
  Enterprise environments may have additional security policy restrictions
- 权限问题是WSL使用中的常见问题，建议提前配置好相关权限
  Permission issues are common in WSL usage, it is recommended to configure relevant permissions in advance
- 使用内网穿透时注意安全性，避免暴露敏感服务
  Pay attention to security when using intranet penetration to avoid exposing sensitive services
- WSL1和WSL2在网络配置上有显著差异，选择版本时需要考虑具体使用场景
  WSL1 and WSL2 have significant differences in network configuration, consider specific usage scenarios when choosing versions
- 开机自启动脚本需要根据实际安装的Ubuntu版本号进行调整
  Boot startup scripts need to be adjusted according to the actual Ubuntu version installed

---

*最后更新: 2025年7月 | Last updated: Jupy 2025*
*整合日常问题解决方案和完整部署流程: 2025年7月 | Integrated daily problem solutions and complete deployment process: July 2025*
