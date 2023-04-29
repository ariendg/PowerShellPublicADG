# Arien de Groot 26-4-2023 Not working yet
#Requires -Modules PIMTools, @{ ModuleName="Az.ConnectedMachine"; ModuleVersion="0.4.1" }, Az.Resources, Az.Accounts, AzureAD
param (
    $Resource_ToUpdate = "PistachioServer",
    $ExcludedExtensionsregex = 'MicrosoftMonitoringAgent|AzureSecurityWindowsAgent|ChangeTracking-Windows'
)
# Check connection to AzureAD Needed for PIMTools purposes
try { 
    $checkConnectedAz = Get-AzSubscription
    $checkConnectedAzureAD = Get-AzureADTenantDetail
}
catch {
    Write-Host "You're not connected to AzureAD";
    Write-Host "Make sure you have AzureAD Module available on this system then use Connect-AzureAD to establish connection"
    if (!$checkConnectedAz) {
        Connect-AzAccount
    }
    if (!$checkConnectedAzureAD) {
        Connect-AzureAD
    }
}
$r = 0 # to be able to find resources with same name in different Subscriptions later

Get-AzSubscription | ForEach-Object {
    $_ | Set-AzContext | Out-Null
    $subscriptionName = $_.Name
    if($result = Get-AzResource -Name $Resource_ToUpdate -ResourceType "Microsoft.HybridCompute/machines" | Select-Object ResourceGroupName) {
        $r++
        Write-Host "Informational: Found $($result.ResourceGroupName) in $subscriptionName for $Resource_ToUpdate"
        $ResourceGroupName = $result.ResourceGroupName
        $subscriptionId = $_.SubscriptionId
    }
    else {
        Write-Host "Informational: No such Resource was found in $subscriptionName"
    }
}
if ($r -eq 0) { "No such Resource was found in Azure" }
else {
    $PIM = New-AzurePIMRequest -RoleName 'Azure Connected Machine Resource Administrator' -ResourceName $ResourceGroupName -ResourceType 'resourcegroup' -DurationInHours 2 -Reason "Wintel Auto Activation: Upgrade Arc Resource MachineExtensions" -ErrorAction Continue
    Set-AzContext -Subscription $subscriptionId | Out-Null
    Get-AzConnectedMachineExtension -MachineName $Resource_ToUpdate -ResourceGroupName $ResourceGroupName | Where-Object Name -NotMatch $ExcludedExtensionsregex | ForEach-Object {
        $LatestVersion = (Get-AzVMExtensionImage -Location "West Europe" -PublisherName $_.Publisher -Type $_.MachineExtensionType | ForEach-Object {[version]$_.Version} | Sort-Object -Descending | Select-Object -First 1).ToString()
        Write-Output "Updating Extension $($_.Name) to $LatestVersion"        
        $target = @{"$($_.Publisher)" = @{"targetVersion"="$LatestVersion"}}
        #$target = @{"Microsoft.Azure.AzureDefenderForServers" = @{"targetVersion"="1.0.8.5"}}
        Update-AzConnectedExtension -ResourceGroupName $ResourceGroupName -MachineName $Resource_ToUpdate -ExtensionTarget $target -Nowait -Verbose | Out-Null
    }
}

#$LatestVersion = (Get-AzVMExtensionImage -Location "West Europe" -PublisherName "Microsoft.AdminCenter" -Type "AdminCenter" | ForEach-Object {[version]$_.Version} | Sort-Object -Descending | Select-Object -First 1).ToString()
#Get-AzConnectedMachineExtension -MachineName $Resource_ToUpdate -ResourceGroupName $ResourceGroupName | Where-Object Name -NotMatch $ExcludedExtensionsregex | Select-Object Name, Publisher, MachineExtensionType
#Update-AzConnectedExtension -MachineName $Resource_ToUpdate -ResourceGroupName $ResourceGroupName -ExtensionTarget $target -Nowait -Verbose -WhatIf