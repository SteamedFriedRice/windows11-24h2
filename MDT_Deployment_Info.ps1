<#
    [SYNOPSIS]
        Automates timestamping, imaging user tracking, and version history in the Windows Registry for KACE SMA.

    [DESCRIPTION]
        This script creates or updates a registry key named "KACE Deployment"
        under HKEY_LOCAL_MACHINE\SOFTWARE and adds:
        - Image Name
        - Image Version
        - Deployment Date (MM-dd-yyyy)
        - Deployment Time (12-hour format with AM/PM)
        - Deployment Method (MDT)
        - Imaging Technician (Captured from setupact.log)
        - Version History (Maintains log of previous deployments)

    [AUTHOR]
        Hunter Rice

    [VERSION]
        1.8

    [LAST UPDATED]
        2025-02-04

    [CHANGELOG]
        Version 1.8:
            - **Successfully extracts Imaging Technician from `setupact.log` and stores it in registry.**
        Version 1.7:
            - Changed from `.txt` to `.log` for setupact file.
        Version 1.6:
            - Removed `$env:SMSTSLogonUser` as unreliable.
        Version 1.5:
            - Added fallback to logged-in user if imaging user is not found.
            - If MDT variable `%SMSTSLogonUser%` is missing, uses extracted username.
        Version 1.4:
            - Added "ImagedBy" registry value to store the technician who performed imaging.
        Version 1.3:
            - Changed date format to MM-dd-yyyy.
            - Changed time format to 12-hour with AM/PM.
        Version 1.2:
            - Added "VersionHistory" subkey to track all previous deployments.
        Version 1.1:
            - Added "DeploymentTime" registry entry for precise timestamping.
        Version 1.0:
            - Created registry key "KACE Deployment".
            - Added tracking values for MDT deployment. 
#>

# Define registry paths
$regPath = "HKLM:\SOFTWARE\KACE Deployment"
$historyPath = "$regPath\VersionHistory"

# Ensure the registry key and history subkey exist
New-Item -Path $regPath -Force | Out-Null
New-Item -Path $historyPath -Force | Out-Null

# Get current date and time in required format
$timestamp = Get-Date -Format "MM-dd-yyyy"   # Example: 02-04-2025
$timeNow = Get-Date -Format "hh:mm:ss tt"    # Example: 03:45:12 PM

# Generate version entry
$versionKey = "Version_$timestamp`_$timeNow"

# Define log file path (setupact.log)
$logFile = "C:\Windows\Panther\UnattendGC\setupact.log"

# Default Imaging Technician as "Unknown"
$imagedBy = "Unknown"

# Check if the log file exists and extract Imaging User
if (Test-Path $logFile) {
    $logContent = Get-Content $logFile -Raw

    if ($logContent -match "\[DJOIN\.EXE\]\s+Unattended Join:\s+Username\s*=\s*\[(.*?)\]") {
        $imagedBy = $matches[1].Trim()
    }
}

# Store extracted user in registry
Set-ItemProperty -Path $regPath -Name "ImageName" -Value "Windows11_23H2"
Set-ItemProperty -Path $regPath -Name "ImageVersion" -Value "1.0"
Set-ItemProperty -Path $regPath -Name "DeployedDate" -Value $timestamp
Set-ItemProperty -Path $regPath -Name "DeploymentTime" -Value $timeNow
Set-ItemProperty -Path $regPath -Name "DeploymentMethod" -Value "MDT"
Set-ItemProperty -Path $regPath -Name "ImagedBy" -Value $imagedBy

# Append version to VersionHistory subkey
Set-ItemProperty -Path $historyPath -Name $versionKey -Value "Windows11_23H2 - Version 1.0 - MDT - Imaged By: $imagedBy"

Write-Host "Stored Imaging Technician: $imagedBy"

# Confirm registry values
Get-ItemProperty -Path $regPath
Get-ItemProperty -Path $historyPath