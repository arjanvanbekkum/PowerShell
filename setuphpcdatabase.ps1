
.  "C:\ProgramData\QRM\WriteToLog.ps1"

$ServerInstance = "localhost"
$HeadNode = "headnode"

Set-StrictMode -Version 3
$ErrorActionPreference='Stop'

LogWrite "Set Mixed Mode Authentication"
Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile "C:\programdata\QRM\SQL\update_sql_mixed_mode.sql"

$output = net stop sqlserveragent
LogWrite $output
$output = net stop mssqlserver 
LogWrite $output

$output = net start mssqlserver
LogWrite $output
$output = net start sqlserveragent 
LogWrite $output

LogWrite "Creating HPC Databases in SQL server $ServerInstance ..."
Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile "C:\programdata\QRM\SQL\CreateHpcDatabase.sql" 

LogWrite "Creating QRM Databases in SQL server $ServerInstance ..."
Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile "C:\programdata\QRM\SQL\CreateQRMDatabase.sql" 

$password = aws ssm get-parameter --name "/sql-server/service-account/password" --query "Parameter.Value" --with-decryption --output text --region eu-central-1
$HpcSetupUser = aws ssm get-parameter --name "/sql-server/service-account/username" --query "Parameter.Value" --with-decryption --output text --region eu-central-1

$ParameterArray = "TargetAccount=$HpcSetupUser", "PassWord=$password"

LogWrite "HPC Databases created."
$hpcDBs = @('HPCDiagnostics', 'HPCManagement', 'HPCMonitoring', 'HPCReporting', 'HPCScheduler', 'qrmca', 'qrmwcs')

foreach($hpcdb in $hpcDBs)
{
    LogWrite "Setup $hpcdb DB permissions for Setup user $HpcSetupUser"
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $hpcdb -InputFile "C:\programdata\QRM\SQL\AddDbUserForHpcSetupUser.sql" -Variable  $ParameterArray 
    LogWrite "Setup $hpcdb DB permissions for head node account $headnode"
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $hpcdb -InputFile "C:\programdata\QRM\SQL\AddDbUserForHpcService.sql" -Variable  $ParameterArray 
}

LogWrite "Add custom defined HPC error messages in Sql server $ServerInstance"
Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile "C:\programdata\QRM\SQL\DefineErrorMessages.sql"

LogWrite "Creating backup scheduling HPC databases"
Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile "C:\programdata\QRM\SQL\CreateHPCMonitoringBackupJob.sql"
Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile "C:\programdata\QRM\SQL\CreateHPCSchedulerBackupJob.sql"
Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile "C:\programdata\QRM\SQL\CreateHPCManagementBackupJob.sql"
Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile "C:\programdata\QRM\SQL\CreateHPCDiagnosticsBackupJob.sql"
Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile "C:\programdata\QRM\SQL\CreateHPCReportingBackupJob.sql"

LogWrite "Creating backup scheduling QRM databases"
Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile "C:\programdata\QRM\SQL\CreateQrmCABackupJob.sql"
Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile "C:\programdata\QRM\SQL\CreateQrmWcsBackupJob.sql"

LogWrite "Creating maintenance job for QRM database"
Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile "C:\programdata\QRM\SQL\CreateQrmMaintenanceJob.sql"


