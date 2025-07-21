# Simple WSL Backup Test
param(
    [string]$TestDistribution = "Ubuntu"
)

Write-Host "Testing WSL Backup Manager..." -ForegroundColor Cyan

try {
    # Import the module
    Import-Module "$PSScriptRoot\WSL-BackupManager.psm1" -Force -ErrorAction Stop
    Write-Host "Module imported successfully" -ForegroundColor Green
    
    # Check available functions
    $functions = Get-Command -Module WSL-BackupManager
    Write-Host "Available functions: $($functions.Name -join ', ')" -ForegroundColor Yellow
    
    # Test getting WSL distributions
    Write-Host "`nChecking WSL distributions..." -ForegroundColor Yellow
    $wslList = wsl --list --quiet 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $wslList) {
        Write-Host "No WSL distributions found. Please install a WSL distribution first." -ForegroundColor Yellow
        exit 0
    }
    
    $availableDistros = $wslList | Where-Object { $_ -and $_.Trim() -ne "" }
    Write-Host "Available distributions: $($availableDistros -join ', ')" -ForegroundColor Green
    
    # Use the first available distribution for testing
    $testDist = $availableDistros[0].Trim()
    Write-Host "Using distribution: $testDist" -ForegroundColor Cyan
    
    # Test getting distribution info
    Write-Host "`nTesting Get-WSLDistributionInfo..." -ForegroundColor Yellow
    $distInfo = Get-WSLDistributionInfo -DistributionName $testDist
    Write-Host "Distribution info retrieved successfully:" -ForegroundColor Green
    Write-Host "  Name: $($distInfo.Name)"
    Write-Host "  Status: $($distInfo.Status)"
    Write-Host "  Version: $($distInfo.Version)"
    
    # Test backup list (should be empty initially)
    Write-Host "`nTesting Get-WSLBackupList..." -ForegroundColor Yellow
    $backups = Get-WSLBackupList -DistributionName $testDist
    Write-Host "Current backups for ${testDist}: $($backups.Count)" -ForegroundColor Green
    
    Write-Host "`nBasic functionality test completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $($_.Exception.ToString())" -ForegroundColor Red
    exit 1
}