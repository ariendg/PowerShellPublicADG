<#
.SYNOPSIS
This script is to correct Tags from Source CMDB for your Azure Resources on Subscriptions. A CSV-File is already generated for Onboarding purposes and this is convenient to script with foreach!
Run on demand. when team thinks tags are out of sync too much.

.DESCRIPTION
Sometimes it is needed to Activate resource ole 'Azure Connected Machine Resource Administrator' in front/before running this script!
The Resource group wil be displayed in output for details about what Role might be missing.

.NOTES
File Name: Correct Tags Azure
Author: Ariën de Groot
DateUpdated: 9-1-2023
Version: 1.0 - Initial version to do the work when team thinks tags are out of sync too much. Still some error handling etc needed
Version: 1.1 - MyVariables added to make more dynamic for future tags and share with community. Still some error handling etc needed
Version: 1.2 - logMsg function
Version: 1.3 - before and after Message for updating Tag with Color

.EXAMPLE
'.\Correct Tags Azure from CSV.ps1 or F5
#>

# Install-Module -Name Az.Resources -Force -AllowClobber
[CmdletBinding()]
param (
    $MyResourceType = "Microsoft.HybridCompute/machines",
    $MyTagName = 'MyTag',
    $MyCSVLocation = '\\localserver\Share\SubFolder\',
    $MyColumnName = 'MyColumn',
    $MyAssetColumnName = 'Asset ID'
)

$Logfile = 'CorrecttagsAzurefromCSV.log'
function logMsg {
    Param (
        [parameter(Mandatory=$true)]
        [string]$LogString,
        [parameter(Mandatory=$false)]
        [String]$Color,
        [parameter(Mandatory=$false)]
        [String]$Type
    )
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $LogTimeMessage = "$Stamp $LogString"
    Add-Content $LogFile -value $LogTimeMessage
    if (-not($Color)) { $Color = 'Red' }
    Write-Host "$LogString" -ForegroundColor $Color
}

try { 
    $checkConnected = Get-AzSubscription
}
catch { 
    Write-Host "You're not connected to AzureAD";
    Write-Host "Make sure you have AzureAD module available on this system then use Connect-AzureAD to establish connection"; 
    if (!$checkConnected) {
        Connect-AzAccount
    }
}

$resources = @()
Get-AzSubscription | ForEach-Object {
    $_ | Set-AzContext | Out-Null
    $subscriptionName = $_.Name
    $subscriptionId = $_.SubscriptionId
    Get-AzResource -ResourceType $MyResourceType | ForEach-Object {
        $resources += [PSCustomObject]@{
            SubscriptionName  = $subscriptionName
            SubscriptionId    = $subscriptionId
            ResourceGroupName = $_.ResourceGroupName
            ResourceName      = $_.ResourceName
            ResourceType      = $_.ResourceType
            Location          = $_.Location
            Tags              = $_.Tags
            ResourceId        = $_.ResourceId
        }
    }
}
#Uncomment or run next line for more details what script is doing getting all different Subscription resources and staging them for use
#$resources | Out-GridView

#We have a simple CSV to work with that has only 2 Values: Name and TagValue
$MyTagNameList = Import-Csv ($MyCSVLocation+$MyTagName+".csv") -Delimiter ";"
$i = 0; $r = 0;

foreach ($currentItem in $MyTagNameList) {
    $Resource = $resources | Where-Object ResourceName -eq $currentItem.$MyAssetColumnName
    $result = ($Resource).Tags
    if ($Resource) {
        $r++
        #Uncomment next line for more details what script is doing
        #Write-Output "looping $($Resource.ResourceName) that was also found in Azure Arc (HybridCompute) and now checking the Tag for it"
        if ($result["$MyTagName"] -ne $currentItem."$MyColumnName") {
            $i++            
            $TagValue = $currentItem | Select-Object -ExpandProperty "$MyColumnName"
            $tag = @{$MyTagName="$TagValue"}
            try {
                Set-AzContext -Subscription $Resource.SubscriptionId | Out-Null
                logMsg "$($Resource.ResourceName) has the wrong Tag set on RG: $($Resource.ResourceGroupName). It has tag: $($result["$MyTagName"]) and it should be tag: $($currentItem."$MyColumnName")"
                Update-AzTag -Tag $tag -ResourceId $Resource.ResourceId -Operation Merge -ErrorAction Stop
                logMsg "Now updated $($Resource.ResourceName) with tag: $($currentItem."$MyColumnName") where it had tag: $($result["$MyTagName"]) on RG: $($Resource.ResourceGroupName)" Green
            }
            catch {
                Write-Warning "Could not Update AzTag on $($Resource.ResourceName) with $($Resource.ResourceId)"
                Write-Verbose -Verbose $error[0]
            }
        }
    }
    #Uncomment next lines for more details what script is doing
    <#    
    else {
        Write-Output "Did not find $($currentItem.'Asset ID') from CSV in Azure Arc as a Server"
    }
    #>
}
if ($i -eq 0) { Write-Host "There were no wrong Azure Tags set in $r found resource matches from CSV. All other automation or corrections worked"}
