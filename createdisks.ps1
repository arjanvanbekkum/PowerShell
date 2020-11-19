.  "C:\ProgramData\WriteToLog.ps1"

# get the ID of the instance
$instance = Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing

# get the volume of the tag which is connected to the volumes
$valuetag = Get-EC2Tag -Filter @{Name="resource-id";Value=$instance} | Where-Object {$_.Key -eq "ec2-volume-manager-attachment"  } | Select-Object -expand Value

# get the expected volume with the same tag / value pair
$expectedvolume = ((Get-EC2Volume).Tags | Where-Object { ($_.key -eq "ec2-volume-manager-attachment") -and ($_.value -eq $valuetag) }).Count

# get the number of volumes connected to the instance
$disks = ((get-ec2volume) | Where-Object { ($_.Attachments.InstanceId -eq $instance) }).Tags | Where-Object { ($_.key -eq "ec2-volume-manager-attachment") -and ($_.value -eq $valuetag) }

# if the numbers do not match, we are waiting for the volume to be attached to the instance
while ($disks.Count -ne $expectedvolume)
{
  $disks = ((get-ec2volume) | Where-Object { ($_.Attachments.InstanceId -eq $instance) }).Tags | Where-Object { ($_.key -eq "ec2-volume-manager-attachment") -and ($_.value -eq $valuetag) }
  Start-Sleep -s 5
  LogWrite "waiting for volumes..."
}

# get all the volumes 
$volumes = @(get-ec2volume) | Where-Object { ($_.Attachments.InstanceId -eq $instance) } | ForEach-Object { $_.VolumeId}

# Set all disk offline, because the will get a default driveletter
foreach ($vol in $volumes) 
{
  $volumeid = ((Get-EC2Volume -VolumeId $vol).VolumeId).Remove(0,4)
  
  $disk = Get-Disk | Where-Object {$_.SerialNumber -CLike "*$volumeid*"} 

  if ( ($disk.Number -ne 0) -and ($disk) )
  {
    LogWrite "Setting disknumber: "$disk.Number" offline - volume: $volumeid "
    Set-Disk -Number $disk.Number -IsOffline $True
  }
}

# loop the volumes and create the disks in windows with driveletter and systemlabel
foreach ($vol in $volumes) 
{
 
  $volumeid = ((Get-EC2Volume -VolumeId $vol).VolumeId).Remove(0,4)
  
  LogWrite "Found volume with id: $volumeid"
  $DriveLetter = (Get-EC2Volume -VolumeId $vol).Tags | Where-Object { $_.key -eq "DriveLetter" } | Select-Object -expand Value
  $SystemLabel = (Get-EC2Volume -VolumeId $vol).Tags | Where-Object { $_.key -eq "SystemLabel" } | Select-Object -expand Value

  $disk = Get-Disk | Where-Object {$_.SerialNumber -CLike "*$volumeid*"} 

  if ( ($disk) -and ($DriveLetter) -and ($SystemLabel) )
  {
     if ( ($disk.PartitionStyle -eq "Raw") -and ($disk.OperationalStatus -eq "Offline") ) 
     {
        Initialize-Disk -Number $disk.Number 
        Clear-Disk -Number $disk.Number -RemoveData -Confirm:$false -PassThru
        Initialize-Disk -Number $disk.Number 
        New-Partition -DiskNumber $disk.Number -UseMaximumSize -DriveLetter $DriveLetter | Format-Volume -FileSystem NTFS -NewFileSystemLabel $SystemLabel
        LogWrite "Creating disk with DriveLetter $DriveLetter and SystemLabel $SystemLabel" 
     }
     else 
     { 
         if ($disk.OperationalStatus -eq "Offline")
         {
            Set-Disk -Number $disk.Number -IsOffline $False
            $currentDrive = get-partition -DiskNumber $disk.Number| Where-Object { $_.Type -ne "Reserved" } | Select-Object -Expand DriveLetter
            if ( ($currentDrive -ne $DriveLetter) -and ($DriveLetter) -and ($currentDrive) )
            {
                Get-Partition -DriveLetter $currentDrive | Set-Partition -NewDriveLetter $DriveLetter
                Set-Volume -DriveLetter $DriveLetter -NewFileSystemLabel $SystemLabel
                LogWrite "Changing drive from $currentDrive to $DriveLetter"
            }
            LogWrite "Mounted disk with DriveLetter $DriveLetter and SystemLabel $SystemLabel"
         }
         else
         {
           LogWrite "Disk with DriveLetter $DriveLetter is already online" 
         }
      }
   } 
   else
   {
      LogWrite "volume not $volumeid not found" 
   }
}



