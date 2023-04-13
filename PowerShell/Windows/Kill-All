# A simple script that kills all processes matching the input ProcessName

function Kill-All {

  [CmdletBinding()]
  param(
    [Parameter(Mandatory,ParameterSetName='ByProcessName')]
    [string]$ProcessName)
    
  Get-Process | Where-Object -FilterScript {$_.processname -eq $ProcessName} | Select-Object id | kill
 }
