
Param(
	[parameter(Position=1)]
	[string]$rgName = "<resource-group>",
	[parameter(Position=2)]
	[string]$accountName = "<storage-account>"
	)

$storageAccount = Get-AzStorageAccount -ResourceGroupName $rgName -Name $accountName
$ctx = $storageAccount.Context

Get-AzStorageContainer -Context $ctx | Select Name, PublicAccess