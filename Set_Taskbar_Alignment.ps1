<#
    [SYNOPSIS]
        A PowerShell script to move the taskbar to the left for all users by modifying registry settings.

    [DESCRIPTION]
        This script modifies the registry for the current user and loads the `NTUSER.DAT` file for the Default User profile to set taskbar alignment to the left.

    [AUTHOR]
        Hunter Rice

    [VERSION]
        1.0.6

    [LAST UPDATED]
        2025-01-08

    [CHANGELOG]
        Version 1.0.0:
            - Initial script creation.
        Version 1.0.1:
            - Added checks to ensure registry paths exist before setting properties.
        Version 1.0.2:
            - Validated taskbar alignment for the current user before applying changes for the Default User.
        Version 1.0.4:
            - Added explicit creation of the `TaskbarAl` registry key if it does not exist.
        Version 1.0.5:
            - Replaced `New-ItemProperty` with `reg.exe` for better compatibility.
        Version 1.0.6:
            - Updated validation to use `reg.exe` to avoid PowerShell caching issues.
#>

# Move the taskbar to the left for the current user
$currentUserKey = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
try {
    # Use reg.exe to set TaskbarAl for the current user
    reg.exe add $currentUserKey /v TaskbarAl /t REG_DWORD /d 0 /f | Out-Null
    Write-Host "Taskbar alignment set to the left for the current user."
} catch {
    Write-Warning "Failed to set TaskbarAl for the current user: $_"
}

# Validate the change using reg.exe
$currentUserValidation = reg.exe query $currentUserKey /v TaskbarAl 2>&1
if ($currentUserValidation -match "0x0") {
    Write-Host "Successfully moved the taskbar to the left for the current user."
} else {
    Write-Warning "Validation failed: Taskbar is not aligned to the left for the current user."
}

# Path to the Default User's NTUSER.DAT file
$defaultUserNtUserDat = "$env:SystemDrive\Users\Default\NTUSER.DAT"

# Registry hive name for the Default User profile
$defaultProfileHive = "DefaultProfile"

# Load the Default User's registry hive and set taskbar alignment
if (Test-Path $defaultUserNtUserDat) {
    reg.exe load "HKEY_USERS\$defaultProfileHive" $defaultUserNtUserDat | Out-Null

    # Set taskbar alignment to the left
    $defaultUserKey = "HKEY_USERS\$defaultProfileHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    try {
        # Use reg.exe to set TaskbarAl for the Default User
        reg.exe add $defaultUserKey /v TaskbarAl /t REG_DWORD /d 0 /f | Out-Null
        Write-Host "Taskbar alignment set to the left for the Default User profile."
    } catch {
        Write-Warning "Failed to set TaskbarAl for the Default User profile: $_"
    }

    # Validate the change using reg.exe
    $defaultUserValidation = reg.exe query $defaultUserKey /v TaskbarAl 2>&1
    if ($defaultUserValidation -match "0x0") {
        Write-Host "Successfully moved the taskbar to the left for the Default User profile."
    } else {
        Write-Warning "Validation failed: Taskbar is not aligned to the left for the Default User profile."
    }

    # Unload the Default User's registry hive
    reg.exe unload "HKEY_USERS\$defaultProfileHive" | Out-Null
} else {
    Write-Warning "NTUSER.DAT file not found at $defaultUserNtUserDat. Taskbar alignment not set for Default User profile."
}
