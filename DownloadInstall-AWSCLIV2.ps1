# Arien de Groot 9-11-2023
# Configure TLS 1.2 for current PowerShell session
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Define the URL of the AWS CLI MSI installer
$installerUrl = "https://awscli.amazonaws.com/AWSCLIV2.msi"

# Define the path where the installer will be saved
$installerPath = "$env:TEMP\AWSCLIV2.msi"

# Download the installer
#$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
(New-Object Net.WebClient).DownloadFile($installerUrl, $installerPath)

# Install the AWS CLI
try {
    Start-Process msiexec.exe -Wait -ArgumentList "/i $installerPath /qn" -ErrorAction Stop    
}
catch {
    Write-Warning "Could not Install file $installerPath somehow"
    Write-Verbose -Verbose $error[0]
}

#Version Detection: (aws --version).Split(' ')[0].Split('/')[1]