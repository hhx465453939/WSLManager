# WSL Migration Manager Test Suite
# Tests for cross-machine environment packaging, transfer, batch deployment and migration validation

# Import required modules
Import-Module "$PSScriptRoot\WSL-Detection.psm1" -Force
Import-Module "$PSScriptRoot\WSL-BackupManager.psm1" -Force
Import-Module "$PSScriptRoot\WSL-MigrationManager.psm1" -Force

# Test configuration
$script:TestDistribution = "Ubuntu-Test-Migration"
$script:TestResults = @()
$script:TestStartTime = Get-Date

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = "",
        [string]$Error = ""
    )
    
    $result = @{
        TestName = $TestName
        Passed = $Passed
        Details = $Details
        Error = $Error
        Timestamp = Get-Date
    }
    
    $script:TestResults += $result
    
    $status = if ($Passed) { "PASS" } else { "FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Details) { Write-Host "  Details: $Details" -ForegroundColor Gray }
    if ($Error) { Write-Host "  Error: $Error" -ForegroundColor Red }
}

function Test-MigrationPrerequisites {
    Write-Host "`n=== Testing Migration Prerequisites ===" -ForegroundColor Cyan
    
    try {
        # Test WSL availability
        $wslVersion = wsl --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "WSL Version Check" $true "WSL is available"
        } else {
            Write-TestResult "WSL Version Check" $false "" "WSL is not available or not installed"
            return $false
        }
        
        # Test PowerShell version
        $psVersion = $PSVersionTable.PSVersion
        if ($psVersion.Major -ge 5) {
            Write-TestResult "PowerShell Version Check" $true "PowerShell $($psVersion.ToString()) is supported"
        } else {
            Write-TestResult "PowerShell Version Check" $false "" "PowerShell version $($psVersion.ToString()) is not supported"
            return $false
        }
        
        # Test required modules
        $requiredModules = @("WSL-Detection", "WSL-BackupManager", "WSL-MigrationManager")
        $allModulesLoaded = $true
        
        foreach ($module in $requiredModules) {
            if (Get-Module $module) {
                Write-TestResult "Module Check: $module" $true "Module is loaded"
            } else {
                Write-TestResult "Module Check: $module" $false "" "Module is not loaded"
                $allModulesLoaded = $false
            }
        }
        
        return $allModulesLoaded
    }
    catch {
        Write-TestResult "Prerequisites Check" $false "" $_.Exception.Message
        return $false
    }
}

function Test-SystemEnvironmentInfo {
    Write-Host "`n=== Testing System Environment Information Collection ===" -ForegroundColor Cyan
    
    try {
        $systemInfo = Get-SystemEnvironmentInfo
        
        # Test required fields
        $requiredFields = @("ComputerName", "UserName", "OSVersion", "OSBuild", "TotalMemoryGB", "ProcessorName")
        $allFieldsPresent = $true
        
        foreach ($field in $requiredFields) {
            if ($systemInfo.$field) {
                Write-TestResult "System Info Field: $field" $true "Value: $($systemInfo.$field)"
            } else {
                Write-TestResult "System Info Field: $field" $false "" "Field is missing or empty"
                $allFieldsPresent = $false
            }
        }
        
        # Test data types
        if ($systemInfo.TotalMemoryGB -is [double] -and $systemInfo.TotalMemoryGB -gt 0) {
            Write-TestResult "Memory Info Type Check" $true "Memory: $($systemInfo.TotalMemoryGB) GB"
        } else {
            Write-TestResult "Memory Info Type Check" $false "" "Memory information is invalid"
            $allFieldsPresent = $false
        }
        
        return $allFieldsPresent
    }
    catch {
        Write-TestResult "System Environment Info" $false "" $_.Exception.Message
        return $false
    }
}

function Test-WSLConfigurationCollection {
    Write-Host "`n=== Testing WSL Configuration Collection ===" -ForegroundColor Cyan
    
    try {
        # Get available distributions
        $distributions = wsl --list --quiet 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $distributions) {
            Write-TestResult "WSL Distribution Check" $false "" "No WSL distributions found"
            return $false
        }
        
        # Use first available distribution for testing
        $testDist = $distributions | Select-Object -First 1
        Write-Host "Testing with distribution: $testDist" -ForegroundColor Yellow
        
        $config = Get-WSLConfigurationForMigration -DistributionName $testDist
        
        # Test configuration structure
        $requiredFields = @("DistributionName", "DefaultUser", "WSLConfig", "EnvironmentVariables", "InstalledPackages")
        $allFieldsPresent = $true
        
        foreach ($field in $requiredFields) {
            if ($config.ContainsKey($field)) {
                Write-TestResult "Config Field: $field" $true "Field present"
            } else {
                Write-TestResult "Config Field: $field" $false "" "Field is missing"
                $allFieldsPresent = $false
            }
        }
        
        # Test distribution name matches
        if ($config.DistributionName -eq $testDist) {
            Write-TestResult "Distribution Name Match" $true "Names match: $testDist"
        } else {
            Write-TestResult "Distribution Name Match" $false "" "Names don't match: expected $testDist, got $($config.DistributionName)"
            $allFieldsPresent = $false
        }
        
        return $allFieldsPresent
    }
    catch {
        Write-TestResult "WSL Configuration Collection" $false "" $_.Exception.Message
        return $false
    }
}

function Test-MigrationPackageCreation {
    Write-Host "`n=== Testing Migration Package Creation ===" -ForegroundColor Cyan
    
    try {
        # Get available distributions
        $distributions = wsl --list --quiet 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $distributions) {
            Write-TestResult "Distribution Availability" $false "" "No WSL distributions available for testing"
            return $false
        }
        
        $testDist = $distributions | Select-Object -First 1
        Write-Host "Creating migration package for: $testDist" -ForegroundColor Yellow
        
        # Create test migration package
        $packageResult = New-WSLMigrationPackage -DistributionName $testDist -IncludeSystemInfo -Compress
        
        # Test package creation result
        if ($packageResult -and $packageResult.MigrationId) {
            Write-TestResult "Package Creation" $true "Migration ID: $($packageResult.MigrationId)"
        } else {
            Write-TestResult "Package Creation" $false "" "Package creation returned invalid result"
            return $false
        }
        
        # Test package directory exists
        if (Test-Path $packageResult.PackagePath) {
            Write-TestResult "Package Directory" $true "Path: $($packageResult.PackagePath)"
        } else {
            Write-TestResult "Package Directory" $false "" "Package directory not found"
            return $false
        }
        
        # Test compressed package exists
        if ($packageResult.CompressedPath -and (Test-Path $packageResult.CompressedPath)) {
            Write-TestResult "Compressed Package" $true "Path: $($packageResult.CompressedPath)"
        } else {
            Write-TestResult "Compressed Package" $false "" "Compressed package not found"
        }
        
        # Test required files in package
        $requiredFiles = @("migration-metadata.json", "install-migration.ps1", "validate-migration.ps1", "README.md")
        $allFilesPresent = $true
        
        foreach ($file in $requiredFiles) {
            $filePath = Join-Path $packageResult.PackagePath $file
            if (Test-Path $filePath) {
                Write-TestResult "Package File: $file" $true "File exists"
            } else {
                Write-TestResult "Package File: $file" $false "" "File missing"
                $allFilesPresent = $false
            }
        }
        
        # Test backup file exists
        $backupFile = Join-Path $packageResult.PackagePath "$testDist.tar"
        if (Test-Path $backupFile) {
            $backupSize = [math]::Round((Get-Item $backupFile).Length / 1MB, 2)
            Write-TestResult "Backup File" $true "Size: $backupSize MB"
        } else {
            Write-TestResult "Backup File" $false "" "Backup file missing"
            $allFilesPresent = $false
        }
        
        # Store package info for later tests
        $script:TestPackageResult = $packageResult
        
        return $allFilesPresent
    }
    catch {
        Write-TestResult "Migration Package Creation" $false "" $_.Exception.Message
        return $false
    }
}

function Test-MigrationMetadataValidation {
    Write-Host "`n=== Testing Migration Metadata Validation ===" -ForegroundColor Cyan
    
    try {
        if (-not $script:TestPackageResult) {
            Write-TestResult "Package Availability" $false "" "No test package available"
            return $false
        }
        
        # Load metadata
        $metadataPath = Join-Path $script:TestPackageResult.PackagePath "migration-metadata.json"
        $metadata = Get-Content $metadataPath | ConvertFrom-Json
        
        # Test metadata structure
        $requiredFields = @("MigrationId", "DistributionName", "CreatedDate", "BackupInfo", "WSLConfiguration")
        $allFieldsValid = $true
        
        foreach ($field in $requiredFields) {
            if ($metadata.$field) {
                Write-TestResult "Metadata Field: $field" $true "Field present"
            } else {
                Write-TestResult "Metadata Field: $field" $false "" "Field missing or empty"
                $allFieldsValid = $false
            }
        }
        
        # Test GUID format
        try {
            [System.Guid]::Parse($metadata.MigrationId) | Out-Null
            Write-TestResult "Migration ID Format" $true "Valid GUID format"
        } catch {
            Write-TestResult "Migration ID Format" $false "" "Invalid GUID format"
            $allFieldsValid = $false
        }
        
        # Test date format
        try {
            [datetime]::ParseExact($metadata.CreatedDate, "yyyy-MM-dd HH:mm:ss", $null) | Out-Null
            Write-TestResult "Date Format" $true "Valid date format"
        } catch {
            Write-TestResult "Date Format" $false "" "Invalid date format"
            $allFieldsValid = $false
        }
        
        # Test backup info
        if ($metadata.BackupInfo -and $metadata.BackupInfo.BackupId -and $metadata.BackupInfo.Checksum) {
            Write-TestResult "Backup Info" $true "Backup information complete"
        } else {
            Write-TestResult "Backup Info" $false "" "Backup information incomplete"
            $allFieldsValid = $false
        }
        
        return $allFieldsValid
    }
    catch {
        Write-TestResult "Migration Metadata Validation" $false "" $_.Exception.Message
        return $false
    }
}

function Test-MigrationScripts {
    Write-Host "`n=== Testing Migration Scripts ===" -ForegroundColor Cyan
    
    try {
        if (-not $script:TestPackageResult) {
            Write-TestResult "Package Availability" $false "" "No test package available"
            return $false
        }
        
        $packagePath = $script:TestPackageResult.PackagePath
        
        # Test install script syntax
        $installScript = Join-Path $packagePath "install-migration.ps1"
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $installScript -Raw), [ref]$null)
            Write-TestResult "Install Script Syntax" $true "PowerShell syntax is valid"
        } catch {
            Write-TestResult "Install Script Syntax" $false "" "PowerShell syntax error: $($_.Exception.Message)"
            return $false
        }
        
        # Test validation script syntax
        $validationScript = Join-Path $packagePath "validate-migration.ps1"
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $validationScript -Raw), [ref]$null)
            Write-TestResult "Validation Script Syntax" $true "PowerShell syntax is valid"
        } catch {
            Write-TestResult "Validation Script Syntax" $false "" "PowerShell syntax error: $($_.Exception.Message)"
            return $false
        }
        
        # Test README content
        $readmeFile = Join-Path $packagePath "README.md"
        $readmeContent = Get-Content $readmeFile -Raw
        
        if ($readmeContent -match "Installation Instructions" -and $readmeContent -match "install-migration.ps1") {
            Write-TestResult "README Content" $true "Contains installation instructions"
        } else {
            Write-TestResult "README Content" $false "" "Missing installation instructions"
            return $false
        }
        
        return $true
    }
    catch {
        Write-TestResult "Migration Scripts Test" $false "" $_.Exception.Message
        return $false
    }
}

function Test-MigrationConsistencyValidation {
    Write-Host "`n=== Testing Migration Consistency Validation ===" -ForegroundColor Cyan
    
    try {
        # Get available distributions for testing
        $distributions = wsl --list --quiet 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $distributions) {
            Write-TestResult "Distribution Availability" $false "" "No WSL distributions available for validation testing"
            return $false
        }
        
        $testDist = $distributions | Select-Object -First 1
        Write-Host "Testing validation with distribution: $testDist" -ForegroundColor Yellow
        
        # Test basic validation (without original metadata)
        $validationResult = Test-WSLMigrationConsistency -DistributionName $testDist
        
        if ($validationResult -and $validationResult.ContainsKey("ValidationPassed")) {
            Write-TestResult "Basic Validation Structure" $true "Validation result structure is correct"
        } else {
            Write-TestResult "Basic Validation Structure" $false "" "Validation result structure is invalid"
            return $false
        }
        
        # Test validation details
        if ($validationResult.ValidationDetails -and $validationResult.ValidationDetails.Count -gt 0) {
            Write-TestResult "Validation Details" $true "Validation details provided: $($validationResult.ValidationDetails.Count) items"
        } else {
            Write-TestResult "Validation Details" $false "" "No validation details provided"
        }
        
        # Test distribution existence check
        if ($validationResult.DistributionExists) {
            Write-TestResult "Distribution Existence Check" $true "Distribution existence correctly detected"
        } else {
            Write-TestResult "Distribution Existence Check" $false "" "Distribution existence check failed"
        }
        
        # Test distribution running check
        if ($validationResult.DistributionRunning) {
            Write-TestResult "Distribution Running Check" $true "Distribution can execute commands"
        } else {
            Write-TestResult "Distribution Running Check" $false "" "Distribution cannot execute commands"
        }
        
        return $true
    }
    catch {
        Write-TestResult "Migration Consistency Validation" $false "" $_.Exception.Message
        return $false
    }
}

function Test-MigrationHistory {
    Write-Host "`n=== Testing Migration History ===" -ForegroundColor Cyan
    
    try {
        # Test getting migration history
        $history = Get-WSLMigrationHistory
        
        if ($history -is [array] -or $history -eq $null) {
            Write-TestResult "Migration History Structure" $true "History returned as array or null"
        } else {
            Write-TestResult "Migration History Structure" $false "" "History returned in unexpected format"
            return $false
        }
        
        # If we have test package, check if it's in history
        if ($script:TestPackageResult -and $history) {
            $testMigration = $history | Where-Object { $_.MigrationId -eq $script:TestPackageResult.MigrationId }
            if ($testMigration) {
                Write-TestResult "Test Migration in History" $true "Test migration found in history"
            } else {
                Write-TestResult "Test Migration in History" $false "" "Test migration not found in history"
            }
        }
        
        # Test filtering by distribution name
        if ($history) {
            $firstMigration = $history | Select-Object -First 1
            if ($firstMigration -and $firstMigration.DistributionName) {
                $filteredHistory = Get-WSLMigrationHistory -DistributionName $firstMigration.DistributionName
                if ($filteredHistory) {
                    Write-TestResult "History Filtering" $true "Filtering by distribution name works"
                } else {
                    Write-TestResult "History Filtering" $false "" "Filtering returned no results"
                }
            }
        }
        
        return $true
    }
    catch {
        Write-TestResult "Migration History Test" $false "" $_.Exception.Message
        return $false
    }
}

function Test-PackageCleanup {
    Write-Host "`n=== Testing Package Cleanup ===" -ForegroundColor Cyan
    
    try {
        if (-not $script:TestPackageResult) {
            Write-TestResult "Package Cleanup" $true "No test package to clean up"
            return $true
        }
        
        # Clean up test package directory
        if (Test-Path $script:TestPackageResult.PackagePath) {
            Remove-Item $script:TestPackageResult.PackagePath -Recurse -Force
            Write-TestResult "Package Directory Cleanup" $true "Package directory removed"
        }
        
        # Clean up compressed package
        if ($script:TestPackageResult.CompressedPath -and (Test-Path $script:TestPackageResult.CompressedPath)) {
            Remove-Item $script:TestPackageResult.CompressedPath -Force
            Write-TestResult "Compressed Package Cleanup" $true "Compressed package removed"
        }
        
        return $true
    }
    catch {
        Write-TestResult "Package Cleanup" $false "" $_.Exception.Message
        return $false
    }
}

function Show-TestSummary {
    Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
    
    $totalTests = $script:TestResults.Count
    $passedTests = ($script:TestResults | Where-Object { $_.Passed }).Count
    $failedTests = $totalTests - $passedTests
    $successRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }
    
    Write-Host "Total Tests: $totalTests" -ForegroundColor White
    Write-Host "Passed: $passedTests" -ForegroundColor Green
    Write-Host "Failed: $failedTests" -ForegroundColor Red
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } else { "Yellow" })
    
    $duration = (Get-Date) - $script:TestStartTime
    Write-Host "Test Duration: $($duration.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Gray
    
    if ($failedTests -gt 0) {
        Write-Host "`nFailed Tests:" -ForegroundColor Red
        $script:TestResults | Where-Object { -not $_.Passed } | ForEach-Object {
            Write-Host "  - $($_.TestName): $($_.Error)" -ForegroundColor Red
        }
    }
    
    # Generate test report
    $reportPath = "$PSScriptRoot\WSL-Migration-Test-Report.json"
    $testReport = @{
        TestSuite = "WSL Migration Manager"
        ExecutionDate = $script:TestStartTime.ToString("yyyy-MM-dd HH:mm:ss")
        Duration = $duration.TotalSeconds
        Summary = @{
            TotalTests = $totalTests
            PassedTests = $passedTests
            FailedTests = $failedTests
            SuccessRate = $successRate
        }
        Results = $script:TestResults
    }
    
    $testReport | ConvertTo-Json -Depth 10 | Set-Content $reportPath -Encoding UTF8
    Write-Host "`nTest report saved: $reportPath" -ForegroundColor Gray
}

# Main test execution
function Start-MigrationTests {
    Write-Host "WSL Migration Manager Test Suite" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green
    
    # Run all tests
    $prerequisitesOk = Test-MigrationPrerequisites
    if (-not $prerequisitesOk) {
        Write-Host "`nPrerequisites not met. Stopping tests." -ForegroundColor Red
        Show-TestSummary
        return
    }
    
    Test-SystemEnvironmentInfo
    Test-WSLConfigurationCollection
    Test-MigrationPackageCreation
    Test-MigrationMetadataValidation
    Test-MigrationScripts
    Test-MigrationConsistencyValidation
    Test-MigrationHistory
    Test-PackageCleanup
    
    Show-TestSummary
}

# Run tests if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Start-MigrationTests
}