# WSL Migration Management Module
# Provides cross-machine environment packaging, transfer, batch deployment and migration validation

# Import required modules
if (Get-Module WSL-Detection) { Remove-Module WSL-Detection }
Import-Module "$PSScriptRoot\WSL-Detection.psm1" -Force

if (Get-Module WSL-BackupManager) { Remove-Module WSL-BackupManager }
Import-Module "$PSScriptRoot\WSL-BackupManager.psm1" -Force

# Global variables
$script:MigrationBasePath = "$env:USERPROFILE\WSL-Migrations"
$script:MigrationMetadataFileName = "migration-metadata.json"
$script:MigrationLogFile = "$script:MigrationBasePath\migration.log"

# Ensure migration directory exists
function Initialize-MigrationDirectory {
    if (-not (Test-Path $script:MigrationBasePath)) {
        New-Item -ItemType Directory -Path $script:MigrationBasePath -Force | Out-Null
        Write-Host "Created migration directory: $script:MigrationBasePath" -ForegroundColor Green
    }
}

# Write migration log
function Write-MigrationLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Ensure log directory exists
    $logDir = Split-Path $script:MigrationLogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    Add-Content -Path $script:MigrationLogFile -Value $logEntry
    
    # Display different colors based on level
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARN" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry -ForegroundColor White }
    }
}

# Get system environment information for migration
function Get-SystemEnvironmentInfo {
    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem
        $processorInfo = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
        
        return @{
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            OSVersion = $osInfo.Version
            OSBuild = $osInfo.BuildNumber
            OSArchitecture = $osInfo.OSArchitecture
            TotalMemoryGB = [math]::Round($computerInfo.TotalPhysicalMemory / 1GB, 2)
            ProcessorName = $processorInfo.Name
            ProcessorCores = $processorInfo.NumberOfCores
            WSLVersion = (wsl --version 2>$null | Select-Object -First 1) -replace "WSL version: ", ""
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    catch {
        Write-MigrationLog "Failed to get system environment info: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Get WSL configuration for migration
function Get-WSLConfigurationForMigration {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName
    )
    
    try {
        $config = @{
            DistributionName = $DistributionName
            DefaultUser = $null
            WSLConfig = @{}
            EnvironmentVariables = @{}
            InstalledPackages = @()
            Services = @()
            NetworkConfig = @{}
        }
        
        # Get default user
        try {
            $defaultUser = wsl -d $DistributionName -- whoami 2>$null
            if ($LASTEXITCODE -eq 0 -and $defaultUser) {
                $config.DefaultUser = $defaultUser.Trim()
            }
        }
        catch {
            Write-MigrationLog "Could not determine default user for $DistributionName" "WARN"
        }
        
        # Get .wslconfig if exists
        $wslConfigPath = "$env:USERPROFILE\.wslconfig"
        if (Test-Path $wslConfigPath) {
            $config.WSLConfig = Get-Content $wslConfigPath -Raw
        }
        
        # Get environment variables
        try {
            $envVars = wsl -d $DistributionName -- env 2>$null
            if ($LASTEXITCODE -eq 0 -and $envVars) {
                $config.EnvironmentVariables = $envVars | Where-Object { $_ -match "=" } | ForEach-Object {
                    $parts = $_ -split "=", 2
                    @{ Name = $parts[0]; Value = $parts[1] }
                }
            }
        }
        catch {
            Write-MigrationLog "Could not get environment variables for $DistributionName" "WARN"
        }
        
        # Get installed packages (for Ubuntu/Debian)
        try {
            $packages = wsl -d $DistributionName -- bash -c "dpkg -l 2>/dev/null | grep '^ii' | awk '{print \$2}'" 2>$null
            if ($LASTEXITCODE -eq 0 -and $packages) {
                $config.InstalledPackages = $packages | Where-Object { $_ -and $_.Trim() -ne "" }
            }
        }
        catch {
            Write-MigrationLog "Could not get installed packages for $DistributionName" "WARN"
        }
        
        # Get running services
        try {
            $services = wsl -d $DistributionName -- bash -c "systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null | awk '{print \$1}'" 2>$null
            if ($LASTEXITCODE -eq 0 -and $services) {
                $config.Services = $services | Where-Object { $_ -and $_.Trim() -ne "" }
            }
        }
        catch {
            Write-MigrationLog "Could not get running services for $DistributionName" "WARN"
        }
        
        # Get network configuration
        try {
            $networkInfo = wsl -d $DistributionName -- bash -c "ip addr show 2>/dev/null | grep 'inet ' | head -5" 2>$null
            if ($LASTEXITCODE -eq 0 -and $networkInfo) {
                $config.NetworkConfig = @{
                    Interfaces = $networkInfo | Where-Object { $_ -and $_.Trim() -ne "" }
                }
            }
        }
        catch {
            Write-MigrationLog "Could not get network configuration for $DistributionName" "WARN"
        }
        
        return $config
    }
    catch {
        Write-MigrationLog "Failed to get WSL configuration for migration: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Create portable WSL environment package
function New-WSLMigrationPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        [string]$OutputPath = $null,
        [switch]$IncludeSystemInfo,
        [switch]$Compress = $true
    )
    
    try {
        Initialize-MigrationDirectory
        
        Write-MigrationLog "Creating migration package for distribution: $DistributionName" "INFO"
        
        # Generate package path
        if (-not $OutputPath) {
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $packageName = "${DistributionName}-migration-${timestamp}"
            $OutputPath = Join-Path $script:MigrationBasePath $packageName
        }
        
        # Create package directory
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
        
        Write-MigrationLog "Package directory: $OutputPath" "INFO"
        
        # Create full backup of the distribution
        $backupPath = Join-Path $OutputPath "${DistributionName}.tar"
        Write-MigrationLog "Creating distribution backup..." "INFO"
        
        $backupResult = New-WSLFullBackup -DistributionName $DistributionName -BackupPath $backupPath
        if (-not $backupResult) {
            throw "Failed to create distribution backup"
        }
        
        # Get WSL configuration
        Write-MigrationLog "Collecting WSL configuration..." "INFO"
        $wslConfig = Get-WSLConfigurationForMigration -DistributionName $DistributionName
        
        # Get system environment info if requested
        $systemInfo = $null
        if ($IncludeSystemInfo) {
            Write-MigrationLog "Collecting system environment information..." "INFO"
            $systemInfo = Get-SystemEnvironmentInfo
        }
        
        # Create migration metadata
        $migrationId = [System.Guid]::NewGuid().ToString()
        $metadata = @{
            MigrationId = $migrationId
            DistributionName = $DistributionName
            CreatedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            CreatedBy = $env:USERNAME
            SourceComputer = $env:COMPUTERNAME
            PackageVersion = "1.0.0"
            BackupInfo = $backupResult
            WSLConfiguration = $wslConfig
            SystemInfo = $systemInfo
            Files = @{
                Backup = "${DistributionName}.tar"
                Metadata = "migration-metadata.json"
                InstallScript = "install-migration.ps1"
                ValidationScript = "validate-migration.ps1"
            }
        }
        
        # Save metadata
        $metadataPath = Join-Path $OutputPath "migration-metadata.json"
        $metadata | ConvertTo-Json -Depth 10 | Set-Content $metadataPath -Encoding UTF8
        Write-MigrationLog "Migration metadata saved: $metadataPath" "SUCCESS"
        
        # Create installation script
        $installScriptContent = @"
# WSL Migration Installation Script
# Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

param(
    [string]`$TargetDistributionName = "$DistributionName",
    [switch]`$Force,
    [switch]`$ValidateAfterInstall
)

Write-Host "Installing WSL migration package..." -ForegroundColor Green
Write-Host "Source Distribution: $DistributionName" -ForegroundColor Yellow
Write-Host "Target Distribution: `$TargetDistributionName" -ForegroundColor Yellow

try {
    # Check if target distribution already exists
    `$existingDists = wsl --list --quiet 2>`$null
    if (`$existingDists -contains `$TargetDistributionName -and -not `$Force) {
        throw "Distribution '`$TargetDistributionName' already exists. Use -Force to overwrite."
    }
    
    # Remove existing distribution if Force is specified
    if (`$existingDists -contains `$TargetDistributionName -and `$Force) {
        Write-Host "Removing existing distribution: `$TargetDistributionName" -ForegroundColor Yellow
        wsl --unregister `$TargetDistributionName
    }
    
    # Import the distribution
    `$backupFile = Join-Path `$PSScriptRoot "${DistributionName}.tar"
    if (-not (Test-Path `$backupFile)) {
        throw "Backup file not found: `$backupFile"
    }
    
    Write-Host "Importing distribution from backup..." -ForegroundColor Yellow
    wsl --import `$TargetDistributionName `$env:USERPROFILE\WSL\`$TargetDistributionName `$backupFile
    
    if (`$LASTEXITCODE -ne 0) {
        throw "Failed to import distribution"
    }
    
    # Apply WSL configuration if exists
    `$metadata = Get-Content "`$PSScriptRoot\migration-metadata.json" | ConvertFrom-Json
    if (`$metadata.WSLConfiguration.WSLConfig) {
        `$wslConfigPath = "`$env:USERPROFILE\.wslconfig"
        Write-Host "Applying WSL configuration..." -ForegroundColor Yellow
        `$metadata.WSLConfiguration.WSLConfig | Set-Content `$wslConfigPath -Encoding UTF8
    }
    
    Write-Host "Migration installation completed successfully!" -ForegroundColor Green
    
    # Run validation if requested
    if (`$ValidateAfterInstall) {
        Write-Host "Running post-installation validation..." -ForegroundColor Yellow
        & "`$PSScriptRoot\validate-migration.ps1" -DistributionName `$TargetDistributionName
    }
}
catch {
    Write-Host "Migration installation failed: `$(`$_.Exception.Message)" -ForegroundColor Red
    exit 1
}
"@
        
        $installScriptPath = Join-Path $OutputPath "install-migration.ps1"
        $installScriptContent | Set-Content $installScriptPath -Encoding UTF8
        Write-MigrationLog "Installation script created: $installScriptPath" "SUCCESS"
        
        # Create validation script
        $validationScriptContent = @"
# WSL Migration Validation Script
# Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

param(
    [Parameter(Mandatory = `$true)]
    [string]`$DistributionName
)

Write-Host "Validating migrated WSL distribution: `$DistributionName" -ForegroundColor Green

try {
    `$validationResults = @{
        DistributionExists = `$false
        DistributionRunning = `$false
        DefaultUserCorrect = `$false
        PackagesInstalled = 0
        ServicesRunning = 0
        ValidationPassed = `$false
    }
    
    # Check if distribution exists
    `$distributions = wsl --list --quiet 2>`$null
    if (`$distributions -contains `$DistributionName) {
        `$validationResults.DistributionExists = `$true
        Write-Host "✓ Distribution exists in WSL" -ForegroundColor Green
    } else {
        Write-Host "✗ Distribution not found in WSL" -ForegroundColor Red
        return `$validationResults
    }
    
    # Check if distribution can start
    try {
        `$testResult = wsl -d `$DistributionName -- echo "test" 2>`$null
        if (`$LASTEXITCODE -eq 0 -and `$testResult -eq "test") {
            `$validationResults.DistributionRunning = `$true
            Write-Host "✓ Distribution can start and execute commands" -ForegroundColor Green
        } else {
            Write-Host "✗ Distribution cannot start or execute commands" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "✗ Error testing distribution startup: `$(`$_.Exception.Message)" -ForegroundColor Red
    }
    
    # Load original metadata for comparison
    `$metadata = Get-Content "`$PSScriptRoot\migration-metadata.json" | ConvertFrom-Json
    
    # Check default user
    try {
        `$currentUser = wsl -d `$DistributionName -- whoami 2>`$null
        if (`$LASTEXITCODE -eq 0 -and `$currentUser.Trim() -eq `$metadata.WSLConfiguration.DefaultUser) {
            `$validationResults.DefaultUserCorrect = `$true
            Write-Host "✓ Default user matches original: `$(`$currentUser.Trim())" -ForegroundColor Green
        } else {
            Write-Host "✗ Default user mismatch. Expected: `$(`$metadata.WSLConfiguration.DefaultUser), Got: `$(`$currentUser.Trim())" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "✗ Error checking default user: `$(`$_.Exception.Message)" -ForegroundColor Red
    }
    
    # Check installed packages (sample check)
    try {
        `$currentPackages = wsl -d `$DistributionName -- bash -c "dpkg -l 2>/dev/null | grep '^ii' | wc -l" 2>`$null
        if (`$LASTEXITCODE -eq 0 -and `$currentPackages) {
            `$validationResults.PackagesInstalled = [int]`$currentPackages.Trim()
            `$originalCount = `$metadata.WSLConfiguration.InstalledPackages.Count
            Write-Host "✓ Packages installed: `$(`$validationResults.PackagesInstalled) (original: `$originalCount)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "✗ Error checking installed packages: `$(`$_.Exception.Message)" -ForegroundColor Red
    }
    
    # Overall validation result
    `$validationResults.ValidationPassed = `$validationResults.DistributionExists -and `$validationResults.DistributionRunning
    
    if (`$validationResults.ValidationPassed) {
        Write-Host "✓ Migration validation PASSED" -ForegroundColor Green
    } else {
        Write-Host "✗ Migration validation FAILED" -ForegroundColor Red
    }
    
    return `$validationResults
}
catch {
    Write-Host "Validation error: `$(`$_.Exception.Message)" -ForegroundColor Red
    return @{ ValidationPassed = `$false; Error = `$_.Exception.Message }
}
"@
        
        $validationScriptPath = Join-Path $OutputPath "validate-migration.ps1"
        $validationScriptContent | Set-Content $validationScriptPath -Encoding UTF8
        Write-MigrationLog "Validation script created: $validationScriptPath" "SUCCESS"
        
        # Create README file
        $readmeContent = @"
# WSL Migration Package

This package contains a complete WSL distribution migration created on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss").

## Package Contents

- **${DistributionName}.tar**: Complete WSL distribution backup
- **migration-metadata.json**: Migration metadata and configuration
- **install-migration.ps1**: Installation script for target machine
- **validate-migration.ps1**: Validation script to verify migration
- **README.md**: This file

## Installation Instructions

1. Copy this entire folder to the target machine
2. Open PowerShell as Administrator
3. Navigate to the package directory
4. Run the installation script:

```powershell
.\install-migration.ps1 -TargetDistributionName "YourDistributionName" -ValidateAfterInstall
```

## Options

- `-TargetDistributionName`: Name for the distribution on target machine (default: $DistributionName)
- `-Force`: Overwrite existing distribution with same name
- `-ValidateAfterInstall`: Run validation after installation

## Validation

To manually validate the migration:

```powershell
.\validate-migration.ps1 -DistributionName "YourDistributionName"
```

## Source Information

- **Source Distribution**: $DistributionName
- **Source Computer**: $env:COMPUTERNAME
- **Created By**: $env:USERNAME
- **Migration ID**: $migrationId

## Requirements

- Windows 10/11 with WSL2 enabled
- PowerShell 5.1 or later
- Administrator privileges for installation
"@
        
        $readmePath = Join-Path $OutputPath "README.md"
        $readmeContent | Set-Content $readmePath -Encoding UTF8
        Write-MigrationLog "README file created: $readmePath" "SUCCESS"
        
        # Compress package if requested
        if ($Compress) {
            Write-MigrationLog "Compressing migration package..." "INFO"
            $compressedPath = "$OutputPath.zip"
            
            try {
                Compress-Archive -Path "$OutputPath\*" -DestinationPath $compressedPath -Force
                Write-MigrationLog "Package compressed: $compressedPath" "SUCCESS"
                
                # Update metadata with compressed info
                $packageInfo = Get-Item $compressedPath
                $metadata.CompressedPackage = @{
                    Path = $compressedPath
                    SizeBytes = $packageInfo.Length
                    SizeMB = [math]::Round($packageInfo.Length / 1MB, 2)
                }
                
                # Save updated metadata
                $metadata | ConvertTo-Json -Depth 10 | Set-Content $metadataPath -Encoding UTF8
            }
            catch {
                Write-MigrationLog "Failed to compress package: $($_.Exception.Message)" "WARN"
            }
        }
        
        # Save migration record
        Save-MigrationRecord -Metadata $metadata
        
        $packageSize = if ($Compress -and (Test-Path "$OutputPath.zip")) {
            [math]::Round((Get-Item "$OutputPath.zip").Length / 1MB, 2)
        } else {
            $folderSize = (Get-ChildItem $OutputPath -Recurse | Measure-Object -Property Length -Sum).Sum
            [math]::Round($folderSize / 1MB, 2)
        }
        
        Write-MigrationLog "Migration package created successfully!" "SUCCESS"
        Write-MigrationLog "Package size: $packageSize MB" "INFO"
        Write-MigrationLog "Migration ID: $migrationId" "INFO"
        
        return @{
            MigrationId = $migrationId
            PackagePath = $OutputPath
            CompressedPath = if ($Compress) { "$OutputPath.zip" } else { $null }
            Size = $packageSize
            Metadata = $metadata
        }
    }
    catch {
        Write-MigrationLog "Failed to create migration package: $($_.Exception.Message)" "ERROR"
        
        # Clean up on failure
        if ($OutputPath -and (Test-Path $OutputPath)) {
            try {
                Remove-Item $OutputPath -Recurse -Force
                Write-MigrationLog "Cleaned up failed package directory: $OutputPath" "INFO"
            }
            catch {
                Write-MigrationLog "Error cleaning up failed package: $($_.Exception.Message)" "WARN"
            }
        }
        
        throw
    }
}

# Save migration record to metadata file
function Save-MigrationRecord {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Metadata
    )
    
    try {
        $migrationMetadataPath = Join-Path $script:MigrationBasePath $script:MigrationMetadataFileName
        
        # Read existing migration records
        $allMigrations = @()
        if (Test-Path $migrationMetadataPath) {
            $existingContent = Get-Content $migrationMetadataPath -Raw -ErrorAction SilentlyContinue
            if ($existingContent) {
                $allMigrations = $existingContent | ConvertFrom-Json
                if ($allMigrations -isnot [array]) {
                    $allMigrations = @($allMigrations)
                }
            }
        }
        
        # Add new migration record
        $allMigrations += $Metadata
        
        # Save updated migration records
        $allMigrations | ConvertTo-Json -Depth 10 | Set-Content $migrationMetadataPath -Encoding UTF8
        Write-MigrationLog "Migration record saved: $migrationMetadataPath" "SUCCESS"
    }
    catch {
        Write-MigrationLog "Failed to save migration record: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Install WSL distribution from migration package
function Install-WSLMigrationPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackagePath,
        [string]$TargetDistributionName = $null,
        [switch]$Force,
        [switch]$ValidateAfterInstall
    )
    
    try {
        Write-MigrationLog "Installing WSL migration package: $PackagePath" "INFO"
        
        # Check if package exists
        $isCompressed = $false
        $workingPath = $PackagePath
        
        if ($PackagePath.EndsWith('.zip')) {
            if (-not (Test-Path $PackagePath)) {
                throw "Migration package not found: $PackagePath"
            }
            
            # Extract compressed package
            $isCompressed = $true
            $extractPath = Join-Path $env:TEMP "WSL-Migration-$(Get-Random)"
            Write-MigrationLog "Extracting compressed package to: $extractPath" "INFO"
            
            Expand-Archive -Path $PackagePath -DestinationPath $extractPath -Force
            $workingPath = $extractPath
        }
        elseif (-not (Test-Path $PackagePath)) {
            throw "Migration package directory not found: $PackagePath"
        }
        
        # Load migration metadata
        $metadataPath = Join-Path $workingPath "migration-metadata.json"
        if (-not (Test-Path $metadataPath)) {
            throw "Migration metadata not found: $metadataPath"
        }
        
        $metadata = Get-Content $metadataPath | ConvertFrom-Json
        Write-MigrationLog "Loaded migration metadata for: $($metadata.DistributionName)" "INFO"
        
        # Determine target distribution name
        if (-not $TargetDistributionName) {
            $TargetDistributionName = $metadata.DistributionName
        }
        
        Write-MigrationLog "Target distribution name: $TargetDistributionName" "INFO"
        
        # Check if target distribution already exists
        $existingDists = wsl --list --quiet 2>$null
        if ($existingDists -contains $TargetDistributionName -and -not $Force) {
            throw "Distribution '$TargetDistributionName' already exists. Use -Force to overwrite."
        }
        
        # Remove existing distribution if Force is specified
        if ($existingDists -contains $TargetDistributionName -and $Force) {
            Write-MigrationLog "Removing existing distribution: $TargetDistributionName" "WARN"
            wsl --unregister $TargetDistributionName
            
            if ($LASTEXITCODE -ne 0) {
                Write-MigrationLog "Warning: Failed to unregister existing distribution" "WARN"
            }
        }
        
        # Import the distribution
        $backupFile = Join-Path $workingPath $metadata.Files.Backup
        if (-not (Test-Path $backupFile)) {
            throw "Backup file not found: $backupFile"
        }
        
        Write-MigrationLog "Importing distribution from backup: $backupFile" "INFO"
        $installPath = "$env:USERPROFILE\WSL\$TargetDistributionName"
        
        # Ensure install directory exists
        if (-not (Test-Path (Split-Path $installPath -Parent))) {
            New-Item -ItemType Directory -Path (Split-Path $installPath -Parent) -Force | Out-Null
        }
        
        # Import distribution
        wsl --import $TargetDistributionName $installPath $backupFile
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to import distribution"
        }
        
        Write-MigrationLog "Distribution imported successfully" "SUCCESS"
        
        # Apply WSL configuration if exists
        if ($metadata.WSLConfiguration.WSLConfig -and $metadata.WSLConfiguration.WSLConfig.Trim() -ne "") {
            $wslConfigPath = "$env:USERPROFILE\.wslconfig"
            Write-MigrationLog "Applying WSL configuration to: $wslConfigPath" "INFO"
            
            try {
                $metadata.WSLConfiguration.WSLConfig | Set-Content $wslConfigPath -Encoding UTF8
                Write-MigrationLog "WSL configuration applied successfully" "SUCCESS"
            }
            catch {
                Write-MigrationLog "Warning: Failed to apply WSL configuration: $($_.Exception.Message)" "WARN"
            }
        }
        
        # Test distribution startup
        Write-MigrationLog "Testing distribution startup..." "INFO"
        $testResult = wsl -d $TargetDistributionName -- echo "Migration test successful" 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $testResult -eq "Migration test successful") {
            Write-MigrationLog "Distribution startup test passed" "SUCCESS"
        }
        else {
            Write-MigrationLog "Warning: Distribution startup test failed" "WARN"
        }
        
        # Clean up extracted files if package was compressed
        if ($isCompressed -and (Test-Path $extractPath)) {
            try {
                Remove-Item $extractPath -Recurse -Force
                Write-MigrationLog "Cleaned up temporary extraction directory" "INFO"
            }
            catch {
                Write-MigrationLog "Warning: Failed to clean up temporary files: $($_.Exception.Message)" "WARN"
            }
        }
        
        Write-MigrationLog "Migration installation completed successfully!" "SUCCESS"
        
        # Run validation if requested
        $validationResult = $null
        if ($ValidateAfterInstall) {
            Write-MigrationLog "Running post-installation validation..." "INFO"
            $validationResult = Test-WSLMigrationConsistency -DistributionName $TargetDistributionName -OriginalMetadata $metadata
        }
        
        return @{
            Success = $true
            TargetDistributionName = $TargetDistributionName
            InstallPath = $installPath
            OriginalMigrationId = $metadata.MigrationId
            ValidationResult = $validationResult
        }
    }
    catch {
        Write-MigrationLog "Migration installation failed: $($_.Exception.Message)" "ERROR"
        
        # Clean up on failure
        if ($TargetDistributionName) {
            try {
                $existingDists = wsl --list --quiet 2>$null
                if ($existingDists -contains $TargetDistributionName) {
                    Write-MigrationLog "Cleaning up failed installation..." "INFO"
                    wsl --unregister $TargetDistributionName
                }
            }
            catch {
                Write-MigrationLog "Error during cleanup: $($_.Exception.Message)" "WARN"
            }
        }
        
        throw
    }
}

# Batch deployment functionality
function Deploy-WSLMigrationBatch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackagePath,
        [Parameter(Mandatory = $true)]
        [string[]]$TargetComputers,
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Credential,
        [string]$RemotePath = "C:\Temp\WSL-Migration",
        [switch]$ValidateAfterDeploy,
        [int]$MaxConcurrentJobs = 5
    )
    
    try {
        Write-MigrationLog "Starting batch deployment to $($TargetComputers.Count) computers" "INFO"
        
        if (-not (Test-Path $PackagePath)) {
            throw "Migration package not found: $PackagePath"
        }
        
        # Initialize results tracking
        $deploymentResults = @()
        $jobs = @()
        
        # Create deployment script block
        $deploymentScript = {
            param($PackagePath, $RemotePath, $ValidateAfterDeploy)
            
            try {
                # Copy package to remote machine
                $remotePkgPath = Join-Path $RemotePath (Split-Path $PackagePath -Leaf)
                
                if (-not (Test-Path $RemotePath)) {
                    New-Item -ItemType Directory -Path $RemotePath -Force | Out-Null
                }
                
                Copy-Item $PackagePath $remotePkgPath -Force
                
                # Install migration package
                $installResult = & {
                    Import-Module "$PSScriptRoot\WSL-MigrationManager.psm1" -Force
                    Install-WSLMigrationPackage -PackagePath $remotePkgPath -ValidateAfterInstall:$ValidateAfterDeploy
                }
                
                return @{
                    Success = $true
                    Computer = $env:COMPUTERNAME
                    Result = $installResult
                }
            }
            catch {
                return @{
                    Success = $false
                    Computer = $env:COMPUTERNAME
                    Error = $_.Exception.Message
                }
            }
        }
        
        # Start deployment jobs
        foreach ($computer in $TargetComputers) {
            # Wait if we've reached max concurrent jobs
            while ($jobs.Count -ge $MaxConcurrentJobs) {
                $completedJobs = $jobs | Where-Object { $_.State -ne "Running" }
                foreach ($completedJob in $completedJobs) {
                    $result = Receive-Job $completedJob
                    $deploymentResults += $result
                    Remove-Job $completedJob
                    $jobs = $jobs | Where-Object { $_.Id -ne $completedJob.Id }
                    
                    if ($result.Success) {
                        Write-MigrationLog "Deployment completed on $($result.Computer)" "SUCCESS"
                    }
                    else {
                        Write-MigrationLog "Deployment failed on $($result.Computer): $($result.Error)" "ERROR"
                    }
                }
                
                if ($jobs.Count -ge $MaxConcurrentJobs) {
                    Start-Sleep -Seconds 5
                }
            }
            
            # Start new deployment job
            Write-MigrationLog "Starting deployment to: $computer" "INFO"
            
            try {
                $job = Invoke-Command -ComputerName $computer -Credential $Credential -ScriptBlock $deploymentScript -ArgumentList $PackagePath, $RemotePath, $ValidateAfterDeploy -AsJob
                $jobs += $job
            }
            catch {
                Write-MigrationLog "Failed to start deployment job for $computer`: $($_.Exception.Message)" "ERROR"
                $deploymentResults += @{
                    Success = $false
                    Computer = $computer
                    Error = "Failed to start deployment job: $($_.Exception.Message)"
                }
            }
        }
        
        # Wait for remaining jobs to complete
        Write-MigrationLog "Waiting for remaining deployment jobs to complete..." "INFO"
        
        while ($jobs.Count -gt 0) {
            $completedJobs = $jobs | Where-Object { $_.State -ne "Running" }
            foreach ($completedJob in $completedJobs) {
                $result = Receive-Job $completedJob
                $deploymentResults += $result
                Remove-Job $completedJob
                $jobs = $jobs | Where-Object { $_.Id -ne $completedJob.Id }
                
                if ($result.Success) {
                    Write-MigrationLog "Deployment completed on $($result.Computer)" "SUCCESS"
                }
                else {
                    Write-MigrationLog "Deployment failed on $($result.Computer): $($result.Error)" "ERROR"
                }
            }
            
            if ($jobs.Count -gt 0) {
                Start-Sleep -Seconds 5
            }
        }
        
        # Generate deployment summary
        $successCount = ($deploymentResults | Where-Object { $_.Success }).Count
        $failureCount = ($deploymentResults | Where-Object { -not $_.Success }).Count
        
        Write-MigrationLog "Batch deployment completed!" "SUCCESS"
        Write-MigrationLog "Successful deployments: $successCount" "SUCCESS"
        Write-MigrationLog "Failed deployments: $failureCount" "INFO"
        
        return @{
            TotalComputers = $TargetComputers.Count
            SuccessfulDeployments = $successCount
            FailedDeployments = $failureCount
            Results = $deploymentResults
            Summary = @{
                Success = $failureCount -eq 0
                SuccessRate = [math]::Round(($successCount / $TargetComputers.Count) * 100, 2)
            }
        }
    }
    catch {
        Write-MigrationLog "Batch deployment failed: $($_.Exception.Message)" "ERROR"
        
        # Clean up any remaining jobs
        if ($jobs) {
            $jobs | Stop-Job -ErrorAction SilentlyContinue
            $jobs | Remove-Job -ErrorAction SilentlyContinue
        }
        
        throw
    }
}

# Test migration consistency and validation
function Test-WSLMigrationConsistency {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        [hashtable]$OriginalMetadata = $null
    )
    
    try {
        Write-MigrationLog "Validating migrated WSL distribution: $DistributionName" "INFO"
        
        $validationResults = @{
            DistributionExists = $false
            DistributionRunning = $false
            DefaultUserCorrect = $false
            PackagesInstalled = 0
            ServicesRunning = 0
            NetworkConfigValid = $false
            ValidationPassed = $false
            ValidationDetails = @()
        }
        
        # Check if distribution exists
        $distributions = wsl --list --quiet 2>$null
        if ($distributions -contains $DistributionName) {
            $validationResults.DistributionExists = $true
            $validationResults.ValidationDetails += "✓ Distribution exists in WSL"
            Write-MigrationLog "✓ Distribution exists in WSL" "SUCCESS"
        } else {
            $validationResults.ValidationDetails += "✗ Distribution not found in WSL"
            Write-MigrationLog "✗ Distribution not found in WSL" "ERROR"
            return $validationResults
        }
        
        # Check if distribution can start and execute commands
        try {
            $testResult = wsl -d $DistributionName -- echo "test" 2>$null
            if ($LASTEXITCODE -eq 0 -and $testResult -eq "test") {
                $validationResults.DistributionRunning = $true
                $validationResults.ValidationDetails += "✓ Distribution can start and execute commands"
                Write-MigrationLog "✓ Distribution can start and execute commands" "SUCCESS"
            } else {
                $validationResults.ValidationDetails += "✗ Distribution cannot start or execute commands"
                Write-MigrationLog "✗ Distribution cannot start or execute commands" "ERROR"
            }
        }
        catch {
            $validationResults.ValidationDetails += "✗ Error testing distribution startup: $($_.Exception.Message)"
            Write-MigrationLog "✗ Error testing distribution startup: $($_.Exception.Message)" "ERROR"
        }
        
        # If original metadata is provided, perform detailed comparison
        if ($OriginalMetadata) {
            # Check default user
            try {
                $currentUser = wsl -d $DistributionName -- whoami 2>$null
                if ($LASTEXITCODE -eq 0 -and $currentUser.Trim() -eq $OriginalMetadata.WSLConfiguration.DefaultUser) {
                    $validationResults.DefaultUserCorrect = $true
                    $validationResults.ValidationDetails += "✓ Default user matches original: $($currentUser.Trim())"
                    Write-MigrationLog "✓ Default user matches original: $($currentUser.Trim())" "SUCCESS"
                } else {
                    $validationResults.ValidationDetails += "✗ Default user mismatch. Expected: $($OriginalMetadata.WSLConfiguration.DefaultUser), Got: $($currentUser.Trim())"
                    Write-MigrationLog "✗ Default user mismatch. Expected: $($OriginalMetadata.WSLConfiguration.DefaultUser), Got: $($currentUser.Trim())" "WARN"
                }
            }
            catch {
                $validationResults.ValidationDetails += "✗ Error checking default user: $($_.Exception.Message)"
                Write-MigrationLog "✗ Error checking default user: $($_.Exception.Message)" "ERROR"
            }
            
            # Check installed packages (sample check)
            try {
                $currentPackages = wsl -d $DistributionName -- bash -c "dpkg -l 2>/dev/null | grep '^ii' | wc -l" 2>$null
                if ($LASTEXITCODE -eq 0 -and $currentPackages) {
                    $validationResults.PackagesInstalled = [int]$currentPackages.Trim()
                    $originalCount = $OriginalMetadata.WSLConfiguration.InstalledPackages.Count
                    $validationResults.ValidationDetails += "✓ Packages installed: $($validationResults.PackagesInstalled) (original: $originalCount)"
                    Write-MigrationLog "✓ Packages installed: $($validationResults.PackagesInstalled) (original: $originalCount)" "SUCCESS"
                }
            }
            catch {
                $validationResults.ValidationDetails += "✗ Error checking installed packages: $($_.Exception.Message)"
                Write-MigrationLog "✗ Error checking installed packages: $($_.Exception.Message)" "ERROR"
            }
            
            # Check network configuration
            try {
                $networkTest = wsl -d $DistributionName -- ping -c 1 8.8.8.8 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $validationResults.NetworkConfigValid = $true
                    $validationResults.ValidationDetails += "✓ Network connectivity test passed"
                    Write-MigrationLog "✓ Network connectivity test passed" "SUCCESS"
                } else {
                    $validationResults.ValidationDetails += "✗ Network connectivity test failed"
                    Write-MigrationLog "✗ Network connectivity test failed" "WARN"
                }
            }
            catch {
                $validationResults.ValidationDetails += "✗ Error testing network connectivity: $($_.Exception.Message)"
                Write-MigrationLog "✗ Error testing network connectivity: $($_.Exception.Message)" "ERROR"
            }
        }
        
        # Overall validation result
        $validationResults.ValidationPassed = $validationResults.DistributionExists -and $validationResults.DistributionRunning
        
        if ($validationResults.ValidationPassed) {
            Write-MigrationLog "✓ Migration validation PASSED" "SUCCESS"
        } else {
            Write-MigrationLog "✗ Migration validation FAILED" "ERROR"
        }
        
        return $validationResults
    }
    catch {
        Write-MigrationLog "Validation error: $($_.Exception.Message)" "ERROR"
        return @{ 
            ValidationPassed = $false
            Error = $_.Exception.Message
            ValidationDetails = @("✗ Validation error: $($_.Exception.Message)")
        }
    }
}

# Get migration history and records
function Get-WSLMigrationHistory {
    param(
        [string]$DistributionName = $null,
        [string]$SourceComputer = $null
    )
    
    try {
        $migrationMetadataPath = Join-Path $script:MigrationBasePath $script:MigrationMetadataFileName
        if (-not (Test-Path $migrationMetadataPath)) {
            Write-MigrationLog "Migration history file not found" "WARN"
            return @()
        }
        
        $allMigrations = Get-Content $migrationMetadataPath | ConvertFrom-Json
        if ($allMigrations -isnot [array]) {
            $allMigrations = @($allMigrations)
        }
        
        # Filter migration history
        $filteredMigrations = $allMigrations
        
        if ($DistributionName) {
            $filteredMigrations = $filteredMigrations | Where-Object { $_.DistributionName -eq $DistributionName }
        }
        
        if ($SourceComputer) {
            $filteredMigrations = $filteredMigrations | Where-Object { $_.SourceComputer -eq $SourceComputer }
        }
        
        # Sort by creation time
        $sortedMigrations = $filteredMigrations | Sort-Object { [datetime]::ParseExact($_.CreatedDate, "yyyy-MM-dd HH:mm:ss", $null) } -Descending
        
        return $sortedMigrations
    }
    catch {
        Write-MigrationLog "Failed to get migration history: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-SystemEnvironmentInfo',
    'Get-WSLConfigurationForMigration',
    'New-WSLMigrationPackage',
    'Install-WSLMigrationPackage', 
    'Deploy-WSLMigrationBatch',
    'Test-WSLMigrationConsistency',
    'Get-WSLMigrationHistory'
)