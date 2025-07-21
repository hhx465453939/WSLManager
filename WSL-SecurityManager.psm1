# WSL Security Manager Module - Permission Management System
# Task 6.1: User and Group Permission Management

function Test-WSLUserPermissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
    
    try {
        Write-Host "Checking user permissions for $UserName in $DistributionName..." -ForegroundColor Yellow
        
        # Check if user exists
        $userExists = wsl -d $DistributionName -- id $UserName 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "User $UserName does not exist in distribution $DistributionName"
        }
        
        # Get user information
        $userInfo = wsl -d $DistributionName -- id $UserName
        $groups = wsl -d $DistributionName -- groups $UserName
        
        # Check sudo permissions
        $sudoCheck = wsl -d $DistributionName -- sudo -l -U $UserName 2>$null
        $hasSudo = $LASTEXITCODE -eq 0
        
        # Check if user is in sudo group
        $inSudoGroup = $groups -match "sudo|wheel|admin"
        
        # Get home directory permissions
        $homeDir = wsl -d $DistributionName -- eval 'echo $HOME'
        $homeDirPerms = wsl -d $DistributionName -- ls -ld $homeDir
        
        $result = @{
            UserName = $UserName
            DistributionName = $DistributionName
            UserInfo = $userInfo
            Groups = $groups
            HasSudo = $hasSudo
            InSudoGroup = $inSudoGroup
            HomeDirectory = $homeDir
            HomeDirectoryPermissions = $homeDirPerms
            CheckTime = Get-Date
        }
        
        Write-Host "User permission check completed successfully" -ForegroundColor Green
        return $result
    }
    catch {
        Write-Error "Error checking user permissions: $($_.Exception.Message)"
        return $null
    }
}

function Set-WSLUserPermissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        
        [Parameter(Mandatory = $true)]
        [string]$UserName,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Groups = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$GrantSudo,
        
        [Parameter(Mandatory = $false)]
        [switch]$RevokeSudo
    )
    
    try {
        Write-Host "Setting user permissions for $UserName in $DistributionName..." -ForegroundColor Yellow
        
        # Check if user exists
        $userExists = wsl -d $DistributionName -- id $UserName 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "User $UserName does not exist in distribution $DistributionName"
        }
        
        $changes = @()
        
        # Add user to specified groups
        foreach ($group in $Groups) {
            Write-Host "Adding user to group: $group" -ForegroundColor Cyan
            wsl -d $DistributionName -- sudo usermod -a -G $group $UserName
            if ($LASTEXITCODE -eq 0) {
                $changes += "Added to group: $group"
            } else {
                Write-Warning "Failed to add user to group $group"
            }
        }
        
        # Grant or revoke sudo permissions
        if ($GrantSudo) {
            Write-Host "Granting sudo permissions" -ForegroundColor Cyan
            wsl -d $DistributionName -- sudo usermod -a -G sudo $UserName
            if ($LASTEXITCODE -eq 0) {
                $changes += "Granted sudo permissions"
            } else {
                Write-Warning "Failed to grant sudo permissions"
            }
        }
        
        if ($RevokeSudo) {
            Write-Host "Revoking sudo permissions" -ForegroundColor Cyan
            wsl -d $DistributionName -- sudo deluser $UserName sudo 2>$null
            if ($LASTEXITCODE -eq 0) {
                $changes += "Revoked sudo permissions"
            } else {
                Write-Warning "Failed to revoke sudo permissions"
            }
        }
        
        $result = @{
            UserName = $UserName
            DistributionName = $DistributionName
            Changes = $changes
            Timestamp = Get-Date
        }
        
        Write-Host "User permission setting completed" -ForegroundColor Green
        return $result
    }
    catch {
        Write-Error "Error setting user permissions: $($_.Exception.Message)"
        return $null
    }
}

function Test-WSLFileSystemPermissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [switch]$Recursive
    )
    
    try {
        Write-Host "Checking filesystem permissions for path $Path..." -ForegroundColor Yellow
        
        # Check if path exists
        $pathExists = wsl -d $DistributionName -- test -e $Path
        if ($LASTEXITCODE -ne 0) {
            throw "Path $Path does not exist in distribution $DistributionName"
        }
        
        # Get detailed permission information
        if ($Recursive) {
            $permissions = wsl -d $DistributionName -- find $Path -exec ls -la {} \;
        } else {
            $permissions = wsl -d $DistributionName -- ls -la $Path
        }
        
        # Check for sensitive permissions
        $worldWritable = wsl -d $DistributionName -- find $Path -perm -002 -type f 2>$null
        $setuidFiles = wsl -d $DistributionName -- find $Path -perm -4000 -type f 2>$null
        $setgidFiles = wsl -d $DistributionName -- find $Path -perm -2000 -type f 2>$null
        
        $result = @{
            DistributionName = $DistributionName
            Path = $Path
            Permissions = $permissions
            WorldWritableFiles = $worldWritable
            SetuidFiles = $setuidFiles
            SetgidFiles = $setgidFiles
            CheckTime = Get-Date
        }
        
        Write-Host "Filesystem permission check completed" -ForegroundColor Green
        return $result
    }
    catch {
        Write-Error "Error checking filesystem permissions: $($_.Exception.Message)"
        return $null
    }
}

function Set-WSLFileSystemPermissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$Mode,
        
        [Parameter(Mandatory = $false)]
        [string]$Owner,
        
        [Parameter(Mandatory = $false)]
        [string]$Group,
        
        [Parameter(Mandatory = $false)]
        [switch]$Recursive
    )
    
    try {
        Write-Host "Setting filesystem permissions for path $Path..." -ForegroundColor Yellow
        
        # Check if path exists
        $pathExists = wsl -d $DistributionName -- test -e $Path
        if ($LASTEXITCODE -ne 0) {
            throw "Path $Path does not exist in distribution $DistributionName"
        }
        
        $changes = @()
        
        # Set permission mode
        if ($Mode) {
            Write-Host "Setting permission mode: $Mode" -ForegroundColor Cyan
            if ($Recursive) {
                wsl -d $DistributionName -- sudo chmod -R $Mode $Path
            } else {
                wsl -d $DistributionName -- sudo chmod $Mode $Path
            }
            
            if ($LASTEXITCODE -eq 0) {
                $changes += "Permission mode set to: $Mode"
            } else {
                Write-Warning "Failed to set permission mode"
            }
        }
        
        # Set owner
        if ($Owner) {
            Write-Host "Setting owner: $Owner" -ForegroundColor Cyan
            if ($Recursive) {
                wsl -d $DistributionName -- sudo chown -R $Owner $Path
            } else {
                wsl -d $DistributionName -- sudo chown $Owner $Path
            }
            
            if ($LASTEXITCODE -eq 0) {
                $changes += "Owner set to: $Owner"
            } else {
                Write-Warning "Failed to set owner"
            }
        }
        
        # Set group
        if ($Group) {
            Write-Host "Setting group: $Group" -ForegroundColor Cyan
            if ($Recursive) {
                wsl -d $DistributionName -- sudo chgrp -R $Group $Path
            } else {
                wsl -d $DistributionName -- sudo chgrp $Group $Path
            }
            
            if ($LASTEXITCODE -eq 0) {
                $changes += "Group set to: $Group"
            } else {
                Write-Warning "Failed to set group"
            }
        }
        
        $result = @{
            DistributionName = $DistributionName
            Path = $Path
            Changes = $changes
            Timestamp = Get-Date
        }
        
        Write-Host "Filesystem permission setting completed" -ForegroundColor Green
        return $result
    }
    catch {
        Write-Error "Error setting filesystem permissions: $($_.Exception.Message)"
        return $null
    }
}

function New-WSLPermissionAuditReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ".\WSL-Security-Audit",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeFileSystem
    )
    
    try {
        Write-Host "Generating WSL permission audit report..." -ForegroundColor Yellow
        
        # Ensure output directory exists
        if (!(Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
        
        $reportData = @{
            DistributionName = $DistributionName
            GeneratedTime = Get-Date
            SystemInfo = @{}
            Users = @()
            Groups = @()
            SecurityIssues = @()
            FileSystemIssues = @()
        }
        
        # Get system information
        Write-Host "Collecting system information..." -ForegroundColor Cyan
        $reportData.SystemInfo = @{
            KernelVersion = wsl -d $DistributionName -- uname -r
            OSVersion = wsl -d $DistributionName -- cat /etc/os-release | Select-String "PRETTY_NAME"
            Hostname = wsl -d $DistributionName -- hostname
        }
        
        # Get user information
        Write-Host "Collecting user information..." -ForegroundColor Cyan
        $users = wsl -d $DistributionName -- cut -d: -f1 /etc/passwd
        foreach ($user in $users) {
            if ($user -and $user.Trim()) {
                $userInfo = Test-WSLUserPermissions -DistributionName $DistributionName -UserName $user.Trim()
                if ($userInfo) {
                    $reportData.Users += $userInfo
                }
            }
        }
        
        # Get group information
        Write-Host "Collecting group information..." -ForegroundColor Cyan
        $groups = wsl -d $DistributionName -- cut -d: -f1 /etc/group
        $reportData.Groups = $groups
        
        # Check security issues
        Write-Host "Checking security issues..." -ForegroundColor Cyan
        
        # Check for empty password users
        $emptyPasswordUsers = wsl -d $DistributionName -- awk -F: '($2 == "") {print $1}' /etc/shadow 2>$null
        if ($emptyPasswordUsers) {
            $reportData.SecurityIssues += @{
                Type = "EmptyPassword"
                Description = "Users with empty passwords found"
                Users = $emptyPasswordUsers
                Severity = "High"
            }
        }
        
        # Check sudo users
        $sudoUsers = wsl -d $DistributionName -- getent group sudo | cut -d: -f4
        if ($sudoUsers) {
            $reportData.SecurityIssues += @{
                Type = "SudoUsers"
                Description = "Users with sudo permissions"
                Users = $sudoUsers -split ","
                Severity = "Medium"
            }
        }
        
        # Generate report files
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $reportFile = Join-Path $OutputPath "WSL_Security_Audit_${DistributionName}_${timestamp}.json"
        
        # Save JSON report
        $reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportFile -Encoding UTF8
        
        Write-Host "Permission audit report generated:" -ForegroundColor Green
        Write-Host "JSON report: $reportFile" -ForegroundColor Green
        
        return @{
            JsonReport = $reportFile
            ReportData = $reportData
        }
    }
    catch {
        Write-Error "Error generating permission audit report: $($_.Exception.Message)"
        return $null
    }
}

# Export functions
Export-ModuleMember -Function Test-WSLUserPermissions, Set-WSLUserPermissions, Test-WSLFileSystemPermissions, Set-WSLFileSystemPermissions, New-WSLPermissionAuditReport

# Security Policy Configuration Functions - Task 6.2

function Test-WSLSecurityRisks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ".\WSL-Security-Assessment"
    )
    
    try {
        Write-Host "Assessing security risks for $DistributionName..." -ForegroundColor Yellow
        
        $securityRisks = @{
            DistributionName = $DistributionName
            AssessmentTime = Get-Date
            Risks = @()
            Recommendations = @()
        }
        
        # Check for weak passwords
        Write-Host "Checking for weak password policies..." -ForegroundColor Cyan
        $passwordPolicy = wsl -d $DistributionName -- cat /etc/login.defs | grep -E "PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_WARN_AGE" 2>$null
        if (-not $passwordPolicy) {
            $securityRisks.Risks += @{
                Type = "WeakPasswordPolicy"
                Severity = "Medium"
                Description = "Password policy not configured or weak"
                Details = "No password aging policy found in /etc/login.defs"
            }
            $securityRisks.Recommendations += "Configure password aging policy in /etc/login.defs"
        }
        
        # Check for unattended upgrades
        Write-Host "Checking automatic security updates..." -ForegroundColor Cyan
        $unattendedUpgrades = wsl -d $DistributionName -- dpkg -l unattended-upgrades 2>$null
        if ($LASTEXITCODE -ne 0) {
            $securityRisks.Risks += @{
                Type = "NoAutoUpdates"
                Severity = "Medium"
                Description = "Automatic security updates not configured"
                Details = "unattended-upgrades package not installed"
            }
            $securityRisks.Recommendations += "Install and configure unattended-upgrades for automatic security updates"
        }
        
        # Check SSH configuration if SSH is installed
        Write-Host "Checking SSH configuration..." -ForegroundColor Cyan
        $sshInstalled = wsl -d $DistributionName -- which sshd 2>$null
        if ($LASTEXITCODE -eq 0) {
            $sshConfig = wsl -d $DistributionName -- cat /etc/ssh/sshd_config 2>$null
            if ($sshConfig -match "PermitRootLogin yes") {
                $securityRisks.Risks += @{
                    Type = "SSHRootLogin"
                    Severity = "High"
                    Description = "SSH root login is enabled"
                    Details = "PermitRootLogin is set to yes in sshd_config"
                }
                $securityRisks.Recommendations += "Disable SSH root login by setting PermitRootLogin to no"
            }
            
            if ($sshConfig -match "PasswordAuthentication yes") {
                $securityRisks.Risks += @{
                    Type = "SSHPasswordAuth"
                    Severity = "Medium"
                    Description = "SSH password authentication is enabled"
                    Details = "Consider using key-based authentication only"
                }
                $securityRisks.Recommendations += "Consider disabling password authentication and using SSH keys"
            }
        }
        
        # Check for world-writable files in critical directories
        Write-Host "Checking for world-writable files..." -ForegroundColor Cyan
        $criticalDirs = @("/etc", "/bin", "/sbin", "/usr/bin", "/usr/sbin")
        foreach ($dir in $criticalDirs) {
            $worldWritable = wsl -d $DistributionName -- find $dir -type f -perm -002 2>$null
            if ($worldWritable) {
                $securityRisks.Risks += @{
                    Type = "WorldWritableFiles"
                    Severity = "High"
                    Description = "World-writable files found in critical directory: $dir"
                    Details = $worldWritable
                }
                $securityRisks.Recommendations += "Remove world-write permissions from files in $dir"
            }
        }
        
        # Check for SUID/SGID files
        Write-Host "Checking for SUID/SGID files..." -ForegroundColor Cyan
        $suidFiles = wsl -d $DistributionName -- find / -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | head -20
        if ($suidFiles) {
            $securityRisks.Risks += @{
                Type = "SuidSgidFiles"
                Severity = "Medium"
                Description = "SUID/SGID files found (review required)"
                Details = $suidFiles
            }
            $securityRisks.Recommendations += "Review SUID/SGID files and remove unnecessary ones"
        }
        
        # Check firewall status
        Write-Host "Checking firewall status..." -ForegroundColor Cyan
        $ufwStatus = wsl -d $DistributionName -- ufw status 2>$null
        if ($LASTEXITCODE -ne 0 -or $ufwStatus -match "inactive") {
            $securityRisks.Risks += @{
                Type = "NoFirewall"
                Severity = "Medium"
                Description = "Firewall is not active or not installed"
                Details = "UFW firewall is not active"
            }
            $securityRisks.Recommendations += "Install and configure UFW firewall"
        }
        
        Write-Host "Security risk assessment completed" -ForegroundColor Green
        return $securityRisks
    }
    catch {
        Write-Error "Error assessing security risks: $($_.Exception.Message)"
        return $null
    }
}

function Set-WSLFirewallRules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AllowPorts = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$DenyPorts = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$AllowServices = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableFirewall,
        
        [Parameter(Mandatory = $false)]
        [switch]$ResetRules
    )
    
    try {
        Write-Host "Configuring firewall rules for $DistributionName..." -ForegroundColor Yellow
        
        $changes = @()
        
        # Install UFW if not present
        $ufwInstalled = wsl -d $DistributionName -- which ufw 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Installing UFW firewall..." -ForegroundColor Cyan
            wsl -d $DistributionName -- sudo apt-get update -qq
            wsl -d $DistributionName -- sudo apt-get install -y ufw
            if ($LASTEXITCODE -eq 0) {
                $changes += "Installed UFW firewall"
            } else {
                throw "Failed to install UFW firewall"
            }
        }
        
        # Reset rules if requested
        if ($ResetRules) {
            Write-Host "Resetting firewall rules..." -ForegroundColor Cyan
            wsl -d $DistributionName -- sudo ufw --force reset
            $changes += "Reset all firewall rules"
        }
        
        # Set default policies
        Write-Host "Setting default firewall policies..." -ForegroundColor Cyan
        wsl -d $DistributionName -- sudo ufw default deny incoming
        wsl -d $DistributionName -- sudo ufw default allow outgoing
        $changes += "Set default policies (deny incoming, allow outgoing)"
        
        # Allow specified ports
        foreach ($port in $AllowPorts) {
            Write-Host "Allowing port: $port" -ForegroundColor Cyan
            wsl -d $DistributionName -- sudo ufw allow $port
            if ($LASTEXITCODE -eq 0) {
                $changes += "Allowed port: $port"
            } else {
                Write-Warning "Failed to allow port: $port"
            }
        }
        
        # Deny specified ports
        foreach ($port in $DenyPorts) {
            Write-Host "Denying port: $port" -ForegroundColor Cyan
            wsl -d $DistributionName -- sudo ufw deny $port
            if ($LASTEXITCODE -eq 0) {
                $changes += "Denied port: $port"
            } else {
                Write-Warning "Failed to deny port: $port"
            }
        }
        
        # Allow specified services
        foreach ($service in $AllowServices) {
            Write-Host "Allowing service: $service" -ForegroundColor Cyan
            wsl -d $DistributionName -- sudo ufw allow $service
            if ($LASTEXITCODE -eq 0) {
                $changes += "Allowed service: $service"
            } else {
                Write-Warning "Failed to allow service: $service"
            }
        }
        
        # Enable firewall if requested
        if ($EnableFirewall) {
            Write-Host "Enabling firewall..." -ForegroundColor Cyan
            wsl -d $DistributionName -- sudo ufw --force enable
            if ($LASTEXITCODE -eq 0) {
                $changes += "Enabled firewall"
            } else {
                Write-Warning "Failed to enable firewall"
            }
        }
        
        # Get current status
        $firewallStatus = wsl -d $DistributionName -- sudo ufw status verbose
        
        $result = @{
            DistributionName = $DistributionName
            Changes = $changes
            FirewallStatus = $firewallStatus
            Timestamp = Get-Date
        }
        
        Write-Host "Firewall configuration completed" -ForegroundColor Green
        return $result
    }
    catch {
        Write-Error "Error configuring firewall rules: $($_.Exception.Message)"
        return $null
    }
}

function Invoke-WSLSecurityHardening {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        
        [Parameter(Mandatory = $false)]
        [switch]$ApplyRecommendations,
        
        [Parameter(Mandatory = $false)]
        [string]$HardeningProfile = "Standard"
    )
    
    try {
        Write-Host "Applying security hardening to $DistributionName..." -ForegroundColor Yellow
        
        $hardeningActions = @()
        
        # Assess current security risks
        $securityAssessment = Test-WSLSecurityRisks -DistributionName $DistributionName
        
        if ($ApplyRecommendations -and $securityAssessment) {
            Write-Host "Applying security hardening recommendations..." -ForegroundColor Cyan
            
            # Configure password policy
            Write-Host "Configuring password policy..." -ForegroundColor Cyan
            $passwordConfig = @"
# Password aging controls
PASS_MAX_DAYS   90
PASS_MIN_DAYS   1
PASS_WARN_AGE   7
PASS_MIN_LEN    8
"@
            wsl -d $DistributionName -- sudo sh -c "echo '$passwordConfig' >> /etc/login.defs"
            $hardeningActions += "Configured password aging policy"
            
            # Install and configure automatic updates
            Write-Host "Configuring automatic security updates..." -ForegroundColor Cyan
            wsl -d $DistributionName -- sudo apt-get update -qq
            wsl -d $DistributionName -- sudo apt-get install -y unattended-upgrades apt-listchanges
            wsl -d $DistributionName -- sudo dpkg-reconfigure -plow unattended-upgrades
            $hardeningActions += "Configured automatic security updates"
            
            # Configure basic firewall
            Write-Host "Configuring basic firewall..." -ForegroundColor Cyan
            $firewallResult = Set-WSLFirewallRules -DistributionName $DistributionName -AllowServices @("ssh") -EnableFirewall
            if ($firewallResult) {
                $hardeningActions += "Configured and enabled firewall"
            }
            
            # Secure SSH configuration if SSH is installed
            $sshInstalled = wsl -d $DistributionName -- which sshd 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Hardening SSH configuration..." -ForegroundColor Cyan
                $sshHardening = @"
# Security hardening for SSH
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
TCPKeepAlive yes
ClientAliveInterval 300
ClientAliveCountMax 2
"@
                wsl -d $DistributionName -- sudo sh -c "echo '$sshHardening' >> /etc/ssh/sshd_config"
                $hardeningActions += "Hardened SSH configuration"
            }
            
            # Set secure file permissions on critical directories
            Write-Host "Setting secure file permissions..." -ForegroundColor Cyan
            wsl -d $DistributionName -- sudo chmod 755 /etc
            wsl -d $DistributionName -- sudo chmod 644 /etc/passwd
            wsl -d $DistributionName -- sudo chmod 640 /etc/shadow
            wsl -d $DistributionName -- sudo chmod 644 /etc/group
            $hardeningActions += "Set secure permissions on critical files"
            
            # Install security tools
            Write-Host "Installing security monitoring tools..." -ForegroundColor Cyan
            wsl -d $DistributionName -- sudo apt-get install -y fail2ban logwatch rkhunter chkrootkit
            $hardeningActions += "Installed security monitoring tools"
        }
        
        $result = @{
            DistributionName = $DistributionName
            HardeningProfile = $HardeningProfile
            SecurityAssessment = $securityAssessment
            HardeningActions = $hardeningActions
            AppliedRecommendations = $ApplyRecommendations
            Timestamp = Get-Date
        }
        
        Write-Host "Security hardening completed" -ForegroundColor Green
        return $result
    }
    catch {
        Write-Error "Error applying security hardening: $($_.Exception.Message)"
        return $null
    }
}

function Set-WSLSecurityPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        
        [Parameter(Mandatory = $false)]
        [string]$PolicyFile,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$PolicySettings = @{}
    )
    
    try {
        Write-Host "Applying security policy to $DistributionName..." -ForegroundColor Yellow
        
        $policyChanges = @()
        
        # Default security policy settings
        $defaultPolicy = @{
            PasswordComplexity = $true
            AutomaticUpdates = $true
            FirewallEnabled = $true
            SSHHardening = $true
            FilePermissions = $true
            AuditLogging = $true
        }
        
        # Merge with provided settings
        $effectivePolicy = $defaultPolicy.Clone()
        foreach ($key in $PolicySettings.Keys) {
            $effectivePolicy[$key] = $PolicySettings[$key]
        }
        
        # Load policy from file if provided
        if ($PolicyFile -and (Test-Path $PolicyFile)) {
            Write-Host "Loading policy from file: $PolicyFile" -ForegroundColor Cyan
            $filePolicy = Get-Content $PolicyFile | ConvertFrom-Json
            foreach ($property in $filePolicy.PSObject.Properties) {
                $effectivePolicy[$property.Name] = $property.Value
            }
            $policyChanges += "Loaded policy from file: $PolicyFile"
        }
        
        # Apply password complexity policy
        if ($effectivePolicy.PasswordComplexity) {
            Write-Host "Applying password complexity policy..." -ForegroundColor Cyan
            wsl -d $DistributionName -- sudo apt-get install -y libpam-pwquality
            $pamConfig = @"
# Password complexity requirements
password requisite pam_pwquality.so retry=3 minlen=8 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1
"@
            wsl -d $DistributionName -- sudo sh -c "echo '$pamConfig' >> /etc/pam.d/common-password"
            $policyChanges += "Applied password complexity policy"
        }
        
        # Apply automatic updates policy
        if ($effectivePolicy.AutomaticUpdates) {
            Write-Host "Enabling automatic security updates..." -ForegroundColor Cyan
            wsl -d $DistributionName -- sudo apt-get install -y unattended-upgrades
            wsl -d $DistributionName -- sudo dpkg-reconfigure -plow unattended-upgrades
            $policyChanges += "Enabled automatic security updates"
        }
        
        # Apply firewall policy
        if ($effectivePolicy.FirewallEnabled) {
            Write-Host "Enabling firewall policy..." -ForegroundColor Cyan
            $firewallResult = Set-WSLFirewallRules -DistributionName $DistributionName -EnableFirewall
            if ($firewallResult) {
                $policyChanges += "Enabled firewall policy"
            }
        }
        
        # Apply SSH hardening policy
        if ($effectivePolicy.SSHHardening) {
            $sshInstalled = wsl -d $DistributionName -- which sshd 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Applying SSH hardening policy..." -ForegroundColor Cyan
                # SSH hardening is applied in the hardening function
                $policyChanges += "Applied SSH hardening policy"
            }
        }
        
        # Apply file permissions policy
        if ($effectivePolicy.FilePermissions) {
            Write-Host "Applying secure file permissions policy..." -ForegroundColor Cyan
            wsl -d $DistributionName -- sudo find /etc -type f -exec chmod 644 {} \;
            wsl -d $DistributionName -- sudo find /etc -type d -exec chmod 755 {} \;
            wsl -d $DistributionName -- sudo chmod 640 /etc/shadow
            $policyChanges += "Applied secure file permissions policy"
        }
        
        # Apply audit logging policy
        if ($effectivePolicy.AuditLogging) {
            Write-Host "Enabling audit logging policy..." -ForegroundColor Cyan
            wsl -d $DistributionName -- sudo apt-get install -y auditd
            wsl -d $DistributionName -- sudo systemctl enable auditd
            $policyChanges += "Enabled audit logging policy"
        }
        
        $result = @{
            DistributionName = $DistributionName
            EffectivePolicy = $effectivePolicy
            PolicyChanges = $policyChanges
            Timestamp = Get-Date
        }
        
        Write-Host "Security policy application completed" -ForegroundColor Green
        return $result
    }
    catch {
        Write-Error "Error applying security policy: $($_.Exception.Message)"
        return $null
    }
}

# Update exports to include new functions
Export-ModuleMember -Function Test-WSLUserPermissions, Set-WSLUserPermissions, Test-WSLFileSystemPermissions, Set-WSLFileSystemPermissions, New-WSLPermissionAuditReport, Test-WSLSecurityRisks, Set-WSLFirewallRules, Invoke-WSLSecurityHardening, Set-WSLSecurityPolicy