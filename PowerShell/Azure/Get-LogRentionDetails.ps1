<#
.SYNOPSIS
    Retrieves diagnostic settings and retention details for SQL Servers, Logic Apps, and Web Apps across Azure subscriptions.

.DESCRIPTION
    This script collects diagnostic log retention settings for SQL Servers, Logic Apps, and Web Apps in all or a specified Azure subscription.
    Results are exported to a CSV file.  Requires the Az PowerShell module. Ensure you are authenticated with Azure using `Connect-AzAccount`.  
    If you need to install the Az module, you can do so with `Install-Module -Name Az -AllowClobber -Scope CurrentUser`.
    Note that Microsoft has deprecated the retention settings for diagnostic logs in Azure Monitor, so this script is meant to help identify
    resources that still have retention settings configured. It is recommended to review and update these settings as needed.

.PARAMETER All
    If specified, processes all enabled subscriptions except those with names starting with 'MSDN-'.

.PARAMETER SubscriptionName
    The name of a single subscription to process. If not provided and -All is not specified, you will be prompted.

.EXAMPLE
    .\get-log-retention-details.ps1 -All

    Processes all enabled subscriptions.

.EXAMPLE
    .\get-log-retention-details.ps1 -SubscriptionName "My Subscription"

    Processes only the specified subscription.

.NOTES
    Requires Az PowerShell module.
    Make sure you are authenticated: Connect-AzAccount
    Output CSV will be named with the subscription and timestamp.

.LASTEDIT
    2025-07-08
.AUTHOR
    Ismael J Carlo
    github.com/ismaeljcarlo
#>



[CmdletBinding()]
param(
    [switch]$All,
    [string]$SubscriptionName
)

function Get-DiagnosticRetentionDetails {
    param(
        [string]$SubscriptionName,
        [string]$ResourceGroupName,
        [string]$ResourceType,
        [string]$ResourceName,
        [string]$ResourceId
    )

    $diagSettings = Get-AzDiagnosticSetting -ResourceId $ResourceId
    $details = @()

    if ($diagSettings) {
        foreach ($setting in $diagSettings) {
            foreach ($log in $setting.Log) {
                $retentionEnabled = $log.RetentionPolicyEnabled
                $retentionDays = $log.RetentionPolicyDays
                $logCategory = $log.Category
                $destinationTypes = @()
                if ($setting.WorkspaceId) { $destinationTypes += "Log Analytics" }
                if ($setting.StorageAccountId) { $destinationTypes += "Storage Account" }
                if ($setting.EventHubAuthorizationRuleId) { $destinationTypes += "Event Hub" }
                $destinationTypes = $destinationTypes -join ', '

                $details += [PSCustomObject]@{
                    SubscriptionName = $SubscriptionName
                    ResourceGroup    = $ResourceGroupName
                    ResourceType     = $ResourceType
                    ResourceName     = $ResourceName
                    ResourceId       = $ResourceId
                    LogCategory      = $logCategory
                    RetentionEnabled = $retentionEnabled
                    RetentionDays    = $retentionDays
                    Destinations     = $destinationTypes
                }
            }
        }
    } else {
        $details += [PSCustomObject]@{
            SubscriptionName = $SubscriptionName
            ResourceGroup    = $ResourceGroupName
            ResourceType     = $ResourceType
            ResourceName     = $ResourceName
            ResourceId       = $ResourceId
            LogCategory      = $null
            RetentionEnabled = $null
            RetentionDays    = $null
            Destinations     = "No diagnostic settings"
        }
    }
    return $details
}

# Step 1: Retrieve all subscriptions in the Azure account
if ($All) {
    $subscriptions = Get-AzSubscription | Where-Object { $_.State -ne 'Disabled' -and $_.Name -notmatch 'MSDN-' }
} else {
    if (-not $SubscriptionName) {
        $SubscriptionName = Read-Host "Enter the subscription name"
    }
    $subscriptions = Get-AzSubscription | Where-Object { $_.State -ne 'Disabled' -and $_.Name -eq $SubscriptionName }
    if ($subscriptions.Count -eq 0) {
        Write-Host "No matching subscription found for '$SubscriptionName'. Exiting." -ForegroundColor Red
        return
    } else {
        Write-Host "Found $($subscriptions.Count) subscription(s) to process."
    }
}

# Prepare an array to collect results
$results = @()

foreach ($subscription in $subscriptions) {
    Set-AzContext -SubscriptionId $subscription.Id
    # Output the subscription being processed
    Write-Host "Processing subscription: $($subscription.Name) ($($subscription.Id))" -ForegroundColor Cyan

    $resourceGroups = Get-AzResourceGroup
    

    foreach ($rg in $resourceGroups) {
        # Output the resource group being processed
        Write-Host "Processing resource group: $($rg.ResourceGroupName)" -ForegroundColor Yellow
        
       
        # SQL Servers
        Write-Host "Processing SQL Servers"
        
        $sqlServers = Get-AzSqlServer -ResourceGroupName $rg.ResourceGroupName
        if (-not $sqlServers) {
            Write-Host "No SQL Servers found in resource group: $($rg.ResourceGroupName)" -ForegroundColor Yellow
            continue
        } else {
            Write-Host "Found $($sqlServers.Count) SQL Servers in resource group: $($rg.ResourceGroupName)" -ForegroundColor Yellow
        }

        foreach ($sqlServer in $sqlServers) {
            # Output the SQL Server being processed
            Write-Host "Processing SQL Server: $($sqlServer.ServerName)" -ForegroundColor Green
            $resourceId = "/subscriptions/$($subscription.Id)/resourceGroups/$($rg.ResourceGroupName)/providers/Microsoft.Sql/servers/$($sqlServer.ServerName)"
            $results += Get-DiagnosticRetentionDetails -SubscriptionName $subscription.Name -ResourceGroupName $rg.ResourceGroupName -ResourceType "SQLServer" -ResourceName $sqlServer.ServerName -ResourceId $resourceId
        }

        # Logic Apps
        Write-Host "Processing Logic Apps"

        $logicApps = Get-AzLogicApp -ResourceGroupName $rg.ResourceGroupName
        if (-not $logicApps) {
            Write-Host "No Logic Apps found in resource group: $($rg.ResourceGroupName)" -ForegroundColor Yellow
            continue
        } else {
            Write-Host "Found $($logicApps.Count) Logic Apps in resource group: $($rg.ResourceGroupName)" -ForegroundColor Yellow
        }

        foreach ($logicApp in $logicApps) {
            # Output the Logic App being processed
            Write-Host "Processing Logic App: $($logicApp.Name)" -ForegroundColor Green
            $resourceId = "/subscriptions/$($subscription.Id)/resourceGroups/$($rg.ResourceGroupName)/providers/Microsoft.Logic/workflows/$($logicApp.Name)"
            $results += Get-DiagnosticRetentionDetails -SubscriptionName $subscription.Name -ResourceGroupName $rg.ResourceGroupName -ResourceType "LogicApp" -ResourceName $logicApp.Name -ResourceId $resourceId
        }

        # Web Apps
        Write-Host "Processing Web Apps"
         $webApps = Get-AzWebApp -ResourceGroupName $rg.ResourceGroupName
        if (-not $webApps) {
            Write-Host "No Web Apps found in resource group: $($rg.ResourceGroupName)" -ForegroundColor Yellow
            continue
        } else {
            Write-Host "Found $($webApps.Count) Web Apps in resource group: $($rg.ResourceGroupName)" -ForegroundColor Yellow
        }

         foreach ($webApp in $webApps) {
            # Output the Web App being processed
            Write-Host "Processing Web App: $($webApp.Name)" -ForegroundColor Green                
            $resourceId = "/subscriptions/$($subscription.Id)/resourceGroups/$($rg.ResourceGroupName)/providers/Microsoft.Web/sites/$($webApp.Name)"
            $results += Get-DiagnosticRetentionDetails -SubscriptionName $subscription.Name -ResourceGroupName $rg.ResourceGroupName -ResourceType "WebApp" -ResourceName $webApp.Name -ResourceId $resourceId
        }
    }
}

# Output as a CSV file
if ($results.Count -eq 0) {
    Write-Host "No diagnostic settings found for any resources."
} else {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        #includes subscription name in the filename if only one subscription is processed
        if ($subscriptions.Count -eq 1) {
            $safeSubName = ($subscriptions[0].Name -replace '[^a-zA-Z0-9\-]', '_')
            $filename = ".\get-log-retention-$safeSubName-$timestamp.csv"
        # if multiple subscriptions are processed, just use the timestamp
        } else {
            $filename = ".\get-log-retention-$timestamp.csv"
        }
        $results | Export-Csv $filename -NoTypeInformation
}
