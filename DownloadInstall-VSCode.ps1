# Arien de Groot 14-11-2023
# Configure TLS 1.2 for current PowerShell session
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Define the URL of the Microsoft Visual Studio Code installer
$installerUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"

# Define the path where the installer will be saved
$installerPath = "$env:TEMP\VSCodeSetup-x64.exe"

# Download the installer
#$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
(New-Object Net.WebClient).DownloadFile($installerUrl, $installerPath)

# Install Visual Studio Code
try {
    # Source https://github.com/Azure/dev-box-images/blob/70fc714f198a006135a84987af7e20760f588ae0/scripts/Install-VSCode.ps1
    $process = Start-Process -FilePath $installerPath -NoNewWindow -Wait -PassThru -ArgumentList `
	"/verysilent", `
	"/norestart", `
	"/mergetasks=!runcode,desktopicon,quicklaunchicon,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath" ` # https://github.com/Microsoft/vscode/blob/main/build/win32/code.iss#L77-L83
    -ErrorAction Stop
}
catch {
    Write-Warning "Could not Install file $installerPath somehow"
    Write-Verbose -Verbose $error[0]
    exit $process.ExitCode
}