# WSL Manager - WSL Operations and Management Scripts and Toolset

Welcome to WSL Manager! This is a collection of PowerShell scripts and tools designed to simplify and automate the daily operational tasks of the Windows Subsystem for Linux (WSL). Whether you are a novice or an experienced user of WSL, this toolset will help you manage your WSL environment more efficiently.

---

# WSL Manager - WSL 运维管理脚本和工具集

欢迎使用 WSL Manager！这是一个旨在简化和自动化 Windows Subsystem for Linux (WSL) 日常运维任务的 PowerShell 脚本和工具集合。无论您是 WSL 的新手还是资深用户，这套工具都能帮助您更高效地管理您的 WSL 环境。哥们WSL最近老出问题，一怒之下怒了一下写了个运维手册，顺便测试一下AI编程，有啥问题欢迎联系。

## Features / 功能特性

- **Automated Installation and Configuration:** One-click detection, installation, and basic configuration of the WSL environment.
- **Health Monitoring and Diagnostics:** Real-time monitoring of WSL resource usage with a powerful diagnostic engine to automatically detect and fix common issues.
- **Backup and Recovery:** Easily back up and restore your WSL distributions to ensure data safety.
- **Performance Optimization:** Provides multiple performance presets to optimize WSL resource configuration with a single click, adapting to different workloads.
- **Unified Command-Line Interface:** A unified entry point to all management functions through the `WSL-CLI` module.
- **Security Management:** Assists in managing user and file permissions within WSL to enhance environment security.

---

- **自动化安装与配置：** 一键完成 WSL 环境的检测、安装和基础配置。
- **健康监控与诊断：** 实时监控 WSL 资源使用情况，并提供强大的诊断引擎，自动检测和修复常见问题。
- **备份与恢复：** 轻松备份和恢复您的 WSL 发行版，保障数据安全。
- **性能优化：** 提供多种性能预设，一键优化 WSL 资源配置，适应不同工作负载。
- **统一命令行接口：** 通过 `WSL-CLI` 模块，提供统一的入口来调用所有管理功能。
- **安全管理：** 辅助管理 WSL 中的用户和文件权限，提升环境安全性。

## File Structure / 文件结构

```
/WSLManager
|-- Modules/                  # Core functional modules / 核心功能模块
|   |-- WSL-AutoInstall.psm1
|   |-- WSL-BackupManager.psm1
|   |-- WSL-CLI.psm1
|   |-- ... (Other modules / 其他模块)
|-- Scripts/                  # Example and test scripts / 示例和测试脚本
|   |-- Install.ps1
|   |-- ... (Other scripts / 其他脚本)
|-- WSL运维操作手册.md        # Detailed user operation manual / 详细的用户操作手册
|-- README.md                 # Project introduction / 项目介绍
```

## Quick Start / 快速开始

1.  **Installation / 安装：**

    Run PowerShell as an administrator and execute the following commands:

    ```powershell
    # Allow execution of local scripts
    # 允许执行本地脚本
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

    # Run the installation script
    # 运行安装脚本
    .\Scripts\Install.ps1
    ```

2.  **Using the Command-Line Tool / 使用命令行工具：**

    After installation, you can import the `WSL-CLI` module in PowerShell to use all functions:

    ```powershell
    # Import the WSL-CLI module
    # 导入 WSL-CLI 模块
    Import-Module .\Modules\WSL-CLI.psm1

    # View available commands
    # 查看可用命令
    Get-Command -Module WSL-CLI

    # Example: Run a health check
    # 示例：运行健康检查
    Get-WSLHealthStatus

    # Example: Back up a distribution
    # 示例：备份一个发行版
    Backup-WSLDistribution -Name Ubuntu-24.04
    ```

## Documentation / 文档

We provide a very detailed **[WSL Operations Manual.md](./WSL运维操作手册.md)**, which contains detailed usage, examples, and best practices for each function. It is highly recommended that you read this manual carefully before use.

---

我们提供了非常详细的 **[WSL运维操作手册.md](./WSL运维操作手册.md)**，其中包含了每个功能的详细用法、示例和最佳实践。强烈建议您在使用前仔细阅读该手册。

## Contributing / 贡献

Contributions of any kind are welcome! If you have any suggestions or find a bug, please feel free to submit an Issue or Pull Request.

---

欢迎任何形式的贡献！如果您有任何建议或发现了 Bug，请随时提交 Issue 或 Pull Request。

## License / 许可

This project is licensed under the MIT License.

---

本项目采用 MIT 许可证。