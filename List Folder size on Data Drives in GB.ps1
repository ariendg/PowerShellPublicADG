# Arien de Groot 25-2-2024
$ErrorActionPreference = "SilentlyContinue"

$Folders = @()
Get-CimInstance Win32_LogicalDisk -ErrorAction Stop | Where-Object DriveType -eq 3 | Where-Object DeviceID -notmatch 'C:' | Select-Object @{Name='DeviceID'; Expression={$_.DeviceID + '\'}} | ForEach-Object {
    $FolderPaths = Get-ChildItem -Path $_.DeviceID -Force -Directory | Where-Object Name -NotIn @('System Volume Information','Program Files','$RECYCLE.BIN')

    ForEach ($Folder in $FolderPaths) {

        [UInt64]$FolderSize = ( Get-Childitem -Path $Folder.FullName -Force -Recurse | Measure-Object -Property Length -Sum ).Sum
        
        $Folders+= [PSCustomObject]@{
            FolderName    = $Folder.BaseName
            FolderPath    = $Folder.FullName
            Size          = [math]::Round($FolderSize / 1GB,3)
        }

    }
}

$Folders | Sort-Object Size -Descending | ForEach-Object {
    [PSCustomObject]@{
        FolderName    = $_.FolderName
        FolderPath    = $_.FolderPath
        Size          = "{0:N3}" -f $_.Size
    }
}