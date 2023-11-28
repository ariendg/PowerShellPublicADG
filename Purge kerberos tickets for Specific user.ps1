$SpecificLoggedOnUser = Get-CimInstance -ClassName Win32_LoggedOnUser | Where-Object { $_.Antecedent -like "*$Username*"}
$SpecificLoggedOnUser | ForEach-Object{
    Get-CimInstance -ClassName Win32_LogonSession -Filter "LogonId = $($_.Dependent.LogonId)" | ForEach-Object {[Convert]::ToString($_.LogonId, 16)} |
    ForEach-Object { klist.exe purge -li $_ }
}