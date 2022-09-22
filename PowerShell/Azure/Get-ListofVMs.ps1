$filePath=$args[0]

$vmList = @{} 
Import-Csv -Path $filePath | ForEach-Object {$vmList.Add($_.key,$_.value)}
    
$subs = get-azsubscription
    
foreach ($sub in $subs) {
    set-azcontext $sub.name 
    foreach ($vmListItem in $vmList.keys) {
        $vm = "not found";
        Write-Console "Checking: $($vmList[$($vmListItem)])"
        $vm = Get-AzVm -name $vmList[$vmListItem]
    }
} 