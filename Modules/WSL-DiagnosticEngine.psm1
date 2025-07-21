# WSL Diagnostic Engine Module
# Provides fault diagnosis and automatic repair functions for WSL environment

# Import necessary modules
if (Get-Module WSL-Detection) { Remove-Module WSL-Detection }
if (Get-Module WSL-HealthMonitor) { Remove-Module WSL-HealthMonitor }
Import-Module "$PSScriptRoot\WSL-Detection.psm1" -Force
Import-Module "$PSScriptRoot\WSL-HealthMonitor.psm1" -Force

# Common WSL problem diagnosis function
function Invoke-WSLDiagnostics {
    <#
    .SYNOPSIS
    Diagnose common WSL problems
    
    .DESCRIPTION
    Diagnose common WSL issues including path problems, permission issues, service status, cleanup residuals, WSL environment recovery, system cannot find WSL command specified path, etc.
    
    .PARAMETER ProblemType
    Specify the type of problem to diagnose: All, Path, Permission, Service, Network, Installation
    
    .PARAMETER AutoFix
    Automatically attempt to fix detected problems
    
    .EXAMPLE
    Invoke-WSLDiagnostics
    Invoke-WSLDiagnostics -ProblemType "Service" -AutoFix
    #>
    [CmdletBinding()]
    param(
        [ValidateSet("All", "Path", "Permission", "Service", "Network", "Installation")]
        [string]$ProblemType = "All",
        [switch]$AutoFix
    )
    
    Write-Host "Starting WSL diagnostic engine..." -ForegroundColor Green
    Write-Host "Diagnostic time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host "Problem type: $ProblemType" -ForegroundColor Gray
    Write-Host "=" * 50 -ForegroundColor Gray
    
    $diagnosticResults = @{
        Timestamp = Get-Date
        ProblemType = $ProblemType
        Issues = @()
        Fixes = @()
        OverallStatus = "Unknown"
    }
    
    # Diagnose different types of problems
    if ($ProblemType -eq "All" -or $ProblemType -eq "Installation") {
        $installationIssues = Test-WSLInstallationIssues
        if ($installationIssues.Count -gt 0) {
            $diagnosticResults.Issues += $installationIssues
            if ($AutoFix) {
                $fixes = Repair-WSLInstallation
                $diagnosticResults.Fixes += $fixes
            }
        }
    }
    
    if ($ProblemType -eq "All" -or $ProblemType -eq "Service") {
        $serviceIssues = Test-WSLServiceIssues
        if ($serviceIssues.Count -gt 0) {
            $diagnosticResults.Issues += $serviceIssues
            if ($AutoFix) {
                $fixes = Repair-WSLServices
                $diagnosticResults.Fixes += $fixes
            }
        }
    }
    
    if ($ProblemType -eq "All" -or $ProblemType -eq "Path") {
        $pathIssues = Test-WSLPathIssues
        if ($pathIssues.Count -gt 0) {
            $diagnosticResults.Issues += $pathIssues
            if ($AutoFix) {
                $fixes = Repair-WSLPathIssues
                $diagnosticResults.Fixes += $fixes
            }
        }
    }
    
    if ($ProblemType -eq "All" -or $ProblemType -eq "Permission") {
        $permissionIssues = Test-WSLPermissionIssues
        if ($permissionIssues.Count -gt 0) {
            $diagnosticResults.Issues += $permissionIssues
            if ($AutoFix) {
                $fixes = Repair-WSLPermissions
                $diagnosticResults.Fixes += $fixes
            }
        }
    }
    
    if ($ProblemType -eq "All" -or $ProblemType -eq "Network") {
        $networkIssues = Test-WSLNetworkIssues
        if ($networkIssues.Count -gt 0) {
            $diagnosticResults.Issues += $networkIssues
            if ($AutoFix) {
                $fixes = Repair-WSLNetwork
                $diagnosticResults.Fixes += $fixes
            }
        }
    }
    
    # Determine overall status
    if ($diagnosticResults.Issues.Count -eq 0) {
        $diagnosticResults.OverallStatus = "Healthy"
    } elseif ($diagnosticResults.Fixes.Count -gt 0) {
        $diagnosticResults.OverallStatus = "Fixed"
    } else {
        $diagnosticResults.OverallStatus = "Issues Found"
    }
    
    # Display results
    Write-Host "`n" + "=" * 50 -ForegroundColor Gray
    Write-Host "WSL diagnostic completed" -ForegroundColor Green
    Write-Host "Overall status: $($diagnosticResults.OverallStatus)" -ForegroundColor $(
        switch ($diagnosticResults.OverallStatus) {
            "Healthy" { "Green" }
            "Fixed" { "Yellow" }
            "Issues Found" { "Red" }
            default { "Gray" }
        }
    )
    
    if ($diagnosticResults.Issues.Count -gt 0) {
        Write-Host "`nIssues found:" -ForegroundColor Red
        foreach ($issue in $diagnosticResults.Issues) {
            Write-Host "  • $($issue.Description)" -ForegroundColor Red
            Write-Host "    Severity: $($issue.Severity)" -ForegroundColor Yellow
            Write-Host "    Recommendation: $($issue.Recommendation)" -ForegroundColor Cyan
        }
    }
    
    if ($diagnosticResults.Fixes.Count -gt 0) {
        Write-Host "`nFixes applied:" -ForegroundColor Green
        foreach ($fix in $diagnosticResults.Fixes) {
            Write-Host "  • $($fix.Description)" -ForegroundColor Green
            Write-Host "    Status: $($fix.Status)" -ForegroundColor $(if($fix.Status -eq "Success") {"Green"} else {"Red"})
        }
    }
    
    return $diagnosticResults
}

# Test WSL installation issues
function Test-WSLInstallationIssues {
    [CmdletBinding()]
    param()
    
    Write-Host "Checking WSL installation issues..." -ForegroundColor Yellow
    $issues = @()
    
    # Check if WSL is installed
    $wslCommand = Get-Command wsl -ErrorAction SilentlyContinue
    if (-not $wslCommand) {
        $issues += @{
            Type = "Installation"
            Severity = "Critical"
            Description = "WSL command not found - WSL may not be installed"
            Recommendation = "Install WSL using 'wsl --install' or enable WSL feature in Windows Features"
            FixAction = "InstallWSL"
        }
    }
    
    # Check WSL version
    $wslVersion = wsl --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        $issues += @{
            Type = "Installation"
            Severity = "High"
            Description = "Cannot determine WSL version - WSL may be corrupted"
            Recommendation = "Reinstall WSL or update to latest version"
            FixAction = "UpdateWSL"
        }
    }
    
    # Check if any distributions are installed
    $distributions = wsl -l -q 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $distributions) {
        $issues += @{
            Type = "Installation"
            Severity = "Medium"
            Description = "No WSL distributions installed"
            Recommendation = "Install a Linux distribution from Microsoft Store or using wsl --install"
            FixAction = "InstallDistribution"
        }
    }
    
    return $issues
}

# Test WSL service issues
function Test-WSLServiceIssues {
    [CmdletBinding()]
    param()
    
    Write-Host "Checking WSL service issues..." -ForegroundColor Yellow
    $issues = @()
    
    # Check LxssManager service
    $lxssService = Get-Service -Name "LxssManager" -ErrorAction SilentlyContinue
    if (-not $lxssService) {
        $issues += @{
            Type = "Service"
            Severity = "Critical"
            Description = "LxssManager service not found"
            Recommendation = "WSL feature may not be properly installed"
            FixAction = "EnableWSLFeature"
        }
    } elseif ($lxssService.Status -ne "Running") {
        $issues += @{
            Type = "Service"
            Severity = "High"
            Description = "LxssManager service is not running"
            Recommendation = "Start the LxssManager service"
            FixAction = "StartLxssManager"
        }
    }
    
    # Check Virtual Machine Platform feature
    $vmPlatform = Get-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -ErrorAction SilentlyContinue
    if (-not $vmPlatform -or $vmPlatform.State -ne "Enabled") {
        $issues += @{
            Type = "Service"
            Severity = "High"
            Description = "Virtual Machine Platform feature is not enabled"
            Recommendation = "Enable Virtual Machine Platform feature"
            FixAction = "EnableVMPlatform"
        }
    }
    
    # Check WSL feature
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -ErrorAction SilentlyContinue
    if (-not $wslFeature -or $wslFeature.State -ne "Enabled") {
        $issues += @{
            Type = "Service"
            Severity = "Critical"
            Description = "WSL feature is not enabled"
            Recommendation = "Enable Windows Subsystem for Linux feature"
            FixAction = "EnableWSLFeature"
        }
    }
    
    return $issues
}

# Test WSL path issues
function Test-WSLPathIssues {
    [CmdletBinding()]
    param()
    
    Write-Host "Checking WSL path issues..." -ForegroundColor Yellow
    $issues = @()
    
    # Check if WSL is in PATH
    $wslPath = (Get-Command wsl -ErrorAction SilentlyContinue).Source
    if (-not $wslPath) {
        $issues += @{
            Type = "Path"
            Severity = "High"
            Description = "WSL command not found in PATH"
            Recommendation = "Add WSL installation directory to system PATH"
            FixAction = "FixWSLPath"
        }
    }
    
    # Check WSL installation directory
    $systemRoot = $env:SystemRoot
    $wslExePath = "$systemRoot\System32\wsl.exe"
    if (-not (Test-Path $wslExePath)) {
        $issues += @{
            Type = "Path"
            Severity = "Critical"
            Description = "WSL executable not found in expected location"
            Recommendation = "Reinstall WSL or repair Windows installation"
            FixAction = "RepairWSLInstallation"
        }
    }
    
    # Check for WSL distribution paths
    $distributions = wsl -l -q 2>$null
    if ($distributions) {
        foreach ($dist in $distributions) {
            if ($dist.Trim()) {
                $distPath = wsl -d $dist.Trim() pwd 2>$null
                if ($LASTEXITCODE -ne 0) {
                    $issues += @{
                        Type = "Path"
                        Severity = "Medium"
                        Description = "Cannot access distribution '$($dist.Trim())' filesystem"
                        Recommendation = "Check distribution integrity or reinstall"
                        FixAction = "RepairDistribution"
                    }
                }
            }
        }
    }
    
    return $issues
}

# Test WSL permission issues
function Test-WSLPermissionIssues {
    [CmdletBinding()]
    param()
    
    Write-Host "Checking WSL permission issues..." -ForegroundColor Yellow
    $issues = @()
    
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    # Check WSL directory permissions
    $wslDataPath = "$env:LOCALAPPDATA\Packages"
    if (Test-Path $wslDataPath) {
        $wslPackages = Get-ChildItem $wslDataPath | Where-Object { $_.Name -match "CanonicalGroupLimited|SUSE|Debian" }
        foreach ($package in $wslPackages) {
            try {
                $testFile = "$($package.FullName)\test_permission.tmp"
                "test" | Out-File -FilePath $testFile -ErrorAction Stop
                Remove-Item $testFile -ErrorAction SilentlyContinue
            }
            catch {
                $issues += @{
                    Type = "Permission"
                    Severity = "Medium"
                    Description = "Cannot write to WSL package directory: $($package.Name)"
                    Recommendation = "Check file permissions or run as administrator"
                    FixAction = "FixPackagePermissions"
                }
            }
        }
    }
    
    # Check registry permissions for WSL
    try {
        $wslRegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
        if (Test-Path $wslRegKey) {
            Get-ItemProperty $wslRegKey -ErrorAction Stop | Out-Null
        }
    }
    catch {
        $issues += @{
            Type = "Permission"
            Severity = "Medium"
            Description = "Cannot access WSL registry keys"
            Recommendation = "Run as administrator or check registry permissions"
            FixAction = "FixRegistryPermissions"
        }
    }
    
    return $issues
}

# Test WSL network issues
function Test-WSLNetworkIssues {
    [CmdletBinding()]
    param()
    
    Write-Host "Checking WSL network issues..." -ForegroundColor Yellow
    $issues = @()
    
    # Check WSL network adapters
    $wslAdapters = Get-NetAdapter | Where-Object { $_.Name -match "WSL|vEthernet" }
    if ($wslAdapters.Count -eq 0) {
        $issues += @{
            Type = "Network"
            Severity = "Medium"
            Description = "No WSL network adapters found"
            Recommendation = "WSL networking may not be properly configured"
            FixAction = "ResetWSLNetwork"
        }
    } else {
        foreach ($adapter in $wslAdapters) {
            if ($adapter.Status -ne "Up") {
                $issues += @{
                    Type = "Network"
                    Severity = "Medium"
                    Description = "WSL network adapter '$($adapter.Name)' is not active"
                    Recommendation = "Restart WSL or reset network configuration"
                    FixAction = "RestartWSLNetwork"
                }
            }
        }
    }
    
    # Test network connectivity from WSL
    $distributions = wsl -l -q 2>$null
    if ($distributions) {
        $defaultDist = ($distributions | Select-Object -First 1).Trim()
        if ($defaultDist) {
            $pingResult = wsl -d $defaultDist -- ping -c 1 8.8.8.8 2>$null
            if ($LASTEXITCODE -ne 0) {
                $issues += @{
                    Type = "Network"
                    Severity = "High"
                    Description = "WSL cannot reach external network"
                    Recommendation = "Check WSL network configuration and Windows firewall"
                    FixAction = "FixWSLConnectivity"
                }
            }
        }
    }
    
    return $issues
}

# Repair WSL installation
function Repair-WSLInstallation {
    [CmdletBinding()]
    param()
    
    Write-Host "Attempting to repair WSL installation..." -ForegroundColor Yellow
    $fixes = @()
    
    # Enable WSL feature if not enabled
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -ErrorAction SilentlyContinue
    if (-not $wslFeature -or $wslFeature.State -ne "Enabled") {
        try {
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart
            $fixes += @{
                Description = "Enabled WSL feature"
                Status = "Success"
                RequiresRestart = $true
            }
        }
        catch {
            $fixes += @{
                Description = "Failed to enable WSL feature: $($_.Exception.Message)"
                Status = "Failed"
                RequiresRestart = $false
            }
        }
    }
    
    # Enable Virtual Machine Platform if not enabled
    $vmPlatform = Get-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -ErrorAction SilentlyContinue
    if (-not $vmPlatform -or $vmPlatform.State -ne "Enabled") {
        try {
            Enable-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -NoRestart
            $fixes += @{
                Description = "Enabled Virtual Machine Platform"
                Status = "Success"
                RequiresRestart = $true
            }
        }
        catch {
            $fixes += @{
                Description = "Failed to enable Virtual Machine Platform: $($_.Exception.Message)"
                Status = "Failed"
                RequiresRestart = $false
            }
        }
    }
    
    return $fixes
}

# Repair WSL services
function Repair-WSLServices {
    [CmdletBinding()]
    param()
    
    Write-Host "Attempting to repair WSL services..." -ForegroundColor Yellow
    $fixes = @()
    
    # Start LxssManager service
    $lxssService = Get-Service -Name "LxssManager" -ErrorAction SilentlyContinue
    if ($lxssService -and $lxssService.Status -ne "Running") {
        try {
            Start-Service -Name "LxssManager"
            $fixes += @{
                Description = "Started LxssManager service"
                Status = "Success"
                RequiresRestart = $false
            }
        }
        catch {
            $fixes += @{
                Description = "Failed to start LxssManager service: $($_.Exception.Message)"
                Status = "Failed"
                RequiresRestart = $false
            }
        }
    }
    
    # Restart WSL
    try {
        wsl --shutdown
        Start-Sleep -Seconds 3
        wsl --status
        $fixes += @{
            Description = "Restarted WSL subsystem"
            Status = "Success"
            RequiresRestart = $false
        }
    }
    catch {
        $fixes += @{
            Description = "Failed to restart WSL: $($_.Exception.Message)"
            Status = "Failed"
            RequiresRestart = $false
        }
    }
    
    return $fixes
}

# Repair WSL path issues
function Repair-WSLPathIssues {
    [CmdletBinding()]
    param()
    
    Write-Host "Attempting to repair WSL path issues..." -ForegroundColor Yellow
    $fixes = @()
    
    # Add WSL to PATH if missing
    $systemRoot = $env:SystemRoot
    $wslPath = "$systemRoot\System32"
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    
    if ($currentPath -notlike "*$wslPath*") {
        try {
            $newPath = "$currentPath;$wslPath"
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
            $fixes += @{
                Description = "Added WSL directory to system PATH"
                Status = "Success"
                RequiresRestart = $false
            }
        }
        catch {
            $fixes += @{
                Description = "Failed to update system PATH: $($_.Exception.Message)"
                Status = "Failed"
                RequiresRestart = $false
            }
        }
    }
    
    return $fixes
}

# Repair WSL permissions
function Repair-WSLPermissions {
    [CmdletBinding()]
    param()
    
    Write-Host "Attempting to repair WSL permissions..." -ForegroundColor Yellow
    $fixes = @()
    
    # Fix WSL package directory permissions
    $wslDataPath = "$env:LOCALAPPDATA\Packages"
    if (Test-Path $wslDataPath) {
        $wslPackages = Get-ChildItem $wslDataPath | Where-Object { $_.Name -match "CanonicalGroupLimited|SUSE|Debian" }
        foreach ($package in $wslPackages) {
            try {
                $acl = Get-Acl $package.FullName
                $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
                $acl.SetAccessRule($accessRule)
                Set-Acl $package.FullName $acl
                $fixes += @{
                    Description = "Fixed permissions for WSL package: $($package.Name)"
                    Status = "Success"
                    RequiresRestart = $false
                }
            }
            catch {
                $fixes += @{
                    Description = "Failed to fix permissions for $($package.Name): $($_.Exception.Message)"
                    Status = "Failed"
                    RequiresRestart = $false
                }
            }
        }
    }
    
    return $fixes
}

# Repair WSL network
function Repair-WSLNetwork {
    [CmdletBinding()]
    param()
    
    Write-Host "Attempting to repair WSL network..." -ForegroundColor Yellow
    $fixes = @()
    
    # Reset WSL network
    try {
        wsl --shutdown
        Start-Sleep -Seconds 5
        
        # Restart network adapters
        $wslAdapters = Get-NetAdapter | Where-Object { $_.Name -match "WSL|vEthernet" }
        foreach ($adapter in $wslAdapters) {
            Disable-NetAdapter -Name $adapter.Name -Confirm:$false
            Enable-NetAdapter -Name $adapter.Name -Confirm:$false
        }
        
        $fixes += @{
            Description = "Reset WSL network configuration"
            Status = "Success"
            RequiresRestart = $false
        }
    }
    catch {
        $fixes += @{
            Description = "Failed to reset WSL network: $($_.Exception.Message)"
            Status = "Failed"
            RequiresRestart = $false
        }
    }
    
    return $fixes
}

# Generate diagnostic report
function New-WSLDiagnosticReport {
    <#
    .SYNOPSIS
    Generate comprehensive WSL diagnostic report
    
    .DESCRIPTION
    Generate a detailed diagnostic report including system information, health status, and recommendations
    
    .PARAMETER OutputPath
    Path to save the diagnostic report
    
    .PARAMETER Format
    Report format: HTML, JSON, Text
    
    .EXAMPLE
    New-WSLDiagnosticReport -OutputPath "C:\WSL_Report.html" -Format "HTML"
    #>
    [CmdletBinding()]
    param(
        [string]$OutputPath,
        [ValidateSet("HTML", "JSON", "Text")]
        [string]$Format = "HTML"
    )
    
    Write-Host "Generating WSL diagnostic report..." -ForegroundColor Green
    
    # Collect diagnostic information
    $healthReport = Test-WSLHealth
    $diagnosticResults = Invoke-WSLDiagnostics
    $systemInfo = Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, TotalPhysicalMemory
    
    $report = @{
        GeneratedAt = Get-Date
        SystemInfo = $systemInfo
        HealthReport = $healthReport
        DiagnosticResults = $diagnosticResults
        Summary = @{
            OverallStatus = if ($diagnosticResults.OverallStatus -eq "Healthy" -and $healthReport.OverallHealth -eq "Healthy") { "Healthy" } else { "Issues Found" }
            TotalIssues = $diagnosticResults.Issues.Count
            CriticalIssues = ($diagnosticResults.Issues | Where-Object { $_.Severity -eq "Critical" }).Count
            FixesApplied = $diagnosticResults.Fixes.Count
        }
    }
    
    # Generate report based on format
    switch ($Format) {
        "JSON" {
            $reportContent = $report | ConvertTo-Json -Depth 10
        }
        "HTML" {
            $reportContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>WSL Diagnostic Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 10px; border-radius: 5px; }
        .section { margin: 20px 0; }
        .issue { background-color: #ffe6e6; padding: 10px; margin: 5px 0; border-radius: 3px; }
        .fix { background-color: #e6ffe6; padding: 10px; margin: 5px 0; border-radius: 3px; }
        .healthy { color: green; }
        .warning { color: orange; }
        .critical { color: red; }
    </style>
</head>
<body>
    <div class="header">
        <h1>WSL Diagnostic Report</h1>
        <p>Generated: $($report.GeneratedAt)</p>
        <p>Overall Status: <span class="$(if($report.Summary.OverallStatus -eq 'Healthy') {'healthy'} else {'critical'})">$($report.Summary.OverallStatus)</span></p>
    </div>
    
    <div class="section">
        <h2>System Information</h2>
        <p>Windows Version: $($report.SystemInfo.WindowsProductName) $($report.SystemInfo.WindowsVersion)</p>
        <p>Total Memory: $([math]::Round($report.SystemInfo.TotalPhysicalMemory / 1GB, 2)) GB</p>
    </div>
    
    <div class="section">
        <h2>Health Summary</h2>
        <p>Overall Health: $($report.HealthReport.OverallHealth)</p>
        <p>Service Status: $($report.HealthReport.ServiceStatus.OverallStatus)</p>
        <p>Network Status: $($report.HealthReport.NetworkStatus.OverallStatus)</p>
        <p>Memory Usage: $($report.HealthReport.ResourceUsage.SystemMemory.UsagePercent)%</p>
    </div>
    
    <div class="section">
        <h2>Issues Found ($($report.Summary.TotalIssues))</h2>
"@
            foreach ($issue in $diagnosticResults.Issues) {
                $reportContent += @"
        <div class="issue">
            <strong>$($issue.Description)</strong><br>
            Severity: <span class="$(if($issue.Severity -eq 'Critical') {'critical'} elseif($issue.Severity -eq 'High') {'warning'} else {'healthy'})">$($issue.Severity)</span><br>
            Recommendation: $($issue.Recommendation)
        </div>
"@
            }
            
            $reportContent += @"
    </div>
    
    <div class="section">
        <h2>Fixes Applied ($($report.Summary.FixesApplied))</h2>
"@
            foreach ($fix in $diagnosticResults.Fixes) {
                $reportContent += @"
        <div class="fix">
            <strong>$($fix.Description)</strong><br>
            Status: <span class="$(if($fix.Status -eq 'Success') {'healthy'} else {'critical'})">$($fix.Status)</span>
        </div>
"@
            }
            
            $reportContent += @"
    </div>
</body>
</html>
"@
        }
        default {
            $reportContent = @"
WSL Diagnostic Report
Generated: $($report.GeneratedAt)
Overall Status: $($report.Summary.OverallStatus)

System Information:
- Windows Version: $($report.SystemInfo.WindowsProductName) $($report.SystemInfo.WindowsVersion)
- Total Memory: $([math]::Round($report.SystemInfo.TotalPhysicalMemory / 1GB, 2)) GB

Health Summary:
- Overall Health: $($report.HealthReport.OverallHealth)
- Service Status: $($report.HealthReport.ServiceStatus.OverallStatus)
- Network Status: $($report.HealthReport.NetworkStatus.OverallStatus)
- Memory Usage: $($report.HealthReport.ResourceUsage.SystemMemory.UsagePercent)%

Issues Found ($($report.Summary.TotalIssues)):
"@
            foreach ($issue in $diagnosticResults.Issues) {
                $reportContent += "`n- $($issue.Description) (Severity: $($issue.Severity))`n  Recommendation: $($issue.Recommendation)"
            }
            
            $reportContent += "`n`nFixes Applied ($($report.Summary.FixesApplied)):"
            foreach ($fix in $diagnosticResults.Fixes) {
                $reportContent += "`n- $($fix.Description) (Status: $($fix.Status))"
            }
        }
    }
    
    # Save report if output path is specified
    if ($OutputPath) {
        $reportContent | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "Diagnostic report saved to: $OutputPath" -ForegroundColor Green
    }
    
    return $reportContent
}

# Export functions
Export-ModuleMember -Function Invoke-WSLDiagnostics, New-WSLDiagnosticReport