<#  
.SYNOPSIS  
    This script finds all storage accounts in a tenant and writes out the storage account names and sizes to an excel file.
 .DESCRIPTION  
    This script finds all storage accounts in a tenant and writes out the storage account names and sizes to an excel file.
.NOTES  
    File Name  : Get-AzureADGroupMembers.ps1
    Author     : Ismael Carlo  
    Requires   : PowerShell 7
.LINK  
    https://github.com/IsmaelJCarlo/PowerShell
.EXAMPLE
    ./Get-AzureADGroupMembers.ps1 -ObjectID <objectid>
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory,ParameterSetName='ByObjectId')]
  [string]$ObjectId
)

$logfilePrefix = "AzureADGroupMembers"

$logfilepath = ".\$($logFilePrefix).log"
$excelfilepath = ".\$($logFilePrefix).xlsx"



Start-Transcript -Path $logfilepath

# Replaces output files with unique prefixes
$AzureADGroup = Get-AzureADGroup -ObjectId $ObjectId

write-host "Log file path: $logfilepath"
write-host "Excel file path: $excelfilepath"


$AzureADGroupDetails = New-Object System.Data.DataTable
[void]$AzureADGroupDetails.Columns.Add("DisplayName")
[void]$AzureADGroupDetails.Columns.Add("UserPrincipalName")

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

Initialize-Module "ImportExcel"

$AzureADGroupMembers = Get-AzureADGroupMember -ObjectId $ObjectId

foreach ($AzureADGroupMember in $AzureADGroupMembers) {
  
  [void]$AzureADGroupDetails.Rows.Add($AzureADGroupMember.DisplayName, $AzureADGroupMember.UserPrincipalName)

  Start-Sleep -seconds 1 # This seems necessary to avoid API timeouts
}    

$AzureADGroupDetails | Select-Object DisplayName, UserPrincipalName |  Export-Excel -WorkSheet $AzureADGroup.DisplayName -Path $excelfilepath -AutoSize 

Stop-Transcript