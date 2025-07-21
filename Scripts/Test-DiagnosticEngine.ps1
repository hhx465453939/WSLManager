# WSL Diagnostic Engine Test Script

# Import modules
Import-Module ..\Modules\WSL-DiagnosticEngine.psm1 -Force

Write-Host "=== WSL Diagnostic Engine Test ===" -ForegroundColor Cyan
Write-Host "Test time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Test 1: General diagnostics
Write-Host "`nTest 1: General WSL diagnostics" -ForegroundColor Yellow
$diagnosticResults = Invoke-WSLDiagnostics
Write-Host "✓ General diagnostics completed" -ForegroundColor Green
Write-Host "  Issues found: $($diagnosticResults.Issues.Count)" -ForegroundColor White
Write-Host "  Overall status: $($diagnosticResults.OverallStatus)" -ForegroundColor White

# Test 2: Service-specific diagnostics
Write-Host "`nTest 2: Service-specific diagnostics" -ForegroundColor Yellow
$serviceResults = Invoke-WSLDiagnostics -ProblemType "Service"
Write-Host "✓ Service diagnostics completed" -ForegroundColor Green
Write-Host "  Service issues found: $($serviceResults.Issues.Count)" -ForegroundColor White

# Test 3: Path-specific diagnostics
Write-Host "`nTest 3: Path-specific diagnostics" -ForegroundColor Yellow
$pathResults = Invoke-WSLDiagnostics -ProblemType "Path"
Write-Host "✓ Path diagnostics completed" -ForegroundColor Green
Write-Host "  Path issues found: $($pathResults.Issues.Count)" -ForegroundColor White

# Test 4: Network-specific diagnostics
Write-Host "`nTest 4: Network-specific diagnostics" -ForegroundColor Yellow
$networkResults = Invoke-WSLDiagnostics -ProblemType "Network"
Write-Host "✓ Network diagnostics completed" -ForegroundColor Green
Write-Host "  Network issues found: $($networkResults.Issues.Count)" -ForegroundColor White

# Test 5: Auto-fix functionality
Write-Host "`nTest 5: Auto-fix functionality" -ForegroundColor Yellow
$autoFixResults = Invoke-WSLDiagnostics -ProblemType "Service" -AutoFix
Write-Host "✓ Auto-fix diagnostics completed" -ForegroundColor Green
Write-Host "  Fixes applied: $($autoFixResults.Fixes.Count)" -ForegroundColor White

# Test 6: Generate diagnostic report
Write-Host "`nTest 6: Generate diagnostic report" -ForegroundColor Yellow
$reportPath = "$PSScriptRoot\WSL_Diagnostic_Report.html"
$report = New-WSLDiagnosticReport -OutputPath $reportPath -Format "HTML"
if (Test-Path $reportPath) {
    Write-Host "✓ Diagnostic report generated successfully" -ForegroundColor Green
    Write-Host "  Report saved to: $reportPath" -ForegroundColor White
} else {
    Write-Host "✗ Failed to generate diagnostic report" -ForegroundColor Red
}

Write-Host "`n=== All tests completed ===" -ForegroundColor Cyan