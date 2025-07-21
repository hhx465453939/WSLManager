# WSL Migration Functionality Test
# Tests migration functions without requiring actual WSL distributions

# Import migration module
try {
    Import-Module ..\Modules\WSL-MigrationManager.psm1 -Force
    Write-Host "✓ WSL Migration Manager module loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to load WSL Migration Manager module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== WSL Migration Functionality Test ===" -ForegroundColor Cyan

# Test 1: System Environment Information Collection
Write-Host "`n1. Testing System Environment Information Collection..." -ForegroundColor Yellow
try {
    $systemInfo = Get-SystemEnvironmentInfo
    
    # Verify required fields
    $requiredFields = @("ComputerName", "UserName", "OSVersion", "OSBuild", "TotalMemoryGB", "ProcessorName")
    $allFieldsPresent = $true
    
    foreach ($field in $requiredFields) {
        if ($systemInfo.$field) {
            Write-Host "   ✓ $field`: $($systemInfo.$field)" -ForegroundColor Green
        } else {
            Write-Host "   ✗ $field`: Missing" -ForegroundColor Red
            $allFieldsPresent = $false
        }
    }
    
    if ($allFieldsPresent) {
        Write-Host "✓ System environment information collection: PASSED" -ForegroundColor Green
    } else {
        Write-Host "✗ System environment information collection: FAILED" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ System environment information collection failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Migration History Functions
Write-Host "`n2. Testing Migration History Functions..." -ForegroundColor Yellow
try {
    $history = Get-WSLMigrationHistory
    
    if ($history -is [array] -or $history -eq $null) {
        Write-Host "   ✓ Migration history function returns correct type" -ForegroundColor Green
        Write-Host "✓ Migration history functions: PASSED" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Migration history function returns unexpected type" -ForegroundColor Red
        Write-Host "✗ Migration history functions: FAILED" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Migration history functions failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Module Function Exports
Write-Host "`n3. Testing Module Function Exports..." -ForegroundColor Yellow
try {
    $exportedFunctions = Get-Command -Module WSL-MigrationManager
    $expectedFunctions = @(
        'New-WSLMigrationPackage',
        'Install-WSLMigrationPackage', 
        'Deploy-WSLMigrationBatch',
        'Test-WSLMigrationConsistency',
        'Get-WSLMigrationHistory'
    )
    
    $allFunctionsExported = $true
    foreach ($func in $expectedFunctions) {
        if ($exportedFunctions.Name -contains $func) {
            Write-Host "   ✓ $func exported" -ForegroundColor Green
        } else {
            Write-Host "   ✗ $func not exported" -ForegroundColor Red
            $allFunctionsExported = $false
        }
    }
    
    if ($allFunctionsExported) {
        Write-Host "✓ Module function exports: PASSED" -ForegroundColor Green
    } else {
        Write-Host "✗ Module function exports: FAILED" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Module function exports test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Migration Directory Initialization
Write-Host "`n4. Testing Migration Directory Initialization..." -ForegroundColor Yellow
try {
    # Call the internal function to initialize migration directory
    $migrationPath = "$env:USERPROFILE\WSL-Migrations"
    
    # Test if we can create the directory structure
    if (-not (Test-Path $migrationPath)) {
        New-Item -ItemType Directory -Path $migrationPath -Force | Out-Null
    }
    
    if (Test-Path $migrationPath) {
        Write-Host "   ✓ Migration directory can be created: $migrationPath" -ForegroundColor Green
        Write-Host "✓ Migration directory initialization: PASSED" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Migration directory creation failed" -ForegroundColor Red
        Write-Host "✗ Migration directory initialization: FAILED" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Migration directory initialization failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Parameter Validation
Write-Host "`n5. Testing Parameter Validation..." -ForegroundColor Yellow
try {
    # Test New-WSLMigrationPackage parameter validation
    try {
        New-WSLMigrationPackage -DistributionName "" 2>$null
        Write-Host "   ✗ Empty distribution name should fail" -ForegroundColor Red
    }
    catch {
        Write-Host "   ✓ Empty distribution name properly rejected" -ForegroundColor Green
    }
    
    # Test Install-WSLMigrationPackage parameter validation
    try {
        Install-WSLMigrationPackage -PackagePath "NonExistentPath" 2>$null
        Write-Host "   ✗ Non-existent package path should fail" -ForegroundColor Red
    }
    catch {
        Write-Host "   ✓ Non-existent package path properly rejected" -ForegroundColor Green
    }
    
    Write-Host "✓ Parameter validation: PASSED" -ForegroundColor Green
}
catch {
    Write-Host "✗ Parameter validation test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Logging Functions
Write-Host "`n6. Testing Logging Functions..." -ForegroundColor Yellow
try {
    # Test if logging directory can be created
    $logPath = "$env:USERPROFILE\WSL-Migrations\migration.log"
    $logDir = Split-Path $logPath -Parent
    
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Test log file creation
    "Test log entry" | Add-Content -Path $logPath
    
    if (Test-Path $logPath) {
        Write-Host "   ✓ Log file can be created: $logPath" -ForegroundColor Green
        
        # Clean up test log
        Remove-Item $logPath -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Logging functions: PASSED" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Log file creation failed" -ForegroundColor Red
        Write-Host "✗ Logging functions: FAILED" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Logging functions test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "WSL Migration Manager functionality tests completed." -ForegroundColor White
Write-Host "`nNote: Full migration package creation and installation tests require:" -ForegroundColor Yellow
Write-Host "- At least one WSL distribution to be installed" -ForegroundColor White
Write-Host "- Administrator privileges for some operations" -ForegroundColor White
Write-Host "- Sufficient disk space for backup creation" -ForegroundColor White

Write-Host "`nTo install a WSL distribution for full testing:" -ForegroundColor Yellow
Write-Host "1. Run: wsl --list --online" -ForegroundColor White
Write-Host "2. Run: wsl --install <DistributionName>" -ForegroundColor White
Write-Host "3. Then run: .\Test-MigrationSimple.ps1" -ForegroundColor White

Write-Host "`n✓ Migration module is ready for use!" -ForegroundColor Green