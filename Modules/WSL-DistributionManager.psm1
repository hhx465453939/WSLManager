# WSL Linux发行版管理模块
# WSL Linux Distribution Management Module

<#
.SYNOPSIS
WSL Linux发行版管理模块

.DESCRIPTION
提供WSL Linux发行版的完整管理功能，包括安装、配置、状态检查和用户管理
#>

#region 发行版信息和常量

# 支持的Linux发行版信息
$script:SupportedDistributions = @{
    "Ubuntu" = @{
        Name = "Ubuntu"
        StoreId = "Ubuntu"
        Command = "ubuntu"
        DefaultVersion = "22.04"
        Description = "Ubuntu Linux distribution"
        Recommended = $true
    }
    "Ubuntu-20.04" = @{
        Name = "Ubuntu 20.04 LTS"
        StoreId = "Ubuntu-20.04"
        Command = "ubuntu2004"
        DefaultVersion = "20.04"
        Description = "Ubuntu 20.04 LTS"
        Recommended = $true
    }
    "Ubuntu-22.04" = @{
        Name = "Ubuntu 22.04 LTS"
        StoreId = "Ubuntu-22.04"
        Command = "ubuntu2204"
        DefaultVersion = "22.04"
        Description = "Ubuntu 22.04 LTS"
        Recommended = $true
    }
    "Debian" = @{
        Name = "Debian GNU/Linux"
        StoreId = "Debian"
        Command = "debian"
        DefaultVersion = "latest"
        Description = "Debian GNU/Linux"
        Recommended = $true
    }
    "Alpine" = @{
        Name = "Alpine Linux"
        StoreId = "Alpine"
        Command = "alpine"
        DefaultVersion = "latest"
        Description = "Alpine Linux (lightweight)"
        Recommended = $false
    }
    "openSUSE-Leap-15.4" = @{
        Name = "openSUSE Leap 15.4"
        StoreId = "openSUSE-Leap-15.4"
        Command = "opensuse-leap-15-4"
        DefaultVersion = "15.4"
        Description = "openSUSE Leap 15.4"
        Recommended = $false
    }
}

#endregion

#region 发行版列表和状态管理

<#
.SYNOPSIS
获取已安装的WSL发行版列表

.DESCRIPTION
获取当前系统中已安装的所有WSL发行版及其状态信息

.OUTPUTS
Array of PSCustomObject 包含发行版信息
#>
function Get-WSLDistributionList {
    [CmdletBinding()]
    param()
    
    try {
        # Get WSL distribution list
        $wslListOutput = wsl --list --verbose 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "WSL command failed or no distributions installed"
            return @()
        }
        
        $distributions = @()
        $lines = $wslListOutput -split "`n" | Where-Object { $_.Trim() -ne "" }
        
        # Skip header line and process each distribution
        for ($i = 1; $i -lt $lines.Count; $i++) {
            $line = $lines[$i].Trim()
            if ($line -eq "") { continue }
            
            # Parse WSL list output format
            # Format: "  NAME                   STATE           VERSION"
            # or:     "* NAME                   STATE           VERSION" (default)
            
            $isDefault = $line.StartsWith("*")
            $cleanLine = $line -replace "^\*?\s*", ""
            
            # Split by multiple spaces to separate columns
            $parts = $cleanLine -split "\s{2,}" | Where-Object { $_.Trim() -ne "" }
            
            if ($parts.Count -ge 3) {
                $name = $parts[0].Trim()
                $state = $parts[1].Trim()
                $version = $parts[2].Trim()
                
                # Get additional information
                $distInfo = $script:SupportedDistributions[$name]
                
                $distribution = [PSCustomObject]@{
                    Name = $name
                    State = $state
                    Version = $version
                    IsDefault = $isDefault
                    IsRunning = ($state -eq "Running")
                    IsStopped = ($state -eq "Stopped")
                    Command = if ($distInfo) { $distInfo.Command } else { $name.ToLower() }
                    Description = if ($distInfo) { $distInfo.Description } else { "Unknown distribution" }
                    IsSupported = ($distInfo -ne $null)
                    InstallDate = $null
                    DiskUsage = $null
                }
                
                # Try to get additional information
                try {
                    # Get installation path and disk usage
                    $regPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
                    $lxssKeys = Get-ChildItem $regPath -ErrorAction SilentlyContinue
                    
                    foreach ($key in $lxssKeys) {
                        $distName = Get-ItemProperty $key.PSPath -Name "DistributionName" -ErrorAction SilentlyContinue
                        if ($distName -and $distName.DistributionName -eq $name) {
                            $basePath = Get-ItemProperty $key.PSPath -Name "BasePath" -ErrorAction SilentlyContinue
                            if ($basePath -and (Test-Path $basePath.BasePath)) {
                                $distribution.InstallDate = (Get-Item $basePath.BasePath).CreationTime
                                
                                # Calculate disk usage
                                $vhdxPath = Join-Path $basePath.BasePath "ext4.vhdx"
                                if (Test-Path $vhdxPath) {
                                    $fileSize = (Get-Item $vhdxPath).Length
                                    $distribution.DiskUsage = [math]::Round($fileSize / 1GB, 2)
                                }
                            }
                            break
                        }
                    }
                }
                catch {
                    # Ignore errors getting additional info
                }
                
                $distributions += $distribution
            }
        }
        
        return $distributions
    }
    catch {
        Write-Error "Failed to get WSL distribution list: $($_.Exception.Message)"
        return @()
    }
}

<#
.SYNOPSIS
获取可用的Linux发行版列表

.DESCRIPTION
获取可以安装的Linux发行版列表，包括Microsoft Store中的发行版

.OUTPUTS
Array of PSCustomObject 包含可用发行版信息
#>
function Get-AvailableDistributions {
    [CmdletBinding()]
    param()
    
    try {
        $availableDistributions = @()
        
        # Get online available distributions
        $wslListOnline = wsl --list --online 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            $lines = $wslListOnline -split "`n" | Where-Object { $_.Trim() -ne "" }
            
            # Skip header lines and process each distribution
            $startProcessing = $false
            foreach ($line in $lines) {
                $cleanLine = $line.Trim()
                
                # Look for the start of the distribution list
                if ($cleanLine -match "NAME\s+FRIENDLY NAME") {
                    $startProcessing = $true
                    continue
                }
                
                if ($startProcessing -and $cleanLine -ne "") {
                    # Parse distribution line
                    $parts = $cleanLine -split "\s{2,}" | Where-Object { $_.Trim() -ne "" }
                    
                    if ($parts.Count -ge 2) {
                        $name = $parts[0].Trim()
                        $friendlyName = $parts[1].Trim()
                        
                        $distInfo = $script:SupportedDistributions[$name]
                        
                        $distribution = [PSCustomObject]@{
                            Name = $name
                            FriendlyName = $friendlyName
                            Command = if ($distInfo) { $distInfo.Command } else { $name.ToLower() }
                            Description = if ($distInfo) { $distInfo.Description } else { $friendlyName }
                            IsRecommended = if ($distInfo) { $distInfo.Recommended } else { $false }
                            IsSupported = ($distInfo -ne $null)
                            InstallCommand = "wsl --install -d $name"
                        }
                        
                        $availableDistributions += $distribution
                    }
                }
            }
        }
        
        # If online list failed, use our predefined list
        if ($availableDistributions.Count -eq 0) {
            Write-Warning "Could not get online distribution list, using predefined list"
            
            foreach ($distKey in $script:SupportedDistributions.Keys) {
                $distInfo = $script:SupportedDistributions[$distKey]
                
                $distribution = [PSCustomObject]@{
                    Name = $distKey
                    FriendlyName = $distInfo.Name
                    Command = $distInfo.Command
                    Description = $distInfo.Description
                    IsRecommended = $distInfo.Recommended
                    IsSupported = $true
                    InstallCommand = "wsl --install -d $distKey"
                }
                
                $availableDistributions += $distribution
            }
        }
        
        return $availableDistributions | Sort-Object @{Expression={$_.IsRecommended}; Descending=$true}, Name
    }
    catch {
        Write-Error "Failed to get available distributions: $($_.Exception.Message)"
        return @()
    }
}

<#
.SYNOPSIS
获取WSL发行版的详细状态

.DESCRIPTION
获取指定WSL发行版的详细状态信息

.PARAMETER DistributionName
发行版名称

.OUTPUTS
PSCustomObject 包含详细状态信息
#>
function Get-WSLDistributionStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName
    )
    
    try {
        $distributions = Get-WSLDistributionList
        $distribution = $distributions | Where-Object { $_.Name -eq $DistributionName }
        
        if (-not $distribution) {
            throw "Distribution '$DistributionName' not found"
        }
        
        # Get additional status information
        $status = [PSCustomObject]@{
            Name = $distribution.Name
            State = $distribution.State
            Version = $distribution.Version
            IsDefault = $distribution.IsDefault
            IsRunning = $distribution.IsRunning
            Command = $distribution.Command
            Description = $distribution.Description
            InstallDate = $distribution.InstallDate
            DiskUsage = $distribution.DiskUsage
            NetworkInfo = $null
            ProcessCount = 0
            MemoryUsage = 0
            LastAccessed = $null
        }
        
        # Get network information if running
        if ($distribution.IsRunning) {
            try {
                $ipAddress = wsl -d $DistributionName hostname -I 2>$null
                if ($LASTEXITCODE -eq 0 -and $ipAddress) {
                    $status.NetworkInfo = @{
                        IPAddress = $ipAddress.Trim()
                        Hostname = (wsl -d $DistributionName hostname 2>$null).Trim()
                    }
                }
            }
            catch {
                # Ignore network info errors
            }
            
            # Get process count
            try {
                $processCount = wsl -d $DistributionName ps aux 2>$null | Measure-Object | Select-Object -ExpandProperty Count
                if ($processCount -gt 1) { # Subtract header line
                    $status.ProcessCount = $processCount - 1
                }
            }
            catch {
                # Ignore process count errors
            }
        }
        
        return $status
    }
    catch {
        Write-Error "Failed to get distribution status: $($_.Exception.Message)"
        return $null
    }
}

#endregion

#region 发行版安装和配置

<#
.SYNOPSIS
安装Linux发行版

.DESCRIPTION
安装指定的Linux发行版到WSL

.PARAMETER DistributionName
要安装的发行版名称

.PARAMETER SetAsDefault
安装后设置为默认发行版

.PARAMETER CreateUser
是否创建用户账户

.PARAMETER Username
用户名（如果CreateUser为true）

.OUTPUTS
PSCustomObject 包含安装结果
#>
function Install-WSLDistribution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        
        [switch]$SetAsDefault,
        
        [switch]$CreateUser,
        
        [string]$Username = $env:USERNAME
    )
    
    Write-Host "Installing WSL Distribution: $DistributionName" -ForegroundColor Yellow
    
    $result = @{
        DistributionName = $DistributionName
        InstallStarted = $false
        InstallCompleted = $false
        UserCreated = $false
        SetAsDefault = $false
        Success = $false
        Errors = @()
        InstallTime = $null
        FinalStatus = $null
    }
    
    try {
        # Check if distribution is already installed
        $existingDist = Get-WSLDistributionList | Where-Object { $_.Name -eq $DistributionName }
        if ($existingDist) {
            Write-Host "  ℹ Distribution '$DistributionName' is already installed" -ForegroundColor Gray
            $result.InstallCompleted = $true
            $result.Success = $true
            $result.FinalStatus = Get-WSLDistributionStatus -DistributionName $DistributionName
            return [PSCustomObject]$result
        }
        
        # Check if distribution is available
        $availableDist = Get-AvailableDistributions | Where-Object { $_.Name -eq $DistributionName }
        if (-not $availableDist) {
            throw "Distribution '$DistributionName' is not available for installation"
        }
        
        Write-Host "  Installing distribution..." -ForegroundColor Cyan
        $startTime = Get-Date
        
        # Install the distribution
        $installOutput = wsl --install -d $DistributionName 2>&1
        $result.InstallStarted = $true
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Distribution installation initiated" -ForegroundColor Green
            
            # Wait for installation to complete
            Write-Host "  Waiting for installation to complete..." -ForegroundColor Cyan
            $timeout = 300 # 5 minutes timeout
            $elapsed = 0
            $installed = $false
            
            while ($elapsed -lt $timeout -and -not $installed) {
                Start-Sleep -Seconds 5
                $elapsed += 5
                
                $currentDist = Get-WSLDistributionList | Where-Object { $_.Name -eq $DistributionName }
                if ($currentDist) {
                    $installed = $true
                    Write-Host "  ✓ Distribution installation completed" -ForegroundColor Green
                    $result.InstallCompleted = $true
                }
                else {
                    Write-Host "  ⏳ Still installing... ($elapsed/$timeout seconds)" -ForegroundColor Gray
                }
            }
            
            if (-not $installed) {
                throw "Installation timeout after $timeout seconds"
            }
        }
        else {
            throw "Distribution installation failed: $installOutput"
        }
        
        $endTime = Get-Date
        $result.InstallTime = $endTime - $startTime
        
        # Set as default if requested
        if ($SetAsDefault) {
            Write-Host "  Setting as default distribution..." -ForegroundColor Cyan
            $defaultResult = wsl --set-default $DistributionName 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ Set as default distribution" -ForegroundColor Green
                $result.SetAsDefault = $true
            }
            else {
                Write-Warning "Could not set as default: $defaultResult"
                $result.Errors += "Failed to set as default: $defaultResult"
            }
        }
        
        # Create user if requested
        if ($CreateUser -and $Username) {
            Write-Host "  Configuring user account..." -ForegroundColor Cyan
            
            try {
                # Try to create user (this may require interactive input)
                $userResult = wsl -d $DistributionName -- bash -c "id $Username" 2>$null
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "  Creating user account: $Username" -ForegroundColor Cyan
                    Write-Host "  Note: You may be prompted to set a password" -ForegroundColor Yellow
                    
                    # This will likely require interactive input
                    wsl -d $DistributionName -- bash -c "sudo useradd -m -s /bin/bash $Username && sudo passwd $Username"
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  ✓ User account created" -ForegroundColor Green
                        $result.UserCreated = $true
                    }
                    else {
                        Write-Warning "User creation may have failed or requires manual completion"
                    }
                }
                else {
                    Write-Host "  ℹ User '$Username' already exists" -ForegroundColor Gray
                    $result.UserCreated = $true
                }
            }
            catch {
                Write-Warning "User configuration failed: $($_.Exception.Message)"
                $result.Errors += "User configuration failed: $($_.Exception.Message)"
            }
        }
        
        # Get final status
        $result.FinalStatus = Get-WSLDistributionStatus -DistributionName $DistributionName
        $result.Success = $true
        
        Write-Host "  ✓ Distribution installation completed successfully" -ForegroundColor Green
        
    }
    catch {
        $errorMsg = "Distribution installation failed: $($_.Exception.Message)"
        Write-Error $errorMsg
        $result.Errors += $errorMsg
        $result.Success = $false
    }
    
    return [PSCustomObject]$result
}

<#
.SYNOPSIS
配置WSL发行版

.DESCRIPTION
配置已安装的WSL发行版，包括基础设置和软件包

.PARAMETER DistributionName
发行版名称

.PARAMETER InstallBasicTools
是否安装基础工具

.PARAMETER UpdatePackages
是否更新软件包

.OUTPUTS
PSCustomObject 包含配置结果
#>
function Set-WSLDistributionConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        
        [switch]$InstallBasicTools,
        
        [switch]$UpdatePackages
    )
    
    Write-Host "Configuring WSL Distribution: $DistributionName" -ForegroundColor Yellow
    
    $result = @{
        DistributionName = $DistributionName
        PackagesUpdated = $false
        BasicToolsInstalled = $false
        Success = $false
        Errors = @()
        ConfigurationTime = $null
    }
    
    try {
        # Check if distribution exists
        $distribution = Get-WSLDistributionList | Where-Object { $_.Name -eq $DistributionName }
        if (-not $distribution) {
            throw "Distribution '$DistributionName' not found"
        }
        
        $startTime = Get-Date
        
        # Update packages if requested
        if ($UpdatePackages) {
            Write-Host "  Updating package lists..." -ForegroundColor Cyan
            
            # Detect distribution type and use appropriate package manager
            $distType = "unknown"
            if ($DistributionName -match "Ubuntu|Debian") {
                $distType = "debian"
            }
            elseif ($DistributionName -match "Alpine") {
                $distType = "alpine"
            }
            elseif ($DistributionName -match "openSUSE") {
                $distType = "opensuse"
            }
            
            switch ($distType) {
                "debian" {
                    $updateResult = wsl -d $DistributionName -- bash -c "sudo apt update && sudo apt upgrade -y" 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  ✓ Packages updated (apt)" -ForegroundColor Green
                        $result.PackagesUpdated = $true
                    }
                    else {
                        Write-Warning "Package update failed: $updateResult"
                        $result.Errors += "Package update failed: $updateResult"
                    }
                }
                "alpine" {
                    $updateResult = wsl -d $DistributionName -- sh -c "apk update && apk upgrade" 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  ✓ Packages updated (apk)" -ForegroundColor Green
                        $result.PackagesUpdated = $true
                    }
                    else {
                        Write-Warning "Package update failed: $updateResult"
                        $result.Errors += "Package update failed: $updateResult"
                    }
                }
                "opensuse" {
                    $updateResult = wsl -d $DistributionName -- bash -c "sudo zypper refresh && sudo zypper update -y" 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  ✓ Packages updated (zypper)" -ForegroundColor Green
                        $result.PackagesUpdated = $true
                    }
                    else {
                        Write-Warning "Package update failed: $updateResult"
                        $result.Errors += "Package update failed: $updateResult"
                    }
                }
                default {
                    Write-Warning "Unknown distribution type, skipping package update"
                }
            }
        }
        
        # Install basic tools if requested
        if ($InstallBasicTools) {
            Write-Host "  Installing basic development tools..." -ForegroundColor Cyan
            
            $basicTools = @("curl", "wget", "git", "vim", "nano", "htop", "unzip")
            
            switch ($distType) {
                "debian" {
                    $toolsCmd = "sudo apt install -y " + ($basicTools -join " ")
                    $toolsResult = wsl -d $DistributionName -- bash -c $toolsCmd 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  ✓ Basic tools installed" -ForegroundColor Green
                        $result.BasicToolsInstalled = $true
                    }
                    else {
                        Write-Warning "Basic tools installation failed: $toolsResult"
                        $result.Errors += "Basic tools installation failed: $toolsResult"
                    }
                }
                "alpine" {
                    $toolsCmd = "apk add " + ($basicTools -join " ")
                    $toolsResult = wsl -d $DistributionName -- sh -c $toolsCmd 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  ✓ Basic tools installed" -ForegroundColor Green
                        $result.BasicToolsInstalled = $true
                    }
                    else {
                        Write-Warning "Basic tools installation failed: $toolsResult"
                        $result.Errors += "Basic tools installation failed: $toolsResult"
                    }
                }
                "opensuse" {
                    $toolsCmd = "sudo zypper install -y " + ($basicTools -join " ")
                    $toolsResult = wsl -d $DistributionName -- bash -c $toolsCmd 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  ✓ Basic tools installed" -ForegroundColor Green
                        $result.BasicToolsInstalled = $true
                    }
                    else {
                        Write-Warning "Basic tools installation failed: $toolsResult"
                        $result.Errors += "Basic tools installation failed: $toolsResult"
                    }
                }
                default {
                    Write-Warning "Unknown distribution type, skipping basic tools installation"
                }
            }
        }
        
        $endTime = Get-Date
        $result.ConfigurationTime = $endTime - $startTime
        $result.Success = $true
        
        Write-Host "  ✓ Distribution configuration completed" -ForegroundColor Green
        
    }
    catch {
        $errorMsg = "Distribution configuration failed: $($_.Exception.Message)"
        Write-Error $errorMsg
        $result.Errors += $errorMsg
        $result.Success = $false
    }
    
    return [PSCustomObject]$result
}

#endregion

#region 发行版控制操作

<#
.SYNOPSIS
启动WSL发行版

.DESCRIPTION
启动指定的WSL发行版

.PARAMETER DistributionName
发行版名称

.OUTPUTS
Boolean 启动是否成功
#>
function Start-WSLDistribution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName
    )
    
    try {
        Write-Host "Starting WSL Distribution: $DistributionName" -ForegroundColor Yellow
        
        # Check if already running
        $status = Get-WSLDistributionStatus -DistributionName $DistributionName
        if ($status -and $status.IsRunning) {
            Write-Host "  ℹ Distribution is already running" -ForegroundColor Gray
            return $true
        }
        
        # Start the distribution
        $startResult = wsl -d $DistributionName -- echo "Distribution started" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Distribution started successfully" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Failed to start distribution: $startResult"
            return $false
        }
    }
    catch {
        Write-Error "Failed to start distribution: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
停止WSL发行版

.DESCRIPTION
停止指定的WSL发行版

.PARAMETER DistributionName
发行版名称

.PARAMETER Force
强制停止

.OUTPUTS
Boolean 停止是否成功
#>
function Stop-WSLDistribution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        
        [switch]$Force
    )
    
    try {
        Write-Host "Stopping WSL Distribution: $DistributionName" -ForegroundColor Yellow
        
        # Check if already stopped
        $status = Get-WSLDistributionStatus -DistributionName $DistributionName
        if ($status -and $status.IsStopped) {
            Write-Host "  ℹ Distribution is already stopped" -ForegroundColor Gray
            return $true
        }
        
        # Stop the distribution
        if ($Force) {
            $stopResult = wsl --terminate $DistributionName 2>&1
        }
        else {
            $stopResult = wsl -d $DistributionName -- sudo shutdown -h now 2>&1
            Start-Sleep -Seconds 3
            
            # If graceful shutdown didn't work, force terminate
            $status = Get-WSLDistributionStatus -DistributionName $DistributionName
            if ($status -and $status.IsRunning) {
                $stopResult = wsl --terminate $DistributionName 2>&1
            }
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Distribution stopped successfully" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Failed to stop distribution: $stopResult"
            return $false
        }
    }
    catch {
        Write-Error "Failed to stop distribution: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
重启WSL发行版

.DESCRIPTION
重启指定的WSL发行版

.PARAMETER DistributionName
发行版名称

.OUTPUTS
Boolean 重启是否成功
#>
function Restart-WSLDistribution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName
    )
    
    try {
        Write-Host "Restarting WSL Distribution: $DistributionName" -ForegroundColor Yellow
        
        # Stop the distribution
        $stopResult = Stop-WSLDistribution -DistributionName $DistributionName -Force
        
        if ($stopResult) {
            Start-Sleep -Seconds 2
            
            # Start the distribution
            $startResult = Start-WSLDistribution -DistributionName $DistributionName
            
            if ($startResult) {
                Write-Host "  ✓ Distribution restarted successfully" -ForegroundColor Green
                return $true
            }
        }
        
        Write-Error "Failed to restart distribution"
        return $false
    }
    catch {
        Write-Error "Failed to restart distribution: $($_.Exception.Message)"
        return $false
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Get-WSLDistributionList',
    'Get-AvailableDistributions',
    'Get-WSLDistributionStatus',
    'Install-WSLDistribution',
    'Set-WSLDistributionConfiguration',
    'Start-WSLDistribution',
    'Stop-WSLDistribution',
    'Restart-WSLDistribution'
)