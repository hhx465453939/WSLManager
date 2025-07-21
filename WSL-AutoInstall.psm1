# WSL2自动安装模块
# WSL2 Automatic Installation Module

<#
.SYNOPSIS
WSL2自动安装和配置模块

.DESCRIPTION
提供WSL2的完整自动安装功能，包括Windows功能启用、WSL2内核安装和配置
#>

# Import required modules
Import-Module .\WSL-Detection.psm1 -Force

#region Windows功能管理

<#
.SYNOPSIS
启用WSL相关的Windows功能

.DESCRIPTION
自动启用WSL和虚拟机平台功能，这是WSL2运行的必要条件

.PARAMETER Force
强制启用功能，即使检测到可能的问题

.OUTPUTS
PSCustomObject 包含功能启用结果
#>
function Enable-WSLWindowsFeatures {
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if (-not $isAdmin) {
        throw "Administrator privileges required to enable Windows features"
    }
    
    Write-Host "Enabling WSL Windows Features..." -ForegroundColor Yellow
    
    $results = @{
        WSLFeature = $null
        VMPlatform = $null
        HyperVPlatform = $null
        Success = $false
        RequiresReboot = $false
        Errors = @()
    }
    
    try {
        # Enable WSL feature
        Write-Host "  Enabling Windows Subsystem for Linux..." -ForegroundColor Cyan
        $wslResult = Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -All -NoRestart
        $results.WSLFeature = $wslResult
        
        if ($wslResult.RestartNeeded) {
            $results.RequiresReboot = $true
        }
        
        Write-Host "  ✓ WSL feature enabled" -ForegroundColor Green
        
        # Enable Virtual Machine Platform
        Write-Host "  Enabling Virtual Machine Platform..." -ForegroundColor Cyan
        $vmResult = Enable-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -All -NoRestart
        $results.VMPlatform = $vmResult
        
        if ($vmResult.RestartNeeded) {
            $results.RequiresReboot = $true
        }
        
        Write-Host "  ✓ Virtual Machine Platform enabled" -ForegroundColor Green
        
        # Try to enable Hyper-V Platform if available (optional for WSL2)
        try {
            Write-Host "  Checking Hyper-V Platform availability..." -ForegroundColor Cyan
            $hyperVFeature = Get-WindowsOptionalFeature -Online -FeatureName "HypervisorPlatform" -ErrorAction SilentlyContinue
            
            if ($hyperVFeature -and $hyperVFeature.State -ne "Enabled") {
                Write-Host "  Enabling Hyper-V Platform..." -ForegroundColor Cyan
                $hyperVResult = Enable-WindowsOptionalFeature -Online -FeatureName "HypervisorPlatform" -All -NoRestart
                $results.HyperVPlatform = $hyperVResult
                
                if ($hyperVResult.RestartNeeded) {
                    $results.RequiresReboot = $true
                }
                
                Write-Host "  ✓ Hyper-V Platform enabled" -ForegroundColor Green
            }
            else {
                Write-Host "  ℹ Hyper-V Platform already enabled or not available" -ForegroundColor Gray
            }
        }
        catch {
            Write-Warning "Could not enable Hyper-V Platform: $($_.Exception.Message)"
            $results.Errors += "Hyper-V Platform: $($_.Exception.Message)"
        }
        
        $results.Success = $true
        
        if ($results.RequiresReboot) {
            Write-Host "`n⚠ System reboot required to complete feature installation" -ForegroundColor Yellow
            Write-Host "Please restart your computer and run the installation again" -ForegroundColor Yellow
        }
        
    }
    catch {
        $errorMsg = "Failed to enable Windows features: $($_.Exception.Message)"
        Write-Error $errorMsg
        $results.Errors += $errorMsg
        $results.Success = $false
    }
    
    return [PSCustomObject]$results
}

<#
.SYNOPSIS
检查Windows功能状态

.DESCRIPTION
检查WSL相关Windows功能的当前状态

.OUTPUTS
PSCustomObject 包含功能状态信息
#>
function Get-WSLWindowsFeatureStatus {
    [CmdletBinding()]
    param()
    
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if (-not $isAdmin) {
        Write-Warning "Administrator privileges required for complete feature status check"
        return $null
    }
    
    try {
        $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -ErrorAction SilentlyContinue
        $vmPlatform = Get-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -ErrorAction SilentlyContinue
        $hyperVPlatform = Get-WindowsOptionalFeature -Online -FeatureName "HypervisorPlatform" -ErrorAction SilentlyContinue
        
        $status = [PSCustomObject]@{
            WSLEnabled = ($wslFeature.State -eq "Enabled")
            VMPlatformEnabled = ($vmPlatform.State -eq "Enabled")
            HyperVPlatformEnabled = ($hyperVPlatform.State -eq "Enabled")
            WSLAvailable = ($wslFeature -ne $null)
            VMPlatformAvailable = ($vmPlatform -ne $null)
            HyperVPlatformAvailable = ($hyperVPlatform -ne $null)
            AllRequiredEnabled = (($wslFeature.State -eq "Enabled") -and ($vmPlatform.State -eq "Enabled"))
            Timestamp = Get-Date
        }
        
        return $status
    }
    catch {
        Write-Error "Failed to check Windows feature status: $($_.Exception.Message)"
        return $null
    }
}

#endregion

#region WSL2内核安装

<#
.SYNOPSIS
下载并安装WSL2 Linux内核更新包

.DESCRIPTION
自动下载最新的WSL2 Linux内核更新包并安装

.PARAMETER DownloadPath
内核更新包的下载路径，默认为临时目录

.PARAMETER Force
强制重新下载和安装，即使已经安装

.OUTPUTS
PSCustomObject 包含安装结果
#>
function Install-WSL2Kernel {
    [CmdletBinding()]
    param(
        [string]$DownloadPath = $env:TEMP,
        [switch]$Force
    )
    
    Write-Host "Installing WSL2 Linux Kernel..." -ForegroundColor Yellow
    
    $result = @{
        Downloaded = $false
        Installed = $false
        KernelVersion = $null
        DownloadPath = $null
        Success = $false
        Errors = @()
    }
    
    try {
        # Check if WSL2 kernel is already installed (unless Force is specified)
        if (-not $Force) {
            try {
                $wslVersion = wsl --version 2>$null
                if ($LASTEXITCODE -eq 0 -and $wslVersion -match "WSL version") {
                    Write-Host "  ℹ WSL2 kernel already installed" -ForegroundColor Gray
                    $result.Installed = $true
                    $result.Success = $true
                    $result.KernelVersion = $wslVersion
                    return [PSCustomObject]$result
                }
            }
            catch {
                # WSL not installed yet, continue with installation
            }
        }
        
        # WSL2 kernel update package URL (Microsoft official)
        $kernelUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
        $kernelFile = Join-Path $DownloadPath "wsl_update_x64.msi"
        
        # Download WSL2 kernel update
        Write-Host "  Downloading WSL2 kernel update..." -ForegroundColor Cyan
        Write-Host "  URL: $kernelUrl" -ForegroundColor Gray
        Write-Host "  Destination: $kernelFile" -ForegroundColor Gray
        
        # Use System.Net.WebClient for download with progress
        $webClient = New-Object System.Net.WebClient
        
        # Add progress handler
        $webClient.add_DownloadProgressChanged({
            param($sender, $e)
            $percent = [math]::Round(($e.BytesReceived / $e.TotalBytesToReceive) * 100, 1)
            Write-Progress -Activity "Downloading WSL2 Kernel" -Status "$percent% Complete" -PercentComplete $percent
        })
        
        try {
            $webClient.DownloadFile($kernelUrl, $kernelFile)
            Write-Progress -Activity "Downloading WSL2 Kernel" -Completed
            Write-Host "  ✓ Download completed" -ForegroundColor Green
            $result.Downloaded = $true
            $result.DownloadPath = $kernelFile
        }
        finally {
            $webClient.Dispose()
        }
        
        # Verify download
        if (-not (Test-Path $kernelFile)) {
            throw "Downloaded kernel file not found: $kernelFile"
        }
        
        $fileSize = (Get-Item $kernelFile).Length
        Write-Host "  Downloaded file size: $([math]::Round($fileSize / 1MB, 2)) MB" -ForegroundColor Gray
        
        # Install WSL2 kernel update
        Write-Host "  Installing WSL2 kernel update..." -ForegroundColor Cyan
        
        $installArgs = @(
            "/i"
            "`"$kernelFile`""
            "/quiet"
            "/norestart"
        )
        
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Host "  ✓ WSL2 kernel installed successfully" -ForegroundColor Green
            $result.Installed = $true
            
            # Verify installation
            try {
                Start-Sleep -Seconds 2
                $wslVersion = wsl --version 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $result.KernelVersion = $wslVersion
                    Write-Host "  ✓ WSL2 kernel verification successful" -ForegroundColor Green
                }
            }
            catch {
                Write-Warning "Could not verify WSL2 kernel installation"
            }
        }
        else {
            throw "WSL2 kernel installation failed with exit code: $($process.ExitCode)"
        }
        
        # Clean up downloaded file
        try {
            Remove-Item $kernelFile -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Cleanup completed" -ForegroundColor Gray
        }
        catch {
            Write-Warning "Could not clean up downloaded file: $kernelFile"
        }
        
        $result.Success = $true
        
    }
    catch {
        $errorMsg = "WSL2 kernel installation failed: $($_.Exception.Message)"
        Write-Error $errorMsg
        $result.Errors += $errorMsg
        $result.Success = $false
    }
    
    return [PSCustomObject]$result
}

#endregion

#region WSL2完整安装流程

<#
.SYNOPSIS
执行完整的WSL2安装流程

.DESCRIPTION
执行完整的WSL2安装，包括环境检测、Windows功能启用、内核安装和配置

.PARAMETER SkipRebootCheck
跳过重启检查，强制继续安装

.PARAMETER Force
强制重新安装所有组件

.OUTPUTS
PSCustomObject 包含完整安装结果
#>
function Install-WSL2Complete {
    [CmdletBinding()]
    param(
        [switch]$SkipRebootCheck,
        [switch]$Force
    )
    
    Write-Host "=== WSL2 Complete Installation ===" -ForegroundColor Green
    
    $installResult = @{
        PreCheck = $null
        FeatureInstall = $null
        KernelInstall = $null
        PostCheck = $null
        Success = $false
        RequiresReboot = $false
        Errors = @()
        Recommendations = @()
        Timestamp = Get-Date
    }
    
    try {
        # Step 1: Pre-installation check
        Write-Host "`n1. Pre-installation Environment Check" -ForegroundColor Yellow
        $preCheck = Test-WSLEnvironment -Detailed
        $installResult.PreCheck = $preCheck
        
        if (-not $preCheck.WindowsSupport.IsWSL2Supported) {
            throw "System does not support WSL2. Windows 10 Build 18362 or higher required."
        }
        
        Write-Host "  ✓ System supports WSL2" -ForegroundColor Green
        
        # Check if reboot is needed from previous installation
        if (-not $SkipRebootCheck) {
            $featureStatus = Get-WSLWindowsFeatureStatus
            if ($featureStatus -and $featureStatus.AllRequiredEnabled -and -not $Force) {
                Write-Host "  ℹ Required Windows features already enabled" -ForegroundColor Gray
            }
        }
        
        # Step 2: Enable Windows Features
        Write-Host "`n2. Enabling Windows Features" -ForegroundColor Yellow
        $featureResult = Enable-WSLWindowsFeatures -Force:$Force
        $installResult.FeatureInstall = $featureResult
        
        if (-not $featureResult.Success) {
            throw "Failed to enable required Windows features"
        }
        
        if ($featureResult.RequiresReboot) {
            $installResult.RequiresReboot = $true
            $installResult.Recommendations += "System reboot required before continuing with WSL2 kernel installation"
            
            if (-not $SkipRebootCheck) {
                Write-Host "`n⚠ REBOOT REQUIRED" -ForegroundColor Red
                Write-Host "Windows features have been enabled but require a system restart." -ForegroundColor Yellow
                Write-Host "Please restart your computer and run this installation again." -ForegroundColor Yellow
                Write-Host "Use -SkipRebootCheck parameter to continue without reboot (not recommended)" -ForegroundColor Gray
                
                $installResult.Success = $false
                return [PSCustomObject]$installResult
            }
            else {
                Write-Warning "Continuing installation without reboot (may cause issues)"
            }
        }
        
        # Step 3: Install WSL2 Kernel
        Write-Host "`n3. Installing WSL2 Kernel" -ForegroundColor Yellow
        $kernelResult = Install-WSL2Kernel -Force:$Force
        $installResult.KernelInstall = $kernelResult
        
        if (-not $kernelResult.Success) {
            $installResult.Errors += $kernelResult.Errors
            Write-Warning "WSL2 kernel installation failed, but basic WSL may still work"
        }
        
        # Step 4: Post-installation verification
        Write-Host "`n4. Post-installation Verification" -ForegroundColor Yellow
        Start-Sleep -Seconds 3  # Allow time for services to start
        
        $postCheck = Test-WSLEnvironment
        $installResult.PostCheck = $postCheck
        
        # Set WSL2 as default version
        try {
            Write-Host "  Setting WSL2 as default version..." -ForegroundColor Cyan
            $wslSetResult = wsl --set-default-version 2 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ WSL2 set as default version" -ForegroundColor Green
            }
            else {
                Write-Warning "Could not set WSL2 as default version: $wslSetResult"
                $installResult.Recommendations += "Manually set WSL2 as default: wsl --set-default-version 2"
            }
        }
        catch {
            Write-Warning "Could not set WSL2 as default version: $($_.Exception.Message)"
            $installResult.Recommendations += "Manually set WSL2 as default: wsl --set-default-version 2"
        }
        
        # Determine overall success
        $installResult.Success = $featureResult.Success -and ($kernelResult.Success -or $kernelResult.Installed)
        
        # Add recommendations
        if ($installResult.Success) {
            $installResult.Recommendations += "WSL2 installation completed successfully"
            $installResult.Recommendations += "You can now install Linux distributions from Microsoft Store"
            $installResult.Recommendations += "Or use: wsl --install -d <distribution-name>"
        }
        
    }
    catch {
        $errorMsg = "WSL2 installation failed: $($_.Exception.Message)"
        Write-Error $errorMsg
        $installResult.Errors += $errorMsg
        $installResult.Success = $false
    }
    
    return [PSCustomObject]$installResult
}

<#
.SYNOPSIS
显示WSL2安装结果报告

.DESCRIPTION
以友好的格式显示WSL2安装结果

.PARAMETER InstallResult
安装结果对象

.PARAMETER ShowDetails
是否显示详细信息
#>
function Show-WSL2InstallReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$InstallResult,
        
        [switch]$ShowDetails
    )
    
    Write-Host "`n=== WSL2 Installation Report ===" -ForegroundColor Cyan
    Write-Host "Installation Time: $($InstallResult.Timestamp)" -ForegroundColor Gray
    
    # Overall status
    $statusColor = if ($InstallResult.Success) { "Green" } else { "Red" }
    $statusText = if ($InstallResult.Success) { "SUCCESS" } else { "FAILED" }
    
    Write-Host "`nOverall Status: " -NoNewline
    Write-Host $statusText -ForegroundColor $statusColor
    
    # Reboot requirement
    if ($InstallResult.RequiresReboot) {
        Write-Host "Reboot Required: " -NoNewline
        Write-Host "YES" -ForegroundColor Yellow
    }
    
    # Installation steps
    Write-Host "`nInstallation Steps:" -ForegroundColor Cyan
    
    if ($InstallResult.FeatureInstall) {
        $featureStatus = if ($InstallResult.FeatureInstall.Success) { "OK" } else { "FAILED" }
        $featureColor = if ($InstallResult.FeatureInstall.Success) { "Green" } else { "Red" }
        Write-Host "  Windows Features: " -NoNewline
        Write-Host $featureStatus -ForegroundColor $featureColor
    }
    
    if ($InstallResult.KernelInstall) {
        $kernelStatus = if ($InstallResult.KernelInstall.Success) { "OK" } else { "FAILED" }
        $kernelColor = if ($InstallResult.KernelInstall.Success) { "Green" } else { "Red" }
        Write-Host "  WSL2 Kernel: " -NoNewline
        Write-Host $kernelStatus -ForegroundColor $kernelColor
    }
    
    # Errors
    if ($InstallResult.Errors.Count -gt 0) {
        Write-Host "`nErrors:" -ForegroundColor Red
        $InstallResult.Errors | ForEach-Object {
            Write-Host "  • $_" -ForegroundColor Yellow
        }
    }
    
    # Recommendations
    if ($InstallResult.Recommendations.Count -gt 0) {
        Write-Host "`nRecommendations:" -ForegroundColor Blue
        $InstallResult.Recommendations | ForEach-Object {
            Write-Host "  • $_" -ForegroundColor Cyan
        }
    }
    
    # Detailed information
    if ($ShowDetails) {
        Write-Host "`n=== Detailed Information ===" -ForegroundColor Cyan
        
        if ($InstallResult.PreCheck) {
            Write-Host "`nPre-installation Check:"
            Write-Host "  Windows Support: $($InstallResult.PreCheck.WindowsSupport.SupportLevel)"
            Write-Host "  Can Install WSL2: $($InstallResult.PreCheck.CanInstallWSL2)"
        }
        
        if ($InstallResult.FeatureInstall) {
            Write-Host "`nWindows Features:"
            Write-Host "  WSL Feature: $(if ($InstallResult.FeatureInstall.WSLFeature) { 'Enabled' } else { 'Failed' })"
            Write-Host "  VM Platform: $(if ($InstallResult.FeatureInstall.VMPlatform) { 'Enabled' } else { 'Failed' })"
            if ($InstallResult.FeatureInstall.HyperVPlatform) {
                Write-Host "  Hyper-V Platform: Enabled"
            }
        }
        
        if ($InstallResult.KernelInstall) {
            Write-Host "`nWSL2 Kernel:"
            Write-Host "  Downloaded: $($InstallResult.KernelInstall.Downloaded)"
            Write-Host "  Installed: $($InstallResult.KernelInstall.Installed)"
            if ($InstallResult.KernelInstall.KernelVersion) {
                Write-Host "  Version Info:"
                $InstallResult.KernelInstall.KernelVersion -split "`n" | ForEach-Object {
                    if ($_.Trim()) {
                        Write-Host "    $_"
                    }
                }
            }
        }
    }
    
    Write-Host ""
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Enable-WSLWindowsFeatures',
    'Get-WSLWindowsFeatureStatus',
    'Install-WSL2Kernel',
    'Install-WSL2Complete',
    'Show-WSL2InstallReport'
)