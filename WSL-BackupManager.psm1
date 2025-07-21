# WSL Backup Management Module
# Provides full backup, incremental backup and metadata management for WSL distributions

# Import required modules
if (Get-Module WSL-Detection) { Remove-Module WSL-Detection }
Import-Module "$PSScriptRoot\WSL-Detection.psm1" -Force

# Global variables
$script:BackupBasePath = "$env:USERPROFILE\WSL-Backups"
$script:MetadataFileName = "backup-metadata.json"
$script:LogFile = "$script:BackupBasePath\backup.log"

# Ensure backup directory exists
function Initialize-BackupDirectory {
    if (-not (Test-Path $script:BackupBasePath)) {
        New-Item -ItemType Directory -Path $script:BackupBasePath -Force | Out-Null
        Write-Host "Created backup directory: $script:BackupBasePath" -ForegroundColor Green
    }
}

# Write log
function Write-BackupLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Ensure log directory exists
    $logDir = Split-Path $script:LogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    Add-Content -Path $script:LogFile -Value $logEntry
    
    # Display different colors based on level
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARN" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry -ForegroundColor White }
    }
}

# Get distribution information
function Get-WSLDistributionInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName
    )
    
    try {
        # Check if distribution exists
        $distributions = wsl --list --verbose 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to get WSL distribution list"
        }
        
        $distExists = $distributions | Where-Object { $_ -match $DistributionName }
        if (-not $distExists) {
            throw "Distribution '$DistributionName' does not exist"
        }
        
        # Get distribution status
        $status = "Stopped"
        if ($distributions | Where-Object { $_ -match $DistributionName -and $_ -match "Running" }) {
            $status = "Running"
        }
        
        # Get distribution version information
        $versionInfo = wsl -d $DistributionName -- cat /etc/os-release 2>$null
        $version = "Unknown"
        if ($LASTEXITCODE -eq 0 -and $versionInfo) {
            $versionLine = $versionInfo | Where-Object { $_ -match "PRETTY_NAME=" }
            if ($versionLine) {
                $version = ($versionLine -split '=')[1] -replace '"', ''
            }
        }
        
        # Get disk usage information
        $diskUsage = wsl -d $DistributionName -- df -h / 2>$null
        $usedSpace = "Unknown"
        if ($LASTEXITCODE -eq 0 -and $diskUsage) {
            $diskLine = $diskUsage | Select-Object -Skip 1 | Select-Object -First 1
            if ($diskLine) {
                $usedSpace = ($diskLine -split '\s+')[2]
            }
        }
        
        return @{
            Name = $DistributionName
            Status = $status
            Version = $version
            UsedSpace = $usedSpace
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    catch {
        Write-BackupLog "Failed to get distribution info: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Create backup metadata
function New-BackupMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DistributionInfo,
        [Parameter(Mandatory = $true)]
        [string]$BackupPath,
        [Parameter(Mandatory = $true)]
        [string]$BackupType,
        [string]$ParentBackupId = $null
    )
    
    $backupId = [System.Guid]::NewGuid().ToString()
    $backupFile = Get-Item $BackupPath
    
    # Calculate file checksum
    Write-BackupLog "Calculating backup file checksum..." "INFO"
    $hash = Get-FileHash -Path $BackupPath -Algorithm SHA256
    
    $metadata = @{
        BackupId = $backupId
        DistributionName = $DistributionInfo.Name
        BackupType = $BackupType
        BackupPath = $BackupPath
        CreatedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Size = [math]::Round($backupFile.Length / 1MB, 2)
        SizeBytes = $backupFile.Length
        Checksum = $hash.Hash
        Algorithm = "SHA256"
        ParentBackupId = $ParentBackupId
        DistributionInfo = $DistributionInfo
        Metadata = @{
            Version = $DistributionInfo.Version
            OriginalSize = $DistributionInfo.UsedSpace
            BackupTool = "WSL-BackupManager"
            ToolVersion = "1.0.0"
        }
    }
    
    return $metadata
}

# Save backup metadata
function Save-BackupMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Metadata
    )
    
    try {
        $metadataPath = Join-Path $script:BackupBasePath $script:MetadataFileName
        
        # Read existing metadata
        $allMetadata = @()
        if (Test-Path $metadataPath) {
            $existingContent = Get-Content $metadataPath -Raw -ErrorAction SilentlyContinue
            if ($existingContent) {
                $allMetadata = $existingContent | ConvertFrom-Json
                if ($allMetadata -isnot [array]) {
                    $allMetadata = @($allMetadata)
                }
            }
        }
        
        # Add new metadata
        $allMetadata += $Metadata
        
        # Save updated metadata
        $allMetadata | ConvertTo-Json -Depth 10 | Set-Content $metadataPath -Encoding UTF8
        Write-BackupLog "Backup metadata saved: $metadataPath" "SUCCESS"
        
        return $Metadata.BackupId
    }
    catch {
        Write-BackupLog "Failed to save backup metadata: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Verify backup file integrity
function Test-BackupIntegrity {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupPath,
        [Parameter(Mandatory = $true)]
        [string]$ExpectedChecksum
    )
    
    try {
        if (-not (Test-Path $BackupPath)) {
            Write-BackupLog "Backup file does not exist: $BackupPath" "ERROR"
            return $false
        }
        
        Write-BackupLog "Verifying backup file integrity..." "INFO"
        $actualHash = Get-FileHash -Path $BackupPath -Algorithm SHA256
        
        if ($actualHash.Hash -eq $ExpectedChecksum) {
            Write-BackupLog "Backup file integrity verification passed" "SUCCESS"
            return $true
        }
        else {
            Write-BackupLog "Backup file integrity verification failed" "ERROR"
            Write-BackupLog "Expected checksum: $ExpectedChecksum" "ERROR"
            Write-BackupLog "Actual checksum: $($actualHash.Hash)" "ERROR"
            return $false
        }
    }
    catch {
        Write-BackupLog "Error verifying backup file integrity: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Execute full backup
function New-WSLFullBackup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        [string]$BackupPath = $null,
        [switch]$Compress
    )
    
    try {
        Initialize-BackupDirectory
        
        Write-BackupLog "Starting full backup of distribution: $DistributionName" "INFO"
        
        # Get distribution information
        $distInfo = Get-WSLDistributionInfo -DistributionName $DistributionName
        Write-BackupLog "Distribution info: $($distInfo.Version), Used space: $($distInfo.UsedSpace)" "INFO"
        
        # Generate backup file name
        if (-not $BackupPath) {
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $fileName = "${DistributionName}-full-${timestamp}.tar"
            if ($Compress) {
                $fileName += ".gz"
            }
            $BackupPath = Join-Path $script:BackupBasePath $fileName
        }
        
        # Ensure backup directory exists
        $backupDir = Split-Path $BackupPath -Parent
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        
        Write-BackupLog "Backup file path: $BackupPath" "INFO"
        
        # Execute WSL export
        Write-BackupLog "Exporting WSL distribution..." "INFO"
        $exportArgs = @("--export", $DistributionName, $BackupPath)
        
        $process = Start-Process -FilePath "wsl" -ArgumentList $exportArgs -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -ne 0) {
            throw "WSL export failed, exit code: $($process.ExitCode)"
        }
        
        # Verify backup file was created successfully
        if (-not (Test-Path $BackupPath)) {
            throw "Backup file not created: $BackupPath"
        }
        
        $backupFile = Get-Item $BackupPath
        Write-BackupLog "Backup completed, file size: $([math]::Round($backupFile.Length / 1MB, 2)) MB" "SUCCESS"
        
        # Create and save metadata
        $metadata = New-BackupMetadata -DistributionInfo $distInfo -BackupPath $BackupPath -BackupType "Full"
        $backupId = Save-BackupMetadata -Metadata $metadata
        
        # Verify backup integrity
        if (Test-BackupIntegrity -BackupPath $BackupPath -ExpectedChecksum $metadata.Checksum) {
            Write-BackupLog "Full backup completed successfully, backup ID: $backupId" "SUCCESS"
            return @{
                BackupId = $backupId
                BackupPath = $BackupPath
                Size = $metadata.Size
                Checksum = $metadata.Checksum
            }
        }
        else {
            throw "Backup file integrity verification failed"
        }
    }
    catch {
        Write-BackupLog "Full backup failed: $($_.Exception.Message)" "ERROR"
        
        # Clean up failed backup file
        if ($BackupPath -and (Test-Path $BackupPath)) {
            try {
                Remove-Item $BackupPath -Force
                Write-BackupLog "Cleaned up failed backup file: $BackupPath" "INFO"
            }
            catch {
                Write-BackupLog "Error cleaning up failed backup file: $($_.Exception.Message)" "WARN"
            }
        }
        
        throw
    }
}

# Get file changes information (for incremental backup)
function Get-FileChanges {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        [Parameter(Mandatory = $true)]
        [datetime]$SinceDate
    )
    
    try {
        Write-BackupLog "Detecting file changes since $SinceDate..." "INFO"
        
        # Convert date to Unix timestamp
        $unixTimestamp = [int][double]::Parse((Get-Date $SinceDate -UFormat %s))
        
        # Find modified files in WSL
        $findCommand = "find / -type f -newer /tmp/backup_reference_$unixTimestamp 2>/dev/null | head -10000"
        
        # Create reference file
        $touchCommand = "touch -t $(Get-Date $SinceDate -Format 'yyyyMMddHHmm') /tmp/backup_reference_$unixTimestamp"
        wsl -d $DistributionName -- bash -c $touchCommand 2>$null
        
        # Find changed files
        $changedFiles = wsl -d $DistributionName -- bash -c $findCommand 2>$null
        
        # Clean up reference file
        wsl -d $DistributionName -- rm -f "/tmp/backup_reference_$unixTimestamp" 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $changedFiles) {
            $fileList = $changedFiles | Where-Object { $_ -and $_.Trim() -ne "" }
            Write-BackupLog "Found $($fileList.Count) changed files" "INFO"
            return $fileList
        }
        else {
            Write-BackupLog "No file changes detected" "INFO"
            return @()
        }
    }
    catch {
        Write-BackupLog "Failed to detect file changes: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

# Create incremental backup
function New-WSLIncrementalBackup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        [Parameter(Mandatory = $true)]
        [string]$ParentBackupId,
        [string]$BackupPath = $null
    )
    
    try {
        Initialize-BackupDirectory
        
        Write-BackupLog "Starting incremental backup of distribution: $DistributionName" "INFO"
        
        # Get parent backup information
        $metadataPath = Join-Path $script:BackupBasePath $script:MetadataFileName
        if (-not (Test-Path $metadataPath)) {
            throw "Backup metadata file not found"
        }
        
        $allMetadata = Get-Content $metadataPath | ConvertFrom-Json
        if ($allMetadata -isnot [array]) {
            $allMetadata = @($allMetadata)
        }
        
        $parentBackup = $allMetadata | Where-Object { $_.BackupId -eq $ParentBackupId }
        if (-not $parentBackup) {
            throw "Parent backup ID not found: $ParentBackupId"
        }
        
        Write-BackupLog "Parent backup info: $($parentBackup.BackupType), Created: $($parentBackup.CreatedDate)" "INFO"
        
        # Get distribution information
        $distInfo = Get-WSLDistributionInfo -DistributionName $DistributionName
        
        # Detect file changes
        $parentDate = [datetime]::ParseExact($parentBackup.CreatedDate, "yyyy-MM-dd HH:mm:ss", $null)
        $changedFiles = Get-FileChanges -DistributionName $DistributionName -SinceDate $parentDate
        
        if ($changedFiles.Count -eq 0) {
            Write-BackupLog "No file changes detected, skipping incremental backup" "INFO"
            return $null
        }
        
        # Generate backup file name
        if (-not $BackupPath) {
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $fileName = "${DistributionName}-incremental-${timestamp}.tar.gz"
            $BackupPath = Join-Path $script:BackupBasePath $fileName
        }
        
        Write-BackupLog "Incremental backup file path: $BackupPath" "INFO"
        
        # Create changed files list
        $fileListPath = Join-Path $env:TEMP "wsl_incremental_files_$(Get-Random).txt"
        $changedFiles | Out-File -FilePath $fileListPath -Encoding UTF8
        
        try {
            # Create incremental backup in WSL
            $tarCommand = "tar -czf /mnt/c/temp/incremental_backup.tar.gz -T /mnt/c/temp/file_list.txt 2>/dev/null"
            
            # Copy file list to WSL accessible location
            $wslFileListPath = $fileListPath -replace '\\', '/' -replace 'C:', '/mnt/c'
            $wslBackupPath = $BackupPath -replace '\\', '/' -replace 'C:', '/mnt/c'
            
            # Execute tar command to create incremental backup
            $result = wsl -d $DistributionName -- bash -c "tar -czf '$wslBackupPath' -T '$wslFileListPath' 2>/dev/null"
            
            if ($LASTEXITCODE -ne 0) {
                # If tar fails, try full backup as fallback
                Write-BackupLog "Incremental backup failed, performing full backup as fallback" "WARN"
                return New-WSLFullBackup -DistributionName $DistributionName -BackupPath $BackupPath -Compress
            }
            
            # Verify backup file was created successfully
            if (-not (Test-Path $BackupPath)) {
                throw "Incremental backup file not created: $BackupPath"
            }
            
            $backupFile = Get-Item $BackupPath
            Write-BackupLog "Incremental backup completed, file size: $([math]::Round($backupFile.Length / 1MB, 2)) MB" "SUCCESS"
            
            # Create and save metadata
            $metadata = New-BackupMetadata -DistributionInfo $distInfo -BackupPath $BackupPath -BackupType "Incremental" -ParentBackupId $ParentBackupId
            $metadata.ChangedFiles = $changedFiles
            $metadata.ChangedFileCount = $changedFiles.Count
            
            $backupId = Save-BackupMetadata -Metadata $metadata
            
            # Verify backup integrity
            if (Test-BackupIntegrity -BackupPath $BackupPath -ExpectedChecksum $metadata.Checksum) {
                Write-BackupLog "Incremental backup completed successfully, backup ID: $backupId" "SUCCESS"
                return @{
                    BackupId = $backupId
                    BackupPath = $BackupPath
                    Size = $metadata.Size
                    Checksum = $metadata.Checksum
                    ChangedFileCount = $changedFiles.Count
                    ParentBackupId = $ParentBackupId
                }
            }
            else {
                throw "Incremental backup file integrity verification failed"
            }
        }
        finally {
            # Clean up temporary files
            if (Test-Path $fileListPath) {
                Remove-Item $fileListPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Write-BackupLog "Incremental backup failed: $($_.Exception.Message)" "ERROR"
        
        # Clean up failed backup file
        if ($BackupPath -and (Test-Path $BackupPath)) {
            try {
                Remove-Item $BackupPath -Force
                Write-BackupLog "Cleaned up failed incremental backup file: $BackupPath" "INFO"
            }
            catch {
                Write-BackupLog "Error cleaning up failed incremental backup file: $($_.Exception.Message)" "WARN"
            }
        }
        
        throw
    }
}

# Get backup list
function Get-WSLBackupList {
    param(
        [string]$DistributionName = $null,
        [string]$BackupType = $null
    )
    
    try {
        $metadataPath = Join-Path $script:BackupBasePath $script:MetadataFileName
        if (-not (Test-Path $metadataPath)) {
            Write-BackupLog "Backup metadata file not found" "WARN"
            return @()
        }
        
        $allMetadata = Get-Content $metadataPath | ConvertFrom-Json
        if ($allMetadata -isnot [array]) {
            $allMetadata = @($allMetadata)
        }
        
        # Filter backup list
        $filteredBackups = $allMetadata
        
        if ($DistributionName) {
            $filteredBackups = $filteredBackups | Where-Object { $_.DistributionName -eq $DistributionName }
        }
        
        if ($BackupType) {
            $filteredBackups = $filteredBackups | Where-Object { $_.BackupType -eq $BackupType }
        }
        
        # Sort by creation time
        $sortedBackups = $filteredBackups | Sort-Object { [datetime]::ParseExact($_.CreatedDate, "yyyy-MM-dd HH:mm:ss", $null) } -Descending
        
        return $sortedBackups
    }
    catch {
        Write-BackupLog "Failed to get backup list: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

# Remove backup
function Remove-WSLBackup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupId,
        [switch]$Force
    )
    
    try {
        $metadataPath = Join-Path $script:BackupBasePath $script:MetadataFileName
        if (-not (Test-Path $metadataPath)) {
            throw "Backup metadata file not found"
        }
        
        $allMetadata = Get-Content $metadataPath | ConvertFrom-Json
        if ($allMetadata -isnot [array]) {
            $allMetadata = @($allMetadata)
        }
        
        $backupToDelete = $allMetadata | Where-Object { $_.BackupId -eq $BackupId }
        if (-not $backupToDelete) {
            throw "Backup ID not found: $BackupId"
        }
        
        # Check for dependent incremental backups
        $dependentBackups = $allMetadata | Where-Object { $_.ParentBackupId -eq $BackupId }
        if ($dependentBackups -and -not $Force) {
            $dependentIds = $dependentBackups | ForEach-Object { $_.BackupId }
            throw "Dependent incremental backups exist: $($dependentIds -join ', '). Use -Force parameter to force deletion."
        }
        
        # Delete backup file
        if (Test-Path $backupToDelete.BackupPath) {
            Remove-Item $backupToDelete.BackupPath -Force
            Write-BackupLog "Deleted backup file: $($backupToDelete.BackupPath)" "INFO"
        }
        
        # Remove from metadata
        $updatedMetadata = $allMetadata | Where-Object { $_.BackupId -ne $BackupId }
        
        # If force delete, also delete dependent incremental backups
        if ($Force -and $dependentBackups) {
            foreach ($dependent in $dependentBackups) {
                if (Test-Path $dependent.BackupPath) {
                    Remove-Item $dependent.BackupPath -Force
                    Write-BackupLog "Deleted dependent backup file: $($dependent.BackupPath)" "INFO"
                }
                $updatedMetadata = $updatedMetadata | Where-Object { $_.BackupId -ne $dependent.BackupId }
            }
        }
        
        # Save updated metadata
        if ($updatedMetadata.Count -gt 0) {
            $updatedMetadata | ConvertTo-Json -Depth 10 | Set-Content $metadataPath -Encoding UTF8
        }
        else {
            # If no backups left, delete metadata file
            Remove-Item $metadataPath -Force
        }
        
        Write-BackupLog "Backup deletion successful: $BackupId" "SUCCESS"
    }
    catch {
        Write-BackupLog "Backup deletion failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Validate backup file format and structure
function Test-BackupFileFormat {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupPath
    )
    
    try {
        if (-not (Test-Path $BackupPath)) {
            Write-BackupLog "Backup file does not exist: $BackupPath" "ERROR"
            return $false
        }
        
        $backupFile = Get-Item $BackupPath
        Write-BackupLog "Validating backup file format: $($backupFile.Name)" "INFO"
        
        # Check file extension
        $validExtensions = @('.tar', '.tar.gz', '.tgz')
        $hasValidExtension = $validExtensions | Where-Object { $BackupPath.EndsWith($_) }
        
        if (-not $hasValidExtension) {
            Write-BackupLog "Invalid backup file extension. Expected: $($validExtensions -join ', ')" "ERROR"
            return $false
        }
        
        # Check if file is a valid tar archive
        try {
            if ($BackupPath.EndsWith('.gz') -or $BackupPath.EndsWith('.tgz')) {
                # Test gzipped tar file
                $testResult = & tar -tzf $BackupPath 2>$null | Select-Object -First 1
            }
            else {
                # Test regular tar file
                $testResult = & tar -tf $BackupPath 2>$null | Select-Object -First 1
            }
            
            if ($LASTEXITCODE -ne 0 -or -not $testResult) {
                Write-BackupLog "Backup file is not a valid tar archive" "ERROR"
                return $false
            }
        }
        catch {
            Write-BackupLog "Error testing tar archive: $($_.Exception.Message)" "ERROR"
            return $false
        }
        
        Write-BackupLog "Backup file format validation passed" "SUCCESS"
        return $true
    }
    catch {
        Write-BackupLog "Error validating backup file format: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Get backup metadata by backup ID or file path
function Get-BackupMetadata {
    param(
        [string]$BackupId = $null,
        [string]$BackupPath = $null
    )
    
    try {
        if (-not $BackupId -and -not $BackupPath) {
            throw "Either BackupId or BackupPath must be specified"
        }
        
        $metadataPath = Join-Path $script:BackupBasePath $script:MetadataFileName
        if (-not (Test-Path $metadataPath)) {
            Write-BackupLog "Backup metadata file not found" "WARN"
            return $null
        }
        
        $allMetadata = Get-Content $metadataPath | ConvertFrom-Json
        if ($allMetadata -isnot [array]) {
            $allMetadata = @($allMetadata)
        }
        
        if ($BackupId) {
            return $allMetadata | Where-Object { $_.BackupId -eq $BackupId }
        }
        elseif ($BackupPath) {
            return $allMetadata | Where-Object { $_.BackupPath -eq $BackupPath }
        }
    }
    catch {
        Write-BackupLog "Failed to get backup metadata: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# Validate backup file before restoration
function Test-BackupForRestore {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupPath,
        [string]$ExpectedChecksum = $null
    )
    
    try {
        Write-BackupLog "Validating backup file for restoration: $BackupPath" "INFO"
        
        # Check if backup file exists
        if (-not (Test-Path $BackupPath)) {
            Write-BackupLog "Backup file does not exist: $BackupPath" "ERROR"
            return $false
        }
        
        # Validate file format
        if (-not (Test-BackupFileFormat -BackupPath $BackupPath)) {
            return $false
        }
        
        # Verify checksum if provided
        if ($ExpectedChecksum) {
            if (-not (Test-BackupIntegrity -BackupPath $BackupPath -ExpectedChecksum $ExpectedChecksum)) {
                return $false
            }
        }
        
        # Check file size (minimum 1MB for a valid WSL backup)
        $backupFile = Get-Item $BackupPath
        if ($backupFile.Length -lt 1MB) {
            Write-BackupLog "Backup file appears to be too small (less than 1MB)" "WARN"
        }
        
        Write-BackupLog "Backup file validation completed successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-BackupLog "Error validating backup file: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Monitor restoration progress
function Start-RestoreProgressMonitor {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        [Parameter(Mandatory = $true)]
        [scriptblock]$RestoreOperation,
        [int]$TimeoutMinutes = 30
    )
    
    try {
        Write-BackupLog "Starting restore progress monitor for: $DistributionName" "INFO"
        
        # Create progress tracking variables
        $startTime = Get-Date
        $timeoutTime = $startTime.AddMinutes($TimeoutMinutes)
        $progressJob = $null
        
        try {
            # Start the restore operation as a background job
            $progressJob = Start-Job -ScriptBlock $RestoreOperation
            
            # Monitor progress
            while ($progressJob.State -eq "Running") {
                $currentTime = Get-Date
                $elapsedMinutes = [math]::Round(($currentTime - $startTime).TotalMinutes, 1)
                
                # Check for timeout
                if ($currentTime -gt $timeoutTime) {
                    Write-BackupLog "Restore operation timed out after $TimeoutMinutes minutes" "ERROR"
                    Stop-Job $progressJob -Force
                    Remove-Job $progressJob -Force
                    throw "Restore operation timed out"
                }
                
                # Display progress
                Write-BackupLog "Restore in progress... Elapsed time: $elapsedMinutes minutes" "INFO"
                
                # Check if distribution is being created
                $distributions = wsl --list --quiet 2>$null
                if ($distributions -and ($distributions -contains $DistributionName)) {
                    Write-BackupLog "Distribution '$DistributionName' detected in WSL list" "INFO"
                }
                
                Start-Sleep -Seconds 10
            }
            
            # Get job results
            $jobResult = Receive-Job $progressJob
            $jobError = $progressJob.ChildJobs[0].Error
            
            if ($progressJob.State -eq "Completed") {
                $totalMinutes = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
                Write-BackupLog "Restore operation completed successfully in $totalMinutes minutes" "SUCCESS"
                return @{
                    Success = $true
                    ElapsedMinutes = $totalMinutes
                    Result = $jobResult
                }
            }
            else {
                $errorMessage = if ($jobError) { $jobError | Out-String } else { "Unknown error" }
                Write-BackupLog "Restore operation failed: $errorMessage" "ERROR"
                return @{
                    Success = $false
                    Error = $errorMessage
                }
            }
        }
        finally {
            # Clean up job
            if ($progressJob) {
                Remove-Job $progressJob -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Write-BackupLog "Error in restore progress monitor: $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Restore WSL distribution from backup
function Restore-WSLDistribution {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupPath,
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        [string]$BackupId = $null,
        [switch]$Force,
        [switch]$VerifyIntegrity,
        [int]$TimeoutMinutes = 30
    )
    
    try {
        Write-BackupLog "Starting WSL distribution restore" "INFO"
        Write-BackupLog "Backup file: $BackupPath" "INFO"
        Write-BackupLog "Target distribution: $DistributionName" "INFO"
        
        # Get backup metadata if BackupId is provided
        $backupMetadata = $null
        if ($BackupId) {
            $backupMetadata = Get-BackupMetadata -BackupId $BackupId
            if (-not $backupMetadata) {
                Write-BackupLog "Backup metadata not found for ID: $BackupId" "WARN"
            }
        }
        
        # Validate backup file
        $expectedChecksum = if ($backupMetadata) { $backupMetadata.Checksum } else { $null }
        if ($VerifyIntegrity -or $expectedChecksum) {
            if (-not (Test-BackupForRestore -BackupPath $BackupPath -ExpectedChecksum $expectedChecksum)) {
                throw "Backup file validation failed"
            }
        }
        else {
            if (-not (Test-BackupFileFormat -BackupPath $BackupPath)) {
                throw "Backup file format validation failed"
            }
        }
        
        # Check if distribution already exists
        $existingDistributions = wsl --list --quiet 2>$null
        if ($existingDistributions -and ($existingDistributions -contains $DistributionName)) {
            if (-not $Force) {
                throw "Distribution '$DistributionName' already exists. Use -Force parameter to overwrite."
            }
            else {
                Write-BackupLog "Removing existing distribution: $DistributionName" "WARN"
                wsl --unregister $DistributionName 2>$null
                if ($LASTEXITCODE -ne 0) {
                    Write-BackupLog "Warning: Failed to unregister existing distribution" "WARN"
                }
                Start-Sleep -Seconds 2
            }
        }
        
        # Create restore operation scriptblock
        $restoreOperation = {
            param($BackupPath, $DistributionName)
            
            # Import WSL distribution
            $importArgs = @("--import", $DistributionName, $BackupPath)
            $process = Start-Process -FilePath "wsl" -ArgumentList $importArgs -Wait -PassThru -NoNewWindow
            
            return @{
                ExitCode = $process.ExitCode
                BackupPath = $BackupPath
                DistributionName = $DistributionName
            }
        }
        
        # Execute restore with progress monitoring
        $restoreResult = Start-RestoreProgressMonitor -DistributionName $DistributionName -RestoreOperation {
            & $restoreOperation $BackupPath $DistributionName
        } -TimeoutMinutes $TimeoutMinutes
        
        if (-not $restoreResult.Success) {
            throw "Restore operation failed: $($restoreResult.Error)"
        }
        
        # Verify restoration
        Start-Sleep -Seconds 3
        $distributions = wsl --list --verbose 2>$null
        $restoredDist = $distributions | Where-Object { $_ -match $DistributionName }
        
        if (-not $restoredDist) {
            throw "Distribution '$DistributionName' not found after restoration"
        }
        
        # Test distribution functionality
        Write-BackupLog "Testing restored distribution functionality..." "INFO"
        $testResult = wsl -d $DistributionName -- echo "WSL restore test successful" 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-BackupLog "Warning: Restored distribution may not be fully functional" "WARN"
        }
        else {
            Write-BackupLog "Restored distribution functionality test passed" "SUCCESS"
        }
        
        # Get restored distribution info
        $restoredInfo = Get-WSLDistributionInfo -DistributionName $DistributionName
        
        Write-BackupLog "WSL distribution restore completed successfully" "SUCCESS"
        Write-BackupLog "Restored distribution info: $($restoredInfo.Version), Status: $($restoredInfo.Status)" "INFO"
        
        return @{
            Success = $true
            DistributionName = $DistributionName
            BackupPath = $BackupPath
            ElapsedMinutes = $restoreResult.ElapsedMinutes
            DistributionInfo = $restoredInfo
            BackupMetadata = $backupMetadata
        }
    }
    catch {
        Write-BackupLog "WSL distribution restore failed: $($_.Exception.Message)" "ERROR"
        
        # Clean up failed restoration
        try {
            $distributions = wsl --list --quiet 2>$null
            if ($distributions -and ($distributions -contains $DistributionName)) {
                Write-BackupLog "Cleaning up failed restoration..." "INFO"
                wsl --unregister $DistributionName 2>$null
            }
        }
        catch {
            Write-BackupLog "Error during cleanup: $($_.Exception.Message)" "WARN"
        }
        
        throw
    }
}

# Import WSL distribution with configuration recovery
function Import-WSLDistribution {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupPath,
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        [string]$BackupId = $null,
        [switch]$RestoreConfiguration,
        [switch]$Force,
        [hashtable]$CustomConfiguration = @{},
        [int]$TimeoutMinutes = 30
    )
    
    try {
        Write-BackupLog "Starting WSL distribution import with configuration recovery" "INFO"
        
        # First, restore the distribution
        $restoreResult = Restore-WSLDistribution -BackupPath $BackupPath -DistributionName $DistributionName -BackupId $BackupId -Force:$Force -VerifyIntegrity -TimeoutMinutes $TimeoutMinutes
        
        if (-not $restoreResult.Success) {
            throw "Distribution restoration failed"
        }
        
        # Apply configuration recovery if requested
        if ($RestoreConfiguration -or $CustomConfiguration.Count -gt 0) {
            Write-BackupLog "Starting configuration recovery..." "INFO"
            
            # Get original configuration from backup metadata
            $originalConfig = @{}
            if ($restoreResult.BackupMetadata -and $restoreResult.BackupMetadata.DistributionInfo) {
                $originalConfig = $restoreResult.BackupMetadata.DistributionInfo
            }
            
            # Merge with custom configuration
            $finalConfig = $originalConfig.Clone()
            foreach ($key in $CustomConfiguration.Keys) {
                $finalConfig[$key] = $CustomConfiguration[$key]
            }
            
            # Apply WSL configuration
            try {
                # Set as default distribution if specified
                if ($finalConfig.SetAsDefault -eq $true) {
                    Write-BackupLog "Setting '$DistributionName' as default distribution..." "INFO"
                    wsl --set-default $DistributionName 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-BackupLog "Default distribution set successfully" "SUCCESS"
                    }
                    else {
                        Write-BackupLog "Warning: Failed to set default distribution" "WARN"
                    }
                }
                
                # Configure WSL version if specified
                if ($finalConfig.WSLVersion) {
                    Write-BackupLog "Setting WSL version to $($finalConfig.WSLVersion)..." "INFO"
                    wsl --set-version $DistributionName $finalConfig.WSLVersion 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-BackupLog "WSL version set successfully" "SUCCESS"
                    }
                    else {
                        Write-BackupLog "Warning: Failed to set WSL version" "WARN"
                    }
                }
                
                # Run post-import configuration commands
                if ($finalConfig.PostImportCommands -and $finalConfig.PostImportCommands.Count -gt 0) {
                    Write-BackupLog "Executing post-import configuration commands..." "INFO"
                    foreach ($command in $finalConfig.PostImportCommands) {
                        Write-BackupLog "Executing: $command" "INFO"
                        wsl -d $DistributionName -- bash -c $command 2>$null
                        if ($LASTEXITCODE -eq 0) {
                            Write-BackupLog "Command executed successfully" "SUCCESS"
                        }
                        else {
                            Write-BackupLog "Warning: Command execution failed" "WARN"
                        }
                    }
                }
                
                Write-BackupLog "Configuration recovery completed" "SUCCESS"
            }
            catch {
                Write-BackupLog "Error during configuration recovery: $($_.Exception.Message)" "WARN"
            }
        }
        
        # Final verification
        Write-BackupLog "Performing final import verification..." "INFO"
        $finalInfo = Get-WSLDistributionInfo -DistributionName $DistributionName
        
        Write-BackupLog "WSL distribution import completed successfully" "SUCCESS"
        Write-BackupLog "Final distribution status: $($finalInfo.Status), Version: $($finalInfo.Version)" "INFO"
        
        return @{
            Success = $true
            DistributionName = $DistributionName
            BackupPath = $BackupPath
            ElapsedMinutes = $restoreResult.ElapsedMinutes
            DistributionInfo = $finalInfo
            ConfigurationRestored = ($RestoreConfiguration -or $CustomConfiguration.Count -gt 0)
            BackupMetadata = $restoreResult.BackupMetadata
        }
    }
    catch {
        Write-BackupLog "WSL distribution import failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Restore from incremental backup chain
function Restore-WSLFromIncrementalChain {
    param(
        [Parameter(Mandatory = $true)]
        [string]$IncrementalBackupId,
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        [switch]$Force,
        [int]$TimeoutMinutes = 45
    )
    
    try {
        Write-BackupLog "Starting incremental backup chain restoration" "INFO"
        
        # Get backup metadata
        $incrementalBackup = Get-BackupMetadata -BackupId $IncrementalBackupId
        if (-not $incrementalBackup) {
            throw "Incremental backup not found: $IncrementalBackupId"
        }
        
        if ($incrementalBackup.BackupType -ne "Incremental") {
            throw "Specified backup is not an incremental backup"
        }
        
        # Find the full backup (parent chain)
        $backupChain = @()
        $currentBackup = $incrementalBackup
        
        while ($currentBackup) {
            $backupChain += $currentBackup
            
            if ($currentBackup.BackupType -eq "Full") {
                break
            }
            
            if ($currentBackup.ParentBackupId) {
                $currentBackup = Get-BackupMetadata -BackupId $currentBackup.ParentBackupId
            }
            else {
                throw "Incomplete backup chain: missing parent backup"
            }
        }
        
        # Reverse chain to start with full backup
        [array]::Reverse($backupChain)
        
        Write-BackupLog "Found backup chain with $($backupChain.Count) backups" "INFO"
        Write-BackupLog "Chain: $($backupChain | ForEach-Object { "$($_.BackupType) ($($_.CreatedDate))" } | Join-String -Separator ' -> ')" "INFO"
        
        # Restore full backup first
        $fullBackup = $backupChain[0]
        Write-BackupLog "Restoring full backup: $($fullBackup.BackupId)" "INFO"
        
        $restoreResult = Restore-WSLDistribution -BackupPath $fullBackup.BackupPath -DistributionName $DistributionName -BackupId $fullBackup.BackupId -Force:$Force -VerifyIntegrity -TimeoutMinutes $TimeoutMinutes
        
        if (-not $restoreResult.Success) {
            throw "Full backup restoration failed"
        }
        
        # Apply incremental backups in sequence
        for ($i = 1; $i -lt $backupChain.Count; $i++) {
            $incrementalBackup = $backupChain[$i]
            Write-BackupLog "Applying incremental backup $i of $($backupChain.Count - 1): $($incrementalBackup.BackupId)" "INFO"
            
            try {
                # Extract incremental backup to temporary location
                $tempDir = Join-Path $env:TEMP "wsl_incremental_restore_$(Get-Random)"
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
                
                try {
                    # Extract incremental backup
                    $extractArgs = @("-xzf", $incrementalBackup.BackupPath, "-C", $tempDir)
                    $process = Start-Process -FilePath "tar" -ArgumentList $extractArgs -Wait -PassThru -NoNewWindow
                    
                    if ($process.ExitCode -ne 0) {
                        throw "Failed to extract incremental backup"
                    }
                    
                    # Copy extracted files to WSL distribution
                    $wslTempDir = $tempDir -replace '\\', '/' -replace 'C:', '/mnt/c'
                    $copyCommand = "cp -rf '$wslTempDir'/* / 2>/dev/null"
                    
                    wsl -d $DistributionName -- bash -c $copyCommand 2>$null
                    if ($LASTEXITCODE -ne 0) {
                        Write-BackupLog "Warning: Some files may not have been copied from incremental backup" "WARN"
                    }
                    
                    Write-BackupLog "Incremental backup applied successfully" "SUCCESS"
                }
                finally {
                    # Clean up temporary directory
                    if (Test-Path $tempDir) {
                        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }
            catch {
                Write-BackupLog "Error applying incremental backup: $($_.Exception.Message)" "ERROR"
                throw
            }
        }
        
        # Final verification
        $finalInfo = Get-WSLDistributionInfo -DistributionName $DistributionName
        
        Write-BackupLog "Incremental backup chain restoration completed successfully" "SUCCESS"
        Write-BackupLog "Final distribution status: $($finalInfo.Status), Version: $($finalInfo.Version)" "INFO"
        
        return @{
            Success = $true
            DistributionName = $DistributionName
            BackupChainCount = $backupChain.Count
            ElapsedMinutes = $restoreResult.ElapsedMinutes
            DistributionInfo = $finalInfo
            BackupChain = $backupChain
        }
    }
    catch {
        Write-BackupLog "Incremental backup chain restoration failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Create portable WSL environment package for migration
function New-WSLMigrationPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        [switch]$IncludeConfiguration,
        [switch]$IncludeUserData,
        [string[]]$ExcludePaths = @(),
        [hashtable]$MigrationMetadata = @{}
    )
    
    try {
        Write-BackupLog "Creating WSL migration package for: $DistributionName" "INFO"
        
        # Ensure output directory exists
        $outputDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        # Get distribution information
        $distInfo = Get-WSLDistributionInfo -DistributionName $DistributionName
        Write-BackupLog "Distribution info: $($distInfo.Version), Status: $($distInfo.Status)" "INFO"
        
        # Create temporary working directory
        $tempDir = Join-Path $env:TEMP "wsl_migration_$(Get-Random)"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        
        try {
            # Create full backup of the distribution
            $backupPath = Join-Path $tempDir "$DistributionName-migration.tar"
            Write-BackupLog "Creating distribution backup..." "INFO"
            
            $backupResult = New-WSLFullBackup -DistributionName $DistributionName -BackupPath $backupPath
            
            # Collect configuration information
            $configInfo = @{
                DistributionInfo = $distInfo
                WSLVersion = 2
                CreatedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                SourceMachine = $env:COMPUTERNAME
                SourceUser = $env:USERNAME
                MigrationTool = "WSL-BackupManager"
                ToolVersion = "1.0.0"
            }
            
            # Add custom migration metadata
            foreach ($key in $MigrationMetadata.Keys) {
                $configInfo[$key] = $MigrationMetadata[$key]
            }
            
            # Collect WSL configuration if requested
            if ($IncludeConfiguration) {
                Write-BackupLog "Collecting WSL configuration..." "INFO"
                
                # Get .wslconfig file if exists
                $wslConfigPath = Join-Path $env:USERPROFILE ".wslconfig"
                if (Test-Path $wslConfigPath) {
                    $configInfo.WSLConfig = Get-Content $wslConfigPath -Raw
                }
                
                # Get distribution-specific configuration
                try {
                    $distConfig = wsl -d $DistributionName -- cat /etc/wsl.conf 2>$null
                    if ($LASTEXITCODE -eq 0 -and $distConfig) {
                        $configInfo.DistributionConfig = $distConfig -join "`n"
                    }
                }
                catch {
                    Write-BackupLog "Could not retrieve distribution configuration" "WARN"
                }
                
                # Get installed packages list
                try {
                    $packageList = wsl -d $DistributionName -- bash -c "dpkg -l 2>/dev/null | grep '^ii' | awk '{print \$2}'" 2>$null
                    if ($LASTEXITCODE -eq 0 -and $packageList) {
                        $configInfo.InstalledPackages = $packageList
                    }
                }
                catch {
                    Write-BackupLog "Could not retrieve package list" "WARN"
                }
            }
            
            # Collect user data information if requested
            if ($IncludeUserData) {
                Write-BackupLog "Collecting user data information..." "INFO"
                
                try {
                    $userList = wsl -d $DistributionName -- bash -c "cut -d: -f1 /etc/passwd | grep -v '^#'" 2>$null
                    if ($LASTEXITCODE -eq 0 -and $userList) {
                        $configInfo.UserAccounts = $userList
                    }
                }
                catch {
                    Write-BackupLog "Could not retrieve user account list" "WARN"
                }
            }
            
            # Save migration metadata
            $metadataPath = Join-Path $tempDir "migration-metadata.json"
            $configInfo | ConvertTo-Json -Depth 10 | Set-Content $metadataPath -Encoding UTF8
            
            # Create migration package (compressed archive)
            Write-BackupLog "Creating migration package..." "INFO"
            
            $packageFiles = @(
                "$DistributionName-migration.tar",
                "migration-metadata.json"
            )
            
            # Create the migration package
            $createArgs = @("-czf", $OutputPath, "-C", $tempDir) + $packageFiles
            $process = Start-Process -FilePath "tar" -ArgumentList $createArgs -Wait -PassThru -NoNewWindow
            
            if ($process.ExitCode -ne 0) {
                throw "Failed to create migration package"
            }
            
            # Verify package was created
            if (-not (Test-Path $OutputPath)) {
                throw "Migration package not created: $OutputPath"
            }
            
            $packageFile = Get-Item $OutputPath
            Write-BackupLog "Migration package created successfully, size: $([math]::Round($packageFile.Length / 1MB, 2)) MB" "SUCCESS"
            
            # Calculate package checksum
            $packageHash = Get-FileHash -Path $OutputPath -Algorithm SHA256
            
            return @{
                Success = $true
                PackagePath = $OutputPath
                Size = [math]::Round($packageFile.Length / 1MB, 2)
                Checksum = $packageHash.Hash
                DistributionName = $DistributionName
                ConfigurationIncluded = $IncludeConfiguration
                UserDataIncluded = $IncludeUserData
                Metadata = $configInfo
            }
        }
        finally {
            # Clean up temporary directory
            if (Test-Path $tempDir) {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Write-BackupLog "Migration package creation failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Deploy WSL environment from migration package
function Deploy-WSLFromMigrationPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackagePath,
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        [switch]$RestoreConfiguration,
        [switch]$Force,
        [hashtable]$CustomConfiguration = @{},
        [int]$TimeoutMinutes = 30
    )
    
    try {
        Write-BackupLog "Deploying WSL environment from migration package: $PackagePath" "INFO"
        
        # Verify package exists
        if (-not (Test-Path $PackagePath)) {
            throw "Migration package not found: $PackagePath"
        }
        
        # Create temporary working directory
        $tempDir = Join-Path $env:TEMP "wsl_deploy_$(Get-Random)"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        
        try {
            # Extract migration package
            Write-BackupLog "Extracting migration package..." "INFO"
            
            $extractArgs = @("-xzf", $PackagePath, "-C", $tempDir)
            $process = Start-Process -FilePath "tar" -ArgumentList $extractArgs -Wait -PassThru -NoNewWindow
            
            if ($process.ExitCode -ne 0) {
                throw "Failed to extract migration package"
            }
            
            # Read migration metadata
            $metadataPath = Join-Path $tempDir "migration-metadata.json"
            if (-not (Test-Path $metadataPath)) {
                throw "Migration metadata not found in package"
            }
            
            $migrationMetadata = Get-Content $metadataPath | ConvertFrom-Json
            Write-BackupLog "Migration metadata loaded: Source machine: $($migrationMetadata.SourceMachine), Created: $($migrationMetadata.CreatedDate)" "INFO"
            
            # Find the distribution backup file
            $backupFiles = Get-ChildItem -Path $tempDir -Filter "*-migration.tar"
            if ($backupFiles.Count -eq 0) {
                throw "Distribution backup file not found in migration package"
            }
            
            $backupPath = $backupFiles[0].FullName
            Write-BackupLog "Found distribution backup: $($backupFiles[0].Name)" "INFO"
            
            # Import the distribution
            Write-BackupLog "Importing WSL distribution..." "INFO"
            
            $importConfig = $CustomConfiguration.Clone()
            
            # Apply migration configuration if requested
            if ($RestoreConfiguration -and $migrationMetadata) {
                if ($migrationMetadata.WSLConfig) {
                    Write-BackupLog "Restoring WSL configuration..." "INFO"
                    $wslConfigPath = Join-Path $env:USERPROFILE ".wslconfig"
                    $migrationMetadata.WSLConfig | Set-Content $wslConfigPath -Encoding UTF8
                }
                
                # Set WSL version from migration metadata
                if ($migrationMetadata.WSLVersion) {
                    $importConfig.WSLVersion = $migrationMetadata.WSLVersion
                }
                
                # Add post-import commands for configuration restoration
                $postCommands = @()
                
                if ($migrationMetadata.DistributionConfig) {
                    $postCommands += "echo '$($migrationMetadata.DistributionConfig)' | sudo tee /etc/wsl.conf > /dev/null"
                }
                
                if ($migrationMetadata.InstalledPackages -and $migrationMetadata.InstalledPackages.Count -gt 0) {
                    Write-BackupLog "Note: Original installation had $($migrationMetadata.InstalledPackages.Count) packages installed" "INFO"
                    # Note: We don't automatically reinstall packages as they should be in the backup
                }
                
                if ($postCommands.Count -gt 0) {
                    $importConfig.PostImportCommands = $postCommands
                }
            }
            
            # Import the distribution with configuration
            $importResult = Import-WSLDistribution -BackupPath $backupPath -DistributionName $DistributionName -RestoreConfiguration:$RestoreConfiguration -CustomConfiguration $importConfig -Force:$Force -TimeoutMinutes $TimeoutMinutes
            
            if (-not $importResult.Success) {
                throw "Distribution import failed"
            }
            
            Write-BackupLog "WSL environment deployment completed successfully" "SUCCESS"
            
            return @{
                Success = $true
                DistributionName = $DistributionName
                PackagePath = $PackagePath
                SourceMachine = $migrationMetadata.SourceMachine
                SourceDate = $migrationMetadata.CreatedDate
                ElapsedMinutes = $importResult.ElapsedMinutes
                ConfigurationRestored = $RestoreConfiguration
                MigrationMetadata = $migrationMetadata
                DistributionInfo = $importResult.DistributionInfo
            }
        }
        finally {
            # Clean up temporary directory
            if (Test-Path $tempDir) {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Write-BackupLog "WSL environment deployment failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Batch deploy WSL environments to multiple machines
function Start-WSLBatchDeployment {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackagePath,
        [Parameter(Mandatory = $true)]
        [string[]]$TargetMachines,
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        [System.Management.Automation.PSCredential]$Credential,
        [switch]$RestoreConfiguration,
        [hashtable]$CustomConfiguration = @{},
        [int]$TimeoutMinutes = 30,
        [int]$MaxConcurrentJobs = 3
    )
    
    try {
        Write-BackupLog "Starting batch deployment to $($TargetMachines.Count) machines" "INFO"
        
        # Verify package exists
        if (-not (Test-Path $PackagePath)) {
            throw "Migration package not found: $PackagePath"
        }
        
        $deploymentResults = @()
        $jobs = @()
        
        # Create deployment script block
        $deploymentScript = {
            param($PackagePath, $DistributionName, $RestoreConfiguration, $CustomConfiguration, $TimeoutMinutes)
            
            try {
                # Import the WSL-BackupManager module on remote machine
                # Note: This assumes the module is available on the target machine
                Import-Module WSL-BackupManager -Force
                
                # Deploy the environment
                $result = Deploy-WSLFromMigrationPackage -PackagePath $PackagePath -DistributionName $DistributionName -RestoreConfiguration:$RestoreConfiguration -CustomConfiguration $CustomConfiguration -TimeoutMinutes $TimeoutMinutes
                
                return @{
                    Success = $true
                    Machine = $env:COMPUTERNAME
                    Result = $result
                    Error = $null
                }
            }
            catch {
                return @{
                    Success = $false
                    Machine = $env:COMPUTERNAME
                    Result = $null
                    Error = $_.Exception.Message
                }
            }
        }
        
        # Start deployment jobs
        foreach ($machine in $TargetMachines) {
            Write-BackupLog "Starting deployment job for machine: $machine" "INFO"
            
            try {
                # Wait if we've reached the maximum concurrent jobs
                while ($jobs.Count -ge $MaxConcurrentJobs) {
                    $completedJobs = $jobs | Where-Object { $_.State -ne "Running" }
                    if ($completedJobs.Count -gt 0) {
                        # Process completed jobs
                        foreach ($job in $completedJobs) {
                            $jobResult = Receive-Job $job
                            $deploymentResults += $jobResult
                            Remove-Job $job
                        }
                        $jobs = $jobs | Where-Object { $_.State -eq "Running" }
                    }
                    else {
                        Start-Sleep -Seconds 5
                    }
                }
                
                # Start new job
                if ($Credential) {
                    $job = Invoke-Command -ComputerName $machine -Credential $Credential -ScriptBlock $deploymentScript -ArgumentList $PackagePath, $DistributionName, $RestoreConfiguration, $CustomConfiguration, $TimeoutMinutes -AsJob
                }
                else {
                    $job = Invoke-Command -ComputerName $machine -ScriptBlock $deploymentScript -ArgumentList $PackagePath, $DistributionName, $RestoreConfiguration, $CustomConfiguration, $TimeoutMinutes -AsJob
                }
                
                $jobs += $job
            }
            catch {
                Write-BackupLog "Failed to start deployment job for machine $machine : $($_.Exception.Message)" "ERROR"
                $deploymentResults += @{
                    Success = $false
                    Machine = $machine
                    Result = $null
                    Error = "Failed to start deployment job: $($_.Exception.Message)"
                }
            }
        }
        
        # Wait for all remaining jobs to complete
        Write-BackupLog "Waiting for all deployment jobs to complete..." "INFO"
        while ($jobs.Count -gt 0) {
            $completedJobs = $jobs | Where-Object { $_.State -ne "Running" }
            if ($completedJobs.Count -gt 0) {
                foreach ($job in $completedJobs) {
                    $jobResult = Receive-Job $job
                    $deploymentResults += $jobResult
                    Remove-Job $job
                }
                $jobs = $jobs | Where-Object { $_.State -eq "Running" }
            }
            else {
                Start-Sleep -Seconds 5
            }
        }
        
        # Analyze results
        $successfulDeployments = $deploymentResults | Where-Object { $_.Success -eq $true }
        $failedDeployments = $deploymentResults | Where-Object { $_.Success -eq $false }
        
        Write-BackupLog "Batch deployment completed: $($successfulDeployments.Count) successful, $($failedDeployments.Count) failed" "INFO"
        
        if ($failedDeployments.Count -gt 0) {
            Write-BackupLog "Failed deployments:" "WARN"
            foreach ($failure in $failedDeployments) {
                Write-BackupLog "  - $($failure.Machine): $($failure.Error)" "WARN"
            }
        }
        
        return @{
            Success = ($failedDeployments.Count -eq 0)
            TotalMachines = $TargetMachines.Count
            SuccessfulDeployments = $successfulDeployments.Count
            FailedDeployments = $failedDeployments.Count
            Results = $deploymentResults
            PackagePath = $PackagePath
            DistributionName = $DistributionName
        }
    }
    catch {
        Write-BackupLog "Batch deployment failed: $($_.Exception.Message)" "ERROR"
        
        # Clean up any remaining jobs
        if ($jobs.Count -gt 0) {
            $jobs | Stop-Job -Force
            $jobs | Remove-Job -Force
        }
        
        throw
    }
}

# Verify migration consistency and environment integrity
function Test-WSLMigrationConsistency {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        [string]$OriginalPackagePath = $null,
        [hashtable]$ExpectedConfiguration = @{},
        [switch]$DetailedCheck
    )
    
    try {
        Write-BackupLog "Starting migration consistency verification for: $DistributionName" "INFO"
        
        $verificationResults = @{
            DistributionExists = $false
            DistributionRunning = $false
            ConfigurationMatch = $false
            UserDataIntact = $false
            PackagesConsistent = $false
            OverallConsistency = $false
            Issues = @()
            Details = @{}
        }
        
        # Check if distribution exists
        try {
            $distInfo = Get-WSLDistributionInfo -DistributionName $DistributionName
            $verificationResults.DistributionExists = $true
            $verificationResults.Details.DistributionInfo = $distInfo
            
            # Check if distribution is running or can be started
            if ($distInfo.Status -eq "Running") {
                $verificationResults.DistributionRunning = $true
            }
            else {
                # Try to start the distribution
                wsl -d $DistributionName -- echo "test" 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $verificationResults.DistributionRunning = $true
                }
                else {
                    $verificationResults.Issues += "Distribution cannot be started"
                }
            }
        }
        catch {
            $verificationResults.Issues += "Distribution does not exist or cannot be accessed: $($_.Exception.Message)"
        }
        
        # Verify configuration if original package is provided
        if ($OriginalPackagePath -and (Test-Path $OriginalPackagePath)) {
            try {
                Write-BackupLog "Comparing with original migration package..." "INFO"
                
                # Extract original metadata
                $tempDir = Join-Path $env:TEMP "wsl_verify_$(Get-Random)"
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
                
                try {
                    $extractArgs = @("-xzf", $OriginalPackagePath, "-C", $tempDir, "migration-metadata.json")
                    $process = Start-Process -FilePath "tar" -ArgumentList $extractArgs -Wait -PassThru -NoNewWindow
                    
                    if ($process.ExitCode -eq 0) {
                        $metadataPath = Join-Path $tempDir "migration-metadata.json"
                        if (Test-Path $metadataPath) {
                            $originalMetadata = Get-Content $metadataPath | ConvertFrom-Json
                            $verificationResults.Details.OriginalMetadata = $originalMetadata
                            
                            # Compare versions
                            if ($originalMetadata.DistributionInfo.Version -eq $distInfo.Version) {
                                $verificationResults.ConfigurationMatch = $true
                            }
                            else {
                                $verificationResults.Issues += "Distribution version mismatch: expected '$($originalMetadata.DistributionInfo.Version)', got '$($distInfo.Version)'"
                            }
                        }
                    }
                }
                finally {
                    if (Test-Path $tempDir) {
                        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }
            catch {
                $verificationResults.Issues += "Could not verify against original package: $($_.Exception.Message)"
            }
        }
        
        # Verify expected configuration
        if ($ExpectedConfiguration.Count -gt 0) {
            Write-BackupLog "Verifying expected configuration..." "INFO"
            
            foreach ($key in $ExpectedConfiguration.Keys) {
                $expectedValue = $ExpectedConfiguration[$key]
                
                switch ($key) {
                    "WSLVersion" {
                        # Check WSL version
                        $versionCheck = wsl -l -v | Where-Object { $_ -match $DistributionName }
                        if ($versionCheck -and $versionCheck -match "2") {
                            if ($expectedValue -eq 2) {
                                Write-BackupLog "WSL version check passed" "SUCCESS"
                            }
                            else {
                                $verificationResults.Issues += "WSL version mismatch: expected $expectedValue, got 2"
                            }
                        }
                    }
                    "DefaultDistribution" {
                        if ($expectedValue -eq $true) {
                            $defaultDist = wsl -l | Select-Object -First 1
                            if ($defaultDist -match $DistributionName) {
                                Write-BackupLog "Default distribution check passed" "SUCCESS"
                            }
                            else {
                                $verificationResults.Issues += "Distribution is not set as default"
                            }
                        }
                    }
                }
            }
        }
        
        # Detailed checks if requested
        if ($DetailedCheck -and $verificationResults.DistributionRunning) {
            Write-BackupLog "Performing detailed consistency checks..." "INFO"
            
            # Check user data integrity
            try {
                $userCheck = wsl -d $DistributionName -- bash -c "ls -la /home 2>/dev/null | wc -l" 2>$null
                if ($LASTEXITCODE -eq 0 -and [int]$userCheck -gt 2) {
                    $verificationResults.UserDataIntact = $true
                }
                else {
                    $verificationResults.Issues += "User data appears to be missing or incomplete"
                }
            }
            catch {
                $verificationResults.Issues += "Could not verify user data integrity"
            }
            
            # Check package consistency
            try {
                $packageCount = wsl -d $DistributionName -- bash -c "dpkg -l 2>/dev/null | grep '^ii' | wc -l" 2>$null
                if ($LASTEXITCODE -eq 0 -and [int]$packageCount -gt 0) {
                    $verificationResults.PackagesConsistent = $true
                    $verificationResults.Details.InstalledPackageCount = [int]$packageCount
                }
                else {
                    $verificationResults.Issues += "Package database appears to be inconsistent"
                }
            }
            catch {
                $verificationResults.Issues += "Could not verify package consistency"
            }
            
            # Check file system integrity
            try {
                $fsCheck = wsl -d $DistributionName -- bash -c "df -h / 2>/dev/null | tail -1" 2>$null
                if ($LASTEXITCODE -eq 0 -and $fsCheck) {
                    $verificationResults.Details.FileSystemInfo = $fsCheck
                    Write-BackupLog "File system check passed" "SUCCESS"
                }
            }
            catch {
                $verificationResults.Issues += "Could not verify file system integrity"
            }
        }
        
        # Calculate overall consistency
        $criticalChecks = @(
            $verificationResults.DistributionExists,
            $verificationResults.DistributionRunning
        )
        
        if ($OriginalPackagePath -or $ExpectedConfiguration.Count -gt 0) {
            $criticalChecks += $verificationResults.ConfigurationMatch
        }
        
        if ($DetailedCheck) {
            $criticalChecks += @(
                $verificationResults.UserDataIntact,
                $verificationResults.PackagesConsistent
            )
        }
        
        $verificationResults.OverallConsistency = ($criticalChecks | Where-Object { $_ -eq $false }).Count -eq 0
        
        if ($verificationResults.OverallConsistency) {
            Write-BackupLog "Migration consistency verification passed" "SUCCESS"
        }
        else {
            Write-BackupLog "Migration consistency verification failed with $($verificationResults.Issues.Count) issues" "WARN"
        }
        
        return $verificationResults
    }
    catch {
        Write-BackupLog "Migration consistency verification failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# 导出模块函数
Export-ModuleMember -Function @(
    'New-WSLFullBackup',
    'New-WSLIncrementalBackup', 
    'Get-WSLBackupList',
    'Remove-WSLBackup',
    'Test-BackupIntegrity',
    'Get-WSLDistributionInfo',
    'Test-BackupFileFormat',
    'Get-BackupMetadata',
    'Test-BackupForRestore',
    'Start-RestoreProgressMonitor',
    'Restore-WSLDistribution',
    'Import-WSLDistribution',
    'Restore-WSLFromIncrementalChain',
    'New-WSLMigrationPackage',
    'Deploy-WSLFromMigrationPackage',
    'Start-WSLBatchDeployment',
    'Test-WSLMigrationConsistency'
)