<#
.SYNOPSIS
    This script imports a CSV file and creates role assignment actions for management groups and subscriptions.

.DESCRIPTION
    This script imports a CSV file that contains user information and creates role assignment actions for management groups and subscriptions.

.PARAMETER FilePath
    The path to the CSV file.

.EXAMPLE
    .\Get-Assign-Role-Commands.ps1 -FilePath ".\data.csv"

    CSV Example:
    Scope,ScopeType,Role,Username
    First-MG,ManagementGroup,"Tag Contributor",First-MG-Policy-ManagedIdentity
    First-MG,ManagementGroup,"Monitoring Contributor",First-MG-Policy-ManagedIdentity
    Second-MG,ManagementGroup,"Tag Contributor",Second-MG-Policy-ManagedIdentity
    Second-MG,ManagementGroup,"Monitoring Contributor",Second-MG-Policy-ManagedIdentity
    First-Subscription,Subscription,"Contributor",First-Subscription-ManagedIdentity

.NOTES
    Author: Ismael J. Carlo
    Date: May 19, 2023

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath
)

# Import CSV file
$csvData = Import-Csv -Path $FilePath -ErrorAction Stop

# Loop through each row in the CSV file
foreach ($row in $csvData) {
    # Create query to find the user's object ID
    $query = "displayname eq '$($row.username)'"
    $objectId = $(Get-AzureADServicePrincipal -filter $query).objectid

    # Get the role definition and scope from the CSV file
    $roleDefinition = $($row.Role)
    $roleScope = $($row.Scope)

    # Debugging
    # Write-Host "Query: $query"
    # Write-Host "Object ID: $objectId"
    # Write-Host "Role Definition: $roleDefinition"
    # Write-Host "Role Scope: $roleScope"

    if ($row.ScopeType -eq "Subscription") {
        # Get the subscription ID
        $subscriptionId = $(Get-AzSubscription -SubscriptionName $roleScope).id

        # Output command syntax for assigning role to subscription
        Write-Output "New-AzRoleAssignment `
            -ObjectId $objectId `
            -RoleDefinitionName `"$(($roleDefinition))`" `
            -Scope /subscriptions/$subscriptionId `
            -Verbose"
    }
    elseif ($row.ScopeType -eq "ManagementGroup") {
        # Get the management group ID
        $managementGroupId = $(Get-AzManagementgroup | where {$_.displayname -eq $roleScope}).id

        # Assign command syntax for assigning role to management group
        $RoleAssignmentCommand = "New-AzRoleAssignment `
        -ObjectId $objectId `
        -RoleDefinitionName `"$(($roleDefinition))`" `
        -Scope $managementGroupId `
        -Verbose"
        
        # Output command syntax for assigning role to management group
        Write-Output $RoleAssignmentCommand
        
        
        # Write-Output "New-AzRoleAssignment `
        #     -ObjectId $objectId `
        #     -RoleDefinitionName `"$(($roleDefinition))`" `
        #     -Scope $managementGroupId `
        #     -Verbose"


    }
}
