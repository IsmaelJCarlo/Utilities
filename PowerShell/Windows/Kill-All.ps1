# A simple script that kills all processes matching the input ProcessName
[CmdletBinding()]
param(
#  [Parameter(Mandatory,ParameterSetName='ByProcessName')]
  [string]$ProcessName = $(Read-Host -Prompt 'Enter the process name'))

function Kill-All {
  Write-Host -BackgroundColor Yellow -ForegroundColor Red "Process to kill: $ProcessName"  
  Get-Process | Where-Object -FilterScript {$_.processname -eq $ProcessName} | Select-Object id | Stop-Process
 }

Kill-All -ProcessName $processName