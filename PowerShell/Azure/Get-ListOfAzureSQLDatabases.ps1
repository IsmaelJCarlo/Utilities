

$subs = Get-AzSubscription

foreach ($sub in $subs) {
    Set-AzContext $sub.name 
    $AzSQLServers = Get-AzSqlServer
    #$AzResourceGroups = Get-AzResourceGroup
    
#    foreach ($AzResourceGroup in $AzResourceGroups) {
        foreach ($AzSQLServer in $AzSQLServers) {
            $AzSQLServer.ResourceGroupName
            $AzSQLServer.ServerName

            $fwrules = Get-AzSqlServerFirewallRule -ResourceGroupName $AzSQLServer.ResourceGroupName -ServerName $AzSQLServer.ServerName 
    }
} 