# WSL Configuration Management Module
# Provides WSL configuration file generation, validation and management functionality

Set-StrictMode -Version Latest

# Configuration file path constants
$script:WSLConfigPath = "$env:USERPROFILE\.wslconfig"
$script:ConfigTemplatesPath = "$PSScriptRoot\config-templates"
$script:ConfigBackupPath = "$PSScriptRoot\config-backups"

# Performance optimization presets
$script:PerformancePresets = @{
    "low-resource" = @{
        memory = "2GB"
        processors = 1
        swap = "512MB"
        autoMemoryReclaim = "gradual"
        sparseVhd = $true
    }
    "balanced" = @{
        memory = "4GB"
        processors = 2
        swap = "1GB"
        autoMemoryReclaim = "gradual"
        sparseVhd = $true
    }
    "high-performance" = @{
        memory = "8GB"
        processors = 4
        swap = "2GB"
        autoMemoryReclaim = "disabled"
        sparseVhd = $false
    }
    "development" = @{
        memory = "6GB"
        processors = 4
        swap = "1GB"
        localhostForwarding = $true
        guiApplications = $true
        autoMemoryReclaim = "gradual"
    }
}

# Helper functions
function Test-MemoryFormat {
    param([string]$Memory)
    return $Memory -match '^\d+(\.\d+)?(GB|MB|KB)$'
}

function Test-WSLConfigData {
    param([hashtable]$ConfigData)
    
    $result = @{
        IsValid = $true
        Errors = @()
    }
    
    if ($ConfigData.ContainsKey('wsl2')) {
        $wsl2 = $ConfigData.wsl2
        
        if ($wsl2.ContainsKey('memory') -and -not (Test-MemoryFormat $wsl2.memory)) {
            $result.Errors += "Invalid memory format"
            $result.IsValid = $false
        }
        
        if ($wsl2.ContainsKey('swap') -and -not (Test-MemoryFormat $wsl2.swap)) {
            $result.Errors += "Invalid swap format"
            $result.IsValid = $false
        }
    }
    
    return $result
}

function ConvertTo-WSLConfigFormat {
    param([hashtable]$ConfigData)
    
    $output = @()
    
    foreach ($section in $ConfigData.Keys) {
        $output += "[$section]"
        
        foreach ($key in $ConfigData[$section].Keys) {
            $value = $ConfigData[$section][$key]
            if ($value -is [bool]) {
                $value = $value.ToString().ToLower()
            }
            $output += "$key=$value"
        }
        $output += ""
    }
    
    return $output -join "`n"
}

function Invoke-WSLConfigApply {
    try {
        wsl --shutdown
        Start-Sleep -Seconds 3
        Restart-Service LxssManager -Force
        Start-Sleep -Seconds 2
        return @{ Success = $true }
    }
    catch {
        return @{ 
            Success = $false
            Error = $_.Exception.Message 
        }
    }
}

function New-WSLConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ConfigData,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = $script:WSLConfigPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Backup
    )
    
    try {
        Write-Host "Generating WSL configuration file..." -ForegroundColor Yellow
        
        if ($Backup -and (Test-Path $OutputPath)) {
            Backup-WSLConfig -ConfigPath $OutputPath
        }
        
        $validationResult = Test-WSLConfigData -ConfigData $ConfigData
        if (-not $validationResult.IsValid) {
            throw "Configuration validation failed: $($validationResult.Errors -join ', ')"
        }
        
        $configContent = ConvertTo-WSLConfigFormat -ConfigData $ConfigData
        
        $configDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $configContent | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
        
        Write-Host "WSL configuration file generated: $OutputPath" -ForegroundColor Green
        
        $verification = Test-WSLConfig -ConfigPath $OutputPath
        if ($verification.IsValid) {
            Write-Host "Configuration file validation passed" -ForegroundColor Green
        } else {
            Write-Warning "Configuration file validation failed: $($verification.Errors -join ', ')"
        }
        
        return @{
            Success = $true
            ConfigPath = $OutputPath
            Validation = $verification
        }
    }
    catch {
        Write-Error "Failed to generate WSL configuration file: $($_.Exception.Message)"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-WSLConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:WSLConfigPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConfigData
    )
    
    $result = @{
        IsValid = $true
        Errors = @()
        Warnings = @()
    }
    
    try {
        if ($ConfigData) {
            $configToValidate = $ConfigData
        } elseif (Test-Path $ConfigPath) {
            $configToValidate = Get-WSLConfig -ConfigPath $ConfigPath
        } else {
            $result.IsValid = $false
            $result.Errors += "Configuration file does not exist: $ConfigPath"
            return $result
        }
        
        if ($configToValidate.ContainsKey('wsl2')) {
            $wsl2Config = $configToValidate.wsl2
            
            if ($wsl2Config.ContainsKey('memory')) {
                if (-not (Test-MemoryFormat -Memory $wsl2Config.memory)) {
                    $result.Errors += "Invalid memory format: $($wsl2Config.memory)"
                    $result.IsValid = $false
                }
            }
            
            if ($wsl2Config.ContainsKey('processors')) {
                $maxProcessors = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
                if ($wsl2Config.processors -gt $maxProcessors) {
                    $result.Warnings += "Processor count ($($wsl2Config.processors)) exceeds system maximum ($maxProcessors)"
                }
            }
            
            if ($wsl2Config.ContainsKey('swap')) {
                if (-not (Test-MemoryFormat -Memory $wsl2Config.swap)) {
                    $result.Errors += "Invalid swap file size format: $($wsl2Config.swap)"
                    $result.IsValid = $false
                }
            }
            
            if ($wsl2Config.ContainsKey('swapFile')) {
                $swapDir = Split-Path $wsl2Config.swapFile -Parent
                if (-not (Test-Path $swapDir)) {
                    $result.Warnings += "Swap file directory does not exist: $swapDir"
                }
            }
        }
        
        Write-Host "WSL configuration validation completed" -ForegroundColor Green
        if ($result.Warnings.Count -gt 0) {
            Write-Warning "Found $($result.Warnings.Count) warnings"
            $result.Warnings | ForEach-Object { Write-Warning $_ }
        }
        
        return $result
    }
    catch {
        $result.IsValid = $false
        $result.Errors += "Configuration validation exception: $($_.Exception.Message)"
        return $result
    }
}

function Get-WSLConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:WSLConfigPath
    )
    
    try {
        if (-not (Test-Path $ConfigPath)) {
            Write-Warning "Configuration file does not exist: $ConfigPath"
            return $null
        }
        
        $configContent = Get-Content $ConfigPath -Raw
        $config = @{}
        $currentSection = $null
        
        $configContent -split "`n" | ForEach-Object {
            $line = $_.Trim()
            
            if ($line -eq "" -or $line.StartsWith("#") -or $line.StartsWith(";")) {
                return
            }
            
            if ($line -match '^\[(.+)\]$') {
                $currentSection = $matches[1]
                $config[$currentSection] = @{}
                return
            }
            
            if ($line -match '^(.+?)=(.+)$' -and $currentSection) {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                
                if ($value -eq "true") { $value = $true }
                elseif ($value -eq "false") { $value = $false }
                elseif ($value -match '^\d+$') { $value = [int]$value }
                
                $config[$currentSection][$key] = $value
            }
        }
        
        return $config
    }
    catch {
        Write-Error "Failed to read WSL configuration: $($_.Exception.Message)"
        return $null
    }
}

function Set-WSLConfigParameter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Section,
        
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $true)]
        $Value,
        
        [Parameter(Mandatory = $false)]
        [switch]$Apply
    )
    
    try {
        Write-Host "Setting WSL configuration parameter: [$Section] $Key = $Value" -ForegroundColor Yellow
        
        $config = Get-WSLConfig
        if (-not $config) {
            $config = @{}
        }
        
        if (-not $config.ContainsKey($Section)) {
            $config[$Section] = @{}
        }
        
        $config[$Section][$Key] = $Value
        
        $validation = Test-WSLConfigData -ConfigData $config
        if (-not $validation.IsValid) {
            throw "Configuration validation failed: $($validation.Errors -join ', ')"
        }
        
        $result = New-WSLConfig -ConfigData $config -Backup
        
        if ($result.Success) {
            Write-Host "Configuration parameter set successfully" -ForegroundColor Green
            
            if ($Apply) {
                Write-Host "Applying configuration..." -ForegroundColor Yellow
                $applyResult = Invoke-WSLConfigApply
                if ($applyResult.Success) {
                    Write-Host "Configuration applied successfully" -ForegroundColor Green
                } else {
                    Write-Warning "Configuration application failed: $($applyResult.Error)"
                }
            } else {
                Write-Host "Configuration saved, WSL restart required to apply changes" -ForegroundColor Cyan
            }
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to set WSL configuration parameter: $($_.Exception.Message)"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Set-WSLConfigPreset {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("low-resource", "balanced", "high-performance", "development")]
        [string]$PresetName,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$CustomConfig = @{},
        
        [Parameter(Mandatory = $false)]
        [switch]$Apply
    )
    
    try {
        Write-Host "Applying WSL configuration preset: $PresetName" -ForegroundColor Yellow
        
        $presetConfig = $script:PerformancePresets[$PresetName].Clone()
        
        foreach ($key in $CustomConfig.Keys) {
            $presetConfig[$key] = $CustomConfig[$key]
        }
        
        $fullConfig = @{
            wsl2 = $presetConfig
        }
        
        $result = New-WSLConfig -ConfigData $fullConfig -Backup
        
        if ($result.Success) {
            Write-Host "Configuration preset applied successfully: $PresetName" -ForegroundColor Green
            
            if ($Apply) {
                Write-Host "Restarting WSL to apply configuration..." -ForegroundColor Yellow
                $applyResult = Invoke-WSLConfigApply
                if ($applyResult.Success) {
                    Write-Host "Configuration applied successfully" -ForegroundColor Green
                } else {
                    Write-Warning "Configuration application failed: $($applyResult.Error)"
                }
            }
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to apply WSL configuration preset: $($_.Exception.Message)"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Backup-WSLConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:WSLConfigPath,
        
        [Parameter(Mandatory = $false)]
        [string]$BackupPath
    )
    
    try {
        if (-not (Test-Path $ConfigPath)) {
            Write-Warning "Configuration file does not exist, no backup needed: $ConfigPath"
            return $false
        }
        
        if (-not (Test-Path $script:ConfigBackupPath)) {
            New-Item -ItemType Directory -Path $script:ConfigBackupPath -Force | Out-Null
        }
        
        if (-not $BackupPath) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $BackupPath = Join-Path $script:ConfigBackupPath ".wslconfig_backup_$timestamp"
        }
        
        Copy-Item -Path $ConfigPath -Destination $BackupPath -Force
        
        Write-Host "WSL configuration file backed up to: $BackupPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to backup WSL configuration file: $($_.Exception.Message)"
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'New-WSLConfig',
    'Test-WSLConfig', 
    'Get-WSLConfig',
    'Set-WSLConfigParameter',
    'Set-WSLConfigPreset',
    'Backup-WSLConfig'
)