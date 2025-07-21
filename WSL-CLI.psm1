# WSL Operations Management - Unified Command Line Interface
# Provides unified cmdlets for all WSL management operations

# Import all required modules
$ModulePath = $PSScriptRoot
$RequiredModules = @(
    'WSL-Detection.psm1',
    'WSL-AutoInstall.psm1', 
    'WSL-DistributionManager.psm1',
    'WSL-HealthMonitor.psm1',
    'WSL-DiagnosticEngine.psm1',
    'WSL-BackupManager.psm1',
    'WSL-ConfigManager.psm1',
    'WSL-PerformanceOptimizer.psm1',
    'WSL-SecurityManager.psm1'
)

foreach ($Module in $RequiredModules) {
    $ModuleFile = Join-Path $ModulePath $Module
    if (Test-Path $ModuleFile) {
        if (Get-Module (Split-Path $Module -LeafBase)) { 
            Remove-Module (Split-Path $Module -LeafBase) -Force 
        }
        Import-Module $ModuleFile -Force -DisableNameChecking
    }
}

# Global variables for CLI state
$Global:WSLCLIConfig = @{
    LogLevel = 'Info'
    OutputFormat = 'Table'
    InteractiveMode = $true
    LastOperation = $null
}

#region Core Management Functions

<#
.SYNOPSIS
Initialize WSL environment with complete setup

.DESCRIPTION
Performs complete WSL environment initialization including feature detection,
WSL2 installation, distribution setup, and basic configuration

.PARAMETER Distribution
Linux distribution to install (default: Ubuntu)

.PARAMETER Force
Force reinstallation even if WSL is already configured

.PARAMETER SkipOptimization
Skip performance optimization during setup

.EXAMPLE
Initialize-WSL
Initialize-WSL -Distribution "Ubuntu-20.04" -Force

.NOTES
Requires administrator privileges
#>
function Initialize-WSL {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)]
        [ValidateSet('Ubuntu', 'Ubuntu-20.04', 'Ubuntu-22.04', 'Debian', 'Alpine', 'openSUSE-Leap-15.4')]
        [string]$Distribution = 'Ubuntu',
        
        [switch]$Force,
        
        [switch]$SkipOptimization
    )
    
    begin {
        Write-WSLLog "Starting WSL environment initialization" -Level Info
        Test-WSLAdminPrivileges
    }
    
    process {
        if ($PSCmdlet.ShouldProcess("WSL Environment", "Initialize")) {
            try {
                # Step 1: Environment detection
                Write-Host "🔍 Detecting WSL environment..." -ForegroundColor Cyan
                $detection = Test-WSLEnvironment -Detailed
                
                if (-not $Force -and $detection.WSLInstalled -and $detection.OverallStatus -eq 'Ready') {
                    Write-Host "✅ WSL environment is already configured" -ForegroundColor Green
                    return $detection
                }
                
                # Step 2: Install WSL2 if needed
                if (-not $detection.WSLInstalled -or $Force) {
                    Write-Host "📦 Installing WSL2..." -ForegroundColor Cyan
                    $installResult = Install-WSL2Complete -Verbose
                    if (-not $installResult.Success) {
                        throw "WSL2 installation failed: $($installResult.Message)"
                    }
                }
                
                # Step 3: Install distribution
                Write-Host "🐧 Installing Linux distribution: $Distribution..." -ForegroundColor Cyan
                $distResult = Install-WSLDistribution -Name $Distribution -SetAsDefault
                if (-not $distResult.Success) {
                    throw "Distribution installation failed: $($distResult.Message)"
                }
                
                # Step 4: Basic configuration
                Write-Host "⚙️ Applying basic configuration..." -ForegroundColor Cyan
                Set-WSLConfigPreset -PresetName "balanced"
                
                # Step 5: Performance optimization
                if (-not $SkipOptimization) {
                    Write-Host "🚀 Optimizing performance..." -ForegroundColor Cyan
                    Optimize-WSLPerformance -Profile "balanced"
                }
                
                # Step 6: Final verification
                Write-Host "✅ Verifying installation..." -ForegroundColor Cyan
                $finalCheck = Test-WSLEnvironment -Detailed
                
                Write-Host "🎉 WSL environment initialization completed successfully!" -ForegroundColor Green
                return $finalCheck
                
            }
            catch {
                Write-Error "WSL initialization failed: $($_.Exception.Message)"
                Write-WSLLog "WSL initialization error: $($_.Exception.Message)" -Level Error
                throw
            }
        }
    }
}

<#
.SYNOPSIS
Get comprehensive WSL system status

.DESCRIPTION
Retrieves detailed information about WSL environment including distributions,
health status, resource usage, and configuration

.PARAMETER Detailed
Include detailed information about each component

.PARAMETER OutputFormat
Output format: Table, List, JSON, or HTML

.EXAMPLE
Get-WSLStatus
Get-WSLStatus -Detailed -OutputFormat JSON

.NOTES
No special privileges required
#>
function Get-WSLStatus {
    [CmdletBinding()]
    param(
        [switch]$Detailed,
        
        [ValidateSet('Table', 'List', 'JSON', 'HTML')]
        [string]$OutputFormat = $Global:WSLCLIConfig.OutputFormat
    )
    
    begin {
        Write-WSLLog "Retrieving WSL system status" -Level Info
    }
    
    process {
        try {
            $status = @{
                Timestamp = Get-Date
                Environment = Test-WSLEnvironment -Detailed:$Detailed
                Distributions = Get-WSLDistributionList
                Health = Test-WSLHealth -Detailed:$Detailed
                Resources = Get-WSLResourceUsage
                Configuration = Get-WSLConfig
            }
            
            switch ($OutputFormat) {
                'JSON' { 
                    return $status | ConvertTo-Json -Depth 5 
                }
                'HTML' { 
                    return ConvertTo-WSLStatusHTML -Status $status 
                }
                'List' { 
                    return Format-WSLStatusList -Status $status 
                }
                default { 
                    return Format-WSLStatusTable -Status $status -Detailed:$Detailed 
                }
            }
        }
        catch {
            Write-Error "Failed to retrieve WSL status: $($_.Exception.Message)"
            throw
        }
    }
}

<#
.SYNOPSIS
Perform WSL health check and diagnostics

.DESCRIPTION
Runs comprehensive health checks and diagnostics on WSL environment,
with optional automatic repair of detected issues

.PARAMETER AutoRepair
Automatically attempt to repair detected issues

.PARAMETER Component
Specific component to check (All, Services, Network, Storage, Permissions)

.PARAMETER GenerateReport
Generate detailed diagnostic report

.EXAMPLE
Test-WSL
Test-WSL -AutoRepair -GenerateReport
Test-WSL -Component Network

.NOTES
Some repair operations require administrator privileges
#>
function Test-WSL {
    [CmdletBinding()]
    param(
        [switch]$AutoRepair,
        
        [ValidateSet('All', 'Services', 'Network', 'Storage', 'Permissions', 'Configuration')]
        [string]$Component = 'All',
        
        [switch]$GenerateReport
    )
    
    begin {
        Write-WSLLog "Starting WSL health check" -Level Info
        if ($AutoRepair) {
            Test-WSLAdminPrivileges
        }
    }
    
    process {
        try {
            Write-Host "🔍 Running WSL diagnostics..." -ForegroundColor Cyan
            
            # Run diagnostics
            $diagnostics = Invoke-WSLDiagnostics -Component $Component -AutoRepair:$AutoRepair
            
            # Display results
            Show-WSLDiagnosticResults -Results $diagnostics
            
            # Generate report if requested
            if ($GenerateReport) {
                $reportPath = New-WSLDiagnosticReport -DiagnosticResults $diagnostics
                Write-Host "📄 Diagnostic report saved to: $reportPath" -ForegroundColor Green
            }
            
            return $diagnostics
        }
        catch {
            Write-Error "WSL diagnostics failed: $($_.Exception.Message)"
            throw
        }
    }
}

#endregion

#region Backup and Recovery Functions

<#
.SYNOPSIS
Create WSL distribution backup

.DESCRIPTION
Creates a backup of specified WSL distribution with options for full or incremental backup

.PARAMETER Distribution
Name of the distribution to backup

.PARAMETER BackupPath
Path where backup will be stored

.PARAMETER Type
Backup type: Full or Incremental

.PARAMETER Compress
Compress the backup file

.EXAMPLE
Backup-WSL -Distribution "Ubuntu" -BackupPath "C:\WSLBackups"
Backup-WSL -Distribution "Ubuntu" -Type Incremental -Compress

.NOTES
Requires sufficient disk space for backup
#>
function Backup-WSL {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Distribution,
        
        [Parameter(Position = 1)]
        [string]$BackupPath = "$env:USERPROFILE\WSLBackups",
        
        [ValidateSet('Full', 'Incremental')]
        [string]$Type = 'Full',
        
        [switch]$Compress
    )
    
    begin {
        Write-WSLLog "Starting WSL backup operation" -Level Info
        Test-WSLDistributionExists -Name $Distribution
    }
    
    process {
        if ($PSCmdlet.ShouldProcess($Distribution, "Backup WSL Distribution")) {
            try {
                Write-Host "💾 Creating $Type backup of $Distribution..." -ForegroundColor Cyan
                
                switch ($Type) {
                    'Full' {
                        $result = New-WSLFullBackup -DistributionName $Distribution -BackupPath $BackupPath -Compress:$Compress
                    }
                    'Incremental' {
                        $result = New-WSLIncrementalBackup -DistributionName $Distribution -BackupPath $BackupPath -Compress:$Compress
                    }
                }
                
                if ($result.Success) {
                    Write-Host "✅ Backup completed successfully!" -ForegroundColor Green
                    Write-Host "📁 Backup location: $($result.BackupFile)" -ForegroundColor Gray
                } else {
                    throw $result.Message
                }
                
                return $result
            }
            catch {
                Write-Error "Backup failed: $($_.Exception.Message)"
                throw
            }
        }
    }
}

<#
.SYNOPSIS
Restore WSL distribution from backup

.DESCRIPTION
Restores a WSL distribution from a previously created backup file

.PARAMETER BackupFile
Path to the backup file

.PARAMETER DistributionName
Name for the restored distribution

.PARAMETER Force
Force restore even if distribution already exists

.EXAMPLE
Restore-WSL -BackupFile "C:\WSLBackups\Ubuntu_backup.tar" -DistributionName "Ubuntu-Restored"

.NOTES
Requires administrator privileges for some operations
#>
function Restore-WSL {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({Test-Path $_})]
        [string]$BackupFile,
        
        [Parameter(Position = 1)]
        [string]$DistributionName,
        
        [switch]$Force
    )
    
    begin {
        Write-WSLLog "Starting WSL restore operation" -Level Info
        Test-WSLAdminPrivileges
    }
    
    process {
        if ($PSCmdlet.ShouldProcess($BackupFile, "Restore WSL Distribution")) {
            try {
                Write-Host "📦 Restoring WSL distribution from backup..." -ForegroundColor Cyan
                
                $result = Restore-WSLDistribution -BackupFile $BackupFile -DistributionName $DistributionName -Force:$Force
                
                if ($result.Success) {
                    Write-Host "✅ Restore completed successfully!" -ForegroundColor Green
                    Write-Host "🐧 Distribution name: $($result.DistributionName)" -ForegroundColor Gray
                } else {
                    throw $result.Message
                }
                
                return $result
            }
            catch {
                Write-Error "Restore failed: $($_.Exception.Message)"
                throw
            }
        }
    }
}

#endregion

#region Configuration Management Functions

<#
.SYNOPSIS
Configure WSL settings

.DESCRIPTION
Configure WSL global settings and distribution-specific parameters

.PARAMETER Memory
Memory limit for WSL (e.g., "4GB", "50%")

.PARAMETER Processors
Number of processors to allocate

.PARAMETER Swap
Swap file size (e.g., "2GB")

.PARAMETER Distribution
Target distribution for configuration

.PARAMETER Preset
Use predefined configuration preset

.EXAMPLE
Set-WSLConfig -Memory "4GB" -Processors 2
Set-WSLConfig -Preset "high-performance"
Set-WSLConfig -Distribution "Ubuntu" -Memory "8GB"

.NOTES
Changes require WSL restart to take effect
#>
function Set-WSLConfig {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Memory,
        
        [ValidateRange(1, [System.Environment]::ProcessorCount)]
        [int]$Processors,
        
        [string]$Swap,
        
        [string]$Distribution,
        
        [ValidateSet('low-resource', 'balanced', 'high-performance', 'development')]
        [string]$Preset
    )
    
    begin {
        Write-WSLLog "Configuring WSL settings" -Level Info
    }
    
    process {
        if ($PSCmdlet.ShouldProcess("WSL Configuration", "Update Settings")) {
            try {
                if ($Preset) {
                    Write-Host "⚙️ Applying configuration preset: $Preset..." -ForegroundColor Cyan
                    $result = Set-WSLConfigPreset -PresetName $Preset
                } else {
                    Write-Host "⚙️ Updating WSL configuration..." -ForegroundColor Cyan
                    
                    $configParams = @{}
                    if ($Memory) { $configParams.Memory = $Memory }
                    if ($Processors) { $configParams.Processors = $Processors }
                    if ($Swap) { $configParams.Swap = $Swap }
                    
                    if ($Distribution) {
                        $result = Set-WSLDistributionConfiguration -Name $Distribution -Configuration $configParams
                    } else {
                        $result = Set-WSLConfigParameter @configParams
                    }
                }
                
                if ($result.Success) {
                    Write-Host "✅ Configuration updated successfully!" -ForegroundColor Green
                    Write-Host "🔄 Restart WSL to apply changes: wsl --shutdown" -ForegroundColor Yellow
                } else {
                    throw $result.Message
                }
                
                return $result
            }
            catch {
                Write-Error "Configuration update failed: $($_.Exception.Message)"
                throw
            }
        }
    }
}

#endregion

#region Interactive Menu System

<#
.SYNOPSIS
Start interactive WSL management menu

.DESCRIPTION
Launches an interactive menu system for WSL management operations

.EXAMPLE
Start-WSLMenu

.NOTES
Provides guided interface for all WSL operations
#>
function Start-WSLMenu {
    [CmdletBinding()]
    param()
    
    do {
        Clear-Host
        Show-WSLMenuHeader
        
        $choice = Show-WSLMainMenu
        
        switch ($choice) {
            '1' { Invoke-WSLEnvironmentMenu }
            '2' { Invoke-WSLDistributionMenu }
            '3' { Invoke-WSLHealthMenu }
            '4' { Invoke-WSLBackupMenu }
            '5' { Invoke-WSLConfigMenu }
            '6' { Invoke-WSLSecurityMenu }
            '7' { Invoke-WSLCleanupMenu }
            '8' { Show-WSLHelp }
            'Q' { return }
            default { 
                Write-Host "Invalid selection. Press any key to continue..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    } while ($true)
}

function Show-WSLMenuHeader {
    Write-Host @"
╔══════════════════════════════════════════════════════════════════════════════╗
║                          WSL Operations Management                           ║
║                            Command Line Interface                            ║
╚══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
    
    # Show current WSL status
    try {
        $quickStatus = Test-WSLEnvironment
        $statusColor = switch ($quickStatus.OverallStatus) {
            'Ready' { 'Green' }
            'Warning' { 'Yellow' }
            'Error' { 'Red' }
            default { 'Gray' }
        }
        Write-Host "Current Status: " -NoNewline -ForegroundColor Gray
        Write-Host $quickStatus.OverallStatus -ForegroundColor $statusColor
        Write-Host ""
    }
    catch {
        Write-Host "Status: Unknown" -ForegroundColor Gray
        Write-Host ""
    }
}

function Show-WSLMainMenu {
    Write-Host "Main Menu:" -ForegroundColor Yellow
    Write-Host "  1. Environment Management (Initialize, Status, Detection)"
    Write-Host "  2. Distribution Management (Install, Configure, Manage)"
    Write-Host "  3. Health & Diagnostics (Check, Repair, Monitor)"
    Write-Host "  4. Backup & Recovery (Backup, Restore, Migration)"
    Write-Host "  5. Configuration Management (Settings, Optimization)"
    Write-Host "  6. Security Management (Permissions, Policies)"
    Write-Host "  7. Cleanup & Reset (Clean, Uninstall, Reset)"
    Write-Host "  8. Help & Documentation"
    Write-Host "  Q. Quit"
    Write-Host ""
    
    return Read-Host "Select an option (1-8, Q)"
}

#endregion

#region Helper Functions

function Write-WSLLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info'
    )
    
    if ($Global:WSLCLIConfig.LogLevel -eq 'Debug' -or $Level -ne 'Debug') {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$Level] $Message"
        
        # Write to console based on level
        switch ($Level) {
            'Error' { Write-Host $logMessage -ForegroundColor Red }
            'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
            'Debug' { Write-Host $logMessage -ForegroundColor Gray }
            default { Write-Host $logMessage -ForegroundColor White }
        }
        
        # Also write to log file if configured
        $logPath = "$env:TEMP\WSL-CLI.log"
        Add-Content -Path $logPath -Value $logMessage -ErrorAction SilentlyContinue
    }
}

function Test-WSLAdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This operation requires administrator privileges. Please run PowerShell as Administrator."
    }
}

function Test-WSLDistributionExists {
    param([string]$Name)
    
    $distributions = wsl --list --quiet 2>$null
    if ($distributions -notcontains $Name) {
        throw "WSL distribution '$Name' not found. Available distributions: $($distributions -join ', ')"
    }
}

#endregion

# Export main cmdlets
Export-ModuleMember -Function @(
    'Initialize-WSL',
    'Get-WSLStatus', 
    'Test-WSL',
    'Backup-WSL',
    'Restore-WSL', 
    'Set-WSLConfig',
    'Start-WSLMenu'
)
#region I
nteractive Menu Implementation

function Invoke-WSLEnvironmentMenu {
    do {
        Clear-Host
        Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║                           Environment Management                             ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "Environment Options:" -ForegroundColor Yellow
        Write-Host "  1. Initialize WSL Environment"
        Write-Host "  2. Check WSL Environment Status"
        Write-Host "  3. Detect WSL Features and Capabilities"
        Write-Host "  4. Install WSL2 Components"
        Write-Host "  5. Show Environment Report"
        Write-Host "  B. Back to Main Menu"
        Write-Host ""
        
        $choice = Read-Host "Select an option (1-5, B)"
        
        switch ($choice) {
            '1' { 
                $dist = Read-Host "Enter distribution name (default: Ubuntu)"
                if ([string]::IsNullOrEmpty($dist)) { $dist = "Ubuntu" }
                Initialize-WSL -Distribution $dist -Verbose
                Pause
            }
            '2' { 
                Get-WSLStatus -Detailed
                Pause
            }
            '3' { 
                Test-WSLEnvironment -Detailed | Format-Table -AutoSize
                Pause
            }
            '4' { 
                Install-WSL2Complete -Verbose
                Pause
            }
            '5' { 
                $reportPath = New-WSLEnvironmentReport
                Write-Host "Environment report generated: $reportPath" -ForegroundColor Green
                Pause
            }
            'B' { return }
            default { 
                Write-Host "Invalid selection. Press any key to continue..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    } while ($true)
}

function Invoke-WSLDistributionMenu {
    do {
        Clear-Host
        Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║                          Distribution Management                             ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "Distribution Options:" -ForegroundColor Yellow
        Write-Host "  1. List Available Distributions"
        Write-Host "  2. Install New Distribution"
        Write-Host "  3. Remove Distribution"
        Write-Host "  4. Set Default Distribution"
        Write-Host "  5. Distribution Configuration"
        Write-Host "  B. Back to Main Menu"
        Write-Host ""
        
        $choice = Read-Host "Select an option (1-5, B)"
        
        switch ($choice) {
            '1' { 
                Get-WSLDistributionList | Format-Table -AutoSize
                Pause
            }
            '2' { 
                $distName = Read-Host "Enter distribution name"
                Install-WSLDistribution -Name $distName -Verbose
                Pause
            }
            '3' { 
                $distName = Read-Host "Enter distribution name to remove"
                Remove-WSLDistribution -Name $distName -Confirm
                Pause
            }
            '4' { 
                $distName = Read-Host "Enter distribution name to set as default"
                Set-WSLDefaultDistribution -Name $distName
                Pause
            }
            '5' { 
                $distName = Read-Host "Enter distribution name to configure"
                Show-WSLDistributionConfig -Name $distName
                Pause
            }
            'B' { return }
            default { 
                Write-Host "Invalid selection. Press any key to continue..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    } while ($true)
}

function Invoke-WSLHealthMenu {
    do {
        Clear-Host
        Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║                           Health & Diagnostics                              ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "Health & Diagnostics Options:" -ForegroundColor Yellow
        Write-Host "  1. Quick Health Check"
        Write-Host "  2. Detailed Health Check"
        Write-Host "  3. Run Diagnostics with Auto-Repair"
        Write-Host "  4. Performance Monitoring"
        Write-Host "  5. Generate Diagnostic Report"
        Write-Host "  B. Back to Main Menu"
        Write-Host ""
        
        $choice = Read-Host "Select an option (1-5, B)"
        
        switch ($choice) {
            '1' { 
                Test-WSLHealth | Format-Table -AutoSize
                Pause
            }
            '2' { 
                Test-WSLHealth -Detailed | Format-List
                Pause
            }
            '3' { 
                Test-WSL -AutoRepair -Verbose
                Pause
            }
            '4' { 
                Get-WSLResourceUsage | Format-Table -AutoSize
                Pause
            }
            '5' { 
                Test-WSL -GenerateReport
                Pause
            }
            'B' { return }
            default { 
                Write-Host "Invalid selection. Press any key to continue..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    } while ($true)
}

function Invoke-WSLBackupMenu {
    do {
        Clear-Host
        Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║                            Backup & Recovery                                ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "Backup & Recovery Options:" -ForegroundColor Yellow
        Write-Host "  1. Create Full Backup"
        Write-Host "  2. Create Incremental Backup"
        Write-Host "  3. Restore from Backup"
        Write-Host "  4. List Available Backups"
        Write-Host "  5. Export Distribution"
        Write-Host "  6. Import Distribution"
        Write-Host "  B. Back to Main Menu"
        Write-Host ""
        
        $choice = Read-Host "Select an option (1-6, B)"
        
        switch ($choice) {
            '1' { 
                $dist = Read-Host "Enter distribution name to backup"
                $path = Read-Host "Enter backup path (default: $env:USERPROFILE\WSLBackups)"
                if ([string]::IsNullOrEmpty($path)) { $path = "$env:USERPROFILE\WSLBackups" }
                Backup-WSL -Distribution $dist -BackupPath $path -Type Full -Verbose
                Pause
            }
            '2' { 
                $dist = Read-Host "Enter distribution name to backup"
                $path = Read-Host "Enter backup path (default: $env:USERPROFILE\WSLBackups)"
                if ([string]::IsNullOrEmpty($path)) { $path = "$env:USERPROFILE\WSLBackups" }
                Backup-WSL -Distribution $dist -BackupPath $path -Type Incremental -Verbose
                Pause
            }
            '3' { 
                $backupFile = Read-Host "Enter backup file path"
                $newName = Read-Host "Enter new distribution name (optional)"
                if ([string]::IsNullOrEmpty($newName)) {
                    Restore-WSL -BackupFile $backupFile -Verbose
                } else {
                    Restore-WSL -BackupFile $backupFile -DistributionName $newName -Verbose
                }
                Pause
            }
            '4' { 
                $path = Read-Host "Enter backup directory (default: $env:USERPROFILE\WSLBackups)"
                if ([string]::IsNullOrEmpty($path)) { $path = "$env:USERPROFILE\WSLBackups" }
                Get-WSLBackupList -BackupPath $path | Format-Table -AutoSize
                Pause
            }
            '5' { 
                $dist = Read-Host "Enter distribution name to export"
                $outputPath = Read-Host "Enter output path"
                Export-WSLDistribution -Name $dist -OutputPath $outputPath -Verbose
                Pause
            }
            '6' { 
                $importFile = Read-Host "Enter import file path"
                $name = Read-Host "Enter distribution name"
                Import-WSLDistribution -ImportFile $importFile -Name $name -Verbose
                Pause
            }
            'B' { return }
            default { 
                Write-Host "Invalid selection. Press any key to continue..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    } while ($true)
}

function Invoke-WSLConfigMenu {
    do {
        Clear-Host
        Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║                         Configuration Management                            ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "Configuration Options:" -ForegroundColor Yellow
        Write-Host "  1. View Current Configuration"
        Write-Host "  2. Apply Configuration Preset"
        Write-Host "  3. Set Memory Limit"
        Write-Host "  4. Set Processor Count"
        Write-Host "  5. Performance Optimization"
        Write-Host "  6. Reset to Default Configuration"
        Write-Host "  B. Back to Main Menu"
        Write-Host ""
        
        $choice = Read-Host "Select an option (1-6, B)"
        
        switch ($choice) {
            '1' { 
                Get-WSLConfig | Format-List
                Pause
            }
            '2' { 
                Write-Host "Available presets: low-resource, balanced, high-performance, development"
                $preset = Read-Host "Enter preset name"
                Set-WSLConfig -Preset $preset -Verbose
                Pause
            }
            '3' { 
                $memory = Read-Host "Enter memory limit (e.g., 4GB, 50%)"
                Set-WSLConfig -Memory $memory -Verbose
                Pause
            }
            '4' { 
                $processors = Read-Host "Enter processor count"
                Set-WSLConfig -Processors ([int]$processors) -Verbose
                Pause
            }
            '5' { 
                Write-Host "Available profiles: low-resource, balanced, high-performance"
                $profile = Read-Host "Enter optimization profile"
                Optimize-WSLPerformance -Profile $profile -Verbose
                Pause
            }
            '6' { 
                Reset-WSLConfiguration -Confirm
                Pause
            }
            'B' { return }
            default { 
                Write-Host "Invalid selection. Press any key to continue..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    } while ($true)
}

function Invoke-WSLSecurityMenu {
    do {
        Clear-Host
        Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║                            Security Management                              ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "Security Options:" -ForegroundColor Yellow
        Write-Host "  1. Security Audit"
        Write-Host "  2. Apply Security Policies"
        Write-Host "  3. Manage User Permissions"
        Write-Host "  4. Configure Firewall Rules"
        Write-Host "  5. Security Hardening"
        Write-Host "  B. Back to Main Menu"
        Write-Host ""
        
        $choice = Read-Host "Select an option (1-5, B)"
        
        switch ($choice) {
            '1' { 
                Get-WSLSecurityAudit | Format-Table -AutoSize
                Pause
            }
            '2' { 
                $policyFile = Read-Host "Enter security policy file path (optional)"
                if ([string]::IsNullOrEmpty($policyFile)) {
                    Set-WSLSecurityPolicy -Verbose
                } else {
                    Set-WSLSecurityPolicy -PolicyFile $policyFile -Verbose
                }
                Pause
            }
            '3' { 
                $user = Read-Host "Enter username"
                $permissions = Read-Host "Enter permissions (comma-separated)"
                Set-WSLUserPermissions -User $user -Permissions ($permissions -split ',') -Verbose
                Pause
            }
            '4' { 
                Enable-WSLFirewall -Verbose
                Pause
            }
            '5' { 
                Invoke-WSLSecurityHardening -Verbose
                Pause
            }
            'B' { return }
            default { 
                Write-Host "Invalid selection. Press any key to continue..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    } while ($true)
}

function Invoke-WSLCleanupMenu {
    do {
        Clear-Host
        Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║                            Cleanup & Reset                                  ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "Cleanup & Reset Options:" -ForegroundColor Yellow
        Write-Host "  1. Clean Cache and Temporary Files"
        Write-Host "  2. Clean Specific Distribution"
        Write-Host "  3. Reset WSL Configuration"
        Write-Host "  4. Complete WSL Uninstall"
        Write-Host "  5. System Reset (DANGEROUS)"
        Write-Host "  B. Back to Main Menu"
        Write-Host ""
        
        $choice = Read-Host "Select an option (1-5, B)"
        
        switch ($choice) {
            '1' { 
                Clear-WSLCache -Verbose
                Pause
            }
            '2' { 
                $dist = Read-Host "Enter distribution name to clean"
                Clear-WSLDistribution -Name $dist -Verbose
                Pause
            }
            '3' { 
                Reset-WSLConfiguration -Confirm
                Pause
            }
            '4' { 
                Write-Host "WARNING: This will completely remove WSL and all distributions!" -ForegroundColor Red
                $confirm = Read-Host "Type 'CONFIRM' to proceed"
                if ($confirm -eq 'CONFIRM') {
                    Uninstall-WSLCompletely -Verbose
                }
                Pause
            }
            '5' { 
                Write-Host "DANGER: This will reset WSL to factory defaults!" -ForegroundColor Red
                $confirm = Read-Host "Type 'RESET' to proceed"
                if ($confirm -eq 'RESET') {
                    Reset-WSLToDefault -BackupFirst -Verbose
                }
                Pause
            }
            'B' { return }
            default { 
                Write-Host "Invalid selection. Press any key to continue..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    } while ($true)
}

function Show-WSLHelp {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                              WSL Help & Documentation                        ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Available Commands:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Core Management:" -ForegroundColor Green
    Write-Host "  Initialize-WSL          - Initialize WSL environment"
    Write-Host "  Get-WSLStatus          - Get comprehensive WSL status"
    Write-Host "  Test-WSL               - Run health checks and diagnostics"
    Write-Host ""
    Write-Host "Backup & Recovery:" -ForegroundColor Green
    Write-Host "  Backup-WSL             - Create distribution backup"
    Write-Host "  Restore-WSL            - Restore from backup"
    Write-Host ""
    Write-Host "Configuration:" -ForegroundColor Green
    Write-Host "  Set-WSLConfig          - Configure WSL settings"
    Write-Host ""
    Write-Host "Interactive:" -ForegroundColor Green
    Write-Host "  Start-WSLMenu          - Launch interactive menu"
    Write-Host ""
    Write-Host "For detailed help on any command, use: Get-Help <CommandName> -Detailed"
    Write-Host ""
    Write-Host "Documentation and troubleshooting guides are available in the docs folder."
    Write-Host ""
    
    Pause
}

function Pause {
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Additional helper functions for formatting output
function Format-WSLStatusTable {
    param($Status, [switch]$Detailed)
    
    $output = @()
    
    # Environment status
    $output += [PSCustomObject]@{
        Component = "WSL Environment"
        Status = $Status.Environment.OverallStatus
        Details = if ($Detailed) { $Status.Environment.Details } else { $Status.Environment.Summary }
    }
    
    # Distributions
    foreach ($dist in $Status.Distributions) {
        $output += [PSCustomObject]@{
            Component = "Distribution: $($dist.Name)"
            Status = $dist.State
            Details = if ($Detailed) { "$($dist.Version) - $($dist.DefaultUid)" } else { $dist.Version }
        }
    }
    
    # Health status
    $output += [PSCustomObject]@{
        Component = "Health Status"
        Status = $Status.Health.OverallHealth
        Details = if ($Detailed) { $Status.Health.Issues -join '; ' } else { "$($Status.Health.ChecksPassed)/$($Status.Health.TotalChecks) checks passed" }
    }
    
    return $output | Format-Table -AutoSize
}

function ConvertTo-WSLStatusHTML {
    param($Status)
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>WSL Status Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #0078d4; color: white; padding: 10px; }
        .section { margin: 20px 0; }
        .status-ok { color: green; }
        .status-warning { color: orange; }
        .status-error { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>WSL Status Report</h1>
        <p>Generated: $($Status.Timestamp)</p>
    </div>
    
    <div class="section">
        <h2>Environment Status</h2>
        <p class="status-$($Status.Environment.OverallStatus.ToLower())">
            Overall Status: $($Status.Environment.OverallStatus)
        </p>
    </div>
    
    <div class="section">
        <h2>Distributions</h2>
        <table>
            <tr><th>Name</th><th>State</th><th>Version</th></tr>
"@
    
    foreach ($dist in $Status.Distributions) {
        $html += "<tr><td>$($dist.Name)</td><td>$($dist.State)</td><td>$($dist.Version)</td></tr>"
    }
    
    $html += @"
        </table>
    </div>
    
    <div class="section">
        <h2>Resource Usage</h2>
        <table>
            <tr><th>Resource</th><th>Usage</th></tr>
            <tr><td>Memory</td><td>$($Status.Resources.MemoryUsage)</td></tr>
            <tr><td>CPU</td><td>$($Status.Resources.CpuUsage)</td></tr>
            <tr><td>Disk</td><td>$($Status.Resources.DiskUsage)</td></tr>
        </table>
    </div>
</body>
</html>
"@
    
    return $html
}

#endregion

# Module initialization
Write-Host "WSL Operations Management CLI loaded successfully!" -ForegroundColor Green
Write-Host "Use 'Start-WSLMenu' to launch the interactive interface or 'Get-Help Initialize-WSL' for command help." -ForegroundColor Gray