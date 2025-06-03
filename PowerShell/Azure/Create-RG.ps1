<#
.SYNOPSIS
    This script demonstrates the use of the UseDefaults parameter.

.DESCRIPTION
    The UseDefaults parameter is a switch that, when provided, assumes "Yes" and uses default settings.
    If the parameter is not provided or explicitly set to $false, it assumes "No" and uses custom settings.

.PARAMETER UseDefaults
    A switch parameter that, when provided, uses default settings.
    If not provided or set to $false, custom settings are used.

.EXAMPLE
    .\YourScript.ps1 -UseDefaults
    This will use default settings.

.EXAMPLE
    .\Create-RG.ps1 -UseDefaults:$false
    This will prompt you for inputs on items such as tags.

.EXAMPLE
    .\Create-RG.ps1
    This will prompt you for inputs on items such as tags.

.NOTES 
    Author: Ismael Carlo
    Contact: GitHub.com/ismaeljcarlo

    If you are using this script for personal use, be sure to update the defaults to you needs below.

.RELEASE NOTES
    Version 0.1 2025-06-03 Initial Release 

#>


param (
    [switch]$useDefaults
)

# Improves handling of Read-Host to include a default value
function Read-HostWithDefault {
    param (
        [string]$prompt,
        [string]$default
    )

    $userInput = Read-Host "$prompt (Press enter for: $default)"

    if ($userInput -ne "") {
        return $userInput
    } else {
        return $default
    }
}


# Start Azure Session if not connected
$azContext = Get-AzContext

if ($azContext -eq $null -or $azContext.Subscription -eq $null) {
    # No existing session, so connect to Azure
    Connect-AzAccount -UseDeviceAuthentication
} else {
    Write-Output "Existing Azure Connection is detected"
}

if ((Read-HostWithDefault -prompt "Your subscription is currently set to $($(Get-AZContext).Name), do you wish to proceed?" -default "Y") -ne "Y") {
    Write-Host "Cancelled"
    exit
}

# Default values
$location = "eastus"
$environment = "DEV"
$application = "MSDN"
$costCenter = "N\A"
$email = "msdnuser@thisdomainname.com"
$owner = $email
$organization = "MSDN"
$team = $email
$supportTeam = $email
$supportOwner = $email
$manager = $email
$teamLead = $email
$resourceGroupName = $application + "-" + [guid]::NewGuid().ToString() + "-rg" # Generates a GUID based name

# Tags

if ($UseDefaults.IsPresent) {
    $tags = @{
    Environment   = $environment
    Application   = $application
    CostCenter    = $costCenter
    Owner         = $owner
    Organization  = $organization
    Team          = $organization
    SupportTeam   = $supportTeam
    SupportOwner  = $supportOwner
    Manager       = $manager
    TeamLead      = $teamLead
    }
} else {
     $tags = @{
        Environment   = Read-HostWithDefault -prompt "Environment: $($environment)" -default $environment
        Application   = Read-HostWithDefault -prompt "Application: $($application)" -default $application
        CostCenter    = Read-HostWithDefault -prompt "Cost Center: $($costCenter)" -default $costCenter
        Owner         = Read-HostWithDefault -prompt "Owner: $($owner)" -default $owner
        Organization  = Read-HostWithDefault -prompt "Organization: $($organization)" -default $organization
        Team          = Read-HostWithDefault -prompt "Team: $($team)" -default $team
        SupportTeam   = Read-HostWithDefault -prompt "Support Team: $($supportTeam)" -default $supportTeam
        SupportOwner  = Read-HostWithDefault -prompt "Support Owner: $($supportOwner)" -default $supportOwner
        Manager       = Read-HostWithDefault -prompt "Manager: $($manager)" -default $manager
        TeamLead      = Read-HostWithDefault -prompt "Team Lead: $($teamLead)" -default $teamLead
     }
}

# Create Resource Group with tags
New-AzResourceGroup -Name $resourceGroupName -Location $location -Tag $tags

