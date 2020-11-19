.  "C:\ProgramData\QRM\WriteToLog.ps1"

$ServerInstance = "localhost"

LogWrite "Create Backup folder"
# backup location
$path = "E:\Daily Backups"
New-Item -ItemType Directory -Force -Path $path
$Acl = (Get-Item $path).GetAccessControl('Access')
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("NT SERVICE\MSSQLSERVER", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$Acl.SetAccessRule($Ar)
Set-Acl $path $Acl

LogWrite "Create Database Data folder"
# database location
$path = "D:\Data"
New-Item -ItemType Directory -Force -Path $path
$Acl = (Get-Item $path).GetAccessControl('Access')
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("NT SERVICE\MSSQLSERVER", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$Acl.SetAccessRule($Ar)
Set-Acl $path $Acl

LogWrite "Create TempDb Data folder"
# TempDB location
$path = "T:\Data"
New-Item -ItemType Directory -Force -Path $path
$Acl = (Get-Item $path).GetAccessControl('Access')
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("NT SERVICE\MSSQLSERVER", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$Acl.SetAccessRule($Ar)
Set-Acl $path $Acl

LogWrite "Moving Temp DB"
Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile "C:\programdata\QRM\SQL\MoveTempDb.sql"

$output = net stop sqlserveragent
LogWrite $output
$output = net stop mssqlserver 
LogWrite $output

$output = net start mssqlserver
LogWrite $output
$output = net start sqlserveragent 
LogWrite $output



