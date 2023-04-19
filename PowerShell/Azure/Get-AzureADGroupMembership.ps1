<#  
.SYNOPSIS  
    This script finds all members of a security group and outputs them to a file called: AzureADGroupMembers.xlsx
 .DESCRIPTION 
    This script finds all members of a security group and outputs them to a file called: AzureADGroupMembers.xlsx
    It will append the file with new sheets respectively named for each security group. Each time you run the 
    file, you must provide the object ID of a security group.  

    To execute the file for multiple groups,it is recommended to create a list of security groups.  You can do this multiple ways:

    1. Create a text file with the security group object IDs and import it with Get-Content. Example:
        $groups = Get-Content .\AzureAdSecurityGroups.txt
        foreach ($group in $groups) { ./Get-AzureADGroupMembers.ps1 -objectId $group.objectId }
    2. Use Get-AzureADGroup to search for groups matching a list of names.  
        Example:
        $groups = Get-AzureADGroup -filter "DisplayName eq 'GroupName1' or DisplayName eq 'GroupName2'"
        foreach ($group in $groups) { ./Get-AzureADGroupMembers.ps1 -objectId $group.objectId }
.NOTES  
    File Name  : Get-AzureADGroupMembers.ps1
    Author     : Ismael Carlo  
    Requires   : PowerShell 7, AzureAD, Connect-AzureAD must be called before this script is executed.
.LINK  
    https://github.com/IsmaelJCarlo/PowerShell
.EXAMPLE
    ./Get-AzureADGroupMembers.ps1 -ObjectID <objectid>
.EXAMPLE
        $groups = Get-Content .\AzureAdSecurityGroups.txt
        foreach ($group in $groups) { ./Get-AzureADGroupMembers.ps1 -objectId $group.objectId }
.EXAMPLE
        $groups = Get-AzureADGroup -filter "DisplayName eq 'GroupName1' or DisplayName eq 'GroupName2'"
        foreach ($group in $groups) { ./Get-AzureADGroupMembers.ps1 -objectId $group.objectId }
#>

[CmdletBinding()]
  param(
    [Parameter(Mandatory,ParameterSetName='ByObjectId')]
    [string]$ObjectId)

# Variables
$logfilePrefix = "AzureADGroupMembers"
$logfilepath = ".\$($logFilePrefix).log"
$excelfilepath = ".\$($logFilePrefix).xlsx"


# Functions
# This function installs a module if it isn't already installed.  I
function Initialize-Module ($moduleName) {
    # If module is imported say that and do nothing
    if (Get-Module | Where-Object {$_.Name -eq $moduleName}) {
        write-host "Module $moduleName is already imported."
    }
    else {

        # If module is not imported, but available on disk then import
        if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $moduleName}) {
            Import-Module $moduleName -Verbose
        }
        else {

            # If module is not imported, not available on disk, but is in online gallery then install and import
            if (Find-Module -Name $moduleName | Where-Object {$_.Name -eq $moduleName}) {
                Install-Module -Name $moduleName -Force -Verbose -Scope CurrentUser
                Import-Module $moduleName -Verbose
            }
            else {

                # If the module is not imported, not available and not in the online gallery then abort
                write-host "Module $moduleName not imported, not available and not in an online gallery, exiting."
                EXIT 1
            }
        }
    }
}


#~ Main Script ~#

# Enable Logging
Start-Transcript -Path $logfilepath -Append -UseMinimalHeader

# Replaces output files with unique prefixes
$AzureADGroup = Get-AzureADGroup -ObjectId $ObjectId

# Prints the output files to the console to help the user find them
Write-Host "Log file path: $logfilepath"
Write-Host "Excel file path: $excelfilepath"

# Initializes a data table to store values which will be copied to Excel later on.
$AzureADGroupDetails = New-Object System.Data.DataTable
[void]$AzureADGroupDetails.Columns.Add("DisplayName")
[void]$AzureADGroupDetails.Columns.Add("UserPrincipalName")

# Export Excel is a module that outputs files in XLSX format and will be used for the output.
Initialize-Module "ImportExcel"

# Gets the members of the referenced AAD Security Group
$AzureADGroupMembers = Get-AzureADGroupMember -ObjectId $ObjectId

# Loops through each member and adds the details to the data table.
foreach ($AzureADGroupMember in $AzureADGroupMembers) {
    [void]$AzureADGroupDetails.Rows.Add($AzureADGroupMember.DisplayName, $AzureADGroupMember.UserPrincipalName)
    Start-Sleep -seconds 1 # This seems necessary to avoid API timeouts
}    

# Exports group membership details to Excel
$AzureADGroupDetails | Select-Object DisplayName, UserPrincipalName |  Export-Excel -WorkSheet $AzureADGroup.DisplayName -Path $excelfilepath -TitleBold

# Stops logging
Stop-Transcript