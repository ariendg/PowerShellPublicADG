# Arien de Groot 8-4-2024
# Ofcourse first connect to your favorite Site
Get-CMDevice -CollectionId SMS00001 | Where-Object CNIsOnline | Sort-Object Name | Select-Object Name | ForEach-Object {
    $pingResult = Test-Connection -ComputerName $_.Name -Count 1 -ErrorAction SilentlyContinue
    if ($pingResult -ne $null) {
        $latency = $pingResult | Select-Object -ExpandProperty ResponseTime
        Write-Host "$($_.Name) - Latency: $latency ms"
    }
    else {
        Write-Host "Ping to $($_.Name) failed."
    }
}