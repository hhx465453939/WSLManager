#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Uninstalls the WSLManager module from the system.

.DESCRIPTION
    This script removes the WSLManager PowerShell module from the system-wide module directory.
    It deletes all module files, configuration templates, and other assets.
    Administrator privileges are required to write to the Program Files directory.

.NOTES
    Author: AI Assistant
    Version: 1.0
#>

param (
    [string]$InstallPath = (Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules\WSLManager')
)

Set-StrictMode -Version Latest

function Main {
    Write-Host "Starting WSLManager uninstallation..."

    if (-not (Test-Path -Path $InstallPath)) {
        Write-Host "WSLManager is not installed at '$InstallPath'."
        Write-Host "Uninstallation is not needed."
        return
    }

    Write-Host "Uninstalling from '$InstallPath'..."
    $choice = Read-Host "Are you sure you want to completely remove WSLManager? (Y/N)"
    if ($choice -ne 'Y') {
        Write-Host "Uninstallation aborted by user."
        return
    }

    try {
        # Unload the module if it's currently imported
        if (Get-Module -Name WSLManager) {
            Write-Host "Unloading the WSLManager module..."
            Remove-Module -Name WSLManager -Force
        }

        Write-Host "Removing module directory: $InstallPath"
        Remove-Item -Path $InstallPath -Recurse -Force

        Write-Host "Verifying uninstallation..."
        if (Get-Module -ListAvailable -Name WSLManager) {
            Write-Error "Uninstallation failed. The module is still available."
        } else {
            Write-Host "WSLManager has been successfully uninstalled."
        }
    }
    catch {
        Write-Error "An error occurred during uninstallation: $($_.Exception.Message)"
    }
}

Main