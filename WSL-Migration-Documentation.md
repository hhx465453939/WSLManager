# WSL Migration Manager Documentation

## Overview

The WSL Migration Manager provides comprehensive functionality for cross-machine environment packaging, transfer, batch deployment, and migration validation. This module implements requirement 5 (WSL环境迁移和部署) from the WSL operations management system.

## Features

### 1. Cross-Machine Environment Packaging (需求 5.1)
- Creates portable WSL environment packages
- Includes complete distribution backup
- Captures system configuration and metadata
- Generates installation and validation scripts
- Supports compressed package format

### 2. Automatic Environment Reconstruction (需求 5.2)
- Imports WSL distributions from migration packages
- Restores configuration settings
- Maintains file permissions and user settings
- Validates successful migration

### 3. Batch Deployment Support (需求 5.4)
- Deploys to multiple target machines simultaneously
- Supports concurrent deployment jobs
- Provides deployment progress monitoring
- Generates deployment summary reports

### 4. Migration Consistency Validation (需求 5.5)
- Verifies distribution functionality
- Compares with original configuration
- Tests network connectivity
- Validates installed packages and services

## Functions

### Get-SystemEnvironmentInfo
Collects comprehensive system environment information for migration metadata.

**Returns:**
- Computer name and user information
- Operating system version and build
- Hardware specifications (memory, processor)
- WSL and PowerShell versions

### Get-WSLConfigurationForMigration
Extracts WSL distribution configuration for migration packaging.

**Parameters:**
- `DistributionName` (required): Name of the WSL distribution

**Returns:**
- Distribution configuration
- Default user information
- Environment variables
- Installed packages list
- Running services
- Network configuration

### New-WSLMigrationPackage
Creates a portable migration package for WSL distribution.

**Parameters:**
- `DistributionName` (required): Name of the distribution to package
- `OutputPath` (optional): Custom output path for the package
- `IncludeSystemInfo` (switch): Include system environment information
- `Compress` (switch): Create compressed package (default: true)

**Returns:**
- Migration ID
- Package path and compressed path
- Package size and metadata

**Example:**
```powershell
$package = New-WSLMigrationPackage -DistributionName "Ubuntu-20.04" -IncludeSystemInfo -Compress
Write-Host "Migration package created: $($package.PackagePath)"
```

### Install-WSLMigrationPackage
Installs WSL distribution from migration package.

**Parameters:**
- `PackagePath` (required): Path to migration package (directory or .zip file)
- `TargetDistributionName` (optional): Name for the new distribution
- `Force` (switch): Overwrite existing distribution
- `ValidateAfterInstall` (switch): Run validation after installation

**Returns:**
- Installation success status
- Target distribution name
- Installation path
- Validation results (if requested)

**Example:**
```powershell
$result = Install-WSLMigrationPackage -PackagePath "C:\Migrations\Ubuntu-migration.zip" -ValidateAfterInstall
if ($result.Success) {
    Write-Host "Migration installed successfully: $($result.TargetDistributionName)"
}
```

### Deploy-WSLMigrationBatch
Deploys migration package to multiple target computers.

**Parameters:**
- `PackagePath` (required): Path to migration package
- `TargetComputers` (required): Array of target computer names
- `Credential` (required): Credentials for remote access
- `RemotePath` (optional): Remote path for package deployment
- `ValidateAfterDeploy` (switch): Validate after deployment
- `MaxConcurrentJobs` (optional): Maximum concurrent deployment jobs (default: 5)

**Returns:**
- Deployment summary with success/failure counts
- Detailed results for each target computer
- Success rate percentage

**Example:**
```powershell
$cred = Get-Credential
$targets = @("Server01", "Server02", "Server03")
$result = Deploy-WSLMigrationBatch -PackagePath "C:\Migration.zip" -TargetComputers $targets -Credential $cred
Write-Host "Deployment success rate: $($result.Summary.SuccessRate)%"
```

### Test-WSLMigrationConsistency
Validates migrated WSL distribution consistency.

**Parameters:**
- `DistributionName` (required): Name of the distribution to validate
- `OriginalMetadata` (optional): Original migration metadata for comparison

**Returns:**
- Validation status (passed/failed)
- Detailed validation results
- Comparison with original configuration (if metadata provided)

**Example:**
```powershell
$validation = Test-WSLMigrationConsistency -DistributionName "Ubuntu-Migrated"
if ($validation.ValidationPassed) {
    Write-Host "Migration validation passed"
    $validation.ValidationDetails | ForEach-Object { Write-Host "  $_" }
}
```

### Get-WSLMigrationHistory
Retrieves migration history and records.

**Parameters:**
- `DistributionName` (optional): Filter by distribution name
- `SourceComputer` (optional): Filter by source computer

**Returns:**
- Array of migration records
- Sorted by creation date (newest first)

**Example:**
```powershell
$history = Get-WSLMigrationHistory -DistributionName "Ubuntu-20.04"
$history | ForEach-Object {
    Write-Host "Migration: $($_.MigrationId) from $($_.SourceComputer) on $($_.CreatedDate)"
}
```

## Migration Package Structure

Each migration package contains:

```
migration-package/
├── [DistributionName].tar          # Complete WSL distribution backup
├── migration-metadata.json        # Migration metadata and configuration
├── install-migration.ps1          # Installation script
├── validate-migration.ps1         # Validation script
└── README.md                       # Installation instructions
```

### Migration Metadata Format

```json
{
  "MigrationId": "guid",
  "DistributionName": "string",
  "CreatedDate": "yyyy-MM-dd HH:mm:ss",
  "CreatedBy": "username",
  "SourceComputer": "computername",
  "PackageVersion": "1.0.0",
  "BackupInfo": {
    "BackupId": "guid",
    "Size": "number (MB)",
    "Checksum": "SHA256 hash"
  },
  "WSLConfiguration": {
    "DefaultUser": "username",
    "WSLConfig": "wslconfig content",
    "EnvironmentVariables": [],
    "InstalledPackages": [],
    "Services": [],
    "NetworkConfig": {}
  },
  "SystemInfo": {
    "ComputerName": "string",
    "OSVersion": "string",
    "TotalMemoryGB": "number",
    "ProcessorName": "string"
  }
}
```

## Usage Scenarios

### Scenario 1: Single Machine Migration
```powershell
# On source machine
$package = New-WSLMigrationPackage -DistributionName "Ubuntu-Dev" -IncludeSystemInfo -Compress

# Transfer package to target machine
# On target machine
Install-WSLMigrationPackage -PackagePath "Ubuntu-Dev-migration.zip" -ValidateAfterInstall
```

### Scenario 2: Batch Deployment
```powershell
# Create migration package
$package = New-WSLMigrationPackage -DistributionName "Ubuntu-Production" -Compress

# Deploy to multiple servers
$servers = @("WebServer01", "WebServer02", "WebServer03")
$cred = Get-Credential
$deployment = Deploy-WSLMigrationBatch -PackagePath $package.CompressedPath -TargetComputers $servers -Credential $cred -ValidateAfterDeploy

# Check deployment results
Write-Host "Successful deployments: $($deployment.SuccessfulDeployments)/$($deployment.TotalComputers)"
```

### Scenario 3: Migration Validation
```powershell
# Validate existing distribution
$validation = Test-WSLMigrationConsistency -DistributionName "Ubuntu-Migrated"

# Display validation results
$validation.ValidationDetails | ForEach-Object {
    $color = if ($_ -like "*✓*") { "Green" } else { "Red" }
    Write-Host $_ -ForegroundColor $color
}
```

## Requirements Mapping

| Requirement | Implementation | Function |
|-------------|----------------|----------|
| 5.1 - Portable environment packages | Complete distribution backup with metadata | `New-WSLMigrationPackage` |
| 5.2 - Automatic environment reconstruction | Import and configuration restoration | `Install-WSLMigrationPackage` |
| 5.3 - File permissions and user config preservation | Maintained through WSL export/import | Built into WSL commands |
| 5.4 - Batch deployment support | Concurrent deployment to multiple machines | `Deploy-WSLMigrationBatch` |
| 5.5 - Migration consistency validation | Comprehensive validation and comparison | `Test-WSLMigrationConsistency` |

## Error Handling

The migration manager includes comprehensive error handling:

- **Package Creation Errors**: Backup failures, insufficient disk space, permission issues
- **Installation Errors**: Invalid packages, existing distributions, import failures
- **Deployment Errors**: Network connectivity, authentication, remote execution failures
- **Validation Errors**: Distribution startup issues, configuration mismatches

All errors are logged with detailed messages and suggested resolutions.

## Logging

Migration operations are logged to:
- **Log File**: `%USERPROFILE%\WSL-Migrations\migration.log`
- **Console Output**: Color-coded status messages
- **Event Details**: Timestamps, operation details, error messages

## Testing

Use the provided test scripts to verify functionality:

- `Test-MigrationFunctionality.ps1`: Basic functionality tests (no WSL required)
- `Test-MigrationSimple.ps1`: Simple migration tests (requires WSL distribution)
- `Test-WSLMigration.ps1`: Comprehensive test suite

## Prerequisites

- Windows 10/11 with WSL2 enabled
- PowerShell 5.1 or later
- Administrator privileges for installation operations
- Sufficient disk space for backup creation
- Network connectivity for batch deployments

## Best Practices

1. **Always validate migrations** after installation
2. **Test packages** on non-production systems first
3. **Monitor disk space** during package creation
4. **Use compressed packages** for network transfers
5. **Keep migration history** for audit purposes
6. **Backup critical data** before migration operations

## Troubleshooting

### Common Issues

1. **"Distribution not found"**: Ensure WSL distribution exists and is accessible
2. **"Package creation failed"**: Check disk space and WSL service status
3. **"Installation failed"**: Verify package integrity and target system compatibility
4. **"Validation failed"**: Check distribution startup and network connectivity

### Debug Steps

1. Check WSL status: `wsl --status`
2. Verify distribution list: `wsl --list --verbose`
3. Review migration logs in `%USERPROFILE%\WSL-Migrations\migration.log`
4. Test basic WSL functionality: `wsl --distribution [name] -- echo "test"`

## Support

For issues and questions:
1. Check the migration log files
2. Run the test scripts to verify functionality
3. Review the troubleshooting section
4. Ensure all prerequisites are met