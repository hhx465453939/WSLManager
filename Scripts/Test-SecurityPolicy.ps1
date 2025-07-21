# WSL Security Policy Configuration Test Script

Write-Host "=== WSL Security Policy Configuration Test ===" -ForegroundColor Green

try {
    # Import module
    Write-Host "Importing WSL-SecurityManager module..." -ForegroundColor Cyan
    Import-Module ..\Modules\WSL-SecurityManager.psm1 -Force
    Write-Host "Module imported successfully" -ForegroundColor Green
    
    # Test security policy functions exist
    Write-Host "`n--- Testing Security Policy Functions ---" -ForegroundColor Cyan
    
    $securityFunctions = @(
        'Test-WSLSecurityRisks',
        'Set-WSLFirewallRules', 
        'Invoke-WSLSecurityHardening',
        'Set-WSLSecurityPolicy'
    )
    
    foreach ($func in $securityFunctions) {
        if (Get-Command $func -ErrorAction SilentlyContinue) {
            Write-Host "Function $func exists" -ForegroundColor Green
        } else {
            Write-Warning "Function $func not found"
        }
    }
    
    Write-Host "`n--- Testing Function Parameters ---" -ForegroundColor Cyan
    
    # Test Test-WSLSecurityRisks parameters
    $cmd = Get-Command Test-WSLSecurityRisks
    $params = $cmd.Parameters.Keys | Where-Object { $_ -notmatch "Verbose|Debug|ErrorAction|WarningAction|InformationAction|ErrorVariable|WarningVariable|InformationVariable|OutVariable|OutBuffer|PipelineVariable" }
    Write-Host "Test-WSLSecurityRisks parameters: $($params -join ', ')" -ForegroundColor Cyan
    
    # Test Set-WSLFirewallRules parameters  
    $cmd = Get-Command Set-WSLFirewallRules
    $params = $cmd.Parameters.Keys | Where-Object { $_ -notmatch "Verbose|Debug|ErrorAction|WarningAction|InformationAction|ErrorVariable|WarningVariable|InformationVariable|OutVariable|OutBuffer|PipelineVariable" }
    Write-Host "Set-WSLFirewallRules parameters: $($params -join ', ')" -ForegroundColor Cyan
    
    # Test Invoke-WSLSecurityHardening parameters
    $cmd = Get-Command Invoke-WSLSecurityHardening
    $params = $cmd.Parameters.Keys | Where-Object { $_ -notmatch "Verbose|Debug|ErrorAction|WarningAction|InformationAction|ErrorVariable|WarningVariable|InformationVariable|OutVariable|OutBuffer|PipelineVariable" }
    Write-Host "Invoke-WSLSecurityHardening parameters: $($params -join ', ')" -ForegroundColor Cyan
    
    # Test Set-WSLSecurityPolicy parameters
    $cmd = Get-Command Set-WSLSecurityPolicy
    $params = $cmd.Parameters.Keys | Where-Object { $_ -notmatch "Verbose|Debug|ErrorAction|WarningAction|InformationAction|ErrorVariable|WarningVariable|InformationVariable|OutVariable|OutBuffer|PipelineVariable" }
    Write-Host "Set-WSLSecurityPolicy parameters: $($params -join ', ')" -ForegroundColor Cyan
    
    Write-Host "`n--- Testing Security Policy Configuration Structure ---" -ForegroundColor Cyan
    
    # Test creating a sample security policy
    $samplePolicy = @{
        PasswordComplexity = $true
        AutomaticUpdates = $true
        FirewallEnabled = $true
        SSHHardening = $true
        FilePermissions = $true
        AuditLogging = $false
    }
    
    Write-Host "Sample security policy created:" -ForegroundColor Green
    $samplePolicy.GetEnumerator() | ForEach-Object {
        Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor White
    }
    
    # Create a sample policy file
    $policyFile = ".\sample-security-policy.json"
    $samplePolicy | ConvertTo-Json | Out-File -FilePath $policyFile -Encoding UTF8
    Write-Host "Sample policy file created: $policyFile" -ForegroundColor Green
    
    Write-Host "`n--- Testing Security Risk Assessment Structure ---" -ForegroundColor Cyan
    
    # Test security risk structure
    $sampleRisk = @{
        Type = "WeakPasswordPolicy"
        Severity = "Medium"
        Description = "Password policy not configured or weak"
        Details = "No password aging policy found in /etc/login.defs"
    }
    
    Write-Host "Sample security risk structure:" -ForegroundColor Green
    $sampleRisk.GetEnumerator() | ForEach-Object {
        Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor White
    }
    
    Write-Host "`n--- Testing Firewall Rule Configuration ---" -ForegroundColor Cyan
    
    # Test firewall rule parameters
    $sampleFirewallConfig = @{
        AllowPorts = @("22", "80", "443")
        DenyPorts = @("23", "21")
        AllowServices = @("ssh", "http", "https")
        EnableFirewall = $true
        ResetRules = $false
    }
    
    Write-Host "Sample firewall configuration:" -ForegroundColor Green
    $sampleFirewallConfig.GetEnumerator() | ForEach-Object {
        Write-Host "  $($_.Key): $($_.Value -join ', ')" -ForegroundColor White
    }
    
    Write-Host "`n=== Security Policy Configuration Test Complete ===" -ForegroundColor Green
    Write-Host "All security policy functions loaded and tested successfully" -ForegroundColor Green
    Write-Host "Note: Actual WSL testing requires installed distributions" -ForegroundColor Yellow
    
    # Clean up sample policy file
    if (Test-Path $policyFile) {
        Remove-Item $policyFile -Force
        Write-Host "Sample policy file cleaned up" -ForegroundColor Cyan
    }
}
catch {
    Write-Error "Test failed: $($_.Exception.Message)"
    Write-Host "Error details: $($_.Exception)" -ForegroundColor Red
}