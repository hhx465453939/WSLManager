# WSL功能检测模块
# WSL Functionality Detection Module

<#
.SYNOPSIS
WSL环境检测和功能验证模块

.DESCRIPTION
提供WSL环境的完整检测功能，包括Windows版本检查、WSL功能状态、Hyper-V支持和硬件虚拟化检测
#>

# 导入必要的.NET类型
Add-Type -AssemblyName System.Management

#region Windows版本和WSL支持检测

<#
.SYNOPSIS
检测Windows版本和WSL支持情况

.DESCRIPTION
检查当前Windows版本是否支持WSL，并返回详细的版本信息和支持状态

.OUTPUTS
PSCustomObject 包含Windows版本信息和WSL支持状态
#>
function Test-WindowsWSLSupport {
    [CmdletBinding()]
    param()
    
    try {
        # 获取Windows版本信息
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $buildNumber = [System.Environment]::OSVersion.Version.Build
        $version = [System.Environment]::OSVersion.Version
        
        # 检查WSL支持的最低要求
        $wslSupported = $false
        $wsl2Supported = $false
        $recommendedVersion = $false
        
        # WSL 1 最低要求: Windows 10 Build 16215
        if ($buildNumber -ge 16215) {
            $wslSupported = $true
        }
        
        # WSL 2 最低要求: Windows 10 Build 18362 (Version 1903)
        if ($buildNumber -ge 18362) {
            $wsl2Supported = $true
        }
        
        # 推荐版本: Windows 10 Build 19041 (Version 2004) 或更高
        if ($buildNumber -ge 19041) {
            $recommendedVersion = $true
        }
        
        # 检查是否为Windows 11
        $isWindows11 = $buildNumber -ge 22000
        
        $result = [PSCustomObject]@{
            OSName = $osInfo.Caption
            OSVersion = $osInfo.Version
            BuildNumber = $buildNumber
            Architecture = $osInfo.OSArchitecture
            IsWSLSupported = $wslSupported
            IsWSL2Supported = $wsl2Supported
            IsRecommendedVersion = $recommendedVersion
            IsWindows11 = $isWindows11
            SupportLevel = if ($recommendedVersion) { "Full" } elseif ($wsl2Supported) { "WSL2" } elseif ($wslSupported) { "WSL1" } else { "None" }
            Recommendations = @()
        }
        
        # 添加建议
        if (-not $wslSupported) {
            $result.Recommendations += "Need Windows 10 Build 16215+ for WSL support"
        }
        elseif (-not $wsl2Supported) {
            $result.Recommendations += "Recommend Windows 10 Build 18362+ for WSL2 support"
        }
        elseif (-not $recommendedVersion) {
            $result.Recommendations += "Recommend Windows 10 Build 19041+ for best WSL experience"
        }
        
        return $result
    }
    catch {
        Write-Error "检测Windows版本时发生错误: $($_.Exception.Message)"
        return $null
    }
}

#endregion

#region Hyper-V和WSL功能检测

<#
.SYNOPSIS
检查Hyper-V功能状态

.DESCRIPTION
检测Hyper-V平台功能是否已启用，这是WSL2运行的必要条件

.OUTPUTS
PSCustomObject 包含Hyper-V功能状态信息
#>
function Test-HyperVFeature {
    [CmdletBinding()]
    param()
    
    try {
        # 检查Hyper-V平台功能
        $hyperVPlatform = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-All" -ErrorAction SilentlyContinue
        $hyperVHypervisor = Get-WindowsOptionalFeature -Online -FeatureName "HypervisorPlatform" -ErrorAction SilentlyContinue
        $vmPlatform = Get-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -ErrorAction SilentlyContinue
        
        $result = [PSCustomObject]@{
            HyperVPlatformEnabled = ($hyperVPlatform.State -eq "Enabled")
            HyperVHypervisorEnabled = ($hyperVHypervisor.State -eq "Enabled")
            VirtualMachinePlatformEnabled = ($vmPlatform.State -eq "Enabled")
            HyperVAvailable = ($hyperVPlatform -ne $null)
            HypervisorAvailable = ($hyperVHypervisor -ne $null)
            VMPlatformAvailable = ($vmPlatform -ne $null)
            WSL2Ready = $false
            RequiredFeatures = @()
            MissingFeatures = @()
        }
        
        # 检查WSL2所需的功能
        if ($result.VirtualMachinePlatformEnabled -and ($result.HyperVHypervisorEnabled -or $result.HyperVPlatformEnabled)) {
            $result.WSL2Ready = $true
        }
        
        # 确定所需功能
        $result.RequiredFeatures = @("VirtualMachinePlatform")
        if ($result.HypervisorAvailable) {
            $result.RequiredFeatures += "HypervisorPlatform"
        }
        
        # 确定缺失功能
        if (-not $result.VirtualMachinePlatformEnabled) {
            $result.MissingFeatures += "VirtualMachinePlatform"
        }
        if ($result.HypervisorAvailable -and -not $result.HyperVHypervisorEnabled) {
            $result.MissingFeatures += "HypervisorPlatform"
        }
        
        return $result
    }
    catch {
        Write-Error "检测Hyper-V功能时发生错误: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
检查WSL功能状态

.DESCRIPTION
检测WSL相关的Windows功能是否已启用

.OUTPUTS
PSCustomObject 包含WSL功能状态信息
#>
function Test-WSLFeature {
    [CmdletBinding()]
    param()
    
    try {
        # 检查WSL功能
        $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -ErrorAction SilentlyContinue
        
        # 检查WSL是否已安装
        $wslInstalled = $false
        $wslVersion = $null
        try {
            $wslVersionOutput = wsl --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                $wslInstalled = $true
                $wslVersion = $wslVersionOutput
            }
        }
        catch {
            # WSL命令不可用
        }
        
        $result = [PSCustomObject]@{
            WSLFeatureEnabled = ($wslFeature.State -eq "Enabled")
            WSLFeatureAvailable = ($wslFeature -ne $null)
            WSLInstalled = $wslInstalled
            WSLVersion = $wslVersion
            WSLReady = ($wslFeature.State -eq "Enabled" -and $wslInstalled)
        }
        
        return $result
    }
    catch {
        Write-Error "检测WSL功能时发生错误: $($_.Exception.Message)"
        return $null
    }
}

#endregion

#region 硬件虚拟化支持检测

<#
.SYNOPSIS
检测硬件虚拟化支持

.DESCRIPTION
检查CPU是否支持硬件虚拟化技术（Intel VT-x或AMD-V），以及是否在BIOS中启用

.OUTPUTS
PSCustomObject 包含硬件虚拟化支持信息
#>
function Test-HardwareVirtualization {
    [CmdletBinding()]
    param()
    
    try {
        # 检查CPU虚拟化支持
        $processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
        
        # 检查Hyper-V要求
        $hyperVRequirements = @{
            VMMonitorModeExtensions = $false
            VirtualizationEnabledInFirmware = $false
            SecondLevelAddressTranslation = $false
            DataExecutionPreventionAvailable = $false
        }
        
        try {
            # 使用systeminfo命令获取Hyper-V要求信息
            $systemInfo = systeminfo /fo csv | ConvertFrom-Csv
            $hyperVReqs = $systemInfo | Where-Object { $_.Property -like "*Hyper-V*" }
            
            # 解析Hyper-V要求
            $hyperVSection = systeminfo | Select-String -Pattern "Hyper-V Requirements:" -Context 0,10
            if ($hyperVSection) {
                $hyperVText = $hyperVSection.Context.PostContext -join "`n"
                
                $hyperVRequirements.VMMonitorModeExtensions = $hyperVText -match "VM Monitor Mode Extensions:\s*Yes"
                $hyperVRequirements.VirtualizationEnabledInFirmware = $hyperVText -match "Virtualization Enabled In Firmware:\s*Yes"
                $hyperVRequirements.SecondLevelAddressTranslation = $hyperVText -match "Second Level Address Translation:\s*Yes"
                $hyperVRequirements.DataExecutionPreventionAvailable = $hyperVText -match "Data Execution Prevention Available:\s*Yes"
            }
        }
        catch {
            Write-Warning "无法通过systeminfo获取详细的虚拟化信息"
        }
        
        # 检查CPU特性
        $cpuFeatures = @{
            Manufacturer = $processor.Manufacturer
            Name = $processor.Name
            Architecture = $processor.Architecture
            NumberOfCores = $processor.NumberOfCores
            NumberOfLogicalProcessors = $processor.NumberOfLogicalProcessors
        }
        
        # 检查是否支持虚拟化
        $virtualizationSupported = $false
        $virtualizationEnabled = $false
        
        # Intel处理器检查VT-x
        if ($processor.Manufacturer -like "*Intel*") {
            $virtualizationSupported = $hyperVRequirements.VMMonitorModeExtensions
            $virtualizationEnabled = $hyperVRequirements.VirtualizationEnabledInFirmware
        }
        # AMD处理器检查AMD-V
        elseif ($processor.Manufacturer -like "*AMD*") {
            $virtualizationSupported = $hyperVRequirements.VMMonitorModeExtensions
            $virtualizationEnabled = $hyperVRequirements.VirtualizationEnabledInFirmware
        }
        
        $result = [PSCustomObject]@{
            CPUInfo = $cpuFeatures
            VirtualizationSupported = $virtualizationSupported
            VirtualizationEnabled = $virtualizationEnabled
            HyperVRequirements = $hyperVRequirements
            WSL2Compatible = ($virtualizationSupported -and $virtualizationEnabled -and $hyperVRequirements.SecondLevelAddressTranslation)
            Issues = @()
            Recommendations = @()
        }
        
        # Add issues and recommendations
        if (-not $virtualizationSupported) {
            $result.Issues += "CPU does not support hardware virtualization"
            $result.Recommendations += "Need CPU with Intel VT-x or AMD-V support"
        }
        elseif (-not $virtualizationEnabled) {
            $result.Issues += "Hardware virtualization not enabled in BIOS/UEFI"
            $result.Recommendations += "Enable virtualization technology in BIOS/UEFI settings"
        }
        
        if (-not $hyperVRequirements.SecondLevelAddressTranslation) {
            $result.Issues += "Missing Second Level Address Translation support"
            $result.Recommendations += "Need CPU with SLAT support"
        }
        
        if (-not $hyperVRequirements.DataExecutionPreventionAvailable) {
            $result.Issues += "Data Execution Prevention not available"
            $result.Recommendations += "Need CPU with DEP support"
        }
        
        return $result
    }
    catch {
        Write-Error "检测硬件虚拟化支持时发生错误: $($_.Exception.Message)"
        return $null
    }
}

#endregion

#region 综合检测函数

<#
.SYNOPSIS
执行完整的WSL环境检测

.DESCRIPTION
执行所有WSL相关的检测，包括Windows版本、功能状态和硬件支持

.PARAMETER Detailed
是否返回详细信息

.OUTPUTS
PSCustomObject 包含完整的WSL环境检测结果
#>
function Test-WSLEnvironment {
    [CmdletBinding()]
    param(
        [switch]$Detailed
    )
    
    Write-Host "正在检测WSL环境..." -ForegroundColor Yellow
    
    # 执行各项检测
    $windowsSupport = Test-WindowsWSLSupport
    $hyperVStatus = Test-HyperVFeature
    $wslStatus = Test-WSLFeature
    $hardwareSupport = Test-HardwareVirtualization
    
    # 综合评估
    $overallStatus = "Unknown"
    $canInstallWSL = $false
    $canInstallWSL2 = $false
    $issues = @()
    $recommendations = @()
    
    if ($windowsSupport -and $hyperVStatus -and $wslStatus -and $hardwareSupport) {
        # 评估WSL安装可能性
        $canInstallWSL = $windowsSupport.IsWSLSupported
        $canInstallWSL2 = $windowsSupport.IsWSL2Supported -and $hyperVStatus.WSL2Ready -and $hardwareSupport.WSL2Compatible
        
        # Collect issues and recommendations
        $issues += $windowsSupport.Recommendations
        $issues += $hyperVStatus.MissingFeatures | ForEach-Object { "Missing Windows feature: $_" }
        $issues += $hardwareSupport.Issues
        
        $recommendations += $windowsSupport.Recommendations
        $recommendations += $hardwareSupport.Recommendations
        if ($hyperVStatus.MissingFeatures.Count -gt 0) {
            $recommendations += "Need to enable Windows features: $($hyperVStatus.MissingFeatures -join ', ')"
        }
        
        # 确定整体状态
        if ($canInstallWSL2 -and $wslStatus.WSLReady) {
            $overallStatus = "Ready"
        }
        elseif ($canInstallWSL2) {
            $overallStatus = "WSL2Capable"
        }
        elseif ($canInstallWSL) {
            $overallStatus = "WSL1Capable"
        }
        else {
            $overallStatus = "NotSupported"
        }
    }
    
    $result = [PSCustomObject]@{
        OverallStatus = $overallStatus
        CanInstallWSL = $canInstallWSL
        CanInstallWSL2 = $canInstallWSL2
        WindowsSupport = $windowsSupport
        HyperVStatus = $hyperVStatus
        WSLStatus = $wslStatus
        HardwareSupport = $hardwareSupport
        Issues = $issues | Select-Object -Unique
        Recommendations = $recommendations | Select-Object -Unique
        Timestamp = Get-Date
    }
    
    if (-not $Detailed) {
        # 返回简化版本
        $result = [PSCustomObject]@{
            OverallStatus = $result.OverallStatus
            CanInstallWSL = $result.CanInstallWSL
            CanInstallWSL2 = $result.CanInstallWSL2
            Issues = $result.Issues
            Recommendations = $result.Recommendations
            Timestamp = $result.Timestamp
        }
    }
    
    return $result
}

<#
.SYNOPSIS
显示WSL环境检测报告

.DESCRIPTION
以友好的格式显示WSL环境检测结果

.PARAMETER DetectionResult
检测结果对象

.PARAMETER ShowDetails
是否显示详细信息
#>
function Show-WSLDetectionReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$DetectionResult,
        
        [switch]$ShowDetails
    )
    
    Write-Host "`n=== WSL环境检测报告 ===" -ForegroundColor Cyan
    Write-Host "检测时间: $($DetectionResult.Timestamp)" -ForegroundColor Gray
    
    # 显示整体状态
    $statusColor = switch ($DetectionResult.OverallStatus) {
        "Ready" { "Green" }
        "WSL2Capable" { "Yellow" }
        "WSL1Capable" { "Yellow" }
        "NotSupported" { "Red" }
        default { "Gray" }
    }
    
    $statusText = switch ($DetectionResult.OverallStatus) {
        "Ready" { "WSL Environment Ready" }
        "WSL2Capable" { "WSL2 Capable - Needs Configuration" }
        "WSL1Capable" { "WSL1 Only" }
        "NotSupported" { "WSL Not Supported" }
        default { "Status Unknown" }
    }
    
    Write-Host "`n整体状态: " -NoNewline
    Write-Host $statusText -ForegroundColor $statusColor
    
    Write-Host "WSL Support: " -NoNewline
    Write-Host $(if ($DetectionResult.CanInstallWSL) { "Yes" } else { "No" }) -ForegroundColor $(if ($DetectionResult.CanInstallWSL) { "Green" } else { "Red" })
    
    Write-Host "WSL2 Support: " -NoNewline
    Write-Host $(if ($DetectionResult.CanInstallWSL2) { "Yes" } else { "No" }) -ForegroundColor $(if ($DetectionResult.CanInstallWSL2) { "Green" } else { "Red" })
    
    # 显示问题
    if ($DetectionResult.Issues.Count -gt 0) {
        Write-Host "`n发现的问题:" -ForegroundColor Red
        $DetectionResult.Issues | ForEach-Object {
            Write-Host "  • $_" -ForegroundColor Yellow
        }
    }
    
    # 显示建议
    if ($DetectionResult.Recommendations.Count -gt 0) {
        Write-Host "`n建议操作:" -ForegroundColor Blue
        $DetectionResult.Recommendations | ForEach-Object {
            Write-Host "  • $_" -ForegroundColor Cyan
        }
    }
    
    # 显示详细信息
    if ($ShowDetails -and $DetectionResult.WindowsSupport) {
        Write-Host "`n=== 详细信息 ===" -ForegroundColor Cyan
        
        Write-Host "`nWindows信息:"
        Write-Host "  操作系统: $($DetectionResult.WindowsSupport.OSName)"
        Write-Host "  版本: $($DetectionResult.WindowsSupport.OSVersion)"
        Write-Host "  内部版本号: $($DetectionResult.WindowsSupport.BuildNumber)"
        Write-Host "  架构: $($DetectionResult.WindowsSupport.Architecture)"
        Write-Host "  支持级别: $($DetectionResult.WindowsSupport.SupportLevel)"
        
        if ($DetectionResult.HyperVStatus) {
            Write-Host "`nHyper-V Status:"
            Write-Host "  Virtual Machine Platform: $(if ($DetectionResult.HyperVStatus.VirtualMachinePlatformEnabled) { 'Enabled' } else { 'Disabled' })"
            Write-Host "  Hyper-V Hypervisor: $(if ($DetectionResult.HyperVStatus.HyperVHypervisorEnabled) { 'Enabled' } else { 'Disabled' })"
            Write-Host "  WSL2 Ready: $(if ($DetectionResult.HyperVStatus.WSL2Ready) { 'Yes' } else { 'No' })"
        }
        
        if ($DetectionResult.WSLStatus) {
            Write-Host "`nWSL Status:"
            Write-Host "  WSL Feature: $(if ($DetectionResult.WSLStatus.WSLFeatureEnabled) { 'Enabled' } else { 'Disabled' })"
            Write-Host "  WSL Installed: $(if ($DetectionResult.WSLStatus.WSLInstalled) { 'Yes' } else { 'No' })"
            if ($DetectionResult.WSLStatus.WSLVersion) {
                Write-Host "  WSL Version Info:"
                $DetectionResult.WSLStatus.WSLVersion -split "`n" | ForEach-Object {
                    if ($_.Trim()) {
                        Write-Host "    $_"
                    }
                }
            }
        }
        
        if ($DetectionResult.HardwareSupport) {
            Write-Host "`nHardware Support:"
            Write-Host "  CPU: $($DetectionResult.HardwareSupport.CPUInfo.Name)"
            Write-Host "  Manufacturer: $($DetectionResult.HardwareSupport.CPUInfo.Manufacturer)"
            Write-Host "  Virtualization Supported: $(if ($DetectionResult.HardwareSupport.VirtualizationSupported) { 'Yes' } else { 'No' })"
            Write-Host "  Virtualization Enabled: $(if ($DetectionResult.HardwareSupport.VirtualizationEnabled) { 'Yes' } else { 'No' })"
            Write-Host "  WSL2 Compatible: $(if ($DetectionResult.HardwareSupport.WSL2Compatible) { 'Yes' } else { 'No' })"
        }
    }
    
    Write-Host ""
}

#endregion

# 导出函数
Export-ModuleMember -Function @(
    'Test-WindowsWSLSupport',
    'Test-HyperVFeature', 
    'Test-WSLFeature',
    'Test-HardwareVirtualization',
    'Test-WSLEnvironment',
    'Show-WSLDetectionReport'
)