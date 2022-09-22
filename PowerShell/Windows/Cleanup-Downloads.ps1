# Cleans up files older files in Downloads Folder for Current user 

# User Defined Variables
$logFile = "Cleanup-Downloads.log"
$folder = "~\Downloads"

$daysOld = 0

# System Defined Variables
$myDate = get-date -format g
$dateStamp = $myDate  + "   " + $File.FullName
$logFilePath = "$folder\$logFile"

#Stamp Log File with Date
Add-Content $LogFilePath "Executing cleanup on $dateStamp"
# Delete files older than $daysOld
Get-Childitem $folder -Exclude $logFile | Where-Object {($_.LastWriteTime).AddDays($daysOld) -lt (get-date)} | remove-item -force -recurse -verbose 4>> $logFilePath
