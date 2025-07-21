# Test script for WSL Backup Recovery and Import functionality
# Tests the newly implemented recovery functions in WSL-BackupManager.psm1

param(
    [string]$TestDistribution = "Ubuntu-Test",
    [string]$BackupTestFile = $null,
    [switch]$CleanupAfterTest = $true,
    [switch]$Verbose = $false
)

# Import the backup manager module
$ModulePath = Join-Path $PSScriptRoot "WSL-BackupManager.psm1"
if (-not (Test-Path $ModulePath)) {
    Write-Error "WSL-BackupManager.psm1 not found in current directory"
    exit 1
}

Import-Module $ModulePath -Force

# Test results tracking
$TestResults = @()
$TestCount = 0
$PassedTests = 0

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = "",
        [string]$Details = ""
    )
    
    $script:TestCount++
    if ($Passed) {
        $script:PassedTests++
        Write-Host "✓ PASS: $TestName" -ForegroundColor Green
    } else {
        Write-Host "✗ FAIL: $TestName" -ForegroundColor Red
    }
    
    if ($Message) {
        Write-Host "  $Message" -ForegroundColor Yellow
    }
    
    if ($Details -and $Verbose) {
        Write-Host "  Details: $Details" -ForegroundColor Gray
    }
    
    $script:TestResults += @{
        TestName = $TestName
        Passed = $Passed
        Message = $Message
        Details = $Details
    }
}

function Test-BackupFileFormatValidation {
    Write-Host "`n=== Testing Backup File Format Validation ===" -ForegroundColor Cyan
    
    # Test 1: Valid tar file format detection
    try {
        $tempTarFile = Join-Path $env:TEMP "test-backup.tar"
        # Create a minimal tar file for testing
        "test content" | Out-File -FilePath (Join-Path $env:TEMP "test.txt") -Encoding ASCII
        & tar -cf $tempTarFile -C $env:TEMP "test.txt" 2>$null
        
        if (Test-Path $tempTarFile) {
            $result = Test-BackupFileFormat -BackupPath $tempTarFile
            Write-TestResult "Valid TAR file format detection" $result "Should detect valid tar file"
            Remove-Item $tempTarFile -Force -ErrorAction SilentlyContinue
        } else {
            Write-TestResult "Valid TAR file format detection" $false "Failed to create test tar file"
        }
        
        Remove-Item (Join-Path $env:TEMP "test.txt") -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-TestResult "Valid TAR file format detection" $false "Exception: $($_.Exception.Message)"
    }
    
    # Test 2: Invalid file format detection
    try {
        $tempInvalidFile = Join-Path $env:TEMP "test-invalid.txt"
        "invalid content" | Out-File -FilePath $tempInvalidFile -Encoding ASCII
        
        $result = Test-BackupFileFormat -BackupPath $tempInvalidFile
        Write-TestResult "Invalid file format detection" (-not $result) "Should reject non-tar files"
        
        Remove-Item $tempInvalidFile -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-TestResult "Invalid file format detection" $false "Exception: $($_.Exception.Message)"
    }
    
    # Test 3: Non-existent file handling
    try {
        $nonExistentFile = Join-Path $env:TEMP "non-existent-file.tar"
        $result = Test-BackupFileFormat -BackupPath $nonExistentFile
        Write-TestResult "Non-existent file handling" (-not $result) "Should handle missing files gracefully"
    }
    catch {
        Write-TestResult "Non-existent file handling" $false "Exception: $($_.Exception.Message)"
    }
}

function Test-BackupMetadataRetrieval {
    Write-Host "`n=== Testing Backup Metadata Retrieval ===" -ForegroundColor Cyan
    
    # Test 1: Get metadata with invalid backup ID
    try {
        $result = Get-BackupMetadata -BackupId "invalid-backup-id"
        Write-TestResult "Invalid backup ID handling" ($result -eq $null) "Should return null for invalid ID"
    }
    catch {
        Write-TestResult "Invalid backup ID handling" $false "Exception: $($_.Exception.Message)"
    }
    
    # Test 2: Get metadata without parameters
    try {
        $result = Get-BackupMetadata
        Write-TestResult "No parameters handling" $false "Should throw error when no parameters provided"
    }
    catch {
        Write-TestResult "No parameters handling" $true "Correctly threw error for missing parameters"
    }
}

function Test-BackupValidationForRestore {
    Write-Host "`n=== Testing Backup Validation for Restore ===" -ForegroundColor Cyan
    
    # Test 1: Non-existent backup file
    try {
        $nonExistentFile = Join-Path $env:TEMP "non-existent-backup.tar"
        $result = Test-BackupForRestore -BackupPath $nonExistentFile
        Write-TestResult "Non-existent backup validation" (-not $result) "Should fail validation for missing file"
    }
    catch {
        Write-TestResult "Non-existent backup validation" $false "Exception: $($_.Exception.Message)"
    }
    
    # Test 2: Valid backup file without checksum
    if ($BackupTestFile -and (Test-Path $BackupTestFile)) {
        try {
            $result = Test-BackupForRestore -BackupPath $BackupTestFile
            Write-TestResult "Valid backup without checksum" $result "Should pass validation for existing backup file"
        }
        catch {
            Write-TestResult "Valid backup without checksum" $false "Exception: $($_.Exception.Message)"
        }
    } else {
        Write-TestResult "Valid backup without checksum" $false "No test backup file provided or file not found"
    }
}

function Test-RestoreProgressMonitor {
    Write-Host "`n=== Testing Restore Progress Monitor ===" -ForegroundColor Cyan
    
    # Test 1: Simple operation monitoring
    try {
        $testOperation = {
            Start-Sleep -Seconds 2
            return @{ Status = "Completed"; Message = "Test operation successful" }
        }
        
        $result = Start-RestoreProgressMonitor -DistributionName "TestDist" -RestoreOperation $testOperation -TimeoutMinutes 1
        
        $passed = $result.Success -eq $true
        Write-TestResult "Simple operation monitoring" $passed "Should successfully monitor simple operation"
    }
    catch {
        Write-TestResult "Simple operation monitoring" $false "Exception: $($_.Exception.Message)"
    }
    
    # Test 2: Timeout handling
    try {
        $longOperation = {
            Start-Sleep -Seconds 120  # 2 minutes - should timeout
            return @{ Status = "Completed" }
        }
        
        $result = Start-RestoreProgressMonitor -DistributionName "TestDist" -RestoreOperation $longOperation -TimeoutMinutes 1
        
        $passed = $result.Success -eq $false
        Write-TestResult "Timeout handling" $passed "Should timeout long operations"
    }
    catch {
        Write-TestResult "Timeout handling" $true "Correctly handled timeout with exception"
    }
}

function Test-RestoreDistributionFunction {
    Write-Host "`n=== Testing Restore Distribution Function ===" -ForegroundColor Cyan
    
    # Test 1: Invalid backup file
    try {
        $invalidFile = Join-Path $env:TEMP "invalid-backup.tar"
        $result = Restore-WSLDistribution -BackupPath $invalidFile -DistributionName $TestDistribution
        Write-TestResult "Invalid backup file handling" $false "Should fail with invalid backup file"
    }
    catch {
        Write-TestResult "Invalid backup file handling" $true "Correctly failed with invalid backup file"
    }
    
    # Test 2: Valid backup file (if provided)
    if ($BackupTestFile -and (Test-Path $BackupTestFile)) {
        try {
            # Check if test distribution already exists
            $existingDists = wsl --list --quiet 2>$null
            $distExists = $existingDists -and ($existingDists -contains $TestDistribution)
            
            if ($distExists) {
                Write-Host "  Test distribution '$TestDistribution' already exists, skipping restore test" -ForegroundColor Yellow
                Write-TestResult "Valid backup restore" $true "Skipped - distribution already exists"
            } else {
                Write-Host "  Attempting to restore from: $BackupTestFile" -ForegroundColor Yellow
                $result = Restore-WSLDistribution -BackupPath $BackupTestFile -DistributionName $TestDistribution -TimeoutMinutes 5
                
                $passed = $result.Success -eq $true
                Write-TestResult "Valid backup restore" $passed "Should successfully restore from valid backup"
                
                if ($passed -and $CleanupAfterTest) {
                    Write-Host "  Cleaning up test distribution..." -ForegroundColor Yellow
                    wsl --unregister $TestDistribution 2>$null
                }
            }
        }
        catch {
            Write-TestResult "Valid backup restore" $false "Exception: $($_.Exception.Message)"
        }
    } else {
        Write-TestResult "Valid backup restore" $false "No valid test backup file provided"
    }
}

function Test-ImportDistributionFunction {
    Write-Host "`n=== Testing Import Distribution Function ===" -ForegroundColor Cyan
    
    # Test 1: Import with invalid backup file
    try {
        $invalidFile = Join-Path $env:TEMP "invalid-backup.tar"
        $result = Import-WSLDistribution -BackupPath $invalidFile -DistributionName $TestDistribution
        Write-TestResult "Import with invalid file" $false "Should fail with invalid backup file"
    }
    catch {
        Write-TestResult "Import with invalid file" $true "Correctly failed with invalid backup file"
    }
    
    # Test 2: Import with configuration (if valid backup provided)
    if ($BackupTestFile -and (Test-Path $BackupTestFile)) {
        try {
            $customConfig = @{
                SetAsDefault = $false
                WSLVersion = 2
                PostImportCommands = @("echo 'Import test successful'")
            }
            
            # Check if test distribution already exists
            $existingDists = wsl --list --quiet 2>$null
            $distExists = $existingDists -and ($existingDists -contains $TestDistribution)
            
            if ($distExists) {
                Write-Host "  Test distribution '$TestDistribution' already exists, skipping import test" -ForegroundColor Yellow
                Write-TestResult "Import with configuration" $true "Skipped - distribution already exists"
            } else {
                Write-Host "  Attempting to import with configuration from: $BackupTestFile" -ForegroundColor Yellow
                $result = Import-WSLDistribution -BackupPath $BackupTestFile -DistributionName $TestDistribution -RestoreConfiguration -CustomConfiguration $customConfig -TimeoutMinutes 5
                
                $passed = $result.Success -eq $true
                Write-TestResult "Import with configuration" $passed "Should successfully import with configuration"
                
                if ($passed -and $CleanupAfterTest) {
                    Write-Host "  Cleaning up test distribution..." -ForegroundColor Yellow
                    wsl --unregister $TestDistribution 2>$null
                }
            }
        }
        catch {
            Write-TestResult "Import with configuration" $false "Exception: $($_.Exception.Message)"
        }
    } else {
        Write-TestResult "Import with configuration" $false "No valid test backup file provided"
    }
}

function Show-TestSummary {
    Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
    Write-Host "Total Tests: $TestCount" -ForegroundColor White
    Write-Host "Passed: $PassedTests" -ForegroundColor Green
    Write-Host "Failed: $($TestCount - $PassedTests)" -ForegroundColor Red
    Write-Host "Success Rate: $([math]::Round(($PassedTests / $TestCount) * 100, 1))%" -ForegroundColor Yellow
    
    if ($TestCount - $PassedTests -gt 0) {
        Write-Host "`nFailed Tests:" -ForegroundColor Red
        $TestResults | Where-Object { -not $_.Passed } | ForEach-Object {
            Write-Host "  - $($_.TestName): $($_.Message)" -ForegroundColor Red
        }
    }
}

# Main test execution
Write-Host "WSL Backup Recovery and Import Functionality Test" -ForegroundColor Magenta
Write-Host "=================================================" -ForegroundColor Magenta

if ($BackupTestFile) {
    Write-Host "Using test backup file: $BackupTestFile" -ForegroundColor Yellow
} else {
    Write-Host "No test backup file provided - some tests will be skipped" -ForegroundColor Yellow
}

Write-Host "Test distribution name: $TestDistribution" -ForegroundColor Yellow
Write-Host "Cleanup after test: $CleanupAfterTest" -ForegroundColor Yellow

# Run all tests
Test-BackupFileFormatValidation
Test-BackupMetadataRetrieval
Test-BackupValidationForRestore
Test-RestoreProgressMonitor
Test-RestoreDistributionFunction
Test-ImportDistributionFunction

# Show summary
Show-TestSummary

# Exit with appropriate code
if ($PassedTests -eq $TestCount) {
    Write-Host "`nAll tests passed! ✓" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome tests failed! ✗" -ForegroundColor Red
    exit 1
}