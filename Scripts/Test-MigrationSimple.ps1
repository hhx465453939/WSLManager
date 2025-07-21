# Simple WSL Migration Test
# Basic test for migration package creation and validation

param(
    [string]$DistributionName = $null,
    [switch]$SkipPackageCreation,
    [switch]$CleanupAfterTest
)

# Import migration module
try {
    Import-Module ..\Modules\WSL-MigrationManager.psm1 -Force
    Write-Host "✓ WSL Migration Manager module loaded" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to load WSL Migration Manager module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Get available distributions
Write-Host "`nChecking available WSL distributions..." -ForegroundColor Yellow
$distributions = wsl --list --quiet 2>$null

if ($LASTEXITCODE -ne 0 -or -not $distributions) {
    Write-Host "✗ No WSL distributions found. Please install a WSL distribution first." -ForegroundColor Red
    exit 1
}

# Select distribution for testing
if (-not $DistributionName) {
    $DistributionName = $distributions | Select-Object -First 1
}

if ($distributions -notcontains $DistributionName) {
    Write-Host "✗ Distribution '$DistributionName' not found." -ForegroundColor Red
    Write-Host "Available distributions: $($distributions -join ', ')" -ForegroundColor Gray
    exit 1
}

Write-Host "✓ Using distribution: $DistributionName" -ForegroundColor Green

# Test 1: System Environment Information
Write-Host "`n=== Test 1: System Environment Information ===" -ForegroundColor Cyan
try {
    $systemInfo = Get-SystemEnvironmentInfo
    Write-Host "✓ Computer: $($systemInfo.ComputerName)" -ForegroundColor Green
    Write-Host "✓ OS: $($systemInfo.OSVersion) Build $($systemInfo.OSBuild)" -ForegroundColor Green
    Write-Host "✓ Memory: $($systemInfo.TotalMemoryGB) GB" -ForegroundColor Green
    Write-Host "✓ Processor: $($systemInfo.ProcessorName)" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to get system environment info: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: WSL Configuration Collection
Write-Host "`n=== Test 2: WSL Configuration Collection ===" -ForegroundColor Cyan
try {
    $wslConfig = Get-WSLConfigurationForMigration -DistributionName $DistributionName
    Write-Host "✓ Distribution: $($wslConfig.DistributionName)" -ForegroundColor Green
    Write-Host "✓ Default User: $($wslConfig.DefaultUser)" -ForegroundColor Green
    Write-Host "✓ Installed Packages: $($wslConfig.InstalledPackages.Count)" -ForegroundColor Green
    Write-Host "✓ Environment Variables: $($wslConfig.EnvironmentVariables.Count)" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to get WSL configuration: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Migration Package Creation
if (-not $SkipPackageCreation) {
    Write-Host "`n=== Test 3: Migration Package Creation ===" -ForegroundColor Cyan
    try {
        Write-Host "Creating migration package (this may take several minutes)..." -ForegroundColor Yellow
        $packageResult = New-WSLMigrationPackage -DistributionName $DistributionName -IncludeSystemInfo -Compress
        
        Write-Host "✓ Migration package created successfully!" -ForegroundColor Green
        Write-Host "✓ Migration ID: $($packageResult.MigrationId)" -ForegroundColor Green
        Write-Host "✓ Package Path: $($packageResult.PackagePath)" -ForegroundColor Green
        Write-Host "✓ Package Size: $($packageResult.Size) MB" -ForegroundColor Green
        
        if ($packageResult.CompressedPath) {
            Write-Host "✓ Compressed Package: $($packageResult.CompressedPath)" -ForegroundColor Green
        }
        
        # Test package contents
        Write-Host "`nChecking package contents..." -ForegroundColor Yellow
        $requiredFiles = @("migration-metadata.json", "install-migration.ps1", "validate-migration.ps1", "README.md", "$DistributionName.tar")
        
        foreach ($file in $requiredFiles) {
            $filePath = Join-Path $packageResult.PackagePath $file
            if (Test-Path $filePath) {
                $fileSize = [math]::Round((Get-Item $filePath).Length / 1KB, 2)
                Write-Host "✓ $file ($fileSize KB)" -ForegroundColor Green
            } else {
                Write-Host "✗ $file (missing)" -ForegroundColor Red
            }
        }
        
        # Store package info for cleanup
        $script:TestPackageResult = $packageResult
    }
    catch {
        Write-Host "✗ Failed to create migration package: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 4: Migration Validation
Write-Host "`n=== Test 4: Migration Validation ===" -ForegroundColor Cyan
try {
    $validationResult = Test-WSLMigrationConsistency -DistributionName $DistributionName
    
    if ($validationResult.ValidationPassed) {
        Write-Host "✓ Migration validation passed" -ForegroundColor Green
    } else {
        Write-Host "✗ Migration validation failed" -ForegroundColor Red
    }
    
    Write-Host "Validation details:" -ForegroundColor Gray
    foreach ($detail in $validationResult.ValidationDetails) {
        if ($detail -like "*✓*") {
            Write-Host "  $detail" -ForegroundColor Green
        } else {
            Write-Host "  $detail" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "✗ Failed to run migration validation: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Migration History
Write-Host "`n=== Test 5: Migration History ===" -ForegroundColor Cyan
try {
    $history = Get-WSLMigrationHistory
    
    if ($history -and $history.Count -gt 0) {
        Write-Host "✓ Found $($history.Count) migration record(s)" -ForegroundColor Green
        
        # Show latest migration
        $latest = $history | Select-Object -First 1
        Write-Host "Latest migration:" -ForegroundColor Gray
        Write-Host "  Distribution: $($latest.DistributionName)" -ForegroundColor Gray
        Write-Host "  Created: $($latest.CreatedDate)" -ForegroundColor Gray
        Write-Host "  Source: $($latest.SourceComputer)" -ForegroundColor Gray
        Write-Host "  Migration ID: $($latest.MigrationId)" -ForegroundColor Gray
    } else {
        Write-Host "✓ No migration history found (this is normal for first run)" -ForegroundColor Green
    }
}
catch {
    Write-Host "✗ Failed to get migration history: $($_.Exception.Message)" -ForegroundColor Red
}

# Cleanup
if ($CleanupAfterTest -and $script:TestPackageResult) {
    Write-Host "`n=== Cleanup ===" -ForegroundColor Cyan
    try {
        if (Test-Path $script:TestPackageResult.PackagePath) {
            Remove-Item $script:TestPackageResult.PackagePath -Recurse -Force
            Write-Host "✓ Cleaned up package directory" -ForegroundColor Green
        }
        
        if ($script:TestPackageResult.CompressedPath -and (Test-Path $script:TestPackageResult.CompressedPath)) {
            Remove-Item $script:TestPackageResult.CompressedPath -Force
            Write-Host "✓ Cleaned up compressed package" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "✗ Cleanup failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
Write-Host "WSL Migration functionality test completed." -ForegroundColor White

if (-not $SkipPackageCreation -and $script:TestPackageResult -and -not $CleanupAfterTest) {
    Write-Host "`nMigration package created at:" -ForegroundColor Yellow
    Write-Host "$($script:TestPackageResult.PackagePath)" -ForegroundColor White
    if ($script:TestPackageResult.CompressedPath) {
        Write-Host "Compressed package: $($script:TestPackageResult.CompressedPath)" -ForegroundColor White
    }
    Write-Host "`nTo test installation on another machine:" -ForegroundColor Yellow
    Write-Host "1. Copy the package to the target machine" -ForegroundColor White
    Write-Host "2. Run: .\install-migration.ps1 -ValidateAfterInstall" -ForegroundColor White
}