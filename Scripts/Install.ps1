#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs the WSLManager module on the system.

.DESCRIPTION
    This script installs the WSLManager PowerShell module to the system-wide module directory.
    It copies all necessary module files (.psm1, .psd1), configuration templates, and other assets.
    Administrator privileges are required to write to the Program Files directory.

.NOTES
    Author: AI Assistant
    Version: 1.0
#>

param (
    [string]$InstallPath = (Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules\WSLManager')
)

Set-StrictMode -Version Latest

# Source the detection module to use its functions
. "$PSScriptRoot\WSL-Detection.psm1"

function Check-Dependencies {
    Write-Host "Checking system for WSL compatibility..."
    
    $wslSupport = Test-WindowsWSLSupport
    if (-not $wslSupport.IsWSLSupported) {
        Write-Error "This system does not support WSL. Please update Windows to a compatible version."
        return $false
    }

    $wslFeature = Test-WSLFeature
    if (-not $wslFeature.WSLFeatureEnabled) {
        Write-Warning "The 'Windows Subsystem for Linux' feature is not enabled."
        $choice = Read-Host "Do you want to enable it now? (Y/N)"
        if ($choice -eq 'Y') {
            Write-Host "Enabling WSL feature..."
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
            Write-Host "Please restart your computer to complete the installation."
            exit
        } else {
            Write-Error "WSL feature is required to proceed. Installation aborted."
            return $false
        }
    }

    Write-Host "All dependencies are met."
    return $true
}

function Main {
    if (-not (Check-Dependencies)) {
        return
    }

    Write-Host "Starting WSLManager installation..."

    if (Test-Path -Path $InstallPath) {
        Write-Host "An existing installation was found at '$InstallPath'."
        $choice = Read-Host "Do you want to overwrite it? (Y/N)"
        if ($choice -ne 'Y') {
            Write-Host "Installation aborted by user."
            return
        }
        Write-Host "Removing previous installation..."
        Remove-Item -Path $InstallPath -Recurse -Force
    }

    Write-Host "Creating installation directory at '$InstallPath'..."
    New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null

    $SourcePath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

    Write-Host "Copying module files..."
    Get-ChildItem -Path $SourcePath -Filter *.psm1 | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $InstallPath
    }
    # In case a module manifest is added later
    Get-ChildItem -Path $SourcePath -Filter *.psd1 | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $InstallPath
    }

    Write-Host "Copying configuration templates..."
    $ConfigTemplatePath = Join-Path -Path $SourcePath -ChildPath 'config-templates'
    if (Test-Path -Path $ConfigTemplatePath) {
        Copy-Item -Path $ConfigTemplatePath -Destination $InstallPath -Recurse
    }

    Write-Host "Verifying installation..."
    $Module = Get-Module -ListAvailable -Name WSLManager
    if ($Module) {
        Write-Host "Installation successful!"
        Write-Host "Module installed at: $($Module.Path)"
        Write-Host "You can now use the module by running: Import-Module WSLManager"
    } else {
        Write-Error "Installation failed. The module could not be found after installation."
    }
}

Main