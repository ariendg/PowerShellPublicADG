# Use environment variables to define the path to pwsh.exe
$pwshPath = [System.IO.Path]::Combine($Env:ProgramFiles, "PowerShell", "7", "pwsh.exe")

# Desired minimum version as a [Version] object
$minimumVersion = [Version]'7.4.6'

# Check if pwsh.exe exists
if (Test-Path -Path $pwshPath) {
    # Run pwsh.exe and capture the version as a [Version] object
    $versionInfo = [Version](& $pwshPath -NoProfile -Command { $PSVersionTable.PSVersion.ToString() })

    # Compare the installed version to the minimum required version
    if ($versionInfo -ge $minimumVersion) {
        # Return code 0 if the version is equal or greater than 7.4.6
        Write-Output "Installed - and the version is equal or greater than 7.4.6"
        exit 0
    } else {
        # Return code 1 if the version is lower than 7.4.6  but comment output
        #Write-Output "the version is lower than 7.4.6"
        exit 0
    }
} else {
    # Return code 1 if PowerShell 7 is not installed but comment output
    #Write-Output "PowerShell 7 is not installed"
    exit 0
}