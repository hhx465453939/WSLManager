# WSL Manager - WSL 运维管理脚本和工具集

欢迎使用 WSL Manager！这是一个旨在简化和自动化 Windows Subsystem for Linux (WSL) 日常运维任务的 PowerShell 脚本和工具集合。无论您是 WSL 的新手还是资深用户，这套工具都能帮助您更高效地管理您的 WSL 环境。

## 功能特性

- **自动化安装与配置：** 一键完成 WSL 环境的检测、安装和基础配置。
- **健康监控与诊断：** 实时监控 WSL 资源使用情况，并提供强大的诊断引擎，自动检测和修复常见问题。
- **备份与恢复：** 轻松备份和恢复您的 WSL 发行版，保障数据安全。
- **性能优化：** 提供多种性能预设，一键优化 WSL 资源配置，适应不同工作负载。
- **统一命令行接口：** 通过 `WSL-CLI` 模块，提供统一的入口来调用所有管理功能。
- **安全管理：** 辅助管理 WSL 中的用户和文件权限，提升环境安全性。

## 文件结构

```
/WSLManager
|-- Modules/                  # 核心功能模块
|   |-- WSL-AutoInstall.psm1
|   |-- WSL-BackupManager.psm1
|   |-- WSL-CLI.psm1
|   |-- ... (其他模块)
|-- Scripts/                  # 示例和测试脚本
|   |-- Install.ps1
|   |-- ... (其他脚本)
|-- WSL运维操作手册.md        # 详细的用户操作手册
|-- README.md                 # 项目介绍
```

## 快速开始

1.  **安装：**

    以管理员权限运行 PowerShell，并执行以下命令：

    ```powershell
    # 允许执行本地脚本
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

    # 运行安装脚本
    .\Scripts\Install.ps1
    ```

2.  **使用命令行工具：**

    安装完成后，您可以在 PowerShell 中导入 `WSL-CLI` 模块来使用所有功能：

    ```powershell
    Import-Module .\Modules\WSL-CLI.psm1

    # 查看可用命令
    Get-Command -Module WSL-CLI

    # 示例：运行健康检查
    Get-WSLHealthStatus

    # 示例：备份一个发行版
    Backup-WSLDistribution -Name Ubuntu-24.04
    ```

## 文档

我们提供了非常详细的 **[WSL运维操作手册.md](./WSL运维操作手册.md)**，其中包含了每个功能的详细用法、示例和最佳实践。强烈建议您在使用前仔细阅读该手册。

## 贡献

欢迎任何形式的贡献！如果您有任何建议或发现了 Bug，请随时提交 Issue 或 Pull Request。

## 许可

本项目采用 MIT 许可证。